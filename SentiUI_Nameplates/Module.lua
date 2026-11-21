-- Registration with the SentiUI core. The module's pages appear as their own
-- "Nameplates" section in the settings; settings land in
-- SentiUIDB.modules.Nameplates.
local _, ns = ...

local db
function ns.Cfg() return db or ns.DEFAULTS end

SentiUI:RegisterModule("Nameplates", {
	label = ns.L["Nameplates"],
	order = 160,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		db = mod.db
		if not db.enabled then return end
		ns.Manager.Enable()
	end,
	OnSettingChanged = function(mod, path)
		db = mod.db
		ns.Manager.SettingChanged(path)
	end,
})
