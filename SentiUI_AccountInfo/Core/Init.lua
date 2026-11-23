-- luacheck: read globals GetNormalizedRealmName UnitFullName C_AddOns C_Timer
-- luacheck: read globals CreateFrame DEFAULT_CHAT_FRAME InCombatLockdown issecretvalue
local addonName, ns = ...

ns.name = addonName
ns.title = "SentiUI AccountInfo"
ns.shortTitle = "SAI"
ns.color = "ebad33"
-- set true by Module.lua's OnEnable; service events only register after
-- the SAI_BOOT callback fires, so a disabled module stays fully inert
ns.enabled = false

local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local version = getMetadata and getMetadata(addonName, "Version")
if not version or version:find("@project%-version@") then
	version = ns.L.UNKNOWN_VERSION
end
ns.version = version

-- Public handle, mainly for debugging and the panel plugin.
_G.SentiUI_AccountInfo = ns
_G.SentiAccountInfo = ns -- legacy alias, the panel and old strings use it

--------------------------------------------------------------------------------
-- Sentinel-style helpers
--------------------------------------------------------------------------------

-- pcall wrapper that logs errors with a context tag.
function ns.SafeCall(context, func, ...)
	local ok, err = pcall(func, ...)
	if not ok then
		ns:Print("|cffff5555%s: %s|r", tostring(context or "?"), tostring(err))
	end
	return ok, err
end

function ns.IsSecret(v)
	return issecretvalue and issecretvalue(v) or false
end

function ns.CanAccessTable(t)
	return type(t) == "table" and (not canaccesstable or canaccesstable(t))
end

-- Returns v unchanged when it is not a secret, nil otherwise.
function ns.Plain(v)
	if ns.IsSecret(v) then
		return nil
	end
	return v
end

-- Frame ops that must not run in combat go through this queue.
local combatQueue = {}
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function()
	local list = combatQueue
	combatQueue = {}
	for _, entry in ipairs(list) do
		ns.SafeCall("RunOutOfCombat", entry.fn, unpack(entry.args, 1, entry.n))
	end
end)

function ns:RunOutOfCombat(func, ...)
	if not InCombatLockdown() then
		return func(...)
	end
	local n = select("#", ...)
	combatQueue[#combatQueue + 1] = { fn = func, args = { ... }, n = n }
end

-- Timer helpers: After(seconds, fn), Every(seconds, fn) → handle with
-- :Cancel(); CancelTimer(handle).
function ns:After(seconds, func)
	return C_Timer.NewTimer(seconds, func)
end

function ns:Every(seconds, func)
	return C_Timer.NewTicker(seconds, func)
end

function ns:CancelTimer(handle)
	if handle then
		handle:Cancel()
	end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------
-- Game events go to plain callbacks; several files may listen to the same
-- event. Internal messages between files use the callback registry below:
--   ns.RegisterCallback(owner, "SAI_SOMETHING", func)  /  ns:Fire("SAI_SOMETHING", ...)

local eventFrame = CreateFrame("Frame")
local eventCallbacks = {}

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = eventCallbacks[event]
	if not list then
		return
	end
	-- Iterate over a snapshot so callbacks may unregister themselves.
	-- pcall each handler: a throwing scan must not silence later handlers.
	local snapshot = { unpack(list) }
	for i = 1, #snapshot do
		local ok, err = pcall(snapshot[i], event, ...)
		if not ok then
			ns:Print("event %s handler error: %s", tostring(event), tostring(err))
		end
	end
end)

function ns:RegisterEvent(event, callback)
	-- Some client flavours drop events (PLAYERBANKBAGSLOTS_CHANGED etc.);
	-- registering them throws "unknown event" - validate first.
	if C_EventUtils and C_EventUtils.IsEventValid
		and not C_EventUtils.IsEventValid(event) then
		return
	end
	local list = eventCallbacks[event]
	if not list then
		list = {}
		eventCallbacks[event] = list
		eventFrame:RegisterEvent(event)
	end
	list[#list + 1] = callback
end

function ns:UnregisterEvent(event, callback)
	local list = eventCallbacks[event]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i] == callback then
			table.remove(list, i)
		end
	end
	if #list == 0 then
		eventCallbacks[event] = nil
		eventFrame:UnregisterEvent(event)
	end
end

--------------------------------------------------------------------------------
-- Callbacks (own event registry, CallbackHandler-style signatures)
--------------------------------------------------------------------------------
-- ns.RegisterCallback(owner, "SAI_EVENT", func) — the callback is invoked
-- as func(event, ...): handlers declare a leading "_" for the event name
-- and read their payload from the remaining arguments.

local callbackRegistry = {}

function ns.RegisterCallback(owner, event, func)
	local list = callbackRegistry[event]
	if not list then
		list = {}
		callbackRegistry[event] = list
	end
	list[#list + 1] = { owner = owner, func = func }
end

-- UnregisterCallback(owner [, event]) drops all of owner's callbacks, or
-- only those for one event.
function ns.UnregisterCallback(owner, event)
	if event then
		local list = callbackRegistry[event]
		if list then
			for i = #list, 1, -1 do
				if list[i].owner == owner then
					table.remove(list, i)
				end
			end
		end
		return
	end
	for _, list in pairs(callbackRegistry) do
		for i = #list, 1, -1 do
			if list[i].owner == owner then
				table.remove(list, i)
			end
		end
	end
end

function ns:Fire(event, ...)
	local list = callbackRegistry[event]
	if not list then
		return
	end
	-- Snapshot: callbacks may unregister themselves while iterating.
	-- Each callback is pcall'd: one bad listener must not keep the rest
	-- (e.g. the scanner's SAI_BOOT hook) from running.
	local snapshot = { unpack(list) }
	for i = 1, #snapshot do
		local ok, err = pcall(snapshot[i].func, event, ...)
		if not ok then
			ns:Print("callback error on %s: %s", tostring(event), tostring(err))
		end
	end
end

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------

function ns:Print(text, ...)
	if select("#", ...) > 0 then
		text = text:format(...)
	end
	DEFAULT_CHAT_FRAME:AddMessage(("|cff%s%s|r: %s"):format(self.color, self.shortTitle, text))
end

--------------------------------------------------------------------------------
-- Player
--------------------------------------------------------------------------------

-- Own realm. GetRealmName first (the rest of the suite uses it and it
-- is what this client populates), GetNormalizedRealmName as backup.
-- This client sometimes reports an empty realm for a whole session:
-- the last resort is the realm this character was already saved under
-- in ns.db.chars, so a blank realm never orphans the record.
local function SavedRealm(name)
	local chars = ns.db and ns.db.chars
	if type(name) ~= "string" or name == "" or type(chars) ~= "table" then
		return nil
	end
	local found
	for key in pairs(chars) do
		local who, realm = tostring(key):match("^(.-)%-(.+)$")
		if who == name and type(realm) == "string" and realm ~= "" then
			if found and found ~= realm then
				return nil -- same name saved on several realms - stay safe
			end
			found = realm
		end
	end
	return found
end

local function RawPlayerName()
	if type(GetUnitName) == "function" then
		local ok, name = pcall(GetUnitName, "player", false)
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
	end
	if type(UnitFullName) == "function" then
		local ok, name, second = pcall(UnitFullName, "player")
		if ok and type(name) == "string" and name ~= "" then
			if type(second) == "string" and second ~= "" then
				return name .. " " .. second
			end
			return name
		end
	end
end

local function OwnRealm()
	for _, fn in ipairs({ GetRealmName, GetNormalizedRealmName }) do
		if type(fn) == "function" then
			local ok, realm = pcall(fn)
			if ok and type(realm) == "string" and realm ~= "" then
				return realm
			end
		end
	end
	-- the connected realm name is also mirrored in a cvar on retail-like
	-- clients - cheap extra source before the saved-record fallback
	if C_CVar and type(C_CVar.GetCVar) == "function" then
		local ok, realm = pcall(C_CVar.GetCVar, "realmName")
		if ok and type(realm) == "string" and realm ~= "" then
			return realm
		end
	end
	return SavedRealm(RawPlayerName())
end
ns.OwnRealm = OwnRealm

-- Character name as the server writes it. Forever names are
-- "First Surname": GetUnitName already returns the full name on this
-- client; UnitFullName's ("First", "Surname") split is the fallback -
-- there a "realm" that isn't ours is the surname.
function ns:GetPlayerName()
	if type(GetUnitName) == "function" then
		local ok, name = pcall(GetUnitName, "player", false)
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
	end
	if type(UnitFullName) ~= "function" then
		return nil
	end
	local ok, name, second = pcall(UnitFullName, "player")
	if not ok or type(name) ~= "string" or name == "" then
		return nil
	end
	local realm = OwnRealm()
	if type(second) == "string" and second ~= "" and realm and second ~= realm then
		return name .. " " .. second
	end
	return name
end

-- "Name-Realm", the database key for the character. This client can
-- report an empty realm for a whole session: rather than never writing
-- anything, a bare "Name-" key is used then (the record is folded into
-- the full key once a realm resolves). The key is cached for the
-- session once resolved, so a hiccup in the APIs can never split the
-- record.
local cachedFullName
function ns:GetPlayerFullName()
	if cachedFullName then
		return cachedFullName
	end
	local name = ns:GetPlayerName()
	if not name then
		return nil
	end
	cachedFullName = name .. "-" .. (OwnRealm() or "")
	return cachedFullName
end

-- Display name for a database key "Name-Realm" -> "Name".
function ns.ShortName(key)
	return type(key) == "string" and (key:match("^(.-)%-") or key) or key
end
