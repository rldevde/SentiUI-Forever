-- Reads what the professions window needs from C_TradeSkillUI: the open
-- profession, the professions that own a crafting window (the tabs), and
-- the learned recipes grouped by category. Every call is guarded - the
-- client's enum and a few calls may be missing, and returns can be secret.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Data = {}
ns.Data = Data

-- Enum.TradeskillRelativeDifficulty
Data.OPTIMAL, Data.MEDIUM, Data.EASY, Data.TRIVIAL = 0, 1, 2, 3

local function secret(v) return S.IsSecret and S.IsSecret(v) or false end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
local function str(v) return type(v) == "string" and not secret(v) and v or nil end

local function ts() return type(C_TradeSkillUI) == "table" and C_TradeSkillUI or nil end

-- Guarded C_TradeSkillUI call; undocumented calls may not exist.
function Data.Call(name, ...)
	local f = ts() and ts()[name]
	if type(f) ~= "function" then return nil end
	local ok, a, b, c, d = pcall(f, ...)
	if not ok then return nil end
	return a, b, c, d
end
local call = Data.Call

function Data.Has(name)
	local f = ts() and ts()[name]
	return type(f) == "function"
end

-- The list is being re-read (a profession switch); half old, half new.
-- TRADE_SKILL_LIST_UPDATE follows when done.
function Data.Changing() return call("IsDataSourceChanging") == true end

-- The open profession { id, name, skill, max, bonus }; nil when none is.
function Data.Profession()
	local p = call("GetBaseProfessionInfo")
	if type(p) ~= "table" then return nil end
	local id = num(p.professionID)
	if not id or id == 0 then return nil end
	local c = call("GetChildProfessionInfo")
	local shown = (type(c) == "table" and (num(c.professionID) or 0) ~= 0) and c or p
	return { id = id, name = str(p.professionName) or "",
		skill = num(shown.skillLevel) or 0, max = num(shown.maxSkillLevel) or 0,
		bonus = num(shown.skillModifier) or 0 }
end

-- Someone else's recipes (a link or a guild member's list): owner's name,
-- true when unknown, nil for the player's own, an NPC's or the guild list.
function Data.Viewing()
	if call("IsTradeSkillGuild") == true then return nil end
	local linked, owner = call("IsTradeSkillLinked")
	if linked == true then return str(owner) or true end
	if call("IsTradeSkillGuildMember") == true then return true end
	return nil
end

function Data.Icon(id) return (call("GetTradeSkillTexture", id)) end

-- Secure buttons only fire with the spell NAME on this client, not the ID.
function Data.SpellName(id)
	if C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, id)
		if ok and type(n) == "string" then return n end
	end
	if _G.GetSpellInfo then
		local ok, n = pcall(_G.GetSpellInfo, id)
		if ok and type(n) == "string" then return n end
	end
	return nil
end

-- Professions with a crafting window, in tab order (two primaries first -
-- those can be unlearned). Gathering professions fail the crafting-UI
-- check, same rule the game's own tabs use.
function Data.Tabs()
	local out = {}
	if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return out end
	local list = { GetProfessions() }
	for i = 1, 7 do
		local idx = list[i]
		if type(idx) == "number" then
			local name, icon, rank, maxRank, _, offset, skillLine = GetProfessionInfo(idx)
			local spellID
			if num(offset) and C_SpellBook and type(C_SpellBook.GetSpellBookItemInfo) == "function" then
				local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
				local item = C_SpellBook.GetSpellBookItemInfo(offset + 1, bank)
				spellID = type(item) == "table" and num(item.spellID) or nil
			end
			if spellID and call("CanTradeSkillShowCraftingUI", spellID) == true and num(skillLine) then
				out[#out + 1] = { skillLine = skillLine, name = str(name) or "",
					icon = icon, spellID = spellID, rank = num(rank) or 0,
					max = num(maxRank) or 0, primary = i <= 2 }
			end
		end
	end
	return out
end

-- Difficulty colors: the game's own, with fallbacks.
local function gameColor(g, r, gg, b)
	local c = _G[g]
	if type(c) == "table" and type(c.GetRGB) == "function" then return { c:GetRGB() } end
	return { r, gg, b }
end
function Data.Color(difficulty)
	if difficulty == Data.OPTIMAL then return gameColor("DIFFICULT_DIFFICULTY_COLOR", 1, 0.5, 0.25) end
	if difficulty == Data.MEDIUM then return gameColor("FAIR_DIFFICULTY_COLOR", 1, 1, 0) end
	if difficulty == Data.EASY then return gameColor("EASY_DIFFICULTY_COLOR", 0.25, 0.75, 0.25) end
	return { 0.5, 0.5, 0.5 }
end

function Data.SkillWords(difficulty)
	if difficulty == Data.OPTIMAL then return L["Always a skill point"] end
	if difficulty == Data.MEDIUM then return L["Usually a skill point"] end
	if difficulty == Data.EASY then return L["Sometimes a skill point"] end
	return L["No skill points"]
end

-- Materials: a recipe's schematic never changes, so it is read once.
Data.schematics = {}
local function schematic(id)
	local s = Data.schematics[id]
	if s == nil then
		s = call("GetRecipeSchematic", id, false)
		s = type(s) == "table" and s or false
		Data.schematics[id] = s
	end
	return s or nil
end

local function have(itemID)
	if C_Item and type(C_Item.GetItemCount) == "function" then
		return num(C_Item.GetItemCount(itemID)) or 0
	end
	return 0
end

-- { { itemID, name, icon, need, have } } in slot order; hidden/optional
-- reagent slots skipped.
function Data.Materials(id)
	local s = schematic(id)
	local out = {}
	if not (s and type(s.reagentSlotSchematics) == "table") then return out end
	for _, slot in ipairs(s.reagentSlotSchematics) do
		local first = type(slot.reagents) == "table" and slot.reagents[1]
		local itemID = type(first) == "table" and num(first.itemID)
		if itemID and slot.hiddenInCraftingForm ~= true and slot.required ~= false then
			out[#out + 1] = {
				itemID = itemID,
				name = C_Item and C_Item.GetItemNameByID and str(C_Item.GetItemNameByID(itemID)) or nil,
				icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or nil,
				need = num(slot.quantityRequired) or 1,
				have = have(itemID),
			}
		end
	end
	return out
end

function Data.MatsLine(mats)
	local bits = {}
	for _, m in ipairs(mats) do
		if m.name then bits[#bits + 1] = string.format("%d %s", m.need, m.name) end
	end
	return table.concat(bits, ", ")
end

function Data.OutputItem(id)
	local s = schematic(id)
	return s and num(s.outputItemID) or nil
end

function Data.OutputQuality(id)
	local item = Data.OutputItem(id)
	if item and C_Item and type(C_Item.GetItemQualityByID) == "function" then
		return num(C_Item.GetItemQualityByID(item))
	end
	return nil
end

-- Favorites sit in their own section on top, like the game's list.
Data.FAVORITES = { id = "fav", name = PROFESSIONS_CATEGORY_FAVORITE or L["Favorites"], order = -1 }

function Data.CanFavorite()
	return ts() and type(ts().SetRecipeFavorite) == "function"
		and Data.Viewing() == nil and call("IsNPCCrafting") ~= true
end
function Data.SetFavorite(id, on) call("SetRecipeFavorite", id, on and true or false) end

function Data.CanTrack(recipe)
	if type(recipe) ~= "table" or Data.Viewing() ~= nil
		or call("IsNPCCrafting") == true then return false end
	if not (ts() and type(ts().SetRecipeTracked) == "function") then return false end
	if call("HasNoReagentCost", recipe.id) == true then return false end
	return true
end
function Data.SetTracked(id, on) call("SetRecipeTracked", id, on and true or false) end
function Data.IsTracked(id) return call("IsRecipeTracked", id) == true end

local function recipeIDs()
	local ids = call("GetAllRecipeIDs")
	if type(ids) ~= "table" then ids = call("GetFilteredRecipeIDs") end
	return type(ids) == "table" and ids or {}
end

local function category(id, cache)
	if cache[id] ~= nil then return cache[id] end
	local c = call("GetCategoryInfo", id)
	local out = false
	if type(c) == "table" then
		out = { id = id, name = str(c.name) or "", order = num(c.uiOrder) or 0 }
	end
	cache[id] = out
	return out
end

function Data.RecipeLink(recipe)
	if type(recipe) ~= "table" then return nil end
	return str(call("GetRecipeLink", recipe.id)) or recipe.link
end

-- The recipe's cooldown as the game's page reads it: seconds left (nil when
-- ready), midnight reset flag, charges left, max charges.
function Data.Cooldown(id)
	local left, isDay, charges, max = call("GetRecipeCooldown", id)
	left, charges, max = num(left), num(charges), num(max)
	if left and left <= 0 then left = nil end
	return left, isDay == true, charges, max
end

-- On cooldown with no charge to spend.
function Data.Waiting(id)
	local left, _, charges, max = Data.Cooldown(id)
	if max and max > 0 and charges and charges > 0 then return false end
	return left ~= nil
end

-- { prof, sections = { { id, name, order, recipes } }, byID }
function Data.Read()
	local data = { prof = Data.Profession(), sections = {}, byID = {} }
	if not data.prof then return data end
	local inLine = ts() and type(ts().IsRecipeInSkillLine) == "function"
	local cats, bySection = {}, {}
	for _, id in ipairs(recipeIDs()) do
		local r = num(id) and call("GetRecipeInfo", id)
		if type(r) == "table" and r.learned == true and r.isDummyRecipe ~= true
			and (not inLine or call("IsRecipeInSkillLine", id, data.prof.id) ~= false) then
			local mats = Data.Materials(id)
			local recipe = {
				id = id, name = str(r.name) or "", icon = r.icon,
				link = str(r.hyperlink), favorite = r.favorite == true,
				difficulty = num(r.relativeDifficulty) or Data.TRIVIAL,
				enchant = r.isEnchantingRecipe == true,
				verb = str(r.alternateVerb),
				count = num(call("GetCraftableCount", id)) or 0,
				mats = mats, sub = Data.MatsLine(mats),
			}
			local cat = recipe.favorite and Data.FAVORITES
				or (num(r.categoryID) and category(r.categoryID, cats)) or nil
			local key = cat and cat.id or 0
			local section = bySection[key]
			if not section then
				section = { id = key,
					name = cat and cat.name ~= "" and cat.name or (OTHER or L["Other"]),
					order = cat and cat.order or 1e6, recipes = {} }
				bySection[key] = section
				data.sections[#data.sections + 1] = section
			end
			section.recipes[#section.recipes + 1] = recipe
			data.byID[id] = recipe
		end
	end
	table.sort(data.sections, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.name < b.name
	end)
	return data
end

-- The profession's inventory-slot filter (gear professions), driven through
-- the game's own filter so its list agrees.
function Data.Slots()
	local out = {}
	local n = num(call("GetAllFilterableInventorySlotsCount")) or 0
	for i = 1, n do
		local name = str(call("GetFilterableInventorySlotName", i))
		if name then out[#out + 1] = { index = i, name = name } end
	end
	return out
end
function Data.SetSlot(index)
	call("ClearInventorySlotFilter")
	if index then call("SetInventorySlotFilter", index, true, true) end
end
function Data.Filtered()
	local ids = call("GetFilteredRecipeIDs")
	local set = {}
	for _, id in ipairs(type(ids) == "table" and ids or {}) do set[id] = true end
	return set
end

function Data.SkillsUp(recipe)
	return recipe.difficulty ~= Data.TRIVIAL and recipe.difficulty ~= nil
end
