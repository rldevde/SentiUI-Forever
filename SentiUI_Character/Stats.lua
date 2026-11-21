-- Stat panel: collapsible groups of label/value rows, all secret-safe.
local _, ns = ...
local S = SentiUI
local C = S.colors
local L = ns.L

ns.Stats = {}
local St = ns.Stats

local function Num(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, v = pcall(fn, ...)
	if not ok then return nil end
	return ns.Plain(v)
end

-- multi-return variant: first two values, each secret-checked
local function Num2(fn, ...)
	if type(fn) ~= "function" then return nil, nil end
	local ok, a, b = pcall(fn, ...)
	if not ok then return nil, nil end
	return ns.Plain(a), ns.Plain(b)
end

local function Pct(fn, ...)
	local v = Num(fn, ...)
	return v and string.format("%.1f%%", v) or nil
end

local function Str(fn, ...)
	local v = Num(fn, ...)
	return v and tostring(v) or nil
end

-- groupId -> rows. Each row: label + value getter.
local function Groups()
	return {
		{ id = "attr", label = L["Attributes"], rows = {
			{ L["Strength"],     function() return Str(UnitStat, "player", 1) end },
			{ L["Agility"],      function() return Str(UnitStat, "player", 2) end },
			{ L["Stamina"],      function() return Str(UnitStat, "player", 3) end },
			{ L["Intellect"],    function() return Str(UnitStat, "player", 4) end },
			{ L["Spirit"],       function() return Str(UnitStat, "player", 5) end },
		}},
		{ id = "melee", label = L["Melee"], rows = {
			{ L["Attack power"],        function() return Str(UnitAttackPower, "player") end },
			{ L["Ranged attack power"], function() return Str(UnitRangedAttackPower, "player") end },
			{ L["Crit chance"],         function() return Pct(GetCritChance) end },
		}},
		{ id = "def", label = L["Defense"], rows = {
			{ L["Armor"],   function() return Str(UnitArmor, "player") end },
			{ L["Defense"], function()
				local base, bonus = Num2(UnitDefense, "player")
				if not base then return nil end
				return tostring(base + (bonus or 0))
			end },
			{ L["Dodge"], function() return Pct(GetDodgeChance) end },
			{ L["Parry"], function() return Pct(GetParryChance) end },
			{ L["Block"], function() return Pct(GetBlockChance) end },
		}},
		{ id = "res", label = L["Resistances"], rows = {
			{ L["Holy"],   function() return Str(UnitResistance, "player", 1) end },
			{ L["Fire"],   function() return Str(UnitResistance, "player", 2) end },
			{ L["Nature"], function() return Str(UnitResistance, "player", 3) end },
			{ L["Frost"],  function() return Str(UnitResistance, "player", 4) end },
			{ L["Shadow"], function() return Str(UnitResistance, "player", 5) end },
			{ L["Arcane"], function() return Str(UnitResistance, "player", 6) end },
		}},
	}
end

-- Row pool -------------------------------------------------------------

local rows = {}
local function GetRow(i)
	if rows[i] then return rows[i] end
	local host = ns.Win.statsRows or ns.Win.statsHost
	local r = CreateFrame("Frame", nil, host)
	r:SetHeight(16)
	r.label = S.Font(r, 10, C.textDim)
	r.label:SetPoint("LEFT", 8, 0)
	r.value = S.Font(r, 10)
	r.value:SetPoint("RIGHT", -8, 0)
	r.stripe = r:CreateTexture(nil, "BACKGROUND")
	r.stripe:SetAllPoints()
	r.stripe:SetColorTexture(1, 1, 1, 0.03)
	r.stripe:Hide()
	rows[i] = r
	return r
end

local heads = {}
local function GetHead(i)
	if heads[i] then return heads[i] end
	local host = ns.Win.statsRows or ns.Win.statsHost
	local h = CreateFrame("Button", nil, host)
	h:SetHeight(22)
	h.txt = S.Font(h, 11, C.accent, "OUTLINE")
	h.txt:SetPoint("LEFT", 8, 0)
	h.arrow = S.Font(h, 10, C.textDim)
	h.arrow:SetPoint("RIGHT", -8, 0)
	h.line = h:CreateTexture(nil, "ARTWORK")
	h.line:SetColorTexture(C.accent.r, C.accent.g, C.accent.b, 0.35)
	h.line:SetPoint("BOTTOMLEFT", 8, 0)
	h.line:SetPoint("BOTTOMRIGHT", -8, 0)
	h.line:SetHeight(1)
	heads[i] = h
	return h
end

local open = {}  -- groupId -> bool
local groups   -- cached group defs

local function IsOpen(id)
	local db = ns.C.db()
	if open[id] == nil then
		open[id] = not db or db.statsOpen ~= "main" or id == "attr" or id == "melee"
	end
	return open[id]
end

function St.Build()
	if St.built then return end
	St.built = true
	groups = Groups()
end

function St.Layout()
	St.Refresh()
end

function St.Refresh()
	if not St.built then return end
	local db = ns.C.db()
	local host = ns.Win.statsRows or ns.Win.statsHost
	local w = (ns.Win.statsScroll and ns.Win.statsScroll:GetWidth())
		or (ns.Win.statsHost and ns.Win.statsHost:GetWidth()) or 200
	local y = -4
	local rowI, headI = 0, 0

	for _, g in ipairs(groups) do
		headI = headI + 1
		local h = GetHead(headI)
		h:SetPoint("TOPLEFT", host, "TOPLEFT", 0, y)
		h:SetWidth(w)
		h.txt:SetText(g.label)
		h.arrow:SetText(IsOpen(g.id) and "▾" or "▸")
		h:SetScript("OnClick", function()
			open[g.id] = not IsOpen(g.id)
			St.Refresh()
		end)
		h:Show()
		y = y - 24

		if IsOpen(g.id) then
			for _, row in ipairs(g.rows) do
				rowI = rowI + 1
				local r = GetRow(rowI)
				r:SetPoint("TOPLEFT", host, "TOPLEFT", 0, y)
				r:SetWidth(w)
				r.label:SetText(row[1])
				r.value:SetText(row[2]() or "-")
				r.stripe:SetShown(db.zebra and rowI % 2 == 0)
				r:Show()
				y = y - 17
			end
		end
		y = y - 4
	end
	for i = rowI + 1, #rows do rows[i]:Hide() end
	for i = headI + 1, #heads do heads[i]:Hide() end
	if ns.Win.statsRows then
		ns.Win.statsRows:SetHeight(math.max(1, -y + 6))
		ns.Win.statsRows:SetWidth(w)
	end
end
