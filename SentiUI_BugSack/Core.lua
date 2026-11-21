-- SentiUI BugSack: error grabber + store. Installs the client's error
-- handler (the BugGrabber way: seterrorhandler is stubbed out so nothing
-- else can replace it), listens for LUA_WARNING and
-- ADDON_ACTION_BLOCKED/FORBIDDEN, deduplicates by message and keeps a
-- capped store per session. The window in Window.lua renders it.
local addonName, ns = ...
local S = SentiUI
local L = ns.L

local type, tostring, time = type, tostring, time
local tremove = table.remove
local wipe = wipe or table.wipe or function(t) for k in pairs(t) do t[k] = nil end return t end
local GetTime = GetTime
local print = print

local MAX_ERRORS = 500
local THROTTLE = 10

local Grab = {}
ns.Grab = Grab
ns.version = C_AddOns and C_AddOns.GetAddOnMetadata
	and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"

-----------------------------------------------------------------------
-- SavedVariables / store
-----------------------------------------------------------------------
if type(SentiUIBugSackDB) ~= "table" then SentiUIBugSackDB = {} end
local sv = SentiUIBugSackDB
if type(sv.session) ~= "number" then sv.session = 0 end
if type(sv.errors) ~= "table" then sv.errors = {} end
sv.session = sv.session + 1
local db = sv.errors
while #db > MAX_ERRORS do tremove(db, 1) end

-- module settings, working even before the enable pass or when the module
-- is disabled (ns.mod only exists after OnEnable runs)
local function Cfg()
	return (ns.mod and ns.mod.db)
		or (S.DB and S.DB.Module and S.DB.Module("BugSack", ns.DEFAULTS))
		or ns.DEFAULTS
end

function Grab:GetDB() return db end
function Grab:GetSessionId() return sv.session end

function Grab:GetErrors(sessionId)
	if not sessionId then return db end
	local list = {}
	for _, e in ipairs(db) do
		if e.session == sessionId then list[#list + 1] = e end
	end
	return list
end

function Grab:GetErrorCount() return #db end

function Grab:Reset()
	wipe(sv.errors)
	db = sv.errors
	if ns.Window then pcall(ns.Window.Refresh) end -- window errors must never feed the grabber loop
	S.Print(L["All bugs wiped"])
end

-----------------------------------------------------------------------
-- Formatting
-----------------------------------------------------------------------
local Escape = C_StringUtil and C_StringUtil.EscapeDecimalNonPrintables
	or function(s) return s end

local function colorStack(ret)
	ret = ret:gsub("Interface/AddOns/", "")
	ret = ret:gsub("^%.%.%.[^/]+/AddOns/", "")
	ret = ret:gsub("<([^>]+:)(%d+)>", "|cffffea00<%1|cff00ff00%2|r>|r")
	ret = ret:gsub("%[([^%]]+)%]:(%d+):", "|cffffea00[%1]:|cff00ff00%2|r:|r")
	ret = ret:gsub('"[^"\n]*"', "|cff8888ff%0|r")
	ret = ret:gsub("'[^'\n]*'", "|cff8888ff%0|r")
	return ret
end

local function colorLocals(ret)
	ret = ret:gsub("|(%a)", "||%1"):gsub("|$", "||")
	ret = ret:gsub("> %@(.-):(%d+)", "> @|cffeda55f%1|r:|cff00ff00%2|r")
	ret = ret:gsub("(\n +)([^=\"\n]+)=", "%1|cffffff80%2|r=")
	ret = ret:gsub("=(%-?%d%d*%.?%d*)\n", "=|cffff7fff%1|r\n")
	ret = ret:gsub("=nil\n", "=|cffff7f7fnil|r\n")
	ret = ret:gsub("=true\n", "=|cffff9100true|r\n")
	ret = ret:gsub("=false\n", "=|cffff9100false|r\n")
	ret = ret:gsub("=<([^>]+)>", "=|cffffea00<%1>|r")
	return ret
end

-- colored for the detail view, plain for copy/export
function Grab:FormatError(err)
	local message = Escape(err.message or "")
	local stack = err.stack and Escape(err.stack) or ""
	local body = colorStack(message .. (stack ~= "" and ("\n" .. stack) or ""))
	if err.locals then
		return ("%dx %s\n\nLocals:\n%s"):format(err.counter or 1, body,
			colorLocals(Escape(err.locals)))
	end
	return ("%dx %s"):format(err.counter or 1, body)
end

function Grab:FormatErrorPlain(err)
	local message = Escape(err.message or "")
	local stack = err.stack and Escape(err.stack) or ""
	local body = message .. (stack ~= "" and ("\n" .. stack) or "")
	if err.locals then
		return ("%dx %s\n\nLocals:\n%s"):format(err.counter or 1, body,
			Escape(err.locals))
	end
	return ("%dx %s"):format(err.counter or 1, body)
end

local function addonFromText(text)
	if type(text) ~= "string" then return nil end
	return text:match("[\\/]AddOns[\\/]([^\\/\n]+)") or text:match("AddOn '([^']+)'")
end

function Grab:GetErrorAddon(err)
	return addonFromText(err.stack)
		or addonFromText(err.message)
		or addonFromText(err.locals)
		or L["Unknown"]
end

function Grab:GetErrorsByAddon(list)
	local groups, order = {}, {}
	for _, err in ipairs(list) do
		local name = self:GetErrorAddon(err)
		if not groups[name] then
			groups[name] = {}
			order[#order + 1] = name
		end
		groups[name][#groups[name] + 1] = err
	end
	local unknown = L["Unknown"]
	table.sort(order, function(a, b)
		if (a == unknown) ~= (b == unknown) then return b == unknown end
		if #groups[a] ~= #groups[b] then return #groups[a] > #groups[b] end
		return a:lower() < b:lower()
	end)
	return groups, order
end

-- copyable text block for the export view / bugtracker posts
function Grab:BuildExport(list, title)
	local parts = {
		("SentiUI BugSack %s - %s - %d %s - %s"):format(
			ns.version or "?", title or (L["Session"] .. " " .. sv.session),
			#list, L["Errors"], date("%Y-%m-%d %H:%M:%S")),
	}
	for _, err in ipairs(list) do
		local t = type(err.time) == "number"
			and date("%Y-%m-%d %H:%M:%S", err.time) or "?"
		parts[#parts + 1] = ("---- [%s] %s %d ----"):format(t,
			L["Session"], err.session or 0)
		parts[#parts + 1] = self:FormatErrorPlain(err)
	end
	return table.concat(parts, "\n\n")
end

-----------------------------------------------------------------------
-- Notification on captured errors
-----------------------------------------------------------------------
local ERROR_SOUND = (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959
local lastSound, lastChat = 0, 0
function Grab:ErrorCaptured(err, index)
	local cfg = Cfg()
	local now = GetTime()
	if not cfg.mute and now - lastSound > 3 then
		lastSound = now
		if PlaySound then PlaySound(ERROR_SOUND, "Master") end
	end
	if cfg.chat and now - lastChat > 3 then
		lastChat = now
		local text = L["New error captured!"]
		if err then
			local name = self:GetErrorAddon(err)
			if name ~= L["Unknown"] then
				text = L["New error in %s"]:format("|cff339eff" .. name .. "|r")
			end
		end
		if index then
			text = ("|Hsentiuibugsack:error:%d|h%s|h"):format(index, text)
		end
		S.Print(text)
	end
	if ns.Window then pcall(ns.Window.Refresh) end -- window errors must never feed the grabber loop
	if cfg.auto and not InCombatLockdown() and ns.Window then
		ns.Window.Open()
	end
end

-----------------------------------------------------------------------
-- Capture engine
-----------------------------------------------------------------------
do
	local issecretvalue = issecretvalue or function() return false end

	local function GetErrorStack()
		if GetCallstackHeight and GetErrorCallstackHeight then
			local currentStackHeight = GetCallstackHeight()
			local errorCallStackHeight = GetErrorCallstackHeight()
			if errorCallStackHeight then
				local level = currentStackHeight - (errorCallStackHeight - 1)
				local stack = debugstack(level)
				if issecretvalue(stack) then
					return "debugstack() returned secrets.", level
				elseif stack then
					return stack, level
				end
			end
		end
		local stack = debugstack(3)
		if issecretvalue(stack) then return "debugstack() returned secrets.", 3 end
		return stack or "debugstack() returned nil.", 3
	end

	local function GetErrorLocals(level)
		if not debuglocals then return nil end
		local locals = debuglocals(level)
		if issecretvalue(locals) then return "debuglocals() returned secrets." end
		return locals
	end

	local function storeError(err)
		db[#db + 1] = err
		if #db > MAX_ERRORS then tremove(db, 1) end
	end

	local function findError(target)
		for i = #db, 1, -1 do
			local err = db[i]
			if err.message == target then return err, i end
		end
	end

	local msgsAllowed = THROTTLE
	local msgsAllowedLastTime = GetTime()
	local lastWarning = 0
	local function captureError(errorMessage, isSimple)
		-- module turned off: hand the error back to whatever handler was
		-- installed before us so nothing is silently swallowed
		if Cfg().enabled == false then
			if ns.originalHandler then
				return pcall(ns.originalHandler, errorMessage)
			end
			return
		end
		msgsAllowed = msgsAllowed + (GetTime() - msgsAllowedLastTime) * THROTTLE
		msgsAllowedLastTime = GetTime()
		if msgsAllowed < 1 then
			if GetTime() > lastWarning + 10 then
				print(L["STOPPED - too many errors, capture throttled"])
				lastWarning = GetTime()
			end
			return
		end
		if msgsAllowed > THROTTLE then msgsAllowed = THROTTLE end
		msgsAllowed = msgsAllowed - 1

		errorMessage = tostring(errorMessage)
		if issecretvalue(errorMessage)
			or errorMessage:find("SentiUI_BugSack", nil, true) then
			print("|cffebad33[BugSack]|r", errorMessage)
			return
		end

		local err, pos = findError(errorMessage)
		local index
		if err then
			err.counter = (err.counter or 0) + 1
			err.time = time()
			if err.session ~= sv.session then
				tremove(db, pos)
				storeError(err)
				err.session = sv.session
				if not isSimple then
					local stack, level = GetErrorStack()
					err.stack = stack
					err.locals = GetErrorLocals(level)
				end
				index = #db
			else
				index = pos
			end
		else
			err = { message = errorMessage, session = sv.session,
				time = time(), counter = 1 }
			storeError(err)
			index = #db
			if not isSimple then
				local stack, level = GetErrorStack()
				err.stack = stack
				err.locals = GetErrorLocals(level)
			end
		end
		Grab:ErrorCaptured(err, index)
	end

	local frame = CreateFrame("Frame")
	local badAddons = {}
	frame:SetScript("OnEvent", function(_, event, arg1, arg2)
		if event == "LUA_WARNING" then
			captureError("LUA_WARNING: " .. tostring(arg2 or arg1 or ""), true)
		else -- ADDON_ACTION_BLOCKED / ADDON_ACTION_FORBIDDEN
			local name = arg1 or "<name>"
			if not badAddons[name] then
				badAddons[name] = true
				captureError(L["%s blocked from %s: %s"]:format(event, name,
					arg2 or "<func>"), true)
			end
		end
	end)
	frame:RegisterEvent("LUA_WARNING")
	frame:RegisterEvent("ADDON_ACTION_BLOCKED")
	frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	UIParent:UnregisterEvent("ADDON_ACTION_BLOCKED")
	UIParent:UnregisterEvent("ADDON_ACTION_FORBIDDEN")
	if ScriptErrorsFrame then ScriptErrorsFrame:UnregisterEvent("LUA_WARNING") end

	-- install: remember the previous handler so a disabled module can hand
	-- errors back instead of swallowing them, then take over like
	-- BugGrabber does - nobody else may replace our handler afterwards
	ns.originalHandler = geterrorhandler and geterrorhandler()
	local real = seterrorhandler
	if real then real(captureError) end
	function seterrorhandler() end
end

-----------------------------------------------------------------------
-- Slash commands + clickable chat links
-----------------------------------------------------------------------
local strtrim = strtrim or function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

SlashCmdList.SentiUIBugSack = function(msg)
	msg = strtrim(msg or ""):lower()
	if msg == "wipe" then
		Grab:Reset()
	elseif msg == "export" then
		if ns.Window then ns.Window.OpenExport("session") end
	elseif msg == "export all" then
		if ns.Window then ns.Window.OpenExport("all") end
	elseif msg ~= "" and tonumber(msg) then
		local err = db[tonumber(msg)]
		if err then print(Grab:FormatError(err)) else
			S.Print("/sbs | /sbs wipe | /sbs export | /sbs export all | /sbs <n>")
		end
	else
		if ns.Window then ns.Window.Toggle() end
	end
end
SLASH_SentiUIBugSack1 = "/sbs"
SLASH_SentiUIBugSack2 = "/bugsack"

if hooksecurefunc and type(SetItemRef) == "function" then
	hooksecurefunc("SetItemRef", function(link)
		if type(link) ~= "string" then return end
		local cmd, arg = link:match("^sentiuibugsack:(%a+):?(%d*)$")
		if cmd == "error" then
			local err = db[tonumber(arg) or 0]
			if err and ns.Window then ns.Window.ShowError(err) end
		elseif cmd == "open" and ns.Window then
			ns.Window.Open()
		end
	end)
end
