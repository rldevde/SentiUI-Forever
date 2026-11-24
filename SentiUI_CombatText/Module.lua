-- Registration with the SentiUI core. The module's page appears as its own
-- "Combat Text" section in the settings; settings land in
-- SentiUIDB.modules.CombatText.
local _, ns = ...

SentiUI:RegisterModule("CombatText", {
	label = ns.L["Combat Text"],
	order = 130,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		ns.Core.Enable(mod)
	end,
	OnSettingChanged = function(mod, path) ns.Core.SettingChanged(mod, path) end,
})
