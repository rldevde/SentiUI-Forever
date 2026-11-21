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
		ns.db = mod.db
		ns.Blizzard.Apply()
		ns.UF.Initialize()
		ns.Group.Initialize()
	end,
	OnSettingChanged = function(mod, path) ns.SettingChanged(mod, path) end,
})
