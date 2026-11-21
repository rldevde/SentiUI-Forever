-- Registration with the SentiUI core. The module's page appears as its own
-- "Buffs" section in the settings; settings land in SentiUIDB.modules.Buffs.
local _, ns = ...

SentiUI:RegisterModule("Buffs", {
	label = ns.L["Buffs"],
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
