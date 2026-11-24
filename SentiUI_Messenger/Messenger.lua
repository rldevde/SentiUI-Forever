-- SentiUI messenger: a whisper hub. Every conversation lives in a side list
-- (pinned first, then recent, with the last line and an unread count), the
-- picked conversation shows as a thread on the right with its own reply box.
-- Character whispers persist per account, Battle.net ones last for the
-- session because their sender names can be secret.
local _, ns = ...
local S = SentiUI
local L = ns.L
local W = S.Widgets
local IsSecret = S.IsSecret

local pairs, ipairs, pcall, type, tostring = pairs, ipairs, pcall, type, tostring
local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local format, gsub, lower, date = string.format, string.gsub, string.lower, date
local strtrim = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

local C = S.colors

local Core = {}
ns.Core = Core
local db

local MAX_UNREAD_BADGE = 99
local AWAY_GAP = 900        -- seconds between two auto replies to one person
local SOUND_GAP = 4         -- minimum seconds between two incoming sounds

local convos = {}           -- key -> conversation
local seq = 0
local awaySent = {}         -- key -> last auto-reply time
local lastSound = 0
local lastFrom              -- key of the last incoming whisper (reply target)
local origReplyTell         -- the game's ChatFrame_ReplyTell before our override

-- ---------------------------------------------------------------------------
-- store
-- ---------------------------------------------------------------------------

local function plain(v) return type(v) ~= "nil" and not IsSecret(v) end

local function saved()
	if type(db.convos) ~= "table" then db.convos = {} end
	return db.convos
end

local function normName(name)
	if type(name) ~= "string" or name == "" then return nil end
	return (strtrim(name))
end

local function keyOf(name, bn, presenceID)
	if bn then return "bn:" .. tostring(presenceID or name) end
	return "c:" .. name
end

local function Get(name, bn, presenceID)
	return convos[keyOf(name, bn, presenceID)]
end

local function ensure(name, bn, presenceID)
	local key = keyOf(name, bn, presenceID)
	local c = convos[key]
	if not c then
		c = { key = key, name = name, bn = bn or nil, presenceID = presenceID,
		      msgs = {}, unread = 0 }
		convos[key] = c
	end
	if bn and presenceID then c.presenceID = presenceID end
	return c
end

-- learn the player's class and level from their GUID for the colored
-- name and the header info line; the guild is probed by name when the
-- API allows it
local function learn(c, guid)
	if not plain(guid) or type(guid) ~= "string" or guid == "" then return end
	c.guid = guid
	if type(GetPlayerInfoByGUID) ~= "function" then return end
	local ok, _, class, _, _, _, _, _, level = pcall(GetPlayerInfoByGUID, guid)
	if ok and plain(class) and type(class) == "string" then c.class = class end
	if ok and plain(level) and type(level) == "number" and level > 0 then c.level = level end
end

local function learnGuild(c)
	if c.guildKnown then return end
	c.guildKnown = true
	if c.bn or type(GetGuildInfo) ~= "function" then return end
	local ok, g = pcall(GetGuildInfo, c.name)
	if ok and plain(g) and type(g) == "string" and g ~= "" then c.guild = g end
end

-- "Lvl 19  ·  Priest  ·  <Guild>" for the card/hub header
local function infoLine(c)
	local out = {}
	if c.level then out[#out + 1] = tostring(c.level) end
	local cls = c.class and LOCALIZED_CLASS_NAMES_MALE
		and LOCALIZED_CLASS_NAMES_MALE[c.class]
	if cls then out[#out + 1] = cls end
	learnGuild(c)
	if c.guild then out[#out + 1] = "<" .. c.guild .. ">" end
	return table.concat(out, "  ·  ")
end

-- drop the oldest unpinned conversations past the cap
local function trim()
	local list = Core.List()
	for i = #list, math.max(1, db.maxConvos or 40) + 1, -1 do
		local c = list[i]
		if not c.pinned then
			convos[c.key] = nil
			saved()[c.key] = nil
		end
	end
end

function Core.List()
	local out = {}
	for _, c in pairs(convos) do
		if #c.msgs > 0 then out[#out + 1] = c end
	end
	tsort(out, function(a, b)
		if (a.pinned == true) ~= (b.pinned == true) then return a.pinned == true end
		return (a.at or 0) > (b.at or 0)
	end)
	return out
end

function Core.Unread()
	local n = 0
	for _, c in pairs(convos) do n = n + (c.unread or 0) end
	return n
end

-- append a line; me = sent by you. Returns whether the line was stored.
local function add(c, text, me)
	seq = seq + 1
	c.at = seq
	tinsert(c.msgs, { t = time(), me = me or nil, text = text })
	local cap = db.historySize or 80
	while #c.msgs > cap do tremove(c.msgs, 1) end
	if not c.bn then saved()[c.key] = c end
	if not me and not Core.Showing(c.key) and not Core.CardShowing(c.key) then
		c.unread = (c.unread or 0) + 1
	end
	trim()
	Core.Refresh()
	if not me then Core.Preview(c, text) end
	return true
end

local function markRead(c)
	if c and (c.unread or 0) > 0 then
		c.unread = 0
		Core.RefreshBadge()
	end
end

-- restore persisted character conversations on enable
local function loadSaved()
	for key, c in pairs(saved()) do
		if type(c) == "table" and type(c.name) == "string" and type(c.msgs) == "table" then
			c.key = key
			c.unread = 0
			convos[key] = c
		end
	end
end

-- ---------------------------------------------------------------------------
-- sending
-- ---------------------------------------------------------------------------

local function sendTo(c, text)
	if type(text) ~= "string" or strtrim(text) == "" then return end
	text = strtrim(text)
	if c.bn then
		local pid = c.presenceID
		if pid and type(BNSendWhisper) == "function" then
			local ok = pcall(BNSendWhisper, pid, text)
			if ok then add(c, text, true) end
		elseif type(C_ChatInfo) == "table" and C_ChatInfo.SendChatMessage then
			-- some clients route BN whispers through the chat info call
			local ok = pcall(C_ChatInfo.SendChatMessage, text, "BN_WHISPER", nil, pid or c.name)
			if ok then add(c, text, true) end
		end
	else
		if type(C_ChatInfo) == "table" and C_ChatInfo.SendChatMessage then
			local ok = pcall(C_ChatInfo.SendChatMessage, text, "WHISPER", nil, c.name)
			if ok then add(c, text, true) end
		end
	end
end

local function maybeAway(c)
	if not db.autoReply or c.bn then return end
	if type(UnitIsAFK) ~= "function" or not UnitIsAFK("player") then return end
	local now = time()
	if awaySent[c.key] and now - awaySent[c.key] < AWAY_GAP then return end
	awaySent[c.key] = now
	local text = db.autoReplyText
	if type(text) ~= "string" or strtrim(text) == "" then
		text = DEFAULT_AFK_MESSAGE or L["Away"] or "AFK"
	end
	sendTo(c, text)
end

-- ---------------------------------------------------------------------------
-- incoming events
-- ---------------------------------------------------------------------------

local function onWhisper(event, msg, sender, _, _, _, _, _, _, _, _, _, guid, presenceID)
	-- a whisper with a secret sender or text can't be stored; the chat box
	-- still shows it on its own
	if not plain(sender) or type(sender) ~= "string" or sender == "" then return end
	if not plain(msg) or type(msg) ~= "string" or msg == "" then return end
	local bn = event:find("BN_") ~= nil
	if bn and not plain(presenceID) then return end
	local name = normName(sender)
	if not name then return end
	local c = ensure(name, bn, presenceID)
	if bn then c.bnName = name end
	learn(c, guid)
	local me = event:find("_INFORM") ~= nil
	-- sendTo already echoed our own line; the INFORM event would add it
	-- a second time
	if me then
		local last = c.msgs[#c.msgs]
		if last and last.me and last.text == msg and (time() - (last.t or 0)) < 5 then
			return
		end
	end
	add(c, msg, me)
	if not me then
		lastFrom = c.key
		if db.autoOpen then Core.OpenCard(c.key) end
		maybeAway(c)
		if db.sound then
			local now = GetTime()
			if now - lastSound >= SOUND_GAP then
				lastSound = now
				pcall(PlaySound, SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master")
			end
		end
	end
end

-- shared thread widget (hub right pane + conversation card): a real
-- ScrollingMessageFrame so item/spell links stay clickable
local function MakeThread(parent)
	local t = CreateFrame("ScrollingMessageFrame", nil, parent)
	t:SetFont(S.media.font, 11, "")
	t:SetFading(false)
	t:SetMaxLines(400)
	t:SetJustifyH("LEFT")
	pcall(t.SetHyperlinksEnabled, t, true)
	t:EnableMouseWheel(true)
	t:SetScript("OnMouseWheel", function(self, d)
		if d > 0 then self:ScrollUp() else self:ScrollDown() end
	end)
	t:SetScript("OnHyperlinkClick", function(self, link, text, button)
		pcall(SetItemRef, link, text, button, self)
	end)
	t:SetScript("OnHyperlinkEnter", function(self, link)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		pcall(GameTooltip.SetHyperlink, GameTooltip, link)
		GameTooltip:Show()
	end)
	t:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
	return t
end

-- ---------------------------------------------------------------------------
-- hub window
-- ---------------------------------------------------------------------------

local hub, search, listSF, rows = nil, nil, nil, {}
local smf, input, sendBtn, titleSub, hubInfo
local picked

function Core.Showing(key)
	return hub ~= nil and hub:IsShown() and picked == key
end

local LIST_W, EDGE, ROW_H = 240, 14, 44

local function RowClassColor(c)
	if c.bn then return C.accent2.r, C.accent2.g, C.accent2.b end
	local cl = c.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[c.class]
	if cl then return cl.r, cl.g, cl.b end
	return C.text.r, C.text.g, C.text.b
end

local function stripMarkup(text)
	-- the preview line can't render icons/links; keep the visible label
	text = gsub(text or "", "|T.-|t", "")
	text = gsub(text, "|H.-|h(.-)|h", "%1")
	text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
	text = gsub(text, "|r", "")
	return text
end

local function displayName(c)
	if c.bn then return c.bnName or c.name or L["Battle.net"] end
	return c.name
end

local function timeAgo(t)
	if time() - (t or 0) < 86400 then return date("%H:%M", t) end
	return date("%d.%m", t)
end

local function matches(c, q)
	if q == "" then return true end
	if lower(displayName(c)):find(q, 1, true) then return true end
	for _, m in ipairs(c.msgs) do
		if lower(stripMarkup(m.text)):find(q, 1, true) then return true end
	end
	return false
end

local function FillSMF(target, c)
	if not target then return end
	target:Clear()
	if not c then return end
	for _, m in ipairs(c.msgs) do
		local stamp = db.timestamps and ("|cff8b8f9a" .. date("%H:%M", m.t) .. "|r ") or ""
		if m.me then
			target:AddMessage(stamp .. "|cff" .. S.Hex(C.accent2) .. L["You"] .. ":|r " .. m.text)
		else
			local r, g, b = RowClassColor(c)
			target:AddMessage(stamp .. "|cff" .. S.Hex({ r = r, g = g, b = b }) ..
				displayName(c) .. ":|r " .. m.text)
		end
	end
	target:ScrollToBottom()
end

local function FillThread()
	if not smf then return end
	FillSMF(smf, picked and convos[picked])
end

local function UpdateInputTarget()
	if not input then return end
	local c = picked and convos[picked]
	if hubInfo then hubInfo:SetText(c and infoLine(c) or "") end
	if c then
		input.placeholder:SetText(format(L["Whisper to %s"], displayName(c)))
		sendBtn:SetEnabled(true)
		sendBtn:SetAlpha(1)
	else
		input.placeholder:SetText(L["No conversations yet."])
		sendBtn:SetEnabled(false)
		sendBtn:SetAlpha(0.5)
	end
end

local function Pick(key)
	picked = key
	local c = key and convos[key]
	if c then markRead(c) end
	FillThread()
	UpdateInputTarget()
	Core.RebuildList()
end

-- ForeverBlackListed bridge ---------------------------------------------------
-- the standalone addon keeps its blacklist state; lookups are cheap table
-- reads. BN conversations have no character name - no list actions.
local function FBLRef()
	local F = _G.ForeverBlackListed
	return (type(F) == "table" and type(F.FindEntry) == "function") and F or nil
end

local function FBLEntry(c)
	local F = (c and not c.bn) and FBLRef() or nil
	if not F or type(c.name) ~= "string" then return nil end
	local ok, e = pcall(F.FindEntry, F, "player", c.name)
	return ok and e or nil
end

-- context menu on a conversation row -----------------------------------------
local menu, menuCatch
local function CloseConvoMenu()
	if menu then menu:Hide() end
	if menuCatch then menuCatch:Hide() end
end

local function ConvoMenu(c, anchor)
	local items = {
		{ text = displayName(c), title = true },
		{ text = L["Open"], fn = function() Core.Open(c.key) end },
		{ text = c.pinned and L["Unpin"] or L["Pin"], fn = function()
			c.pinned = not c.pinned or nil
			if not c.bn then saved()[c.key] = c end
			Core.RebuildList()
		end },
	}
	local F = FBLRef()
	if F then
		local e = FBLEntry(c)
		if e then
			items[#items + 1] = { text = e.list == "good"
					and ("|cff4dd278" .. L["Remove from good list"] .. "|r")
					or ("|cffff5555" .. L["Remove from blacklist"] .. "|r"),
				fn = function()
					F:RemoveEntry(e)
					if F.RefreshWindow then F:RefreshWindow() end
					if F.DataDirty then F:DataDirty() end
					Core.RebuildList()
				end }
		else
			items[#items + 1] = { text = "|cffff5555" .. L["Add to blacklist"] .. "|r",
				fn = function()
					F:PromptNoteAdd(c.name, "player", "black")
					Core.RebuildList()
				end }
			items[#items + 1] = { text = "|cff4dd278" .. L["Add to good list"] .. "|r",
				fn = function()
					F:PromptNoteAdd(c.name, "player", "good")
					Core.RebuildList()
				end }
		end
	end
	items[#items + 1] = { text = "|cffff5555" .. L["Delete"] .. "|r",
		fn = function() Core.DeleteConvo(c.key) end }

	if not menu then
		menuCatch = CreateFrame("Button", nil, UIParent)
		menuCatch:SetAllPoints(UIParent)
		menuCatch:SetFrameStrata("TOOLTIP")
		menuCatch:SetFrameLevel(1)
		menuCatch:RegisterForClicks("AnyUp", "AnyDown")
		menuCatch:SetScript("OnClick", CloseConvoMenu)
		menuCatch:Hide()
		menu = CreateFrame("Frame", "SentiUIMessengerMenu", UIParent, "BackdropTemplate")
		menu:SetFrameStrata("TOOLTIP")
		menu:SetFrameLevel(10)
		menu:SetToplevel(true)
		menu:EnableMouse(true)
		S.Template(menu, "panel")
		S.EscClosable(menu)
		menu.items = {}
	end
	for _, b in ipairs(menu.items) do b:Hide() end
	local y = 4
	for i, it in ipairs(items) do
		local b = menu.items[i]
		if not b then
			b = CreateFrame("Button", nil, menu, "BackdropTemplate")
			S.Template(b, "inset")
			b.label = S.Font(b, 11, C.text)
			b.label:SetPoint("LEFT", 8, 0)
			b.label:SetPoint("RIGHT", -8, 0)
			b.label:SetJustifyH("LEFT")
			b:SetScript("OnEnter", function(s) S.SetBorderLit(s, true) end)
			b:SetScript("OnLeave", function(s) S.SetBorderLit(s, false) end)
			menu.items[i] = b
		end
		b:SetPoint("TOPLEFT", 4, -y)
		b:SetPoint("TOPRIGHT", -4, -y)
		b:SetHeight(20)
		b.label:SetText(it.text)
		b.label:SetTextColor(it.title and C.accent.r or C.text.r,
			it.title and C.accent.g or C.text.g,
			it.title and C.accent.b or C.text.b)
		b:EnableMouse(not it.title)
		b:SetScript("OnClick", function()
			CloseConvoMenu()
			if it.fn then it.fn() end
		end)
		b:Show()
		y = y + 24
	end
	menu:SetSize(190, y + 4)
	local scale = UIParent:GetEffectiveScale() or 1
	local cx, cy = GetCursorPosition()
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale + 4, cy / scale + 4)
	menuCatch:Show()
	menu:Show()
end

local function rowButtons(row)
	-- small hover actions on the row's right edge: pin and delete.
	-- rows are pooled across conversations, so the handlers resolve the
	-- row's current conversation (row.c) instead of closing over one.
	if row.pinBtn then return end
	local del = W.Close(row, function()
		local c = row.c
		if c then Core.DeleteConvo(c.key) end
	end)
	del:SetSize(16, 16)
	del:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, -4)
	del:SetAlpha(0)
	del.label:SetText("x")
	row.del = del

	local pin = CreateFrame("Button", nil, row, "BackdropTemplate")
	pin:SetSize(16, 16)
	pin:SetPoint("RIGHT", del, "LEFT", -4, 0)
	S.Template(pin, "raised")
	pin.label = S.Font(pin, 10, C.textDim)
	pin.label:SetPoint("CENTER", 0, 0)
	pin.label:SetText("P")
	pin:SetAlpha(0)
	pin:SetScript("OnClick", function()
		local c = row.c
		if not c then return end
		c.pinned = not c.pinned or nil
		if not c.bn then saved()[c.key] = c end
		Core.RebuildList()
	end)
	row.pinBtn = pin

	row:SetScript("OnEnter", function()
		S.SetBorderLit(row, true)
		del:SetAlpha(1) pin:SetAlpha(1)
	end)
	row:SetScript("OnLeave", function()
		if picked ~= (row.c and row.c.key) then S.SetBorderLit(row, false) end
		del:SetAlpha(0) pin:SetAlpha(0)
	end)
end

function Core.RebuildList()
	if not (hub and listSF) then return end
	local q = lower(strtrim(search and search:GetText() or ""))
	local child = listSF:GetScrollChild()
	local y = -2
	local i = 0
	local list = Core.List()
	for _, c in ipairs(list) do
		if matches(c, q) then
			i = i + 1
			local row = rows[i]
			if not row then
				row = CreateFrame("Button", nil, child, "BackdropTemplate")
				row:SetHeight(ROW_H)
				S.Template(row, "inset")
				row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				row.name = S.Font(row, 12)
				row.name:SetPoint("TOPLEFT", 8, -7)
				row.time = S.Font(row, 9, C.textDim)
				row.time:SetPoint("TOPRIGHT", -8, -8)
				row.prev = S.Font(row, 10, C.textDim)
				row.prev:SetPoint("TOPLEFT", 8, -24)
				row.prev:SetPoint("TOPRIGHT", -30, -8)
				row.prev:SetJustifyH("LEFT")
				row.prev:SetWordWrap(false)
				row.badge = S.Font(row, 10, C.accent)
				row.badge:SetPoint("BOTTOMRIGHT", -8, 6)
				row.pin = S.Font(row, 11, C.accent)
				row.pin:SetPoint("BOTTOMLEFT", 6, 5)
				rows[i] = row
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 2, y)
			row:SetPoint("TOPRIGHT", -6, y)
			y = y - (ROW_H + 4)
			local rr, gg, bb = RowClassColor(c)
			local e = FBLEntry(c)
			if e then
				if e.list == "good" then
					rr, gg, bb = 0.30, 0.85, 0.45
				else
					rr, gg, bb = 1.00, 0.30, 0.30
				end
			end
			row.name:SetText(displayName(c))
			row.name:SetTextColor(rr, gg, bb)
			local last = c.msgs[#c.msgs]
			row.time:SetText(last and timeAgo(last.t) or "")
			row.prev:SetText(last and stripMarkup(last.text) or "")
			row.badge:SetText((c.unread or 0) > 0 and tostring(c.unread) or "")
			row.pin:SetText(c.pinned and "*" or "")
			S.SetBorderLit(row, picked == c.key)
			row.c = c
			rowButtons(row)
			row:SetScript("OnClick", function(_, btn)
				if btn == "RightButton" then
					ConvoMenu(c, row)
				else
					Pick(c.key)
				end
			end)
			row:Show()
		end
	end
	for j = i + 1, #rows do rows[j]:Hide() end
	if i == 0 then
		-- keep a hint row alive: reuse the first pooled row
		local row = rows[1]
		if row then
			row.name:SetText("")
			row.time:SetText("")
			row.prev:SetText(#list == 0 and L["No conversations yet."] or "")
			row.badge:SetText("")
			row.pin:SetText("")
			S.SetBorderLit(row, false)
			row:SetScript("OnClick", nil)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 2, -2)
			row:SetPoint("TOPRIGHT", -6, -2)
			row:Show()
			i = 1
			y = y - 0
		end
	end
	child:SetHeight(math.max(1, -y))
	listSF:UpdateBar()
end

local function BuildHub()
	if hub then return hub end
	local f = CreateFrame("Frame", "SentiUIMessengerHub", UIParent, "BackdropTemplate")
		S.PopIn(f)
	if S.CombatDeferWindow then S:CombatDeferWindow(f) end
	f:SetSize(720, 500)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:Hide()
	S.Template(f, "panel")
	S.EscClosable(f)

	-- title bar: drags the window; its landing spot is written into the
	-- mover store so /sui unlock and login placement agree
	local title = S.Font(f, 13, C.accent)
	title:SetPoint("TOPLEFT", 14, -10)
	title:SetText(L["Messenger"])
	titleSub = S.Font(f, 10, C.textDim)
	titleSub:SetPoint("LEFT", title, "RIGHT", 8, 0)

	-- drag strip stops before the close button: on this client the strip
	-- wins hit-testing over the header corner and the X dies under it
	local drag = CreateFrame("Frame", nil, f)
	drag:SetPoint("TOPLEFT")
	drag:SetPoint("TOPRIGHT", -36, 0)
	drag:SetHeight(32)
	drag:EnableMouse(true)
	drag:RegisterForDrag("LeftButton")
	drag:SetScript("OnDragStart", function() f:StartMoving() end)
	drag:SetScript("OnDragStop", function()
		f:StopMovingOrSizing()
		-- same store as the mover: nearest-anchor format + MoversChanged
		S.Movers.Save("messenger.hub")
	end)

	W.Close(f, function() f:Hide() end):SetPoint("TOPRIGHT", -8, -7)

	local hairline = S.Line(f, C.accent)
	hairline:SetPoint("TOPLEFT", 10, -32)
	hairline:SetPoint("TOPRIGHT", -10, -32)

	-- left column: search + conversation list -------------------------------
	search = W.EditBox(f, LIST_W - 2 * EDGE, 24)
	search.placeholder:SetText(L["Search..."])
	search.holder:SetPoint("TOPLEFT", EDGE, -44)
	search.onChanged = function() Core.RebuildList() end

	local lp = CreateFrame("Frame", nil, f, "BackdropTemplate")
	lp:SetPoint("TOPLEFT", search.holder, "BOTTOMLEFT", 0, -8)
	lp:SetPoint("BOTTOMLEFT", EDGE, EDGE + 26)
	lp:SetWidth(LIST_W - 2 * EDGE)
	S.Template(lp, "inset")
	listSF = W.Scroll(lp)
	listSF:SetPoint("TOPLEFT", 4, -4)
	listSF:SetPoint("BOTTOMRIGHT", -4, 4)
	listSF:GetScrollChild():SetWidth(LIST_W - 2 * EDGE - 8)

	local clear = W.Button(f, L["Clear all"], LIST_W - 2 * EDGE, 20)
	clear:SetPoint("BOTTOMLEFT", EDGE, EDGE)
	clear:SetScript("OnClick", function()
		for key, c in pairs(convos) do
			convos[key] = nil
			if not c.bn then saved()[key] = nil end
		end
		Pick(nil)
		Core.RefreshBadge()
	end)

	-- divider ---------------------------------------------------------------
	local div = S.Line(f, C.border)
	div:SetPoint("TOPLEFT", lp, "TOPRIGHT", EDGE / 2, 0)
	div:SetPoint("BOTTOMLEFT", clear, "TOPRIGHT", EDGE / 2, -6)
	div:SetWidth(1)

	-- right column: info line + thread + input --------------------------------
	local rx = EDGE + LIST_W + 8
	hubInfo = S.Font(f, 10, C.textDim)
	hubInfo:SetPoint("TOPLEFT", rx, -46)

	local tp = CreateFrame("Frame", nil, f, "BackdropTemplate")
	tp:SetPoint("TOPLEFT", rx, -62)
	tp:SetPoint("BOTTOMRIGHT", -EDGE, EDGE + 34)
	S.Template(tp, "inset")

	smf = MakeThread(tp)
	smf:SetPoint("TOPLEFT", 8, -8)
	smf:SetPoint("BOTTOMRIGHT", -8, 8)

	input = W.EditBox(f, 1, 26)
	input.holder:SetPoint("BOTTOMLEFT", rx, EDGE)
	input.holder:SetPoint("BOTTOMRIGHT", -(EDGE + 72), EDGE)
	input:SetScript("OnEnterPressed", function(self)
		local c = picked and convos[picked]
		if c then
			sendTo(c, self:GetText())
			self:SetText("")
		end
		self:ClearFocus()
	end)

	sendBtn = W.Button(f, SEND or "Send", 64, 26)
	sendBtn:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
	sendBtn:SetScript("OnClick", function()
		local c = picked and convos[picked]
		if c then
			sendTo(c, input:GetText())
			input:SetText("")
		end
	end)

	-- saved/mover position
	S.Movers.Register(f, "messenger.hub", L["Messenger"])

	hub = f
	return f
end

function Core.Toggle()
	local f = BuildHub()
	if f:IsShown() then
		f:Hide()
	else
		f:Show()
		Core.RebuildList()
		FillThread()
		UpdateInputTarget()
		Core.RefreshBadge()
	end
end

function Core.Open(key)
	local f = BuildHub()
	f:Show()
	if key then Pick(key) else
		Core.RebuildList()
		FillThread()
		UpdateInputTarget()
	end
end

-- ---------------------------------------------------------------------------
-- whisper chips + conversation card + preview toast
-- A row of pill chips over the chat panel - one per recent conversation,
-- first name in class color, unread count, pin marker. Clicking a chip
-- opens that conversation's own window (the card). A new whisper flashes a
-- short preview above the chips.
-- ---------------------------------------------------------------------------

local TILE_H, TILE_GAP = 26, 6
local tileHolder, tilePool = nil, {}
local card, cardKey = nil, nil
local preview = nil

-- ---------------------------------------------------------------------------
-- the conversation card: one person's window
-- ---------------------------------------------------------------------------

local function hasSpot(key)
	return S.DB.Positions()[key] ~= nil
end

local function BuildCard()
	if card then return card end
	local f = CreateFrame("Frame", "SentiUIMessengerCard", UIParent, "BackdropTemplate")
		S.PopIn(f)
	if S.CombatDeferWindow then S:CombatDeferWindow(f) end
	f:SetSize(280, 360)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:Hide()
	S.Template(f, "panel")
	S.EscClosable(f)

	f.name = S.Font(f, 13)
	f.name:SetPoint("TOPLEFT", 12, -8)
	-- sub line: level, class, guild - learned lazily from GUID/name
	f.sub = S.Font(f, 9, C.textDim)
	f.sub:SetPoint("TOPLEFT", 12, -23)

	local function headBtn(label, tip, x, onClick)
		local b = CreateFrame("Button", nil, f, "BackdropTemplate")
		b:SetSize(20, 20)
		b:SetPoint("TOPRIGHT", x, -6)
		S.Template(b, "raised")
		b.label = S.Font(b, 10, C.textDim)
		b.label:SetPoint("CENTER")
		b.label:SetText(label)
		b:SetScript("OnClick", onClick)
		b:SetScript("OnEnter", function(s)
			S.SetBorderLit(s, true)
			GameTooltip:SetOwner(s, "ANCHOR_TOP")
			GameTooltip:AddLine(tip, 1, 1, 1)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function(s)
			S.SetBorderLit(s, false)
			GameTooltip:Hide()
		end)
		return b
	end

	W.Close(f, function() f:Hide() end):SetPoint("TOPRIGHT", -8, -6)
	headBtn(">", L["Open in Messenger"], -32, function()
		f:Hide()
		if cardKey then Core.Open(cardKey) end
	end)
	headBtn("C", L["Copy history"], -56, function()
		Core.CopyHistory(cardKey)
	end)
	headBtn("B", IGNORE or "Ignore", -80, function()
		local c = cardKey and convos[cardKey]
		if c and not c.bn and C_FriendList and C_FriendList.AddIgnore then
			pcall(C_FriendList.AddIgnore, c.name)
		end
	end)
	headBtn("I", INVITE or "Invite", -104, function()
		local c = cardKey and convos[cardKey]
		if c and not c.bn then
			local inv = C_PartyInfo and C_PartyInfo.InviteUnit or InviteUnit
			if inv then pcall(inv, c.name) end
		end
	end)

	local hairline = S.Line(f, C.accent)
	hairline:SetPoint("TOPLEFT", 10, -34)
	hairline:SetPoint("TOPRIGHT", -10, -34)

	-- drag strip stops before the header buttons (x > C B I): it would
	-- cover them in hit-testing
	local drag = CreateFrame("Frame", nil, f)
	drag:SetPoint("TOPLEFT")
	drag:SetPoint("TOPRIGHT", -130, 0)
	drag:SetHeight(34)
	drag:EnableMouse(true)
	drag:RegisterForDrag("LeftButton")
	drag:SetScript("OnDragStart", function() f:StartMoving() end)
	drag:SetScript("OnDragStop", function()
		f:StopMovingOrSizing()
		S.Movers.Save("messenger.card")
	end)

	local tp = CreateFrame("Frame", nil, f, "BackdropTemplate")
	tp:SetPoint("TOPLEFT", 10, -40)
	tp:SetPoint("BOTTOMRIGHT", -10, 42)
	S.Template(tp, "inset")
	f.smf = MakeThread(tp)
	f.smf:SetPoint("TOPLEFT", 8, -8)
	f.smf:SetPoint("BOTTOMRIGHT", -8, 8)

	f.input = W.EditBox(f, 1, 24)
	f.input.holder:SetPoint("BOTTOMLEFT", 10, 10)
	f.input.holder:SetPoint("BOTTOMRIGHT", -66, 10)
	f.input:SetScript("OnEnterPressed", function(self)
		local c = cardKey and convos[cardKey]
		if c then
			sendTo(c, self:GetText())
			self:SetText("")
		end
		self:ClearFocus()
	end)

	local send = W.Button(f, SEND or "Send", 48, 24)
	send:SetPoint("BOTTOMRIGHT", -10, 10)
	send:SetScript("OnClick", function()
		local c = cardKey and convos[cardKey]
		if c then
			sendTo(c, f.input:GetText())
			f.input:SetText("")
		end
	end)

	-- persisted like the other windows: own mover entry + nearest-anchor save
	S.Movers.Register(f, "messenger.card", L["Conversation"])

	card = f
	return f
end

function Core.CardShowing(key)
	return card ~= nil and card:IsShown() and cardKey == key
end

-- shared delete for the hub row, the tile's x and clear-all: drops the
-- conversation (saved and session), closes a card showing it, and
-- repaints whatever is open
function Core.DeleteConvo(key)
	local c = key and convos[key]
	if not c then return end
	convos[key] = nil
	if not c.bn then saved()[key] = nil end
	if Core.CardShowing(key) then card:Hide() end
	if picked == key then Pick(nil) end
	Core.Refresh()
end

local function FillCard()
	if not card then return end
	local c = cardKey and convos[cardKey]
	if not c then
		card:Hide()
		return
	end
	local r, g, b = RowClassColor(c)
	card.name:SetText(displayName(c))
	card.name:SetTextColor(r, g, b)
	card.sub:SetText(infoLine(c))
	card.input.placeholder:SetText(format(L["Whisper to %s"], displayName(c)))
	FillSMF(card.smf, c)
end

function Core.OpenCard(key)
	if not convos[key] then return end
	local f = BuildCard()
	if not hasSpot("messenger.card") then
		-- first open: rise just above the tile strip
		f:ClearAllPoints()
		if tileHolder then
			f:SetPoint("BOTTOMLEFT", tileHolder, "TOPLEFT", 0, 10)
		else
			f:SetPoint("CENTER")
		end
	end
	cardKey = key
	markRead(convos[key])
	FillCard()
	f:Show()
end

function Core.ToggleCard(key)
	if Core.CardShowing(key) then
		card:Hide()
	else
		Core.OpenCard(key)
	end
end

-- ---------------------------------------------------------------------------
-- copy window: the whole conversation as selectable plain text, with
-- timestamps - for copying the history out of the game
-- ---------------------------------------------------------------------------

local copyWin

local function BuildCopy()
	if copyWin then return copyWin end
	local f = CreateFrame("Frame", "SentiUIMessengerCopy", UIParent, "BackdropTemplate")
		S.PopIn(f)
	if S.CombatDeferWindow then S:CombatDeferWindow(f) end
	f:SetSize(480, 360)
	f:SetPoint("CENTER", 0, 60)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:Hide()
	S.Template(f, "panel")
	S.EscClosable(f)

	local title = S.Font(f, 12, C.accent)
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetText(L["Chat history"])
	f.title = title
	W.Close(f, function() f:Hide() end):SetPoint("TOPRIGHT", -8, -8)
	local hairline = S.Line(f, C.accent)
	hairline:SetPoint("TOPLEFT", 10, -30)
	hairline:SetPoint("TOPRIGHT", -10, -30)

	local tp = CreateFrame("Frame", nil, f, "BackdropTemplate")
	tp:SetPoint("TOPLEFT", 10, -36)
	tp:SetPoint("BOTTOMRIGHT", -10, 12)
	S.Template(tp, "inset")
	local sf = W.Scroll(tp)
	sf:SetPoint("TOPLEFT", 4, -4)
	sf:SetPoint("BOTTOMRIGHT", -4, 4)
	local child = sf:GetScrollChild()
	child:SetWidth(440)
	local eb = CreateFrame("EditBox", nil, child)
	eb:SetPoint("TOPLEFT")
	eb:SetWidth(440)
	eb:SetMultiLine(true)
	eb:SetAutoFocus(false)
	eb:SetFont(S.media.font, 10, "")
	eb:SetTextColor(C.text.r, C.text.g, C.text.b)
	-- no OnEscapePressed: it runs inside the Escape dispatch and
	-- taints the engine's protected spell-stop calls. The window is
	-- in UISpecialFrames, so Escape closes it natively.
	f.eb = eb
	f.sf = sf
	copyWin = f
	return f
end

function Core.CopyHistory(key)
	local c = key and convos[key]
	if not c or #c.msgs == 0 then return end
	local f = BuildCopy()
	f.title:SetText(L["Chat history"] .. " - " .. displayName(c))
	local lines = {}
	for _, m in ipairs(c.msgs) do
		local who = m.me and L["You"] or displayName(c)
		lines[#lines + 1] = format("%s  %s: %s",
			date("%d.%m %H:%M", m.t), who, stripMarkup(m.text))
	end
	local text = table.concat(lines, "\n")
	f.eb:SetText(text)
	-- rough content height so the scroll range is right
	local est = math.max(200, #lines * 13 + 10)
	f.eb:SetHeight(est)
	f.sf:GetScrollChild():SetHeight(est)
	f.sf:Scroll(0)
	f:Show()
	f.eb:SetFocus()
	f.eb:HighlightText()
end

-- ---------------------------------------------------------------------------
-- the tile strip
-- ---------------------------------------------------------------------------

local function tileAt(i)
	local t = tilePool[i]
	if t then return t end
	t = CreateFrame("Button", nil, tileHolder, "BackdropTemplate")
	t:SetHeight(TILE_H)
	-- pill ends: the PillEdge backdrop rounds to a capsule at this
	-- height; a missing media file degrades to a flat chip, never square-ish
	S.Template(t, "inset")
	-- one line carries pin marker + first name; no RIGHT anchor so
	-- GetStringWidth() measures the real text width for the chip size
	t.label = S.Font(t, 11)
	t.label:SetPoint("LEFT", 10, 0)
	t.label:SetJustifyH("LEFT")
	t.badge = S.Font(t, 10, C.accent)
	t.badge:SetPoint("RIGHT", -10, 0)
	-- close on the chip's right edge INSIDE the frame: hover fades it in
	-- and swaps it for the unread count, so it keeps a hit box big
	-- enough to press and never floats outside the parent
	local x = CreateFrame("Button", nil, t)
	x:SetSize(18, 18)
	x:SetPoint("RIGHT", t, "RIGHT", -2, 0)
	x:SetFrameLevel(t:GetFrameLevel() + 3)
	x.txt = S.Font(x, 12, C.textDim)
	x.txt:SetPoint("CENTER", 0, 1)
	x.txt:SetText("x")
	x:SetAlpha(0)
	x:SetScript("OnClick", function(self)
		local c = self:GetParent().c
		if c then Core.DeleteConvo(c.key) end
	end)
	x:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
		self.txt:SetTextColor(C.accent.r, C.accent.g, C.accent.b)
	end)
	x:SetScript("OnLeave", function(self)
		self.txt:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b)
		local p = self:GetParent()
		if not (p and p:IsMouseOver()) then
			self:SetAlpha(0)
			p.badge:SetShown(p.badgeText ~= "")
		end
	end)
	t.x = x
	t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	t:SetScript("OnEnter", function(self)
		S.SetBorderLit(self, true)
		self.x:SetAlpha(1)
		self.badge:Hide()   -- the x takes the count's spot on hover
		local c = self.c
		if c then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			local r, g, b = RowClassColor(c)
			GameTooltip:AddLine(displayName(c), r, g, b)
			local last = c.msgs[#c.msgs]
			if last then GameTooltip:AddLine(stripMarkup(last.text), 0.7, 0.7, 0.7) end
			GameTooltip:Show()
		end
	end)
	t:SetScript("OnLeave", function(self)
		if not Core.CardShowing(self.c and self.c.key) then S.SetBorderLit(self, false) end
		if not self.x:IsMouseOver() then
			self.x:SetAlpha(0)
			self.badge:SetShown(self.badgeText ~= "")
		end
		GameTooltip:Hide()
	end)
	t:SetScript("OnClick", function(self, btn)
		if not self.c then return end
		if btn == "RightButton" then
			Core.Open(self.c.key)
		else
			Core.ToggleCard(self.c.key)
		end
	end)
	tilePool[i] = t
	return t
end

-- the chip label: pin marker + first name - a whisper partner is
-- recognized faster by name than by an initial glyph
local function chipName(c)
	local nm = displayName(c) or "?"
	return nm:match("^(%S+)") or nm
end

function Core.RebuildTiles()
	if not tileHolder then return end
	local max = math.max(2, db.tileMax or 6)
	local list = Core.List()
	local n = math.min(#list, max)
	local x = 0
	for i = 1, n do
		local c = list[i]
		local t = tileAt(i)
		t.c = c
		local r, g, b = RowClassColor(c)
		t.label:SetText((c.pinned and "|cff" .. S.Hex(C.accent) .. "*|r " or "")
			.. chipName(c))
		t.label:SetTextColor(r, g, b)
		local badge = (c.unread or 0) > 0 and tostring(c.unread) or ""
		t.badgeText = badge
		t.badge:SetText(badge)
		t.badge:SetShown(badge ~= "" and not t:IsMouseOver())
		local tw = math.ceil(10 + (t.label:GetStringWidth() or 40)
			+ (badge ~= "" and (t.badge:GetStringWidth() or 8) + 22 or 24))
		t:SetWidth(tw)
		t:ClearAllPoints()
		t:SetPoint("LEFT", tileHolder, "LEFT", x, 0)
		x = x + tw + TILE_GAP
		S.SetBorderLit(t, Core.CardShowing(c.key))
		t:Show()
	end
	for i = n + 1, #tilePool do tilePool[i]:Hide() end
	tileHolder:SetWidth(math.max(x, 1))
	tileHolder:SetHeight(TILE_H)
	tileHolder:SetShown(db.tiles)
end

local function BuildTiles()
	if tileHolder then return end
	tileHolder = CreateFrame("Frame", "SentiUIMessengerTiles", UIParent)
	tileHolder:SetSize(400, TILE_H)
	-- dock above whichever left-side strip is highest: the chat tab row,
	-- the XP bar, or a rep bar stacked above it - the panel's top edge
	-- alone can sit under a data bar
	local anchor, top = nil, -math.huge
	local okX, midX = pcall(UIParent.GetWidth, UIParent)
	midX = (okX and type(midX) == "number") and midX * 0.5 or math.huge
	for _, name in ipairs({ "GeneralDockManager", "SentiUIxpBar", "SentiUIrepBar" }) do
		local f = _G[name]
		if f and f.IsShown and f:IsShown() then
			local ok, left, tp = pcall(function() return f:GetLeft(), f:GetTop() end)
			if ok and type(left) == "number" and type(tp) == "number"
				and left < midX and tp > top then
				anchor, top = f, tp
			end
		end
	end
	if anchor then
		tileHolder:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 2, 4)
	else
		local chatPanel = _G.SentiUILeftChatPanel
		if chatPanel then
			tileHolder:SetPoint("BOTTOMLEFT", chatPanel, "TOPLEFT", 6, 30)
		else
			tileHolder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 60, 300)
		end
	end
	tileHolder:SetFrameStrata("MEDIUM")
	S.Movers.Register(tileHolder, "messenger.tiles", L["Whisper tiles"])
end

-- ---------------------------------------------------------------------------
-- the preview toast above the tiles
-- ---------------------------------------------------------------------------

function Core.Preview(c, text)
	if not db.preview or not tileHolder or not db.tiles then return end
	if Core.CardShowing(c.key) or Core.Showing(c.key) then return end
	if not preview then
		preview = CreateFrame("Button", "SentiUIMessengerPreview", tileHolder, "BackdropTemplate")
		preview:SetSize(280, 42)
		preview:SetPoint("BOTTOMLEFT", tileHolder, "TOPLEFT", 0, 8)
		preview:SetFrameStrata("DIALOG")
		S.Template(preview, "raised")
		preview.name = S.Font(preview, 11, C.accent)
		preview.name:SetPoint("TOPLEFT", 8, -5)
		preview.text = S.Font(preview, 10, C.text)
		preview.text:SetPoint("TOPLEFT", 8, -21)
		preview.text:SetPoint("TOPRIGHT", -8, -21)
		preview.text:SetJustifyH("LEFT")
		preview.text:SetWordWrap(false)
		preview:SetScript("OnClick", function()
			preview:Hide()
			if preview.c then Core.ToggleCard(preview.c.key) end
		end)
		preview:Hide()
	end
	preview.c = c
	local r, g, b = RowClassColor(c)
	preview.name:SetText(displayName(c))
	preview.name:SetTextColor(r, g, b)
	preview.text:SetText(stripMarkup(text or ""))
	preview:SetAlpha(1)
	preview:Show()
	preview.until_ = GetTime() + (db.previewSec or 6)
	if not preview.ticker then
		local acc = 0
		preview:SetScript("OnUpdate", function(self, e)
			acc = acc + e
			if acc < 0.1 then return end
			acc = 0
			local left = (self.until_ or 0) - GetTime()
			if left <= 0 then
				self:Hide()
			elseif left < 1 then
				self:SetAlpha(left)
			end
		end)
		preview.ticker = true
	end
end

-- ---------------------------------------------------------------------------
-- badge + refresh
-- ---------------------------------------------------------------------------

local badge

local function ensureBadge()
	if badge or not db.minimapBadge then return badge end
	local mb = _G.SentiUIMinimapButton
	if not mb then return nil end
	badge = mb:CreateFontString(nil, "OVERLAY")
	badge:SetFont(S.media.font, 9, "OUTLINE")
	badge:SetPoint("TOPRIGHT", mb, "TOPRIGHT", 1, 4)
	badge:SetTextColor(C.accent.r, C.accent.g, C.accent.b)
	return badge
end

function Core.RefreshBadge()
	local b = ensureBadge()
	if not b then return end
	local n = Core.Unread()
	b:SetText(n > 0 and (n > MAX_UNREAD_BADGE and "99+" or tostring(n)) or "")
end

function Core.Refresh()
	Core.RefreshBadge()
	Core.RebuildTiles()
	if titleSub then
		local n = Core.Unread()
		titleSub:SetText(n > 0 and format(L["Messenger: %d unread"], n) or "")
	end
	if hub and hub:IsShown() then
		Core.RebuildList()
		-- live-append to the open thread instead of a full repaint
		local c = picked and convos[picked]
		if c then
			markRead(c)
			FillThread()
		end
	end
	if card and card:IsShown() then FillCard() end
end

-- ---------------------------------------------------------------------------
-- enable / settings
-- ---------------------------------------------------------------------------

function Core.DB() return db end

function Core.SettingChanged(mod, path)
	if not Core.enabled then return end
	db = mod.db
	if path == "historySize" and smf then
		for _, c in pairs(convos) do
			while #c.msgs > db.historySize do tremove(c.msgs, 1) end
		end
	end
	if path == "minimapBadge" and badge then badge:SetText("") end
	if path == "tiles" or path == "tileMax" then Core.RebuildTiles() end
	Core.RefreshBadge()
end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db

	loadSaved()

	BuildTiles()
	Core.RebuildTiles()

	for _, ev in ipairs({ "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
		"CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM" }) do
		S.RegisterEvent(ev, onWhisper)
	end

	-- the minimap button can register after us; retry attaching the badge
	local tries = 0
	local function tryBadge()
		tries = tries + 1
		if ensureBadge() or tries > 10 then return end
		C_Timer.After(1, tryBadge)
	end
	C_Timer.After(1, tryBadge)

	-- the "r" reply binding calls ChatFrame_ReplyTell: point it at the
	-- whisper card instead of the plain chat edit box
	if db.keyR and type(ChatFrame_ReplyTell) == "function" then
		origReplyTell = ChatFrame_ReplyTell
		ChatFrame_ReplyTell = function()
			if lastFrom and convos[lastFrom] then
				Core.OpenCard(lastFrom)
			elseif origReplyTell then
				origReplyTell()
			end
		end
	end

	SlashCmdList.SENTIMSG = function(msg)
		msg = strtrim(msg or "")
		if msg ~= "" then
			local c = Get(msg, false)
			if not c then
				-- case-insensitive lookup before opening a blank chat
				local lq = lower(msg)
				for _, x in pairs(convos) do
					if not x.bn and lower(x.name) == lq then c = x break end
				end
			end
			c = c or ensure(msg, false)
			Core.Open(c.key)
		else
			Core.Toggle()
		end
	end
	SLASH_SENTIMSG1 = "/smsg"
	SLASH_SENTIMSG2 = "/sm"

	Core.RefreshBadge()
end
