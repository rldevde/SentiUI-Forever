-- Nameplate lifecycle: the driver still positions every nameplate, our
-- custom plate rides on it. The game's unit frame is parked under a hidden
-- parent (events quieted, cast bar too) so none of the game's plate code
-- draws under ours; its widgets (quest progress, soft target) move onto the
-- driver frame and stay visible. UpdateHitTestArea keeps unit clicks alive.
local _, ns = ...
local S = SentiUI

local Manager = {}
ns.Manager = Manager

local spare = {}
local hidden = CreateFrame("Frame")
hidden:Hide()
-- Blizzard scripts call layout methods on GetParent() - stub them
hidden.Layout = function() end
hidden.MarkDirty = function() end
hidden.SetNeedsLayout = function() end
hidden.UpdateLayout = function() end
hidden.IsLayoutFrame = function() return false end
local home = hidden -- spare plates also park here

Manager.byUnit = {} -- unit token -> our plate
local held = {}     -- parked game UnitFrame -> its nameplate

local function forbidden(f)
	if type(f) ~= "table" or not f.IsForbidden then return false end
	local ok, no = pcall(f.IsForbidden, f)
	if not ok then return true end -- the probe itself threw: do not touch
	-- the answer can be a secret boolean: the compare needs its own pcall,
	-- and an unreadable answer must not kill the attach (SetParent is
	-- pcall'd anyway - try it rather than leave the game's plate visible)
	local ok2, res = pcall(function() return no == true end)
	return ok2 and res == true
end

local function quiet(uf)
	if type(uf.UnregisterAllEvents) ~= "function" then return end
	pcall(uf.UnregisterAllEvents, uf)
	local cast = uf.castBar
	if type(cast) ~= "table" and type(uf.CastBarsContainer) == "table" then
		cast = uf.CastBarsContainer.castBar
	end
	if type(cast) == "table" and type(cast.UnregisterAllEvents) == "function"
		and not forbidden(cast) then
		pcall(cast.UnregisterAllEvents, cast)
	end
end

local function HideGameFrame(np)
	local uf = np.UnitFrame or np.unitFrame
	if type(uf) ~= "table" or not uf.SetParent or forbidden(uf) then return end
	held[uf] = np
	if uf:GetParent() ~= hidden then pcall(uf.SetParent, uf, hidden) end
	quiet(uf)
	for _, k in ipairs({ uf.WidgetContainer, uf.SoftTargetFrame }) do
		if type(k) == "table" and k.SetParent and not forbidden(k)
			and k:GetParent() ~= np then
			pcall(k.SetParent, k, np)
		end
	end
	if type(uf.UpdateHitTestArea) == "function"
		and type(NamePlateSetupOptions) == "table" then
		pcall(uf.UpdateHitTestArea, uf, NamePlateSetupOptions)
	end
end

local function Take()
	local p = table.remove(spare)
	if not p or forbidden(p) then
		p = ns.Plate.Create(home)
	end
	return p
end

local function Release(p)
	if forbidden(p) then return end
	ns.Cast.Stop(p)
	ns.Auras.Clear(p)
	if p.unit then Manager.byUnit[p.unit] = nil end
	p.unit, p.np, p.friendly, p._target = nil, nil, nil, nil
	p:Hide()
	p:ClearAllPoints()
	p:SetParent(home)
	spare[#spare + 1] = p
end

local function Attach(unit)
	local np = C_NamePlate and C_NamePlate.GetNamePlateForUnit
		and C_NamePlate.GetNamePlateForUnit(unit)
	if not np or forbidden(np) then return end
	local p = Manager.byUnit[unit]
	if p and p.np == np then return end -- already on this driver
	if p then Release(p) end
	HideGameFrame(np)
	p = Take()
	p.np, p.unit = np, unit
	p:SetParent(np)
	p:ClearAllPoints()
	p:SetPoint("CENTER", np, "CENTER", 0, 0)
	Manager.byUnit[unit] = p
	-- a plate update must never take the cast bar down with it
	S.SafeCall("plate:update", ns.Plate.Update, p)
	ns.Cast.Refresh(p)
end

local function Detach(unit)
	local p = Manager.byUnit[unit]
	if p then Release(p) end
end

-- every plate the driver currently shows
local function ScanAll()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	local ok, plates = pcall(C_NamePlate.GetNamePlates)
	if not ok or type(plates) ~= "table" then return end
	for _, np in ipairs(plates) do
		if not forbidden(np) then
			local unit = np.namePlateUnitToken
			if not unit then
				local uf = np.UnitFrame or np.unitFrame
				unit = uf and uf.unit
			end
			if type(unit) == "string" and not Manager.byUnit[unit] then
				Attach(unit)
			end
		end
	end
end

-- light refresh: volatile parts only (threat colors, target border)
local function RefreshAll()
	for _, p in pairs(Manager.byUnit) do
		S.SafeCall("plates:colors", ns.Plate.RefreshColors, p)
	end
end

local function AllPlates()
	for _, p in pairs(Manager.byUnit) do
		S.SafeCall("plates:update", ns.Plate.Update, p)
	end
end

local ticker, wired

function Manager.Enable()
	local db = ns.Cfg()
	-- the game CVars the module owns
	if C_CVar and C_CVar.SetCVar then
		pcall(C_CVar.SetCVar, "nameplateShowEnemies", db.cvarEnemies and 1 or 0)
		pcall(C_CVar.SetCVar, "nameplateShowFriends", db.cvarFriends and 1 or 0)
	end
	if wired then
		ScanAll()
		if not ticker then
			ticker = C_Timer.NewTicker(0.25, function()
				S.SafeCall("plates:tick", RefreshAll)
			end)
		end
		return
	end
	wired = true

	S.RegisterEvent("NAME_PLATE_UNIT_ADDED", function(_, unit)
		S.SafeCall("plates:add", Attach, unit)
	end)
	S.RegisterEvent("NAME_PLATE_UNIT_REMOVED", function(_, unit)
		S.SafeCall("plates:remove", Detach, unit)
	end)

	for _, ev in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH",
		"UNIT_NAME_UPDATE", "UNIT_FACTION", "UNIT_LEVEL" }) do
		S.RegisterEvent(ev, function(_, unit)
			local p = unit and Manager.byUnit[unit]
			if p then S.SafeCall("plates:update", ns.Plate.Update, p) end
		end)
	end
	S.RegisterEvent("UNIT_AURA", function(_, unit)
		local p = unit and Manager.byUnit[unit]
		if p then S.SafeCall("plates:auras", ns.Auras.Update, p) end
	end)

	for _, ev in ipairs({ "PLAYER_TARGET_CHANGED", "RAID_TARGET_UPDATE" }) do
		S.RegisterEvent(ev, function() S.SafeCall("plates:all", AllPlates) end)
	end
	for _, ev in ipairs({ "UNIT_THREAT_SITUATION_UPDATE",
		"UNIT_THREAT_LIST_UPDATE", "UNIT_FLAGS" }) do
		S.RegisterEvent(ev, function()
			S.SafeCall("plates:colors", RefreshAll)
		end)
	end
	for _, ev in ipairs({ "PLAYER_ROLES_ASSIGNED", "GROUP_ROSTER_UPDATE",
		"ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED",
		"PLAYER_ENTERING_WORLD" }) do
		S.RegisterEvent(ev, function()
			ns.Threat.Forget()
			S.SafeCall("plates:colors", RefreshAll)
		end)
	end
	S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
		S.SafeCall("plates:scan", ScanAll)
	end)

	ns.Cast.Register()

	-- threat events are unreliable on this client: a slow ticker is the
	-- driver, events only make updates feel instant
	ticker = C_Timer.NewTicker(0.25, function()
		S.SafeCall("plates:tick", RefreshAll)
	end)

	ScanAll()
end

function Manager.Disable()
	if ticker then ticker:Cancel() ticker = nil end
	local active = {}
	for _, p in pairs(Manager.byUnit) do active[#active + 1] = p end
	for _, p in ipairs(active) do Release(p) end
	-- give the game's frames back: reparent + rebuild their event set.
	-- The driver re-registers on the next hand-out anyway; this is a
	-- best-effort restore so plates are not blank until then.
	for uf, np in pairs(held) do
		if not forbidden(uf) and not forbidden(np) then
			pcall(uf.SetParent, uf, np)
			if type(CompactUnitFrame_UpdateUnitEvents) == "function" then
				pcall(CompactUnitFrame_UpdateUnitEvents, uf)
			end
		end
		held[uf] = nil
	end
end

-- /snptest dumps the live state of the plate on your target - attach,
-- parking, bar sizes and whether the engine cast API exists. The output
-- tells us exactly which layer is broken instead of guessing.
SLASH_SENTIUINPTEST1 = "/snptest"
SlashCmdList.SENTIUINPTEST = function()
	local function say(fmt, ...)
		DEFAULT_CHAT_FRAME:AddMessage("|cffebad33snp:|r " .. format(fmt, ...))
	end
	local n = 0
	for _ in pairs(Manager.byUnit) do n = n + 1 end
	say("attached plates: %d", n)
	local p = Manager.byUnit["target"]
	if not p then
		say("no plate on target (nameplates off? unit not shown?)")
		return
	end
	local np = p.np
	say("unit=%s friendly=%s attack=%s", tostring(p.unit),
		tostring(p.friendly), tostring(p.attack))
	say("plate shown=%s hpBox=%s shown=%s size=%sx%s",
		tostring(p:IsShown()), tostring(p.hpBox ~= nil),
		tostring(p.hpBox and p.hpBox:IsShown()),
		p.hpBox and tostring(p.hpBox:GetWidth()) or "?",
		p.hpBox and tostring(p.hpBox:GetHeight()) or "?")
	local okM, mn, mx = pcall(p.hp.GetMinMaxValues, p.hp)
	local okV, v = pcall(p.hp.GetValue, p.hp)
	say("hp minmax=%s/%s value=%s (readable=%s)",
		tostring(okM and mn), tostring(okM and mx),
		tostring(okV and v), tostring(not S.IsSecret(v)))
	local function sv(v)
		if S.IsSecret(v) then return "secret" end
		local ok, s = pcall(tostring, v)
		return ok and s or "?"
	end
	say("castBox shown=%s durAPI=%s durObj=%s",
		tostring(p.castBox and p.castBox:IsShown()),
		tostring(type(UnitCastingDuration)),
		sv(p.cast and p.cast.duration ~= nil))
	local okI, _, nm, _, st2, et2 = pcall(UnitCastingInfo, p.unit)
	say("castInfo ok=%s name=%s st=%s et=%s", sv(okI), sv(nm),
		sv(st2), sv(et2))
	local uf = np and (np.UnitFrame or np.unitFrame)
	say("blizzard uf=%s parked=%s forbidden=%s", tostring(uf ~= nil),
		tostring(uf and uf:GetParent() == hidden), tostring(uf and forbidden(uf)))
end

function Manager.SettingChanged(path)
	if path == "enabled" then
		if ns.Cfg().enabled then Manager.Enable() else Manager.Disable() end
		return
	end
	if path == "cvarEnemies" and C_CVar and C_CVar.SetCVar then
		pcall(C_CVar.SetCVar, "nameplateShowEnemies",
			ns.Cfg().cvarEnemies and 1 or 0)
		return
	end
	if path == "cvarFriends" and C_CVar and C_CVar.SetCVar then
		pcall(C_CVar.SetCVar, "nameplateShowFriends",
			ns.Cfg().cvarFriends and 1 or 0)
		return
	end
	AllPlates()
end
