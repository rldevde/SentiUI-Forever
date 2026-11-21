-- Registration with the SentiUI core. The module's pages appear as their own
-- "Loot" section in the settings; settings land in SentiUIDB.modules.Loot.
local _, ns = ...

SentiUI:RegisterModule("Loot", {
	label = ns.L["Loot"],
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
