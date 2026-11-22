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
	local snapshot = { unpack(list) }
	for i = 1, #snapshot do
		snapshot[i](event, ...)
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
	local snapshot = { unpack(list) }
	for i = 1, #snapshot do
		snapshot[i].func(event, ...)
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

-- Own realm, normalized ("CAMWOWEU4Realm1PvE" on Forever).
local function OwnRealm()
	local realm = GetNormalizedRealmName()
	if type(realm) == "string" and realm ~= "" then
		return realm
	end
end
ns.OwnRealm = OwnRealm

-- Character name as the server writes it. Forever names are
-- "First Surname": UnitFullName returns them as name and realm
-- ("First", "Surname"), so a "realm" that isn't ours is the surname.
function ns:GetPlayerName()
	local name, second = UnitFullName("player")
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local realm = OwnRealm()
	if type(second) == "string" and second ~= "" and realm and second ~= realm then
		return name .. " " .. second
	end
	return name
end

-- "Name-Realm", the database key for the character. Nil before the
-- realm is known (early in the loading process).
function ns:GetPlayerFullName()
	local name = ns:GetPlayerName()
	local realm = OwnRealm()
	if name and realm then
		return name .. "-" .. realm
	end
end

-- Display name for a database key "Name-Realm" -> "Name".
function ns.ShortName(key)
	return type(key) == "string" and (key:match("^(.-)%-") or key) or key
end
