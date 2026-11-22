local addonName, ns = ...

-- SentiAccountInfoDB is account-wide: every character on this WoW account
-- reads and writes the same table, so characters see each other. Chars
-- merged in from other WoW accounts (SyncAccounts.py or import strings)
-- live in the same chars table, tagged with an `account` field.
--
-- ns.dbLoaded tells whether the client handed over saved data at all; a
-- known Forever beta bug sometimes skips loading it.

local DB_VERSION = 1

local function ApplyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			if type(value) == "table" then
				target[key] = {}
				ApplyDefaults(target[key], value)
			else
				target[key] = value
			end
		elseif type(value) == "table" and type(target[key]) == "table" then
			ApplyDefaults(target[key], value)
		end
	end
end

ns.dbDefaults = {
	version = DB_VERSION,
	chars = {},
}

local function OnAddonLoaded(event, name)
	if name ~= addonName then
		return
	end
	ns:UnregisterEvent(event, OnAddonLoaded)

	ns.dbLoaded = SentiAccountInfoDB ~= nil
	SentiAccountInfoDB = SentiAccountInfoDB or {}
	ApplyDefaults(SentiAccountInfoDB, ns.dbDefaults)
	ns.db = SentiAccountInfoDB

	ns:Fire("SAI_DB_READY")
end

ns:RegisterEvent("ADDON_LOADED", OnAddonLoaded)
