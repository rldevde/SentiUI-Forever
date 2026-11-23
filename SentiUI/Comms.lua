-- Shared comms layer: every channel query the suite makes goes through
-- here. Owns the "SentiUI" custom channel + the SUIv1 addon prefix, the
-- suite version exchange (announce on join, answer queries, remember
-- peers) and the join/leave notice log the admin UI reads.
-- Modules hook in with Comms.OnMessage / Comms.OnNotice / Comms.OnLog.
local _, S = ...

local Comms = {}
S.Comms = Comms

local CHANNEL = "SentiUI"
local PREFIX = "SUIv1"
local PEER_MAX_AGE = 14 * 86400
local LOG_MAX = 150

local chanNum
local msgHandlers, noticeHandlers, logHandlers = {}, {}, {}

local function DB()
	return S.DB.Module("Comms", { peers = {}, log = {} })
end

function Comms.Channel() return CHANNEL end
function Comms.Prefix() return PREFIX end
function Comms.ChanNum() return chanNum end
function Comms.Joined() return chanNum ~= nil end

function Comms.OwnName()
	local ok, n = pcall(GetUnitName, "player")
	n = ok and n or nil
	local okr, r = pcall(GetRealmName)
	r = okr and r or nil
	if type(n) == "string" then
		if type(r) == "string" and r ~= "" then return n .. "-" .. r end
		return n
	end
end

-- channel plumbing --------------------------------------------------------

local function ChanNumOf(name)
	local f = GetChannelName or (C_ChatInfo and C_ChatInfo.GetChannelName)
	if not f then return nil end
	local ok, n = pcall(f, name)
	n = ok and tonumber(n)
	return (n and n > 0) and n or nil
end

local function DoJoin(name)
	-- channel joins are protected during combat lockdown
	if InCombatLockdown and InCombatLockdown() then
		S.RunOutOfCombat(function() DoJoin(name) end)
		return
	end
	local join = JoinTemporaryChannel or JoinChannelByName
		or (C_ChatInfo and (C_ChatInfo.JoinTemporaryChannel or C_ChatInfo.JoinChannelByName))
	if join then pcall(join, name) end
end

-- default channels must exist first or the join is silently dropped
local function ChannelsReady()
	local f = GetChannelList or (C_ChatInfo and C_ChatInfo.GetChannelList)
	if not f then return true end
	local ok, n = pcall(function() return select("#", f()) end)
	return not ok or n > 0
end

local joinTries = 0
local function JoinSync()
	if chanNum or joinTries > 30 then return end
	local n = ChanNumOf(CHANNEL)
	if n then
		chanNum = n
		Comms.OnJoined()
		return
	end
	if not ChannelsReady() then
		joinTries = joinTries + 1
		C_Timer.After(1, JoinSync)
		return
	end
	DoJoin(CHANNEL)
	C_Timer.After(3, function()
		local n2 = ChanNumOf(CHANNEL)
		if n2 then
			chanNum = n2
			Comms.OnJoined()
			return
		end
		joinTries = joinTries + 1
		C_Timer.After(5, JoinSync)
	end)
end

function Comms.OnJoined()
	Comms.AddLog("info", format(S.L["Joined channel '%s' (#%d)"], CHANNEL, chanNum or 0))
	C_Timer.After(2, function() Comms.Announce() end)
	C_Timer.After(3, function() Comms.Query() end)
end

function Comms.Send(msg)
	if not chanNum or type(msg) ~= "string" or msg == "" then return end
	local f = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
	if f then pcall(f, PREFIX, msg, "CHANNEL", chanNum) end
end

function Comms.OnMessage(fn) msgHandlers[#msgHandlers + 1] = fn end
function Comms.OnNotice(fn) noticeHandlers[#noticeHandlers + 1] = fn end
function Comms.OnLog(fn) logHandlers[#logHandlers + 1] = fn end

-- peers + version exchange -------------------------------------------------

function Comms.ModuleVersions()
	local out = {}
	local num = (C_AddOns and C_AddOns.GetNumAddOns) or GetNumAddOns
	local info = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
	local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
	if not (num and info and meta) then
		out.SentiUI = S.version or "?"
		return out
	end
	local ok, n = pcall(num)
	n = ok and tonumber(n) or 0
	for i = 1, n do
		local okI, name = pcall(info, i)
		if okI and type(name) == "string"
			and (name == "SentiUI" or name:find("^SentiUI_")) then
			local okM, v = pcall(meta, name, "Version")
			out[name] = (okM and type(v) == "string" and v ~= "") and v or "?"
		end
	end
	return out
end

local function SuiteChunks()
	local mods = Comms.ModuleVersions()
	local names = {}
	for k in pairs(mods) do names[#names + 1] = k end
	table.sort(names)
	local chunks, cur = {}, {}
	for _, n in ipairs(names) do
		local piece = n .. "@" .. tostring(mods[n])
		if #table.concat(cur, ",") + #piece + 1 > 190 then
			chunks[#chunks + 1] = table.concat(cur, ",")
			cur = {}
		end
		cur[#cur + 1] = piece
	end
	if #cur > 0 or #chunks == 0 then chunks[#chunks + 1] = table.concat(cur, ",") end
	return chunks
end

function Comms.Announce()
	if not chanNum then return end
	local mods = Comms.ModuleVersions()
	Comms.Send("SUIver;v;" .. tostring(mods.SentiUI or "?"))
	local chunks = SuiteChunks()
	for i, c in ipairs(chunks) do
		Comms.Send("SUIver;m;" .. i .. "/" .. #chunks .. ";" .. c)
	end
end

-- ask every peer to re-announce (they answer with jitter)
function Comms.Query() Comms.Send("SUIver;q") end

local function Peer(name)
	local p = DB().peers
	local e = p[name]
	if type(e) ~= "table" then e = { mods = {} } p[name] = e end
	if type(e.mods) ~= "table" then e.mods = {} end
	return e
end

local Older -- defined further down (numeric n.n.n compare)

local announcePending
-- session dedupe: each peer hears "you are outdated" from us at most once
local notified = {}

-- a peer's manifest is behind ours: whisper them the modules they should
-- update (addon message, invisible to chat). Their client prints it
-- locally - the same happens to us when we are the one behind
local function NotifyOutdated(sender, mods)
	if notified[sender] or type(mods) ~= "table" then return end
	local own = Comms.ModuleVersions()
	local parts = {}
	for name, v in pairs(own) do
		local pv = mods[name]
		if pv == nil or Older(pv, v) then
			parts[#parts + 1] = name:gsub("^SentiUI_", "") .. "@" .. tostring(v)
			if #parts >= 8 then break end
		end
	end
	if #parts == 0 then return end
	notified[sender] = true
	local f = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
	if f then pcall(f, PREFIX, "SUIver;n;" .. table.concat(parts, ","), "WHISPER", sender) end
end

-- a peer tells US we are behind: list the modules with ours vs theirs
local function OnNotify(msg)
	local own = Comms.ModuleVersions()
	local out = {}
	for piece in msg:sub(10):gmatch("[^,]+") do
		local a, v = piece:match("^(.-)@(.*)$")
		if a then
			local mine = own[a] or own["SentiUI_" .. a]
			if not mine or Older(mine, v) then
				out[#out + 1] = format("%s: %s -> %s",
					a == "SentiUI" and a or "SentiUI_" .. a,
					tostring(mine or S.L["none"]), v)
			end
		end
	end
	if #out > 0 then
		S.PrintSystem(format(S.L["SentiUI update available: %s"], table.concat(out, ", ")))
	end
end

local function OnVersionMessage(msg, sender)
	local kind = msg:match("^SUIver;(%w+)")
	if kind == "q" then
		if not announcePending then
			announcePending = true
			C_Timer.After(1 + math.random() * 3, function()
				announcePending = nil
				Comms.Announce()
			end)
		end
		return
	end
	if kind == "n" then OnNotify(msg) return end
	if sender == "?" or sender == Comms.OwnName() then return end
	local e = Peer(sender)
	e.at = time()
	if kind == "v" then
		e.mods.SentiUI = msg:match("^SUIver;v;(.*)$") or "?"
		NotifyOutdated(sender, e.mods)
	elseif kind == "m" then
		local seq, tot, chunk = msg:match("^SUIver;m;(%d+)/(%d+);(.*)$")
		seq, tot = tonumber(seq), tonumber(tot)
		if seq and tot and chunk then
			e.parts = type(e.parts) == "table" and e.parts or {}
			e.parts[seq] = chunk
			local full = true
			for i = 1, tot do if not e.parts[i] then full = false end end
			if full then
				for piece in table.concat(e.parts):gmatch("[^,]+") do
					local a, v = piece:match("^(.-)@(.*)$")
					if a then e.mods[a] = v end
				end
				e.parts = nil
				NotifyOutdated(sender, e.mods)
			end
		end
	end
end

function Comms.Peers()
	local p, now, out = DB().peers, time(), {}
	for k, e in pairs(p) do
		if type(e) == "table" and now - (e.at or 0) < PEER_MAX_AGE then
			out[#out + 1] = { name = k, at = e.at, mods = e.mods or {} }
		else
			p[k] = nil
		end
	end
	table.sort(out, function(a, b) return (a.at or 0) > (b.at or 0) end)
	return out
end

-- how far a peer is behind: count modules we have that they lack or run
-- older (string compare - versions are n.n.n numerals on this suite)
Older = function(a, b)
	local na, nb = {}, {}
	for x in tostring(a or ""):gmatch("%d+") do na[#na + 1] = tonumber(x) end
	for x in tostring(b or ""):gmatch("%d+") do nb[#nb + 1] = tonumber(x) end
	for i = 1, math.max(#na, #nb) do
		local x, y = na[i] or 0, nb[i] or 0
		if x ~= y then return x < y end
	end
	return false
end

-- returns outdated, missing counts vs our own suite
function Comms.PeerStatus(mods)
	local own = Comms.ModuleVersions()
	local outdated, missing, total = 0, 0, 0
	for name, v in pairs(own) do
		total = total + 1
		local pv = type(mods) == "table" and mods[name]
		if pv == nil then
			missing = missing + 1
		elseif Older(pv, v) then
			outdated = outdated + 1
		end
	end
	return outdated, missing, total
end

-- live channel roster: GetChannelRosterInfo needs the channel's index in
-- the client channel list, not its number - resolve via GetChannelList
function Comms.Roster()
	if not chanNum then return nil end
	local ri = C_ChatInfo and C_ChatInfo.GetChannelRosterInfo or GetChannelRosterInfo
	local gl = GetChannelList or (C_ChatInfo and C_ChatInfo.GetChannelList)
	if type(ri) ~= "function" or type(gl) ~= "function" then return nil end
	local idx
	local ok, res = pcall(function() return { gl() } end)
	if ok and type(res) == "table" then
		for i = 1, #res, 3 do
			if tonumber(res[i]) == chanNum then idx = (i + 2) / 3 break end
		end
	end
	if not idx then return nil end
	local out = {}
	for i = 1, 500 do
		local okR, nm, owner, mod = pcall(ri, idx, i)
		if not okR or not nm then break end
		out[#out + 1] = { name = tostring(nm), owner = owner == true, mod = mod == true }
	end
	return out
end

-- event log ----------------------------------------------------------------

function Comms.AddLog(kind, text)
	local log = DB().log
	log[#log + 1] = { t = time(), kind = kind, text = text }
	while #log > LOG_MAX do table.remove(log, 1) end
	for _, fn in ipairs(logHandlers) do
		S.SafeCall("comms:log", fn, log[#log])
	end
end

function Comms.Log() return DB().log end

-- message + notice dispatch --------------------------------------------------

S.RegisterEvent("CHAT_MSG_ADDON", function(_, prefix, msg, dist, sender)
	if prefix ~= PREFIX or type(msg) ~= "string" then return end
	sender = type(sender) == "string" and sender or "?"
	if msg:sub(1, 7) == "SUIver;" then
		S.SafeCall("comms:ver", OnVersionMessage, msg, sender)
		return
	end
	for _, fn in ipairs(msgHandlers) do
		S.SafeCall("comms:msg", fn, msg, sender, dist)
	end
end)

-- CHAT_MSG_CHANNEL_NOTICE: type, player, language, channelName,
-- target, special, zoneID, channelIndex, channelBaseName
S.RegisterEvent("CHAT_MSG_CHANNEL_NOTICE", function(_, typ, sender, _, cname, target, _, _, _, base)
	local hit = (type(base) == "string" and base == CHANNEL)
		or (type(cname) == "string" and cname:find(CHANNEL, 1, true) ~= nil)
	if not hit then return end
	-- keep the roster state fresh: a join we missed still resolves chanNum
	if not chanNum then
		local n = ChanNumOf(CHANNEL)
		if n then chanNum = n end
	end
	local text
	if typ == "JOINED" then text = format(S.L["%s joined"], sender or "?")
	elseif typ == "LEFT" then text = format(S.L["%s left"], sender or "?")
	elseif typ == "YOU_JOINED" then text = S.L["you joined"]
	elseif typ == "YOU_LEFT" then text = S.L["you left"]
	elseif typ == "KICKED" then text = format(S.L["%s kicked %s"], sender or "?", target or "?")
	elseif typ == "BANNED" then text = format(S.L["%s banned %s"], sender or "?", target or "?")
	elseif typ == "UNBANNED" then text = format(S.L["%s unbanned %s"], sender or "?", target or "?")
	elseif typ == "OWNER_CHANGED" then text = format(S.L["owner is now %s"], sender or "?")
	elseif typ == "MODERATOR" then text = format(S.L["%s is now moderator"], sender or "?")
	elseif typ == "NOT_MODERATOR" or typ == "MODERATOR_REMOVED" then
		text = format(S.L["%s is no longer moderator"], sender or "?")
	elseif typ == "YOU_CHANGED" then text = S.L["channel slot changed"]
	elseif typ == "NOT_MEMBER" then text = S.L["not a channel member"]
	elseif typ == "WRONG_PASSWORD" then text = S.L["wrong channel password"]
	else text = tostring(typ) .. " " .. tostring(sender or "")
	end
	Comms.AddLog("notice", text)
	for _, fn in ipairs(noticeHandlers) do
		S.SafeCall("comms:notice", fn, typ, sender, target)
	end
	-- someone new just arrived: re-announce with jitter so they learn our
	-- suite version even if their own join query never reaches us
	if typ == "JOINED" then
		C_Timer.After(2 + math.random() * 4, function() Comms.Announce() end)
	end
end)

local function RegisterPrefix()
	local f = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix
		or RegisterAddonMessagePrefix
	if f then pcall(f, PREFIX) end
end

S.RegisterEvent("PLAYER_LOGIN", function()
	RegisterPrefix()
	C_Timer.After(6, JoinSync)
end)

-- rejoin watchdog: a lost channel rejoins within two minutes
C_Timer.NewTicker(120, function()
	local n = ChanNumOf(CHANNEL)
	if n then
		if n ~= chanNum then chanNum = n end
		return
	end
	chanNum = nil
	joinTries = 0
	JoinSync()
end)

-- periodic re-announce so late joiners learn who is around, plus a
-- periodic query that asks every peer for a fresh manifest - covers
-- peers that joined before us or whose announce we missed
C_Timer.NewTicker(900, function() Comms.Announce() end)
C_Timer.NewTicker(1800, function() Comms.Query() end)
