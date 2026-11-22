-- ForeverBlackListed inside the panel. Shares the FBLDB data model:
-- entries added here are seen by the standalone addon (and synced by
-- it when installed), entries from it show up here. When the real
-- ForeverBlackListed is loaded we delegate writes to it entirely.
local _, ns = ...
local S = SentiUI
local L = ns.L

local F = {}
ns.FBL = F

local format, tinsert, sort = string.format, table.insert, table.sort
local strtrim = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end
local lower, time = string.lower, time

local function IsSecret(v)
	return type(issecretvalue) == "function" and issecretvalue(v) == true
end

-- database ------------------------------------------------------------------------
local DEFAULTS = {
	entries = {},
	groups = {
		players = { name = "Players", order = 1, builtin = true },
		bots = { name = "Bots", order = 2, builtin = true },
		other = { name = "Other", order = 3, builtin = true },
		boosters = { name = "Boosters", order = 4, builtin = true },
		goldsellers = { name = "Gold sellers", order = 5, builtin = true },
		boostgold = { name = "Booster & gold seller", order = 6, builtin = true },
	},
	groupSeq = 6,
	lastGroup = "players",
	tooltip = { enabled = true, showClear = true, checkGuild = true, showNote = true },
	sync = { join = true, autoAccept = true, liveShare = true, trust = "all",
		log = {}, peers = {} },
	auto = { enabled = false, level = 10, group = "bots", guildMembers = false, realm = "" },
	warn = { whisper = true, invite = true, autoDecline = false },
	tombstones = {},
}

local function Merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then dst[k] = {} Merge(dst[k], v)
			elseif v[1] == nil then Merge(dst[k], v) end
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

FBLDB = type(FBLDB) == "table" and FBLDB or {}
Merge(FBLDB, DEFAULTS)
F.db = FBLDB
-- several addons declare FBLDB (standalone, My-Social, us); whichever
-- saved-variables file loads last replaces the global, so a .db captured
-- at file load can point at an orphaned table whose writes never reach
-- disk. And a late-loading declarer's file can hand us a global that
-- never saw Merge - DB() resolves the live global AND guarantees the
-- defaults on whatever table it hands out.
local merged = setmetatable({}, { __mode = "k" })
local function DB()
	local db = _G.FBLDB
	if type(db) ~= "table" then db = {} _G.FBLDB = db end
	-- pcall: a saved table can carry values this client marks secret,
	-- and a mid-merge throw would leave the table half-filled
	if not merged[db] then pcall(Merge, db, DEFAULTS) merged[db] = true end
	-- callers index db.sync all over; the merged defaults normally
	-- provide it, but keep the guarantee whatever a declarer's file
	-- leaves in the slot (read + type check inside pcall: secret-safe)
	local ok, isTab = pcall(function() return type(db.sync) == "table" end)
	if not (ok and isTab) then db.sync = {} end
	return db
end
F.DB = DB

-- sync traffic log: a small persisted ring buffer every user can read on
-- the window's "Sync" page - what went out, what came in and from whom
local win -- the list window is created far below; Log pings it when open
local LOG_MAX = 80
local function Log(dir, msg)
	local db = DB()
	local log = db.sync.log
	if type(log) ~= "table" then log = {} db.sync.log = log end
	log[#log + 1] = { t = time(), dir = dir, msg = msg }
	local n = #log
	if n > LOG_MAX then
		local cut = n - LOG_MAX
		for i = 1, LOG_MAX do log[i] = log[i + cut] end
		for i = LOG_MAX + 1, n do log[i] = nil end
	end
	if win and win:IsShown() and win.filter == "log" then
		F.RefreshWindow()
	end
end
F.SyncLog = Log

-- known peers: FBL-speaking clients seen on the channel. Kept (and
-- persisted) so the sync page can list who is around, their addon
-- version and list revision, and when we last heard them
local PEER_MAX_AGE = 14 * 86400
local function PeerSeen(name, ver, rev, cnt)
	local db = DB()
	local p = db.sync.peers
	if type(p) ~= "table" then p = {} db.sync.peers = p end
	local key = (name and F.CleanName(name)) or "?"
	local e = p[key]
	if type(e) ~= "table" then e = {} p[key] = e end
	e.at = time()
	if ver then e.ver = ver end
	if rev then e.rev = rev end
	if cnt then e.cnt = cnt end
end

local function KnownPeers()
	local db = DB()
	local p = type(db.sync.peers) == "table" and db.sync.peers or {}
	local now, out = time(), {}
	for k, e in pairs(p) do
		if type(e) == "table" and now - (e.at or 0) < PEER_MAX_AGE then
			out[#out + 1] = { name = k, ver = e.ver, rev = e.rev, at = e.at, cnt = e.cnt }
		else
			p[k] = nil -- stale or malformed: prune in place
		end
	end
	sort(out, function(a, b) return (a.at or 0) > (b.at or 0) end)
	return out
end

-- the standalone addon, when loaded, owns sync/votes/merge - delegate
local function ext() return _G.ForeverBlackListed end
-- the standalone's db never passes through our DB(), so its .sync slot
-- can be missing entirely (older standalone versions did not seed one) -
-- hand out the same guarantee either way (read + type check inside pcall:
-- secret-safe)
local function extdb()
	local e = ext()
	local db = e and e.db
	if type(db) ~= "table" then return DB() end
	local ok, isTab = pcall(function() return type(db.sync) == "table" end)
	if not (ok and isTab) then db.sync = {} end
	return db
end

local function Dirty()
	local db = DB()
	db.rev = (db.rev or 0) >= time() and (db.rev + 1) or time()
	local x = ext()
	if x and x.SyncDirty then x:SyncDirty()
	elseif F._liveShare then F._liveShare() end
end

-- name handling (ported: Forever names are "First Last", realm "-Realm") --------------
function F.CleanName(name)
	if type(name) ~= "string" then return nil end
	name = strtrim(name)
	if name == "" then return nil end
	name = name:gsub(":[^:]+$", "")
	name = name:gsub(":[^:]+:[^:]+$", "")
	local base = name:gsub("%-[^-]+$", "")
	if base:find(" ") then name = base end
	name = strtrim((name:gsub("%s%s+", " ")))
	if name == "" then return nil end
	return name
end

function F.SplitNameRealm(name)
	if type(name) ~= "string" then return nil end
	name = strtrim(name)
	if name == "" then return nil end
	name = name:gsub(":[^:]+$", "")
	name = name:gsub(":[^:]+:[^:]+$", "")
	local realm
	local base, suffix = name:match("^(.-)%-([^-]+)$")
	if suffix and base ~= "" and base:find(" ") then
		name, realm = base, suffix
	end
	return name, realm
end

local function Key(kind, name)
	local clean = F.CleanName(name)
	if not clean then return nil end
	return kind .. "|" .. clean:lower()
end
F.Key = Key -- the one-time importer probes for present entries with it

function F.GetUnitFullName(unit)
	local name
	if GetUnitName then
		local ok, n = pcall(GetUnitName, unit)
		if ok then name = n end
	end
	if (not name or name == "") and UnitName then
		local ok, n = pcall(UnitName, unit)
		if ok then name = n end
	end
	if not name or IsSecret(name) then return nil end
	return F.CleanName(name)
end

local function OwnAuthor()
	local me = F.GetUnitFullName("player")
	local author = me and F.CleanName(me)
	return author and author:lower() or nil, me
end

-- store ----------------------------------------------------------------------------
function F.FindEntry(kind, name)
	local k = Key(kind, name)
	return k and extdb().entries[k] or nil
end

function F.AddEntry(name, kind, group, note, guild, list, realm)
	local x = ext()
	if x then return x:AddEntry(name, kind, group, note, guild, list, realm) end
	kind = (kind == "guild") and "guild" or "player"
	local clean, parsedRealm = F.SplitNameRealm(name)
	if not clean then return nil, "empty" end
	note = (note and strtrim(note) ~= "") and strtrim(note) or nil
	if not note then return nil, "note_required" end
	realm = realm or parsedRealm
	if kind == "player" and not realm and GetRealmName then
		local ok, r = pcall(GetRealmName)
		if ok and type(r) == "string" and r ~= "" then realm = r end
	end
	local k = Key(kind, clean)
	local db = DB()
	if db.entries[k] then return nil, "exists", db.entries[k] end
	if not db.groups[group] then group = db.groups[db.lastGroup] and db.lastGroup or "other" end
	if not db.groups[group] then group = "other" end
	local e = {
		name = clean, kind = kind, group = group,
		list = (list == "good") and "good" or "black",
		note = note,
		guild = (kind == "player" and guild and strtrim(guild) ~= "") and strtrim(guild) or nil,
		realm = (kind == "player" and realm) and strtrim(realm) or nil,
		added = time(), mod = time(),
	}
	db.entries[k] = e
	db.tombstones[k] = nil
	local author, me = OwnAuthor()
	if author then
		e.notes = { [author] = { a = strtrim(me), n = e.note, t = e.added } }
		e.by = strtrim(me)
	end
	if F.RefreshWindow then F.RefreshWindow() end
	Dirty()
	return e
end

function F.RemoveEntry(entry)
	local x = ext()
	if x then return x:RemoveEntry(entry) end
	if not entry then return end
	local k = Key(entry.kind, entry.name)
	if k then
		DB().entries[k] = nil
		DB().tombstones[k] = time()
	end
	if F.RefreshWindow then F.RefreshWindow() end
	Dirty()
end

-- votes (ported): one vote per voter, last-write-wins merge over sync;
-- voting again toggles the vote off (deletion marker so merges cannot
-- resurrect it)
function F.VoteEntry(e, v)
	local x = ext()
	if x and x.VoteEntry then return x:VoteEntry(e, v) end
	if not e then return end
	local me = F.GetUnitFullName("player")
	local voter = me and F.CleanName(me)
	if not voter then return end
	voter = voter:lower()
	e.votes = e.votes or {}
	local mine = e.votes[voter]
	if v then
		if mine and not mine.del and (mine.v or 0) == v then
			e.votes[voter] = { v = 0, t = time(), del = true }
		else
			e.votes[voter] = { v = v, t = time() }
		end
	else
		e.votes[voter] = { v = 0, t = time(), del = true }
	end
	e.mod = time()
	Dirty()
end

function F.MyVote(e)
	local me = F.GetUnitFullName("player")
	local voter = me and F.CleanName(me)
	local v = voter and e.votes and e.votes[voter:lower()]
	return v and not v.del and v.v or nil
end

function F.SetGroup(e, gid)
	local x = ext()
	if x and x.SetGroup then return x:SetGroup(e, gid) end
	if not (e and gid and DB().groups[gid]) then return end
	e.group = gid
	e.mod = time()
	Dirty()
end

function F.SetList(e, list)
	if not e then return end
	e.list = (list == "good") and "good" or "black"
	e.mod = time()
	Dirty()
end

-- pretty export for the copy/paste popup
function F.ExportJSON()
	return F.JsonEncode(F.ExportTable(), true)
end

function F.CheckUnit(name, guild)
	local db = extdb()
	local pe = name and F.FindEntry("player", name) or nil
	local ge
	if db.tooltip.checkGuild and guild then
		ge = F.FindEntry("guild", guild)
	end
	return pe, ge
end

function F.EntryCount()
	local n = 0
	for _ in pairs(extdb().entries) do n = n + 1 end
	return n
end

function F.EntryVotes(e)
	local x = ext()
	if x then return x:EntryVotes(e) end
	local up, down = 0, 0
	for _, v in pairs(e.votes or {}) do
		if (v.v or 0) > 0 then up = up + 1 elseif (v.v or 0) < 0 then down = down + 1 end
	end
	return up, down, up - down
end

function F.AnyNote(e)
	local x = ext()
	if x then return x:AnyNote(e) end
	local author = OwnAuthor()
	local n = author and e.notes and e.notes[author]
	if n and not n.del and n.n then return n.n end
	for _, v in pairs(e.notes or {}) do
		if not v.del and v.n then return v.n end
	end
	return e.note
end

function F.GroupName(id)
	local g = extdb().groups[id]
	if not g then return "?" end
	return g.builtin and (L[g.name] or g.name) or g.name
end

function F.Groups()
	local db = extdb()
	local counts = {}
	for _, e in pairs(db.entries) do
		counts[e.group] = (counts[e.group] or 0) + 1
	end
	local list = {}
	for id, g in pairs(db.groups) do
		tinsert(list, { id = id, name = F.GroupName(id), count = counts[id] or 0 })
	end
	sort(list, function(a, b)
		return (db.groups[a.id] and db.groups[a.id].order or 99)
			< (db.groups[b.id] and db.groups[b.id].order or 99)
	end)
	return list
end

-- admin (ported): the built-in list admin, extra chars from
-- db.sync.admin, and - when the real addon is loaded - its channel
-- owner decide whose deletions count for everyone.
-- two admin characters: both are list admins everywhere the builtin
-- admin was honored before (deletes, request popups, admin page)
F.builtinAdmins = { "Xenshi Lucas", "Raziel Lucas" }

function F.EffectiveAdmins()
	local out = {}
	for _, a in ipairs(F.builtinAdmins) do
		local b = F.CleanName(a)
		if b then out[b:lower()] = true end
	end
	local cfg = extdb().sync and extdb().sync.admin
	if type(cfg) == "string" then
		for part in cfg:gmatch("[^,]+") do
			local c = F.CleanName(part:match("^%s*(.-)%s*$"))
			if c then out[c:lower()] = true end
		end
	end
	local x = ext()
	if x and x.EffectiveAdmins then
		for n in pairs(x:EffectiveAdmins()) do out[n] = true end
	end
	return out
end

function F.IsAdmin()
	local x = ext()
	if x and x.IsAdmin then return x:IsAdmin() end
	local me = F.GetUnitFullName("player")
	me = me and F.CleanName(me)
	return me ~= nil and F.EffectiveAdmins()[me:lower()] == true
end

-- notes: own note goes through SetNote, foreign notes need admin rights
-- and carry a tombstone stamped with the deleter
function F.SetNote(e, text)
	local x = ext()
	if x then return x:SetNote(e, text) end
	if not e then return end
	local author, me = OwnAuthor()
	if not author then return end
	e.notes = e.notes or {}
	text = (type(text) == "string") and strtrim(text) or nil
	if text and text ~= "" then
		e.notes[author] = { a = strtrim(me), n = text, t = time() }
		e.note = text
	else
		e.notes[author] = { t = time(), del = true }
		e.note = nil
	end
	e.mod = time()
	Dirty()
end

function F.DeleteNote(e, author)
	local x = ext()
	if x then return x:DeleteNote(e, author) end
	if not (e and type(author) == "string") then return end
	author = author:lower()
	local myKey = OwnAuthor()
	if not myKey then return end
	if author == myKey then F.SetNote(e, "") return end
	if not F.IsAdmin() then return end
	if not e.notes or not e.notes[author] or e.notes[author].del then return end
	e.notes[author] = { t = time(), del = true, by = myKey }
	e.mod = time()
	Dirty()
end

function F.SortedEntries()
	local db = extdb()
	local out = {}
	for _, e in pairs(db.entries) do out[#out + 1] = e end
	sort(out, function(a, b)
		local ga = db.groups[a.group] and db.groups[a.group].order or 99
		local gb = db.groups[b.group] and db.groups[b.group].order or 99
		if ga ~= gb then return ga < gb end
		return (a.name or ""):lower() < (b.name or ""):lower()
	end)
	return out
end

-- actions ---------------------------------------------------------------------------
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs.SENTIFBL_NOTE = {
	text = L["Blacklist note for %s"],
	button1 = OKAY or "OK",
	button2 = CANCEL or "Cancel",
	hasEditBox = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, data)
		local text = strtrim(self.editBox and self.editBox:GetText() or "")
		if text ~= "" and data then
			F.AddEntry(data.name, data.kind, data.group, text, data.guild, data.list, data.realm)
		end
	end,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent()
		if parent and parent.button1 then parent.button1:Click() end
	end,
}

function F.PromptAdd(name, kind, list, guild, realm, group)
	local clean, r = F.SplitNameRealm(name)
	if not clean then return end
	if F.FindEntry(kind, clean) then
		S.Print(format(L["%s is already listed"], clean))
		return
	end
	StaticPopup_Show("SENTIFBL_NOTE", clean, nil, {
		name = clean, kind = kind or "player", list = list,
		guild = guild, realm = realm or r, group = group,
	})
end

function F.AddUnit(unit)
	if not UnitExists or not UnitExists(unit) then return end
	local okP, isPlayer = pcall(UnitIsPlayer, unit)
	if not okP or not isPlayer then
		S.Print(L["Target is not a player"])
		return
	end
	local name = F.GetUnitFullName(unit)
	local guild
	if GetGuildInfo then
		local ok, g = pcall(GetGuildInfo, unit)
		if ok and g and g ~= "" and not IsSecret(g) then guild = g end
	end
	F.PromptAdd(name, "player", nil, guild)
end

function F.RemoveUnit(unit)
	local name = F.GetUnitFullName(unit)
	local e = name and F.FindEntry("player", name)
	if e then F.RemoveEntry(e) else S.Print(L["Not listed"]) end
end

-- warnings (ported from Warn.lua) ---------------------------------------------------
local function Blacklisted(name)
	name = F.CleanName(name)
	local e = name and F.FindEntry("player", name)
	return (e and e.list ~= "good") and e or nil
end

local warn = CreateFrame("Frame")
warn:RegisterEvent("CHAT_MSG_WHISPER")
warn:RegisterEvent("PARTY_INVITE_REQUEST")
warn:SetScript("OnEvent", function(_, event, arg1, arg2)
	local db = extdb()
	if not (db and db.warn) then return end
	if event == "CHAT_MSG_WHISPER" then
		if not db.warn.whisper then return end
		local e = Blacklisted(arg2)
		if e then
			S.Print(format("|cffff5555" .. L["Blacklisted player %s whispers you"] .. "|r", e.name))
		end
	elseif event == "PARTY_INVITE_REQUEST" then
		local e = Blacklisted(arg1)
		if not e then return end
		if db.warn.autoDecline and StaticPopup_Hide then
			StaticPopup_Hide("PARTY_INVITE")
			S.Print(format("|cffff5555" .. L["Auto-declined invite from %s"] .. "|r", e.name))
		elseif db.warn.invite then
			S.Print(format("|cffff5555" .. L["Blacklisted player %s invites you"] .. "|r", e.name))
		end
	end
end)

-- tooltip lines (ported) ------------------------------------------------------------
local ACCENT, DIM = "ebad33", "8c919f"
local function TipLines(tip)
	local db = extdb()
	if not db then return end
	local ok, _, unit = pcall(tip.GetUnit, tip)
	if not ok or not unit or IsSecret(unit) then return end
	local okP, isPlayer = pcall(UnitIsPlayer, unit)
	if not okP or not isPlayer then return end
	local name = F.GetUnitFullName(unit)
	if not name then return end
	local guild
	if GetGuildInfo then
		local ok2, g = pcall(GetGuildInfo, unit)
		if ok2 and g and g ~= "" and not IsSecret(g) then guild = g end
	end

	local auto = db.auto
	if auto and auto.enabled and not F.FindEntry("player", name) then
		local note
		local okL, lvl = pcall(UnitLevel, unit)
		if okL and type(lvl) == "number" and not IsSecret(lvl)
			and lvl > 0 and lvl < (auto.level or 0) then
			note = format(L["auto: below level %d"], lvl)
		end
		if not note and auto.guildMembers and guild then
			local ge = F.FindEntry("guild", guild)
			if ge and ge.list ~= "good" then note = L["auto: guild member"] end
		end
		if not note and auto.realm and auto.realm ~= "" then
			local okN, raw = pcall(GetUnitName or UnitName, unit)
			local realm = (okN and type(raw) == "string") and raw:match("%-(.+)$") or nil
			if realm and not IsSecret(realm) and realm:lower() == auto.realm:lower() then
				note = format(L["auto: realm %s"], realm)
			end
		end
		if note then F.AddEntry(name, "player", auto.group, note, guild) end
	end

	if not db.tooltip.enabled then return end
	local entry, guildEntry = F.CheckUnit(name, guild)
	if entry then
		local good = entry.list == "good"
		tip:AddDoubleLine("|cff" .. ACCENT .. L["Blacklist:"] .. "|r",
			good and "|cff4dd278" .. L["Good list"] .. "|r"
				or "|cffff5555" .. L["Yes"] .. "|r")
		local detail = F.GroupName(entry.group)
		local up, down = F.EntryVotes(entry)
		if up + down > 0 then
			detail = detail .. format("  |cff4dd278+%d|r |cffff5555-%d|r", up, down)
		end
		if entry.realm then
			detail = detail .. "  |cff8c919f@" .. entry.realm .. "|r"
		end
		if db.tooltip.showNote then
			local mn = F.AnyNote(entry)
			if mn then detail = detail .. " - " .. mn end
		end
		tip:AddLine("|cff" .. DIM .. detail .. "|r")
		tip:Show()
	elseif guildEntry then
		local good = guildEntry.list == "good"
		tip:AddDoubleLine("|cff" .. ACCENT .. L["Blacklist:"] .. "|r",
			"|cffff5555" .. L["Guild"] .. "|r" ..
			(good and " |cff4dd278" .. L["Good list"] .. "|r" or ""))
		tip:AddLine("|cff" .. DIM .. guildEntry.name .. "|r")
		tip:Show()
	elseif db.tooltip.showClear then
		tip:AddDoubleLine("|cff" .. ACCENT .. L["Blacklist:"] .. "|r",
			"|cff" .. DIM .. L["No"] .. "|r")
		tip:Show()
	end
end

local TDP = TooltipDataProcessor
local unitType = Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit
-- tooltip lines only via TooltipDataProcessor: an insecure HookScript
-- handler on GameTooltip taints its whole dispatch - Blizzard's own
-- unit-health update then died inside our call chain (the
-- "blizzard: GameTooltip / TextStatusBar" reports)
if TDP and TDP.AddTooltipPostCall and unitType then
	TDP.AddTooltipPostCall(unitType, function(tip)
		if tip ~= GameTooltip or (ext() and ext().db) then return end
		S.SafeCall("fbl:tip", TipLines, tip)
	end)
end

-- removal requests (ported): non-admins ask an admin to delete an
-- entry; "FBLreq;kind;name;reason" rides the FBLsync channel, the
-- admin side shows an accept popup and the tombstone spreads on sync.
local reqQueue, reqSeen = {}, {}
local PREFIX = "FBLsync"
local chanNum, chanName

local SendPullRequest -- defined in the sync block below

local function ChanNum(name)
	local f = GetChannelName or (C_ChatInfo and C_ChatInfo.GetChannelName)
	if not f then return nil end
	local ok, n = pcall(f, name)
	n = ok and tonumber(n)
	return (n and n > 0) and n or nil
end

local function DoJoin(name)
	-- channel joins are protected during combat lockdown
	-- (ADDON_ACTION_BLOCKED): wait for combat to end instead
	if InCombatLockdown and InCombatLockdown() then
		S.RunOutOfCombat(function() DoJoin(name) end)
		return
	end
	local join = JoinTemporaryChannel or JoinChannelByName
		or (C_ChatInfo and (C_ChatInfo.JoinTemporaryChannel or C_ChatInfo.JoinChannelByName))
	if join then ns.HardAPI("JoinChannelByName", join, name) end
end

-- default channels must exist first or the join is silently dropped
local function ChannelsReady()
	local f = GetChannelList or (C_ChatInfo and C_ChatInfo.GetChannelList)
	if not f then return true end
	local ok, n = pcall(function() return select("#", f()) end)
	return not ok or n > 0
end

local OnJoined -- defined below
local DataHash, QueueChannelSend, SendVersionPing -- sync block below

local joinTries = 0
local function JoinSync()
	if chanNum or joinTries > 30 then return end
	local names = { "ForeverBlackListed", "FBLsync" }
	for _, name in ipairs(names) do
		local n = ChanNum(name)
		if n then
			chanNum, chanName = n, name
			OnJoined()
			return
		end
	end
	if not ChannelsReady() then
		joinTries = joinTries + 1
		C_Timer.After(1, JoinSync)
		return
	end
	DoJoin(names[1])
	C_Timer.After(3, function()
		local n = ChanNum(names[1])
		if n then
			chanNum, chanName = n, names[1]
			OnJoined()
			return
		end
		DoJoin(names[2])
		C_Timer.After(3, function()
			local n2 = ChanNum(names[2])
			if n2 then
				chanNum, chanName = n2, names[2]
				OnJoined()
				return
			end
			joinTries = joinTries + 1
			C_Timer.After(5, JoinSync)
		end)
	end)
end

local function PrefixRegistered()
	local f = C_ChatInfo and C_ChatInfo.IsAddonMessagePrefixRegistered
		or IsAddonMessagePrefixRegistered
	if not f then return nil end
	local ok, r = pcall(f, PREFIX)
	return ok and r or nil
end

-- live channel roster (everyone in the channel, not just FBL speakers):
-- GetChannelRosterInfo needs the channel's index in the client channel
-- list, not its number - resolve it through GetChannelList triplets
local function LiveRosterCount()
	if not chanNum then return nil end
	local ri = C_ChatInfo and C_ChatInfo.GetChannelRosterInfo
		or GetChannelRosterInfo
	if type(ri) ~= "function" then return nil end
	local gl = GetChannelList or (C_ChatInfo and C_ChatInfo.GetChannelList)
	if type(gl) ~= "function" then return nil end
	local idx
	local ok, res = pcall(function() return { gl() } end)
	if ok and type(res) == "table" then
		for i = 1, #res, 3 do
			if tonumber(res[i]) == chanNum then idx = (i + 2) / 3 break end
		end
	end
	if not idx then return nil end
	local n = 0
	for i = 1, 500 do
		local okR, nm = pcall(ri, idx, i)
		if not okR or not nm then break end
		n = n + 1
	end
	return n
end

function F.Debug()
	local pend = 0
	for _ in pairs(pending) do pend = pend + 1 end
	local reg = PrefixRegistered()
	S.Print(format("FBL: channel=%s prefix=%s autoAccept=%s trust=%s entries=%d pending=%d lastSync=%s",
		tostring(chanNum or "-"),
		reg == nil and "?" or tostring(reg),
		tostring(DB().sync and DB().sync.autoAccept),
		tostring(DB().sync and DB().sync.trust),
		F.EntryCount(),
		pend,
		tostring(DB().sync and DB().sync.lastFrom or "-")))
end

-- once in the channel: announce our version+rev, ask for the newest
-- list and push ours when it changed since our last broadcast - the
-- same three-way handshake the standalone performs on join
OnJoined = function()
	Log("info", format(L["Joined sync channel '%s' (#%d)"], chanName or "?", chanNum or 0))
	C_Timer.After(3, SendVersionPing)
	C_Timer.After(4, SendPullRequest)
	if DataHash() ~= (DB().sync.lastHash or -1) then
		C_Timer.After(5, QueueChannelSend)
	end
end

-- rejoin watchdog: a lost channel rejoins within two minutes, like
-- the standalone's self-heal timer
C_Timer.NewTicker(120, function()
	local n, nm
	for _, name in ipairs({ "ForeverBlackListed", "FBLsync" }) do
		n = ChanNum(name)
		if n then nm = name break end
	end
	if n then
		if n ~= chanNum then chanNum, chanName = n, nm end -- slot moved, re-resolve
		return
	end
	chanNum = nil
	joinTries = 0
	JoinSync()
end)

-- periodic version ping, same 30 min cadence as the standalone
-- (closure - SendVersionPing is assigned further down this file)
C_Timer.NewTicker(1800, function() SendVersionPing() end)

local function RegisterPrefix()
	local f = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix
		or RegisterAddonMessagePrefix
	if f then pcall(f, PREFIX) end
end
S.RegisterEvent("PLAYER_LOGIN", function()
	RegisterPrefix()
	C_Timer.After(5, JoinSync)
end)

StaticPopupDialogs.SENTIFBL_DEL_REQUEST = {
	text = L["Removal request for %s:\n%s"],
	button1 = YES or "Yes",
	button2 = NO or "No",
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, data)
		local e = data and F.FindEntry(data.kind, data.name)
		if e then F.RemoveEntry(e) end
	end,
	-- no OnHide: Escape hides the popup via hideOnEscape and an
	-- OnHide callback runs insecure Lua inside the Escape dispatch,
	-- tainting the engine's spell-stop calls after it. Visibility
	-- is tracked natively via StaticPopup_Visible instead.
}

local function ShowNextRequest()
	if type(StaticPopup_Visible) == "function"
		and StaticPopup_Visible("SENTIFBL_DEL_REQUEST") then
		return
	end
	local req = table.remove(reqQueue, 1)
	if not req then return end
	StaticPopup_Show("SENTIFBL_DEL_REQUEST", req.name,
		format("%s: %s", req.sender or "?", req.reason ~= "" and req.reason or "-"), req)
end

local function OnRemovalRequest(sender, kind, name, reason)
	PeerSeen(sender)
	if not F.IsAdmin() then return end
	if type(name) ~= "string" or name == "" then return end
	local key = (sender or "?") .. "|" .. kind .. "|" .. name
	local now = time()
	if reqSeen[key] and now - reqSeen[key] < 120 then return end
	reqSeen[key] = now
	Log("in", format(L["Removal request from %s: %s"], sender or "?", name))
	tinsert(reqQueue, { sender = sender, kind = kind, name = name,
		reason = reason or "" })
	ShowNextRequest()
end

function F.PendingRequests()
	return reqQueue
end

function F.ResolveRequest(req, accept)
	for i, r in ipairs(reqQueue) do
		if r == req then table.remove(reqQueue, i) break end
	end
	if accept then
		local e = F.FindEntry(req.kind, req.name)
		if e then F.RemoveEntry(e) end
	end
	if F.RefreshWindow then F.RefreshWindow() end
end

-- merge helpers (ported): per-author notes and per-voter votes merge
-- last-write-wins; deletes are honored only from the author or an admin
local function MergeVotes(e, remote)
	if type(remote) ~= "table" then return end
	local myKey = OwnAuthor()
	for voter, rv in pairs(remote) do
		if type(rv) == "table" and type(voter) == "string"
			and voter ~= myKey then
			local lv = e.votes and e.votes[voter]
			local rt = tonumber(rv.t) or 0
			if not lv or rt > (lv.t or 0) then
				e.votes = e.votes or {}
				if rv.del then
					e.votes[voter] = { v = 0, t = rt, del = true }
				else
					e.votes[voter] = { v = (tonumber(rv.v) or 0) >= 0 and 1 or -1, t = rt }
				end
			end
		end
	end
end

local function MergeNotes(e, remote)
	if type(remote) ~= "table" then return end
	local myKey = OwnAuthor()
	for author, rn in pairs(remote) do
		if type(rn) == "table" and type(author) == "string"
			and author ~= myKey then
			local ln = e.notes and e.notes[author]
			local rt = tonumber(rn.t) or 0
			if not ln or rt > (ln.t or 0) then
				if rn.del then
					local by = type(rn.by) == "string" and rn.by:lower() or author
					if by == author or F.EffectiveAdmins()[by] then
						e.notes = e.notes or {}
						e.notes[author] = { t = rt, del = true,
							by = (by ~= author) and by or nil }
					end
				elseif type(rn.n) == "string" and rn.n ~= "" then
					local disp = (type(rn.a) == "string"
						and rn.a:lower() == author:lower()) and rn.a or author
					e.notes = e.notes or {}
					e.notes[author] = { a = disp, n = rn.n, t = rt }
				end
			end
		end
	end
end

local function AdoptSenderNote(e, noteText, sender, ts)
	if type(noteText) ~= "string" or strtrim(noteText) == "" then return end
	local clean = sender and F.CleanName(sender)
	if not clean then return end
	local author = clean:lower()
	local ln = e.notes and e.notes[author]
	local rt = tonumber(ts) or time()
	if not ln or rt > (ln.t or 0) then
		e.notes = e.notes or {}
		e.notes[author] = { a = clean, n = noteText, t = rt }
	end
end

function F.AddGroup(name)
	name = strtrim(name or "")
	if name == "" then return nil end
	for id, g in pairs(DB().groups) do
		if F.GroupName(id):lower() == name:lower() then return id end
	end
	DB().groupSeq = (DB().groupSeq or 3) + 1
	local id = "g" .. DB().groupSeq
	local maxOrder = 0
	for _, g in pairs(DB().groups) do
		if (g.order or 0) > maxOrder then maxOrder = g.order end
	end
	DB().groups[id] = { name = name, order = maxOrder + 1, builtin = false }
	return id
end

-- export/import (ported): the same JSON shape the standalone writes,
-- so an import from us merges into a real FBL client identically
function F.ExportTable()
	local groups = {}
	for id, g in pairs(DB().groups) do
		tinsert(groups, { id = id, name = g.name, builtin = g.builtin and true or nil })
	end
	local entries = {}
	local list = {}
	for _, e in pairs(DB().entries) do tinsert(list, e) end
	sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
	for _, e in ipairs(list) do
		tinsert(entries, {
			name = e.name, kind = e.kind, group = e.group,
			list = (e.list == "good") and "good" or nil,
			guild = e.guild, realm = e.realm, note = e.note,
			notes = (e.notes and next(e.notes)) and e.notes or nil,
			rating = e.rating,
			votes = (e.votes and next(e.votes)) and e.votes or nil,
			added = e.added, mod = e.mod or e.added, by = e.by,
		})
	end
	local tombs = {}
	for k, ts in pairs(DB().tombstones or {}) do
		local kind, name = k:match("^(%a+)|(.+)$")
		if kind and name then
			tinsert(tombs, { kind = kind, name = name, removed = ts })
		end
	end
	sort(tombs, function(a, b) return a.name < b.name end)
	return {
		app = "ForeverBlackListed", version = 1, exported = time(),
		rev = DB().rev or 0,
		groups = groups, entries = entries, tombstones = tombs,
	}
end

function F.ExportWireJSON()
	return (F.JsonEncode(F.ExportTable()):gsub("|", "\\u007c"))
end

local function resolveGroup(ref, groupsById, groupsByName)
	if type(ref) ~= "string" or ref == "" then return nil end
	if groupsById[ref] then return ref end
	local byName = groupsByName[ref:lower()]
	if byName then return byName end
	return F.AddGroup(ref)
end

-- remote deletions only apply when the sender is a configured list admin
local function RemoteDeleteAllowed(sender)
	if not sender then return true end
	local s = F.CleanName(sender)
	return s ~= nil and F.EffectiveAdmins()[s:lower()] == true
end

function F.ImportJSON(text, sender, quiet)
	local data, err = F.JsonDecode(text)
	if not data then return nil, err end
	if type(data) == "table" and data.entries == nil and data[1] ~= nil then
		data = { entries = data }
	end
	if type(data) ~= "table" or type(data.entries) ~= "table" then
		return nil, L["Invalid import data"]
	end
	local db = DB()
	local groupsById, groupsByName = {}, {}
	for id, g in pairs(db.groups) do
		groupsById[id] = true
		groupsByName[g.name:lower()] = id
		groupsByName[F.GroupName(id):lower()] = id
	end
	if type(data.groups) == "table" then
		for _, g in ipairs(data.groups) do
			if type(g) == "table" and type(g.name) == "string" then
				local gid = type(g.id) == "string" and g.id or nil
				if gid and groupsById[gid] then
				elseif groupsByName[g.name:lower()] then
				elseif gid then
					db.groupSeq = (db.groupSeq or 3) + 1
					local maxOrder = 0
					for _, og in pairs(db.groups) do
						if (og.order or 0) > maxOrder then maxOrder = og.order end
					end
					db.groups[gid] = { name = g.name, order = maxOrder + 1, builtin = false }
					groupsById[gid] = true
					groupsByName[g.name:lower()] = gid
				end
			end
		end
	end
	local maxTs = time() + 300
	if RemoteDeleteAllowed(sender) and type(data.tombstones) == "table" then
		for _, t in ipairs(data.tombstones) do
			if type(t) == "table" then
				local clean = F.CleanName(t.name)
				local ts = math.min(tonumber(t.removed) or 0, maxTs)
				if clean then
					local k = Key(t.kind == "guild" and "guild" or "player", clean)
					if k and ts > (db.tombstones[k] or 0) then
						db.tombstones[k] = ts
					end
				end
			end
		end
	end
	local removed = 0
	for k, ts in pairs(db.tombstones) do
		local e = db.entries[k]
		if e and ts > (e.added or 0) then
			db.entries[k] = nil
			removed = removed + 1
		end
	end
	local added, updated = 0, removed
	for _, raw in ipairs(data.entries) do
		if type(raw) == "table" and type(raw.name) == "string" then
			local kind = (raw.kind == "guild") and "guild" or "player"
			local clean = F.CleanName(raw.name)
			if clean then
				local k = Key(kind, clean)
				local addedTs = math.min(tonumber(raw.added) or time(), maxTs)
				local modTs = math.min(tonumber(raw.mod) or addedTs, maxTs)
				local ts = db.tombstones[k] or 0
				if ts > addedTs then
					if db.entries[k] then
						db.entries[k] = nil
						updated = updated + 1
					end
				else
					if addedTs > ts then db.tombstones[k] = nil end
					local group = resolveGroup(raw.group, groupsById, groupsByName) or "other"
					local note = type(raw.note) == "string" and strtrim(raw.note) or nil
					if note == "" then note = nil end
					local guild = type(raw.guild) == "string" and strtrim(raw.guild) or nil
					if guild == "" then guild = nil end
					local realm = type(raw.realm) == "string" and strtrim(raw.realm) or nil
					if realm == "" then realm = nil end
					local rating = tonumber(raw.rating)
					if rating then rating = math.floor(math.min(5, math.max(1, rating))) end
					local newList = (raw.list == "good") and "good" or nil
					local byName = type(raw.by) == "string" and strtrim(raw.by)
					if byName == "" then byName = nil end
					if byName then byName = byName:sub(1, 60) end
					local e = db.entries[k]
					if e then
						if modTs > (e.mod or e.added or 0) then
							e.group = group
							e.guild = guild or e.guild
							e.realm = realm or e.realm
							e.rating = rating
							e.list = newList or "black"
							e.added = math.min(e.added or modTs, addedTs)
							e.by = e.by or byName
							e.mod = modTs
							updated = updated + 1
						end
						AdoptSenderNote(e, note, sender, modTs)
						MergeNotes(e, raw.notes)
						MergeVotes(e, raw.votes)
						if sender then e.note = nil end
					else
						e = {
							name = clean, kind = kind, group = group,
							list = newList or "black", note = note,
							guild = guild,
							realm = (kind == "player") and realm or nil,
							rating = rating, added = addedTs, mod = modTs,
							by = byName,
						}
						db.entries[k] = e
						AdoptSenderNote(e, note, sender, modTs)
						MergeNotes(e, raw.notes)
						MergeVotes(e, raw.votes)
						if sender then e.note = nil end
						added = added + 1
					end
				end
			end
		end
	end
	if tonumber(data.rev) then
		db.rev = math.max(db.rev or 0, tonumber(data.rev))
	end
	if F.RefreshWindow then F.RefreshWindow() end
	if (added > 0 or updated > 0) and not quiet then Dirty() end
	return added, updated
end

-- wire sync: "Sync all" pushes the whole list as chunked JSON onto the
-- sync channel; chunk format matches the standalone ("FBLv1;i;total;chunk"
-- on the FBLsync addon prefix and on channel chat), so FBL clients and
-- ours reassemble/merge each other's payloads identically
local SYNC_CHUNK = 200
local pending, lastDone = {}, {}
local sendQueue, sendTicker
local ignored = {}
local seenPeers = {} -- session-only: first FBLver per sender hits the log

DataHash = function()
	local h, n = 0, 0
	for _, e in pairs(DB().entries) do
		n = n + 1
		local nc = 0
		for _ in pairs(e.notes or {}) do nc = nc + 1 end
		local nv = 0
		for _ in pairs(e.votes or {}) do nv = nv + 1 end
		h = (h * 33 + #(e.name or "") + #(e.note or "") + #(e.guild or "")
			+ nc + nv + (e.rating or 0) + (e.list == "good" and 7 or 3)
			+ (e.mod or 0) % 9973) % 16777216
	end
	for _, ts in pairs(DB().tombstones or {}) do
		h = (h * 33 + ts % 65536) % 16777216
	end
	return h * 1024 + n
end

-- trust check for channel auto-accept: "all" | "guild" | "friends"
local function Trusted(name)
	local mode = (DB().sync and DB().sync.trust) or "all"
	if mode == "all" then return true end
	local function norm(n)
		n = n and F.CleanName(n)
		return n and n:gsub("%-[^%-]+$", ""):lower() or nil
	end
	name = norm(name)
	if not name then return false end
	local function same(a)
		a = norm(a)
		return a ~= nil and a == name
	end
	if IsInGuild and IsInGuild() and GetNumGuildMembers then
		local ok, n = pcall(GetNumGuildMembers)
		if ok and n then
			for i = 1, n do
				local okR, gn = pcall(GetGuildRosterInfo, i)
				if okR and same(gn) then return true end
			end
		end
	end
	if mode == "guild" then return false end
	local num = 0
	if C_FriendList and C_FriendList.GetNumFriends then
		num = C_FriendList.GetNumFriends() or 0
	elseif GetNumFriends then
		num = GetNumFriends() or 0
	end
	for i = 1, num do
		local fn
		if C_FriendList and C_FriendList.GetFriendInfoByIndex then
			local info = C_FriendList.GetFriendInfoByIndex(i)
			fn = info and info.name
		elseif GetFriendInfo then
			fn = GetFriendInfo(i)
		end
		if same(fn) then return true end
	end
	return false
end

-- after our list changes (merge, manual import), rebroadcast version
-- and stats soon-ish so peer panels see the fresh rev/count quickly
local statTimer
local function AnnounceStats()
	if statTimer then return end
	statTimer = C_Timer.NewTimer(10, function()
		statTimer = nil
		SendVersionPing()
	end)
end

local function MergeReceived(json, from, quiet)
	local wasClean = DataHash() == (DB().sync.lastHash or -1)
	local added, updated = F.ImportJSON(json, from, true)
	if added then
		if added > 0 or updated > 0 then AnnounceStats() end
		if wasClean then DB().sync.lastHash = DataHash() end
		DB().sync.lastFrom, DB().sync.lastAt = from, time()
		if not quiet and (added > 0 or updated > 0) then
			S.Print(format(L["Sync from %s: %d added, %d updated"], from, added, updated))
		end
		Log("in", format(L["Sync from %s: %d added, %d updated"], from, added, updated))
	else
		Log("in", format("%s: %s", from, tostring(updated or L["Invalid import data"])))
		S.Print("|cffff5555" .. from .. ": " .. tostring(updated or L["Invalid import data"]) .. "|r")
	end
end

StaticPopupDialogs.SENTIFBL_SYNC_ACCEPT = {
	text = L["Accept blacklist sync from %s?"],
	button1 = YES or "Yes",
	button2 = NO or "No",
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, data)
		if data then MergeReceived(data.json, data.from) end
	end,
}

local function OwnNameLower()
	local me = F.GetUnitFullName("player")
	me = me and F.CleanName(me)
	return me and me:lower() or nil
end

local function FinishReceive(from, transport)
	if from and from:lower() == OwnNameLower() then return end -- own echo
	local key = transport .. "|" .. from
	local s = pending[key]
	if not s then return end
	pending[key] = nil
	local json = table.concat(s.parts)
	Log("in", format(L["List received from %s via %s (%d chunks)"], from, transport, s.total))
	-- the same export arriving on a second transport within two
	-- minutes is the other half of a "Sync all" - merge only once
	local done = lastDone[from]
	if done and done.json == json and time() - done.at < 120 then
		Log("in", format(L["Duplicate list from %s ignored"], from))
		return
	end
	lastDone[from] = { json = json, at = time() }
	if not (DB().sync and DB().sync.autoAccept) then
		Log("in", format(L["Sync offer from %s - awaiting your accept"], from))
		StaticPopup_Show("SENTIFBL_SYNC_ACCEPT", from, nil,
			{ json = json, from = from })
		return
	end
	if not Trusted(from) then
		if not ignored[from] then
			ignored[from] = true
			Log("in", format(L["Ignored sync from %s (not trusted)"], from))
			S.Print(format("|cff8c919f" .. L["Ignored sync from %s (not trusted)"] .. "|r", from))
		end
		return
	end
	MergeReceived(json, from)
end

-- pull requests: "FBLpull;rev" asks the channel for a newer list; the
-- answer is jittered so several peers don't dump their exports at once,
-- and skipped when our revision is not ahead of the requester's
local pullRespAt = 0
-- QueueChannelSend is forward-declared next to OnJoined above;
-- OnPullRequest defers into it
local function OnPullRequest(text, sender)
	local reqRev = tonumber(text:match("^FBLpull;(%d+)"))
	if reqRev then PeerSeen(sender, nil, reqRev) end
	if not reqRev or (DB().rev or 0) <= reqRev then return end
	if not (DB().sync and DB().sync.liveShare) then return end
	if time() - pullRespAt < 60 then return end
	pullRespAt = time()
	Log("in", format(L["Pull request from %s (rev %d)"], sender or "?", reqRev))
	C_Timer.After(math.random(5, 40), function()
		if (DB().rev or 0) > reqRev then
			Log("out", format(L["Answering pull from %s"], sender or "?"))
			QueueChannelSend()
		end
	end)
end

-- ask the channel for the newest list once we are in - peers whose
-- rev is ahead push theirs back
SendPullRequest = function()
	if not chanNum then return end
	if InCombatLockdown and InCombatLockdown() then return end
	local msg = "FBLpull;" .. tostring(DB().rev or 0)
	-- addon messages only: SendChatMessage on a channel is hardware-gated
	-- on this client, every timer-driven attempt raised a blocked call
	local f = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
	ns.HardAPI("SendAddonMessage", f, PREFIX, msg, "CHANNEL", chanNum)
	Log("out", format(L["Requested list update (rev %d)"], DB().rev or 0))
end

-- rate-limited pull triggered by peer version pings: a peer
-- advertising a newer rev makes us ask the channel for it
local pullSentAt = 0
local function MaybePull()
	if time() - pullSentAt < 600 then return end
	pullSentAt = time()
	SendPullRequest()
end

local function OurVersion()
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		local ok, v = pcall(C_AddOns.GetAddOnMetadata, "SentiUI_Panel", "Version")
		if ok and type(v) == "string" and v ~= "" then return v end
	end
	return "0"
end

-- announce version + list rev so peers can spot a newer list and pull
SendVersionPing = function()
	if not chanNum then return end
	if InCombatLockdown and InCombatLockdown() then return end
	local msg = "FBLver;SentiUI_Panel-" .. OurVersion()
		.. ";" .. tostring(DB().rev or 0)
	-- FBLstat rides alongside, not inside FBLver: extending the version
	-- message could break the standalone's parser, while an unknown
	-- message type is simply ignored by older clients
	local stat = format("FBLstat;%d;%d", DB().rev or 0, F.EntryCount())
	local f = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
	if f then
		ns.HardAPI("SendAddonMessage", f, PREFIX, msg, "CHANNEL", chanNum)
		ns.HardAPI("SendAddonMessage", f, PREFIX, stat, "CHANNEL", chanNum)
		if IsInGuild and IsInGuild() then
			ns.HardAPI("SendAddonMessageGUILD", f, PREFIX, msg, "GUILD")
			ns.HardAPI("SendAddonMessageGUILD", f, PREFIX, stat, "GUILD")
		end
		Log("out", format(L["Version ping sent (rev %d)"], DB().rev or 0))
	end
end

local function OnChunk(from, transport, seq, total, chunk)
	from = F.CleanName(from)
	if not (from and seq and total and chunk) then return end
	if total < 1 or total > 2000 then return end
	PeerSeen(from)
	local key = transport .. "|" .. from
	local s = pending[key]
	if not s or s.total ~= total then
		s = { total = total, parts = {}, got = 0 }
		pending[key] = s
	end
	if not s.parts[seq] then
		s.parts[seq] = chunk
		s.got = s.got + 1
	end
	if s.got >= total then FinishReceive(from, transport) end
end

-- paced drain: addon-channel messages need no hardware event, one
-- chunk per tick keeps us under the message throttle
local sendFailed = 0
local function DrainSend()
	-- channel sends are combat-restricted on this client; the ticker
	-- keeps running and resumes once combat ends
	if InCombatLockdown and InCombatLockdown() then return end
	local msg = sendQueue[1]
	if not (msg and chanNum) then
		if sendTicker then sendTicker:Cancel() sendTicker = nil end
		return
	end
	local sent
	local f = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
	if f then sent = ns.HardAPI("SendAddonMessage", f, PREFIX, msg, "CHANNEL", chanNum) end
	-- channel chat is hardware-gated: only drains while a real input
	-- event is active (the Sync-all click); otherwise it errors and
	-- the chunk stays queued for the next tick
	if sent then table.remove(sendQueue, 1)
	else sendFailed = sendFailed + 1 end
	if #sendQueue == 0 and sendTicker then
		sendTicker:Cancel()
		sendTicker = nil
		if sendFailed > 0 then
			Log("out", format(L["Send failed: %d chunks rejected"], sendFailed))
			S.Print("|cffff5555" .. format(L["Send failed: %d chunks rejected"], sendFailed) .. "|r")
		else
			Log("out", L["Blacklist sent"])
			S.Print(L["Blacklist sent"])
		end
		sendFailed = 0
	end
end

QueueChannelSend = function()
	if not chanNum then return end
	local json = F.ExportWireJSON()
	local total = math.ceil(#json / SYNC_CHUNK)
	if total == 0 then return end
	sendQueue = {}
	for i = 1, total do
		sendQueue[i] = format("FBLv1;%d;%d;%s", i, total,
			json:sub((i - 1) * SYNC_CHUNK + 1, i * SYNC_CHUNK))
	end
	DB().sync.lastHash = DataHash()
	Log("out", format(L["Sending blacklist: %d chunks"], total))
	if not sendTicker then sendTicker = C_Timer.NewTicker(0.3, DrainSend) end
end

-- live share: local changes rebroadcast after a short debounce
local liveTimer
F._liveShare = function()
	if not (chanNum and DB().sync and DB().sync.liveShare) then return end
	if liveTimer then liveTimer:Cancel() end
	liveTimer = C_Timer.NewTimer(6, function()
		liveTimer = nil
		QueueChannelSend()
	end)
end

function F.SyncSendChannel()
	local x = ext()
	if x and x.SyncSendChannel then
		Log("out", L["Send delegated to ForeverBlackListed"])
		return x:SyncSendChannel()
	end
	if not chanNum then JoinSync() end
	if not chanNum then
		Log("out", L["Not in the sync channel"])
		S.Print("|cffff5555" .. L["Not in the sync channel"] .. "|r")
		return
	end
	QueueChannelSend()
	if #sendQueue > 0 then
		S.Print(format(L["Sending blacklist: %d chunks"], #sendQueue))
	end
end

local function AdminGate()
	if F.IsAdmin() then return true end
	S.Print("|cffff5555" .. L["Only list admins can sync all"] .. "|r")
	return false
end

-- admin "Sync all": the full list onto the sync channel; with the
-- standalone loaded it additionally pushes on the guild channel
function F.SyncAll()
	if not AdminGate() then return end
	local x = ext()
	if x then
		Log("out", L["Sync-all delegated to ForeverBlackListed (channel + guild)"])
		if x.SyncSendChannel then x:SyncSendChannel() end
		if x.SyncSend and IsInGuild and IsInGuild() then x:SyncSend("GUILD") end
		return
	end
	F.SyncSendChannel()
end

local reqf = CreateFrame("Frame")
reqf:RegisterEvent("CHAT_MSG_ADDON")
reqf:RegisterEvent("CHAT_MSG_CHANNEL")
reqf:SetScript("OnEvent", function(_, ev, a1, a2, a3, a4)
	-- requests and sync chunks ride both transports: the FBLsync addon
	-- prefix and plain channel text, "FBLreq;kind;name;reason" and
	-- "FBLv1;seq;total;chunk" either way
	local text, sender
	if ev == "CHAT_MSG_ADDON" then
		if a1 ~= PREFIX then return end
		text, sender = a2, a4
	else
		text, sender = a1, a2
	end
	text = tostring(text)
	local kind, name, reason = text:match("^FBLreq;([^;]+);([^;]+);?(.*)$")
	if kind then
		OnRemovalRequest(sender, kind, name, reason)
		return
	end
	if text:match("^FBLpull;") then
		OnPullRequest(text, sender)
		return
	end
	local ver, rev = text:match("^FBLver;([^;]*);?(%d*)$")
	if ver then
		PeerSeen(sender, ver, tonumber(rev))
		rev = tonumber(rev)
		if rev then
			local db = DB()
			-- defensive: a declarer's file can hand us a global that never
			-- saw the defaults merge - or holds a non-table in the slot
			if type(db.sync) ~= "table" then db.sync = {} end
			db.sync.seenRev = math.max(db.sync.seenRev or 0, rev)
			local who = sender or "?"
			if not seenPeers[who] then
				seenPeers[who] = true
				Log("in", format(L["Peer %s: %s (rev %d)"], who, ver, rev))
			end
			if rev > (db.rev or 0) then
				Log("in", format(L["%s has a newer list (rev %d > %d)"], who, rev, db.rev or 0))
				MaybePull()
			end
		end
		return
	end
	-- peer stats: "FBLstat;rev;entryCount" - our own extension, lets
	-- the peers strip show whether someone's list is complete
	local srev, scnt = text:match("^FBLstat;(%d+);(%d+)")
	if srev then
		PeerSeen(sender, nil, tonumber(srev), tonumber(scnt))
		return
	end
	local seqS, totalS, chunk = text:match("^FBLv1;(%d+);(%d+);(.*)$")
	if not seqS then
		seqS, totalS, chunk = text:match("^v1|(%d+)|(%d+)|(.*)$")
	end
	if seqS then OnChunk(sender, ev == "CHAT_MSG_ADDON" and "addon" or "chat",
		tonumber(seqS), tonumber(totalS), chunk) end
end)

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
	C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
elseif RegisterAddonMessagePrefix then
	RegisterAddonMessagePrefix(PREFIX)
end


function F.RequestRemoval(e, reason)
	if not e then return end
	local x = ext()
	if x and x.RequestRemoval then return x:RequestRemoval(e, reason) end
	if not chanNum then JoinSync() end
	local why = (reason or ""):gsub(";", ","):sub(1, 120)
	local msg = format("FBLreq;%s;%s;%s", e.kind or "player",
		(e.name or ""):gsub(";", ","), why)
	local sent
	local f = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
	if f and chanNum then
		sent = ns.HardAPI("SendAddonMessage", f, PREFIX, msg, "CHANNEL", chanNum)
	end

	if not sent then
		Log("out", L["Not in the sync channel"])
		S.Print("|cffff5555" .. L["Not in the sync channel"] .. "|r")
		return
	end
	Log("out", format(L["Removal request for %s sent to the admin"], e.name))
	S.Print(format(L["Removal request for %s sent to the admin"], e.name))
end

-- list window ------------------------------------------------------------------------
-- ("win" itself is declared up by the sync log so Log() can reach it)
local function EditBox(parent, w, hint)
	local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	e:SetSize(w or 160, 20)
	e:SetAutoFocus(false)
	e:SetMaxLetters(60)
	local h = ns.Font(e, 9, S.colors.textDim)
	h:SetPoint("LEFT", e, "LEFT", 6, 0)
	h:SetText(hint or "")
	local function upd() h:SetShown((e:GetText() or "") == "") end
	e:SetScript("OnTextChanged", function(self, user)
		upd()
		if user and self.onType then self.onType(self) end
	end)
	-- no OnEscapePressed/OnEditFocusLost handlers: ANY insecure code
	-- inside the Escape dispatch (even a deferred C_Timer call)
	-- taints the engine's spell-stop calls after it. The parent
	-- window is in UISpecialFrames, so Escape hides it natively and
	-- OnTextChanged keeps the hint in sync already.
	upd()
	return e
end

local function Chip(parent, label, onClick)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetHeight(20)
	S.Template(b, "inset")
	b.fs = ns.Font(b, 10, S.colors.textDim)
	b.fs:SetPoint("CENTER")
	b.fs:SetJustifyH("CENTER")
	function b:SetLabel(t)
		self.fs:SetText(t)
		self:SetWidth((self.fs:GetStringWidth() or 40) + 18)
	end
	function b:SetActive(on)
		local c = on and S.colors.accent or S.colors.textDim
		self.fs:SetTextColor(c.r, c.g, c.b)
		S.SetBorderLit(self, on == true)
	end
	b:SetLabel(label)
	b:SetScript("OnClick", function() onClick(b) end)
	return b
end

local function Window()
	if win then return win end
	local f = CreateFrame("Frame", "SentiUIPanelFBLWindow", UIParent, "BackdropTemplate")
	if S.CombatDeferWindow then S:CombatDeferWindow(f) end
	f:SetSize(620, 580)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	S.Template(f, "panel")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	f:SetClampedToScreen(true)
	tinsert(UISpecialFrames, "SentiUIPanelFBLWindow")
	f:Hide()
	win = f

	local hIcon = f:CreateTexture(nil, "ARTWORK")
	hIcon:SetSize(18, 18)
	hIcon:SetPoint("TOPLEFT", 12, -9)
	hIcon:SetTexture("Interface\\Icons\\Ability_Creature_Cursed_04")
	hIcon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	local title = ns.Font(f, 14, S.colors.accent)
	title:SetPoint("TOPLEFT", hIcon, "TOPRIGHT", 8, -1)
	title:SetText(L["Blacklist"])
	local sub = ns.Font(f, 9, S.colors.textDim)
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	f.sub = sub
	local rule = f:CreateTexture(nil, "ARTWORK")
	rule:SetHeight(1)
	rule:SetPoint("TOPLEFT", 10, -40)
	rule:SetPoint("TOPRIGHT", -10, -40)
	rule:SetColorTexture(S.colors.accent.r, S.colors.accent.g, S.colors.accent.b, 0.35)
	local close = ns.CloseButton(f, 18)
	close:SetPoint("TOPRIGHT", -8, -8)
	close:SetScript("OnClick", function() f:Hide() end)

	f.filter = "all"
	local chips = {}
	local function FilterChip(id, label)
		local c = Chip(f, label, function()
			f.filter = id
			F.RefreshWindow()
		end)
		c.fid = id
		chips[#chips + 1] = c
		return c
	end
	FilterChip("all", L["All"])
	FilterChip("black", L["Blocked"])
	FilterChip("good", L["Good list"])
	FilterChip("guild", L["Guild"])
	FilterChip("log", L["Sync log"])
	local adminChip = FilterChip("admin", L["Admin"])
	adminChip:Hide()
	f.adminChip = adminChip
	local x = 10
	for _, c in ipairs(chips) do
		c:SetPoint("TOPLEFT", x, -50)
		x = x + c:GetWidth() + 6
	end
	f.chips = chips

	f.search = EditBox(f, 170, L["Search..."])
	f.search:SetPoint("TOPRIGHT", -14, -50)
	f.search.onType = function() F.RefreshWindow() end

	local listBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
	S.Template(listBg, "inset")
	listBg:SetPoint("TOPLEFT", 10, -82)
	listBg:SetPoint("BOTTOMRIGHT", -10, 80)
	local scroll = CreateFrame("ScrollFrame", nil, listBg)
	scroll:SetPoint("TOPLEFT", 4, -4)
	scroll:SetPoint("BOTTOMRIGHT", -4, 4)
	local holder = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(holder)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, d)
		local m = self:GetVerticalScrollRange()
		self:SetVerticalScroll(math.min(m, math.max(0, self:GetVerticalScroll() - d * 44)))
	end)
	f.holder, f.scroll = holder, scroll
	holder.rows, holder.heads = {}, {}

	local empty = ns.Font(f, 11, S.colors.textDim)
	empty:SetPoint("CENTER", listBg, "CENTER")
	empty:SetWidth(360)
	empty:SetJustifyH("CENTER")
	empty:Hide()
	f.empty = empty

	-- admin overlay page: only exists for list admins ----------------------
	local adminPanel = CreateFrame("Frame", nil, listBg)
	adminPanel:SetAllPoints(listBg)
	adminPanel:Hide()
	f.adminPanel = adminPanel

	local adStatus = ns.Font(adminPanel, 11, S.colors.accent)
	adStatus:SetPoint("TOPLEFT", 12, -10)
	adminPanel.status = adStatus

	local adAdmins = ns.Font(adminPanel, 10, S.colors.textDim)
	adAdmins:SetPoint("TOPLEFT", adStatus, "BOTTOMLEFT", 0, -6)
	adAdmins:SetWidth(500)
	adAdmins:SetJustifyH("LEFT")
	adAdmins:SetJustifyV("TOP")
	adminPanel.admins = adAdmins

	local adEdit = EditBox(adminPanel, 240, L["Extra admin chars (comma separated)..."])
	adEdit:SetPoint("TOPLEFT", 12, -118)
	-- saves on each user keystroke instead of OnEditFocusLost: a
	-- focus-loss handler still runs inside the Escape dispatch and
	-- taints the engine's later spell-stop calls
	adEdit.onType = function(self)
		local v = strtrim(self:GetText() or "")
		DB().sync = DB().sync or {}
		DB().sync.admin = v ~= "" and v or nil
		F.RefreshWindow()
	end
	adminPanel.adminEdit = adEdit

	local adSync = ns.Button(adminPanel, 150, 22, L["Sync all"])
	adSync:SetPoint("TOPRIGHT", -12, -112)
	adSync:SetScript("OnClick", function() F.SyncAll() end)
	adminPanel.syncAll = adSync

	local adSync = adminPanel.syncAll

	local autoChip = Chip(adminPanel, L["Auto-accept sync"], function(c)
		DB().sync.autoAccept = not DB().sync.autoAccept
		c:SetActive(DB().sync.autoAccept)
	end)
	autoChip:SetPoint("TOPRIGHT", adSync, "BOTTOMRIGHT", 0, -6)
	adminPanel.autoChip = autoChip

	local trustChip = Chip(adminPanel, "", function()
		local modes = { "all", "guild", "friends" }
		local cur = DB().sync.trust or "all"
		local nextMode = "all"
		for i, m in ipairs(modes) do
			if m == cur then nextMode = modes[i % 3 + 1] end
		end
		DB().sync.trust = nextMode
		F.RefreshWindow()
	end)
	trustChip:SetPoint("TOPRIGHT", autoChip, "BOTTOMRIGHT", 0, -6)
	adminPanel.trustChip = trustChip

	local impBtn = ns.Button(adminPanel, 118, 22, L["Import"])
	impBtn:SetPoint("TOPLEFT", 12, -140)
	impBtn:SetScript("OnClick", function()
		ns.TextPopup(L["Import"], "", function(t)
			local added, updated = F.ImportJSON(t, nil)
			if added then
				if added > 0 or updated > 0 then AnnounceStats() end
				Log("in", format(L["Import: %d added, %d updated"], added, updated))
				S.Print(format(L["Import: %d added, %d updated"], added, updated))
			else
				S.Print("|cffff5555" .. tostring(updated or L["Invalid import data"]) .. "|r")
			end
		end)
	end)

	local expBtn = ns.Button(adminPanel, 118, 22, L["Export"])
	expBtn:SetPoint("LEFT", impBtn, "RIGHT", 8, 0)
	expBtn:SetScript("OnClick", function()
		ns.TextPopup(L["Export"], F.ExportJSON())
	end)

	local reqHead = ns.Font(adminPanel, 11, S.colors.accent2)
	reqHead:SetPoint("TOPLEFT", 12, -178)
	reqHead:SetText(L["Pending removal requests"])
	adminPanel.reqHead = reqHead

	adminPanel.reqRows = {}
	local function ReqRow(i)
		local r = adminPanel.reqRows[i]
		if r then return r end
		r = CreateFrame("Button", nil, adminPanel, "BackdropTemplate")
		r:SetPoint("TOPLEFT", 10, -200 - (i - 1) * 30)
		r:SetPoint("RIGHT", -10, 0)
		r:SetHeight(26)
		S.Template(r, "raised")
		r.name = ns.Font(r, 10)
		r.name:SetPoint("LEFT", 8, 4)
		r.name:SetWidth(170)
		r.name:SetJustifyH("LEFT")
		r.from = ns.Font(r, 9, S.colors.textDim)
		r.from:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, 2)
		r.reason = ns.Font(r, 9, S.colors.textDim)
		r.reason:SetPoint("LEFT", 190, 0)
		r.reason:SetPoint("RIGHT", -70, 0)
		r.reason:SetJustifyH("LEFT")
		r.reason:SetWordWrap(false)
		r.acc = ns.Button(r, 26, 18, "+")
		r.acc:SetPoint("RIGHT", -36, 0)
		r.dec = ns.Button(r, 26, 18, "x")
		r.dec:SetPoint("RIGHT", -6, 0)
		adminPanel.reqRows[i] = r
		return r
	end
	adminPanel.ReqRow = ReqRow
	local noReq = ns.Font(adminPanel, 10, S.colors.textDim)
	noReq:SetPoint("TOPLEFT", 14, -206)
	noReq:SetText(L["No pending requests"])
	adminPanel.noReq = noReq

	-- sync log page: status lines + the traffic ring buffer, for everyone
	local logPanel = CreateFrame("Frame", nil, listBg)
	logPanel:SetAllPoints(listBg)
	logPanel:Hide()
	f.logPanel = logPanel

	local lStatus = ns.Font(logPanel, 10, S.colors.textDim)
	lStatus:SetPoint("TOPLEFT", 12, -10)
	lStatus:SetPoint("RIGHT", -12, 0)
	lStatus:SetJustifyH("LEFT")
	lStatus:SetJustifyV("TOP")
	logPanel.status = lStatus

	local reqBtn = ns.Button(logPanel, 120, 22, L["Request update"])
	reqBtn:SetPoint("TOPRIGHT", -12, -62)
	reqBtn:SetScript("OnClick", function()
		SendPullRequest()
		if not chanNum then
			Log("out", L["Not in the sync channel"])
			F.RefreshWindow()
		end
	end)

	local clrBtn = ns.Button(logPanel, 90, 22, L["Clear log"])
	clrBtn:SetPoint("RIGHT", reqBtn, "LEFT", -8, 0)
	clrBtn:SetScript("OnClick", function()
		DB().sync.log = {}
		F.RefreshWindow()
	end)

	local logScroll = CreateFrame("ScrollFrame", nil, logPanel)
	logScroll:SetPoint("TOPLEFT", 8, -92)
	logScroll:SetPoint("BOTTOMRIGHT", -196, 8)
	local logHolder = CreateFrame("Frame", nil, logScroll)
	logScroll:SetScrollChild(logHolder)
	logScroll:EnableMouseWheel(true)
	logScroll:SetScript("OnMouseWheel", function(self, d)
		local m = self:GetVerticalScrollRange()
		self:SetVerticalScroll(math.min(m, math.max(0, self:GetVerticalScroll() - d * 44)))
	end)
	logPanel.scroll, logPanel.holder = logScroll, logHolder
	logHolder.rows = {}

	local noLog = ns.Font(logPanel, 10, S.colors.textDim)
	noLog:SetPoint("TOPLEFT", 14, -98)
	noLog:SetText(L["No sync traffic yet"])
	logPanel.noLog = noLog

	-- right strip: known FBL peers on the channel (who, version, rev,
	-- last heard) - the "who is actually out there" user asked for
	local peersBg = CreateFrame("Frame", nil, logPanel, "BackdropTemplate")
	S.Template(peersBg, "inset")
	peersBg:SetPoint("TOPRIGHT", -8, -92)
	peersBg:SetPoint("BOTTOMRIGHT", -8, 8)
	peersBg:SetWidth(180)
	local pHead = ns.Font(peersBg, 10, S.colors.accent2)
	pHead:SetPoint("TOPLEFT", 8, -6)
	logPanel.pHead = pHead
	local pScroll = CreateFrame("ScrollFrame", nil, peersBg)
	pScroll:SetPoint("TOPLEFT", 4, -26)
	pScroll:SetPoint("BOTTOMRIGHT", -4, 4)
	local pHolder = CreateFrame("Frame", nil, pScroll)
	pScroll:SetScrollChild(pHolder)
	pScroll:EnableMouseWheel(true)
	pScroll:SetScript("OnMouseWheel", function(self, d)
		local m = self:GetVerticalScrollRange()
		self:SetVerticalScroll(math.min(m, math.max(0, self:GetVerticalScroll() - d * 44)))
	end)
	logPanel.pScroll, logPanel.pHolder = pScroll, pHolder
	pHolder.rows = {}
	local pEmpty = ns.Font(peersBg, 9, S.colors.textDim)
	pEmpty:SetPoint("TOPLEFT", 10, -30)
	pEmpty:SetText(L["No peers seen yet"])
	logPanel.pEmpty = pEmpty

	local formBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
	S.Template(formBg, "inset")
	formBg:SetPoint("BOTTOMLEFT", 10, 10)
	formBg:SetPoint("BOTTOMRIGHT", -10, 10)
	formBg:SetHeight(66)

	f.kind = "player"
	f.nameBox = EditBox(formBg, 150, L["Name"])
	f.nameBox:SetPoint("TOPLEFT", 8, -6)
	f.noteBox = EditBox(formBg, 200, L["Note (required)"])
	f.noteBox:SetPoint("LEFT", f.nameBox, "RIGHT", 8, 0)

	-- entry kind as a proper radio pair (Player / Guild), matching the
	-- filter chips above; the single unstyled toggle looked broken next
	-- to the highlighted good-list chip
	f.kindChips = {}
	local prev
	for _, k in ipairs({ "player", "guild" }) do
		local kind = k
		local c = Chip(formBg, kind == "player" and L["Player"] or L["Guild"], function()
			f.kind = kind
			for kk, cc in pairs(f.kindChips) do cc:SetActive(kk == kind) end
		end)
		if prev then c:SetPoint("LEFT", prev, "RIGHT", 8, 0)
		else c:SetPoint("TOPLEFT", 8, -38) end
		c:SetWidth(76)
		prev = c
		f.kindChips[kind] = c
	end
	f.kindChips.player:SetActive(true)

	f.goodChip = Chip(formBg, L["Good list"], function(c)
		c.on = not c.on
		c:SetActive(c.on)
	end)
	f.goodChip:SetPoint("LEFT", f.kindChips.guild, "RIGHT", 16, 0)
	f.goodChip:SetWidth(96)

	local addBtn = ns.Button(formBg, 80, 22, L["Add"])
	addBtn:SetPoint("RIGHT", -8, 0)
	addBtn:SetScript("OnClick", function()
		local name = strtrim(f.nameBox:GetText() or "")
		local note = strtrim(f.noteBox:GetText() or "")
		if name == "" then S.Print(L["Enter a name"]) return end
		if note == "" then S.Print(L["Note (required)"]) return end
		local e, err = F.AddEntry(name, f.kind, nil, note, nil,
			f.goodChip.on and "good" or nil)
		if e then
			f.nameBox:SetText("")
			f.noteBox:SetText("")
			F.RefreshWindow()
		elseif err == "exists" then
			S.Print(format(L["%s is already listed"], name))
		else
			S.Print(L["Note (required)"])
		end
	end)
	local tgt = ns.Button(formBg, 80, 22, L["Target"])
	tgt:SetPoint("RIGHT", addBtn, "LEFT", -6, 0)
	tgt:SetScript("OnClick", function()
		local name = F.GetUnitFullName("target")
		if name then f.nameBox:SetText(name) end
	end)

	return f
end

function F.RefreshWindow()
	local f = win
	if not f or not f:IsShown() then return end
	local holder = f.holder
	for _, r in ipairs(holder.rows) do r:Hide() end
	for _, h in ipairs(holder.heads) do h:Hide() if h.rule then h.rule:Hide() end end
	for _, c in ipairs(f.chips) do c:SetActive(c.fid == f.filter) end
	local isAdm = F.IsAdmin()
	f.adminChip:SetShown(isAdm)
	if not isAdm and f.filter == "admin" then f.filter = "all" end
	f.sub:SetText(format(L["%d entries"], F.EntryCount())
		.. (isAdm and ("  |cff4dd278" .. L["Admin"] .. "|r") or ""))

	-- sync log page: status + the traffic ring buffer, newest first
	if f.filter == "log" then
		f.scroll:Hide()
		f.empty:Hide()
		if f.adminPanel then f.adminPanel:Hide() end
		local lp = f.logPanel
		lp:Show()
		local db = DB()
		local roster = LiveRosterCount()
		local pendInfo = {}
		for k, s in pairs(pending) do
			tinsert(pendInfo, format("%s %d/%d", k, s.got or 0, s.total or 0))
		end
		lp.status:SetText(
			format("%s %s", "|cffebad33" .. L["Channel"] .. ":|r",
				chanNum and (tostring(chanName or "?")
						.. "  |cff8c919f(#" .. chanNum .. ")|r")
					or "|cffff5555" .. L["not joined"] .. "|r")
			.. "\n" .. format("%s |cffebad33%d|r    %s %d    %s %d",
				L["Our rev:"], db.rev or 0,
				L["Peers' rev:"], db.sync.seenRev or 0,
				L["Entries:"], F.EntryCount())
			.. "\n" .. format("%s %s    %s %s    %s %s",
				L["Live share:"], db.sync.liveShare
					and "|cff4dd278on|r" or "|cffff5555off|r",
				L["Auto-accept:"], db.sync.autoAccept
					and "|cff4dd278on|r" or "|cffff5555off|r",
				L["Trust:"], "|cffebad33" .. tostring(db.sync.trust or "all") .. "|r")
			.. (roster and format("    %s |cffebad33%d|r", L["Members:"], roster) or "")
			.. (db.sync.lastFrom
				and ("\n" .. format("%s %s  |cff8c919f%s|r", L["Last received:"],
					db.sync.lastFrom,
					db.sync.lastAt and date("%d.%m. %H:%M", db.sync.lastAt) or ""))
				or "")
			.. (#pendInfo > 0
				and ("\n" .. format("|cff339eff%s|r %s",
					L["Receiving:"], table.concat(pendInfo, ", ")))
				or ""))
		local log = db.sync.log or {}
		local h = lp.holder
		local shown = 0
		for i = #log, 1, -1 do
			local e = log[i]
			shown = shown + 1
			local r = h.rows[shown]
			if not r then
				r = ns.Font(h, 9)
				r:SetJustifyH("LEFT")
				r:SetWordWrap(false)
				h.rows[shown] = r
			end
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", 6, -((shown - 1) * 15))
			r:SetPoint("RIGHT", -4, 0)
			local arrow = e.dir == "in" and "|cff4dd278<<|r"
				or e.dir == "out" and "|cff339eff>>|r" or "|cff8c919f--|r"
			r:SetText(format("|cff6a6f7d%s|r %s %s",
				date("%H:%M", e.t or time()), arrow, e.msg or ""))
			r:Show()
		end
		for i = shown + 1, #h.rows do h.rows[i]:Hide() end
		lp.noLog:SetShown(shown == 0)
		h:SetHeight(math.max(1, shown * 15))
		h:SetWidth(math.max(1, lp.scroll:GetWidth()))
		lp.scroll:UpdateScrollChildRect()

		local peers = KnownPeers()
		local ourCnt = F.EntryCount()
		lp.pHead:SetText(format("%s (%d)", L["Peers"], #peers))
		local ph = lp.pHolder
		local pShown = 0
		for _, pe in ipairs(peers) do
			pShown = pShown + 1
			local r = ph.rows[pShown]
			if not r then
				r = CreateFrame("Frame", nil, ph)
				r:SetHeight(38)
				r.name = ns.Font(r, 9)
				r.name:SetPoint("TOPLEFT", 4, -2)
				r.name:SetPoint("RIGHT", -4, 0)
				r.name:SetJustifyH("LEFT")
				r.name:SetWordWrap(false)
				r.sub = ns.Font(r, 8, S.colors.textDim)
				r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, 0)
				r.sub:SetPoint("RIGHT", -4, 0)
				r.sub:SetJustifyH("LEFT")
				r.sub:SetWordWrap(false)
				r.sub2 = ns.Font(r, 8)
				r.sub2:SetPoint("TOPLEFT", r.sub, "BOTTOMLEFT", 0, 0)
				r.sub2:SetPoint("RIGHT", -4, 0)
				r.sub2:SetJustifyH("LEFT")
				r.sub2:SetWordWrap(false)
				ph.rows[pShown] = r
			end
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", 0, -((pShown - 1) * 38))
			r:SetPoint("RIGHT", -2, 0)
			r.name:SetText(pe.name or "?")
			-- their entry count next to ours, so "did they get the full
			-- list?" reads as a number instead of a guess
			local cntTxt
			if pe.cnt then
				cntTxt = format(pe.cnt >= ourCnt
					and "|cff4dd278%d/%d|r" or "|cffff5555%d/%d|r",
					pe.cnt, ourCnt)
			else
				cntTxt = "|cff6a6f7d-/" .. ourCnt .. "|r"
			end
			r.sub:SetText(format("%s  |cff6a6f7d%s|r",
				tostring(pe.ver or "-"),
				pe.at and date("%d.%m %H:%M", pe.at) or "-"))
			r.sub2:SetText(format("rev %s  %s", tostring(pe.rev or "-"), cntTxt))
			r:Show()
		end
		for i = pShown + 1, #ph.rows do ph.rows[i]:Hide() end
		lp.pEmpty:SetShown(pShown == 0)
		ph:SetHeight(math.max(1, pShown * 38))
		ph:SetWidth(math.max(1, lp.pScroll:GetWidth()))
		lp.pScroll:UpdateScrollChildRect()
		return
	end
	if f.logPanel then f.logPanel:Hide() end

	-- admin page: swaps the list for status, admins and pending requests
	if f.filter == "admin" and isAdm then
		f.scroll:Hide()
		f.empty:Hide()
		local ap = f.adminPanel
		ap:Show()
		ap.status:SetText("|cff4dd278" .. L["You are a list admin"] .. "|r")
		local names = {}
		for n in pairs(F.EffectiveAdmins()) do tinsert(names, n) end
		sort(names)
		ap.admins:SetText(format(L["Effective admin: %s"], table.concat(names, ", ")))
		ap.autoChip:SetActive(DB().sync.autoAccept == true)
		local tmode = DB().sync.trust or "all"
		ap.trustChip:SetLabel(format(L["Trust: %s"],
			tmode == "all" and L["Everyone"] or tmode == "guild" and L["Guild"] or L["Friends"]))
		ap.trustChip:SetActive(tmode ~= "all")
		if not ap.adminEdit:HasFocus() then
			ap.adminEdit:SetText(DB().sync and DB().sync.admin or "")
		end
		local reqs = F.PendingRequests()
		for i = 1, math.max(#reqs, #ap.reqRows) do
			local req = reqs[i]
			local r = req and ap.ReqRow(i)
			if r then
				r.name:SetText(req.name .. "  |cff8c919f(" .. tostring(req.kind) .. ")|r")
				r.from:SetText(format(L["Request by %s"], req.sender or "?"))
				r.reason:SetText(req.reason ~= "" and req.reason or "-")
				r.acc:SetScript("OnClick", function() F.ResolveRequest(req, true) end)
				r.dec:SetScript("OnClick", function() F.ResolveRequest(req, false) end)
				r:Show()
			end
		end
		ap.noReq:SetShown(#reqs == 0)
		return
	end
	if f.adminPanel then f.adminPanel:Hide() end
	f.scroll:Show()

	local query = strtrim((f.search:GetText() or ""):lower())
	local groupCounts, entries = {}, F.SortedEntries()
	for _, e in ipairs(entries) do
		groupCounts[e.group] = (groupCounts[e.group] or 0) + 1
	end
	local y, ri, hi, shown, lastGroup = 0, 0, 0, 0, nil
	for _, e in ipairs(entries) do
		local pass = f.filter == "all"
			or (f.filter == "good" and e.list == "good")
			or (f.filter == "black" and e.list ~= "good")
			or (f.filter == "guild" and e.kind == "guild")
		if pass and query ~= "" then
			local note = F.AnyNote(e) or ""
			pass = e.name:lower():find(query, 1, true) ~= nil
				or (e.guild or ""):lower():find(query, 1, true) ~= nil
				or note:lower():find(query, 1, true) ~= nil
		end
		if pass then
			shown = shown + 1
			if e.group ~= lastGroup then
				lastGroup = e.group
				hi = hi + 1
				local hd = holder.heads[hi]
				if not hd then
					hd = ns.Font(holder, 11, S.colors.accent2)
					hd.rule = holder:CreateTexture(nil, "ARTWORK")
					hd.rule:SetHeight(1)
					hd.rule:SetColorTexture(0.92, 0.68, 0.20, 0.25)
					holder.heads[hi] = hd
				end
				hd:ClearAllPoints()
				hd:SetPoint("TOPLEFT", 6, -(y + 4))
				hd:SetText(F.GroupName(e.group) .. "  |cff8c919f(" .. (groupCounts[e.group] or 0) .. ")|r")
				hd.rule:ClearAllPoints()
				hd.rule:SetPoint("LEFT", hd, "RIGHT", 8, -1)
				hd.rule:SetPoint("RIGHT", holder, "RIGHT", -8, 0)
				hd.rule:Show()
				hd:Show()
				y = y + 26
			end
			ri = ri + 1
			local row = holder.rows[ri]
			if not row then
				row = CreateFrame("Button", nil, holder)
				row:SetHeight(24)
				row.icon = row:CreateTexture(nil, "ARTWORK")
				row.icon:SetSize(14, 14)
				row.icon:SetPoint("LEFT", 8, 0)
				row.line = ns.Font(row, 10)
				row.line:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
				row.line:SetPoint("RIGHT", -70, 0)
				row.line:SetJustifyH("LEFT")
				row.line:SetWordWrap(false)
				row.votes = ns.Font(row, 9, S.colors.textDim)
				row.votes:SetPoint("RIGHT", -8, 0)
				row.zebra = row:CreateTexture(nil, "BACKGROUND")
				row.zebra:SetAllPoints()
				row.zebra:SetColorTexture(1, 1, 1, 0.03)
				row.hl = row:CreateTexture(nil, "HIGHLIGHT")
				row.hl:SetAllPoints()
				row.hl:SetColorTexture(1, 1, 1, 0.05)
				row:RegisterForClicks("RightButtonUp")
				holder.rows[ri] = row
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -y)
			row:SetPoint("RIGHT", -4, 0)
			row.zebra:SetShown(ri % 2 == 0)
			row.icon:SetTexture(e.kind == "guild"
				and "Interface\\Icons\\INV_Shirt_GuildTabard_01"
				or "Interface\\Icons\\Achievement_Character_Human_Male")
			local good = e.list == "good"
			row.line:SetText((good and "|cff4dd278" or "|cffff5555") .. e.name .. "|r"
				.. (e.guild and e.kind ~= "guild"
					and ("  |cff8c919f<" .. e.guild .. ">|r") or "")
				.. (e.realm and ("  |cff6a6f7d@" .. e.realm .. "|r") or ""))
			local up, down = F.EntryVotes(e)
			local my = F.MyVote(e)
			row.votes:SetText(up + down > 0
				and format("|cff4dd278+%d|r |cffff5555-%d|r", up, down)
					.. (my and (my > 0 and "  |cff4dd278v|r" or "  |cffff5555v|r") or "")
				or (my and ("  |cff8c919f" .. (my > 0 and "+v" or "-v") .. "|r") or ""))
			row.entry = e
			row:SetScript("OnEnter", function(self)
				if not GameTooltip then return end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(self.entry.name, 1, 1, 1)
				GameTooltip:AddLine(F.GroupName(self.entry.group)
					.. "  |cff8c919f(" .. (self.entry.kind == "guild" and L["Guild"] or L["Player"]) .. ")|r",
					0.55, 0.57, 0.62)
				local note = F.AnyNote(self.entry)
				if note then GameTooltip:AddLine(note, 0.85, 0.87, 0.9, true) end
				if self.entry.added then
					GameTooltip:AddLine(date("%d.%m.%Y", self.entry.added), 0.45, 0.47, 0.52)
				end
				GameTooltip:AddLine(L["Right-click: options"], 0.45, 0.47, 0.52)
				GameTooltip:Show()
			end)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
			row:SetScript("OnClick", function(self)
				local e2 = self.entry
				ns.OpenMenu(self, function()
					local my = F.MyVote(e2)
					local items = {
						{ text = e2.name, isTitle = true },
						{ text = L["Vote +"], checked = my == 1,
							onClick = function() F.VoteEntry(e2, 1) F.RefreshWindow() end },
						{ text = L["Vote -"], checked = my == -1,
							onClick = function() F.VoteEntry(e2, -1) F.RefreshWindow() end },
						{ text = e2.list == "good" and L["Move to blacklist"] or L["Move to good list"],
							onClick = function()
								F.SetList(e2, e2.list == "good" and "black" or "good")
								F.RefreshWindow()
							end },
						{ text = L["Edit note"], onClick = function()
							ns.TextPopup(L["Note"], F.AnyNote(e2) or "", function(t)
								F.SetNote(e2, t)
								F.RefreshWindow()
							end)
						end },
					}
					for _, g in ipairs(F.Groups()) do
						local gid = g.id
						items[#items + 1] = {
							text = format(L["Move to: %s"], g.name),
							checked = e2.group == gid,
							onClick = function()
								F.SetGroup(e2, gid)
								F.RefreshWindow()
							end,
						}
					end
					items[#items + 1] = {
						text = "|cffff5555" .. L["Remove"] .. "|r",
						onClick = function()
							F.RemoveEntry(e2)
							F.RefreshWindow()
						end,
					}
					return items
				end)
			end)
			row:Show()
			y = y + 24
		end
	end
	f.empty:SetText(query ~= "" and L["Nothing found"]
		or L["The list is empty - add entries below"])
	f.empty:SetShown(shown == 0)
	holder:SetHeight(math.max(1, y))
	holder:SetWidth(math.max(1, f.scroll:GetWidth()))
	f.scroll:UpdateScrollChildRect()
end

function F.ToggleWindow()
	local x = ext()
	if x and x.ToggleWindow then x:ToggleWindow() return end
	local f = Window()
	if f:IsShown() then f:Hide() else f:Show() F.RefreshWindow() end
end


-- unit right-click menus (ported from the standalone's Tooltip.lua) --------
-- Adds "Add to Blacklist / good list / guild" entries to Blizzard unit
-- menus on every backend this client exposes (Menu.ModifyMenu plus the
-- classic UnitPopup). Skipped when the real ForeverBlackListed is
-- installed - it registers the same entries itself.
local MENU_TAGS = {
	"MENU_UNIT_FRIEND",
	"MENU_UNIT_TARGET",
	"MENU_UNIT_PLAYER",
	"MENU_UNIT_ENEMY_PLAYER",
	"MENU_UNIT_PARTY",
	"MENU_UNIT_RAID_PLAYER",
	"MENU_UNIT_CHAT_ROSTER",
	"MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
	"MENU_UNIT_COMMUNITIES_MEMBER",
}
local menuDone, menuClassic, modFired = false, false, false

local function GetUnitNameRealm(unit)
	local name, realm
	if GetUnitName then
		local ok, n, r = pcall(GetUnitName, unit)
		if ok then name, realm = n, r end
	end
	if IsSecret(name) then name = nil end
	if IsSecret(realm) then realm = nil end
	return name, realm
end

local function IsPlayerUnit(unit)
	if type(unit) ~= "string" or IsSecret(unit) then return false end
	local ok, exists = pcall(UnitExists, unit)
	if not ok or not exists or IsSecret(exists) then return false end
	local okS, isSelf = pcall(UnitIsUnit, unit, "player")
	if okS and isSelf then return false end
	local okP, isPlayer = pcall(UnitIsPlayer, unit)
	return okP and isPlayer and not IsSecret(isPlayer) or false
end

-- contextData fields can be secret values on this client - reading,
-- comparing or even truth-testing them throws, which silently kills the
-- menu entry. Normalize them to nil up front so every path stays plain.
local function Plain(v)
	if IsSecret(v) then return nil end
	return v
end

-- resolves the right-clicked player: "First Last-Realm" target string +
-- guild, from a menu contextData table (unit or name+server fields)
local function MenuTarget(contextData)
	local name, guild
	local unit = Plain(contextData.unit)
	if unit and IsPlayerUnit(unit) then
		local nm, rlm = GetUnitNameRealm(unit)
		name = rlm and nm and (nm .. "-" .. rlm) or nm
		if GetGuildInfo then
			local ok, g = pcall(GetGuildInfo, unit)
			if ok and g and g ~= "" and not IsSecret(g) then guild = g end
		end
	else
		local nm = Plain(contextData.name)
		if type(nm) == "string" and nm ~= "" then
			name = F.CleanName(nm)
		end
		local server = Plain(contextData.server)
		if name and type(server) == "string" and server ~= "" then
			name = name .. "-" .. server
		end
	end
	return name, guild
end

-- shared toggle action for the description buttons and the fallback menu
local function ToggleAction(kind, target, list, gname)
	local nm, rlm = F.SplitNameRealm(target)
	local e = F.FindEntry(kind, target)
	if e and e.list == list then
		F.RemoveEntry(e)
		S.Print(format(L["Removed %s"], e.name))
	elseif e then
		if gname and not e.guild then e.guild = gname end
		e.realm = rlm or e.realm
		F.SetList(e, list)
		S.Print(format(L["Added %s"], e.name) .. " (" .. (list == "good" and L["Good list"] or L["Blacklist"]) .. ")")
		if F.RefreshWindow then F.RefreshWindow() end
	else
		F.PromptAdd(nm or target, kind, list, gname, rlm)
	end
end

-- builds our entries onto a root description. Uses the Queue* variants
-- when present so the same code works both inside a ModifyMenu callback
-- (build time) and injected onto an already-open menu (rendered after
-- the open menu is asked to invalidate).
local function BuildMenuButtons(rootDescription, contextData)
	local function Btn(text, fn)
		if type(rootDescription.QueueButton) == "function" then
			return rootDescription:QueueButton(text, fn)
		end
		return rootDescription:CreateButton(text, fn)
	end
	local function Div()
		if type(rootDescription.QueueDivider) == "function" then
			return rootDescription:QueueDivider()
		end
		return rootDescription:CreateDivider()
	end
	local function Title(text)
		if type(rootDescription.QueueTitle) == "function" then
			return rootDescription:QueueTitle(text)
		end
		return rootDescription:CreateTitle(text)
	end

	local name, guild = MenuTarget(contextData)
	if not name then return end

	if type(rootDescription.ClearQueuedDescriptions) == "function" then
		rootDescription:ClearQueuedDescriptions()
	end
	Div()
	Title("ForeverBlackListed")

	local function Toggle(kind, target, list, addText, removeText, gname)
		Btn(
			(function()
				local e = F.FindEntry(kind, target)
				return (e and e.list == list) and removeText or addText
			end)(),
			function() ToggleAction(kind, target, list, gname) end)
	end

	Toggle("player", name, "black", L["Add to Blacklist"], L["Remove from Blacklist"], guild)
	Toggle("player", name, "good", L["Add to good list"], L["Remove from good list"], guild)

	-- "Blacklist in group ..." opens our own cursor menu (this client's
	-- Menu API does not render nested descriptions as submenus)
	local function GroupMenu(kind, target)
		local label = kind == "guild" and L["Guild to blacklist in group ..."] or L["Blacklist in group ..."]
		Btn(label, function()
			local items = {}
			for _, g in ipairs(F.Groups()) do
				local gid, gname = g.id, g.name
				tinsert(items, { text = gname, onClick = function()
					local nm, rlm = F.SplitNameRealm(target)
					local e = F.FindEntry(kind, nm)
					if e then
						e.realm = rlm or e.realm
						if kind == "player" and guild and not e.guild then e.guild = guild end
						F.SetGroup(e, gid)
						F.SetList(e, "black")
						S.Print(format(L["Added %s"], e.name) .. " (" .. gname .. ")")
						if F.RefreshWindow then F.RefreshWindow() end
					else
						F.PromptAdd(nm, kind, "black", kind == "player" and guild or nil, rlm, gid)
					end
				end })
			end
			ns.OpenMenu(nil, items)
		end)
	end
	GroupMenu("player", name)
	if guild and F.CleanName(guild) then
		Toggle("guild", guild, "black", L["Add guild to blacklist"], L["Remove guild from blacklist"])
		Toggle("guild", guild, "good", L["Add guild to good list"], L["Remove guild from good list"])
		GroupMenu("guild", guild)
	end
end

local function AddMenuEntry(_, rootDescription, contextData)
	modFired = true
	if not (contextData and F.db) then return end
	BuildMenuButtons(rootDescription, contextData)
end

-- compact fallback menu: our own OpenMenu docked under Blizzard's,
-- used when the ModifyMenu modifier never fires on this client
local function FallbackItems(ctx)
	local name, guild = MenuTarget(ctx)
	if not name then return nil end
	local items = { { text = "ForeverBlackListed", isTitle = true } }
	local function TI(kind, target, list, addText, removeText, gname)
		local e = F.FindEntry(kind, target)
		tinsert(items, {
			text = (e and e.list == list) and removeText or addText,
			onClick = function() ToggleAction(kind, target, list, gname) end,
		})
	end
	TI("player", name, "black", L["Add to Blacklist"], L["Remove from Blacklist"], guild)
	TI("player", name, "good", L["Add to good list"], L["Remove from good list"], guild)
	if guild and F.CleanName(guild) then
		TI("guild", guild, "black", L["Add guild to blacklist"], L["Remove guild from blacklist"])
		TI("guild", guild, "good", L["Add guild to good list"], L["Remove guild from good list"])
	end
	return items
end

local function ClassicToggle(kind, target, list)
	local nm, rlm = F.SplitNameRealm(target)
	local e = F.FindEntry(kind, target)
	if e and e.list == list then
		F.RemoveEntry(e)
		S.Print(format(L["Removed %s"], e.name))
	elseif e then
		F.SetList(e, list)
		e.realm = rlm or e.realm
		S.Print(format(L["Added %s"], e.name) .. " (" .. (list == "good" and L["Good list"] or L["Blacklist"]) .. ")")
		if F.RefreshWindow then F.RefreshWindow() end
	else
		F.PromptAdd(nm or target, kind, list, nil, rlm)
	end
end

local function RegisterClassicMenu()
	if menuClassic or not (UnitPopupButtons and UnitPopupMenus) then return end
	UnitPopupButtons["FBL_BLACK"] = { text = L["Add to Blacklist"], dist = 0 }
	UnitPopupButtons["FBL_GOOD"] = { text = L["Add to good list"], dist = 0 }
	for _, which in ipairs({ "FRIEND", "CHAT_ROSTER", "TARGET", "PLAYER", "PARTY", "RAID_PLAYER", "ENEMY_PLAYER" }) do
		local menu = UnitPopupMenus[which]
		if type(menu) == "table" then
			tinsert(menu, "FBL_BLACK")
			tinsert(menu, "FBL_GOOD")
		end
	end
	if hooksecurefunc then
		hooksecurefunc("UnitPopup_OnClick", function(btn)
			local which = btn and btn.value
			if (which ~= "FBL_BLACK" and which ~= "FBL_GOOD") or not F.db then return end
			local dd = UIDROPDOWNMENU_OPEN_MENU or UIDROPDOWNMENU_INIT_MENU
			if not dd then return end
			local name, guild
			local unit = dd.unit
			if unit and IsPlayerUnit(unit) then
				local nm, rlm = GetUnitNameRealm(unit)
				name = rlm and nm and (nm .. "-" .. rlm) or nm
				if GetGuildInfo then
					local ok, g = pcall(GetGuildInfo, unit)
					if ok and g and g ~= "" and not IsSecret(g) then guild = g end
				end
			elseif dd.name then
				name = F.CleanName(dd.name)
				if dd.server and dd.server ~= "" then
					name = name .. "-" .. dd.server
				end
			end
			if not name then return end
			ClassicToggle("player", name, which == "FBL_GOOD" and "good" or "black")
		end)
	end
	menuClassic = true
end

local function RegisterMenu()
	if menuDone and menuClassic then return end
	-- this client can expose Menu.ModifyMenu while some right-click menus
	-- still render through the classic UnitPopup (which also loads lazily
	-- with Blizzard_UnitPopup) - register into both, each once, so our
	-- entries show regardless of which backend draws the menu
	if not menuDone and Menu and Menu.ModifyMenu then
		for _, tag in ipairs(MENU_TAGS) do
			Menu.ModifyMenu(tag, AddMenuEntry)
		end
		menuDone = true
	end
	RegisterClassicMenu()
end

-- ground truth hook: whichever global actually opens unit menus on this
-- client retries registration. OpenContextMenu is the context-menu
-- opener (what right-clicks use), OpenMenu covers the rest.
local openHooked = false
local function HookMenuOpen()
	if openHooked or not hooksecurefunc then return end
	local hooked = false
	if type(UnitPopup_OpenMenu) == "function" then
		hooksecurefunc("UnitPopup_OpenMenu", function() RegisterMenu() end)
		hooked = true
	end
	if type(UnitPopupManager) == "table"
		and type(UnitPopupManager.OpenMenu) == "function" then
		hooksecurefunc(UnitPopupManager, "OpenMenu", function() RegisterMenu() end)
		hooked = true
	end
	if type(UnitPopup_ShowMenu) == "function" then
		hooksecurefunc("UnitPopup_ShowMenu", function() RegisterMenu() end)
		hooked = true
	end
	if Menu and type(Menu.GetManager) == "function" then
		local ok, mgr = pcall(Menu.GetManager)
		if ok and type(mgr) == "table" then
			local function OnManagerOpen(self, ownerRegion, description)
				RegisterMenu()
				-- direct injection for ports that never consult the
				-- ModifyMenu registry: append onto the root description
				-- of the just-opened menu and ask it to rebuild. And as a
				-- guaranteed-visible fallback our own mini menu docks
				-- under Blizzard's via ns.OpenMenu.
				if modFired then return end
				local ctx
				if type(description) == "table" then
					ctx = Plain(description.contextData)
					if not ctx and type(description.GetContextData) == "function" then
						local okC, c = pcall(description.GetContextData, description)
						if okC then ctx = Plain(c) end
					end
				end
				if not ctx and type(ownerRegion) == "table" then
					-- unit frames carry the unit on the frame itself
					local u = Plain(ownerRegion.unit)
					if u then ctx = { unit = u } end
				end
				if type(ctx) ~= "table" or not F.db then return end
				if type(description) == "table" then
					if type(description.ClearQueuedDescriptions) == "function" then
						description:ClearQueuedDescriptions()
					end
					local okB = pcall(BuildMenuButtons, description, ctx)
					if okB then
						local okO, open = pcall(self.GetOpenMenu, self)
						if okO and open
							and type(open.InvalidateFullItemList) == "function" then
							pcall(open.InvalidateFullItemList, open)
						end
					end
				end
				local okO, open = pcall(self.GetOpenMenu, self)
				if okO and open and ns.OpenMenu then
					ns.OpenMenu(open, function() return FallbackItems(ctx) end)
				end
			end
			if type(mgr.OpenMenu) == "function" then
				hooksecurefunc(mgr, "OpenMenu", OnManagerOpen)
				hooked = true
			end
			if type(mgr.OpenContextMenu) == "function" then
				hooksecurefunc(mgr, "OpenContextMenu", OnManagerOpen)
				hooked = true
			end
		end
	end
	openHooked = hooked
end

local function TryMenuSetup()
	-- the standalone addon registers these entries itself
	local x = ext()
	if x and x.db then return end
	RegisterMenu()
	HookMenuOpen()
end

local menuEv = CreateFrame("Frame")
menuEv:RegisterEvent("PLAYER_LOGIN")
menuEv:RegisterEvent("ADDON_LOADED")
menuEv:RegisterEvent("PLAYER_ENTERING_WORLD")
menuEv:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 ~= "Blizzard_UnitPopup"
		and arg1 ~= "Blizzard_Menu" then
		return
	end
	TryMenuSetup()
end)
