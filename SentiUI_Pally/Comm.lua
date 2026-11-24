-- The PLPWR addon channel: fully wire-compatible with PallyPower, so this
-- module and the real thing see the same paladins, the same assignments and
-- hand each other the same REQ/SELF answers. Message shapes mirror
-- PallyPower's exactly - that is the whole point of the file.
local _, ns = ...
local S = SentiUI
local L = ns.L
local D = ns.Data

local Comm = {}
ns.Comm = Comm

Comm.PREFIX = "PLPWR"

-- sync state ---------------------------------------------------------------
Comm.pallies = {}        -- name -> skills: [i]={rank,talent}, AuraInfo, symbols, freeassign, CooldownInfo, subgroup
Comm.ga = {}             -- name -> { class -> blessing } (class/greater blessings)
Comm.na = {}             -- name -> { class -> { target -> blessing } } (per-player)
Comm.aa = {}             -- name -> aura id
Comm.leaders = {}        -- name -> true (raid leader/assistants, home group only)

local lastMsg
local player, db
local unpack = unpack or table.unpack
local function split(sep, s)
	local out = {}
	for part in string.gmatch(s or "", "([^" .. sep .. "]*)") do
		out[#out + 1] = part
	end
	-- gmatch misses a trailing empty field; the wire never needs it
	return out
end

-- Forever names carry a space ("First Last"); the space-separated fields go
-- over the wire with "_" in place of the space, like PallyPower does.
local function wire(name) return (name:gsub(" ", "_")) end
local function unwire(name) return (name:gsub("_", " ")) end
local function noRealm(name)
	return name and unwire(name:gsub("%-.*$", "")) or name
end

local LFG_CAT = _G.LE_PARTY_CATEGORY_INSTANCE
local function inLFG()
	return LFG_CAT ~= nil and IsInGroup and IsInGroup(LFG_CAT) or false
end

local function dist()
	if inLFG() then return "INSTANCE_CHAT" end
	return IsInRaid() and "RAID" or "PARTY"
end

local function iAmLeader()
	return (UnitIsGroupLeader and UnitIsGroupLeader("player"))
		or (UnitIsGroupAssistant and UnitIsGroupAssistant("player")) or false
end

function Comm.Send(msg, dtype, target)
	if not (GetNumGroupMembers and GetNumGroupMembers() > 0) then return end
	if lastMsg == msg and not target then return end
	lastMsg = msg
	if C_Timer and C_Timer.After then
		C_Timer.After(1, function() if lastMsg == msg then lastMsg = nil end end)
	else
		lastMsg = nil
	end
	local fn = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
	if not fn then return end
	if target then
		pcall(fn, Comm.PREFIX, msg, "WHISPER", target)
	else
		pcall(fn, Comm.PREFIX, msg, dtype or dist())
	end
end

-- ---------------------------------------------------------------------------
-- outgoing state
-- ---------------------------------------------------------------------------

local function ensureMine()
	if not Comm.pallies[player] then
		Comm.pallies[player] = {}
	end
	local me = Comm.pallies[player]
	if not me.AuraInfo then me.AuraInfo = {} end
	if not me.CooldownInfo then me.CooldownInfo = {} end
	if not Comm.ga[player] then
		Comm.ga[player] = {}
	end
	return me
end

function Comm.ScanSelf()
	local me = ensureMine()
	for k in pairs(me) do
		if type(k) == "number" then me[k] = nil end
	end
	for i, s in pairs(D.Skills()) do me[i] = s end
	for k in pairs(me.AuraInfo) do me.AuraInfo[k] = nil end
	for i, s in pairs(D.AuraSkills()) do me.AuraInfo[i] = s end
	me.CooldownInfo = D.MyCooldowns()
	me.symbols = D.ItemCount(D.SYMBOL_ITEM)
	me.freeassign = db and db.freeassign or false
	if not me.subgroup then me.subgroup = 1 end
end

-- SELF answers a REQ privately in home groups, broadcast in instance groups.
function Comm.SendSelf(sender)
	if not db then return end
	if iAmLeader() then Comm.Send("PPLEADER " .. wire(player)) end
	local me = ensureMine()
	local leader = sender and Comm.leaders[sender]
	local s = ""
	for i = 1, D.BLESSINGS do
		local sk = me[i]
		s = s .. (sk and string.format("%x%x", sk.rank, sk.talent or 0) or "nn")
	end
	s = s .. "@"
	if not Comm.ga[player] then Comm.ga[player] = {} end
	-- my own assignments ride along from the saved row
	for i = 1, D.MAXCLASSES do
		local v = Comm.ga[player][i]
		s = s .. (v and v ~= 0 and tostring(v) or "n")
	end
	if sender and not leader then
		Comm.Send("SELF " .. s, nil, sender)
	else
		Comm.Send("SELF " .. s)
	end

	s = ""
	for i = 1, D.MAXAURAS do
		local a = me.AuraInfo[i]
		s = s .. (a and string.format("%x%x", a.rank, a.talent or 0) or "nn")
	end
	s = s .. "@" .. tostring(Comm.aa[player] or 0)
	if sender and not leader then
		Comm.Send("ASELF " .. s, nil, sender)
	else
		Comm.Send("ASELF " .. s)
	end

	-- my per-player overrides, batched five to a message
	local list = {}
	for class, tnames in pairs(Comm.na[player] or {}) do
		for tname, b in pairs(tnames) do
			list[#list + 1] = string.format("%s %s %s %s",
				wire(player), class, wire(tname), b)
		end
	end
	local off = 1
	while off <= #list do
		local chunk = { unpack(list, off, math.min(off + 4, #list)) }
		local msg = "NASSIGN " .. table.concat(chunk, "@")
		if sender and not leader then
			Comm.Send(msg, nil, sender)
		else
			Comm.Send(msg)
		end
		off = off + 5
	end

	if (GetNumGroupMembers and GetNumGroupMembers() or 0) > 0 then
		local cds = ""
		for i = 1, 2 do
			local c = me.CooldownInfo[i]
			cds = cds .. ":" .. (c and c.duration or "n") .. ":"
				.. (c and c.remaining and math.floor(c.remaining) or "n")
		end
		local msg = string.format("FREEASSIGN %s | SYMCOUNT %s | COOLDOWNS%s",
			me.freeassign and "YES" or "NO", tostring(me.symbols or 0), cds)
		if sender and not leader then
			Comm.Send(msg, nil, sender)
		else
			Comm.Send(msg)
		end
	end
end

-- ---------------------------------------------------------------------------
-- assignments (local + broadcast)
-- ---------------------------------------------------------------------------

function Comm.CanControl(name)
	if name == player then return true end
	if inLFG() then
		return Comm.pallies[name] and Comm.pallies[name].freeassign == true or false
	end
	if UnitIsGroupLeader and UnitIsGroupLeader("player") then return true end
	if UnitIsGroupAssistant and UnitIsGroupAssistant("player") then return true end
	return Comm.pallies[name] and Comm.pallies[name].freeassign == true or false
end

function Comm.SetClass(name, class, b)
	if not Comm.CanControl(name) then return end
	Comm.ga[name] = Comm.ga[name] or {}
	Comm.ga[name][class] = b
	Comm.Send(string.format("ASSIGN %s %s %s", wire(name), class, b))
	if ns.UI then ns.UI.Refresh() end
end

function Comm.SetAllClasses(name, b)
	if not Comm.CanControl(name) then return end
	Comm.ga[name] = Comm.ga[name] or {}
	for i = 1, D.MAXCLASSES do Comm.ga[name][i] = b end
	Comm.Send(string.format("MASSIGN %s %s", wire(name), b))
	if ns.UI then ns.UI.Refresh() end
end

function Comm.SetRow(name, row)
	if not Comm.CanControl(name) then return end
	Comm.ga[name] = Comm.ga[name] or {}
	local s = ""
	for i = 1, D.MAXCLASSES do
		Comm.ga[name][i] = row[i] or 0
		s = s .. ((row[i] and row[i] ~= 0) and row[i] or "n")
	end
	Comm.Send(string.format("PASSIGN %s@%s", wire(name), s))
	if ns.UI then ns.UI.Refresh() end
end

function Comm.SetNormal(name, class, tname, b)
	if not Comm.CanControl(name) then return end
	Comm.na[name] = Comm.na[name] or {}
	Comm.na[name][class] = Comm.na[name][class] or {}
	Comm.na[name][class][tname] = (b and b ~= 0) and b or nil
	Comm.Send(string.format("NASSIGN %s %s %s %s", wire(name), class, wire(tname), b or 0))
	if ns.UI then ns.UI.Refresh() end
end

function Comm.SetAura(name, aura)
	if not Comm.CanControl(name) then return end
	Comm.aa[name] = aura
	Comm.Send(string.format("AASSIGN %s %s", wire(name), aura))
	if ns.UI then ns.UI.Refresh() end
end

function Comm.Clear(skip)
	-- only the leader/assistant may broadcast a raid clear; without the role
	-- the button just wipes my own row (PallyPower semantics)
	if iAmLeader() then
		Comm.Send("CLEAR")
		Comm.WipeAssignments(skip and player or nil)
	else
		Comm.ga[player] = nil
		Comm.na[player] = nil
		Comm.aa[player] = 0
	end
	if ns.UI then ns.UI.Refresh() end
end

function Comm.WipeAssignments(keep)
	for name in pairs(Comm.ga) do
		if name ~= keep then Comm.ga[name] = nil end
	end
	for name in pairs(Comm.na) do
		if name ~= keep then Comm.na[name] = nil end
	end
	for name in pairs(Comm.aa) do
		if name ~= keep then Comm.aa[name] = nil end
	end
end

-- ---------------------------------------------------------------------------
-- incoming
-- ---------------------------------------------------------------------------

local function isLeader(sender) return Comm.leaders[sender] == true end

local function maySet(name, sender, leader)
	if name == sender or leader then return true end
	local t = Comm.pallies[name]
	return t and t.freeassign == true or false
end

local function cooldowns(msg, sender)
	if not string.find(msg, "COOLDOWNS") then return end
	local parts = split(":", msg)
	local d1, r1, d2, r2 = parts[2], parts[3], parts[4], parts[5]
	local me = Comm.pallies[sender]
	if not me then return end
	me.CooldownInfo = me.CooldownInfo or {}
	if not me.CooldownInfo[1] and r1 ~= "n" then
		d1, r1 = tonumber(d1), tonumber(r1)
		if d1 and r1 then
			me.CooldownInfo[1] = { start = GetTime() - (d1 - r1), duration = d1 }
		end
	end
	if not me.CooldownInfo[2] and r2 ~= "n" then
		d2, r2 = tonumber(d2), tonumber(r2)
		if d2 and r2 then
			me.CooldownInfo[2] = { start = GetTime() - (d2 - r2), duration = d2 }
		end
	end
end

local function onMessage(sender, msg)
	if sender == player or sender == nil then return end
	local leader = isLeader(sender)

	if msg == "REQ" then
		if IsInRaid() and inLFG() then
			Comm.SendSelf()
		else
			Comm.SendSelf(sender)
		end
	end

	if string.find(msg, "^PPLEADER") then
		local name = noRealm(string.match(msg, "^PPLEADER (.*)"))
		-- the leader runs a PLPWR client too: assignments from it are trusted
		if name and Comm.leaders[name] then Comm.remoteLeader = true end
	end

	if string.find(msg, "^SELF") then
		-- a SELF always re-sends skills and class assignments; per-player
		-- overrides arrive separately via NASSIGN and must NOT be wiped
		Comm.ga[sender] = {}
		Comm.pallies[sender] = {}
		Comm.na[sender] = Comm.na[sender] or {}
		local numbers, assign = string.match(msg, "SELF ([0-9a-fn]*)@([0-9n]*)")
		if numbers then
			for i = 1, D.BLESSINGS do
				local rank = string.sub(numbers, (i - 1) * 2 + 1, (i - 1) * 2 + 1)
				local talent = string.sub(numbers, (i - 1) * 2 + 2, (i - 1) * 2 + 2)
				if rank ~= "n" then
					Comm.pallies[sender][i] = { rank = tonumber(rank, 16), talent = tonumber(talent) }
				end
			end
		end
		if assign then
			for i = 1, D.MAXCLASSES do
				local t = string.sub(assign, i, i)
				Comm.ga[sender][i] = (t == "n" or t == "") and 0 or (t + 0)
			end
		end
	end

	if string.find(msg, "^ASSIGN") then
		local name, class, skill = string.match(msg, "^ASSIGN (.*) (.*) (.*)")
		name = noRealm(name)
		if name and maySet(name, sender, leader) then
			Comm.ga[name] = Comm.ga[name] or {}
			class, skill = (class or 0) + 0, (skill or 0) + 0
			if class >= 1 and class <= D.MAXCLASSES then
				Comm.ga[name][class] = skill
			end
		end
	end

	if string.find(msg, "^PASSIGN") then
		local name, assign = string.match(msg, "^PASSIGN (.*)@([0-9n]*)")
		name = noRealm(name)
		if name and maySet(name, sender, leader) then
			Comm.ga[name] = Comm.ga[name] or {}
			if assign then
				for i = 1, D.MAXCLASSES do
					local t = string.sub(assign, i, i)
					Comm.ga[name][i] = (t == "n" or t == "") and 0 or (t + 0)
				end
			end
		end
	end

	if string.find(msg, "^NASSIGN") then
		for rawp, class, rawt, skill in
			string.gmatch(string.sub(msg, 9), "([^@]*) ([^@]*) ([^@]*) ([^@]*)") do
			local pname, tname = unwire(rawp), unwire(rawt)
			local name = noRealm(pname)
			if name and maySet(name, sender, leader) then
				Comm.na[name] = Comm.na[name] or {}
				class = (class or 0) + 0
				Comm.na[name][class] = Comm.na[name][class] or {}
				skill = (skill or 0) + 0
				Comm.na[name][class][tname] = skill ~= 0 and skill or nil
			end
		end
	end

	if string.find(msg, "^MASSIGN") then
		local name, skill = string.match(msg, "^MASSIGN (.*) (.*)")
		name = noRealm(name)
		if name and maySet(name, sender, leader) then
			Comm.ga[name] = Comm.ga[name] or {}
			skill = (skill or 0) + 0
			for i = 1, D.MAXCLASSES do Comm.ga[name][i] = skill end
		end
	end

	if string.find(msg, "SYMCOUNT") then
		local n = string.match(msg, "SYMCOUNT ([0-9]*)")
		if Comm.pallies[sender] then
			Comm.pallies[sender].symbols = tonumber(n) or 0
		end
	end

	cooldowns(msg, sender)

	if string.find(msg, "^CLEAR") then
		if leader then
			Comm.WipeAssignments(string.find(msg, "SKIP") and sender or nil)
		elseif db and db.freeassign then
			Comm.WipeAssignments(string.find(msg, "SKIP") and player or nil)
		end
	end

	if string.find(msg, "FREEASSIGN YES") and Comm.pallies[sender] then
		Comm.pallies[sender].freeassign = true
	end
	if string.find(msg, "FREEASSIGN NO") and Comm.pallies[sender] then
		Comm.pallies[sender].freeassign = false
	end

	if string.find(msg, "^ASELF") then
		Comm.aa[sender] = 0
		if Comm.pallies[sender] then
			Comm.pallies[sender].AuraInfo = Comm.pallies[sender].AuraInfo or {}
			local numbers, assign = string.match(msg, "ASELF ([0-9a-fn]*)@([0-9n]*)")
			if numbers then
				for i = 1, D.MAXAURAS do
					local rank = string.sub(numbers, (i - 1) * 2 + 1, (i - 1) * 2 + 1)
					local talent = string.sub(numbers, (i - 1) * 2 + 2, (i - 1) * 2 + 2)
					if rank ~= "n" then
						Comm.pallies[sender].AuraInfo[i] = { rank = tonumber(rank, 16), talent = tonumber(talent) }
					end
				end
			end
			if assign then
				Comm.aa[sender] = (assign == "n" or assign == "") and 0 or (assign + 0)
			end
		end
	end

	if string.find(msg, "^AASSIGN") then
		local name, aura = string.match(msg, "^AASSIGN (.*) (.*)")
		name = noRealm(name)
		if name and maySet(name, sender, leader) then
			Comm.aa[name] = (aura or 0) + 0
		end
	end

	if ns.UI then ns.UI.Refresh() end
end

-- ---------------------------------------------------------------------------
-- wiring
-- ---------------------------------------------------------------------------

local function isPaladin()
	local ok, _, c = pcall(UnitClass, "player")
	return ok and c == "PALADIN"
end
Comm.isPaladin = isPaladin

local joined
function Comm.Enable(mod)
	db = mod.db
	player = D.UnitName("player") or UnitName("player")
	if Ambiguate then player = Ambiguate(player, "short") end

	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		pcall(C_ChatInfo.RegisterAddonMessagePrefix, Comm.PREFIX)
	end

	S.RegisterEvent("CHAT_MSG_ADDON", function(_, prefix, msg, dtype, source)
		if prefix ~= Comm.PREFIX then return end
		if dtype ~= "PARTY" and dtype ~= "RAID" and dtype ~= "INSTANCE_CHAT" and dtype ~= "WHISPER" then return end
		local sender = source and (Ambiguate and Ambiguate(source, "short") or source) or nil
		if sender then onMessage(sender, msg) end
	end)

	local function joinSync()
		Comm.pallies = {}
		Comm.ScanSelf()
		C_Timer.After(2, function()
			Comm.SendSelf()
			Comm.Send("REQ")
		end)
	end

	S.RegisterEvent("GROUP_ROSTER_UPDATE", function()
		Comm.roster = D.Roster()
		Comm.leaders = Comm.roster.leaders
		local n = GetNumGroupMembers and GetNumGroupMembers() or 0
		if n > 0 and not joined then
			joined = true
			joinSync()
		elseif n == 0 then
			joined = nil
			Comm.pallies = {}
			Comm.ScanSelf()
		else
			-- roster churn: a known paladin vanished means a stale table
			Comm.ScanSelf()
		end
		if ns.UI then ns.UI.Refresh() end
	end)

	S.RegisterEvent("SPELLS_CHANGED", function()
		Comm.ScanSelf()
		Comm.SendSelf()
	end)

	S.RegisterEvent("PLAYER_ROLES_ASSIGNED", function()
		if ns.UI then ns.UI.Refresh() end
	end)

	S.RegisterEvent("BAG_UPDATE", function()
		local me = ensureMine()
		me.symbols = D.ItemCount(D.SYMBOL_ITEM)
		if ns.UI then ns.UI.Refresh() end
	end)

	Comm.ScanSelf()
	-- my saved assignments re-enter the wire tables so SELF echoes them
	Comm.ga[player] = db.assign or {}
	Comm.na[player] = db.normals or {}
	Comm.aa[player] = db.auraAssign or 0
	Comm.roster = D.Roster()
	Comm.leaders = Comm.roster.leaders
end
