-- Quest progress, Sentinel style. The game's yellow lines mid-screen
-- ("Zombie slain: 5/8") arrive as UI_INFO_MESSAGE events whose message
-- types are the LE_GAME_ERR_QUEST_* constants. Claiming those ids in the
-- client's own BLACK_LISTED_MESSAGE_TYPES table keeps the game from
-- drawing them (its documented opt-out, no hooks) - then ours show
-- instead: the line dim with the count in accent and a thin bar under,
-- a tick for a finished objective, gold for a finished quest.
--
-- The same lines are posted to the party chat when shareProgress is on -
-- the text is the game's own, so it reads right in every language.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Progress = {}
ns.Progress = Progress

local db
local holder
local live = {}            -- visible lines, newest first
local kinds = {}           -- [messageType id] = "count" | "done" | "complete"
local ROWS, ROW_H, W, HOLD = 3, 28, 260, 2.6
local MAX_W = 560 -- row width cap: the line stays single, font shrinks first
local ACC = S.colors.accent

-- the client's quest-progress message types, by LE_GAME_ERR_* name;
-- a name the client lacks is skipped (those lines stay the game's)
local TYPES = {
	QUEST_ADD_KILL_SII = "count", QUEST_ADD_ITEM_SII = "count",
	QUEST_ADD_FOUND_SII = "count", QUEST_ADD_PLAYER_KILL_SII = "count",
	QUEST_OBJECTIVE_COMPLETE_S = "done", QUEST_UNKNOWN_COMPLETE = "done",
	QUEST_COMPLETE_S = "complete",
}

local function Claim()
	for name, kind in pairs(TYPES) do
		local id = _G["LE_GAME_ERR_" .. name]
		if type(id) == "number" then
			kinds[id] = kind
			if type(BLACK_LISTED_MESSAGE_TYPES) == "table" then
				BLACK_LISTED_MESSAGE_TYPES[id] =
					(db and db.progress ~= false) and true or nil
			end
		end
	end
end

-- split "Zombie slain: 5/8" into words + have + need (the count is the
-- last "have/need" in the line); without a count the text comes back whole
local function Parse(text)
	local s, e, have, need, at = nil, nil, nil, nil, 1
	while true do
		local a, b, h, n = text:find("(%d+)%s*/%s*(%d+)", at)
		if not a then break end
		s, e, have, need, at = a, b, h, n, b + 1
	end
	if not s then return text end
	local words = (text:sub(1, s - 1):gsub("[%s:]+$", ""))
	if words == "" then words = (text:sub(e + 1):gsub("^[%s:]+", "")) end
	return words ~= "" and words or text, tonumber(have), tonumber(need)
end

-- rows ----------------------------------------------------------------------
local rows = {}
local function GetRow(i)
	local r = rows[i]
	if r then return r end
	if InCombatLockdown() or not holder then return nil end
	r = CreateFrame("Frame", nil, holder)
	r:SetSize(W, ROW_H)
	r:EnableMouse(false)
	r:Hide() -- born hidden - Paint shows it only while a live entry exists

	-- full-width dim backdrop: without it a row whose text fails to render
	-- leaves a bare gold line floating on screen (it did)
	r.bg = r:CreateTexture(nil, "BACKGROUND")
	r.bg:SetAllPoints()
	r.bg:SetColorTexture(0, 0, 0, 0.42)
	if r.bg.SetGradient and CreateColor then
		pcall(r.bg.SetGradient, r.bg, "VERTICAL",
			CreateColor(0, 0, 0, 0.5), CreateColor(0, 0, 0, 0.28))
	end

	-- accent edge on the left, Sentinel signature
	local edge = r:CreateTexture(nil, "BACKGROUND", nil, 1)
	edge:SetColorTexture(ACC.r, ACC.g, ACC.b, 0.9)
	edge:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
	edge:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
	edge:SetWidth(2)

	-- count underline track + fill, tucked under the text
	r.track = r:CreateTexture(nil, "ARTWORK")
	r.track:SetColorTexture(1, 1, 1, 0.14)
	r.track:SetSize(140, 2)
	r.track:SetPoint("BOTTOM", r, "BOTTOM", 0, 5)
	r.track:Hide()
	r.bar = r:CreateTexture(nil, "ARTWORK", nil, 1)
	r.bar:SetColorTexture(ACC.r, ACC.g, ACC.b, 0.95)
	r.bar:SetSize(140, 2)
	r.bar:SetPoint("LEFT", r.track, "LEFT", 0, 0)
	r.bar:Hide()

	-- the string is created LAST so nothing can cover it. S.ApplyFont does
	-- what this client actually accepts (Font object + GetFont verify,
	-- SetFont only as fallback) - a bare SetFont silently failed here,
	-- which is why these rows showed bars without text
	r.text = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	S.ApplyFont(r.text, S.media.font, 12, "OUTLINE")
	r.text:SetTextColor(0.93, 0.94, 0.97)
	r.text:SetJustifyH("CENTER")
	r.text:SetJustifyV("TOP")
	-- no width constraint: the string sizes itself on one line instead of
	-- wrapping to a second; Paint() grows the row around it
	r.text:SetWordWrap(false)
	r.text:SetWidth(0)
	r.text:SetPoint("TOP", r, "TOP", 0, -3)

	r:SetPoint("TOP", holder, "TOP", 0, -(i - 1) * ROW_H)
	rows[i] = r
	return r
end

-- combat lockdown: rows are Frames - a row created under lockdown is
-- born protected and every Show/SetPoint/SetWidth on it fires
-- ADDON_ACTION_FORBIDDEN. Entries keep landing in `live` (plain data)
-- and the repaint runs on PLAYER_REGEN_ENABLED.
local repaint, regenWired
local function Paint()
	if InCombatLockdown() or not holder then repaint = true return end
	for i = 1, ROWS do
		local r, e = GetRow(i), live[i]
		if not r then return end -- pool creation deferred until out of combat
		if e then
			-- guard content, not the call: if SetText itself is broken it
			-- must surface the error instead of dying inside a pcall
			local t = e.text
			if type(t) ~= "string" or t == "" then t = "·" end
			r.text:SetText(t)
			-- one line sized to its text: shrink the font a step at a time
			-- only when a very long line would overflow the cap
			local rowW = W
			for _, fs in ipairs({ 12, 11, 10, 9 }) do
				S.ApplyFont(r.text, S.media.font, fs, "OUTLINE")
				local okW, sw = pcall(r.text.GetStringWidth, r.text)
				sw = (okW and type(sw) == "number") and sw or W
				rowW = math.max(150, math.min(sw + 18, MAX_W))
				if sw + 18 <= MAX_W then break end
			end
			r:SetWidth(rowW)
			if e.have and e.need and e.need > 0 then
				local frac = math.max(0, math.min(e.have / e.need, 1))
				local tw = math.min(140, rowW - 30)
				r.track:SetWidth(tw)
				r.bar:SetWidth(math.max(frac * tw, frac > 0 and 2 or 0))
				r.track:Show()
				r.bar:Show()
			else
				r.track:Hide()
				r.bar:Hide()
			end
			r:SetAlpha(e.alpha or 1)
			r:Show()
		else
			r:Hide()
		end
	end
end

local function Push(e)
	-- the same objective updates in place: the key is its words without
	-- the count, so "Zombie: 4/8" then "5/8" stay one row
	for i, x in ipairs(live) do
		if x.key == e.key then
			x.text, x.have, x.need = e.text, e.have, e.need
			x.t, x.alpha = e.t, 1
			Paint()
			return
		end
	end
	tinsert(live, 1, e)
	while #live > ROWS do tremove(live) end
	Paint()
end

local function Show(text, kind)
	local words, have, need = Parse(text)
	local key = words
	if kind == "done" then
		words = "|TInterface\\RaidFrame\\ReadyCheck-Ready:11|t "
			.. "|cff" .. S.Hex(S.colors.green) .. words .. "|r"
	elseif kind == "complete" then
		words = "|cff" .. S.Hex(ACC) .. words .. "|r"
	else
		words = "|cffd8dbe0" .. words .. "|r"
	end
	if have and need then
		words = words .. "  |cff" .. S.Hex(ACC) .. have .. "|r"
			.. "|cff666c80/|r" .. "|cff" .. S.Hex(ACC) .. need .. "|r"
	end
	Push({ key = key, text = words, have = have, need = need,
		t = GetTime() })
end

-- SendChatMessage may only exist as C_ChatInfo.SendChatMessage on this
-- client, and IsInGroup may be missing - both failures are silent
local function InGroup()
	if IsInGroup and IsInGroup() then return true end
	if GetNumGroupMembers then
		local ok, n = pcall(GetNumGroupMembers)
		if ok and type(n) == "number" and n > 1 then return true end
	end
	return false
end

local function Share(text, kind)
	if not (db and db.shareProgress ~= false) then return end
	if not InGroup() then return end
	if S.IsSecret(text) or S.IsSecret(kind) then return end
	local msg = text
	if kind == "complete" then
		msg = format("%s %s", L["Quest complete:"], text)
	end
	local send = (C_ChatInfo and C_ChatInfo.SendChatMessage)
		or SendChatMessage
	-- chat output inside an event dispatch is a forbidden call on this
	-- client - the send must run in its own deferred pass
	if send and C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			if InCombatLockdown and InCombatLockdown() then return end
			pcall(send, msg, "PARTY")
		end)
	end
end

-- quest title for the share lines: modern C_QuestLog first, then the
-- classic globals - all guarded since the client may lack either
local function QuestTitle(questID)
	if not C_QuestLog then return end
	if C_QuestLog.GetTitleForQuestID then
		local ok, t = pcall(C_QuestLog.GetTitleForQuestID, questID)
		if ok and type(t) == "string" then return t end
	end
	if C_QuestLog.GetQuestInfo then
		local ok, t = pcall(C_QuestLog.GetQuestInfo, questID)
		if ok and type(t) == "string" then return t end
	end
	if type(GetQuestLogTitle) == "function" then
		local ok, t = pcall(GetQuestLogTitle, questID)
		if ok and type(t) == "string" then return t end
	end
end

-- QUEST_ACCEPTED / QUEST_TURNED_IN: the share covers quest flow, not
-- just objective counts. QUEST_ACCEPTED arg order differs per client -
-- it is either (questID) or (unit, questID)
function Progress.OnAccepted(_, a1, a2)
	local id = type(a2) == "number" and a2 or a1
	if type(id) ~= "number" or S.IsSecret(id) then return end
	local t = QuestTitle(id)
	if t then Share(format("%s %s", L["Quest accepted:"], t), "done") end
end

function Progress.OnTurnedIn(_, questID)
	if type(questID) ~= "number" or S.IsSecret(questID) then return end
	local t = QuestTitle(questID)
	-- Share() prepends "Quest complete:" itself - pass the bare title
	if t then Share(t, "complete") end
end

-- the client's info line -> our styled row + the party share
function Progress.OnInfo(_, msgType, text)
	if S.IsSecret(msgType) or type(msgType) ~= "number" then return end
	local kind = kinds[msgType]
	if not kind or type(text) ~= "string" then return end
	if db.progress ~= false and not S.IsSecret(text) then
		Show(text, kind)
	end
	Share(text, kind)
end

function Progress.SetDb(d) db = d end

-- /sqtest paints sample lines so the styling can be checked without a
-- real quest update, then dumps the font string state of row 1 - if the
-- bars show but "width" prints 0/none the font is the broken piece
SLASH_SENTIUIQUESTTEST1 = "/sqtest"
SlashCmdList.SENTIUIQUESTTEST = function()
	if not holder then print("|cffebad33sqtest:|r holder missing") return end
	Show("Mindless Zombie slain: 5/8", "count")
	Show("Find the totem", "done")
	Show("The Dead Fields", "complete")
	local r = rows[1]
	if not r then print("|cffebad33sqtest:|r no row") return end
	local okN, fname = pcall(r.text.GetFont, r.text)
	local okT, txt = pcall(r.text.GetText, r.text)
	local okW, w = pcall(r.text.GetStringWidth, r.text)
	local okA, a = pcall(r.GetAlpha, r)
	print("|cffebad33sqtest row1:|r")
	print(" font: " .. (okN and tostring(fname) or "err"))
	print(" text: " .. (okT and ("'" .. tostring(txt) .. "'") or "err"))
	print(" width: " .. tostring(okW and w or "err")
		.. " alpha: " .. tostring(okA and a or "err")
		.. " shown: " .. tostring(r:IsShown()))
	-- is something else drawing these lines? count claimed ids
	local total, claimed = 0, 0
	for id in pairs(kinds) do
		total = total + 1
		if type(BLACK_LISTED_MESSAGE_TYPES) == "table"
			and BLACK_LISTED_MESSAGE_TYPES[id] then
			claimed = claimed + 1
		end
	end
	print(" claimed message types: " .. claimed .. "/" .. total)
end

function Progress.Apply()
	-- the holder + row pool are built out of combat: frames created
	-- during lockdown are born protected and every Show/SetPoint on them
	-- fires ADDON_ACTION_FORBIDDEN
	if InCombatLockdown() then
		S.RunOutOfCombat(Progress.Apply)
		return
	end
	Claim()
	if db and db.progress ~= false and not holder then
		holder = CreateFrame("Frame", "SentiUIQuestProgress", UIParent)
		holder:SetSize(W, ROWS * ROW_H)
		holder:SetPoint("TOP", UIParent, "TOP", 0, -92)
		holder:SetFrameStrata("HIGH")
		holder:EnableMouse(false)
		S.Movers.Register(holder, "quests.progress", L["Quest progress"])
		for i = 1, ROWS do GetRow(i) end
		holder:SetScript("OnUpdate", function(_, dt)
			local now, dirty = GetTime(), false
			for i = #live, 1, -1 do
				local e = live[i]
				if now - e.t > HOLD then
					e.alpha = (e.alpha or 1) - (dt or 0.016) * 1.6
					if e.alpha <= 0 then
						tremove(live, i)
						dirty = true
					end
				end
			end
			if dirty then Paint() else
				for i, e in ipairs(live) do
					if rows[i] then rows[i]:SetAlpha(e.alpha or 1) end
				end
			end
		end)
	end
	if holder then holder:SetShown(db and db.progress ~= false) end
	if not regenWired then
		regenWired = true
		S.RegisterEvent("PLAYER_REGEN_ENABLED", function()
			if repaint then repaint = nil Paint() end
		end)
	end
end
