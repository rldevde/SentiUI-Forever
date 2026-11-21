-- Registration with the SentiUI core. Settings land in
-- SentiUIDB.modules.Character, options under their own "Character" page.
local _, ns = ...

SentiUI:RegisterModule("Character", {
	label = ns.L["Character"],
	order = 60,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	-- sibling modules reach our window through here instead of calling the
	-- game's Toggle* functions (those write client bookkeeping tainted)
	api = ns.C,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		ns.C.Enable(mod)
	end,
	OnSettingChanged = function(mod, path) ns.C.SettingChanged(mod, path) end,
})
