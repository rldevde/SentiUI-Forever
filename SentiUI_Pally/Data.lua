-- Blessings module data: class/blessing/aura/seal tables (Forever = vanilla
-- set, no pets, shaman in slot 9), a guarded modern-API layer and the roster
-- scan. Wire formats live in Comm.lua - the tables here only describe what a
-- paladin can cast.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Data = {}
ns.Data = Data

Data.MAXCLASSES = 9
Data.MAXAURAS = 8            -- wire sends aura info for slots 1..8
Data.BLESSINGS = 6           -- wire SELF reports skill slots 1..6
Data.BLESSING_IDS = 8        -- assignable blessing ids (7 = Sacrifice, 8 = Horn)

-- class slots, the same order PallyPower uses on vanilla/Forever
Data.ClassID = {
	"WARRIOR", "ROGUE", "PRIEST", "DRUID", "PALADIN",
	"HUNTER", "MAGE", "WARLOCK", "SHAMAN",
}
Data.ClassToID = {}
for i, c in ipairs(Data.ClassID) do Data.ClassToID[c] = i end

Data.ClassIcons = {
	"Interface\\Icons\\ClassIcon_Warrior",
	"Interface\\Icons\\ClassIcon_Rogue",
	"Interface\\Icons\\ClassIcon_Priest",
	"Interface\\Icons\\ClassIcon_Druid",
	"Interface\\Icons\\ClassIcon_Paladin",
	"Interface\\Icons\\ClassIcon_Hunter",
	"Interface\\Icons\\ClassIcon_Mage",
	"Interface\\Icons\\ClassIcon_Warlock",
	"Interface\\Icons\\ClassIcon_Shaman",
}

-- blessings by id: ranks descending (highest first), used for the known-spell
-- scan, the aura check and the cast attribute
Data.Blessings = {
	{ -- 1 Wisdom
		icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom",
		nicon = "Interface\\Icons\\Spell_Holy_SealOfWisdom",
		ranks = { 27142, 25290, 19854, 19853, 19852, 19850, 19742 },
		granks = { 27143, 25918, 25894 },
	},
	{ -- 2 Might
		icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings",
		nicon = "Interface\\Icons\\Spell_Holy_FistOfJustice",
		ranks = { 27140, 25291, 19838, 19837, 19836, 19835, 19834, 19740 },
		granks = { 27141, 25916, 25782 },
	},
	{ -- 3 Kings
		icon = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings",
		nicon = "Interface\\Icons\\Spell_Magic_MageArmor",
		ranks = { 20217 },
		granks = { 25898 },
	},
	{ -- 4 Salvation
		icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation",
		nicon = "Interface\\Icons\\Spell_Holy_SealOfSalvation",
		ranks = { 1038 },
		granks = { 25895 },
	},
	{ -- 5 Light
		icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight",
		nicon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02",
		ranks = { 27144, 19979, 19978, 19977 },
		granks = { 27145, 25890 },
	},
	{ -- 6 Sanctuary
		icon = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary",
		nicon = "Interface\\Icons\\Spell_Nature_LightningShield",
		ranks = { 27168, 20914, 20913, 20912, 20911 },
		granks = { 27169, 25899 },
	},
	{ -- 7 Sacrifice (assignable, not in the SELF skill block)
		icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
		nicon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
		ranks = { 27148, 27147, 20729, 6940 },
		granks = {},
	},
	{ -- 8 Horn of Lordaeron (Forever only)
		icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
		nicon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
		ranks = { 425600 },
		granks = {},
	},
}

Data.Auras = {
	{ id = 465,   icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },   -- Devotion
	{ id = 7294,  icon = "Interface\\Icons\\Spell_Holy_AuraOfLight" },    -- Retribution
	{ id = 19746, icon = "Interface\\Icons\\Spell_Holy_MindSooth" },      -- Concentration
	{ id = 19876, icon = "Interface\\Icons\\Spell_Shadow_SealOfKings" },  -- Shadow Resistance
	{ id = 19888, icon = "Interface\\Icons\\Spell_Frost_WizardMark" },    -- Frost Resistance
	{ id = 19891, icon = "Interface\\Icons\\Spell_Fire_SealOfFire" },     -- Fire Resistance
	{ id = 20218, icon = "Interface\\Icons\\Spell_Holy_MindVision" },     -- Sanctity
	{ id = 32223, icon = "Interface\\Icons\\Spell_Holy_CrusaderAura" },   -- Crusader
}

Data.Seals = {
	20164,   -- Justice
	20165,   -- Light
	20166,   -- Wisdom
	21084,   -- Righteousness
	21082,   -- the Crusader
	20375,   -- Command
	31801,   -- Vengeance
	31892,   -- Blood
	348700,  -- the Martyr
	348704,  -- Corruption
	1311656, -- Fury (Forever tank seal)
}

-- minimum target level per rank (same order as Blessings[].ranks, desc);
-- lets a right-click pick the highest rank the target can actually receive
Data.BlessLevels = {
	{ 55, 50, 44, 34, 24, 14, 4 },
	{ 60, 50, 42, 32, 22, 12, 4, 0 },
	{ 10 },
	{ 16 },
	{ 59, 50, 40, 30 },
	{ 60, 50, 40, 30, 20 },
	{ 60, 52, 44, 36 },
	{ 0 },
}

Data.RFID = 25780            -- Righteous Fury
Data.SYMBOL_ITEM = 21177     -- Symbol of Kings
Data.Cooldowns = {
	{ 633, 2800, 10310, 27154, 48788 }, -- Lay on Hands
	{ 19752 },                        -- Divine Intervention
}

-- every aura spell id we count as "this unit already has blessing b"
Data.BlessingIDs = {}
for b, info in ipairs(Data.Blessings) do
	local set = {}
	for _, id in ipairs(info.ranks) do set[id] = true end
	for _, id in ipairs(info.granks) do set[id] = true end
	Data.BlessingIDs[b] = set
end
Data.AnyBlessing = {}
for b = 1, Data.BLESSING_IDS do
	for id in pairs(Data.BlessingIDs[b]) do Data.AnyBlessing[id] = true end
end

-- ---------------------------------------------------------------------------
-- guarded API layer
-- ---------------------------------------------------------------------------

local issecret = _G.issecretvalue or function() return false end
local function num(v) return type(v) == "number" and not issecret(v) and v or nil end
local function str(v) return type(v) == "string" and not issecret(v) and v or nil end

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

function Data.SpellIcon(id)
	if C_Spell and C_Spell.GetSpellInfo then
		local ok, t = pcall(C_Spell.GetSpellInfo, id)
		if ok and type(t) == "table" then return num(t.iconID) or t.iconID end
	end
	if _G.GetSpellInfo then
		local ok, _, tex = pcall(_G.GetSpellInfo, id)
		if ok then return tex end
	end
	return nil
end

function Data.IsKnown(id)
	if _G.IsSpellKnown then
		local ok, k = pcall(_G.IsSpellKnown, id)
		if ok then return k and true or false end
	end
	if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
		local ok, k = pcall(C_SpellBook.IsSpellInSpellBook, id)
		if ok then return k and true or false end
	end
	if C_Spell and C_Spell.IsSpellUsable then
		local ok, k = pcall(C_Spell.IsSpellUsable, id)
		if ok then return k and true or false end
	end
	return false
end

function Data.ItemCount(id)
	if C_Item and C_Item.GetItemCount then
		local ok, n = pcall(C_Item.GetItemCount, id)
		if ok and type(n) == "number" then return n end
	end
	if _G.GetItemCount then
		local ok, n = pcall(_G.GetItemCount, id)
		if ok and type(n) == "number" then return n end
	end
	return 0
end

function Data.SpellCooldown(id)
	if C_Spell and C_Spell.GetSpellCooldown then
		local ok, t = pcall(C_Spell.GetSpellCooldown, id)
		if ok and type(t) == "table" then
			local st, dur = num(t.startTime), num(t.duration)
			if st and dur and dur > 0 then return st, dur end
			return nil
		end
	end
	if _G.GetSpellCooldown then
		local ok, st, dur = pcall(_G.GetSpellCooldown, id)
		if ok then
			st, dur = num(st), num(dur)
			if st and dur and dur > 0 then return st, dur end
		end
	end
	return nil
end

function Data.UnitName(unit)
	if GetUnitName then
		local ok, n = pcall(GetUnitName, unit, true)
		if ok and type(n) == "string" and n ~= "" then return n end
	end
	if UnitName then
		local ok, n = pcall(UnitName, unit)
		if ok and type(n) == "string" then return n end
	end
	return nil
end

function Data.UnitClassBase(unit)
	if UnitClassBase then
		local ok, c = pcall(UnitClassBase, unit)
		if ok and type(c) == "string" then return c end
	end
	if UnitClass then
		local ok, _, c = pcall(UnitClass, unit)
		if ok and type(c) == "string" then return c end
	end
	return nil
end

-- aura spell ids on a unit (helpful only), secret-safe; returns a set
function Data.AuraSet(unit)
	local set = {}
	if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return set end
	for i = 1, 40 do
		local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HELPFUL")
		if not ok or type(a) ~= "table" then break end
		local id = num(a.spellId)
		if id then set[id] = true end
	end
	return set
end

function Data.HasBlessing(set, b)
	if not b or b == 0 then return false end
	local ids = Data.BlessingIDs[b]
	if not ids then return false end
	for id in pairs(ids) do if set[id] then return true end end
	return false
end

function Data.HasAnyBlessing(set)
	for id in pairs(Data.AnyBlessing) do if set[id] then return true end end
	return false
end

-- ---------------------------------------------------------------------------
-- my skills (what SELF reports): highest known rank per blessing slot, talent
-- is always 0 on Forever (no improved blessings there)
-- ---------------------------------------------------------------------------

function Data.Rank(b)
	local info = Data.Blessings[b]
	if not info then return nil end
	local n = #info.ranks
	for i, id in ipairs(info.ranks) do
		if Data.IsKnown(id) then return n - i + 1, id end
	end
	return nil
end

function Data.BestBlessingSpell(b)
	local _, id = Data.Rank(b)
	return id
end

-- highest rank of blessing b that a target of the given level can receive
-- (and that I know) - mirrors PallyPower's per-member rank picker
function Data.BlessingForLevel(b, level)
	local info = Data.Blessings[b]
	if not info then return nil end
	local lvls = Data.BlessLevels[b] or {}
	level = level or 0
	for i, id in ipairs(info.ranks) do
		if (lvls[i] or 0) <= level and Data.IsKnown(id) then return id end
	end
	-- nothing fits the level: fall back to my best known rank
	return Data.BestBlessingSpell(b)
end

function Data.BestGreaterSpell(b)
	local info = Data.Blessings[b]
	if not info then return nil end
	for _, id in ipairs(info.granks) do
		if Data.IsKnown(id) then return id end
	end
	return nil
end

function Data.Skills()
	local out = {}
	for b = 1, Data.BLESSINGS do
		local r = Data.Rank(b)
		if r then out[b] = { rank = r, talent = 0 } end
	end
	return out
end

function Data.AuraSkills()
	local out = {}
	for i = 1, Data.MAXAURAS do
		local a = Data.Auras[i]
		if a and Data.IsKnown(a.id) then
			out[i] = { rank = 1, talent = 0 }
		end
	end
	return out
end

function Data.MyCooldowns()
	local out = {}
	for i, spells in ipairs(Data.Cooldowns) do
		for _, id in ipairs(spells) do
			if Data.IsKnown(id) then
				out[i] = {}
				local st, dur = Data.SpellCooldown(id)
				if st and dur then
					out[i].duration = dur
					out[i].remaining = math.max(st + dur - GetTime(), 0)
				end
				break
			end
		end
	end
	return out
end

function Data.KnownAuras()
	local out = {}
	for i, a in ipairs(Data.Auras) do
		if Data.IsKnown(a.id) then out[#out + 1] = i end
	end
	return out
end

function Data.KnownSeals()
	local out = {}
	for i, id in ipairs(Data.Seals) do
		if Data.IsKnown(id) then out[#out + 1] = i end
	end
	return out
end

-- ---------------------------------------------------------------------------
-- roster
-- ---------------------------------------------------------------------------

-- classes[i] = list of member tables { unit, name, rank, subgroup, class, dead }
-- classlist[i] = member count; leaders[name] = true for leader/assistants
function Data.Roster()
	local classes, classlist, leaders, roster = {}, {}, {}, {}
	for i = 1, Data.MAXCLASSES do
		classes[i] = {}
		classlist[i] = 0
	end
	local function push(unit, name, rank, subgroup)
		local ok, exists = pcall(UnitExists, unit)
		if not (ok and exists) then return end
		local cls = Data.UnitClassBase(unit)
		local cid = cls and Data.ClassToID[cls]
		if not cid then return end
		local ok2, dead = pcall(UnitIsDeadOrGhost, unit)
		name = name or Data.UnitName(unit) or ""
		if Ambiguate then name = Ambiguate(name, "short") end
		local tmp = { unit = unit, name = name,
			rank = rank or 0, subgroup = subgroup or 1, class = cls,
			dead = ok2 and dead == true }
		classlist[cid] = classlist[cid] + 1
		classes[cid][#classes[cid] + 1] = tmp
		roster[#roster + 1] = tmp
		if rank and rank > 0 then leaders[tmp.name] = true end
		return tmp
	end
	if IsInRaid() then
		for i = 1, 40 do
			local unit = "raid" .. i
			local ok, exists = pcall(UnitExists, unit)
			if ok and exists then
				local name, rank, subgroup = i, 0, 1
				if GetRaidRosterInfo then
					local ok2, n, r, sg = pcall(GetRaidRosterInfo, i)
					if ok2 then name, rank, subgroup = n, r, sg end
				end
				local t = push(unit, name, rank, subgroup)
				if t and t.rank == 0 and UnitIsGroupLeader then
					local ok3, l = pcall(UnitIsGroupLeader, unit)
					if ok3 and l then t.rank, leaders[t.name] = 2, true end
				end
			end
		end
	else
		local me = push("player", nil,
			UnitIsGroupLeader and UnitIsGroupLeader("player") and 2 or 0, 1)
		if IsInGroup() then
			for i = 1, 4 do
				local unit = "party" .. i
				push(unit, nil,
					UnitIsGroupLeader and UnitIsGroupLeader(unit) and 2 or 0, 1)
			end
		end
	end
	return { classes = classes, classlist = classlist,
		leaders = leaders, roster = roster }
end
