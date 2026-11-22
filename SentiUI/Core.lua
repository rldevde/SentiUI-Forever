-- SentiUI core: namespace, client events, internal callbacks, the after-combat
-- queue, the module registry, settings access and the /sui command.
-- SentiUI_* addons dock in through SentiUI:RegisterModule (see API.md).
local addonName, S = ...
_G.SentiUI = S

S.name = addonName
S.title = "|cffebad33SentiUI|r"
S.version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(addonName, "Version") or "dev"

-- output / safe calls ----------------------------------------------------------
local PRINT_PREFIX = S.title .. " |cff666666-|r "

function S.Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(PRINT_PREFIX .. tostring(msg))
end

-- debug.traceback does not exist on this client - debugstack does. The
-- fallback is pcall-wrapped so a missing stack lib can never turn a real
-- error into "error in error handling".
local function stack(level)
	if type(debugstack) == "function" then
		local ok, s = pcall(debugstack, level)
		if ok and s then return s end
	end
	if type(debug) == "table" and type(debug.traceback) == "function" then
		local ok, s = pcall(debug.traceback, "", level)
		if ok and s then return s end
	end
	return ""
end
S.Stack = stack

-- Errors come out with a traceback: the chat line names the phase and the
-- following lines list the Interface/AddOns/...:line chain, so a failing
-- call can be found in the right file right away.
function S.SafeCall(context, fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = xpcall(fn, function(msg)
		-- error messages can themselves be secret values here - tostring on
		-- a secret throws, which is what "error in error handling" was
		local ok2, s = pcall(tostring, msg)
		return (ok2 and s or "<secret error>") .. "\n" .. stack(3)
	end, ...)
	if not ok then
		S.Print(string.format("|cffff5555%s: %s|r", tostring(context or "?"), tostring(err)))
		S.BugHint()
		return
	end
	return err
end

-- engine-call wrappers ----------------------------------------------------
-- Central so every module (and every future one) reports the same way: a
-- failed or blocked call names its call site file.lua:line once, instead
-- of dying silently inside pcall.
local apiFailed = {}
local function ApiSite(level)
	if not (debug and debug.getinfo) then return "?" end
	local i = debug.getinfo(level, "Sl")
	return i and (tostring(i.short_src) .. ":" .. tostring(i.currentline)) or "?"
end

-- S.Call(label, fn, ...) - labelled pcall for engine calls whose failure
-- should be visible: prints label + call site + error once per site.
-- Returns ok, results... like pcall.
function S.Call(label, fn, ...)
	local ok, a, b, c, d, e, f, g, h, i = pcall(fn, ...)
	if ok then return ok, a, b, c, d, e, f, g, h, i end
	local where = ApiSite(2)
	if not apiFailed[where] then
		apiFailed[where] = true
		S.Print(string.format("|cffff5555blocked api |cffffcc00%s|r @ %s: %s",
			tostring(label), where, tostring(a):sub(1, 140)))
		S.BugHint()
	end
end

-- S.SecureAPI(fn, ...) - for calls that may be protected or restricted
-- (window toggles, item APIs, roster refreshes). Runs them in the
-- engine's securecall lane when present, plain pcall otherwise; a hard
-- failure names its call site once instead of an anonymous UNKNOWN().
-- NOTE: securecall does not untaint on this client - real protection
-- against tainted bookkeeping is forwarding hardware clicks to native
-- buttons (secure /click), not wrapping the call.
function S.SecureAPI(fn, ...)
	if type(fn) ~= "function" then return end
	if type(securecall) == "function" then
		local ok, res = pcall(securecall, fn, ...)
		if ok then return res end
	else
		local ok, res = pcall(fn, ...)
		if ok then return res end
	end
	local where = ApiSite(2)
	if not apiFailed[where] then
		apiFailed[where] = true
		S.Print("|cffffcc33blocked call|r @ " .. where)
		S.BugHint()
	end
end

-- shown once per session after the first reported problem so error bursts
-- do not repeat it
local bugHintShown
function S.BugHint()
	if bugHintShown then return end
	bugHintShown = true
	S.Print("|cff8a8040" .. S.L["Please report errors at https://dev.xrl-dev.de/bugtracker"] .. "|r")
end

function S.IsSecret(v)
	return issecretvalue ~= nil and issecretvalue(v) == true
end

-- secret TABLES: indexing one throws before IsSecret can see a field
function S.IsSecretTable(t)
	if canaccesstable ~= nil then return canaccesstable(t) ~= true end
	return issecrettable ~= nil and issecrettable(t) == true
end

-- How hard a unit is for the player, as { r, g, b }: ask the server for the
-- unit's content difficulty and map it through GetDifficultyColor (handles
-- scaled/hidden levels the plain level number cannot). Falls back to the
-- creature-level curve; nil when the client keeps the answer secret.
function S.LevelColor(unit, level)
	if type(unit) == "string" and C_PlayerInfo
		and C_PlayerInfo.GetContentDifficultyCreatureForPlayer
		and type(GetDifficultyColor) == "function" then
		local ok, d = pcall(C_PlayerInfo.GetContentDifficultyCreatureForPlayer, unit)
		if ok and type(d) == "number" and not S.IsSecret(d) then
			local okC, c = pcall(GetDifficultyColor, d)
			if okC and type(c) == "table" then return c end
		end
	end
	if type(level) == "number" and not S.IsSecret(level)
		and type(GetCreatureDifficultyColor) == "function" then
		local ok, c = pcall(GetCreatureDifficultyColor, level)
		if ok and type(c) == "table" then return c end
	end
end

-- client events ------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

-- name of the event currently being dispatched - the forbidden-call
-- handler below reads it to say WHICH event ran inside the blocked call
local activeEvent

eventFrame:SetScript("OnEvent", function(_, event, ...)
	local list = eventHandlers[event]
	if not list then return end
	activeEvent = event
	for i = 1, #list do S.SafeCall("event:" .. event, list[i], event, ...) end
	activeEvent = nil
end)

-- Returns false for an event this client doesn't have, so callers can list
-- events from other game versions without guarding each one.
function S.RegisterEvent(event, fn)
	local list = eventHandlers[event]
	if not list then
		if not pcall(eventFrame.RegisterEvent, eventFrame, event) then return false end
		list = {}
		eventHandlers[event] = list
	end
	list[#list + 1] = fn
	return true
end

-- internal callbacks -------------------------------------------------------------
local callbacks = {}

function S.On(name, fn)
	local list = callbacks[name]
	if not list then list = {}; callbacks[name] = list end
	list[#list + 1] = fn
end

function S.Fire(name, ...)
	local list = callbacks[name]
	if not list then return end
	for i = 1, #list do S.SafeCall("callback:" .. name, list[i], ...) end
end

-- after-combat queue ---------------------------------------------------------------
-- Protected frame work (anchoring, sizing, showing) goes through here. Out of
-- combat it runs now; in combat it waits for PLAYER_REGEN_ENABLED.
local combatQueue = {}

function S.RunOutOfCombat(fn, ...)
	if InCombatLockdown() then
		combatQueue[#combatQueue + 1] = { fn = fn, n = select("#", ...), ... }
		return false
	end
	S.SafeCall("outOfCombat", fn, ...)
	return true
end

-- visibility watcher --------------------------------------------------------
-- An OnHide/OnShow script on a special window - or an event registration for
-- window-open events like TRADE_SKILL_SHOW/BANKFRAME_OPENED - runs insecure
-- Lua inside the window's open/close dispatch. The client's follow-up calls
-- in that same dispatch then trip on secrets ("execution tainted by X") or
-- get blocked outright (ADDON_ACTION_FORBIDDEN on SpellStopCasting). Polling
-- shown-state transitions from OnUpdate is a different dispatch where Lua is
-- safe. WatchShown also accepts a resolver function for frames that do not
-- exist yet (load-on-demand Blizzard UI).
local watchList, watchFrame

local function WatchPump(self)
	for i = 1, #watchList do
		local w = watchList[i]
		local f
		if type(w.frame) == "function" then
			local okR, r = pcall(w.frame)
			f = okR and r or nil
		else
			f = w.frame
		end
		if f and f.IsShown then
			local ok, raw = pcall(f.IsShown, f)
			-- a non-boolean answer (error or secret) means "unknown", not
			-- hidden - treating it as hidden fakes a transition that never
			-- happened
			if not ok or type(raw) ~= "boolean" then raw = w.shown end
			local shown = raw == true
			if w.shown == nil then w.shown = shown end
			if w.shown ~= shown then
				w.shown = shown
				local cb = shown and w.onShow or w.onHide
				if cb then S.SafeCall("watchShown", cb, f) end
			end
		end
	end
end

local function WatchAdd(entry)
	watchList[#watchList + 1] = entry
	if watchFrame then return end
	watchFrame = CreateFrame("Frame")
	watchFrame:SetScript("OnUpdate", WatchPump)
end

watchList = {}

function S.WatchShown(frameOrResolver, onShow, onHide)
	if not frameOrResolver then return end
	WatchAdd({ frame = frameOrResolver, onShow = onShow, onHide = onHide })
end

function S.WatchHide(frame, fn)
	if not frame or type(fn) ~= "function" then return end
	WatchAdd({ frame = frame, onHide = fn })
end

-- taint radar: the client blames an addon when a protected call gets
-- blocked. The event names the forbidden function and the addon it thinks
-- is responsible - printed so the culprit can be found without guessing.
-- event args are (addonName, functionName); the function name can be
-- "UNKNOWN()" on this client
local function forbidden(_, addon, func)
	-- the event fires synchronously inside the blocked call, so the Lua
	-- stack still holds our call site - find the first SentiUI frame and
	-- name it (file.lua:line) so the culprit needs no guessing
	local where
	if type(debugstack) == "function" then
		local ok, stack = pcall(debugstack, 2)
		local secret = type(issecretvalue) == "function"
			and issecretvalue(stack)
		if ok and type(stack) == "string" and not secret then
			local skippedTop, firstLua
			for src, line in stack:gmatch("([%w%._%-%/\\]+%.lua):(%d+)") do
				if skippedTop then
					if not firstLua then firstLua = src .. ":" .. line end
					-- core internals are dispatch machinery (this handler,
					-- OnEvent, SafeCall/S.Call wrappers) - the culprit is
					-- the module frame below them
					if src:find("SentiUI", 1, true)
						and not src:find("SentiUI[/\\]Core%.lua") then
						where = src .. ":" .. line
						break
					end
				else
					-- the topmost Lua frame is this handler itself
					-- (it called debugstack) - the culprit sits below it
					skippedTop = true
				end
			end
			where = where or firstLua
		end
	end
	S.Print(string.format("|cffff5555forbidden call: %s  (the client blames: %s)%s%s|r",
		tostring(func or "?"), tostring(addon or "unknown"),
		activeEvent and ("  |cffffcc33during " .. activeEvent .. "|r") or "",
		where and ("  |cffffcc33@ " .. where .. "|r") or ""))
	S.BugHint()
end
S.RegisterEvent("ADDON_ACTION_FORBIDDEN", forbidden)
S.RegisterEvent("ADDON_ACTION_BLOCKED", forbidden)

-- combat window deferral -----------------------------------------------------
-- Opening a managed window mid-combat dies as ADDON_ACTION_FORBIDDEN on the
-- client's FrameShow. Instead of failing, the request queues for
-- PLAYER_REGEN_ENABLED with a chat note - and a flagged own window closes
-- when combat starts and comes back after.
local combatWins, pendingToggles = {}, {}

local function combatLock()
	if type(InCombatLockdown) == "function" then return InCombatLockdown() end
	return UnitAffectingCombat and UnitAffectingCombat("player") == true
end

local function noteDeferred(label)
	S.Print(string.format(S.L["%s opens after combat"], label))
end

-- Flag one of our windows: Show() during combat queues the open for after
-- the fight (one chat note per combat) and a shown window hides when
-- combat starts, then returns.
function S:CombatDeferWindow(f)
	if not f or combatWins[f] then return end
	local e = {}
	combatWins[f] = e
	local rawShow = f.Show
	f.Show = function(self, ...)
		if combatLock() then
			e.pending = true
			if not e.noted then
				e.noted = true
				local ok, n = pcall(f.GetName, f)
				noteDeferred(ok and type(n) == "string" and n or "window")
			end
			return
		end
		e.noted = nil
		return rawShow(self, ...)
	end
end

-- Blizzard key toggles (C, K, N ...): the engine's window Show is protected
-- here, so a mid-combat press dies to ADDON_ACTION_FORBIDDEN. The global
-- toggle queues the open instead and fires after combat only when the
-- window is still closed - a manual open in between must not toggle shut.
local TOGGLE_DEFS = {
	{ fn = "ToggleCharacter",        label = "Character",    frames = { "CharacterFrame", "PaperDollFrame" } },
	{ fn = "ToggleSpellBook",        label = "Spellbook",    frames = { "SpellBookFrame", "PlayerSpellsFrame" } },
	{ fn = "ToggleSkillFrame",       label = "Skills",       frames = { "SkillFrame", "ProfessionsBookFrame" } },
	{ fn = "ToggleTalentFrame",      label = "Talents",      frames = { "TalentFrame", "PlayerTalentFrame", "ClassTalentFrame" } },
	{ fn = "ToggleFriendsFrame",     label = "Social",       frames = { "FriendsFrame" } },
	{ fn = "ToggleGuildFrame",       label = "Guild",        frames = { "GuildFrame", "CommunitiesFrame" } },
	{ fn = "ToggleAchievementFrame", label = "Achievements", frames = { "AchievementFrame" } },
	{ fn = "TogglePVPUI",            label = "PvP",          frames = { "PVPUIFrame", "PVPFrame", "HonorFrame" } },
	{ fn = "TogglePVPFrame",         label = "PvP",          frames = { "PVPUIFrame", "PVPFrame", "HonorFrame" } },
	{ fn = "ToggleQuestLog",         label = "Quest log",    frames = { "QuestLogFrame" } },
	{ fn = "ToggleWorldMap",         label = "Map",          frames = { "WorldMapFrame" } },
	{ fn = "ToggleHelpFrame",        label = "Help",         frames = { "HelpFrame" } },
	{ fn = "ToggleCalendar",         label = "Calendar",     frames = { "CalendarFrame" } },
	{ fn = "ToggleLFGParentFrame",   label = "Group finder", frames = { "LFGParentFrame", "PVEFrame", "GroupFinderFrame" } },
}

local function toggleStillClosed(d)
	for _, n in ipairs(d.frames) do
		local fr = _G[n]
		if fr and fr.IsShown then
			local ok, s = pcall(fr.IsShown, fr)
			if ok and s then return false end
		end
	end
	return true
end

local pendingKeys = {}

-- generic panel opens/closes that bypass the named toggles (micro menu,
-- /click paths, other addons): ShowUIPanel defers unless the frame is
-- already open, HideUIPanel unless already closed, ToggleFrame replays
-- verbatim. Same (function, frame) queues once - a double ToggleFrame
-- would undo itself.
local PANEL_DEFS = {
	{ fn = "ShowUIPanel", mode = "show" },
	{ fn = "HideUIPanel", mode = "hide" },
	{ fn = "ToggleFrame", mode = "toggle" },
}

local function queuePanelCall(orig, f, mode, label, ...)
	local key = tostring(orig) .. "|" .. tostring(f)
	if pendingKeys[key] then return end
	pendingKeys[key] = true
	local args = { n = select("#", ...), ... }
	pendingToggles[#pendingToggles + 1] = {
		key = key,
		run = function() return orig(f, (unpack or table.unpack)(args, 1, args.n)) end,
		skip = function()
			local ok, s = pcall(f.IsShown, f)
			s = ok and s == true
			if mode == "show" then return s end
			if mode == "hide" then return not s end
			return false
		end,
	}
	noteDeferred(label)
end

S.RegisterEvent("PLAYER_LOGIN", function()
	for _, d in ipairs(TOGGLE_DEFS) do
		local orig = _G[d.fn]
		if type(orig) == "function" then
			d.orig = orig
			_G[d.fn] = function(...)
				if combatLock() then
					if not d.queued then
						d.queued = true
						pendingToggles[#pendingToggles + 1] = {
							def = d,
							run = function() return orig(...) end,
							skip = function() return not toggleStillClosed(d) end,
						}
						noteDeferred(d.label)
					end
					return
				end
				return orig(...)
			end
		end
	end
	for _, d in ipairs(PANEL_DEFS) do
		local orig, mode = _G[d.fn], d.mode
		if type(orig) == "function" then
			_G[d.fn] = function(f, ...)
				if combatLock() and type(f) == "table" then
					local ok, n = pcall(f.GetName, f)
					queuePanelCall(orig, f, mode,
						ok and type(n) == "string" and n or d.fn, ...)
					return
				end
				return orig(f, ...)
			end
		end
	end
end)

S.RegisterEvent("PLAYER_REGEN_DISABLED", function()
	for f, e in pairs(combatWins) do
		local ok, shown = pcall(f.IsShown, f)
		if ok and shown then
			e.reopen = true
			pcall(f.Hide, f)
		end
	end
end)

S.RegisterEvent("PLAYER_REGEN_ENABLED", function()
	local queue = combatQueue
	combatQueue = {}
	for i = 1, #queue do
			-- this client ships the GLOBAL unpack; table.unpack may be missing
			S.SafeCall("outOfCombat", queue[i].fn, (unpack or table.unpack)(queue[i], 1, queue[i].n))
	end
	-- flagged own windows: queued open requests + auto-reopen
	for f, e in pairs(combatWins) do
		if e.pending or e.reopen then
			e.pending, e.reopen, e.noted = nil, nil, nil
			local ok, shown = pcall(f.IsShown, f)
			if not (ok and shown) then S.SafeCall("combatWin", f.Show, f) end
		end
	end
	-- deferred Blizzard window opens
	local tq = pendingToggles
	pendingToggles = {}
	pendingKeys = {}
	for i = 1, #tq do
		local e = tq[i]
		if e.def then e.def.queued = nil end
		local ok, skip = pcall(e.skip)
		if not (ok and skip) then S.SafeCall("deferOpen", e.run) end
	end
end)

-- modules --------------------------------------------------------------------------
-- A module registers at file load and is enabled at PLAYER_LOGIN (or right away
-- if it registers later) with its settings table.
local modules, moduleOrder = {}, {}

-- def: {
--   label      section name in the options window (defaults to name)
--   order      section order, lower first
--   defaults   merged into SentiUIDB.modules[name]
--   options    { pages = { ... } } - see API.md
--   section    file the pages under another section id instead of an own one
--   OnEnable(mod, db), OnSettingChanged(mod, path, value), OnStyleChanged(mod)
-- }
function S:RegisterModule(name, def)
	assert(type(name) == "string" and name ~= "", "module name required")
	assert(not modules[name], "module already registered: " .. name)
	def = def or {}
	def.name = name
	modules[name] = def
	moduleOrder[#moduleOrder + 1] = name
	if def.changelog and S.Changelog then
		S.Changelog.Register(def.label or name, def.changelog)
	end
	if self.loggedIn then self.EnableModule(def) end
	return def
end

-- Same call, matching the rest of the Sentinel addons.
S.NewModule = S.RegisterModule

function S:GetModule(name) return modules[name] end

function S.Modules()
	local i = 0
	return function()
		i = i + 1
		local name = moduleOrder[i]
		if name then return name, modules[name] end
	end
end

function S.EnableModule(mod)
	if mod.enabled then return end
	mod.db = S.DB.Module(mod.name, mod.defaults or {})
	mod.enabled = true
	if mod.options and S.Options then S.Options.RegisterModule(mod) end
	if mod.OnEnable then S.SafeCall("module:" .. mod.name, mod.OnEnable, mod, mod.db) end
end

-- settings access ---------------------------------------------------------------------
-- scope is "general" or a module name; path is dotted.
local function scopeTable(scope)
	if scope == "general" then return S.DB.General() end
	local mod = modules[scope]
	return mod and mod.db
end

function S:Get(scope, path)
	local t = scopeTable(scope)
	return t and S.DB.GetPath(t, path)
end

function S:Set(scope, path, value)
	local t = scopeTable(scope)
	if not t then return false end
	S.DB.SetPath(t, path, value)
	if scope == "general" then
		S.Fire("GeneralChanged", path, value)
	else
		local mod = modules[scope]
		if mod and mod.OnSettingChanged then
			S.SafeCall("module:" .. scope, mod.OnSettingChanged, mod, path, value)
		end
	end
	S.Fire("SettingChanged", scope, path, value)
	return true
end

-- slash commands ------------------------------------------------------------------------
SLASH_SENTIUI1 = "/sui"
SLASH_SENTIUI2 = "/sentiui"
SlashCmdList.SENTIUI = function(msg)
	msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
	if msg == "" or msg == "options" or msg == "settings" then
		S.OptionsPanel.Toggle()
	elseif msg == "unlock" or msg == "move" then
		S.Movers.SetUnlocked(true)
	elseif msg == "lock" then
		S.Movers.SetUnlocked(false)
	elseif msg == "reset" then
		StaticPopup_Show("SENTIUI_RESET_MOVERS")
	elseif msg == "minimap" then
		S:Set("general", "minimap.hide", not S:Get("general", "minimap.hide"))
		S.MinimapButton.Sync()
	elseif msg == "install" or msg == "installer" then
		S.Installer.Show()
	else
		S.Print(S.L["Commands: /sui - settings | /sui unlock - move frames | /sui lock | /sui reset - reset positions | /sui minimap - toggle button"])
	end
end

-- addon compartment -----------------------------------------------------------------------
function SentiUI_OnAddonCompartmentClick(_, _, _, button)
	if button == "RightButton" then
		S.Movers.Toggle()
	else
		S.OptionsPanel.Toggle()
	end
end

-- boot ---------------------------------------------------------------------------------------
S.RegisterEvent("PLAYER_LOGIN", function()
	S.DB.Init()
	S.loggedIn = true
	-- Each separately, so one failing can't keep the rest from starting.
	for _, mod in S.Modules() do S.SafeCall("enable:" .. mod.name, S.EnableModule, mod) end
	S.MinimapButton.Sync()
	S.Fire("Login")
	S.Print(string.format(S.L["version %s loaded - %s for settings"], S.version, "|cffebad33/sui|r"))
end)
