-- Single unit frames (player, target, target-of-target, pet, focus) and
-- the shared frame plumbing the group frames reuse: secure unit buttons,
-- health/power bars, texts, icons, threat + status. All Blizzard values go
-- through Plain() - unit data can be secret on this client.
local _, ns = ...
local S = SentiUI
local L = ns.L
local Plain = ns.Plain

local ipairs, pairs, type = ipairs, pairs, type
local format, floor = string.format, math.floor
local max = math.max
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip

local BLANK = "Interface\\Buttons\\WHITE8X8"

local UF = {}
ns.UF = UF
UF.polled = {}

-- per-frame event registration -------------------------------------------------
-- f:RegisterEvent + dispatch: unit events only fire when the arg unit matches.
-- Unknown events on this client (e.g. the deprecated *_FREQUENT variants)
-- are skipped instead of throwing.
function ns.RegisterUnitEvent(f, event)
	pcall(f.RegisterEvent, f, event)
end

local EVENT_TO_UPDATE = {
	UNIT_HEALTH = "Health", UNIT_HEALTH_FREQUENT = "Health",
	UNIT_MAXHEALTH = "Health",
	UNIT_POWER_UPDATE = "Power", UNIT_POWER_FREQUENT = "Power",
	UNIT_MAXPOWER = "Power", UNIT_DISPLAYPOWER = "Power",
	UNIT_NAME_UPDATE = "Name", UNIT_LEVEL = "Name", UNIT_FACTION = "Name",
	UNIT_CLASSIFICATION_CHANGED = "Name", UNIT_FLAGS = "Status",
	UNIT_AURA = "Auras", UNIT_THREAT_SITUATION_UPDATE = "Threat",
	UNIT_CONNECTION = "Status", PLAYER_FLAGS_CHANGED = "Status",
	UNIT_PORTRAIT_UPDATE = "Name", UNIT_MODEL_CHANGED = "Name",
	UNIT_SPELLCAST_START = "Cast", UNIT_SPELLCAST_DELAYED = "Cast",
	UNIT_SPELLCAST_CHANNEL_START = "Cast", UNIT_SPELLCAST_CHANNEL_UPDATE = "Cast",
	UNIT_SPELLCAST_INTERRUPTIBLE = "Cast", UNIT_SPELLCAST_NOT_INTERRUPTIBLE = "Cast",
	UNIT_SPELLCAST_STOP = "CastStop", UNIT_SPELLCAST_CHANNEL_STOP = "CastStop",
	UNIT_SPELLCAST_FAILED = "CastStop", UNIT_SPELLCAST_INTERRUPTED = "CastStop",
}
UF.basicEvents = EVENT_TO_UPDATE -- Extras.lua registers the same set on its frames

local function OnFrameEvent(f, event, unit, ...)
	-- cast events carry the unit as arg1; non-unit events (target/roster)
	-- update every frame that asks for them
	if unit and unit ~= f.unit and not UF.passAll[event] then return end
	local what = EVENT_TO_UPDATE[event]
	if what == "CastStop" then
		ns.CastBar.Stop(f)
	elseif what == "Cast" then
		ns.CastBar.Update(f)
	elseif what == "Auras" then
		ns.Auras.Update(f)
	elseif what and UF["Update" .. what] then
		UF["Update" .. what](f)
	end
	if ns.Extras and ns.Extras.OnFrameEvent then
		ns.Extras.OnFrameEvent(f, event)
	end
end
UF.OnFrameEvent = OnFrameEvent
UF.passAll = {} -- events that update frames regardless of their unit arg

local function RegisterBasicEvents(f)
	for ev in pairs(EVENT_TO_UPDATE) do ns.RegisterUnitEvent(f, ev) end
	if ns.Extras then ns.Extras.RegisterFrameEvents(f) end
	f:SetScript("OnEvent", function(self, event, unit, ...)
		OnFrameEvent(self, event, unit, ...)
	end)
end

-- updates ------------------------------------------------------------------------
function UF.UpdateHealth(f)
	local cur, mx = UnitHealth(f.unit), UnitHealthMax(f.unit)
	local secret = S.IsSecret(cur) or S.IsSecret(mx)
	ns.SetBarValues(f.Health, cur, mx)
	local r, g, b = ns.HealthColor(f.unit)
	-- r/g/b can be secret numbers for hidden classes: the setters resolve
	-- them, but the calls go through pcall in case the client refuses
	pcall(f.Health.SetStatusBarColor, f.Health, r, g, b)
	if f.Edge then pcall(f.Edge.SetVertexColor, f.Edge, r, g, b, 1) end
	local st, sr, sg, sb = ns.StatusText(f.unit)
	if st then
		f.HpText:SetFormattedText("|cff%02x%02x%02x%s|r", (sr or 1) * 255, (sg or 1) * 255, (sb or 1) * 255, st)
	elseif secret then
		-- secret values: only the engine percent read is safe - Lua arithmetic
		-- on them would throw (and %s prints the raw "mega number")
		f.HpText:SetText(ns.Pct(f.unit) or "")
	else
		local mode = ns.db.healthTextMode or "PERCENT"
		local pct = ns.Pct(f.unit)
		if mode == "VALUE" then
			f.HpText:SetText(ns.FmtNum(cur))
		elseif mode == "BOTH" then
			f.HpText:SetFormattedText("%s |cff%s%s|r", ns.FmtNum(cur), ns.dimHex, pct or "")
		else
			f.HpText:SetFormattedText("|cff%s%s|r", ns.dimHex, pct or "")
		end
	end
end

function UF.UpdatePower(f)
	if not f.Power or (f.db and f.db.power == false) then
		if f.Power then f.Power:Hide() end
		return
	end
	local cur, mx = UnitPower(f.unit), UnitPowerMax(f.unit)
	local secret = S.IsSecret(cur) or S.IsSecret(mx)
	if not secret and not (type(mx) == "number" and mx > 0) then
		f.Power:Hide()
		if f.PowText then f.PowText:Hide() end
		return
	end
	ns.SetBarValues(f.Power, cur, mx)
	local r, g, b = ns.PowerColor(f.unit)
	f.Power:SetStatusBarColor(r, g, b)
	f.Power:Show()
	if f.PowText then
		if secret then f.PowText:SetText(ns.Pct(f.unit, true) or "")
		else f.PowText:SetText(ns.FmtNum(cur)) end
	end
end

local function LevelText(unit)
	local ok, lv = pcall(UnitLevel, unit)
	lv = ok and Plain(lv)
	if not lv then return "" end
	if lv < 0 then return "|cffff4444??|r " end
	-- difficulty color like the game's own frames; falls back to plain
	-- light gray when the client keeps the answer secret
	local c = S.LevelColor(unit, lv)
	local r, g, b = 200, 200, 200
	if c then r, g, b = c.r * 255, c.g * 255, c.b * 255 end
	return format("|cff%02x%02x%02x%d|r ", r, g, b, lv)
end

-- utf8-aware name truncation (cuts after the last full character)
local function Utf8Trim(s, maxChars)
	local n, last = 0, 0
	for p in s:gmatch("[%z\1-\127\194-\244][\128-\191]*()") do
		n = n + 1
		if n > maxChars then break end
		last = p - 1
	end
	return s:sub(1, last)
end

function UF.UpdateName(f)
	local ok, name = pcall(UnitName, f.unit)
	name = ok and Plain(name) or ""
	if f.nameLen and #name > f.nameLen then
		name = Utf8Trim(name, f.nameLen)
	end
	local level = f.showLevel and LevelText(f.unit) or ""
	f.NameText:SetText(level .. name)
	-- class color on the name; secret rgb (hidden class) resolves in the
	-- setter - never boolean-test the values
	local r, g, b
	if ns.UnitIsPlayer(f.unit) then r, g, b = ns.ClassColor(f.unit) end
	if ns.HasColor(r) then
		pcall(f.NameText.SetTextColor, f.NameText, r, g, b)
	else
		f.NameText:SetTextColor(1, 1, 1)
	end
end

function UF.UpdateThreat(f)
	if not f.Threat then return end
	local ok, st = pcall(UnitThreatSituation, f.unit)
	st = ok and Plain(st) or 0
	if st >= 2 then
		f.Threat:SetBackdropBorderColor(1, st == 3 and 0.1 or 0.55, st == 3 and 0.1 or 0.1, 1)
		f.Threat:Show()
	else
		f.Threat:Hide()
	end
end

function UF.UpdateStatus(f)
	UF.UpdateHealth(f)
end

local ROLE_ICONS = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
local ROLE_TEXCOORDS = {
	TANK = { 0, 0.28125, 0.0227, 0.306 },
	HEALER = { 0.3125, 0.59375, 0.0227, 0.306 },
	DAMAGER = { 0.3125, 0.59375, 0.3203, 0.6016 },
}
ns.RoleIcons = ROLE_ICONS

-- assigned group role, secret-safe: try both client APIs, normalize the
-- token (casing + "DPS"/"DAMAGE" spellings) - secret or unassigned -> nil
local ROLE_ALIASES = { DPS = "DAMAGER", DAMAGE = "DAMAGER" }
local function RoleOf(unit)
	local role
	if UnitGroupRolesAssigned then
		local ok, r = pcall(UnitGroupRolesAssigned, unit)
		if ok then role = Plain(r) end
	end
	if type(role) ~= "string" and GetPartyAssignment then
		local ok, r = pcall(GetPartyAssignment, "LFGRole", unit)
		if ok then role = Plain(r) end
	end
	if type(role) ~= "string" then return end
	role = ROLE_ALIASES[string.upper(role)] or string.upper(role)
	return ROLE_TEXCOORDS[role] and role or nil
end

local RAID_ICON_COORDS = {
	[1] = { 0, 0.25, 0, 0.25 }, [2] = { 0.25, 0.5, 0, 0.25 },
	[3] = { 0.5, 0.75, 0, 0.25 }, [4] = { 0.75, 1, 0, 0.25 },
	[5] = { 0, 0.25, 0.25, 0.5 }, [6] = { 0.25, 0.5, 0.25, 0.5 },
	[7] = { 0.5, 0.75, 0.25, 0.5 }, [8] = { 0.75, 1, 0.25, 0.5 },
}

function UF.UpdateIcons(f)
	if f.RaidIcon then
		local ok, idx = pcall(GetRaidTargetIndex, f.unit)
		idx = ok and Plain(idx)
		local tc = idx and RAID_ICON_COORDS[idx]
		if tc then
			f.RaidIcon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
			f.RaidIcon:Show()
		else
			f.RaidIcon:Hide()
		end
	end
	if f.LeaderIcon then
		local ok, lead = pcall(UnitIsGroupLeader, f.unit)
		f.LeaderIcon:SetShown(ok and Plain(lead) or false)
	end
	if f.RoleIcon then
		local role = RoleOf(f.unit)
		local tc = (not f.db or f.db.showRole ~= false) and role and ROLE_TEXCOORDS[role]
		if tc then
			f.RoleIcon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
			f.RoleIcon:Show()
		else
			f.RoleIcon:Hide()
		end
	end
	if f.RestingIcon then
		local ok, r = pcall(IsResting)
		f.RestingIcon:SetShown(ok and Plain(r) or false)
	end
	if f.CombatIcon then
		local ok, c = pcall(UnitAffectingCombat, "player")
		f.CombatIcon:SetShown(ok and Plain(c) or false)
	end
end

-- ready check icon: ReadyCheckStatus
function UF.UpdateReadyCheck(f)
	if not f.ReadyCheck then return end
	local ok, st = pcall(GetReadyCheckStatus, f.unit)
	st = ok and Plain(st)
	if st == "ready" then
		f.ReadyCheck:SetText("|cff55ff55r|r")
	elseif st == "notready" then
		f.ReadyCheck:SetText("|cffff5555x|r")
	elseif st == "waiting" then
		f.ReadyCheck:SetText("|cffaaaaaa?|r")
	else
		f.ReadyCheck:SetText("")
	end
end

-- mouseover + tooltip -----------------------------------------------------------
local function OnEnter(f)
	if f.Highlight then f.Highlight:Show() end
	if UnitFrame_OnEnter then pcall(UnitFrame_OnEnter, f) end
end
local function OnLeave(f)
	if f.Highlight then f.Highlight:Hide() end
	if UnitFrame_OnLeave then pcall(UnitFrame_OnLeave, f) end
end

-- frame construction --------------------------------------------------------------
function UF.Build(f, key, db)
	f.key = key
	f.db = db
	f:RegisterForClicks("AnyUp")
	f:SetAttribute("*type1", "target")
	f:SetAttribute("*type2", "togglemenu")
	f:HookScript("OnEnter", OnEnter)
	f:HookScript("OnLeave", OnLeave)

	S.Template(f, "panel")
	local health = ns.Bar(f, 10, 10)
	health:SetFrameLevel(f:GetFrameLevel() + 1)
	f.Health = health
	-- Sentinel-style sheen: bright top edge fading down over the fill
	local gloss = health:CreateTexture(nil, "OVERLAY")
	gloss:SetAllPoints()
	gloss:SetTexture(BLANK)
	if CreateColor then
		gloss:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.14), CreateColor(1, 1, 1, 0))
	end
	local edge = health:CreateTexture(nil, "OVERLAY", nil, 2)
	edge:SetTexture(BLANK)
	edge:SetWidth(3)
	edge:SetPoint("TOPLEFT", health, "TOPLEFT")
	edge:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT")
	f.Edge = edge

	local power = ns.Bar(f, 10, 6)
	power:SetFrameLevel(f:GetFrameLevel() + 1)
	local pgloss = power:CreateTexture(nil, "OVERLAY")
	pgloss:SetAllPoints()
	pgloss:SetTexture(BLANK)
	if CreateColor then
		pgloss:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.12), CreateColor(1, 1, 1, 0))
	end
	f.Power = power

	local th = CreateFrame("Frame", nil, f)
	th:SetAllPoints()
	th:SetFrameLevel(f:GetFrameLevel() + 8)
	f.textHolder = th
	f.NameText = ns.Font(th, ns.db.fontSize)
	f.NameText:SetJustifyH("LEFT")
	f.NameText:SetWordWrap(false)
	f.HpText = ns.Font(th, ns.db.fontSize)
	f.HpText:SetJustifyH("RIGHT")
	f.PowText = ns.Font(th, 9)
	f.PowText:SetJustifyH("RIGHT")

	local hl = th:CreateTexture(nil, "OVERLAY")
	hl:SetAllPoints(health)
	hl:SetColorTexture(1, 1, 1, 0.06)
	hl:Hide()
	f.Highlight = hl

	f.RaidIcon = th:CreateTexture(nil, "OVERLAY")
	f.RaidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	f.RaidIcon:SetSize(14, 14)
	f.RaidIcon:Hide()

	f.LeaderIcon = th:CreateTexture(nil, "OVERLAY")
	f.LeaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
	f.LeaderIcon:SetSize(12, 12)
	f.LeaderIcon:SetPoint("CENTER", f, "TOPLEFT", 8, 0)
	f.LeaderIcon:Hide()

	local threat = CreateFrame("Frame", nil, f, "BackdropTemplate")
	threat:SetBackdrop({ edgeFile = BLANK, edgeSize = 2 })
	threat:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
	threat:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
	threat:SetFrameLevel(max(0, f:GetFrameLevel() - 1))
	threat:Hide()
	f.Threat = threat

	-- buffs above, debuffs below (only units that opt in get icon holders;
	-- raid/party keep the frame lean and use the dispel border instead)
	if db.auras == true then
		f.Buffs = ns.Auras.Create(f, "HELPFUL")
		f.Debuffs = ns.Auras.Create(f, "HARMFUL")
	end
	if db.castbar then
		ns.CastBar.Create(f)
	end
	if ns.Extras then ns.Extras.Attach(f) end

	f.Refresh = UF.Refresh
	ns.frames[#ns.frames + 1] = f
	return f
end

-- layout a frame from its unit db
function UF.Configure(f)
	local db = f.db
	if InCombatLockdown() then return S.RunOutOfCombat(UF.Configure, f) end
	f:SetSize(db.w, db.h)
	local powerH = db.power ~= false and 6 or 0
	f.Health:ClearAllPoints()
	f.Health:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
	f.Health:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, powerH > 0 and (powerH + 2) or 1)
	if powerH > 0 then
		-- power sits inside the frame, hugging the bottom edge
		f.Power:ClearAllPoints()
		f.Power:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
		f.Power:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
		f.Power:SetHeight(powerH)
		f.Power:Show()
	else
		f.Power:Hide()
	end
	-- texts live on the bars they describe, clear of the class-colored edge
	f.NameText:ClearAllPoints()
	f.NameText:SetPoint("LEFT", f.Health, "LEFT", 7, 0)
	f.NameText:SetPoint("RIGHT", f.HpText, "LEFT", -4, 0)
	f.HpText:ClearAllPoints()
	f.HpText:SetPoint("RIGHT", f.Health, "RIGHT", -5, 0)
	f.HpText:SetWidth(0)
	f.PowText:ClearAllPoints()
	f.PowText:SetPoint("RIGHT", f.Power, "RIGHT", -3, 0)
	f.PowText:SetShown(powerH > 0)
	if f.RaidIcon then
		f.RaidIcon:ClearAllPoints()
		f.RaidIcon:SetPoint("RIGHT", f, "TOPRIGHT", 0, 0)
	end
	if f.Buffs then ns.Auras.Layout(f, f.Buffs, "BOTTOMLEFT", "TOPLEFT", 0, 3) end
	if f.Debuffs then ns.Auras.Layout(f, f.Debuffs, "TOPLEFT", "BOTTOMLEFT", 0, -3) end
end

function UF.Refresh(f)
	if not f.unit then return end
	UF.UpdateHealth(f)
	UF.UpdatePower(f)
	UF.UpdateName(f)
	UF.UpdateThreat(f)
	UF.UpdateIcons(f)
	ns.Auras.Update(f)
	ns.CastBar.Update(f)
	if ns.Extras then ns.Extras.Refresh(f) end
end
UF.RefreshFrame = UF.Refresh

function UF.SetUnit(f, unit)
	f.unit = unit
	UF.Refresh(f)
end

-- singles --------------------------------------------------------------------------
local singles = {
	{ key = "player", unit = "player", title = L["Player"], pos = { x = -260, y = -320 } },
	{ key = "target", unit = "target", title = L["Target"], pos = { x = 260, y = -320 } },
	{ key = "tot", unit = "targettarget", title = L["Target of Target"], pos = { x = 380, y = -290 } },
	{ key = "pet", unit = "pet", title = L["Pet"], pos = { x = -380, y = -290 } },
	{ key = "focus", unit = "focus", title = L["Focus"], pos = { x = -260, y = -260 } },
}

function UF.CreateSingle(info)
	local db = ns.db[info.key]
	local f = CreateFrame("Button", "SentiUI_UF_" .. info.key, UIParent,
		"SecureUnitButtonTemplate")
	f:SetAttribute("unit", info.unit)
	if info.unit == "player" then f:SetAttribute("toggleForVehicle", true) end
	f:SetPoint("CENTER", UIParent, "CENTER", info.pos.x, info.pos.y)
	UF.Build(f, info.key, db)
	f.showLevel = info.key ~= "tot" and info.key ~= "pet"
	if info.key == "tot" or info.key == "pet" or info.key == "focus" then
		f.nameLen = 14
	end
	if info.key == "player" then
		local r = f.textHolder:CreateTexture(nil, "OVERLAY")
		r:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
		r:SetTexCoord(0, 0.5, 0, 0.421875)
		r:SetSize(20, 20)
		r:SetPoint("CENTER", f, "TOPLEFT", 0, 4)
		r:Hide()
		f.RestingIcon = r
		local c = f.textHolder:CreateTexture(nil, "OVERLAY")
		c:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
		c:SetTexCoord(0.5, 1, 0, 0.49)
		c:SetSize(20, 20)
		c:SetPoint("CENTER", f, "CENTER", 0, 0)
		c:Hide()
		f.CombatIcon = c
	end
	RegisterBasicEvents(f)
	UF.Configure(f)
	UF.SetUnit(f, info.unit)
	ns.units[info.key] = f
	S.Movers.Register(f, "uf." .. info.key, info.title, { x = info.pos.x, y = info.pos.y })
	UF.SetEnabled(f, db.enable)
	return f
end

function UF.SetEnabled(f, enabled)
	if InCombatLockdown() then return S.RunOutOfCombat(UF.SetEnabled, f, enabled) end
	if enabled then
		if f.unit == "player" then
			UnregisterUnitWatch(f)
			RegisterStateDriver(f, "visibility", "[petbattle] hide; show")
		else
			RegisterUnitWatch(f)
		end
	else
		UnregisterUnitWatch(f)
		RegisterStateDriver(f, "visibility", "hide")
	end
end

-- target-targeted updates are not reliable events: poll them
function UF.Poll()
	for _, f in ipairs(UF.polled) do
		if f:IsShown() then S.SafeCall("uf:poll", UF.Refresh, f) end
	end
end

function UF.Initialize()
	for _, info in ipairs(singles) do
		S.SafeCall("uf:single:" .. info.key, UF.CreateSingle, info)
	end
	-- polling for units without reliable events
	UF.polled = { ns.units.tot, ns.units.pet }
	local n = {}
	for _, f in ipairs(UF.polled) do if f then n[#n + 1] = f end end
	UF.polled = n
	C_Timer.NewTicker(0.5, UF.Poll)

	-- target/focus switches refresh their own frames
	for _, ev in ipairs({ "PLAYER_TARGET_CHANGED", "PLAYER_FOCUS_CHANGED", "PLAYER_ENTERING_WORLD" }) do
		ns.RegisterBusEvent(ev, function()
			for key, f in pairs(ns.units) do
				if f and f.Refresh then S.SafeCall("uf:evt:" .. key, f.Refresh, f) end
			end
		end)
	end
	-- raid icon marks change globally
	if ns.Extras then
		S.SafeCall("uf:bossarena", ns.Extras.CreateBossArena)
		ns.RegisterBusEvent("COMBAT_TEXT_UPDATE", function(ev, a, b, c)
			ns.Extras.CombatEvent(ev, a, b, c)
		end)
	end
	ns.RegisterBusEvent("RAID_TARGET_UPDATE", function()
		for _, f in ipairs(ns.frames) do S.SafeCall("uf:icon", UF.UpdateIcons, f) end
	end)
end
