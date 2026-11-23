-- Shared helpers: secret-safe reads, colors, status text, bars, the event
-- bus and the frame registry every unit file hooks into.
local _, ns = ...
local S = SentiUI
local L = ns.L

local ipairs, pairs, type = ipairs, pairs, type
local format, floor = string.format, math.floor
local CreateFrame = CreateFrame

local BLANK = "Interface\\Buttons\\WHITE8X8"

ns.version = "0.1.0"
ns.accentHex = S.Hex(S.colors.accent)
ns.dimHex = S.Hex(S.colors.textDim)
local C = S.colors

function ns.Plain(v)
	if v == nil or S.IsSecret(v) then return nil end
	if type(v) == "table" and S.IsSecretTable(v) then return nil end
	return v
end

function ns.CanAccess(t)
	return type(t) == "table" and not S.IsSecretTable(t)
end

function ns.Font(parent, size, color, flags)
	return S.Font(parent, size or ns.db.fontSize or 11, color, flags or "OUTLINE")
end

-- number formatting -------------------------------------------------------------
function ns.FmtNum(v)
	if type(v) ~= "number" then return "?" end
	if v >= 1e6 then return format("%.1fm", v / 1e6) end
	if v >= 1e4 then return format("%.1fk", v / 1e3) end
	return format("%d", v)
end

-- colors ------------------------------------------------------------------------
local CLASS_COLORS_FALLBACK = {
	WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 },
	HUNTER = { 0.67, 0.83, 0.45 }, ROGUE = { 1.00, 0.96, 0.41 },
	PRIEST = { 1.00, 1.00, 1.00 }, DEATHKNIGHT = { 0.77, 0.12, 0.23 },
	SHAMAN = { 0.00, 0.44, 0.87 }, MAGE = { 0.41, 0.80, 0.94 },
	WARLOCK = { 0.58, 0.51, 0.79 }, MONK = { 0.00, 1.00, 0.59 },
	DRUID = { 1.00, 0.49, 0.04 }, DEMONHUNTER = { 0.64, 0.19, 0.79 },
	EVOKER = { 0.20, 0.58, 0.50 },
}

-- UnitIsPlayer can be secret or unreliable on this client: player GUIDs
-- answer the same question deterministically via their "Player-" prefix.
function ns.UnitIsPlayer(unit)
	if unit == "player" then return true end
	local okG, guid = pcall(UnitGUID, unit)
	guid = okG and ns.Plain(guid)
	if type(guid) == "string" then return guid:sub(1, 7) == "Player-" end
	local ok, p = pcall(UnitIsPlayer, unit)
	return (ok and ns.Plain(p)) == true
end

-- class token: UnitClass first, GetPlayerInfoByGUID as the secret-proof path
local function ClassToken(unit)
	local ok, _, cls = pcall(UnitClass, unit)
	cls = ok and ns.Plain(cls)
	if cls then return cls end
	local okG, guid = pcall(UnitGUID, unit)
	guid = okG and ns.Plain(guid)
	if not guid or type(guid) ~= "string" or guid:sub(1, 7) ~= "Player-" then return nil end
	local okI, _, ecls = pcall(GetPlayerInfoByGUID, guid)
	return okI and ns.Plain(ecls) or nil
end
ns.ClassToken = ClassToken -- portraits read the class for the icon atlas

-- When the client hides a unit's class behind a secret, the engine still
-- resolves it: C_ClassColor.GetClassColor accepts the secret token from
-- UnitClassBase and returns a color object whose r/g/b are secret numbers.
-- Color setters take those natively - callers must NOT boolean-test or
-- format them, just pcall the setter.
local function SecretClassColor(unit)
	if not (C_ClassColor and C_ClassColor.GetClassColor and UnitClassBase) then return nil end
	local ok, name, file, id = pcall(UnitClassBase, unit)
	if not ok then return nil end
	for i = 1, 3 do
		local tok = select(i, file, id, name)
		local got, c = pcall(C_ClassColor.GetClassColor, tok)
		if got and type(c) == "table" then
			local okC, r, g, b = pcall(function() return c.r, c.g, c.b end)
			if okC and ((issecretvalue and issecretvalue(r)) or r ~= nil) then
				return r, g, b
			end
		end
	end
end

function ns.ClassColor(unit)
	local cls = ClassToken(unit)
	if cls then
		-- the color table itself can be a secret table: index it inside pcall
		local ok2, c = pcall(function()
			return (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS or {})[cls] or CLASS_COLORS_FALLBACK[cls]
		end)
		if ok2 and type(c) == "table" and not S.IsSecretTable(c) then
			if c.r then return c.r, c.g, c.b end
			return c[1], c[2], c[3]
		end
	end
	return SecretClassColor(unit)
end

local REACTION_FALLBACK = {
	[1] = { 0.79, 0.15, 0.12 }, [2] = { 0.79, 0.15, 0.12 },
	[3] = { 0.85, 0.30, 0.12 }, [4] = { 0.78, 0.65, 0.12 },
	[5] = { 0.30, 0.85, 0.28 }, [6] = { 0.30, 0.85, 0.28 },
	[7] = { 0.30, 0.85, 0.28 }, [8] = { 0.30, 0.85, 0.28 },
}

function ns.ReactionColor(unit)
	-- UnitReaction(unit, otherUnit): this unit's attitude towards the player
	local ok, r = pcall(UnitReaction, unit, "player")
	r = ok and ns.Plain(r)
	local c = r and REACTION_FALLBACK[floor(r)] or REACTION_FALLBACK[5]
	return c[1], c[2], c[3]
end

local POWER_FALLBACK = {
	[0] = { 0.10, 0.40, 0.85 },  -- mana
	[1] = { 0.85, 0.15, 0.15 },  -- rage
	[2] = { 0.85, 0.60, 0.20 },  -- focus
	[3] = { 0.90, 0.85, 0.25 },  -- energy
	[4] = { 0.85, 0.55, 0.25 },  -- combo points
	[5] = { 0.30, 0.45, 0.75 },  -- runes
	[6] = { 0.00, 0.82, 1.00 },  -- runic power
	[7] = { 0.55, 0.40, 0.90 },  -- soul shards
	[8] = { 0.30, 0.55, 0.95 },  -- astral power
	[9] = { 0.95, 0.90, 0.60 },  -- holy power
	[10] = { 0.65, 0.20, 0.85 }, -- insanity / shadow orbs
	[11] = { 0.15, 0.65, 0.75 }, -- maelstrom
	[12] = { 0.35, 0.90, 0.70 }, -- chi
	[13] = { 0.75, 0.10, 0.45 }, -- fury / pain
	[14] = { 0.75, 0.10, 0.45 },
	[16] = { 0.55, 0.30, 0.95 }, -- arcane charges
	[17] = { 0.40, 0.75, 0.85 }, -- ebon might / ammo slot
	[19] = { 0.20, 0.75, 0.85 }, -- essence
}

function ns.PowerColor(unit)
	local ok, t = pcall(UnitPowerType, unit)
	t = ok and ns.Plain(t)
	-- POWER_BAR_COLOR itself can be a secret table: index inside pcall
	local okC, c = pcall(function()
		local tab = POWER_BAR_COLOR or POWER_BAR_COLOR_NEW
		return t and tab and tab[t] or nil
	end)
	if okC and type(c) == "table" and not S.IsSecretTable(c) then
		if c.r then return c.r, c.g, c.b end
		return c[1], c[2], c[3]
	end
	local fb = POWER_FALLBACK[t] or POWER_FALLBACK[0]
	return fb[1], fb[2], fb[3]
end

-- r may be a secret number (hidden class): no boolean tests, no arithmetic.
-- Callers feed the triple straight to color setters.
local function HasColor(r)
	return (issecretvalue and issecretvalue(r)) or r ~= nil
end
ns.HasColor = HasColor

function ns.HealthColor(unit)
	local mode = ns.db.healthColorMode
	if mode == "STATIC" then return 0.30, 0.85, 0.35 end
	if mode == "REACTION" then
		local ok, friend = pcall(UnitIsFriend, "player", unit)
		if ok and ns.Plain(friend) and ns.UnitIsPlayer(unit) then
			local r, g, b = ns.ClassColor(unit)
			if HasColor(r) then return r, g, b end
		end
		return ns.ReactionColor(unit)
	end
	-- CLASS (default): players get class color, creatures get reaction color.
	-- A secret color means the class is hidden, which only happens for
	-- players, so it can be returned without the UnitIsPlayer question.
	local r, g, b = ns.ClassColor(unit)
	if issecretvalue and issecretvalue(r) then return r, g, b end
	if ns.UnitIsPlayer(unit) then
		if r ~= nil then return r, g, b end
		return 0.30, 0.85, 0.35
	end
	return ns.ReactionColor(unit)
end

-- status text ---------------------------------------------------------------------
function ns.StatusText(unit)
	local ok, dead = pcall(UnitIsDeadOrGhost, unit)
	if ok and ns.Plain(dead) then
		local okG, ghost = pcall(UnitIsGhost, unit)
		if okG and ns.Plain(ghost) then return L["Ghost"], 0.8, 0.8, 0.8 end
		return L["Dead"], 0.85, 0.3, 0.3
	end
	local okC, conn = pcall(UnitIsConnected, unit)
	-- only plainly-false counts: a secret connected flag read as nil
	-- and marked everyone offline
	if okC and ns.Plain(conn) == false then return L["Offline"], 0.6, 0.6, 0.6 end
	local okA, afk = pcall(UnitIsAFK, unit)
	if okA and ns.Plain(afk) then return L["AFK"], 0.9, 0.7, 0.2 end
	local okD, dnd = pcall(UnitIsDND, unit)
	if okD and ns.Plain(dnd) then return L["DND"], 0.9, 0.4, 0.2 end
end

-- statusbar -----------------------------------------------------------------------
function ns.Bar(parent, w, h)
	local b = CreateFrame("StatusBar", nil, parent)
	b:SetStatusBarTexture(BLANK)
	b:SetMinMaxValues(0, 1)
	b:SetValue(0)
	if w then b:SetSize(w, h or 10) end
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.65)
	b.bg = bg
	return b
end

-- clamp a secret-safe read to numbers (returns fallback on secret/nil)
function ns.Num(v, fallback)
	v = ns.Plain(v)
	return type(v) == "number" and v or fallback
end

-- percent text through the client's own percent APIs: they accept secret
-- values (reading them in Lua would throw) and return a 0-100 value.
function ns.Pct(unit, isPower)
	local fn = isPower and UnitPowerPercent or UnitHealthPercent
	if not fn then return nil end
	local scale = CurveConstants and CurveConstants.ScaleTo100
	local ok, v
	if isPower then
		ok, v = pcall(fn, unit, nil, false, scale)
	else
		ok, v = pcall(fn, unit, true, scale)
	end
	if not ok or v == nil then return nil end
	local ok2, s = pcall(format, "%d%%", v)
	return ok2 and s or nil
end

-- raw health/power values may be secret on this client: StatusBar widgets
-- take them as-is, but no Lua arithmetic is allowed on them. The optional
-- interpolation enum gives the fill its smooth ease-out animation.
function ns.SetBarValues(bar, cur, mx)
	local interp = (ns.db and ns.db.smoothBars)
		and Enum and Enum.StatusBarInterpolation
		and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
	if S.IsSecret(cur) or S.IsSecret(mx) then
		pcall(bar.SetMinMaxValues, bar, 0, mx)
		pcall(bar.SetValue, bar, cur, interp)
	elseif type(mx) == "number" and mx > 0 then
		bar:SetMinMaxValues(0, mx)
		bar:SetValue(type(cur) == "number" and cur or 0, interp)
	else
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(0, interp)
	end
end

-- rounded-aware edge border: with the generated ThreatGlow edgeFile the
-- whole ring (including the anti-aliased corners) is one backdrop edge,
-- recolored through SetBackdropBorderColor. Without media it falls back
-- square 1px edge ring for threat/target highlight on unit frames.
-- Four straight strips corner-to-corner, no arcs — consistent with
-- the nameplate look and immune to the pointed-chevron geometry bug.
function ns.EdgeGlow(f, size)
	local g = CreateFrame("Frame", nil, f)
	g:SetAllPoints()
	-- must be above the text-holder frame (f+8) and absorb/heal-pred bars (f+3)
	-- so the border strips are never covered by internal unit-frame layers
	g:SetFrameLevel(f:GetFrameLevel() + 10)
	local s = size or 2
	g.strips = {}
	local function mkStrip(p1, p2, horiz)
		local t = g:CreateTexture(nil, "OVERLAY")
		t:SetTexture(BLANK)
		t:SetPoint(p1)
		t:SetPoint(p2)
		if horiz then t:SetHeight(s) else t:SetWidth(s) end
		-- use array index, NOT p1 as key: "TOPLEFT" is shared by the top
		-- horizontal strip and the left vertical strip, so keying by p1
		-- silently overwrites the top strip with the left one, leaving only
		-- three sides colored while the top stays blank/white.
		g.strips[#g.strips + 1] = t
	end
	mkStrip("TOPLEFT",    "TOPRIGHT",    true)
	mkStrip("BOTTOMLEFT", "BOTTOMRIGHT", true)
	mkStrip("TOPLEFT",    "BOTTOMLEFT",  false)
	mkStrip("TOPRIGHT",   "BOTTOMRIGHT", false)
	function g:SetEdgeColor(cr, cg, cb, ca)
		self._col = { cr, cg, cb, ca or 1 }
		for _, t in pairs(self.strips) do
			t:SetVertexColor(cr, cg, cb, ca or 1)
		end
	end
	g:Hide()
	return g
end

-- event bus -----------------------------------------------------------------------
local bus = CreateFrame("Frame")
local buckets = {}
bus:SetScript("OnEvent", function(_, event, ...)
	local list = buckets[event]
	if not list then return end
	for i = 1, #list do S.SafeCall("uf:" .. event, list[i], event, ...) end
end)

function ns.RegisterBusEvent(event, fn)
	local list = buckets[event]
	if not list then
		list = {}
		buckets[event] = list
		pcall(bus.RegisterEvent, bus, event)
	end
	list[#list + 1] = fn
end

-- all spawned unit frames (single + group children), for global repaints
ns.frames = {}
ns.units = {} -- key -> frame (singles)

function ns.Repaint()
	for i = 1, #ns.frames do
		local f = ns.frames[i]
		if f.Refresh then S.SafeCall("uf:repaint", f.Refresh, f) end
	end
end

-- range alpha for group frames ----------------------------------------------------
-- UnitInRange can return a secret boolean on this client: comparing it
-- throws (and Plain() silently turned "secret" into always-in-range, so
-- the fade never fired). SetAlphaFromBoolean evaluates the secret on
-- the engine side instead - same trick SentiHeal uses.
function ns.ApplyRangeAlpha(b, outAlpha)
	local u = b.unit
	if not u then return end
	outAlpha = outAlpha or 0.55
	if UnitIsUnit(u, "player") then b:SetAlpha(1) return end
	local ok, inr, checked = pcall(UnitInRange, u)
	if ok and inr ~= nil then
		if S.IsSecret(inr) or S.IsSecret(checked) then
			if b.SetAlphaFromBoolean then
				pcall(b.SetAlphaFromBoolean, b, inr, 1, outAlpha)
			end
			return
		end
		-- "checked" false means the unit can't be ranged: treat as in range
		b:SetAlpha((inr or not checked) and 1 or outAlpha)
		return
	end
	local ok2, inRange = pcall(CheckInteractDistance, u, 4)
	b:SetAlpha((ok2 and ns.Plain(inRange)) and 1 or outAlpha)
end
