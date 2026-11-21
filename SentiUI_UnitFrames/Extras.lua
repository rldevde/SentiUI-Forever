-- Extras: heal prediction, absorb overlay, class power pips, combat text,
-- boss/arena frames, phase/res/summon icons, party pets, threat percent.
-- Every client value goes through Plain()/pcall - health, absorb and
-- threat numbers can be secret on this client.
local _, ns = ...
local S = SentiUI
local L = ns.L
local Plain = ns.Plain
local UF = ns.UF
local BLANK = S.media.blank

local max = math.max
local CreateFrame = CreateFrame

local X = {}
ns.Extras = X

-- ===========================================================================
-- Heal prediction + absorb overlays (live inside the health bar stack)
-- ===========================================================================
local function BuildPredOverlays(f)
	-- incoming heal: lighter fill riding on the health fill
	local pred = CreateFrame("StatusBar", nil, f.Health)
	pred:SetStatusBarTexture(BLANK)
	pred:SetStatusBarColor(0.35, 0.85, 0.45, 0.45)
	pred:SetAllPoints(f.Health)
	pred:SetFrameLevel(f.Health:GetFrameLevel() + 1)
	pred:Hide()
	f.HealPred = pred
	-- absorb shield: pale overlay on top of everything
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

function X.UpdatePrediction(f)
	if not f.unit then return end
	if f.HealPred then
		local on = ns.db.healPredict ~= false
		local ok, inc = pcall(UnitGetIncomingHeals, f.unit)
		if on and ok and inc ~= nil then
			-- secret-safe: the amount is often secret - the widget takes
			-- it raw and a 0-length fill is invisible anyway
			local shown = pcall(function()
				if not AnchorAfterFill(f.HealPred, f.Health) then
					f.HealPred:SetAllPoints(f.Health)
				end
				f.HealPred:SetMinMaxValues(0, UnitHealthMax(f.unit))
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
				f.Absorb:SetMinMaxValues(0, UnitHealthMax(f.unit))
				f.Absorb:SetValue(ab)
			end)
		elseif show then
			pcall(function()
				if not AnchorAfterFill(f.Absorb, f.Health) then
					f.Absorb:SetAllPoints(f.Health)
				end
				f.Absorb:SetMinMaxValues(0, UnitHealthMax(f.unit))
				f.Absorb:SetValue(ab)
			end)
		end
		f.Absorb:SetShown(show == true)
	end
end

-- ===========================================================================
-- Class power pips (combo points, holy power, chi, shards, arcane, essence)
-- ===========================================================================
local POWER_TYPES = Enum and Enum.PowerType and {
	Enum.PowerType.ComboPoints, Enum.PowerType.HolyPower, Enum.PowerType.Chi,
	Enum.PowerType.SoulShards, Enum.PowerType.ArcaneCharges,
	Enum.PowerType.Essence,
} or { 4, 9, 12, 7, 16, 19 }
local PIP_W, PIP_H, PIP_GAP = 20, 4, 3

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
	f.ClassPower = h
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
	-- offline: dim the whole frame
	local okC, con = pcall(UnitIsConnected, f.unit)
	local off = okC and ns.Plain(con) == false
	if off ~= f._offline then
		f._offline = off
		if f.Health then f.Health:SetAlpha(off and 0.4 or 1) end
		if f.NameText and off then f.NameText:SetText("|cff888888offline|r") end
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
		RegisterUnitWatch(b)
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
			RegisterUnitWatch(pet)
			UF.Refresh(pet)
			b.PetButton = pet
		end
	end
end

-- ===========================================================================
-- wiring
-- ===========================================================================
function X.Attach(f)
	-- called from UF.Build: extra bars/icons for frames that want them
	BuildPredOverlays(f)
	if f.key == "player" then
		BuildClassPower(f)
		BuildCombatText(f)
	end
end

function X.Refresh(f)
	X.UpdatePrediction(f)
	X.UpdateState(f)
	X.UpdateThreatPct(f)
	if f.key == "player" then X.UpdateClassPower(f) end
end

local EXTRA_EVENTS = {
	UNIT_POWER_UPDATE = X.UpdateClassPower, -- class pips ride the same event
	-- UNIT_HEAL_PREDICTION may never fire on this client - health events
	-- re-read the amounts instead (same trigger SentiHeal uses)
	UNIT_HEALTH = X.UpdatePrediction,
	UNIT_HEALTH_FREQUENT = X.UpdatePrediction,
	UNIT_MAXHEALTH = X.UpdatePrediction,
	UNIT_HEAL_PREDICTION = X.UpdatePrediction,
	UNIT_ABSORB_AMOUNT_CHANGED = X.UpdatePrediction,
	UNIT_HEAL_ABSORB_AMOUNT_CHANGED = X.UpdatePrediction,
	UNIT_POWER_POINT_CHARGE = X.UpdateClassPower,
	UNIT_PHASE = X.UpdateState,
	INCOMING_RESURRECT_CHANGED = X.UpdateState,
	INCOMING_SUMMON_CHANGED = X.UpdateState,
	UNIT_THREAT_SITUATION_UPDATE = X.UpdateThreatPct,
	UNIT_THREAT_LIST_UPDATE = X.UpdateThreatPct,
}

function X.OnFrameEvent(f, event)
	local fn = EXTRA_EVENTS[event]
	if fn then S.SafeCall("ufx:" .. event, fn, f) end
end

function X.RegisterFrameEvents(f)
	for ev in pairs(EXTRA_EVENTS) do ns.RegisterUnitEvent(f, ev) end
end
