-- Registration with the SentiUI core. The module's pages appear as their own
-- "Data Bars" section in the settings; settings land in SentiUIDB.modules.DataBars.
local _, ns = ...

SentiUI:RegisterModule("DataBars", {
	label = ns.L["Data Bars"],
	order = 120,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		ns.Core.Enable(mod)
	end,
	OnSettingChanged = function(mod, path) ns.Core.SettingChanged(mod, path) end,
})
