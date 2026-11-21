-- Registration with the SentiUI core. The module's pages appear as their own
-- "Minimap" section in the settings; settings land in SentiUIDB.modules.Minimap.
local _, ns = ...

SentiUI:RegisterModule("Minimap", {
	label = "Minimap",
	order = 100,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod) ns.Core.Enable(mod) end,
	OnSettingChanged = function(mod, path) ns.Core.SettingChanged(mod, path) end,
})
