-- Registration with the SentiUI core.
local _, ns = ...

SentiUI:RegisterModule("UnitFrames", {
	label = ns.L["Unit Frames"],
	order = 140,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		-- one-time migration: VALUE is the new default; BOTH was the old
		-- system default and was never explicitly chosen by the user, so
		-- migrate it. PERCENT stays if the user explicitly picked it.
		if mod.db.healthTextMode == "BOTH" then
			mod.db.healthTextMode = "VALUE"
		end
		ns.db = mod.db
		ns.Blizzard.Apply()
		ns.UF.Initialize()
		ns.Group.Initialize()
		ns.RaidTools.Initialize()
		ns.Extras.CreateAltPower()
	end,
	OnSettingChanged = function(mod, path) ns.SettingChanged(mod, path) end,
})
