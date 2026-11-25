-- Extras: heal prediction, absorb overlay, class power pips, combat text,
-- boss/arena frames, phase/res/summon icons, party pets, threat percent.
-- Every client value goes through Plain()/pcall - health, absorb and
-- threat numbers can be secret on this client.
local _, ns = ...
local S = SentiUI
local L = ns.L
local Plain, CanAccess = ns.Plain, ns.CanAccess
local UF = ns.UF
local BLANK = S.media.blank

local max = math.max
local format = string.format
local CreateFrame = CreateFrame

local X = {}
ns.Extras = X

-- ===========================================================================
-- Heal prediction + absorb overlays (live inside the health bar stack)
-- ===========================================================================
local function BuildPredOverlays(f)
	-- incoming heal: lighter fill riding on the health fill
	local pred = CreateFrame("StatusBar", nil, f.Health)
	-- the media fill carries its own green; tinting it green again would
	-- double-darken - keep white and let the art show through
	local incTex = S.Tex and S.Tex("IncomingHeal")
	pred:SetStatusBarTexture(incTex or BLANK)
	if incTex then
		pred:SetStatusBarColor(1, 1, 1, 0.45)
	else
		pred:SetStatusBarColor(0.35, 0.85, 0.45, 0.45)
	end
	pred:SetAllPoints(f.Health)
	pred:SetFrameLevel(f.Health:GetFrameLevel() + 1)
	pred:Hide()
	f.HealPred = pred
	-- absorb shield: pale overlay on top of everything. AbsorbBar.tga is
	-- dark-based - multiplying it with the pale tint reads as a missing-
	-- health shadow instead of a shield, so the flat pale band stays
	local ab = CreateFrame("StatusBar", nil, f.Health)
	ab:SetStatusBarTexture(BLANK)
	ab:SetStatusBarColor(0.85, 0.85, 0.95, 0.35)
	ab:SetAllPoints(f.Health)
	ab:SetFrameLevel(f.Health:GetFrameLevel() + 2)
	ab:Hide()
	f.Absorb = ab
end

-- the prediction/absorb bands ride at the health fill's right edge:
-- anchoring them to the fill texture's TOPRIGHT appends the band where
-- the health ends (secret health keeps the engine-side texture position
-- readable) - same layout SentiHeal uses on this client
local function AnchorAfterFill(band, health)
	local tex = health.GetStatusBarTexture and health:GetStatusBarTexture()
	if not tex then return false end
	band:ClearAllPoints()
	band:SetPoint("TOPLEFT", tex, "TOPRIGHT")
	band:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT")
	return true
end

-- the band is anchored at the fill's right edge, so it only spans the
-- MISSING health: its minmax must be the deficit (UnitHealthMissing), not
-- UnitHealthMax - with max, the fill came out (max-cur)/max times too
-- small, shrinking every prediction to a sliver. The value may be
-- secret; it goes to the widget raw.
local function HealthMissing(unit)
	if UnitHealthMissing then
		local ok, m = pcall(UnitHealthMissing, unit)
		if ok and m ~= nil then return m end
	end
	local ok, m = pcall(UnitHealthMax, unit)
	return ok and m or 0
end

function X.UpdatePrediction(f)
	if not f.unit then return end
	local miss = HealthMissing(f.unit)
	if f.HealPred then
		local on = ns.db.healPredict ~= false
		local ok, inc = pcall(UnitGetIncomingHeals, f.unit)
		local plainMiss = Plain(miss)
		if on and ok and inc ~= nil and plainMiss ~= 0 then
			-- secret-safe: the amount is often secret - the widget takes
			-- it raw and a 0-length fill is invisible anyway
			local shown = pcall(function()
				if not AnchorAfterFill(f.HealPred, f.Health) then
					f.HealPred:SetAllPoints(f.Health)
				end
				f.HealPred:SetMinMaxValues(0, miss)
				f.HealPred:SetValue(inc)
			end)
			f.HealPred:SetShown(shown)
		else
			f.HealPred:Hide()
		end
	end
	if f.Absorb then
		local ok, ab = pcall(UnitGetTotalAbsorbs, f.unit)
		local plain = ok and Plain(ab)
		local show = type(plain) == "number" and plain > 0
		if ok and ab ~= nil and plain == nil then
			-- secret amount: feed the widget raw, a zero-length bar is invisible
			show = pcall(function()
				if not AnchorAfterFill(f.Absorb, f.Health) then
					f.Absorb:SetAllPoints(f.Health)
				end
				f.Absorb:SetMinMaxValues(0, miss)
				f.Absorb:SetValue(ab)
			end)
		elseif show then
			pcall(function()
				if not AnchorAfterFill(f.Absorb, f.Health) then
					f.Absorb:SetAllPoints(f.Health)
				end
				f.Absorb:SetMinMaxValues(0, miss)
				f.Absorb:SetValue(ab)
			end)
		end
		f.Absorb:SetShown(show == true)
	end
end

-- ===========================================================================
-- Class power pips (combo points, holy power, chi, shards, arcane, essence)
-- plus death knight runes (recharge fill per pip, not a UnitPower type)
-- ===========================================================================
local POWER_TYPES = Enum and Enum.PowerType and {
	Enum.PowerType.ComboPoints, Enum.PowerType.HolyPower, Enum.PowerType.Chi,
	Enum.PowerType.SoulShards, Enum.PowerType.ArcaneCharges,
	Enum.PowerType.Essence,
} or { 4, 9, 12, 7, 16, 19 }
local RUNE_COUNT = 6
local PIP_W, PIP_H, PIP_GAP = 20, 4, 3

local UpdateRunes -- fwd: the pip tick calls it

local function BuildClassPower(f)
	local h = CreateFrame("Frame", nil, f)
	h:SetHeight(PIP_H + 2)
	h:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 4)
	h:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 4)
	h.pips = {}
	for i = 1, 8 do
		local p = CreateFrame("StatusBar", nil, h)
		p:SetStatusBarTexture(BLANK)
		p:SetMinMaxValues(0, 1)
		p:SetValue(1)
		S.Template(p, "inset")
		p:Hide()
		h.pips[i] = p
	end
	h:Hide()
	-- runes recharge continuously: while any pip is charging a throttled
	-- tick repaints the fill (the flag is only ever set for death knights)
	h:SetScript("OnUpdate", function(self, dt)
		if not self._runes then return end
		self._t = (self._t or 0) + (dt or 0.016)
		if self._t < 0.1 then return end
		self._t = 0
		UpdateRunes(f, self)
	end)
	f.ClassPower = h
end

-- six pips, one per rune: full + accent when ready, dim fill climbing as
-- the rune recharges. GetRuneCooldown is pcall'd - values are usually
-- plain but nothing on this client is guaranteed
function UpdateRunes(f, h)
	if not GetRuneCooldown then h._runes = false h:Hide() return end
	local now, accent = GetTime(), S.colors.accent
	local total = math.min(RUNE_COUNT, #h.pips)
	local w = (f:GetWidth() - (total - 1) * PIP_GAP) / total
	local charging = false
	for i = 1, total do
		local p = h.pips[i]
		p:ClearAllPoints()
		p:SetPoint("LEFT", h, "LEFT", (i - 1) * (w + PIP_GAP), 0)
		p:SetSize(w, PIP_H)
		local frac = 1
		local ok, start, dur, ready = pcall(GetRuneCooldown, i)
		if ok and ready ~= true and type(start) == "number"
			and type(dur) == "number" and dur > 0 then
			frac = math.max(0, math.min((now - start) / dur, 1))
			charging = true
		end
		p:SetMinMaxValues(0, 1)
		p:SetValue(frac)
		local k = frac >= 1 and 1 or 0.45
		p:SetStatusBarColor(accent.r * k, accent.g * k, accent.b * k)
		p:Show()
	end
	for i = total + 1, #h.pips do h.pips[i]:Hide() end
	h._runes = charging
	h:Show()
end

local function ClassPowerType()
	for _, t in ipairs(POWER_TYPES) do
		local ok, mx = pcall(UnitPowerMax, "player", t)
		if ok and type(mx) == "number" and mx > 0 then
			return t, mx
		end
	end
end

function X.UpdateClassPower(f)
	local h = f.ClassPower
	if not h or f.unit ~= "player" then return end
	if ns.db.player and ns.db.player.classPower == false then h:Hide() return end
	-- death knights have no UnitPower resource - their six runes paint
	-- per-rune recharge fills instead of a count
	local okC, _, cls = pcall(UnitClass, "player")
	if okC and cls == "DEATHKNIGHT" then UpdateRunes(f, h) return end
	h._runes = false
	local pt, mx = ClassPowerType()
	if not pt then h:Hide() return end
	local ok, cur = pcall(UnitPower, "player", pt)
	cur = (ok and type(cur) == "number") and cur or 0
	local total = math.min(mx, #h.pips)
	local w = (f:GetWidth() - (total - 1) * PIP_GAP) / total
	for i = 1, total do
		local p = h.pips[i]
		p:ClearAllPoints()
		p:SetPoint("LEFT", h, "LEFT", (i - 1) * (w + PIP_GAP), 0)
		p:SetSize(w, PIP_H)
		p:SetStatusBarColor(S.colors.accent.r, S.colors.accent.g, S.colors.accent.b)
		p:SetShown(i <= cur)
	end
	for i = total + 1, #h.pips do h.pips[i]:Hide() end
	h:Show()
end

-- ===========================================================================
-- Combat text (damage/heal floaters rising out of the player frame)
-- ===========================================================================
local function BuildCombatText(f)
	local h = CreateFrame("Frame", nil, f)
	h:SetAllPoints(f.Health)
	h:SetFrameLevel(f:GetFrameLevel() + 12)
	h.pool = {}
	for i = 1, 6 do
		local fs = ns.Font(h, 12)
		fs:SetAlpha(0)
		h.pool[i] = fs
	end
	-- FontStrings cannot take scripts: animate the pool from the holder
	h.OnTick = function(self, dt)
		local any = false
		for i = 1, #self.pool do
			local fs = self.pool[i]
			if fs.live then
				any = true
				fs.t = fs.t + dt
				fs.off = fs.off + dt * 30
				fs:ClearAllPoints()
				fs:SetPoint("CENTER", self, "CENTER", 0, 8 + fs.off)
				if fs.t > 1.2 then
					fs:SetAlpha(max(0, 1 - (fs.t - 1.2) / 0.6))
				end
				if fs.t > 1.8 then fs.live = false fs:SetAlpha(0) end
			end
		end
		if not any then self:SetScript("OnUpdate", nil) end
	end
	f.CombatText = h
end

local ctIndex = 0
local function SpawnCT(f, text, r, g, b)
	local h = f.CombatText
	if not h then return end
	ctIndex = (ctIndex % #h.pool) + 1
	local fs = h.pool[ctIndex]
	fs:ClearAllPoints()
	fs:SetPoint("CENTER", h, "CENTER", 0, 8)
	pcall(fs.SetText, fs, text) -- text may be a secret value
	fs:SetTextColor(r, g, b)
	fs:SetAlpha(1)
	fs.off = 0
	fs.t = 0
	fs.live = true
	h:SetScript("OnUpdate", h.OnTick)
end

function X.CombatEvent(_, arg1, arg2, arg3)
	local f = ns.units and ns.units.player
	if not f or not f.CombatText or not f:IsShown() then return end
	if ns.db.player and ns.db.player.combatText == false then return end
	-- amounts can be secret numbers: concatenating throws, so decorate only
	-- when the value is plain, else hand the raw amount to the FontString
	local function Text(prefix, v)
		local p = Plain(v)
		if p ~= nil then return prefix .. tostring(p) end
		return v -- secret: FontString renders it raw
	end
	if arg1 == "DAMAGE" then
		SpawnCT(f, Text("-", arg2), 1, 0.35, 0.35)
	elseif arg1 == "HEAL" then
		SpawnCT(f, Text("+", arg2), 0.35, 0.9, 0.45)
	elseif arg1 == "MISS" or arg1 == "DODGE" or arg1 == "PARRY" or arg1 == "BLOCK" then
		SpawnCT(f, tostring(arg1), 0.8, 0.8, 0.8)
	elseif arg1 == "ENERGIZE" or arg1 == "PERIODIC_ENERGIZE" then
		SpawnCT(f, Text("+", arg3 or arg2), 0.4, 0.6, 1)
	elseif arg1 == "ABSORB" then
		SpawnCT(f, Text("", arg2), 0.9, 0.9, 1)
	end
end

-- ===========================================================================
-- Phase / resurrect / summon / offline indicators
-- ===========================================================================
-- small helper: the icon holder (textHolder exists after Build)
local function holder(f) return f.textHolder or f end

local function EnsureIcon(f, key, atlas, size)
	if f[key] then return f[key] end
	local t = holder(f):CreateTexture(nil, "OVERLAY")
	t:SetSize(size or 14, size or 14)
	if type(atlas) == "string" then t:SetTexture(atlas) end
	t:Hide()
	f[key] = t
	return t
end

function X.UpdateState(f)
	if not f.unit then return end
	-- phase icon: a secret return still means a reason exists -> out of phase
	local ph = EnsureIcon(f, "PhaseIcon", "Interface\\Icons\\Spell_Arcane_ManaTap", 13)
	local phased = false
	if UnitPhaseReason then
		local ok, r = pcall(UnitPhaseReason, f.unit)
		phased = ok and r ~= nil
	end
	ph:SetShown(phased)
	if phased then
		ph:ClearAllPoints()
		ph:SetPoint("CENTER", f, "CENTER", 0, 0)
	end
	-- incoming resurrection: secret means "yes" as well
	local res = EnsureIcon(f, "ResIcon", "Interface\\RaidFrame\\Raid-Icon-Rez", 16)
	local ok, r = pcall(UnitHasIncomingResurrection, f.unit)
	res:SetShown(ok and (Plain(r) == true or S.IsSecret(r) == true))
	if res:IsShown() then
		res:ClearAllPoints()
		res:SetPoint("CENTER", f, "CENTER", 0, 0)
	end
	-- incoming summon pending
	local sum = EnsureIcon(f, "SummonIcon", "Interface\\Icons\\Spell_Shadow_Twilight", 14)
	local pending = false
	if C_IncomingSummon and C_IncomingSummon.IncomingSummonStatus then
		local okS, st = pcall(C_IncomingSummon.IncomingSummonStatus, f.unit)
		if okS and st ~= nil then
			local p = Plain(st)
			pending = (type(p) == "number" and p > 0) or S.IsSecret(st) == true
		end
	end
	sum:SetShown(pending)
	if pending then
		sum:ClearAllPoints()
		sum:SetPoint("CENTER", f, "CENTER", 0, 0)
	end
	-- offline: dim the whole frame. ns.IsOffline double-checks via
	-- UnitIsVisible; the 3s hold catches the false reads the client hands
	-- out while a member is zoning
	local off = ns.IsOffline(f.unit)
	if off and not f._offline then
		f._offSince = f._offSince or GetTime()
		if GetTime() - f._offSince < 3 then off = false end
	else
		f._offSince = nil
	end
	if off ~= f._offline then
		f._offline = off
		if f.Health then f.Health:SetAlpha(off and 0.4 or 1) end
		if f.NameText then
			if off then
				f._nameOff = true
				f.NameText:SetText("|cff888888offline|r")
			elseif f._nameOff then
				-- restore the name: it stayed "offline" before
				f._nameOff = nil
				local okN, nm = pcall(UnitName, f.unit)
				if okN and type(nm) == "string" then f.NameText:SetText(nm) end
			end
		end
	end
end

-- ===========================================================================
-- Threat percentage on the target frame
-- ===========================================================================
function X.UpdateThreatPct(f)
	if f.unit ~= "target" or (f.db and f.db.threatPct == false) then
		if f.ThreatPct then f.ThreatPct:Hide() end
		return
	end
	if not f.ThreatPct then
		f.ThreatPct = ns.Font(holder(f), 9)
		f.ThreatPct:SetPoint("RIGHT", f, "BOTTOMRIGHT", -2, -1)
	end
	local ok, tanking, status, pct = pcall(UnitDetailedThreatSituation,
		"player", "target")
	local plain = ok and Plain(pct)
	if type(plain) == "number" and plain > 0 then
		local col = plain >= 100 and "|cffff4040" or plain >= 80 and "|cffffaa33" or "|cffdddddd"
		f.ThreatPct:SetFormattedText("%s%.0f%%|r", col, plain)
		f.ThreatPct:Show()
	elseif ok and pct ~= nil then
		-- secret percent: let the widget render it raw
		local shown = pcall(f.ThreatPct.SetFormattedText, f.ThreatPct,
			"%.0f%%", pct)
		f.ThreatPct:SetShown(shown)
	else
		f.ThreatPct:Hide()
	end
end

-- ===========================================================================
-- Boss + Arena frames (secure unit buttons, same build path as singles)
-- ===========================================================================
local arenaHolder, bossHolder

local function MakeGroupSet(prefix, count, key, title, cfg)
	local w, h = (cfg and cfg.w) or 160, (cfg and cfg.h) or 26
	local holder = CreateFrame("Frame", "SentiUI_UF_" .. key .. "Holder", UIParent,
		"SecureHandlerBaseTemplate")
	holder:SetSize(w, count * (h + 6))
	holder:SetFrameStrata("LOW")
	holder.buttons = {}
	for i = 1, count do
		local unit = prefix .. i
		local b = CreateFrame("Button", "SentiUI_UF_" .. key .. i, holder,
			"SecureUnitButtonTemplate")
		b:SetSize(w, h)
		b:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, -((i - 1) * (h + 6)))
		b:SetAttribute("unit", unit)
		b:SetAttribute("*type1", "target")
		b:SetAttribute("*type2", "togglemenu")
		b.unit = unit
		UF.Build(b, key, { w = w, h = h,
			power = not (cfg and cfg.power == false),
			auras = cfg and cfg.auras == true, castbar = true })
		b:SetScript("OnEvent", function(self, event, u, ...)
			UF.OnFrameEvent(self, event, u, ...)
		end)
		for ev in pairs(UF.basicEvents) do ns.RegisterUnitEvent(b, ev) end
		X.RegisterFrameEvents(b)
		RegisterStateDriver(b, "visibility",
			"[petbattle] hide; [@" .. unit .. ",exists] show; hide")
		UF.Configure(b) -- anchors/sizes the bars and texts (was never called)
		b:HookScript("OnShow", function(c)
			if c.unit then S.SafeCall("uf:show", UF.Refresh, c) end
		end)
		UF.Refresh(b)
		holder.buttons[i] = b
	end
	holder:SetShown(false)
	S.Movers.Register(holder, "uf." .. key, title, { x = 420, y = -80 })
	return holder
end

function X.CreateBossArena()
	local db = ns.db
	if db.boss and db.boss.enable ~= false then
		bossHolder = MakeGroupSet("boss", 5, "boss", L["Boss"], db.boss)
		RegisterStateDriver(bossHolder, "visibility", "[@boss1,exists] show; hide")
	end
	if db.arena and db.arena.enable ~= false then
		arenaHolder = MakeGroupSet("arena", 5, "arena", L["Arena"], db.arena)
		RegisterStateDriver(arenaHolder, "visibility", "[@arena1,exists] show; hide")
	end
end

-- ===========================================================================
-- Party pets: small secure buttons tucked under each party frame
-- ===========================================================================
function X.CreatePartyPets()
	local G = ns.Group
	if not G or not G.partyButtons then return end
	if ns.db.party and ns.db.party.showPets == false then return end
	for i, b in ipairs(G.partyButtons) do
		if i > 1 then -- player pet covered by the pet frame itself
			local pet = CreateFrame("Button", "SentiUI_UF_PartyPet" .. i, b,
				"SecureUnitButtonTemplate")
			pet:SetSize(b:GetWidth() * 0.5, 12)
			pet:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -1)
			pet:SetAttribute("unit", "partypet" .. (i - 1))
			pet:SetAttribute("*type1", "target")
			pet.unit = "partypet" .. (i - 1)
			UF.Build(pet, "partypet", { w = b:GetWidth() * 0.5, h = 12,
				power = false, auras = false })
			pet:SetScript("OnEvent", function(self, event, u, ...)
				UF.OnFrameEvent(self, event, u, ...)
			end)
			for ev in pairs(UF.basicEvents) do ns.RegisterUnitEvent(pet, ev) end
			-- engine-side hide when no pet: keeps the empty box from
			-- hanging under members without a companion
			RegisterStateDriver(pet, "visibility",
				"[petbattle] hide; [@" .. pet.unit .. ",exists] show; hide")
			UF.Configure(pet) -- anchors/sizes the bars and texts (was never called)
			pet:HookScript("OnShow", function(c)
				if c.unit then S.SafeCall("uf:petshow", UF.Refresh, c) end
			end)
			UF.Refresh(pet)
			b.PetButton = pet
		end
	end
end

-- ===========================================================================
-- Alternate power bar: replaces the parked PlayerPowerBarAlt. The engine
-- reports the encounter resource through power index ALTERNATE_POWER_INDEX;
-- values may be secret and go to the widget raw.
-- ===========================================================================
local altBar
local ALT_INDEX = ALTERNATE_POWER_INDEX or 10

local function AltBarInfo(unit)
	if GetUnitPowerBarInfo then
		local ok, info = pcall(GetUnitPowerBarInfo, unit)
		if ok and CanAccess(info) then return info end
	end
	if UnitPowerBarInfo then
		local ok, info = pcall(UnitPowerBarInfo, unit)
		if ok and CanAccess(info) then return info end
	end
end

function X.AltPowerActive()
	if ns.db.altPower == false then return false end
	if not UnitPowerMax then return false end
	local ok, mx = pcall(UnitPowerMax, "player", ALT_INDEX)
	if not ok or mx == nil then return false end
	if S.IsSecret(mx) then return true end -- secret max: a power bar is active
	return type(mx) == "number" and mx > 0
end

function X.UpdateAltPower()
	if not altBar then return end
	local info = AltBarInfo("player")
	local mx = info and Plain(info.maxPower) or nil
	local okM, mx2 = pcall(UnitPowerMax, "player", ALT_INDEX)
	if mx == nil then mx = okM and mx2 or nil end
	local okV, cur = pcall(UnitPower, "player", ALT_INDEX)
	pcall(function()
		altBar:SetMinMaxValues(0, mx)
		altBar:SetValue(okV and cur or 0)
	end)
	local name = info and Plain(info.name) or nil
	local pct = info and Plain(info.percentage) or nil
	if type(name) == "string" and type(pct) == "number" then
		altBar.label:SetText(format("%s  %.0f%%", name, pct * 100))
	elseif type(name) == "string" and name ~= "" then
		altBar.label:SetText(name)
	else
		altBar.label:SetText("")
	end
end

function X.CreateAltPower()
	if altBar then return end
	local holder = CreateFrame("Frame", "SentiUI_UF_AltPower", UIParent)
	holder:SetSize(220, 16)
	holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 260)
	S.Template(holder, "panel")
	local bar = ns.Bar(holder, 1, 1)
	bar:SetPoint("TOPLEFT", holder, "TOPLEFT", 3, -3)
	bar:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -3, 3)
	bar:SetStatusBarColor(0.25, 0.55, 1, 0.9)
	bar.label = ns.Font(holder, 10)
	bar.label:SetPoint("CENTER", bar, "CENTER")
	altBar = bar
	X.altHolder = holder
	holder:Hide()
	S.Movers.Register(holder, "uf.altpower", L["Alt power bar"], { x = 0, y = -160 })
	C_Timer.NewTicker(0.25, function()
		-- poll: UNIT_POWER events for the alt index do not fire reliably on
		-- this client; the ticker keeps secret max reads out of Lua math
		local has = X.AltPowerActive()
		holder:SetShown(has)
		if has then X.UpdateAltPower() end
	end)
end

-- ===========================================================================
-- wiring
-- ===========================================================================
-- ===========================================================================
-- Screen effects: a red vignette pulsing at the edges while health runs
-- low, a one-shot gold flash on level-ups, optional screenshots. Every
-- strip is a pre-built region - alpha animation is legal mid-fight and
-- nothing is ever created under lockdown
-- ===========================================================================
local lowGlow, flash

local function Vignette(parent, r, g, b)
	-- thin solid alarm lines hugging the screen borders - guaranteed to
	-- stay at the edge (gradient strips stretched across the whole screen
	-- on this client no matter how they were anchored)
	local SZ = 6
	local function edge(p1, p2, tall)
		local t = parent:CreateTexture(nil, "OVERLAY")
		t:SetColorTexture(r, g, b, 0.7)
		t:SetPoint(p1, parent, p1, 0, 0)
		t:SetPoint(p2, parent, p2, 0, 0)
		if tall then t:SetHeight(SZ) else t:SetWidth(SZ) end
		t:SetAlpha(0)
		return t
	end
	return {
		edge("TOPLEFT", "TOPRIGHT", true),
		edge("BOTTOMLEFT", "BOTTOMRIGHT", true),
		edge("TOPLEFT", "BOTTOMLEFT", false),
		edge("TOPRIGHT", "BOTTOMRIGHT", false),
	}
end

local function BuildScreenFX()
	if lowGlow then return end
	lowGlow = CreateFrame("Frame", "SentiUI_UF_LowHP", UIParent)
	lowGlow:SetAllPoints(UIParent)
	lowGlow:SetFrameStrata("FULLSCREEN")
	lowGlow.strips = Vignette(lowGlow, 1, 0.12, 0.12)
	lowGlow:SetScript("OnUpdate", function(self, dt)
		if not self.on then return end
		self.t = (self.t or 0) + (dt or 0.016)
		local a = 0.22 + 0.20 * math.sin(self.t * 5.5)
		for _, t in ipairs(self.strips) do t:SetAlpha(a) end
	end)

	flash = CreateFrame("Frame", "SentiUI_UF_Flash", UIParent)
	flash:SetAllPoints(UIParent)
	flash:SetFrameStrata("FULLSCREEN")
	flash.strips = Vignette(flash, 1, 0.75, 0.20)
	flash:SetScript("OnUpdate", function(self, dt)
		if not self.t then return end
		self.t = self.t + (dt or 0.016)
		local t, dur = self.t, 1.4
		if t >= dur then self.t = nil end
		local a = t < 0.25 and (t / 0.25)
			or math.max(0, 1 - (t - 0.25) / (dur - 0.25))
		for _, s in ipairs(self.strips) do s:SetAlpha(a * 0.9) end
	end)
end

function X.UpdateLowHP(f)
	if not lowGlow or f.unit ~= "player" then return end
	local on = false
	if ns.db.lowHP ~= false then
		local cur = Plain(UnitHealth("player"))
		local mx = Plain(UnitHealthMax("player"))
		local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
		on = (cur and mx and mx > 0 and not dead
			and cur / mx <= (ns.db.lowHPPct or 35) / 100) or false
	end
	lowGlow.on = on and true or false
end

ns.RegisterBusEvent("PLAYER_LEVEL_UP", function()
	if ns.db and ns.db.levelFlash ~= false and flash then
		flash.t = 0
	end
	if ns.db and ns.db.shotLevelUp == true and Screenshot then
		C_Timer.After(0.5, function() pcall(Screenshot) end)
	end
end)
ns.RegisterBusEvent("ACHIEVEMENT_EARNED", function()
	if ns.db and ns.db.shotAchieve == true and Screenshot then
		C_Timer.After(0.5, function() pcall(Screenshot) end)
	end
end)
ns.RegisterBusEvent("ENCOUNTER_END", function(_, _, _, _, success)
	local won = Plain(success)
	if won ~= 1 and won ~= true then return end
	if ns.db and ns.db.levelFlash ~= false and flash then flash.t = 0 end
	if ns.db and ns.db.shotBoss == true and Screenshot then
		C_Timer.After(0.5, function() pcall(Screenshot) end)
	end
end)

-- ===========================================================================
-- Cooldown tracker: interrupt + signature defensive icons under a member's
-- cell, driven by UNIT_SPELLCAST_SUCCEEDED on each cell - the combat log
-- can't be used: registering COMBAT_LOG_EVENT_UNFILTERED is a protected
-- call on this client (it was the UNKNOWN() forbidden call)
-- ===========================================================================
-- the pool is fixed at build time; db.cooldownMax only decides how many
-- of the pooled slots the allocator may use (icons cluster right either
-- way), so the option needs no reload
local CD_ICON, CD_GAP, CD_POOL = 12, 2, 8
-- spellID -> cooldown seconds. The interrupt set is complete-ish; the
-- defensive list keeps to signature buttons - an id the client lacks
-- simply never fires
local CD_SPELLS = {
	[1766]  = 15,  -- Kick
	[6552]  = 15,  -- Pummel
	[47528] = 15,  -- Mind Freeze
	[96231] = 15,  -- Rebuke
	[2139]  = 24,  -- Counterspell
	[19647] = 24,  -- Spell Lock (felhunter)
	[57994] = 12,  -- Wind Shear
	[106839]= 15,  -- Skull Bash
	[116705]= 15,  -- Spear Hand Strike
	[15487] = 45,  -- Silence
	[183752]= 15,  -- Disrupt
	[187707]= 15,  -- Muzzle
	[147362]= 24,  -- Counter Shot
	[351338]= 20,  -- Quell
	[78675] = 60,  -- Solar Beam
	[97547] = 60,  -- Solar Beam (other version)
	[642]   = 300, -- Divine Shield
	[1022]  = 300, -- Blessing of Protection
	[45438] = 240, -- Ice Block
	[47585] = 120, -- Dispersion
	[48792] = 180, -- Icebound Fortitude
	[871]   = 240, -- Shield Wall
	[118038]= 120, -- Die by the Sword
	[31224] = 120, -- Cloak of Shadows
	[5277]  = 120, -- Evasion
	[104773]= 180, -- Unending Resolve
	[22812] = 60,  -- Barkskin
	[61336] = 180, -- Survival Instincts
	[19236] = 90,  -- Desperate Prayer
	[109304]= 120, -- Exhilaration
	[115203]= 360, -- Fortifying Brew
	[198589]= 60,  -- Blur
	[196555]= 180, -- Netherwalk
	[108271]= 90,  -- Astral Shift
}

local function SpellTex(id)
	if C_Spell and C_Spell.GetSpellTexture then
		local ok, t = pcall(C_Spell.GetSpellTexture, id)
		if ok and t then return t end
	end
	if _G.GetSpellTexture then
		local ok, t = pcall(_G.GetSpellTexture, id)
		if ok and t then return t end
	end
end

-- the slots are POOLED at build time, never created later: a frame made
-- under combat lockdown is born protected on this client, so the first
-- interrupt cast mid-fight would have made every Show/SetPoint on the
-- slot fire ADDON_ACTION_FORBIDDEN. Runtime only touches regions
-- (SetTexture, SetText) and Show/Hide on the pooled frames - legal
-- mid-fight, same recipe the loot and quest feeds use
local function BuildCDRow(f)
	local h = CreateFrame("Frame", nil, f)
	h:SetSize(CD_POOL * (CD_ICON + CD_GAP), CD_ICON)
	-- under the cell's right edge: the external-defensive row owns the
	-- left corner below
	h:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -1, -1)
	h:SetFrameLevel(f:GetFrameLevel() + 4)
	h.slots = {}
	for i = 1, CD_POOL do
		local slot = CreateFrame("Frame", nil, h)
		slot:SetSize(CD_ICON, CD_ICON)
		slot:SetPoint("RIGHT", h, "RIGHT", -(i - 1) * (CD_ICON + CD_GAP), 0)
		local icon = slot:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints()
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		slot.icon = icon
		-- gold ready-glow, pulsed briefly when the cooldown comes back up
		local glow = slot:CreateTexture(nil, "OVERLAY", nil, 1)
		glow:SetTexture(BLANK)
		glow:SetBlendMode("ADD")
		glow:SetVertexColor(0.92, 0.68, 0.20, 0.9)
		glow:SetPoint("TOPLEFT", -1, 1)
		glow:SetPoint("BOTTOMRIGHT", 1, -1)
		glow:Hide()
		slot.glow = glow
		local cd = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
		cd:SetAllPoints()
		cd:SetDrawEdge(false)
		cd:SetHideCountdownNumbers(true)
		slot.cd = cd
		local t = slot:CreateFontString(nil, "OVERLAY")
		t:SetFont(S.media.font, 8, "OUTLINE")
		t:SetPoint("CENTER", 0, -1)
		slot.t = t
		slot:Hide()
		h.slots[i] = slot
	end
	-- seconds text is ours (the widget's own countdown may not draw here);
	-- one throttled sweep hides spent slots
	h:SetScript("OnUpdate", function(self, dt)
		self._t = (self._t or 0) + (dt or 0.016)
		if self._t < 0.2 then return end
		self._t = 0
		local now = GetTime()
		for i = 1, #self.slots do
			local slot = self.slots[i]
			if slot:IsShown() then
				if slot.ready then
					-- cooldown came back: ~0.8s gold pulse, then the slot
					-- retires instead of vanishing mid-glow
					local t2 = slot.ready - now
					if t2 <= 0 then
						slot.ready = nil
						slot.glow:Hide()
						slot:SetAlpha(1)
						slot:Hide()
					else
						local w = 0.6 + 0.4 * math.sin(t2 * 14)
						slot.glow:SetAlpha(w)
						slot:SetAlpha(0.7 + 0.3 * w)
					end
				else
					local left = (slot.ends or 0) - now
					if left <= 0 then
						slot.spell = nil
						slot.ready = now + 0.8
						slot.glow:Show()
					else
						slot.t:SetText(left >= 60
							and math.ceil(left / 60) .. "m" or math.ceil(left))
					end
				end
			end
		end
	end)
	f.CDRow = h
end

local function ShowCD(b, spellID, secs)
	local h = b.CDRow
	if not h then return end
	local limit = math.min(CD_POOL,
		(b.db and b.db.cooldownMax) or CD_POOL)
	-- a recast restarts its own slot; a new spell takes the first free one
	local slot
	for i = 1, limit do
		if h.slots[i].spell == spellID then slot = h.slots[i] break end
	end
	if not slot then
		for i = 1, limit do
			if not h.slots[i]:IsShown() then slot = h.slots[i] break end
		end
	end
	if not slot then return end
	slot.spell = spellID
	slot.ready = nil
	slot.glow:Hide()
	slot:SetAlpha(1)
	slot.icon:SetTexture(SpellTex(spellID) or BLANK)
	slot.ends = GetTime() + secs
	if CooldownFrame_Set then
		pcall(CooldownFrame_Set, slot.cd, GetTime(), secs)
	elseif slot.cd.SetCooldown then
		pcall(slot.cd.SetCooldown, slot.cd, GetTime(), secs)
	end
	slot:Show()
end

-- a tracked cast lands on the cell whose unit cast it - the event is
-- registered per frame through EXTRA_EVENTS below, no GUID mapping needed
local INTERRUPTS = {
	[1766]=1,[6552]=1,[47528]=1,[96231]=1,[2139]=1,[19647]=1,[57994]=1,
	[106839]=1,[116705]=1,[15487]=1,[183752]=1,[187707]=1,[147362]=1,
	[351338]=1,[78675]=1,[97547]=1,
}
local lastKick = 0

local function OnCastSucceeded(f, event, unit, castGUID, spellID)
	local id = Plain(spellID)
	local secs = id and CD_SPELLS[id]
	if secs then ShowCD(f, id, secs) end
	if f.unit == "player" and id and INTERRUPTS[id] then
		lastKick = GetTime()
	end
end

-- kick announce: the interrupt that lands on our target right after our
-- own kick cast is ours - attribute and post it to the party. Without
-- the combat log this correlation window is the only readable proof.
local kickPending
local function SendKick(msg)
	if InCombatLockdown() then
		if not kickPending then
			kickPending = msg
			C_Timer.After(0.5, function()
				local m = kickPending
				kickPending = nil
				if m and not InCombatLockdown() then SendKick(m) end
			end)
		end
		return
	end
	local ok = pcall(SendChatMessage, msg, "PARTY")
	if not ok and DEFAULT_CHAT_FRAME then
		pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, msg)
	end
end

local function OnCastInterrupted(f, event, unit, castGUID, spellID)
	if f.CastStrip then f.CastStrip:Hide() end
	if f.unit ~= "target" then return end
	if not ns.db or ns.db.kickAnnounce == false then return end
	if GetTime() - lastKick > 0.6 then return end
	lastKick = 0
	if not (IsInGroup and IsInGroup()) then return end
	local id = Plain(spellID)
	local name
	if id then
		if C_Spell and C_Spell.GetSpellName then
			local ok, v = pcall(C_Spell.GetSpellName, id)
			if ok and type(v) == "string" and v ~= "" then name = v end
		end
		if not name and GetSpellInfo then
			local ok, v = pcall(GetSpellInfo, id)
			if ok then name = v end
		end
	end
	SendKick(name and ("Unterbrochen: " .. name) or "Unterbrochen!")
end

-- ===========================================================================
-- Missing raid buff: a small gold "!" above a cell's left corner when a
-- buff your own class hands out is absent on that member. Ids resolve to
-- localized names once, auras match by name - so every rank of a buff
-- counts, and a secret name or missing API just never marks.
-- ===========================================================================
local BUFF_IDS = {
	PRIEST  = { 21562, 48168, 14752, 48074 }, -- Fortitude / Prayer / Spirit(s)
	MAGE    = { 1459, 23028, 27127 },         -- Intellect / Brilliance(s)
	DRUID   = { 1126, 21849, 988 },           -- Mark / Gift / Thorns
	WARRIOR = { 6673, 469 },                  -- Battle / Commanding Shout
	PALADIN = { 19740, 19742, 20217, 25782 }, -- Might / Wisdom / Kings / G.Kings
	SHAMAN  = { 131 },                        -- Water Breathing (thin, but it is ours)
}

local ownBuffs  -- false = "this class gives nothing", nil = not resolved yet
local function OwnBuffNames()
	if ownBuffs ~= nil then return ownBuffs end
	local ok, _, cls = pcall(UnitClass, "player")
	if not ok or type(cls) ~= "string" then return nil end
	local ids = BUFF_IDS[cls]
	if not ids then ownBuffs = false return ownBuffs end
	local names = {}
	for _, id in ipairs(ids) do
		local n
		if C_Spell and C_Spell.GetSpellName then
			local okN, v = pcall(C_Spell.GetSpellName, id)
			if okN then n = v end
		end
		if type(n) ~= "string" and GetSpellInfo then
			local okN, v = pcall(GetSpellInfo, id)
			if okN then n = v end
		end
		if type(n) == "string" and n ~= "" then names[n] = true end
	end
	ownBuffs = next(names) and names or false
	return ownBuffs
end

function X.UpdateMissingBuff(f)
	local mk = f.MissingBuff
	if not mk then return end
	local names = OwnBuffNames()
	if not names or not f.unit then mk:Hide() return end
	local now = GetTime()
	if f._mbT and now - f._mbT < 1 then return end -- aura scans walk 40 indexes
	f._mbT = now
	local dead = pcall(UnitIsDeadOrGhost, f.unit) and UnitIsDeadOrGhost(f.unit)
	if dead == true or not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then
		mk:Hide()
		return
	end
	local have = {}
	for i = 1, 40 do
		local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, f.unit, i, "HELPFUL")
		if not ok or not a then break end
		local okN, nm = pcall(function() return a.name end)
		if okN and type(nm) == "string" then have[nm] = true end
	end
	local missing = false
	for n in pairs(names) do
		if not have[n] then missing = true break end
	end
	mk:SetShown(missing)
end

-- ===========================================================================
-- Own-buff reminder: pulsing gold "!" on the player frame while a buff
-- your own class hands out is absent on yourself - plus a weapon-enchant
-- check for rogue/shaman (temporary enchants never fire UNIT_AURA on
-- their own here, so the check rides the missing-buff scan).
-- ===========================================================================
local WEAPON_BUFF = { ROGUE = true, SHAMAN = true }

function X.UpdateSelfBuff(f)
	local mk = f.SelfBuff
	if not mk then return end
	if ns.db.selfBuffWarn == false then mk:Hide() return end
	local names = OwnBuffNames()
	local okC, _, cls = pcall(UnitClass, "player")
	local wantWeapon = okC and type(cls) == "string" and WEAPON_BUFF[cls]
	if not names and not wantWeapon then mk:Hide() return end
	local now = GetTime()
	if f._sbT and now - f._sbT < 1 then return end
	f._sbT = now
	local have = {}
	if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
		for i = 1, 40 do
			local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex,
				"player", i, "HELPFUL")
			if not ok or not a then break end
			local okN, nm = pcall(function() return a.name end)
			if okN and type(nm) == "string" then have[nm] = true end
		end
	end
	local missing = false
	if names then
		for n in pairs(names) do
			if not have[n] then missing = true break end
		end
	end
	if not missing and wantWeapon and GetWeaponEnchantInfo then
		local okW, mh, _, _, oh = pcall(GetWeaponEnchantInfo)
		if okW and (mh == false or oh == false) then missing = true end
	end
	mk:SetShown(missing)
end

-- ===========================================================================
-- Durability warning: small gear icon at the player frame's bottom corner,
-- yellow once the worst piece drops under half, red under a quarter.
-- UPDATE_INVENTORY_DURABILITY is a global event - bus-registered, since
-- per-frame unit events would filter it out.
-- ===========================================================================
local DUR_SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 11, 16, 17 }
local playerFrame

function X.UpdateDurability(f)
	local ic = f.DurIcon
	if not ic then return end
	if ns.db.durWarn == false then ic:Hide() return end
	local worst = 100
	for _, slot in ipairs(DUR_SLOTS) do
		local ok, cur, mx = pcall(GetInventoryItemDurability, slot)
		if ok and type(cur) == "number" and type(mx) == "number"
			and mx > 0 and cur / mx * 100 < worst then
			worst = cur / mx * 100
		end
	end
	if worst >= 50 then ic:Hide() return end
	ic:SetVertexColor(1, worst < 25 and 0.25 or 0.8, 0.2)
	ic:Show()
end

ns.RegisterBusEvent("UPDATE_INVENTORY_DURABILITY", function()
	if playerFrame then X.UpdateDurability(playerFrame) end
end)

-- ===========================================================================
-- Cast strip: a 4px cast/channel bar under each group cell, driven by the
-- unit spellcast events that already reach every frame. Pooled at build
-- time like the CD slots - runtime only reads UnitCastingInfo and slides
-- the fill, so mid-combat creation never happens.
-- ===========================================================================
local function StripTick(self)
	local now = GetTime()
	local frac = (now - self.start) / math.max(self.ends - self.start, 0.01)
	if frac >= 1 or frac < 0 then self:Hide() return end
	self:SetValue(self.rev and (1 - frac) or frac)
end

local function OnCastStart(f, event)
	local cs = f.CastStrip
	if not cs then return end
	local chan = event == "UNIT_SPELLCAST_CHANNEL_START"
	local ok, _, _, _, st, en = pcall(
		chan and UnitChannelInfo or UnitCastingInfo, f.unit)
	st, en = ok and st, ok and en
	if not ok or type(en) ~= "number" or S.IsSecret(en)
		or S.IsSecret(st) then
		cs:Hide() return
	end
	cs.start, cs.ends, cs.rev = (st or 0) / 1000, en / 1000, chan
	cs:Show()
end

local function OnCastStop(f)
	if f.CastStrip then f.CastStrip:Hide() end
end

function X.Attach(f)
	-- called from UF.Build: extra bars/icons for frames that want them
	BuildPredOverlays(f)
	if f.key == "player" then
		BuildClassPower(f)
		BuildCombatText(f)
		BuildScreenFX()
		playerFrame = f
		local sb = f:CreateFontString(nil, "OVERLAY")
		sb:SetFont(S.media.font, 13, "OUTLINE")
		sb:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
		sb:SetText("!")
		sb:SetTextColor(0.92, 0.68, 0.20)
		sb:Hide()
		local pul = CreateFrame("Frame", nil, f)
		pul:SetScript("OnUpdate", function(self, dt)
			if not sb:IsShown() then return end
			self.t = (self.t or 0) + (dt or 0.016)
			sb:SetAlpha(0.45 + 0.45 * math.abs(math.sin(self.t * 4)))
		end)
		f.SelfBuff = sb
		local di = f:CreateTexture(nil, "OVERLAY")
		di:SetSize(12, 12)
		di:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
		di:SetTexture("Interface\\Icons\\Trade_BlackSmithing")
		di:Hide()
		f.DurIcon = di
	end
	if (f.key == "party" or f.key == "raid") and ns.db.partyCastbar ~= false then
		local cs = CreateFrame("StatusBar", nil, f)
		cs:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 1, -1)
		cs:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -1, -1)
		cs:SetHeight(4)
		cs:SetStatusBarTexture(BLANK)
		cs:SetStatusBarColor(0.92, 0.68, 0.20)
		cs:SetMinMaxValues(0, 1)
		cs:SetValue(0)
		cs:SetFrameLevel(f:GetFrameLevel() + 6)
		local bg = cs:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0, 0, 0, 0.6)
		cs:SetScript("OnUpdate", StripTick)
		cs:Hide()
		f.CastStrip = cs
	end
	if (f.key == "party" or f.key == "raid") and f.db
		and f.db.cooldownIcons ~= false then
		BuildCDRow(f)
	end
	if (f.key == "party" or f.key == "raid") and f.db
		and f.db.missingBuff then
		local mk = f:CreateFontString(nil, "OVERLAY")
		mk:SetFont(S.media.font, 11, "OUTLINE")
		mk:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 1, -2)
		mk:SetText("!")
		mk:SetTextColor(0.92, 0.68, 0.20)
		mk:Hide()
		f.MissingBuff = mk
	end
end

function X.Refresh(f)
	X.UpdatePrediction(f)
	X.UpdateState(f)
	X.UpdateThreatPct(f)
	if f.key == "player" then
		X.UpdateClassPower(f)
		X.UpdateLowHP(f)
		X.UpdateSelfBuff(f)
		X.UpdateDurability(f)
	end
	if f.MissingBuff then X.UpdateMissingBuff(f) end
end

local function OnHealth(f)
	X.UpdatePrediction(f)
	X.UpdateLowHP(f)
end

local EXTRA_EVENTS = {
	UNIT_POWER_UPDATE = X.UpdateClassPower, -- class pips ride the same event
	-- UNIT_HEAL_PREDICTION may never fire on this client - health events
	-- re-read the amounts instead (same trigger SentiHeal uses)
	UNIT_HEALTH = OnHealth,
	UNIT_HEALTH_FREQUENT = OnHealth,
	UNIT_MAXHEALTH = OnHealth,
	UNIT_HEAL_PREDICTION = X.UpdatePrediction,
	UNIT_ABSORB_AMOUNT_CHANGED = X.UpdatePrediction,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = X.UpdatePrediction,
	UNIT_POWER_POINT_CHARGE = X.UpdateClassPower,
	RUNE_POWER_UPDATE = X.UpdateClassPower,
	RUNE_TYPE_UPDATE = X.UpdateClassPower,
	UNIT_PHASE = X.UpdateState,
	INCOMING_RESURRECT_CHANGED = X.UpdateState,
	INCOMING_SUMMON_CHANGED = X.UpdateState,
	UNIT_THREAT_SITUATION_UPDATE = X.UpdateThreatPct,
	UNIT_THREAT_LIST_UPDATE = X.UpdateThreatPct,
	UNIT_SPELLCAST_SUCCEEDED = OnCastSucceeded,
	UNIT_SPELLCAST_INTERRUPTED = OnCastInterrupted,
	UNIT_SPELLCAST_START = OnCastStart,
	UNIT_SPELLCAST_CHANNEL_START = OnCastStart,
	UNIT_SPELLCAST_STOP = OnCastStop,
	UNIT_SPELLCAST_CHANNEL_STOP = OnCastStop,
	UNIT_SPELLCAST_FAILED = OnCastStop,
	UNIT_AURA = function(f)
		X.UpdateMissingBuff(f)
		if f.unit == "player" then X.UpdateSelfBuff(f) end
	end,
}

function X.OnFrameEvent(f, event, ...)
	local fn = EXTRA_EVENTS[event]
	if fn then S.SafeCall("ufx:" .. event, fn, f, event, ...) end
end

function X.RegisterFrameEvents(f)
	for ev in pairs(EXTRA_EVENTS) do ns.RegisterUnitEvent(f, ev) end
end
