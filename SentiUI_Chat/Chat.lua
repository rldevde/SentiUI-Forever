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
	fade:SetAllPoints()
	fade:SetColorTexture(0, 0, 0, 1)
	p.fade = fade
	-- accent hairline under the tab row
	local line = S.Line(p, ACCENT)
	line:SetPoint("TOPLEFT", 4, -26)
	line:SetPoint("TOPRIGHT", -4, -26)
	p.line = line
	-- Sentinel signature: small accent ticks at the bottom corners
	p.ticks = {}
	for _, side in ipairs({ "BOTTOMLEFT", "BOTTOMRIGHT" }) do
		local t = p:CreateTexture(nil, "ARTWORK")
		t:SetTexture(BLANK)
		t:SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
		t:SetSize(6, 2)
		t:SetPoint(side, 4, 1)
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
local SMILE_ORDER = { ":-)", ";-)", ":-D", ":-(", ":-P", ":-p", ":)", ";)", ":D", ":(", ":P", ":p", "<3", "o.O", "O.o", "^^" }
local SMILE_MAP = {
	[":)"] = "smile", [":-)"] = "smile", [";)"] = "wink", [";-)"] = "wink",
	[":D"] = "grin", [":-D"] = "grin", ["^^"] = "joy",
	[":("] = "sad", [":-("] = "sad",
	[":P"] = "tongue", [":-P"] = "tongue", [":p"] = "tongue", [":-p"] = "tongue",
	["<3"] = "heart", ["o.O"] = "surprised", ["O.o"] = "surprised",
}
local function Smileys(text)
	for _, pat in ipairs(SMILE_ORDER) do
		text = text:gsub(pat:gsub("%W", "%%%0"),
			"|T" .. EMOTE_DIR .. SMILE_MAP[pat] .. ".tga:14:14|t")
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
	local masks
	if db.url or db.smilies then
		masks = {}
		local function mask(l) masks[#masks + 1] = l return "\1" .. #masks .. "\2" end
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

-- URL copy popup
StaticPopupDialogs["SENTIUI_URL"] = {
	text = "URL", button1 = CLOSE, hasEditBox = true, editBoxWidth = 350,
	OnShow = function(self, data)
		local eb = self.editBox or self.EditBox
		if eb then eb:SetText(data or "") eb:SetFocus() eb:HighlightText() end
	end,
	-- no EditBoxOnEscapePressed: it runs inside the Escape dispatch
	-- and taints the engine's protected spell-stop calls; hideOnEscape
	-- closes the popup natively
	timeout = 0, whileDead = true, hideOnEscape = true,
}

function Core.HookItemRef()
	local original = SetItemRef
	SetItemRef = function(link, text, button, chatFrame)
		if type(link) == "string" and link:sub(1, 4) == "url:" then
			StaticPopup_Show("SENTIUI_URL", nil, nil, link:sub(5))
			return
		end
		return original(link, text, button, chatFrame)
	end
end

-- copy chat ----------------------------------------------------------------------
function Core.CopyChat(frame)
	if not Core.copyFrame then
		local f = CreateFrame("Frame", "SentiUIChatCopy", UIParent, "BackdropTemplate")
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
		tinsert(UISpecialFrames, "SentiUIChatCopy")
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
		local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", -4, -4)
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
	local glow = tab.glow or (tn and _G[tn .. "Glow"])
	if glow then
		glow:SetTexture(BLANK)
		glow:SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.35)
		glow:ClearAllPoints()
		glow:SetPoint("BOTTOMLEFT", 8, 2)
		glow:SetPoint("BOTTOMRIGHT", -8, 2)
		glow:SetHeight(2)
	end
	local text = tab.Text or (tn and _G[tn .. "Text"])
	if text then
		pcall(text.SetFont, text, S.media.font, db.tabFontSize, "OUTLINE")
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
		if text then
			if frame == SELECTED_CHAT_FRAME or (SELECTED_DOCK_FRAME and frame == SELECTED_DOCK_FRAME) then
				text:SetTextColor(ACCENT.r, ACCENT.g, ACCENT.b)
			else
				text:SetTextColor(0.9, 0.9, 0.9)
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

function Core.StyleEditBox(frame)
	local name = frame.GetName and frame:GetName()
	local eb = FindEditBox(frame)
	if not eb or eb.suiStyled then return end
	eb.suiStyled = true
	for _, k in ipairs({ "Left", "Mid", "Right", "FocusLeft", "FocusMid", "FocusRight" }) do
		local t = (name and _G[name .. "EditBox" .. k]) or eb[k]
		if t then t:SetAlpha(0) end
	end
	if eb.NineSlice then eb.NineSlice:SetAlpha(0) end
	if not eb.SetBackdrop and BackdropTemplateMixin then Mixin(eb, BackdropTemplateMixin) end
	S.Template(eb, "raised")
	if eb.SetAltArrowKeyMode then eb:SetAltArrowKeyMode(false) end
	eb:HookScript("OnEditFocusGained", function(self) self:Show() end)
	-- Blizzard re-anchors the edit box to whatever chat frame is active -
	-- re-assert our layout every time it shows
	eb:HookScript("OnShow", function()
		S.SafeCall("chat:ebshow", Core.PositionEditBox, frame)
	end)
	if not ChatEdit_UpdateHeader then return end
	hooksecurefunc("ChatEdit_UpdateHeader", function(editBox)
		if editBox ~= eb then return end
		local chatType = editBox:GetAttribute("chatType")
		local info = chatType and ChatTypeInfo and ChatTypeInfo[chatType]
		if chatType == "CHANNEL" then
			local id = GetChannelName(editBox:GetAttribute("channelTarget"))
			info = id and id > 0 and ChatTypeInfo["CHANNEL" .. id] or info
		end
		if info and editBox.SetBackdropBorderColor then
			editBox:SetBackdropBorderColor(info.r, info.g, info.b)
		end
	end)
end

function Core.PositionEditBox(frame)
	local eb = FindEditBox(frame)
	if not eb or not Core.leftPanel then return end
	eb:ClearAllPoints()
	if db.editboxPosition == "ABOVE_CHAT" then
		eb:SetPoint("BOTTOMLEFT", Core.leftPanel, "TOPLEFT", 0, 3)
		eb:SetPoint("BOTTOMRIGHT", Core.leftPanel, "TOPRIGHT", 0, 3)
	else
		eb:SetPoint("TOPLEFT", Core.leftPanel, "BOTTOMLEFT", 0, -3)
		eb:SetPoint("TOPRIGHT", Core.leftPanel, "BOTTOMRIGHT", 0, -3)
	end
	eb:SetHeight(22)
	eb:SetFrameStrata("DIALOG")
	eb:SetToplevel(true)
end

function Core.StyleChatFrame(frame)
	if not frame or Core.styled[frame] then return end
	Core.styled[frame] = true
	local name = frame.GetName and frame:GetName()

	for _, region in ipairs(SafeRegions(frame)) do
		if region.IsObjectType and region:IsObjectType("Texture") then region:SetTexture(nil) end
	end
	for _, k in ipairs({ "Background", "TopLeftTexture", "TopRightTexture", "BottomLeftTexture",
		"BottomRightTexture", "LeftTexture", "RightTexture", "TopTexture", "BottomTexture", "ResizeButton" }) do
		local t = name and _G[name .. k]
		if t then t:SetAlpha(0) end
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
			if b.HookScript then b:HookScript("OnShow", function(bb) bb:Hide() end) end
		end
	end
	local mmf = frame.MaximizeMinimizeFrame or (name and _G[name .. "MaximizeMinimizeFrame"])
	if mmf then mmf:Hide() mmf:HookScript("OnShow", function(f) f:Hide() end) end
	if frame.ScrollBar then frame.ScrollBar:SetAlpha(0) frame.ScrollBar:EnableMouse(false) end
	-- the game's scroll-to-bottom button dies when reparented (its click
	-- walks a parent chain) - hide it and use our own chip instead
	local stb = frame.ScrollToBottomButton or (name and _G[name .. "ButtonFrameBottomButton"])
	if stb then stb:SetAlpha(0) stb:EnableMouse(false) end
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
	if frame.Selection then frame.Selection:SetAlpha(0) end

	pcall(frame.SetFont, frame, S.media.font, db.fontSize or 12,
		db.fontOutline ~= "NONE" and db.fontOutline or "")
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

function Core.IsRightChat(frame)
	if not db.rightPanelEnable then return false end
	local fname = frame.GetName and frame:GetName()
	if not fname then return false end
	local tab = _G[fname .. "Tab"]
	local text = tab and (tab.Text or _G[tab:GetName() .. "Text"])
	local label = text and text:GetText()
	if not label or IsSecret(label) then return false end
	return label == LOOT or label == "Loot" or label == "Beute" or label == L["Right Chat"]
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
					if tab then
						tab:ClearAllPoints()
						tab:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 4)
					end
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
	tinsert(UISpecialFrames, "SentiUIEmojiPicker")
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

function Core.SetupSticky()
	if not db.stickyChat then return end
	for _, t in ipairs({ "SAY", "PARTY", "RAID", "GUILD", "OFFICER", "WHISPER", "BN_WHISPER",
		"CHANNEL", "INSTANCE_CHAT", "YELL" }) do
		if ChatTypeInfo and ChatTypeInfo[t] then ChatTypeInfo[t].sticky = 1 end
	end
end

function Core.UpdateKeywords()
	Core.keywords = {}
	for word in (db.keywords or ""):gmatch("[^,]+") do
		word = strtrim(word)
		if word == "%MYNAME%" then word = UnitName("player") or word end
		if word ~= "" then tinsert(Core.keywords, word) end
	end
end

-- enable / settings ----------------------------------------------------------------
function Core.Update()
	Core.UpdatePanels()
	Core.UpdateKeywords()
	Core.StyleVoiceStrip()
	for frame in pairs(Core.styled) do
		pcall(frame.SetFont, frame, S.media.font, db.fontSize,
			db.fontOutline ~= "NONE" and db.fontOutline or "")
		local canFade = db.fade and (frame.isDocked or db.fadeUndockedTabs)
		frame:SetFading(canFade and true or false)
		frame:SetTimeVisible(db.fadeTime)
		Core.PositionEditBox(frame)
		local tab = _G[frame:GetName() .. "Tab"]
		if tab then Core.StyleTab(tab) end
	end
	Core.PositionChat()
end

function Core.SettingChanged(mod, path)
	if not Core.enabled then return end
	if path == "stickyChat" then Core.SetupSticky() end
	if path == "classColorMentions" and db.classColorMentions then Core.SetupClassColors() end
	if path == "keywords" then Core.UpdateKeywords() return end
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
	S.SafeCall("chat:sticky", Core.SetupSticky)
	if db.timestamp ~= "NONE" and SetCVar then pcall(SetCVar, "showTimestamps", "none") end

	S.SafeCall("chat:position", Core.PositionChat)
	-- missing FCF_* globals must not take the module down
	local function SafeHook(name, fn)
		if type(_G[name]) == "function" then hooksecurefunc(name, fn) end
	end
	SafeHook("FCF_OpenTemporaryWindow", function()
		for _, name in ipairs(CHAT_FRAMES or {}) do Core.StyleChatFrame(_G[name]) end
	end)
	SafeHook("FCF_OpenNewWindow", function() Core.PositionChat() end)
	SafeHook("FCF_DockFrame", function() Core.UpdateTabColors() end)
	SafeHook("FCF_Tab_OnClick", function() Core.UpdateTabColors() end)
	SafeHook("FCFTab_UpdateColors", function() Core.UpdateTabColors() end)
	SafeHook("FCF_SetWindowName", function(_, frame)
		if Core.IsRightChat(frame) then Core.PositionChat() end
	end)
	-- the game re-anchors the edit box to the active chat frame on focus
	SafeHook("ChatEdit_SetLastActiveWindow", function(frame)
		if frame then Core.PositionEditBox(frame) end
	end)
	SafeHook("FCF_DockUpdate", function()
		for i = 1, (NUM_CHAT_WINDOWS or 10) do
			local f = _G["ChatFrame" .. i]
			if f then Core.PositionEditBox(f) end
		end
	end)

	S.RegisterEvent("UPDATE_CHAT_WINDOWS", Core.PositionChat)
	S.RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS", Core.PositionChat)
	S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(1, function() S.SafeCall("chat:pew", Core.PositionChat) end)
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
		for _, fn in ipairs({ "FCF_RestorePositionAndDimensions", "FCF_SetWindowPosition",
			"FCF_UpdateDockPosition", "FCF_DockUpdate", "FCF_UpdateChatWindows",
			"FloatingChatFrame_Update", "UIParent_ManageFramePositions",
			"UIParent_UpdateTopFramePositions" }) do
			if type(_G[fn]) == "function" then
				hooksecurefunc(fn, function() S.SafeCall("chat:snap", SnapChatFrame1) end)
			end
		end
	end

	-- the client re-anchors chat windows on level ups; burst-check briefly so
	-- any mover we did not hook still gets reverted before it can be seen
	S.RegisterEvent("PLAYER_LEVEL_UP", function()
		local n = 0
		local t
		t = C_Timer.NewTicker(0.1, function()
			n = n + 1
			S.SafeCall("chat:levelup", SnapChatFrame1)
			if n >= 15 then t:Cancel() end
		end)
		C_Timer.After(1.6, function() S.SafeCall("chat:levelup", Core.PositionChat) end)
	end)

	-- self-healing anchor watch: the client can re-anchor ChatFrame1 on
	-- window/dock updates at any time (level ups, FCF passes) - re-dock it
	-- into the panel whenever its first anchor no longer points there
	local watchAcc = 0
	local watch = CreateFrame("Frame")
	watch:SetScript("OnUpdate", function(_, e)
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
