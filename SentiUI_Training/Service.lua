local _, ns = ...
local S = SentiUI

-- class trainer data core: ns.Training (T) holds the vendored class
-- tables plus the lookup/categorize helpers. The Data\Training*.lua
-- files load after this service and register into T.ClassData.

SentiUITrainingDB = SentiUITrainingDB or {}
SentiUITrainingDB.char = SentiUITrainingDB.char or {}
ns.charDb = SentiUITrainingDB.char

local T = {}
ns.Training = T

T.gameVersion = "forever"
T.locale = GetLocale()
T.currentClass = select(2, UnitClass("player"))
T.playerFaction = UnitFactionGroup("player")
T.playerRace = select(3, UnitRace("player"))
T.L = { OR = (GetLocale() == "deDE") and " oder " or " or " }
T.ClassData = {}
T.WeaponSkills = {}
T.TomeIds = {}
T.SayaadTomes = {}
T.spellInfoCache = {}
T.allRanksCache = {}
T.idToRanks = {}
T.petAbilities = {}
T.learnedPetAbilityMap = {}

function T.forClass(token)
	T.ClassData[token] = T.ClassData[token] or {}
	return T.ClassData[token]
end

local function filter(spellsByLevel, pred)
	local output = {}
	for level, spells in pairs(spellsByLevel or {}) do
		output[level] = {}
		for _, spell in ipairs(spells) do
			if pred(spell) then
				tinsert(output[level], spell)
			end
		end
	end
	return output
end

function T.FactionFilter(spellsByLevel, faction)
	faction = faction or T.playerFaction
	return filter(spellsByLevel, function(spell)
		return spell.faction == nil or spell.faction == faction
	end)
end

function T.RaceFilter(spellsByLevel, race)
	race = race or T.playerRace
	return filter(spellsByLevel, function(spell)
		if spell.race == nil and spell.races == nil then return true end
		if spell.races == nil then return spell.race == race end
		return spell.races[1] == race or spell.races[2] == race
	end)
end

function T.questSpellsFor(entriesById, race)
	local result = {}
	for id, entries in pairs(entriesById or {}) do
		for _, entry in ipairs(entries) do
			if tContains(entry.races, race) then
				tinsert(result, {
					id = id, level = entry.level, races = entry.races,
					areas = entry.areas or { entry.area }, quests = entry.quests,
				})
				break
			end
		end
	end
	return result
end

function T.AddQuestSpells(questSpells)
	T.SpellsByLevel = T.SpellsByLevel or {}
	for _, entry in ipairs(T.questSpellsFor(questSpells[T.currentClass], T.playerRace)) do
		T.SpellsByLevel[entry.level] = T.SpellsByLevel[entry.level] or {}
		tinsert(T.SpellsByLevel[entry.level], { id = entry.id, cost = 0, quest = {
			areas = entry.areas, quests = entry.quests, level = entry.level,
		} })
	end
end

function T:AddOverriddenSpells(...)
	local abilityMap = {}
	for _, abilityIds in ipairs({ ... }) do
		for _, abilityId in ipairs(abilityIds) do
			abilityMap[abilityId] = abilityIds
		end
	end
	self.overriddenSpellsMap = abilityMap
end

local ROMAN_DIGITS = { I = 1, V = 5, X = 10 }
local function romanToNumber(numeral)
	local total, prev = 0, 0
	for i = #numeral, 1, -1 do
		local value = ROMAN_DIGITS[numeral:sub(i, i)]
		total = value < prev and total - value or total + value
		prev = value
	end
	return total
end

function T.stripRankNumeral(name, subText)
	local base, numeral = string.match(name, "^(.-)%s+([IVX]+)$")
	local rank = subText and string.match(subText, "%d+")
	if base and rank and romanToNumber(numeral) == tonumber(rank) then
		return base
	end
	return name
end

local BANK_PLAYER = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
local BANK_PET = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or 1

local function bookHas(bank, id)
	if not C_SpellBook then return false end
	local ok, r = pcall(C_SpellBook.IsSpellInSpellBook, id, bank, false)
	if ok and r then return true end
	ok, r = pcall(C_SpellBook.IsSpellKnown, id, bank)
	return ok and r or false
end

function T.isPreviouslyLearnedAbility(spellId)
	local map = T.overriddenSpellsMap
	if not (map and map[spellId]) then
		return false
	end
	local spellIndex, knownIndex = 0, 0
	for i, otherId in ipairs(map[spellId]) do
		if otherId == spellId then spellIndex = i end
		if bookHas(BANK_PLAYER, otherId) then
			knownIndex = i
		end
	end
	return spellIndex <= knownIndex
end

function T:IsPetAbility(spellId)
	return self.PetAbilityIds ~= nil and self.PetAbilityIds[spellId] == true
end

function T:IsPetAbilityLearned(key)
	return self.learnedPetAbilityMap[key] == true
		or (ns.charDb and ns.charDb.trainingPetLearned
			and ns.charDb.trainingPetLearned[key] == true)
end

function T.isAbilityKnown(spellId)
	if bookHas(BANK_PLAYER, spellId) or T.isPreviouslyLearnedAbility(spellId) then
		return true
	end
	if not T:IsPetAbility(spellId) then
		return false
	end
	if bookHas(BANK_PET, spellId) or T:IsPetAbilityLearned(spellId) then
		return true
	end
	local info = T:SpellInfo(spellId)
	if not (info and info.subText) then
		return false
	end
	local learned = T.learnedPetAbilityMap[info.name]
		or (ns.charDb and ns.charDb.trainingPetLearned and ns.charDb.trainingPetLearned[info.name])
	return learned ~= nil and learned[info.subText] == true
end

-- spell display info, cached; nil while the client has no data yet
function T:SpellInfo(spellId)
	if self.spellInfoCache[spellId] ~= nil then
		return self.spellInfoCache[spellId]
	end
	if not (C_Spell and C_Spell.GetSpellInfo) then return nil end
	local si = C_Spell.GetSpellInfo(spellId)
	if not (si and si.name) then return nil end
	local subText = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(spellId) or nil
	local name = T.stripRankNumeral(si.name, subText)
	local info = {
		id = spellId,
		name = name,
		subText = (subText and subText ~= "") and subText or nil,
		icon = si.iconID or (C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellId)),
		tooltipType = "spell",
		tooltipId = spellId,
	}
	if info.subText then
		info.formattedFullName = name .. " (" .. info.subText .. ")"
	else
		info.formattedFullName = name
	end
	self.spellInfoCache[spellId] = info
	if self.allRanksCache[name] == nil then
		self.allRanksCache[name] = {}
	end
	tinsert(self.allRanksCache[name], spellId)
	self.idToRanks[spellId] = self.allRanksCache[name]
	if self:IsPetAbility(spellId) then
		self.petAbilities[info.formattedFullName] = info
	end
	return info
end

function T:PetAbility(forName) return self.petAbilities[forName] end
function T:AllRanks(spellId) return self.idToRanks[spellId] end

-- ignore list (per character) — replaces the external ignore-store lib
function T.IsIgnored(key)
	return ns.charDb and ns.charDb.trainingIgnored and ns.charDb.trainingIgnored[key] == true
end

function T.SetIgnored(key, state)
	if not ns.charDb then return end
	ns.charDb.trainingIgnored = ns.charDb.trainingIgnored or {}
	ns.charDb.trainingIgnored[key] = state and true or nil
end

-- warlock grimoires: learned if the taught spell is in the current pet's
-- spellbook, or manually marked (persisted per character)
function T.IsTomeLearned(tome)
	if ns.charDb and ns.charDb.trainingTomes and ns.charDb.trainingTomes[tome.itemId or tome.id] then
		return true
	end
	local taught = T.TomeTaughtSpells and T.TomeTaughtSpells[tome.itemId]
	return taught ~= nil and bookHas(BANK_PET, taught)
end

function T.SetTomeLearned(itemId, state)
	if not ns.charDb then return end
	ns.charDb.trainingTomes = ns.charDb.trainingTomes or {}
	ns.charDb.trainingTomes[itemId] = state and true or nil
end

-- hunter beast-training scan: learned abilities persist per character
local function scanPetCraft()
	if not (GetNumCrafts and GetCraftInfo) then return end
	if not ns.charDb then return end
	ns.charDb.trainingPetLearned = ns.charDb.trainingPetLearned or {}
	local n = GetNumCrafts()
	if not n or n == 0 then return end
	if GetCraftDisplaySkillLine and GetCraftDisplaySkillLine() then return end
	for i = 1, n do
		local name, rank = GetCraftInfo(i)
		if name then
			local map = ns.charDb.trainingPetLearned
			map[name] = map[name] or {}
			if rank then map[name][rank] = true end
			T.learnedPetAbilityMap[name] = map[name]
		end
	end
end

if C_EventUtils and C_EventUtils.IsEventValid
	and not C_EventUtils.IsEventValid("CRAFT_UPDATE") then
	-- client without the beast-training craft API: nothing to scan
elseif GetNumCrafts then
	-- CRAFT_UPDATE fires inside the craft-window dispatch - addon Lua
	-- running there taints the client's protected FrameShow/secret work
	-- right after. The scan already defers a frame, and the event is only
	-- registered while the craft window is actually open, so pressing the
	-- keybind in combat cannot dispatch our handler at all
	local craftEv = CreateFrame("Frame")
	craftEv:SetScript("OnEvent", function() C_Timer.After(0, scanPetCraft) end)
	if _G.CraftFrame then
		S.WatchShown(_G.CraftFrame,
			function() pcall(craftEv.RegisterEvent, craftEv, "CRAFT_UPDATE") end,
			function() pcall(craftEv.UnregisterEvent, craftEv, "CRAFT_UPDATE") end)
	else
		pcall(craftEv.RegisterEvent, craftEv, "CRAFT_UPDATE")
	end
end

------------------------------------------------------------
-- categorized data for the page
------------------------------------------------------------
T.KEYS = {
	"available", "missingReqs", "missingTalent", "nextLevel", "notLevel",
	"pet", "ignored", "known",
}
T.WEAPON_KEYS = { "weaponAvailable", "weaponNextLevel", "weaponNotLevel", "weaponIgnored", "weaponKnown" }

function T.FormatCost(cost)
	if not cost or cost <= 0 then
		return ""
	end
	if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
		local ok, s = pcall(C_CurrencyInfo.GetCoinTextureString, cost)
		if ok and s then return s end
	end
	return GetCoinTextureString and GetCoinTextureString(cost) or (cost .. "c")
end

local function fillSpell(info, spell, level)
	info.level = level
	info.cost = spell.cost
	info.quest = spell.quest
	return info
end

function T.BuildData()
	local playerLevel = UnitLevel("player")
	local cats = {}
	for _, k in ipairs(T.KEYS) do cats[k] = {} end
	for _, k in ipairs(T.WEAPON_KEYS) do cats[k] = {} end
	local totals = { available = 0, weaponAvailable = 0, ignored = 0 }

	for level, group in pairs(T.SpellsByLevel or {}) do
		for _, spell in ipairs(group) do
			local info = T:SpellInfo(spell.id)
			if info then
				local key
				if T.isAbilityKnown(spell.id) then
					key = "known"
				elseif T.IsIgnored(spell.id) then
					key = "ignored"
					totals.ignored = totals.ignored + (spell.cost or 0)
				elseif T:IsPetAbility(spell.id) then
					key = "pet"
				elseif spell.requiredTalentId and not T.isAbilityKnown(spell.requiredTalentId) then
					key = "missingTalent"
				elseif level > playerLevel then
					key = (level <= playerLevel + 2) and "nextLevel" or "notLevel"
				else
					local hasReqs = true
					for _, reqId in ipairs(spell.requiredIds or {}) do
						hasReqs = hasReqs and T.isAbilityKnown(reqId)
					end
					key = hasReqs and "available" or "missingReqs"
				end
				local entry = fillSpell({
					id = spell.id, name = info.name, subText = info.subText,
					formattedFullName = info.formattedFullName, icon = info.icon,
				}, spell, level)
				tinsert(cats[key], entry)
				if key == "available" then
					totals.available = totals.available + (spell.cost or 0)
				end
			end
		end
	end

	-- warlock grimoires
	for level, tomes in pairs(T.TomesByLevel or {}) do
		for _, tome in ipairs(tomes) do
			local itemId = tome.itemId
			local name = itemId and C_Item and C_Item.GetItemNameByID
				and C_Item.GetItemNameByID(itemId) or nil
			local key = T.IsTomeLearned(tome) and "known"
				or (T.IsIgnored(tome.id) and "ignored" or "pet")
			tinsert(cats[key], {
				id = tome.id or itemId, itemId = itemId, tome = true,
				name = name or ("Item " .. (itemId or "?")),
				formattedFullName = (tome.family or "?") .. " — " .. (name or itemId or "?"),
				icon = T.WarlockAltIcons and T.WarlockAltIcons[tome.family],
				family = tome.family, level = level, cost = tome.cost,
			})
			if key == "available" then
				totals.available = totals.available + (tome.cost or 0)
			end
		end
	end

	-- weapon skills
	for spellId, w in pairs(T.WeaponSkills) do
		if w.classes and w.classes[T.currentClass] then
			local info = T:SpellInfo(spellId)
			if info then
				local reqLevel = w.level or 1
				local key
				if T.isAbilityKnown(spellId) then
					key = "weaponKnown"
				elseif T.IsIgnored(spellId) then
					key = "weaponIgnored"
					totals.ignored = totals.ignored + (w.cost or 0)
				elseif reqLevel > playerLevel then
					key = (reqLevel <= playerLevel + 2) and "weaponNextLevel" or "weaponNotLevel"
				else
					key = "weaponAvailable"
					totals.weaponAvailable = totals.weaponAvailable + (w.cost or 0)
				end
				tinsert(cats[key], {
					id = spellId, name = info.name, subText = info.subText,
					formattedFullName = info.formattedFullName, icon = info.icon,
					level = reqLevel, cost = w.cost, weapon = true,
					trainers = w.trainers and w.trainers[T.playerFaction],
					zones = w[T.playerFaction .. "FormattedTrainerZones"],
					orderIndex = w.orderIndex,
				})
			end
		end
	end

	-- sort: by level then name; weapons keep the canonical order
	local function byLevel(a, b)
		if a.level ~= b.level then return (a.level or 0) < (b.level or 0) end
		return (a.name or "") < (b.name or "")
	end
	local function byWeapon(a, b)
		if a.orderIndex ~= b.orderIndex then
			return (a.orderIndex or 99) < (b.orderIndex or 99)
		end
		return byLevel(a, b)
	end
	for _, k in ipairs(T.WEAPON_KEYS) do sort(cats[k], byWeapon) end
	for _, k in ipairs(T.KEYS) do sort(cats[k], byLevel) end

	return cats, totals
end

------------------------------------------------------------
-- professions: every recipe, sorted by what you can do about it
------------------------------------------------------------
local TX_ALIAS = { enGB = "enUS", ptPT = "ptBR" }
function T.Text(key)
	local all = ns.TrText or {}
	local lang = GetLocale and GetLocale() or "enUS"
	lang = TX_ALIAS[lang] or lang
	return (all[lang] and all[lang][key]) or (all.enUS and all.enUS[key]) or key
end

T.Professions = { 129, 186, 185, 393, 182, 164, 356, 171, 165, 197, 333, 202 }
local SECONDARY = { [129] = true, [185] = true, [356] = true }
local SKILL_SPELLS = {
	[129] = 3273, [186] = 2575, [185] = 2550, [393] = 8613, [182] = 9134, [164] = 2018,
	[356] = 7620, [171] = 2259, [165] = 2108, [197] = 3908, [333] = 7411, [202] = 4036,
}
T.RecipeCat = { AVAILABLE = 1, MISSING = 2, SOON = 3, LATER = 4, IGNORED = 5 }
local CAT = T.RecipeCat
local requested = {}

-- { id, name, rank, maxRank } of a profession the character has, else nil
function T.SkillInfo(id)
	if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
		local ok, r = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
		if ok and type(r) == "table" then
			local rank = r.rank or r.skillLevel or r.skillLineRank
			if rank then
				return {
					id = id, rank = rank,
					name = r.name or r.skillLineName or r.professionName or ("#" .. id),
					maxRank = r.maxRank or r.maxSkillLevel or r.skillLineMaxRank or rank,
				}
			end
		end
	end
	if GetNumSkillLines and GetSkillLineInfo and C_Spell and SKILL_SPELLS[id] then
		local info = C_Spell.GetSpellInfo(SKILL_SPELLS[id])
		local want = info and info.name
		if want then
			for i = 1, GetNumSkillLines() do
				local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
				if not isHeader and name == want then
					return { id = id, name = name, rank = rank, maxRank = maxRank }
				end
			end
		end
	end
end

-- the professions the character has learned
function T.MySkills()
	local out = {}
	for _, id in ipairs(T.Professions) do
		local s = T.SkillInfo(id)
		if s then
			out[#out + 1] = s
		end
	end
	table.sort(out, function(a, b)
		if (SECONDARY[a.id] or false) ~= (SECONDARY[b.id] or false) then
			return not SECONDARY[a.id]
		end
		return a.name < b.name
	end)
	return out
end

local SOURCE_KEYS = {
	trainer = "TRAINER", vendor = "VENDOR", drop = "DROP", quest = "QUEST",
	crafted = "CRAFTED", world_object = "WORLD_OBJECT", discovery = "DISCOVERY",
}

local function RepRequirement(recipe)
	local rep = recipe.reputation
	if not rep then
		return nil, true
	end
	local alts, met = {}, false
	for i = 1, #rep, 3 do
		local d = C_Reputation and C_Reputation.GetFactionDataByID and C_Reputation.GetFactionDataByID(rep[i])
		local standing = d and d.reaction
		met = met or (standing and standing >= rep[i + 1]) or false
		alts[#alts + 1] = ("%s (%s)"):format((d and d.name) or rep[i + 2] or "?",
			_G["FACTION_STANDING_LABEL" .. rep[i + 1]] or rep[i + 1])
	end
	return T.Text("REQUIRES_REPUTATION"):format(table.concat(alts, " / ")), met
end

-- drops quest/vendor sources when every location belongs to the other faction
local function UsableSources(recipe, sources, faction)
	local usable = {}
	for _, source in ipairs(sources) do
		local spots = (source == "quest" and recipe.quests) or (source == "vendor" and recipe.vendors) or nil
		local keep = not spots or #spots == 0
		for _, spot in ipairs(spots or {}) do
			if not spot.faction or spot.faction == faction then
				keep = true
			end
		end
		if keep then
			usable[#usable + 1] = source
		end
	end
	return (#usable == #sources or #usable == 0) and sources or usable
end

local function Category(recipe, skill, level, repMet)
	local required = recipe.skill
	if not required then
		return CAT.MISSING
	end
	if required <= skill.rank then
		if not repMet or (level and level > UnitLevel("player")) or (recipe.rank and not level) then
			return CAT.MISSING
		end
		return CAT.AVAILABLE
	end
	if required <= skill.rank + 10 and required <= skill.maxRank then
		return CAT.SOON
	end
	return CAT.LATER
end

function T.BuildRecipes()
	local groups = { {}, {}, {}, {}, {} }
	local faction = UnitFactionGroup("player")
	for _, id in ipairs(T.Professions) do
		local skill = T.SkillInfo(id)
		local list = ns.TrainingRecipes and ns.TrainingRecipes[id]
		if skill and list then
			-- a learned rank-up replaces the lower ones
			local knownRank = 0
			for _, r in ipairs(list) do
				if r.rank and r.skill > knownRank and bookHas(BANK_PLAYER, r.spell) then
					knownRank = r.skill
				end
			end
			for _, r in ipairs(list) do
				if (not r.faction or r.faction == faction)
					and not (r.rank and r.skill <= knownRank) and not bookHas(BANK_PLAYER, r.spell) then
					local info = C_Spell and C_Spell.GetSpellInfo(r.spell)
					if not info and C_Spell and C_Spell.RequestLoadSpellData and not requested[r.spell] then
						requested[r.spell] = true
						pcall(C_Spell.RequestLoadSpellData, r.spell)
					end
					local name = info and info.name or ("Spell " .. r.spell)
					if r.rank then
						local sub = C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(r.spell)
						name = ("%s (%s)"):format(name, (sub and sub ~= "") and sub or r.rank)
					end
					local sources = UsableSources(r, r.source or {}, faction)
					if #sources > 0 then
						local labels = {}
						for _, s in ipairs(sources) do
							labels[#labels + 1] = T.Text(SOURCE_KEYS[s] or "") ~= (SOURCE_KEYS[s] or "") and T.Text(SOURCE_KEYS[s]) or s
						end
						local repText, repMet = RepRequirement(r)
						local cat = Category(r, skill, r.level, repMet)
						local row = {
							recipe = r, spell = r.spell, name = name, profession = skill.name, professionID = id,
							sources = sources, source = table.concat(labels, T.Text("SOURCE_SEPARATOR")),
							requiredSkill = r.skill, cost = r.cost, repText = repText,
							icon = (r.creates and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(r.creates))
								or (info and info.iconID) or "Interface\\Icons\\INV_Misc_QuestionMark",
							requirement = (not r.skill and T.Text("SKILL_REQUIREMENT_UNKNOWN"))
								or (r.level and r.level > UnitLevel("player") and T.Text("REQUIRES_LEVEL"):format(r.level))
								or (r.rank and not r.level and T.Text("CHECK_TRAINER_REQUIREMENTS")) or nil,
						}
						local label = T.Text("SKILL"):format(r.skill or "?")
						if r.skill and r.skill > skill.rank then
							label = label .. (" (+%d)"):format(r.skill - skill.rank)
						end
						row.skillLabel = label
						row.searchName = (name .. " " .. skill.name):lower()
						if T.IsIgnored(r.spell) then
							cat = CAT.IGNORED
						end
						table.insert(groups[cat], row)
					end
				end
			end
		end
	end
	for _, rows in ipairs(groups) do
		table.sort(rows, function(a, b)
			local ar, br = a.requiredSkill or math.huge, b.requiredSkill or math.huge
			if ar ~= br then
				return ar < br
			end
			if a.profession ~= b.profession then
				return a.profession < b.profession
			end
			return a.name < b.name
		end)
	end
	return groups
end
