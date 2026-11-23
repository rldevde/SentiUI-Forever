local _, ns = ...

local L = ns.L

-- strtrim is a FrameXML global and not guaranteed on this client.
local strtrim = strtrim or function(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Subcommands register themselves with ns:RegisterCommand; `/sai` alone
-- runs ns.defaultCommand (opens the window), an unknown subcommand
-- prints the list.
local commands = {}
local order = {}

-- handler(args) receives the rest of the line, trimmed.
-- usage and description are shown in the help, e.g. "delete <name>".
function ns:RegisterCommand(name, handler, usage, description)
	if not commands[name] then
		order[#order + 1] = name
	end
	commands[name] = { handler = handler, usage = usage or name, description = description }
end

local function PrintHelp()
	ns:Print(L.HELP_HEADER)
	for _, name in ipairs(order) do
		local command = commands[name]
		DEFAULT_CHAT_FRAME:AddMessage(("  |cffffd100/sai %s|r - %s"):format(command.usage, command.description or ""))
	end
end

SLASH_SENTIACCOUNTINFO1 = "/sai"
SLASH_SENTIACCOUNTINFO2 = "/sentiaccountinfo"
SlashCmdList.SENTIACCOUNTINFO = function(input)
	local name, rest = strtrim(input or ""):match("^(%S*)%s*(.-)$")
	name = name:lower()
	local command = commands[name]
	if command then
		command.handler(rest)
	elseif name == "" and ns.defaultCommand then
		ns.defaultCommand()
	else
		if name ~= "" and name ~= "help" then
			ns:Print(L.UNKNOWN_COMMAND, name)
		end
		PrintHelp()
	end
end

ns:RegisterCommand("help", PrintHelp, "help", L.CMD_HELP)

ns:RegisterCommand("delete", function(args)
	local name = strtrim(args or ""):lower()
	if name == "" or not ns.db then
		return
	end
	for key in pairs(ns.db.chars) do
		if key:lower() == name or ns.ShortName(key):lower() == name then
			if key == ns.Store.OwnKey() or not ns.Store.DeleteChar(key) then
				ns:Print(L.CMD_NOT_FOUND, args)
				return
			end
			ns:Print(L.CMD_DELETED, ns.ShortName(key))
			return
		end
	end
	ns:Print(L.CMD_NOT_FOUND, args)
end, "delete <name>", L.CMD_DELETE)

ns:RegisterCommand("sync", function()
	ns.UI.Show(6)
end, "sync", L.CMD_EXPORT)

-- Manual rescan with diagnostics: prints which link in the
-- boot->scan chain is missing when the dashboard shows no characters.
ns:RegisterCommand("scan", function()
	local charCount = 0
	if ns.db and ns.db.chars then
		for _ in pairs(ns.db.chars) do charCount = charCount + 1 end
	end
	local okKey, key = pcall(function() return ns.Store.OwnKey() end)
	local okN, name = pcall(function() return ns:GetPlayerName() end)
	local okR, realm = pcall(function() return ns.OwnRealm and ns.OwnRealm() end)
	ns:Print("scan: booted=%s enabled=%s db=%s key=%s name=%s realm=%s chars=%d",
		tostring(ns.booted), tostring(ns.enabled),
		tostring(ns.db ~= nil),
		okKey and tostring(key) or ("err:" .. tostring(key)),
		okN and tostring(name) or ("err:" .. tostring(name)),
		okR and tostring(realm) or ("err:" .. tostring(realm)),
		charCount)
	if not (ns.Scanner and ns.Scanner.Rescan) then
		ns:Print("scan: Scanner.Rescan missing - boot never ran")
		return
	end
	local ok, err = pcall(ns.Scanner.Rescan)
	local after = 0
	if ns.db and ns.db.chars then
		for _ in pairs(ns.db.chars) do after = after + 1 end
	end
	if ok then
		ns:Print("scan: Rescan done, chars now %d", after)
	else
		ns:Print("scan: Rescan failed: %s", tostring(err))
	end
end, "scan", L.CMD_SCAN or "Scan the current character now")

ns.RegisterCallback(ns, "SAI_BOOT", function()
	ns:Print(L.ADDON_LOADED, ns.version)
end)
