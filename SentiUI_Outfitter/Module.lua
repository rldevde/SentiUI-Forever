-- Registration with the SentiUI core. The module's page appears under
-- "Outfitter" in the settings; settings land in SentiUIDB.modules.Outfitter.
-- A one-time import inside InitDB carries the standalone SentiOutfitterDB
-- over, so existing sets and positions survive the move.
local _, ns = ...

SentiUI:RegisterModule("Outfitter", {
	label = ns.L["Outfitter"],
	order = 135,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		ns.Outfitter.Boot(mod)
	end,
	OnSettingChanged = function(mod, path)
		ns.Outfitter.SettingChanged(path)
	end,
})
