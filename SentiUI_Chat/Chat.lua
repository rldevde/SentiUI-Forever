-- SentiUI chat: Sentinel-styled panels behind the dock, restyled tabs and
-- edit box, a message filter (short channels, clickable links, keywords,
-- timestamps), spam throttle, class-colored names and player levels.
local _, ns = ...
local S = SentiUI
local L = ns.L
local IsSecret = S.IsSecret

local _G = _G
local ipairs, pairs, pcall, type = ipairs, pairs, pcall, type
local format, gsub, date = string.format, string.gsub, date
local strtrim = strtrim or function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end
local tinsert, tremove = table.insert, table.remove

local BLANK = "Interface\\Buttons\\WHITE8X8"
local ACCENT = S.colors.accent

-- the reliable chat font path on this client is the game's own wrapper
-- FCF_SetChatWindowFontSize(nil, frame, size) - a direct frame:SetFont
-- silently does nothing here, and even the Font object path does not
-- reach a ScrollingMessageFrame. Font file/outline go through
-- S.ApplyFont as a best effort when they differ.
local function ApplyChatFont(frame, size, flags)
	if frame.suiFontPushed == size and (frame.suiFontFlags or "") == (flags or "") then
		return
	end
	frame.suiFontPushed = size
	frame.suiFontFlags = flags
	local okF, _, _, curFlags = pcall(frame.GetFont, frame)
	if FCF_SetChatWindowFontSize then
		pcall(FCF_SetChatWindowFontSize, nil, frame, size)
	end
	if (curFlags or "") ~= (flags or "") then
		S.ApplyFont(frame, S.media.font, size, flags)
	end
end

local Core = {}
ns.Core = Core
local db
Core.styled = {}

local shortChannels = {
	GUILD = "G", OFFICER = "O", PARTY = "P", PARTY_LEADER = "PL",
	RAID = "R", RAID_LEADER = "RL", RAID_WARNING = "RW",
	INSTANCE_CHAT = "I", INSTANCE_CHAT_LEADER = "IL",
	BATTLEGROUND = "BG", BATTLEGROUND_LEADER = "BGL",
}

-- channel-notice lines ("Changed Channel: [1. General]") keep the full name
local noticePatterns = {}
do
	for _, g in ipairs({
		"CHAT_CHANNEL_JOIN_GET", "CHAT_CHANNEL_LEAVE_GET", "CHAT_CHANNEL_LIST_GET", "CHAT_CHANNEL_OWNER_NOTICE",
		"CHAT_YOU_JOINED_NOTICE", "CHAT_YOU_LEFT_NOTICE", "CHAT_SUSPENDED_NOTICE", "CHAT_NOT_MEMBER_NOTICE",
		"CHAT_YOU_CHANGED_NOTICE", "CHAT_INVALID_NAME_NOTICE", "CHAT_PLAYER_NOT_MEMBER_NOTICE",
		"CHAT_CHANNEL_PASSWORD_NOTICE", "CHAT_MODERATION_ON_NOTICE", "CHAT_MODERATION_OFF_NOTICE",
		"CHAT_PLAYER_KICKED_NOTICE", "CHAT_PLAYER_BANNED_NOTICE", "CHAT_PLAYER_UNBANNED_NOTICE",
		"CHAT_PLAYER_ALREADY_MEMBER_NOTICE", "CHAT_NOT_MODERATOR_NOTICE", "CHAT_WRONG_PASSWORD_NOTICE",
	}) do
		local f = _G[g]
		if type(f) == "string" and f ~= "" then
			local pat = f:gsub("%%[sd]", "\1")
			pat = (pat:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")):gsub("\1", ".*")
			if #pat > 3 then noticePatterns[#noticePatterns + 1] = pat end
		end
	end
end

-- panels -----------------------------------------------------------------------
local function SetFade(tex, r, g, b, a1, a2)
	if tex.SetGradient and CreateColor then
		tex:SetGradient("VERTICAL", CreateColor(r, g, b, a1), CreateColor(r, g, b, a2))
	else
		tex:SetColorTexture(r, g, b, (a1 + a2) * 0.5)
	end
end

local function MakePanel(name, label, key, default)
	local p = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	p:SetSize(db.panelWidth, db.panelHeight)
	p:SetFrameStrata("BACKGROUND")
	p:SetFrameLevel(1)
	p:SetPoint(default[1], UIParent, default[3], default[4], default[5])
	-- SentiUI look: the bordered dark panel every module window uses,
	-- with the fade option falling back to the plain Sentinel shade
	S.Template(p, "panel")
	local fade = p:CreateTexture(nil, "BACKGROUND", nil, 2)
	-- inset past the corner arc: a full-frame fade would show a dark
	-- square wedge behind each rounded corner of the panel body
	fade:SetPoint("TOPLEFT", 7, -7)
	fade:SetPoint("BOTTOMRIGHT", -7, 7)
	fade:SetColorTexture(0, 0, 0, 1)
	p.fade = fade
	-- accent hairline under the tab row
	local line = S.Line(p, ACCENT)
	line:SetPoint("TOPLEFT", 4, -26)
	line:SetPoint("TOPRIGHT", -4, -26)
	p.line = line
	-- Sentinel signature: small accent ticks at the bottom corners.
	-- inset past the corner arc and mirrored per side — the right tick
	-- used to hang 4px outside the panel edge (same sign for both sides)
	p.ticks = {}
	for _, side in ipairs({ "BOTTOMLEFT", "BOTTOMRIGHT" }) do
		local t = p:CreateTexture(nil, "ARTWORK")
		t:SetTexture(BLANK)
		t:SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
		t:SetSize(6, 2)
		t:SetPoint(side, side == "BOTTOMLEFT" and 8 or -8, 2)
		p.ticks[#p.ticks + 1] = t
	end
	S.Movers.Register(p, key, label)
	return p
end

function Core.CreatePanels()
	Core.leftPanel = MakePanel("SentiUILeftChatPanel", L["Left Chat"], "chatleft",
		{ "BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 6, 32 })
	Core.rightPanel = MakePanel("SentiUIRightChatPanel", L["Right Chat"], "chatright",
		{ "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -6, 32 })
	Core.UpdatePanels()
end

function Core.UpdatePanels()
	local bg = S.colors.bg
	local a1 = db.panelTransparency and 0.82 or 0.95
	local a2 = db.panelTransparency and 0.0 or 0.35
	for _, p in ipairs({ Core.leftPanel, Core.rightPanel }) do
		p:SetSize(db.panelWidth, db.panelHeight)
		if db.panelTransparency then
			-- transparent mode: no boxed panel, just the shade
			p:SetBackdropColor(0, 0, 0, 0)
			p:SetBackdropBorderColor(0, 0, 0, 0)
			p.fade:SetAlpha(1)
			SetFade(p.fade, bg.r, bg.g, bg.b, a1, a2)
		else
			S.Template(p, "panel")
			p.fade:SetAlpha(0)
		end
	end
	local mode = db.panelBackdrop
	Core.leftPanel:SetAlpha((mode == "SHOWBOTH" or mode == "LEFT") and 1 or 0)
	Core.rightPanel:SetShown(db.rightPanelEnable)
	Core.rightPanel:SetAlpha((mode == "SHOWBOTH" or mode == "RIGHT") and 1 or 0)
end

-- message filter ----------------------------------------------------------------
local urlPatterns = {
	"(%a+://[%w_%-%.%%%?/&=#:~+@!]+)",
	"(www%.[%w_%-%.]+%.%a%a+[%w_%-%.%%%?/&=#:~+@!]*)",
	"([%w_%-%.]+@[%w_%-]+%.%a%a+)",
	"(%d+%.%d+%.%d+%.%d+:?%d*/?[%w_%-%.%%%?/&=#:~+@!]*)",
}
-- bare domains linkify only on a known TLD - "ach.so" is just text
local knownTLDs = { com = 1, net = 1, org = 1, de = 1, io = 1, gg = 1, tv = 1, me = 1,
	info = 1, eu = 1, at = 1, ch = 1, fr = 1, uk = 1, co = 1, dev = 1, app = 1, xyz = 1 }
local bareDomainPat = "([%w_%-%.]+%.(%a%a%a?%a?)[%w_%-%.%%%?/&=#:~+@!/]*)"

local function LinkURL(url)
	return format("|cff%s|Hurl:%s|h[%s]|h|r", S.Hex(ACCENT), url, url)
end

local function LinkBare(url, tld)
	return knownTLDs[(tld or ""):lower()] and LinkURL(url) or url
end

-- emoticons rendered as inline textures: the classic typed smileys and
-- Discord-style :name: codes both resolve into the same 60-icon set
local EMOTE_DIR = "Interface\\AddOns\\SentiUI_Chat\\Media\\Emotes\\"
local EMOTE_ORDER = {
	"smile", "wink", "grin", "joy", "laugh", "rofl", "sweatsmile", "zany",
	"heart", "hearteyes", "blowkiss", "hug", "cool", "smirk", "angel", "party",
	"sad", "crying", "sob", "brokenheart", "angry", "rage", "scream", "devil",
	"surprised", "mindblown", "confused", "thinking", "eyeroll", "grimace", "nerd", "monocle",
	"thumbsup", "thumbsdown", "ok", "yes", "no", "clap", "wave", "handshake",
	"fire", "sparkles", "star", "rainbow", "muscle", "hundred", "trophy", "tada",
	"skull", "ghost", "troll", "sheep", "unicorn", "shrug", "secret", "pleading",
	"sleep", "sleepy", "tongue", "facepalm",
}
local EMOTES = {}
for _, n in ipairs(EMOTE_ORDER) do EMOTES[n] = true end

-- typed smiley codes map onto palette icons so everything shares one style
local SMILE_ORDER = { ":-)", ";-)", ":-D", ":-(", ":-P", ":-p", ";-P", ";-p",
	":')", ":'(", ">:(", ":)", ";)", ":D", ":(", ":P", ":p", ";P", ";p",
	":o", ":O", "D:", ";D", ":3", ":|", ":/", ":*", "xD", "XD", "<3", "o.O", "O.o", "^^" }
local SMILE_MAP = {
	[":)"] = "smile", [":-)"] = "smile", [";)"] = "wink", [";-)"] = "wink",
	[":D"] = "grin", [";D"] = "grin", [":-D"] = "grin", ["^^"] = "joy",
	["xD"] = "joy", ["XD"] = "joy",
	[":("] = "sad", [":-("] = "sad", ["D:"] = "grimace",
	[":'("] = "crying", [":')"] = "sweatsmile", [">:("] = "angry",
	[":P"] = "tongue", [":-P"] = "tongue", [":p"] = "tongue", [":-p"] = "tongue",
	[";P"] = "tongue", [";-P"] = "tongue", [";p"] = "tongue", [";-p"] = "tongue",
	["<3"] = "heart", [":3"] = "hearteyes", [":*"] = "blowkiss",
	["o.O"] = "surprised", ["O.o"] = "surprised", [":o"] = "surprised", [":O"] = "surprised",
	[":|"] = "thinking", [":/"] = "confused",
}
local function Smileys(text)
	for _, pat in ipairs(SMILE_ORDER) do
		local icon = "|T" .. EMOTE_DIR .. SMILE_MAP[pat] .. ".tga:14:14|t"
		local esc = pat:gsub("%W", "%%%0")
		-- boundaries: word-starting smileys (xD, o.O) need a hard word edge
		-- or "xDenis" tears; punct-starting ones only must not touch a
		-- digit/colon so ":3" inside "04:39" and ":o" in "12:oo" stay put,
		-- while a smiley glued to a word ("moment;)") still converts
		local lead = pat:match("^%w") and "([^%w:])" or "([^%d:])"
		for _ = 1, 2 do
			text = text:gsub(lead .. esc .. "([^%w:])",
				function(a, b) return a .. icon .. b end)
		end
		text = text:gsub(lead .. esc .. "$", function(a) return a .. icon end)
		text = text:gsub("^" .. esc .. "([^%w:])", function(b) return icon .. b end)
		text = text:gsub("^" .. esc .. "$", icon)
	end
	-- :name: codes - returning nil keeps unknown codes as plain text
	return (text:gsub(":([%w_]+):", function(n)
		n = n:lower()
		if EMOTES[n] then return "|T" .. EMOTE_DIR .. n .. ".tga:14:14|t" end
	end))
end

function Core.FilterMessage(text)
	local isNotice = false
	for _, p in ipairs(noticePatterns) do
		if text:find(p) then isNotice = true break end
	end
	if db.shortChannels and not isNotice then
		-- returning nil keeps the original text - never empty brackets
		text = gsub(text, "|Hchannel:(.-)|h%[(.-)%]|h", function(chan, label)
			local ab = shortChannels[chan]
			if not ab then ab = chan:match("channel:(%d+)") or chan:match("CHANNEL:(%d+)") or chan:match("^(%d+)$") end
			if not ab then ab = label and label:match("^(%d+)%.") end
			if ab then return format("|Hchannel:%s|h[%s]|h", chan, ab) end
		end)
	end
	-- hyperlinks mask once for the url and smiley passes: an emoticon
	-- inside a link corrupts it. Pass 1 catches full |H..|h label |h
	-- links; pass 2 catches any leftover |H..|h payload whose label side
	-- this client formats differently (|Hplayer:..:1|[Name]) - before, a
	-- ":P" inside "player:Prinz Nexo" turned into an icon and tore the
	-- whole link apart.
	local masks, mask
	if db.url or db.smilies then
		masks = {}
		mask = function(l) masks[#masks + 1] = l return "\1" .. #masks .. "\2" end
		text = gsub(text, "(|H.-|h[^|]-|h)", mask)
		text = gsub(text, "(|H.-|h)", mask)
	end
	if db.url then
		for _, pattern in ipairs(urlPatterns) do
			local replaced
			text, replaced = gsub(text, "^" .. pattern, LinkURL)
			if replaced == 0 then
				text = gsub(text, "([%s\1\2])" .. pattern, function(space, url) return space .. LinkURL(url) end)
			end
		end
		text = gsub(text, "^" .. bareDomainPat, LinkBare)
		text = gsub(text, "([%s\1\2])" .. bareDomainPat, function(sp, url, tld)
			local l = LinkBare(url, tld)
			return l == url and (sp .. url) or (sp .. l)
		end)
	end
	if db.smilies and mask then
		-- the url pass just created fresh |Hurl links - mask them too or a
		-- smiley code inside the url label tears the link markup apart
		text = gsub(text, "(|H.-|h[^|]-|h)", mask)
	end
	if db.smilies then text = Smileys(text) end
	-- plain-text quest references "[19] Name (questID)" get wrapped into real
	-- |Hquest hyperlinks - runs after the link mask so existing links and our
	-- own markup stay untouched
	if db.questLinks then
		text = gsub(text, "%[(%d+)%]%s*([^%[%]]-)%s*%((%d+)%)", function(level, name, id)
			name = strtrim(name)
			if name == "" or #name > 80 then return end
			return format("|Hquest:%s:%s|h[%s] %s (%s)|h", id, level, level, name, id)
		end)
	end
	if masks then
		for i, l in ipairs(masks) do
			text = gsub(text, "\1" .. i .. "\2", function() return l end, 1)
		end
	end
	if Core.keywords and #Core.keywords > 0 then
		local lower = text:lower()
		for _, word in ipairs(Core.keywords) do
			local s = lower:find(word:lower(), 1, true)
			if s and not text:sub(1, s):find("|H[^|]*$") then
				local c = db.keywordColor
				text = text:sub(1, s - 1) .. "|cff" .. S.Hex(c) .. text:sub(s, s + #word - 1) .. "|r" .. text:sub(s + #word)
				if db.keywordAlert and (not Core.lastKeywordSound or GetTime() - Core.lastKeywordSound > 5) then
					Core.lastKeywordSound = GetTime()
					PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master")
				end
			end
		end
	end
	if db.timestamp ~= "NONE" then
		local c = db.timestampColor
		text = "|cff" .. S.Hex(c) .. "[" .. date(db.timestamp) .. "]|r " .. text
	end
	return text
end

local hoverLinks = { item = true, spell = true, enchant = true, quest = true, achievement = true, talent = true, currency = true }

local function AddMessageHook(frame, text, ...)
	if type(text) == "string" and not IsSecret(text) then
		local ok, res = pcall(Core.FilterMessage, text)
		if ok then text = res end
		if frame == ChatFrame1 and not Core.replaying then Core.RecordHistory(text, ...) end
	end
	return frame.suiAddMessage(frame, text, ...)
end

-- chat history: last N lines of the main frame survive a reload
function Core.RecordHistory(text, r, g, b)
	if not db.history or (db.historySize or 0) <= 0 then return end
	SentiUIDB.chatHistory = SentiUIDB.chatHistory or {}
	local h = SentiUIDB.chatHistory
	h[#h + 1] = { text, r, g, b }
	while #h > db.historySize do tremove(h, 1) end
end

function Core.ReplayHistory()
	local h = SentiUIDB.chatHistory
	if not db.history or type(h) ~= "table" or #h == 0 or not ChatFrame1.suiAddMessage then return end
	Core.replaying = true
	for _, line in ipairs(h) do
		pcall(ChatFrame1.suiAddMessage, ChatFrame1, line[1], line[2] or 0.6, line[3] or 0.6, line[4] or 0.6)
	end
	ChatFrame1.suiAddMessage(ChatFrame1, "|cff808080--- " .. L["Chat history"] .. " ---|r")
	Core.replaying = nil
end

-- spam throttle: identical message from the same sender within N seconds
local throttleCache = {}
local function ThrottleFilter(_, _, msg, author)
	local t = db and db.throttle or 0
	if t <= 0 or type(msg) ~= "string" or IsSecret(msg) or IsSecret(author) then return false end
	local key = (author or "") .. "#" .. msg
	local now = GetTime()
	local last = throttleCache[key]
	throttleCache[key] = now
	local myName = UnitName("player")
	if last and now - last < t and author ~= myName and not (author or ""):find("^" .. (myName or "") .. "%-") then return true end
	return false
end

-- URL copy popup - own dialog, not StaticPopupDialogs: the client tracks
-- who wrote each table value and the game's Escape path reads that table,
-- so addon entries taint the dispatch and kill the protected spell-stop
-- call behind it (ADDON_ACTION_FORBIDDEN)
local function ShowUrlPopup(url)
	S.Dialog({
		text = "URL",
		editText = url or "",
		readOnly = true,
		okText = CLOSE or "Close",
		hideCancel = true,
		onAccept = function() end,
	})
end

function Core.HookItemRef()
	local original = SetItemRef
	SetItemRef = function(link, text, button, chatFrame)
		if type(link) == "string" and link:sub(1, 4) == "url:" then
			ShowUrlPopup(link:sub(5))
			return
		end
		return original(link, text, button, chatFrame)
	end
end

-- copy chat ----------------------------------------------------------------------
function Core.CopyChat(frame)
	if not Core.copyFrame then
		local f = CreateFrame("Frame", "SentiUIChatCopy", UIParent, "BackdropTemplate")
		if S.CombatDeferWindow then S:CombatDeferWindow(f) end
		f:SetSize(640, 340)
		f:SetPoint("CENTER")
		f:SetFrameStrata("DIALOG")
		f:SetToplevel(true)
		f:EnableMouse(true)
		f:SetMovable(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			S.Movers.Save("chat.copy")
		end)
		S.Template(f, "panel")
		S.EscClosable(f)
		S.Movers.Register(f, "chat.copy", L["Copy Chat"])
		local title = S.Font(f, 13, ACCENT, "OUTLINE")
		title:SetPoint("TOPLEFT", 10, -8)
		title:SetText(L["Copy Chat"])
			local scroll = CreateFrame("ScrollFrame", "SentiUIChatCopyScroll", f, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", 8, -28)
		scroll:SetPoint("BOTTOMRIGHT", -28, 8)
		local line = S.Line(f, ACCENT)
		line:SetPoint("TOPLEFT", 10, -22)
		line:SetPoint("TOPRIGHT", -10, -22)
		local eb = CreateFrame("EditBox", nil, scroll)
		eb:SetMultiLine(true)
		eb:SetAutoFocus(false)
		eb:SetFontObject(ChatFontNormal or GameFontHighlight)
		eb:SetWidth(600)
		-- no OnEscapePressed (Escape dispatch taint); the window is in
		-- UISpecialFrames so Escape closes it natively
		scroll:SetScrollChild(eb)
		f.edit = eb
		local close = S.Widgets.Close(f, function() f:Hide() end)
		close:SetPoint("TOPRIGHT", -6, -6)
		Core.copyFrame = f
	end
	local lines = {}
	for i = 1, frame:GetNumMessages() do
		local msg = frame:GetMessageInfo(i)
		if msg and not IsSecret(msg) then
			msg = msg:gsub("|T.-|t", ""):gsub("|A.-|a", "")
			lines[#lines + 1] = msg
		end
	end
	Core.copyFrame.edit:SetText(table.concat(lines, "\n"))
	Core.copyFrame:Show()
end

-- frame styling ------------------------------------------------------------------
local tabTextures = { "Left", "Middle", "Right", "SelectedLeft", "SelectedMiddle", "SelectedRight",
	"HighlightLeft", "HighlightMiddle", "HighlightRight", "ActiveLeft", "ActiveMiddle", "ActiveRight" }

local function SafeRegions(obj)
	local ok, r = pcall(function() return { obj:GetRegions() } end)
	return ok and r or {}
end

function Core.StyleTab(tab)
	local tn = tab.GetName and tab:GetName()
	for _, k in ipairs(tabTextures) do
		local t = tab[k] or (tn and _G[tn .. k])
		if t then t:SetTexture(nil) t:SetAlpha(0) end
	end
	-- dark inset background behind the tab label — same dark fill as the
	-- blade chips; keeps the tab readable against the game world
	if not tab.suiTabBG then
		local bg = tab:CreateTexture(nil, "BACKGROUND")
		local tabTex = S.Tex and S.Tex("ChatTab")
		bg:SetTexture(tabTex or BLANK)
		if tabTex then
			bg:SetVertexColor(1, 1, 1, 0.9)
			tab.suiTabBGTex = true
		else
			bg:SetVertexColor(S.colors.bgInset.r, S.colors.bgInset.g, S.colors.bgInset.b, 0.80)
		end
		bg:SetPoint("TOPLEFT",  tab, "TOPLEFT",  2,  0)
		bg:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
		tab.suiTabBG = bg
	end
	-- 2px gold accent hairline along the tab bottom edge (re-use the glow
	-- region the client provides, otherwise create our own)
	local glow = tab.glow or (tn and _G[tn .. "Glow"])
	if glow then
		glow:SetTexture(BLANK)
		glow:SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b, 0)   -- hidden by default
		glow:ClearAllPoints()
		glow:SetPoint("BOTTOMLEFT",  tab, "BOTTOMLEFT",  8, 2)
		glow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -8, 2)
		glow:SetHeight(2)
		tab.suiGlow = glow
	end
	local text = tab.Text or (tn and _G[tn .. "Text"])
	if text then
		S.ApplyFont(text, S.media.font, db.tabFontSize, "OUTLINE")
		text:SetShadowOffset(0, 0)
	end
	if tab.conversationIcon then tab.conversationIcon:SetAlpha(0) end
end

function Core.UpdateTabColors()
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		local tab = _G["ChatFrame" .. i .. "Tab"]
		local frame = _G["ChatFrame" .. i]
		local tn = tab and tab.GetName and tab:GetName()
		local text = tab and (tab.Text or (tn and _G[tn .. "Text"]))
		local active = frame == SELECTED_CHAT_FRAME
			or (SELECTED_DOCK_FRAME and frame == SELECTED_DOCK_FRAME)
		if text then
			if active then
				text:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b)
			else
				text:SetTextColor(0.9, 0.9, 0.9)
			end
		end
		-- gold hairline visible only on the active tab
		if tab and tab.suiGlow then
			tab.suiGlow:SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b, active and 0.7 or 0)
		end
		-- dim the tab bg on inactive tabs for less visual noise; with
		-- media the active state swaps to its own plate instead of a
		-- brighter tint of the same fill
		if tab and tab.suiTabBG then
			if tab.suiTabBGTex then
				local act = S.Tex and S.Tex("ChatTabActive")
				tab.suiTabBG:SetTexture(active and act
					or (S.Tex and S.Tex("ChatTab")))
				tab.suiTabBG:SetVertexColor(1, 1, 1,
					active and 1 or 0.55)
			else
				tab.suiTabBG:SetVertexColor(
					S.colors.bgInset.r, S.colors.bgInset.g, S.colors.bgInset.b,
					active and 0.90 or 0.55)
			end
		end
	end
end

local function FindEditBox(frame)
	if not frame then return nil end
	local eb = frame.editBox
	if not eb then
		local name = frame.GetName and frame:GetName()
		eb = (name and _G[name .. "EditBox"]) or _G.ChatFrameEditBox
	end
	return eb
end

-- Blizzard re-shows the header/focus chrome on every UpdateHeader pass -
-- the watchdog re-hides it each tick, this is the one-time part
local function HideEditBoxChrome(eb, name)
	for _, k in ipairs({ "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }) do
		local t = (name and _G[name .. "EditBox" .. k]) or eb[k]
		if t then t:SetAlpha(0) end
	end
end

-- input bar: appears only when the edit box is open (same rhythm as the
-- Blizzard default). Uses the identical panel template as the chat panels
-- so it looks like a continuation of them. Anchored and sized in
-- PositionEditBox; visibility driven by the per-frame watchdog.
local function EditBar()
	if not Core.editBar and Core.leftPanel then
		local bar = CreateFrame("Frame", "SentiUIChatEditBar", UIParent, "BackdropTemplate")
		bar:SetFrameStrata("DIALOG")
		bar:SetFrameLevel(5)
		S.Template(bar, "panel")
		-- slightly transparent like the chat panel behind it: the client
		-- never hides its editbox, so the bar is a permanent fixture and
		-- must blend in, not sit as an opaque slab over the world
		if bar.SetBackdropColor then
			local bg = S.colors.bg
			bar:SetBackdropColor(bg.r, bg.g, bg.b,
				db.panelTransparency and 0.55 or 0.80)
		end
		-- gold hairline at the top — same signature as the data bars
		local line = S.Line(bar, ACCENT)
		line:SetPoint("TOPLEFT",  bar, "TOPLEFT",  5, 0)
		line:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -5, 0)
		-- channel-colour indicator: 3px strip on the left, tinted per type
		local strip = bar:CreateTexture(nil, "OVERLAY")
		strip:SetTexture(BLANK)
		strip:SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
		strip:SetWidth(3)
		strip:SetPoint("TOPLEFT",    bar, "TOPLEFT",    2, -2)
		strip:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 2,  2)
		bar.channelStrip = strip
		bar:EnableMouse(true)
		bar:SetScript("OnMouseDown", function(b)
			if b.eb then pcall(b.eb.SetFocus, b.eb) end
		end)
		-- hidden by default: the watchdog shows it only while an editbox is open
		bar:Hide()
		Core.editBar = bar
	end
	return Core.editBar
end

function Core.StyleEditBox(frame)
	local name = frame.GetName and frame:GetName()
	local eb = FindEditBox(frame)
	if not eb or eb.suiStyled then return end
	eb.suiStyled = true
	HideEditBoxChrome(eb, name)
	-- the box itself stays transparent: the styled input bar behind it is
	-- the visible chrome. SetBackdrop draws through NineSlice, so both
	-- the backdrop and the slice have to go or it shows as a black sliver
	if eb.SetBackdrop then pcall(eb.SetBackdrop, eb, nil) end
	if eb.NineSlice then eb.NineSlice:SetAlpha(0) end
	if eb.SetAltArrowKeyMode then eb:SetAltArrowKeyMode(false) end
	if eb.SetTextInsets then pcall(eb.SetTextInsets, eb, 4, 4, 0, 0) end
	EditBar()
	-- no OnShow/OnEditFocusGained hooks and no ChatEdit_UpdateHeader
	-- hook: both fire inside the Enter/click dispatch right before
	-- SendChatMessage - insecure Lua there taints the dispatch and the
	-- send dies. The watchdog below re-applies anchor + border color.
end

-- per-editbox border color by chat type (was a ChatEdit_UpdateHeader
-- post-hook - moved to the watchdog, see below)
local function ApplyEditBoxColor(eb)
	local chatType = eb.GetAttribute and eb:GetAttribute("chatType")
	if chatType == eb._suiChatType then return end
	eb._suiChatType = chatType
	local info = chatType and ChatTypeInfo and ChatTypeInfo[chatType]
	if chatType == "CHANNEL" and GetChannelName then
		local id = GetChannelName(eb:GetAttribute("channelTarget"))
		info = id and id > 0 and ChatTypeInfo["CHANNEL" .. id] or info
	end
	-- channel colour lands on the left strip for a subtle type indicator;
	-- the border stays gold at low alpha so it doesn't turn e.g. bright red
	local bar = Core.editBar
	if info and bar and bar.channelStrip then
		bar.channelStrip:SetVertexColor(info.r, info.g, info.b, 1)
	end
end

function Core.PositionEditBox(frame)
	local eb = FindEditBox(frame)
	if not eb or not Core.leftPanel then return end
	local bar = EditBar()
	-- fixed height independent of DataBars: 26px gives enough room for
	-- the text, the gold hairline and the border on any font size up to 14
	local barH = math.max(26, (db.fontSize or 12) + 10)
	if bar then
		bar:ClearAllPoints()
		if db.editboxPosition == "ABOVE_CHAT" then
			bar:SetPoint("BOTTOMLEFT",  Core.leftPanel, "TOPLEFT",  0, 2)
			bar:SetPoint("BOTTOMRIGHT", Core.leftPanel, "TOPRIGHT", 0, 2)
		else
			bar:SetPoint("TOPLEFT",  Core.leftPanel, "BOTTOMLEFT",  0, -2)
			bar:SetPoint("TOPRIGHT", Core.leftPanel, "BOTTOMRIGHT", 0, -2)
		end
		bar:SetHeight(barH)
		bar.eb = eb
	end
	eb:ClearAllPoints()
	if bar then
		-- text sits 10px in from left (past the channel strip + gap) and
		-- 4px from right; vertical fill fills the whole bar
		eb:SetPoint("TOPLEFT",     bar, "TOPLEFT",     10, -1)
		eb:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -4,  1)
	else
		if db.editboxPosition == "ABOVE_CHAT" then
			eb:SetPoint("BOTTOMLEFT",  Core.leftPanel, "TOPLEFT",  0, 3)
			eb:SetPoint("BOTTOMRIGHT", Core.leftPanel, "TOPRIGHT", 0, 3)
		else
			eb:SetPoint("TOPLEFT",  Core.leftPanel, "BOTTOMLEFT",  0, -3)
			eb:SetPoint("TOPRIGHT", Core.leftPanel, "BOTTOMRIGHT", 0, -3)
		end
		eb:SetHeight(22)
	end
	eb:SetFrameStrata("DIALOG")
	eb:SetToplevel(true)
end

function Core.StyleChatFrame(frame)
	if not frame then return end
	local name = frame.GetName and frame:GetName()

	-- chrome kill: idempotent and re-run on every call. Blizzard's chat
	-- init can finish AFTER our first pass (right after a reload) and
	-- paint the default background and buttons back over the styled
	-- frame - the one-time parts below survive, this part must not.
	for _, region in ipairs(SafeRegions(frame)) do
		if region.IsObjectType and region:IsObjectType("Texture") then region:SetTexture(nil) end
	end
	for _, k in ipairs({ "Background", "TopLeftTexture", "TopRightTexture", "BottomLeftTexture",
		"BottomRightTexture", "LeftTexture", "RightTexture", "TopTexture", "BottomTexture", "ResizeButton" }) do
		local t = name and _G[name .. k]
		if t then t:SetAlpha(0) end
	end
	-- a NineSlice/backdrop background is not a region and survives the
	-- sweep - kill it directly
	if frame.NineSlice then pcall(frame.NineSlice.SetAlpha, frame.NineSlice, 0) end
	if frame.SetBackdropColor then
		pcall(frame.SetBackdropColor, frame, 0, 0, 0, 0)
		pcall(frame.SetBackdropBorderColor, frame, 0, 0, 0, 0)
	end
	local buttonFrame = frame.buttonFrame or (name and _G[name .. "ButtonFrame"])
	if buttonFrame then
		if db.voiceButtons then
			-- the strip holds the channel, voice and menu buttons: keep it,
			-- just kill its chrome
			for _, region in ipairs(SafeRegions(buttonFrame)) do
				if region.IsObjectType and region:IsObjectType("Texture") then region:SetAlpha(0) end
			end
		else
			buttonFrame:Hide()
			buttonFrame.Show = buttonFrame.Hide
		end
	end
	-- floating/undocked windows get a Blizzard minimize button
	for _, k in ipairs({ "MinimizeButton", "MaximizeButton", "CollapseButton" }) do
		local b = frame[k] or (name and _G[name .. k])
		if b and b.Hide then
			b:Hide()
			if b.Show then b.Show = function() b:Hide() end end
		end
	end
	local mmf = frame.MaximizeMinimizeFrame or (name and _G[name .. "MaximizeMinimizeFrame"])
	if mmf then
		mmf:Hide()
		if not mmf.suiHideHook then
			mmf.suiHideHook = true
			mmf:HookScript("OnShow", function(f) f:Hide() end)
		end
	end
	-- scrollbars + scroll buttons: Blizzard re-shows them on scroll
	-- events, which read as weird jumping/flicker until the next 0.25s
	-- restyle tick. OnShow -> Hide keeps them gone for good; hooks are
	-- safe here (no protected dispatch touches these widgets). The
	-- up/down arrows live inside the button frame on this client.
	for _, k in ipairs({ "ScrollBar", "ScrollToBottomButton", "ScrollUpButton",
		"ScrollDownButton", "BottomButton" }) do
		local sb = frame[k] or (name and _G[name .. k])
		if sb then
			sb:SetAlpha(0)
			if sb.EnableMouse then sb:EnableMouse(false) end
			if not sb.suiHideHook then
				sb.suiHideHook = true
				sb:HookScript("OnShow", function(s) s:Hide() end)
			end
			sb:Hide()
		end
	end
	if buttonFrame then
		for _, k in ipairs({ "UpButton", "DownButton", "BottomButton" }) do
			local sb = buttonFrame[k] or (name and _G[name .. "ButtonFrame" .. k])
			if sb then
				sb:SetAlpha(0)
				if sb.EnableMouse then sb:EnableMouse(false) end
				if not sb.suiHideHook then
					sb.suiHideHook = true
					sb:HookScript("OnShow", function(s) s:Hide() end)
				end
				sb:Hide()
			end
		end
	end
	-- the game's scroll-to-bottom button dies when reparented (its click
	-- walks a parent chain) - hide it and use our own chip instead
	local stb = name and _G[name .. "ButtonFrameBottomButton"]
	if stb then stb:SetAlpha(0) stb:EnableMouse(false) end
	if frame.Selection then frame.Selection:SetAlpha(0) end

	-- everything below runs once per frame
	if Core.styled[frame] then return end
	Core.styled[frame] = true

	if db.scrollDownButton and not frame.suiToBottom then
		local b = CreateFrame("Button", nil, frame, "BackdropTemplate")
		b:SetSize(20, 16)
		b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
		b:SetFrameLevel(frame:GetFrameLevel() + 5)
		S.Template(b, "inset")
		local a = S.Font(b, 10, ACCENT)
		a:SetAllPoints()
		a:SetJustifyH("CENTER")
		a:SetText("v")
		b:SetScript("OnClick", function() frame:ScrollToBottom() end)
		b:SetScript("OnEnter", function(bb)
			S.SetBorderLit(bb, true)
			GameTooltip:SetOwner(bb, "ANCHOR_TOPLEFT")
			GameTooltip:AddLine(L["Scroll to bottom"])
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function(bb) S.SetBorderLit(bb, false) GameTooltip:Hide() end)
		local function vis()
			local atBottom = true
			if frame.AtBottom then
				local ok, res = pcall(frame.AtBottom, frame)
				atBottom = ok and res ~= false
			end
			b:SetShown(not atBottom)
		end
		-- OnMessageScrollChanged is retail-only - an unknown script name
		-- throws inside HookScript and would kill the rest of the styling
		pcall(frame.HookScript, frame, "OnMessageScrollChanged", vis)
		pcall(frame.HookScript, frame, "OnMouseWheel", function() C_Timer.After(0, vis) end)
		vis()
		frame.suiToBottom = b
	end

	-- every font call rebuilds all lines (and their links): only set the
	-- font when file, size or flags actually differ
	local wantFlags = db.fontOutline ~= "NONE" and db.fontOutline or ""
	local wantSize = db.fontSize or 12
	frame.suiFontPushed = nil -- an explicit style always re-pushes
	ApplyChatFont(frame, wantSize, wantFlags)
	frame.suiFontApplied = wantSize
	frame:SetShadowOffset(1, -1)
	frame:SetShadowColor(0, 0, 0, 0.9)
	frame:SetClampRectInsets(0, 0, 0, 0)
	frame:SetClampedToScreen(false)
	-- fading on undocked tabs only when configured - a floating channel tab
	-- otherwise silently fades its text away
	local canFade = db.fade and (frame.isDocked or db.fadeUndockedTabs)
	if frame.SetFading then frame:SetFading(canFade and true or false) end
	if frame.SetTimeVisible then frame:SetTimeVisible(db.fadeTime) end
	if frame.GetMaxLines and frame.SetMaxLines then
		local ok, ml = pcall(frame.GetMaxLines, frame)
		if ok and type(ml) == "number" and ml < db.maxLines then
			pcall(frame.SetMaxLines, frame, db.maxLines)
		end
	end

	local tab = name and _G[name .. "Tab"]
	if tab then Core.StyleTab(tab) end
	Core.StyleEditBox(frame)
	Core.PositionEditBox(frame)

	-- the combat log reads secret fight data inside AddMessage - leave it alone
	if frame ~= ChatFrame2 and not frame.suiAddMessage then
		frame.suiAddMessage = frame.AddMessage
		frame.AddMessage = AddMessageHook
	end

	if db.copyButton and not frame.suiCopy then
		local copy = CreateFrame("Button", nil, frame, "BackdropTemplate")
		copy:SetSize(44, 16)
		copy:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
		copy:SetFrameLevel(frame:GetFrameLevel() + 5)
		S.Template(copy, "inset")
		local t = S.Font(copy, 9, ACCENT)
		t:SetAllPoints()
		t:SetJustifyH("CENTER")
		t:SetJustifyV("MIDDLE")
		t:SetText(L["Copy"])
		copy:SetAlpha(0.35)
		copy:SetScript("OnClick", function() Core.CopyChat(frame) end)
		copy:SetScript("OnEnter", function(b)
			b:SetAlpha(1)
			S.SetBorderLit(b, true)
			GameTooltip:SetOwner(b, "ANCHOR_TOPLEFT")
			GameTooltip:AddLine(L["Copy Chat"])
			GameTooltip:Show()
		end)
		copy:SetScript("OnLeave", function(b)
			b:SetAlpha(0.35)
			S.SetBorderLit(b, false)
			GameTooltip:Hide()
		end)
		frame.suiCopy = copy
	end

	-- hovering item/spell/quest links shows their tooltip
	pcall(frame.HookScript, frame, "OnHyperlinkEnter", function(f, link)
		if not db.hyperlinkHover or type(link) ~= "string" then return end
		local kind = link:match("^(%a+):")
		if kind and hoverLinks[kind] then
			GameTooltip:SetOwner(f, "ANCHOR_CURSOR")
			pcall(GameTooltip.SetHyperlink, GameTooltip, link)
			GameTooltip:Show()
			Core.hoverTip = true
		end
	end)
	pcall(frame.HookScript, frame, "OnHyperlinkLeave", function()
		if Core.hoverTip then Core.hoverTip = nil GameTooltip:Hide() end
	end)
end

-- loot chat -------------------------------------------------------------------
-- a dedicated chat window for loot, money and gain messages, docked in the
-- right panel: created on demand and stripped down to its own message
-- groups. IsRightChat below already docks every undocked "Loot" window.
local LOOT_EVENTS = {
	CHAT_MSG_LOOT = true, CHAT_MSG_MONEY = true, CHAT_MSG_CURRENCY = true,
	CHAT_MSG_SKILL = true, CHAT_MSG_COMBAT_XP_GAIN = true,
	CHAT_MSG_COMBAT_FACTION_CHANGE = true, CHAT_MSG_ACHIEVEMENT = true,
	CHAT_MSG_COMBAT_HONOR_GAIN = true, CHAT_MSG_GUILD_ITEM_LOOTED = true,
}
local LOOT_GROUPS = { LOOT = 1, MONEY = 1, CURRENCY = 1, SKILL = 1,
	ACHIEVEMENT = 1, COMBAT_XP_GAIN = 1, COMBAT_FACTION_CHANGE = 1,
	COMBAT_HONOR_GAIN = 1, GUILD_ITEM_LOOTED = 1 }

local function LootChatLabel()
	return _G.LOOT or "Loot"
end

local function FindLootWindow()
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		local f = _G["ChatFrame" .. i]
		local tab = _G["ChatFrame" .. i .. "Tab"]
		local text = tab and (tab.Text or _G[tab:GetName() .. "Text"])
		local label = text and text:GetText()
		if f and label and not IsSecret(label)
			and (label == LootChatLabel() or label == "Loot" or label == "Beute") then
			return f
		end
	end
end

local function ForEachLootGroup(fn)
	if not ChatTypeGroup then return end
	for gname, evs in pairs(ChatTypeGroup) do
		-- named groups always count; unnamed ones only when every event in
		-- them is a loot event, so nothing unrelated gets touched
		local want = LOOT_GROUPS[gname] and true or false
		if not want and type(evs) == "table" then
			want = #evs > 0
			for _, ev in ipairs(evs) do
				if not LOOT_EVENTS[ev] then want = false break end
			end
		end
		if want then fn(gname) end
	end
end

local function ConfigLootWindow(f)
	if ChatFrame_RemoveAllMessageGroups then
		pcall(ChatFrame_RemoveAllMessageGroups, f)
	end
	if not ChatFrame_AddMessageGroup then return end
	ForEachLootGroup(function(gname)
		pcall(ChatFrame_AddMessageGroup, f, gname)
	end)
end

-- the whole point of the split: loot lines belong to the loot window
-- only, so every other chat window loses those message groups
local function StripLootFromOthers(keep)
	if not ChatFrame_RemoveMessageGroup then return end
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		local f = _G["ChatFrame" .. i]
		if f and f ~= keep then
			ForEachLootGroup(function(gname)
				pcall(ChatFrame_RemoveMessageGroup, f, gname)
			end)
		end
	end
end

function Core.EnsureLootChat()
	if not (db and db.lootChat) then return end
	if InCombatLockdown() then return S.RunOutOfCombat(Core.EnsureLootChat) end
	local f = FindLootWindow()
	if not f and FCF_OpenNewWindow then
		pcall(FCF_OpenNewWindow, LootChatLabel())
		f = FindLootWindow()
	end
	if not f then return end
	-- remember the frame itself: tab labels can be secret values, so
	-- IsRightChat cannot rely on reading them on this client
	Core.lootWindow = f
	-- a window closed by hand stays closed forever otherwise: bring it
	-- back, the dock pass below re-anchors it into the right panel
	if f.Show and not f:IsShown() then pcall(f.Show, f) end
	if not f.suiLootConfig then
		f.suiLootConfig = true
		S.SafeCall("chat:lootcfg", ConfigLootWindow, f)
	end
	S.SafeCall("chat:lootstrip", StripLootFromOthers, f)
	-- only an undocked window moves into the right panel
	if f.isDocked and FCF_UnDockFrame then
		S.SafeCall("chat:undock", FCF_UnDockFrame, f)
	end
	if not db.rightPanelEnable then
		db.rightPanelEnable = true
		Core.UpdatePanels()
	end
	Core.PositionChat()
end

function Core.IsRightChat(frame)
	if not db.rightPanelEnable then return false end
	-- identity check first: the tab label can be a secret value or a
	-- localized name the list below misses (e.g. "Plündern"), so the
	-- loot window is best identified by the frame itself
	if Core.lootWindow and frame == Core.lootWindow then return true end
	local lw = FindLootWindow()
	if lw and frame == lw then return true end
	local fname = frame.GetName and frame:GetName()
	if not fname then return false end
	local tab = _G[fname .. "Tab"]
	local text = tab and (tab.Text or _G[tab:GetName() .. "Text"])
	local label = text and text:GetText()
	if not label or IsSecret(label) then return false end
	return label == LOOT or label == "Loot" or label == "Beute"
		or label == "Plündern" or label == L["Right Chat"]
end

function Core.PositionChat()
	if InCombatLockdown() then return S.RunOutOfCombat(Core.PositionChat) end
	if not Core.leftPanel then return end
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		local frame = _G["ChatFrame" .. i]
		if frame then
			S.SafeCall("chat:frame", Core.StyleChatFrame, frame)
			S.SafeCall("chat:pos", function()
				local tab = _G["ChatFrame" .. i .. "Tab"]
				if frame == ChatFrame1 then
					frame:ClearAllPoints()
					frame:SetPoint("TOPLEFT", Core.leftPanel, "TOPLEFT", 6, -30)
					frame:SetPoint("BOTTOMRIGHT", Core.leftPanel, "BOTTOMRIGHT", -6, 6)
					if FCF_SavePositionAndDimensions then pcall(FCF_SavePositionAndDimensions, frame) end
				elseif Core.rightPanel and Core.IsRightChat(frame) and not frame.isDocked then
					frame:ClearAllPoints()
					frame:SetPoint("TOPLEFT", Core.rightPanel, "TOPLEFT", 6, -30)
					frame:SetPoint("BOTTOMRIGHT", Core.rightPanel, "BOTTOMRIGHT", -6, 6)
					if FCF_SavePositionAndDimensions then pcall(FCF_SavePositionAndDimensions, frame) end
					if not frame:IsShown() then pcall(frame.Show, frame) end
					if tab then
						-- the right panel already IS the loot window: its floating
						-- "Loot" channel tab pokes out over the panel's top edge
						-- and clicking it toggles the whole frame off - hide it,
						-- take it off the mouse (reversible if it re-docks)
						if not tab.suiHiddenTab then
							tab.suiHiddenTab = true
							tab.suiOrigShow = tab.Show
							tab.Show = function(t) t:Hide() end
						end
						tab:Hide()
						if tab.EnableMouse then tab:EnableMouse(false) end
					end
				elseif tab and tab.suiHiddenTab then
					-- the loot window went back to a Blizzard dock: restore its
					-- tab handle so the window stays reachable there
					tab.Show = tab.suiOrigShow
					tab.suiOrigShow = nil
					tab.suiHiddenTab = nil
					if tab.EnableMouse then tab:EnableMouse(true) end
					pcall(tab.Show, tab)
				end
			end)
		end
	end
	if GeneralDockManager and ChatFrame1 and GeneralDockManager.ClearAllPoints then
		S.SafeCall("chat:dock", function()
			GeneralDockManager:ClearAllPoints()
			GeneralDockManager:SetPoint("BOTTOMLEFT", ChatFrame1, "TOPLEFT", 0, 4)
			GeneralDockManager:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", -20, 4)
			GeneralDockManager:SetHeight(22)
		end)
	end
	S.SafeCall("chat:voicestrip", Core.StyleVoiceStrip)
	S.SafeCall("chat:tabs", Core.UpdateTabColors)
end

-- the channel, voice and menu buttons get their own styled strip: a row of
-- small inset chips in the tab line, right-aligned in front of the emoji chip
local voiceStripOrder = { "ChatFrameToggleVoiceMuteButton", "ChatFrameToggleVoiceDeafenButton",
	"ChatFrameChannelButton", "ChatFrameMenuButton" } -- array order = right to left on screen

function Core.StyleVoiceStrip()
	if not Core.leftPanel then return end
	if not db.voiceButtons then
		for _, n in ipairs(voiceStripOrder) do
			local b = _G[n]
			if b and type(b.SetAlpha) == "function" then
				b:SetAlpha(0)
				if b.EnableMouse then b:EnableMouse(false) end
			end
		end
		return
	end
	local prev
	for _, n in ipairs(voiceStripOrder) do
		local b = _G[n]
		if b and type(b.SetAlpha) == "function" and b.ClearAllPoints then
			if b.EnableMouse then b:EnableMouse(true) end
			b:SetAlpha(0.45)
			b:SetSize(16, 16)
			b:ClearAllPoints()
			if not prev then
				if Core.emojiButton then
					b:SetPoint("RIGHT", Core.emojiButton, "LEFT", -4, 0)
				else
					b:SetPoint("TOPRIGHT", Core.leftPanel, "TOPRIGHT", -4, -5)
				end
			else
				b:SetPoint("RIGHT", prev, "LEFT", -3, 0)
			end
			prev = b
			if not b.SetBackdrop and BackdropTemplateMixin then Mixin(b, BackdropTemplateMixin) end
			S.Template(b, "inset")
			if not b.suiVoiceHook then
				b.suiVoiceHook = true
				pcall(b.HookScript, b, "OnEnter", function(bb)
					bb:SetAlpha(1)
					S.SetBorderLit(bb, true)
				end)
				pcall(b.HookScript, b, "OnLeave", function(bb)
					bb:SetAlpha(0.45)
					S.SetBorderLit(bb, false)
				end)
			end
		end
	end
end

function Core.HideBlizzardButtons()
	Core.StyleVoiceStrip()
	-- junk that stays hidden either way
	for _, n in ipairs({ "QuickJoinToastButton", "FriendsMicroButton", "TextToSpeechButton" }) do
		local b = _G[n]
		if b and type(b.SetAlpha) == "function" then
			b:SetAlpha(0)
			b:EnableMouse(false)
			if b.UnregisterAllEvents and n == "QuickJoinToastButton" then b:UnregisterAllEvents() end
		end
	end
	if GeneralDockManagerScrollFrame and GeneralDockManagerScrollFrame.ScrollLeftButton then
		GeneralDockManagerScrollFrame.ScrollLeftButton:SetAlpha(0)
	end
end

-- emoji picker: a small chip in the tab strip opens the icon row; a click
-- inserts the code into the active edit box
local function InsertEmote(pat)
	local eb = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
	if not eb then
		eb = ChatFrame1 and (ChatFrame1.editBox or _G.ChatFrame1EditBox)
		if eb then eb:Show() eb:SetFocus() end
	end
	if eb then eb:Insert(pat) end
end

local function EmojiPicker()
	if Core.picker then return Core.picker end
	local cols, cell, pad = 8, 26, 7
	local rows = math.ceil(#EMOTE_ORDER / cols)
	local p = CreateFrame("Frame", "SentiUIEmojiPicker", UIParent, "BackdropTemplate")
	p:SetFrameStrata("DIALOG")
	p:SetToplevel(true)
	p:EnableMouse(true)
	S.Template(p, "raised")
	S.EscClosable(p)
	local title = S.Font(p, 11, ACCENT)
	title:SetPoint("TOPLEFT", 8, -6)
	title:SetText(L["Emotes"])
	local line = S.Line(p, ACCENT)
	line:SetPoint("TOPLEFT", 6, -20)
	line:SetPoint("TOPRIGHT", -6, -20)
	for i, name in ipairs(EMOTE_ORDER) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local b = CreateFrame("Button", nil, p, "BackdropTemplate")
		b:SetSize(cell - 4, cell - 4)
		b:SetPoint("TOPLEFT", pad + col * cell, -26 - row * cell)
		S.Template(b, "inset")
		local icon = b:CreateTexture(nil, "OVERLAY")
		icon:SetPoint("CENTER")
		icon:SetSize(16, 16)
		icon:SetTexture(EMOTE_DIR .. name .. ".tga")
		b:SetScript("OnEnter", function(bb)
			S.SetBorderLit(bb, true)
			GameTooltip:SetOwner(bb, "ANCHOR_TOP")
			GameTooltip:AddLine(":" .. name .. ":", 1, 1, 1)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function(bb)
			S.SetBorderLit(bb, false)
			GameTooltip:Hide()
		end)
		b:SetScript("OnClick", function() InsertEmote(":" .. name .. ":") p:Hide() end)
	end
	p:SetSize(pad * 2 + cols * cell, 30 + rows * cell)
	p:Hide()
	Core.picker = p
	return p
end

local function MakeEmojiButton()
	if not db.smilies or not Core.leftPanel then return end
	local b = CreateFrame("Button", "SentiUIEmojiButton", Core.leftPanel, "BackdropTemplate")
	b:SetSize(22, 16)
	b:SetPoint("TOPRIGHT", Core.leftPanel, "TOPRIGHT", -4, -5)
	S.Template(b, "inset")
	local t = S.Font(b, 9, ACCENT)
	t:SetAllPoints()
	t:SetJustifyH("CENTER")
	t:SetText(":)")
	b:SetAlpha(0.55)
	b:SetScript("OnClick", function()
		local p = EmojiPicker()
		p:ClearAllPoints()
		p:SetPoint("BOTTOMRIGHT", b, "TOPRIGHT", 0, 4)
		p:SetShown(not p:IsShown())
	end)
	b:SetScript("OnEnter", function(bb) bb:SetAlpha(1) S.SetBorderLit(bb, true) end)
	b:SetScript("OnLeave", function(bb) bb:SetAlpha(0.55) S.SetBorderLit(bb, false) end)
	Core.emojiButton = b
end

-- class-colored names -------------------------------------------------------------
function Core.SetupClassColors()
	local function SetGroupColored(group, flag)
		local info = ChatTypeGroup and ChatTypeGroup[group]
		if info then
			for _, value in next, info do
				pcall(SetChatColorNameByClass, strsub(value, 10), flag)
			end
		else
			pcall(SetChatColorNameByClass, group, flag)
		end
	end
	for _, group in ipairs({ "SAY", "EMOTE", "YELL", "GUILD", "OFFICER", "GUILD_ACHIEVEMENT",
		"ACHIEVEMENT", "WHISPER", "PARTY", "PARTY_LEADER", "RAID", "RAID_LEADER",
		"RAID_WARNING", "INSTANCE_CHAT", "INSTANCE_CHAT_LEADER", "BATTLEGROUND",
		"BATTLEGROUND_LEADER" }) do
		SetGroupColored(group, true)
	end
	for i = 1, 15 do SetGroupColored("CHANNEL" .. i, true) end
end

-- player level in chat: passive {level, class} cache fed by guild, group and
-- friends data; SendWho is protected, so unknown senders get no level
Core.levelCache = {}

function Core.LearnPlayer(name, level, class)
	if IsSecret(name) or IsSecret(level) or IsSecret(class) then return end
	if not name or name == "" then return end
	local e = Core.levelCache[name]
	if not e or (level or 0) > (e.level or 0) or (class and not e.class) then
		Core.levelCache[name] = { level = level or (e and e.level) or 0, class = class or (e and e.class) }
	end
end

function Core.ScanGroup()
	for i = 1, (GetNumGroupMembers and GetNumGroupMembers() or 0) do
		local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
		local name, realm = UnitName(unit)
		if name then
			if realm and realm ~= "" then name = name .. "-" .. realm end
			local _, class = UnitClass(unit)
			Core.LearnPlayer(name, UnitLevel(unit), class)
		end
	end
end

local function ScanGuild()
	if not IsInGuild() then return end
	if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
	elseif GuildRoster then GuildRoster() end
	local n = GetNumGuildMembers and GetNumGuildMembers() or 0
	for i = 1, n do
		local name, _, _, level, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
		if name then Core.LearnPlayer(name, level, class) end
	end
end

local function ScanFriends()
	local n = C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetNumFriends() or 0
	for i = 1, n do
		local info = C_FriendList.GetFriendInfoByIndex(i)
		if info and info.name then Core.LearnPlayer(info.name, info.level, info.className) end
	end
end

local function ShortName(sender)
	if type(sender) ~= "string" or IsSecret(sender) then return nil end
	return (sender:gsub("%-.*", ""))
end

local levelEvents = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_RAID_WARNING", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_CHANNEL", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
	"CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER", "CHAT_MSG_EMOTE",
}

local function LevelFilter(_, _, msg, sender, ...)
	if not db or not db.playerLevel or type(msg) ~= "string" or IsSecret(msg)
		or IsSecret(sender) then return false end
	local name = ShortName(sender)
	local e = name and Core.levelCache[name]
	if not e or not e.level or e.level <= 0 then return false end
	-- rewrite the name inside the |Hplayer link: [Name] -> [52 Name]
	local newMsg, n = gsub(msg, "(|Hplayer:[^|]-|h%[)[^%]]-(%]|h)", "%1" .. e.level .. " " .. name .. "%2", 1)
	if n == 0 then newMsg = msg end
	return false, newMsg, sender, ...
end

function Core.UpdateKeywords()
	Core.keywords = {}
	for word in (db.keywords or ""):gmatch("[^,]+") do
		local w = strtrim(word)
		if w == "%MYNAME%" then w = UnitName("player") or w end
		if w ~= "" then tinsert(Core.keywords, w) end
	end
end

-- enable / settings ----------------------------------------------------------------
function Core.Update()
	Core.UpdatePanels()
	Core.UpdateKeywords()
	Core.StyleVoiceStrip()
	for frame in pairs(Core.styled) do
		-- an explicit settings change always re-pushes the font
		frame.suiFontPushed = nil
		ApplyChatFont(frame, db.fontSize, db.fontOutline ~= "NONE" and db.fontOutline or "")
		frame.suiFontApplied = db.fontSize
		local canFade = db.fade and (frame.isDocked or db.fadeUndockedTabs)
		frame:SetFading(canFade and true or false)
		frame:SetTimeVisible(db.fadeTime)
		Core.PositionEditBox(frame)
		local tab = _G[frame:GetName() .. "Tab"]
		if tab then Core.StyleTab(tab) end
	end
	Core.PositionChat()
	-- keep the input bar's transparency in sync with the panel setting
	if Core.editBar and Core.editBar.SetBackdropColor then
		local bg = S.colors.bg
		Core.editBar:SetBackdropColor(bg.r, bg.g, bg.b,
			db.panelTransparency and 0.55 or 0.80)
	end
end

function Core.SettingChanged(mod, path)
	if not Core.enabled then return end

	if path == "classColorMentions" and db.classColorMentions then Core.SetupClassColors() end
	if path == "keywords" then Core.UpdateKeywords() return end
	if path == "lootChat" or path == "rightPanelEnable" then
		S.SafeCall("chat:lootwin", Core.EnsureLootChat)
	end
	Core.Update()
end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db

	-- the edit box moved below the chat; carry older profiles over once
	if db._ev == nil then
		db._ev = 1
		if db.editboxPosition == "ABOVE_CHAT" then db.editboxPosition = "BELOW_CHAT" end
	end

	S.SafeCall("chat:panels", Core.CreatePanels)
	S.SafeCall("chat:keywords", Core.UpdateKeywords)
	S.SafeCall("chat:emoji", MakeEmojiButton)
	S.SafeCall("chat:buttons", Core.HideBlizzardButtons)
	S.SafeCall("chat:itemref", Core.HookItemRef)
	if db.classColorMentions then S.SafeCall("chat:colors", Core.SetupClassColors) end

	if db.timestamp ~= "NONE" then
		-- our own timestamps replace the game's: the legacy SetCVar global
		-- is not guaranteed on this client, C_CVar is the native path
		local setCVar = (C_CVar and C_CVar.SetCVar) or SetCVar
		if setCVar then pcall(setCVar, "showTimestamps", "none") end
	end

	S.SafeCall("chat:position", Core.PositionChat)
	S.RegisterEvent("UPDATE_CHAT_WINDOWS", Core.PositionChat)
	S.RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", Core.PositionChat)
	-- resolution / ui-scale changes leave the chat frame and panels at
	-- stale sizes until a manual resize: re-run the panel sizing and the
	-- chat docking pass when they fire
	for _, ev in ipairs({ "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
		S.RegisterEvent(ev, function()
			S.SafeCall("chat:" .. ev, function()
				Core.UpdatePanels()
				Core.PositionChat()
			end)
		end)
	end
	S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(1, function() S.SafeCall("chat:pew", Core.PositionChat) end)
		-- chat windows settle a moment after login; the loot window is
		-- created and docked once they exist
		C_Timer.After(2, function() S.SafeCall("chat:lootwin", Core.EnsureLootChat) end)
	end)
	-- instant snap-back: whenever Blizzard's own positioning pass re-anchors
	-- ChatFrame1 (dock updates, managed-frame pushes on level-up banners),
	-- re-dock it inside the same Lua pass so the wrong spot never renders
	local function SnapChatFrame1()
		if InCombatLockdown() or not (ChatFrame1 and Core.leftPanel) then return end
		local ok, _, relTo = pcall(ChatFrame1.GetPoint, ChatFrame1, 1)
		if not ok or relTo == Core.leftPanel then return end
		ChatFrame1:ClearAllPoints()
		ChatFrame1:SetPoint("TOPLEFT", Core.leftPanel, "TOPLEFT", 6, -30)
		ChatFrame1:SetPoint("BOTTOMRIGHT", Core.leftPanel, "BOTTOMRIGHT", -6, 6)
	end
	if not Core._posHooks then
		Core._posHooks = true
		pcall(ChatFrame1.SetAttribute, ChatFrame1, "ignoreFramePositionManager", true)
		-- no hooksecurefunc on Blizzard layout/chat functions: the
		-- post-call runs inside whatever dispatch triggered it - a
		-- keybind click, a panel open, the Enter key before
		-- SendChatMessage - and taints it, killing the protected calls
		-- and secret compares behind it. One quarter-second watchdog in
		-- its own dispatch re-docks, restyles new frames, re-colors tabs
		-- and edit boxes, and re-anchors the edit box instead.
		local lastSel, lastShown
		-- blizzard's chat-cache restore lands shortly after login and can
		-- clobber our font application; a mismatch seen that early is put
		-- back to db.fontSize, a later one is a live tab-menu change and
		-- gets adopted instead (either path persists)
		local enableT = GetTime()
		C_Timer.NewTicker(0.25, function()
			S.SafeCall("chat:watch", function()
				SnapChatFrame1()
				local shown = 0
				local wantFlags = db.fontOutline ~= "NONE" and db.fontOutline or ""
				for i = 1, (NUM_CHAT_WINDOWS or 10) do
					local f = _G["ChatFrame" .. i]
					if f then
						-- every tick, not only for new frames: the chrome
						-- kill is idempotent and blizzard's init repaints
						-- the default background after our first pass
						S.SafeCall("chat:style", Core.StyleChatFrame, f)
						local okF, _, fsize = pcall(f.GetFont, f)
						if okF and type(fsize) == "number" and fsize > 0
							and db.fontSize and math.abs(fsize - db.fontSize) > 0.5 then
							if GetTime() - enableT < 15 then
								-- re-push only when the observed size moved: a
								-- font API that never reflects the push would
								-- otherwise rebuild the lines every tick
								if f.suiFontLastSeen ~= fsize then
									f.suiFontLastSeen = fsize
									f.suiFontPushed = nil
									ApplyChatFont(f, db.fontSize, wantFlags)
									f.suiFontApplied = db.fontSize
								end
							elseif f.suiFontApplied
								and math.abs(fsize - f.suiFontApplied) > 0.5 then
								-- a live tab-menu change: adopt it. A size that
								-- was never successfully applied (silent font
								-- failure) is not adopted - the saved choice stays
								db.fontSize = math.floor(fsize + 0.5)
								f.suiFontApplied = db.fontSize
							end
						end
						if f:IsShown() then shown = shown + 1 end
						local eb = FindEditBox(f)
						if eb then
							if not eb.suiStyled then
								S.SafeCall("chat:ebstyle", Core.StyleEditBox, f)
							end
							HideEditBoxChrome(eb, f.GetName and f:GetName())
							ApplyEditBoxColor(eb)
							if Core.leftPanel and eb:IsShown() then
								local ok, _, relTo = pcall(eb.GetPoint, eb, 1)
								if ok and relTo ~= (Core.editBar or Core.leftPanel) then
									S.SafeCall("chat:ebpos", Core.PositionEditBox, f)
								end
							end
						end
					end
				end
				if shown ~= lastShown then
					lastShown = shown
					Core.PositionChat()
				end
				local sel = SELECTED_CHAT_FRAME or SELECTED_DOCK_FRAME
				if sel ~= lastSel then
					lastSel = sel
					Core.UpdateTabColors()
				end
			end)
		end)
	end

	-- the client re-anchors chat windows on level ups - repeatedly, not
	-- once: the banner, the spec/spell toasts and the floating combat
	-- text each trigger their own layout pass seconds apart. A short
	-- burst only caught the first shove, so the frame visibly jumped
	-- out of the panel and settled at the old spot. Burst for 5s and
	-- re-run the full dock pass at increasing delays.
	S.RegisterEvent("PLAYER_LEVEL_UP", function()
		local n = 0
		local t
		t = C_Timer.NewTicker(0.1, function()
			n = n + 1
			S.SafeCall("chat:levelup", SnapChatFrame1)
			if n >= 50 then t:Cancel() end
		end)
		for _, delay in ipairs({ 0.6, 1.6, 3, 5 }) do
			C_Timer.After(delay, function() S.SafeCall("chat:levelup", Core.PositionChat) end)
		end
	end)

	-- self-healing anchor watch: the client can re-anchor ChatFrame1 on
	-- window/dock updates at any time (level ups, FCF passes) - re-dock it
	-- into the panel whenever its first anchor no longer points there
	local watchAcc = 0
	local watch = CreateFrame("Frame")
	watch:SetScript("OnUpdate", function(_, e)
		-- fast path every frame: sync the input bar with the active editbox
		if Core.leftPanel then
			-- this client never hides its editbox (IsShown is always true),
			-- so "typing" can only be told from HasFocus - the bar appears
			-- when the box gains focus and leaves with it
			local anyFocused = false
			for i = 1, (NUM_CHAT_WINDOWS or 10) do
				local f = _G["ChatFrame" .. i]
				local eb = f and FindEditBox(f)
				if eb and eb:IsShown() then
					local okE, _, relTo = pcall(eb.GetPoint, eb, 1)
					if okE and relTo ~= (Core.editBar or Core.leftPanel) then
						Core.PositionEditBox(f)
					end
					if eb.HasFocus and eb:HasFocus() then anyFocused = true end
				end
			end
			if Core.editBar then
				Core.editBar:SetShown(anyFocused)
			end
		end
		watchAcc = watchAcc + e
		if watchAcc < 1 then return end
		watchAcc = 0
		if InCombatLockdown() or not (ChatFrame1 and Core.leftPanel) then return end
		local ok, _, relTo = pcall(ChatFrame1.GetPoint, ChatFrame1, 1)
		if ok and relTo ~= Core.leftPanel then
			Core.PositionChat()
		end
	end)

	-- whisper sound
	local function WhisperSound()
		if not db.whisperSound then return end
		if not Core.lastWhisper or GetTime() - Core.lastWhisper > 2 then
			Core.lastWhisper = GetTime()
			PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master")
		end
	end
	S.RegisterEvent("CHAT_MSG_WHISPER", WhisperSound)
	S.RegisterEvent("CHAT_MSG_BN_WHISPER", WhisperSound)

	-- spam throttle
	for _, ev in ipairs({ "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_CHANNEL",
		"CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE" }) do
		pcall(ChatFrame_AddMessageEventFilter, ev, ThrottleFilter)
	end
	C_Timer.NewTicker(60, function()
		local now = GetTime()
		for k, v in pairs(throttleCache) do if now - v > 120 then throttleCache[k] = nil end end
	end)

	C_Timer.After(0.5, function() S.SafeCall("chat:history", Core.ReplayHistory) end)

	-- player level: cache feed + message filter
	for _, ev in ipairs(levelEvents) do pcall(ChatFrame_AddMessageEventFilter, ev, LevelFilter) end
	S.RegisterEvent("GUILD_ROSTER_UPDATE", function() S.SafeCall("chat:guild", ScanGuild) end)
	S.RegisterEvent("GROUP_ROSTER_UPDATE", function() S.SafeCall("chat:group", Core.ScanGroup) end)
	S.RegisterEvent("FRIENDLIST_UPDATE", function() S.SafeCall("chat:friends", ScanFriends) end)
	S.SafeCall("chat:scan", function() ScanGuild() ScanFriends() Core.ScanGroup() end)
end
