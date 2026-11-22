-- Registration with the SentiUI core. The module appears as its own
-- "AccountInfo" section in the settings; the enable flag lands in
-- SentiUIDB.modules.AccountInfo. All character data lives in
-- SentiAccountInfoDB as before.
local _, ns = ...

SentiUI:RegisterModule("AccountInfo", {
	label = "AccountInfo",
	order = 140,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		if ns.booted then return end
		ns.booted = true
		ns.enabled = true
		-- every service file deferred its event/ticker/hook registration
		-- into this callback, so disabled modules stay completely inert
		ns:Fire("SAI_BOOT")
	end,
})
