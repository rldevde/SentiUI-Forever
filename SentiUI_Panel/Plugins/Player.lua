-- Player plugins: vitals, xp, reputation, spec, item level, durability,
-- ammo, soul shards, pet happiness, timed buffs, pvp rank, hearthstone.
local _, ns = ...
local S = SentiUI
local L = ns.L
local P = ns.Plugins
local Plain = ns.Plain
local TipHead, TipKV, TipSub = ns.TipHead, ns.TipKV, ns.TipSub
local SecureAPI = ns.SecureAPI
local format, floor, min = string.format, math.floor, math.min
local sort, tinsert = table.sort, table.insert

local AH = "|cff" .. ns.accentHex
local DH = "|cff" .. ns.dimHex

-- Vitals ------------------------------------------------------------------------------
local function HpColor(pct)
	if pct >= 60 then return "|cff55ff55" end
	if pct >= 30 then return "|cffffcc33" end
	return "|cffff5555"
end

local function PowerColor()
	local okT, ptype = pcall(UnitPowerType, "player")
	ptype = okT and Plain(ptype)
	local info = ptype and PowerBarColor and PowerBarColor[ptype]
	if info and info.r then
		return format("|cff%02x%02x%02x", info.r * 255, info.g * 255, info.b * 255)
	end
	return "|cff339eff"
end

local function ReadVitals()
	local okH, hp, max = pcall(function()
		return UnitHealth("player"), UnitHealthMax("player")
	end)
	hp, max = okH and Plain(hp), okH and Plain(max)
	local okP, pw, pmax = pcall(function()
		return UnitPower("player"), UnitPowerMax("player")
	end)
	pw, pmax = okP and Plain(pw), okP and Plain(pmax)
	if not (hp and max and max > 0) then return nil end
	return hp / max * 100, pw and pmax and pmax > 0 and pw / pmax * 100 or nil,
		hp, max, pw, pmax
end

ns.RegisterPlugin({
	id = "vitals",
	label = L["Vitals"],
	icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
	bar = "top", zone = "LEFT", order = 10,
	events = {
		"PLAYER_ENTERING_WORLD", "UNIT_HEALTH", "UNIT_MAXHEALTH",
		"UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
	},
	onevent = function(_, event, unit)
		if event:sub(1, 5) == "UNIT_" and Plain(unit) ~= "player" then return false end
	end,
	update = function()
		local hp, pw = ReadVitals()
		if not hp then return "" end
		local s = format("%s%d%%|r", HpColor(hp), floor(hp + 0.5))
		if pw then s = s .. "  " .. format("%s%d%%|r", PowerColor(), floor(pw + 0.5)) end
		return s
	end,
	tooltip = function(tip)
		local hpPct, pwPct, hp, hpMax, pw, pwMax = ReadVitals()
		TipHead(tip, L["Vitals"])
		if hp then TipKV(tip, L["Health"], format("%d / %d (%d%%)", hp, hpMax, floor(hpPct + 0.5))) end
		if pwPct then
			TipKV(tip, L["Power"], format("%d / %d (%d%%)", pw or 0, pwMax or 0, floor(pwPct + 0.5)))
		end
	end,
})

-- XP -----------------------------------------------------------------------------------
ns.RegisterPlugin({
	id = "xp",
	label = L["XP"],
	icon = "Interface\\Icons\\XP_Icon",
	bar = "bottom", zone = "RIGHT", order = 40,
	shown = false,
	events = { "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION", "PLAYER_ENTERING_WORLD" },
	update = function(def)
		local cur, max = Plain(UnitXP("player")), Plain(UnitXPMax("player"))
		if not cur or not max or max <= 0 then return "" end
		if not def.started then
			def.started, def.startXP = GetTime(), cur
		end
		return format("%s%d%%|r", AH, floor(cur / max * 100))
	end,
	tooltip = function(tip)
		local cur, max = Plain(UnitXP("player")), Plain(UnitXPMax("player"))
		TipHead(tip, L["Experience"])
		local lvl = Plain(UnitLevel("player"))
		if lvl then TipKV(tip, L["Level"], lvl) end
		if cur and max then
			TipKV(tip, L["Current"], format("%s / %s (%d%%)",
				BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), floor(cur / max * 100)))
			TipKV(tip, L["Remaining"], BreakUpLargeNumbers(max - cur))
			local rest = Plain(GetXPExhaustion())
			if rest then
				TipKV(tip, L["Rested"], format("%s (%d%%)", BreakUpLargeNumbers(rest), floor(rest / max * 100)))
			end
			-- session leveling rate + estimated time to level
			local d = P.byId.xp
			local elapsed = d and d.started and (GetTime() - d.started) or 0
			local gained = d and d.startXP and (cur - d.startXP) or 0
			if elapsed and elapsed > 60 and gained and gained > 0 then
				local rate = gained / elapsed * 3600
				TipKV(tip, L["XP/hour"], format("~%s", BreakUpLargeNumbers(floor(rate))))
				local need = max - cur
				local secs = need / rate * 3600
				local h = floor(secs / 3600)
				local m = floor((secs % 3600) / 60)
				TipKV(tip, L["Time to level"], h > 0 and format("%dh %dm", h, m) or format("%dm", m))
			end
		end
	end,
})

-- Reputation ----------------------------------------------------------------------------
local function WatchedRep()
	local data = C_Reputation and C_Reputation.GetWatchedFactionData and Plain(C_Reputation.GetWatchedFactionData())
	if type(data) == "table" and ns.CanAccess(data) and data.name then
		local lo, hi, cur = Plain(data.currentReactionThreshold), Plain(data.nextReactionThreshold), Plain(data.currentStanding)
		local standing = _G["FACTION_STANDING_LABEL" .. tostring(Plain(data.reaction) or "")]
		if lo and hi and cur and hi > lo then
			return data.name, floor((cur - lo) / (hi - lo) * 100), standing, cur - lo, hi - lo
		end
		return data.name, 100, standing
	end
	if GetWatchedFactionInfo then
		local ok, name, standingID, lo, hi, cur = pcall(GetWatchedFactionInfo)
		local standing = _G["FACTION_STANDING_LABEL" .. tostring(Plain(standingID) or "")]
		if ok and Plain(name) and Plain(lo) and Plain(hi) and Plain(cur) and hi > lo then
			return name, floor((cur - lo) / (hi - lo) * 100), standing, cur - lo, hi - lo
		end
	end
end

local function Short(text, max)
	local n, pos = 0, 1
	while pos <= #text do
		n = n + 1
		if n > max then return text:sub(1, pos - 1) .. "..." end
		local c = text:byte(pos)
		pos = pos + (c >= 240 and 4 or c >= 224 and 3 or c >= 192 and 2 or 1)
	end
	return text
end

ns.RegisterPlugin({
	id = "reputation",
	label = L["Reputation"],
	icon = "Interface\\Icons\\INV_Misc_Ribbon_01",
	bar = "top", zone = "CENTER", order = 10,
	events = { "UPDATE_FACTION", "PLAYER_ENTERING_WORLD" },
	update = function()
		local name, pct = WatchedRep()
		if not name then return "" end
		return format("%s %s%d%%|r", Short(name, 16), AH, pct)
	end,
	tooltip = function(tip)
		local name, pct, standing, have, need = WatchedRep()
		TipHead(tip, L["Reputation"])
		if name then
			tip:AddDoubleLine(name, format("%d%%", pct), 1, 1, 1, 1, 1, 1)
			if standing then TipKV(tip, L["Standing"], standing) end
			if have and need then
				TipKV(tip, L["Progress"], format("%s / %s", BreakUpLargeNumbers(have), BreakUpLargeNumbers(need)))
			end
		else
			tip:AddLine(L["No faction watched"], 0.7, 0.7, 0.7)
		end
	end,
	-- secure /click on the micro button; a deferred hop lands on the
	-- reputation page of our window when the Character module is active
	secureClick = { "CharacterMicroButton" },
	afterClick = function()
		local m = S.GetModule and S:GetModule("Character")
		if m and m.api and m.api.Open then m.api.Open("reputation") end
	end,
	click = function() SecureAPI(ToggleCharacter, "ReputationFrame") end,
	menu = function(def, items)
		items[#items + 1] = { text = L["Watch faction"], isTitle = true }
		local added = 0
		if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
			local okN, n = pcall(C_Reputation.GetNumFactions)
			n = okN and Plain(n) or 0
			for i = 1, n do
				local okD, data = pcall(C_Reputation.GetFactionDataByIndex, i)
				data = okD and Plain(data)
				if ns.CanAccess(data) and Plain(data.name) and not Plain(data.isHeader) then
					local idx, fname = i, data.name
					items[#items + 1] = {
						text = fname,
						onClick = function()
							local fn = C_Reputation.SetWatchedFactionByIndex or SetWatchedFactionIndex
							if fn then SecureAPI(fn, idx) end
							def.last = nil
							P.UpdateOne(def)
						end,
					}
					added = added + 1
				end
				if added >= 12 then break end
			end
		elseif GetNumFactions and GetFactionInfo and SetWatchedFactionIndex then
			for i = 1, GetNumFactions() do
				local ok, name, _, _, _, _, _, _, isHeader = pcall(GetFactionInfo, i)
				name = ok and Plain(name)
				isHeader = ok and Plain(isHeader)
				if name and not isHeader then
					local idx, fname = i, name
					items[#items + 1] = {
						text = fname,
						onClick = function()
							SecureAPI(SetWatchedFactionIndex, idx)
							def.last = nil
							P.UpdateOne(def)
						end,
					}
					added = added + 1
				end
				if added >= 12 then break end
			end
		end
		if added == 0 then
			items[#items + 1] = { text = L["(none)"], disabled = true }
		end
	end,
})

-- Spec -----------------------------------------------------------------------------------
local function SpecName()
	if GetSpecialization and GetSpecializationInfo then
		local ok, i = pcall(GetSpecialization)
		if ok and Plain(i) then
			local ok2, _, name = pcall(GetSpecializationInfo, i)
			if ok2 and Plain(name) then return name end
		end
	end
	if GetNumTalentTabs and GetTalentTabInfo then
		local best, bestPts = nil, 0
		for t = 1, GetNumTalentTabs() do
			local ok, name, _, pts = pcall(GetTalentTabInfo, t)
			pts = ok and Plain(pts)
			if pts and pts > bestPts then best, bestPts = name, pts end
		end
		return best
	end
end

ns.RegisterPlugin({
	id = "spec",
	label = L["Spec"],
	icon = "Interface\\Icons\\INV_Misc_Book_11",
	bar = "bottom", zone = "RIGHT", order = 20,
	shown = false,
	events = { "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_ENTERING_WORLD" },
	update = function()
		local name = SpecName()
		return name and AH .. name .. "|r" or ""
	end,
	tooltip = function(tip)
		TipHead(tip, L["Specialization"])
		tip:AddLine(SpecName() or "-", 1, 1, 1)
		if GetSpecialization and GetSpecializationRole then
			local ok, i = pcall(GetSpecialization)
			i = ok and Plain(i)
			if i then
				local okR, role = pcall(GetSpecializationRole, i)
				role = okR and Plain(role)
				if role then TipKV(tip, L["Role"], _G[role] or role) end
			end
		end
		if GetAverageItemLevel then
			local ok, ilvl = pcall(GetAverageItemLevel)
			ilvl = ok and Plain(ilvl)
			if ilvl then TipKV(tip, L["Item level"], format("%.0f", ilvl)) end
		end
	end,
	secureClick = { "TalentMicroButton", "PlayerSpellsMicroButton" },
	click = function() SecureAPI(ToggleTalentFrame or ToggleCharacter, "TalentsFrame") end,
})

-- Item level ------------------------------------------------------------------------------
local function Levels()
	local ok, avg, eq = pcall(GetAverageItemLevel)
	avg, eq = ok and Plain(avg), ok and Plain(eq)
	eq = eq or avg
	return eq, avg
end

ns.RegisterPlugin({
	id = "itemlevel",
	label = L["Item level"],
	icon = "Interface\\Icons\\INV_Chest_Chain_05",
	bar = "bottom", zone = "RIGHT", order = 30,
	shown = false,
	events = { "PLAYER_EQUIPMENT_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_AVG_ITEM_LEVEL_UPDATE" },
	update = function()
		local eq = Levels()
		if not eq then return "" end
		return format("%s%.1f|r", AH, eq)
	end,
	tooltip = function(tip)
		local eq, avg = Levels()
		TipHead(tip, L["Item level"])
		if eq then TipKV(tip, L["Equipped"], format("%.1f", eq)) end
		if avg and avg ~= eq then TipKV(tip, L["Overall"], format("%.1f", avg)) end
	end,
	secureClick = { "CharacterMicroButton" },
	click = function() SecureAPI(ToggleCharacter, "PaperDollFrame") end,
})

-- Durability --------------------------------------------------------------------------------
local SLOT_NAMES = {
	[1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest",
	[6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands",
	[11] = "Finger", [12] = "Finger", [13] = "Trinket", [14] = "Trinket",
	[15] = "Back", [16] = "Main Hand", [17] = "Off Hand", [18] = "Ranged",
}

local function Durability()
	local items = {}
	local lowest, sum, count = 100, 0, 0
	for slot = 1, 18 do
		local ok, cur, max = pcall(GetInventoryItemDurability, slot)
		cur, max = ok and Plain(cur), ok and Plain(max)
		if cur and max and max > 0 then
			local pct = cur / max * 100
			lowest = min(lowest, pct)
			sum = sum + pct
			count = count + 1
			if pct < 100 then
				local okL, link = pcall(GetInventoryItemLink, "player", slot)
				link = okL and Plain(link)
				items[#items + 1] = { name = link or SLOT_NAMES[slot], pct = pct }
			end
		end
	end
	if count == 0 then return nil, nil, items end
	sort(items, function(a, b) return a.pct < b.pct end)
	return lowest, sum / count, items
end

local function ColorByPercent(pct)
	if pct >= 60 then return "|cff55ff55" end
	if pct >= 30 then return "|cffffcc33" end
	return "|cffff5555"
end

ns.RegisterPlugin({
	id = "durability",
	label = L["Durability"],
	icon = "Interface\\Icons\\Trade_BlackSmithing",
	bar = "bottom", zone = "LEFT", order = 40,
	shown = false,
	events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_ENTERING_WORLD" },
	update = function(def)
		local low, avg = Durability()
		if not low then return "" end
		local pct = P.Opt(def, "average") and avg or low
		return format("%s%d%%|r", ColorByPercent(pct), floor(pct))
	end,
	tooltip = function(tip)
		local low, avg, items = Durability()
		TipHead(tip, L["Durability"])
		if low then
			TipKV(tip, L["Lowest"], format("%d%%", floor(low)))
			TipKV(tip, L["Average"], format("%d%%", floor(avg)))
		end
		if #items > 0 then
			TipSub(tip, L["Damaged items"])
			for i = 1, min(#items, 12) do
				local it = items[i]
				tip:AddDoubleLine("  " .. it.name, format("%s%d%%|r", ColorByPercent(it.pct), floor(it.pct)), 1, 1, 1, 1, 1, 1)
			end
			if #items > 12 then
				tip:AddLine(format("  %s... %s|r", DH, format(L["%d more"], #items - 12)), 1, 1, 1)
			end
		end
	end,
	click = function(def)
		-- at an open merchant: run the enabled vendor actions (protected
		-- APIs are allowed here because a click is a hardware event);
		-- otherwise open the character frame
		local merchant = MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
		if merchant and (P.Opt(def, "autoRepair") or P.Opt(def, "sellJunk")) then
			if P.Opt(def, "autoRepair") then
				local okM, canRepair = pcall(CanMerchantRepair)
				local okC, cost = pcall(GetRepairAllCost)
				cost = okC and Plain(cost) or 0
				if okM and canRepair and cost > 0 then
					local okG, money = pcall(GetMoney)
					if okG and Plain(money) >= cost then
						SecureAPI(RepairAllItems)
						S.Print(format(L["Repaired equipment (%s)"], GetCoinTextureString and GetCoinTextureString(cost) or cost))
					end
				end
			end
			if P.Opt(def, "sellJunk") and C_Container then
				local total = 0
				for bag = 0, 4 do
					local okN, num = pcall(C_Container.GetContainerNumSlots, bag)
					num = okN and Plain(num) or 0
					for slot = 1, num do
						local okI, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
						info = okI and Plain(info)
						if ns.CanAccess(info) and Plain(info.quality) == 0 and not Plain(info.isLocked) then
							local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
							local v
							if get then
								local okV, r = pcall(function() return select(11, get(Plain(info.itemID) or Plain(info.hyperlink) or 0)) end)
								v = okV and Plain(r) or 0
							end
							v = v or 0
							total = total + v * (Plain(info.stackCount) or 1)
							SecureAPI(C_Container.UseContainerItem, bag, slot)
						end
					end
				end
				if total > 0 then
					S.Print(format(L["Sold junk (%s)"], GetCoinTextureString and GetCoinTextureString(total) or total))
				end
			end
			return
		end
		-- our own character window takes no client bookkeeping; only when
		-- the module is absent does this fall back to the game function
		local m = S.GetModule and S:GetModule("Character")
		if m and m.api and m.api.Toggle then
			m.api.Toggle("character")
		else
			SecureAPI(ToggleCharacter, "PaperDollFrame")
		end
	end,
	menu = function(def, items)
		items[#items + 1] = {
			text = L["Show average"], checked = P.Opt(def, "average"), noClose = true,
			onClick = function()
				P.SetOpt(def, "average", not P.Opt(def, "average"))
				def.last = nil
				P.UpdateOne(def)
			end,
		}
		items[#items + 1] = { text = L["Vendor"], isTitle = true }
		items[#items + 1] = {
			text = L["Auto repair"], checked = P.Opt(def, "autoRepair"), noClose = true,
			onClick = function() P.SetOpt(def, "autoRepair", not P.Opt(def, "autoRepair")) end,
		}
		items[#items + 1] = {
			text = L["Sell junk"], checked = P.Opt(def, "sellJunk"), noClose = true,
			onClick = function() P.SetOpt(def, "sellJunk", not P.Opt(def, "sellJunk")) end,
		}
	end,
})

-- Ammo ------------------------------------------------------------------------------------
local AMMO_SLOT = 0
local AMMO_CLASSES = { HUNTER = true, ROGUE = true, WARRIOR = true }

local function UsesAmmo()
	local ok, _, cls = pcall(UnitClass, "player")
	return ok and AMMO_CLASSES[Plain(cls)] == true
end

local function AmmoInfo()
	if not GetInventoryItemID then return end
	local ok, id = pcall(GetInventoryItemID, "player", AMMO_SLOT)
	id = ok and Plain(id)
	if not id then return end
	local count = (C_Item and C_Item.GetItemCount) or GetItemCount
	if not count then return end
	local okC, n = pcall(count, id)
	n = okC and Plain(n)
	if not n then return end
	return n, id
end

ns.RegisterPlugin({
	id = "ammo",
	label = L["Ammo"],
	icon = "Interface\\Icons\\INV_Misc_Ammo_Arrow_01",
	bar = "top", zone = "RIGHT", order = 50,
	events = { "UNIT_INVENTORY_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD" },
	update = function()
		if not UsesAmmo() then return "" end
		local n = AmmoInfo()
		return n and format("%s%s|r", AH, BreakUpLargeNumbers(n)) or ""
	end,
	tooltip = function(tip)
		TipHead(tip, L["Ammo"])
		local n, id = AmmoInfo()
		if n then
			local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
			local name
			if get then
				local ok, iname = pcall(get, id)
				name = ok and Plain(iname)
			end
			TipKV(tip, name or L["Ammo"], BreakUpLargeNumbers(n))
		else
			tip:AddLine(L["No ammunition equipped"], 0.7, 0.7, 0.7)
		end
	end,
})

-- Soul shards -------------------------------------------------------------------------------
local SHARD_ID = 6265
local function IsWarlock()
	local ok, _, cls = pcall(UnitClass, "player")
	return ok and Plain(cls) == "WARLOCK"
end

local function ShardCount()
	local count = (C_Item and C_Item.GetItemCount) or GetItemCount
	if not count then return nil end
	local ok, n = pcall(count, SHARD_ID, true)
	return ok and Plain(n) or nil
end

ns.RegisterPlugin({
	id = "shards",
	label = L["Soul shards"],
	icon = "Interface\\Icons\\Spell_Shadow_SoulGem",
	bar = "top", zone = "RIGHT", order = 60,
	events = { "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD" },
	update = function()
		if not IsWarlock() then return "" end
		local n = ShardCount()
		return n and format("%s%d|r", AH, n) or ""
	end,
	tooltip = function(tip)
		TipHead(tip, L["Soul shards"])
		TipKV(tip, L["Count"], ShardCount() or 0)
	end,
})

-- Pet happiness -----------------------------------------------------------------------------
local function IsHunter()
	local ok, _, cls = pcall(UnitClass, "player")
	return ok and Plain(cls) == "HUNTER"
end

local HAPPY = {
	[1] = { text = "Unhappy", color = "ff5555" },
	[2] = { text = "Content", color = "ffcc33" },
	[3] = { text = "Happy", color = "55ff55" },
}

local function PetMood()
	if not GetPetHappiness then return nil end
	local okPet, has = pcall(UnitExists, "pet")
	if not okPet or not Plain(has) then return nil end
	local ok, lvl = pcall(GetPetHappiness)
	lvl = ok and Plain(lvl)
	return lvl and HAPPY[lvl] or nil
end

ns.RegisterPlugin({
	id = "pethappy",
	label = L["Pet"],
	icon = "Interface\\Icons\\Ability_Hunter_BeastTraining",
	bar = "top", zone = "RIGHT", order = 70,
	events = { "UNIT_HAPPINESS", "UNIT_PET", "PLAYER_ENTERING_WORLD" },
	update = function()
		if not IsHunter() then return "" end
		local mood = PetMood()
		return mood and format("|cff%s%s|r", mood.color, L[mood.text] or mood.text) or ""
	end,
	tooltip = function(tip)
		TipHead(tip, L["Pet happiness"])
		local mood = PetMood()
		if mood then
			TipKV(tip, L["Mood"], L[mood.text] or mood.text)
		else
			tip:AddLine(L["No pet"], 0.7, 0.7, 0.7)
		end
	end,
})

-- Timed buffs / consumables ------------------------------------------------------------------
local function TimedBuffs()
	local out = {}
	if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return out end
	local now = GetTime()
	for i = 1, 60 do
		local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, "player", i, "HELPFUL")
		data = ok and Plain(data)
		if data == nil then break end
		if ns.CanAccess(data) then
			local exp = Plain(data.expirationTime)
			local name = Plain(data.name)
			if name and exp and exp > now and exp - now < 21600 then
				tinsert(out, { name = name, left = exp - now })
			end
		end
	end
	sort(out, function(a, b) return a.left < b.left end)
	return out
end

local function FmtLeft(secs)
	if secs >= 3600 then return format("%dh", floor(secs / 3600)) end
	if secs >= 60 then return format("%dm", floor(secs / 60)) end
	return format("%ds", floor(secs))
end

ns.RegisterPlugin({
	id = "consumables",
	label = L["Buffs"],
	icon = "Interface\\Icons\\INV_Potion_93",
	bar = "top", zone = "LEFT", order = 20,
	events = { "PLAYER_ENTERING_WORLD", "UNIT_AURA" },
	onevent = function(_, event, unit)
		if event == "UNIT_AURA" and Plain(unit) ~= "player" then return false end
	end,
	update = function()
		local list = TimedBuffs()
		local first = list[1]
		if not first then return "" end
		local c = first.left < 120 and "|cffff5555" or first.left < 300 and "|cffffcc33" or AH
		return format("%s%s|r", c, FmtLeft(first.left))
	end,
	tooltip = function(tip)
		TipHead(tip, L["Timed buffs"])
		local list = TimedBuffs()
		if #list == 0 then
			tip:AddLine("  " .. L["(none)"], 0.7, 0.7, 0.7)
			return
		end
		for i = 1, min(#list, 15) do
			local b = list[i]
			tip:AddDoubleLine("  " .. b.name, FmtLeft(b.left), 1, 1, 1, 0.7, 0.7, 0.7)
		end
		if #list > 15 then
			tip:AddLine(format("  %s... %s|r", DH, format(L["%d more"], #list - 15)), 1, 1, 1)
		end
	end,
})

-- PvP rank ------------------------------------------------------------------------------------
local function PvPInfo()
	if UnitHonorLevel and UnitHonor and UnitHonorMax then
		local ok, lvl, cur, max = pcall(function()
			return UnitHonorLevel("player"), UnitHonor("player"), UnitHonorMax("player")
		end)
		lvl = ok and Plain(lvl)
		if lvl and lvl > 0 then
			local pct = 0
			if Plain(cur) and Plain(max) and max > 0 then pct = cur / max end
			return format("%s %d", L["Honor level"], lvl), pct
		end
	end
	if GetPVPRankInfo and GetPVPRankProgress then
		local ok, rank = pcall(GetPVPRankInfo)
		rank = ok and Plain(rank)
		if rank and rank > 0 then
			local okP, pct = pcall(GetPVPRankProgress)
			return format("%s %d", L["Rank"], rank), (okP and Plain(pct)) or 0
		end
	end
end

ns.RegisterPlugin({
	id = "pvprank",
	label = L["PvP"],
	icon = "Interface\\Icons\\Achievement_PVP_A_09",
	bar = "top", zone = "RIGHT", order = 40,
	events = { "HONOR_XP_UPDATE", "PLAYER_PVP_RANK_CHANGED", "PLAYER_ENTERING_WORLD" },
	update = function()
		local name, pct = PvPInfo()
		if not name then return "" end
		return format("%s %s%d%%|r", name, AH, floor(pct * 100))
	end,
	tooltip = function(tip)
		TipHead(tip, L["PvP"])
		local name, pct = PvPInfo()
		if name then
			TipKV(tip, L["Rank"], name)
			TipKV(tip, L["Progress"], format("%d%%", floor(pct * 100)))
		else
			tip:AddLine(L["No rank yet"], 0.7, 0.7, 0.7)
		end
		if GetPVPLifetimeStats then
			local ok, hk = pcall(GetPVPLifetimeStats)
			hk = ok and Plain(hk)
			if hk then TipKV(tip, L["Honorable kills"], BreakUpLargeNumbers(hk)) end
		end
	end,
})

-- Hearthstone ---------------------------------------------------------------------------------
local HEARTH_ID = 6948

local function HearthCooldown()
	local start, dur
	if C_Item and C_Item.GetItemCooldown then
		local ok, s, d = pcall(C_Item.GetItemCooldown, HEARTH_ID)
		if ok then start, dur = Plain(s), Plain(d) end
	elseif GetItemCooldown then
		local ok, s, d = pcall(GetItemCooldown, HEARTH_ID)
		if ok then start, dur = Plain(s), Plain(d) end
	end
	if not start or not dur or dur <= 0 then return 0 end
	local left = start + dur - GetTime()
	return left > 0 and left or 0
end

local function FmtCD(sec)
	sec = floor(sec)
	if sec >= 3600 then
		return format("%d:%02d:%02d", floor(sec / 3600), floor(sec % 3600 / 60), sec % 60)
	end
	return format("%d:%02d", floor(sec / 60), sec % 60)
end

local function HearthHome()
	if not GetBindLocation then return end
	local ok, loc = pcall(GetBindLocation)
	return ok and Plain(loc) or nil
end

ns.RegisterPlugin({
	id = "hearthstone",
	label = L["Hearthstone"],
	icon = "Interface\\Icons\\INV_Misc_Rune_01",
	bar = "top", zone = "RIGHT", order = 80,
	events = { "BAG_UPDATE_COOLDOWN", "HEARTHSTONE_BOUND", "PLAYER_ENTERING_WORLD" },
	update = function()
		local cd = HearthCooldown()
		if cd > 0 then return DH .. FmtCD(cd) .. "|r" end
		local home = HearthHome()
		if not home then return "" end
		return AH .. home .. "|r"
	end,
	tooltip = function(tip)
		TipHead(tip, L["Hearthstone"])
		TipKV(tip, L["Home"], HearthHome() or L["(none)"])
		local cd = HearthCooldown()
		TipKV(tip, L["Cooldown"], cd > 0 and FmtCD(cd) or L["Ready"])
		TipSub(tip, L["Click: use hearthstone"])
	end,
	secureItem = HEARTH_ID,
	click = function()
		-- handled by the secure overlay button (item APIs are protected)
	end,
})
