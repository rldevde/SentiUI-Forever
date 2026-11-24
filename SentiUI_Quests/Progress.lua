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
	-- the row itself stays shown forever; every piece the player sees is a
	-- region (FontString/Texture) Paint shows, hides, sizes and fades.
	-- Region ops are legal under combat lockdown where Show/SetPoint/
	-- SetWidth on the frame would fire ADDON_ACTION_FORBIDDEN - this is
	-- what keeps the loot lines counting mid-fight.

	-- full-width dim backdrop: without it a row whose text fails to render
	-- leaves a bare gold line floating on screen (it did). Centered on the
	-- row and sized per Paint so the box hugs the text
	r.bg = r:CreateTexture(nil, "BACKGROUND")
	r.bg:SetPoint("CENTER", r, "CENTER")
	r.bg:SetSize(W, ROW_H)
	r.bg:SetColorTexture(0, 0, 0, 0.42)
	if r.bg.SetGradient and CreateColor then
		pcall(r.bg.SetGradient, r.bg, "VERTICAL",
			CreateColor(0, 0, 0, 0.5), CreateColor(0, 0, 0, 0.28))
	end
	r.bg:Hide()

	-- accent edge on the left, Sentinel signature
	r.edge = r:CreateTexture(nil, "BACKGROUND", nil, 1)
	r.edge:SetColorTexture(ACC.r, ACC.g, ACC.b, 0.9)
	r.edge:SetPoint("TOPLEFT", r.bg, "TOPLEFT")
	r.edge:SetPoint("BOTTOMLEFT", r.bg, "BOTTOMLEFT")
	r.edge:SetWidth(2)
	r.edge:Hide()

	-- count underline track + fill, tucked under the text
	r.track = r:CreateTexture(nil, "ARTWORK")
	r.track:SetColorTexture(1, 1, 1, 0.14)
	r.track:SetSize(140, 2)
	r.track:SetPoint("BOTTOM", r.bg, "BOTTOM", 0, 5)
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
-- ADDON_ACTION_FORBIDDEN. The pool is warmed out of combat and Paint
-- below only ever touches REGIONS (FontStrings/Textures) on existing
-- rows - legal mid-fight, so loot lines keep counting live instead of
-- expiring unseen inside `live` before the regen repaint can run.
local function RowAlpha(r, a)
	r.bg:SetAlpha(a)
	r.edge:SetAlpha(a)
	r.text:SetAlpha(a)
	r.track:SetAlpha(a)
	r.bar:SetAlpha(a)
end

-- expired rows can fly off to a screen edge while they fade (feedExit):
-- the flight is measured once from the row's spot to off-screen and eased
-- in quadratically, so it accelerates out exactly as its alpha dies. The
-- slide re-points pooled frames - legal mid-fight, the pool is only ever
-- built out of combat.
local function StartExit(e, r)
	local dir = db and db.feedExit or "right"
	if dir == "fade" or not r or e.exiting then return end
	local okC, cx = pcall(r.GetCenter, r)
	local okW, rw = pcall(r.bg.GetWidth, r.bg)
	cx = (okC and type(cx) == "number") and cx or ((GetScreenWidth() or 1920) / 2)
	local half = (okW and type(rw) == "number") and rw / 2 or W / 2
	e.exiting = true
	e.exitFrom = e.curX or 0
	e.exitX = (dir == "left") and -(cx + half + 40)
		or ((GetScreenWidth() or 1920) - cx + half + 40)
end

local function Paint()
	if not holder then return end
	for i = 1, ROWS do
		local r, e = GetRow(i), live[i]
		if not r then return end -- pool creation deferred until out of combat
		r:ClearAllPoints()
		r:SetPoint("TOP", holder, "TOP",
			(e and e.curX) or 0, -(i - 1) * ROW_H)
		if e then
			-- guard content, not the call: if SetText itself is broken it
			-- must surface the error instead of dying inside a pcall. A
			-- secret text goes to the engine raw - it still prints
			local t = e.text
			if not S.IsSecret(t) and (type(t) ~= "string" or t == "") then
				t = "·"
			end
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
			r.bg:SetWidth(rowW)
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
			RowAlpha(r, e.alpha or 1)
			r.bg:Show()
			r.edge:Show()
		else
			r.text:SetText("")
			r.bg:Hide()
			r.edge:Hide()
			r.track:Hide()
			r.bar:Hide()
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
			-- a merged row was mid-flight: put it back in place
			x.exiting, x.curX = nil, 0
			Paint()
			return
		end
	end
	tinsert(live, 1, e)
	while #live > ROWS do tremove(live) end
	Paint()
end

-- quest-complete toast: big card that fades in, holds ~3s, lifts out.
-- Built once next to the feed pool - frames made under lockdown are
-- born protected on this client
local toast
local function BuildToast()
	toast = CreateFrame("Frame", "SentiUIQuestToast", UIParent)
	S.Template(toast, "raised")
	toast:SetSize(320, 64)
	toast:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
	toast:SetFrameStrata("HIGH")
	local icon = toast:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
	icon:SetSize(26, 26)
	icon:SetPoint("LEFT", 14, 0)
	local cap = S.Font(toast, 11, ACC, "OUTLINE")
	cap:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1)
	toast.cap = cap
	local name = S.Font(toast, 12)
	name:SetPoint("TOPLEFT", cap, "BOTTOMLEFT", 0, -3)
	name:SetPoint("RIGHT", toast, "RIGHT", -12, 0)
	name:SetJustifyH("LEFT")
	name:SetWordWrap(false)
	toast.name = name
	toast:SetAlpha(0)
	toast:Hide()
end

local function ShowToast(caption, title)
	if not toast then return end
	pcall(toast.cap.SetText, toast.cap, caption)
	pcall(toast.name.SetText, toast.name, title)
	toast.t = 0
	toast:Show()
	toast:SetScript("OnUpdate", function(self, dt)
		self.t = self.t + (dt or 0.016)
		local a
		if self.t < 0.25 then a = self.t / 0.25
		elseif self.t < 2.8 then a = 1
		elseif self.t < 3.4 then a = 1 - (self.t - 2.8) / 0.6
		else
			self:SetScript("OnUpdate", nil)
			self:Hide()
			return
		end
		self:SetAlpha(a)
		self:ClearAllPoints()
		self:SetPoint("CENTER", UIParent, "CENTER", 0,
			120 + math.min(self.t, 3.4) * 8)
	end)
end

local function Show(text, kind)
	-- a secret message text (combat lockdown can mark it) cannot be
	-- parsed or wrapped - Lua would throw - so it goes to the row raw:
	-- FontString:SetText still prints it. A fresh table as key keeps the
	-- in-place update check from comparing two secrets (that throws too)
	if S.IsSecret(text) then
		Push({ key = {}, text = text, t = GetTime() })
		return
	end
	local words, have, need = Parse(text)
	local key = words
	if kind == "complete" and db.completeToast ~= false then
		ShowToast(L["Quest complete!"], words)
	elseif kind == "done" and db.objectiveToast ~= false then
		ShowToast(L["Objective complete!"], words)
	end
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
	if not kind then return end
	if type(text) ~= "string" and not S.IsSecret(text) then return end
	if db.progress ~= false then
		Show(text, kind) -- handles secret text internally
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
		BuildToast()
		holder:SetScript("OnUpdate", function(_, dt)
			local now, dirty = GetTime(), false
			for i = #live, 1, -1 do
				local e = live[i]
				if now - e.t > HOLD then
					StartExit(e, rows[i])
					e.alpha = (e.alpha or 1) - (dt or 0.016) * 1.6
					if e.alpha <= 0 then
						tremove(live, i)
						dirty = true
					end
				end
			end
			if dirty then Paint() else
				for i, e in ipairs(live) do
					local r = rows[i]
					if r then
						r:SetAlpha(e.alpha or 1)
						if e.exiting then
							local f = e.alpha or 1
							e.curX = (e.exitFrom or 0)
								+ e.exitX * (1 - f * f)
							r:SetPoint("TOP", holder, "TOP",
								e.curX, -(i - 1) * ROW_H)
						end
					end
				end
			end
		end)
	end
	if holder then holder:SetShown(db and db.progress ~= false) end
end
