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

-- class icon atlas (4x4 grid, 64px cells in a 256px sheet); the client's
-- own CLASS_ICON_TCOORDS wins when it exists, this table is the fallback.
-- Icons-Classes is used (proven to ship on this client via ElvUI) - the
-- newer CHARACTERCREATE atlas is not guaranteed to exist here.
local CLASS_ATLAS = "Interface\\WorldStateFrame\\Icons-Classes"
local CLASS_TCOORDS = {
	WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 },
	ROGUE = { 0.5, 0.75, 0, 0.25 }, DRUID = { 0.75, 1, 0, 0.25 },
	HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.5, 0.25, 0.5 },
	PRIEST = { 0.5, 0.75, 0.25, 0.5 }, WARLOCK = { 0.75, 1, 0.25, 0.5 },
	PALADIN = { 0, 0.25, 0.5, 0.75 }, DEATHKNIGHT = { 0.25, 0.5, 0.5, 0.75 },
	MONK = { 0.5, 0.75, 0.5, 0.75 }, DEMONHUNTER = { 0.75, 1, 0.5, 0.75 },
	EVOKER = { 0, 0.25, 0.75, 1 },
}

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
	UNIT_SPELLCAST_EMPOWER_START = "Cast", UNIT_SPELLCAST_EMPOWER_UPDATE = "Cast",
	UNIT_SPELLCAST_STOP = "CastStop", UNIT_SPELLCAST_CHANNEL_STOP = "CastStop",
	UNIT_SPELLCAST_EMPOWER_STOP = "CastStop",
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
		ns.Extras.OnFrameEvent(f, event, unit, ...)
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
	-- dim class colour by 12 % for a less saturated, more polished bar fill.
	-- Only applied to plain (non-secret) numbers; secret colours are passed
	-- through unchanged so the hidden-class path keeps working.
	if type(r) == "number" and type(g) == "number" and type(b) == "number"
		and not S.IsSecret(r) then
		r, g, b = r * 0.88, g * 0.88, b * 0.88
	end
	-- r/g/b can be secret numbers for hidden classes: the setters resolve
	-- them, but the calls go through pcall in case the client refuses
	pcall(f.Health.SetStatusBarColor, f.Health, r, g, b)
	if f.Edge then pcall(f.Edge.SetVertexColor, f.Edge, r, g, b, 1) end
	-- ambient tint: a whisper of the health color inside the bar's dark
	-- backdrop, secret-safe (arithmetic on a secret rgb would throw)
	if f.Health.bg and type(r) == "number" and type(g) == "number"
		and type(b) == "number" and not S.IsSecret(r) then
		f.Health.bg:SetColorTexture(r * 0.16, g * 0.16, b * 0.16, 0.55)
	elseif f.Health.bg then
		f.Health.bg:SetColorTexture(0, 0, 0, 0.55)
	end
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
	if f.Power.bg and type(r) == "number" and type(g) == "number"
		and type(b) == "number" and not S.IsSecret(r) then
		f.Power.bg:SetColorTexture(r * 0.14, g * 0.14, b * 0.14, 0.55)
	end
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
	-- UNIT_PORTRAIT_UPDATE/UNIT_MODEL_CHANGED map here: keep the tile fresh
	UF.UpdatePortrait(f)
end

function UF.UpdateThreat(f)
	if not f.Threat then return end
	local ok, st = pcall(UnitThreatSituation, f.unit)
	st = ok and Plain(st) or 0
	if st >= 2 then
		f.Threat:SetEdgeColor(1, st == 3 and 0.1 or 0.55, st == 3 and 0.1 or 0.1, 1)
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
-- generated per-role glyph files replace the atlas lookup when present
local ROLE_MEDIA = S.Tex and {
	TANK = S.Tex("RoleTank"),
	HEALER = S.Tex("RoleHeal"),
	DAMAGER = S.Tex("RoleDps"),
}
if ROLE_MEDIA and not (ROLE_MEDIA.TANK and ROLE_MEDIA.HEALER
	and ROLE_MEDIA.DAMAGER) then
	ROLE_MEDIA = nil
end

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
			if ROLE_MEDIA then
				f.RoleIcon:SetTexture(ROLE_MEDIA[role])
				f.RoleIcon:SetTexCoord(0, 1, 0, 1)
			else
				f.RoleIcon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
			end
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

-- optional portrait tile inside the frame's left edge: class icon for
-- players, the engine's 3D portrait (SetPortraitTexture) for creatures,
-- or for every unit in "model" mode. Built lazily in Configure so the
-- option can flip live; the health bar shifts right to make room.
local function EnsurePortrait(f)
	if f.Portrait then return end
	local ph = CreateFrame("Frame", nil, f)
	ph:SetFrameLevel(f:GetFrameLevel() + 2)
	local bg = ph:CreateTexture(nil, "BORDER")
	bg:SetAllPoints()
	bg:SetColorTexture(0.05, 0.06, 0.09, 0.92)
	ph.icon = ph:CreateTexture(nil, "ARTWORK")
	ph.icon:SetAllPoints()
	if S.IconRound then S.IconRound(ph, 3) end
	f.Portrait = ph
end

function UF.UpdatePortrait(f)
	local ph = f.Portrait
	if not ph or not ph:IsShown() or not f.unit then return end
	local mode = f.db and f.db.portrait or "off"
	if mode == "class" and ns.UnitIsPlayer(f.unit) then
		local cls = ns.ClassToken and ns.ClassToken(f.unit)
		local tc = cls and ((CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls])
			or CLASS_TCOORDS[cls])
		if tc then
			ph.icon:SetTexture(CLASS_ATLAS)
			ph.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
			return
		end
		-- secret/unknown class falls through to the engine portrait
	end
	if SetPortraitTexture then
		pcall(SetPortraitTexture, ph.icon, f.unit)
		ph.icon:SetTexCoord(0.15, 0.85, 0.15, 0.85)
	end
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

	-- player and target get the "raised" style: Sentinel gold border tint
	-- and the slightly lifted bgRaised background for visual prominence.
	-- All other frames (pet, focus, tot, party, raid) stay "panel" so they
	-- read as secondary / supporting information.
	local frameStyle = (key == "player" or key == "target") and "raised" or "panel"
	-- background colour used for CornerCut caps: must match the backdrop fill
	-- so the rounded bar ends blend into the panel instead of leaving a halo
	local bgC = (key == "player" or key == "target") and S.colors.bgRaised or S.colors.bg
	S.Template(f, frameStyle)
	-- player/target: boost the backdrop's gold border to 70 % alpha so it
	-- reads clearly against dark backgrounds. S.Template writes 45 % which
	-- suits secondary panels; primary frames need a bolder presence.
	-- Also update _suiBorderNorm so SetBorderLit restores the right value.
	if key == "player" or key == "target" then
		local ac = S.colors.accent
		pcall(f.SetBackdropBorderColor, f, ac.r, ac.g, ac.b, 0.70)
		f._suiBorderNorm = { ac.r, ac.g, ac.b, 0.70 }
	end
	local health = ns.Bar(f, 10, 10)
	health:SetFrameLevel(f:GetFrameLevel() + 1)
	f.Health = health
	-- Sentinel-style sheen: bright top edge fading down over the fill
	local gloss = health:CreateTexture(nil, "OVERLAY")
	gloss:SetAllPoints()
	gloss:SetTexture(BLANK)
	if CreateColor then
		gloss:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.20), CreateColor(1, 1, 1, 0))
	end
	local edge = health:CreateTexture(nil, "OVERLAY", nil, 2)
	edge:SetTexture(BLANK)
	edge:SetWidth(3)
	-- inset past the rounded corner arc so the blade ends on the
	-- straight edge instead of poking into the cut corner region
	edge:SetPoint("TOPLEFT", health, "TOPLEFT", 0, -4)
	edge:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 0, 4)
	f.Edge = edge
	-- programmatic rounded ends: CornerCut covers the bar's four corners
	-- with the frame background colour so the fill reads as a pill inside
	-- the dark panel rather than a hard-cornered block.
	-- Sublevel 3 sits above the gloss (0) so the dark cap hides any white
	-- gloss spill into the rounded corner area.
	if S.CornerCut then
		S.CornerCut(health, health, 3, bgC.r, bgC.g, bgC.b, bgC.a or 1, "OVERLAY", 3)
	end

	local power = ns.Bar(f, 10, 6)
	power:SetFrameLevel(f:GetFrameLevel() + 1)
	local pgloss = power:CreateTexture(nil, "OVERLAY")
	pgloss:SetAllPoints()
	pgloss:SetTexture(BLANK)
	if CreateColor then
		pgloss:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.16), CreateColor(1, 1, 1, 0))
	end
	f.Power = power
	-- rounded ends on the power bar (radius 2: bar is only 6–8 px tall)
	if S.CornerCut then
		S.CornerCut(power, power, 2, bgC.r, bgC.g, bgC.b, bgC.a or 1, "OVERLAY", 3)
	end

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
	f.LeaderIcon:SetTexture((S.Tex and S.Tex("LeaderIcon"))
		or "Interface\\GroupFrame\\UI-Group-LeaderIcon")
	f.LeaderIcon:SetSize(12, 12)
	f.LeaderIcon:SetPoint("CENTER", f, "TOPLEFT", 8, 0)
	f.LeaderIcon:Hide()

	-- threat edge follows the rounded silhouette instead of a square
	-- backdrop ring parked behind the frame
	f.Threat = ns.EdgeGlow(f, 2)

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
	-- powerH: per-frame override via db.powerH, falls back to 6 px
	local powerH = db.power ~= false and (db.powerH or 6) or 0
	-- portrait: square tile centered in the left edge, held back from the
	-- corner arcs so no square edge pokes through the rounded silhouette.
	-- health and power share one left edge right of it (flush).
	local barL = 1
	if db.portrait and db.portrait ~= "off" then
		EnsurePortrait(f)
		local pt = max(db.h - 6, 4)
		f.Portrait:SetSize(pt, pt)
		f.Portrait:ClearAllPoints()
		f.Portrait:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -3)
		f.Portrait:Show()
		-- Configure often runs after the frame's first Refresh (party
		-- layout, late-created raid children): paint the icon now, since
		-- unit events only call the partial updaters, never UpdatePortrait
		UF.UpdatePortrait(f)
		barL = 2 + pt + 2
		-- 1 px dark separator between portrait and the health/power bars
		if not f.PortraitSep then
			local sep = f:CreateTexture(nil, "OVERLAY", nil, 1)
			sep:SetTexture(BLANK)
			sep:SetWidth(1)
			sep:SetVertexColor(0.07, 0.08, 0.12, 0.90)
			f.PortraitSep = sep
		end
		f.PortraitSep:ClearAllPoints()
		f.PortraitSep:SetPoint("TOPLEFT",    f, "TOPLEFT", barL - 2, -3)
		f.PortraitSep:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", barL - 2, 3)
		f.PortraitSep:Show()
	elseif f.Portrait then
		f.Portrait:Hide()
		if f.PortraitSep then f.PortraitSep:Hide() end
	end
	barL = max(barL, 4)
	-- PillEdge backdrop has 3 px insets on every side; bars must start
	-- at least 4 px from each edge so they sit cleanly inside the fill
	-- area and do not bleed into the gold border region.
	-- Layout (h=34, powerH=8): 4 top + 17 health + 1 gap + 8 power + 4 bottom = 34
	f.Health:ClearAllPoints()
	f.Health:SetPoint("TOPLEFT", f, "TOPLEFT", barL, -4)
	f.Health:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, powerH > 0 and (powerH + 5) or 5)
	if powerH > 0 then
		f.Power:ClearAllPoints()
		f.Power:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", barL, 4)
		f.Power:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
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
	UF.UpdatePortrait(f)
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
		local restTex = S.Tex and S.Tex("RestingIcon")
		r:SetTexture(restTex or "Interface\\CharacterFrame\\UI-StateIcon")
		if not restTex then r:SetTexCoord(0, 0.5, 0, 0.421875) end
		r:SetSize(20, 20)
		r:SetPoint("CENTER", f, "TOPLEFT", 0, 4)
		r:Hide()
		f.RestingIcon = r
		local c = f.textHolder:CreateTexture(nil, "OVERLAY")
		local cbtTex = S.Tex and S.Tex("CombatIcon")
		c:SetTexture(cbtTex or "Interface\\CharacterFrame\\UI-StateIcon")
		if cbtTex then
			c:SetVertexColor(S.colors.red.r, S.colors.red.g, S.colors.red.b)
		else
			c:SetTexCoord(0.5, 1, 0, 0.49)
		end
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
	UnregisterUnitWatch(f)
	UnregisterStateDriver(f, "visibility")
	if enabled then
		if f.unit == "player" then
			RegisterStateDriver(f, "visibility", "[petbattle] hide; show")
		else
			-- unit-exists driver instead of RegisterUnitWatch: the engine
			-- flips it even in combat, the watch only ran post-combat
			RegisterStateDriver(f, "visibility",
				"[petbattle] hide; [@" .. f.unit .. ",exists] show; hide")
		end
	else
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
