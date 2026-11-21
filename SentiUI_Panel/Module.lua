-- Registration with the SentiUI core. The module's pages appear as their
-- own "Panel" section in the settings; settings land in
-- SentiUIDB.modules.Panel.
local _, ns = ...

SentiUI:RegisterModule("Panel", {
	label = ns.L["Panel"],
	order = 130,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		ns.CoreEnable(mod)
	end,
	OnSettingChanged = function(mod, path) ns.SettingChanged(mod, path) end,
})
