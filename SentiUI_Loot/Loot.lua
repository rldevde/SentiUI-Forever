-- SentiUI loot: instant fast loot, chat loot-spam filter, a persistent
-- loot log window and Sentinel skins for the loot window and the group
-- roll frames.
local _, ns = ...
local S = SentiUI
local L = ns.L
local IsSecret = S.IsSecret

local _G = _G
local ipairs, pairs, pcall, type = ipairs, pairs, pcall, type
local format, date, time = string.format, date, time
local tinsert, tremove = table.insert, table.remove

local ACCENT = S.colors.accent

local Core = {}
ns.Core = Core
local db

-- fast loot ----------------------------------------------------------------------
-- every slot the instant LOOT_READY fires, before the window renders;
-- respects the autoloot modifier/cvar unless "always" is set
local function OnLootReady(_, autoloot)
	if not db.fastLoot then return end
	local loot = db.fastLootAlways or autoloot
		or (GetCVarBool and GetCVarBool("autoLootDefault"))
	if not loot then return end
	for i = (GetNumLootItems and GetNumLootItems() or 0), 1, -1 do
		S.SafeCall("loot:slot", LootSlot, i)
	end
end

-- chat filter ----------------------------------------------------------------------
-- hides poor-quality drops and solo coin messages via the message filter
local function LootFilter(_, _, msg)
	if not db.filter then return false end
	if type(msg) ~= "string" or IsSecret(msg) then return false end
	local link = msg:match("|Hitem:.-|h%[.-%]|h")
	if not link then
		-- no item link: coin and loot system text
		return db.hideCoin or false
	end
	local q = GetItemInfo and select(3, GetItemInfo(link))
	if not q then
		-- item not cached: fall back to the link's quality color
		local hex = link:match("|c(%x%x%x%x%x%x%x%x)")
		if not hex then return false end
		hex = hex:upper()
		for i = 0, 7 do
			local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[i]
			local h = c and c.hex and (c.hex:gsub("^|[cC]", "")):upper()
			if h and h == hex then q = i break end
		end
	end
	if q then return q < (db.filterQuality or 0) end
	return false
end

-- loot log ----------------------------------------------------------------------
local MAX_ROWS, ROW_H = 14, 18
local frame, rows

local function Entries()
	SentiUIDB.lootHistory = SentiUIDB.lootHistory or {}
	return SentiUIDB.lootHistory
end

local function BuildFrame()
	if frame then return end
	frame = CreateFrame("Frame", "SentiUILootHistory", UIParent, "BackdropTemplate")
	S.EscClosable(frame)
	frame:SetSize(460, 310)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	S.Template(frame, "panel")
	local title = S.Font(frame, 13, ACCENT, "OUTLINE")
	title:SetPoint("TOP", 0, -10)
	title:SetText(L["Loot History"])
	local line = S.Line(frame, ACCENT)
	line:SetPoint("TOPLEFT", 10, -26)
	line:SetPoint("TOPRIGHT", -10, -26)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)
	local clear = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clear:SetSize(70, 18)
	clear:SetPoint("BOTTOMRIGHT", -10, 8)
	clear:SetText(L["Clear"])
	clear:SetScript("OnClick", function()
		wipe(Entries())
		frame.offset = 0
		Core.FillHistory()
	end)
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(self, delta)
		local max = math.max(0, #Entries() - MAX_ROWS)
		self.offset = math.max(0, math.min(max, (self.offset or 0) - delta))
		Core.FillHistory()
	end)
	rows = {}
	for i = 1, MAX_ROWS do
		local r = CreateFrame("Button", nil, frame)
		r:SetSize(430, ROW_H)
		r:SetPoint("TOPLEFT", 12, -34 - (i - 1) * ROW_H)
		r.text = S.Font(r, 10)
		r.text:SetPoint("LEFT", 4, 0)
		r.text:SetWidth(420)
		r.hl = r:CreateTexture(nil, "HIGHLIGHT")
		r.hl:SetAllPoints()
		r.hl:SetColorTexture(0.3, 0.3, 0.4, 0.4)
		r:SetScript("OnEnter", function(self)
			local link = self.link
			if link then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				pcall(GameTooltip.SetHyperlink, GameTooltip, link)
				GameTooltip:Show()
			end
		end)
		r:SetScript("OnLeave", function() GameTooltip:Hide() end)
		rows[i] = r
	end
	frame:Hide()
end

function Core.FillHistory()
	if not frame then return end
	local e = Entries()
	local off = frame.offset or 0
	for i, row in ipairs(rows) do
		local d = e[i + off]
		if d then
			row.text:SetText(format("|cff888888%s|r %s",
				date("%H:%M", d.t or 0), d.msg or ""))
			row.link = d.link
			row:Show()
		else
			row:Hide()
		end
	end
end

function Core.AddHistory(msg)
	local e = Entries()
	-- keep the first item hyperlink so rows show its tooltip on hover
	local link = msg:match("(|Hitem:.-|h%[.-%]|h)")
	tinsert(e, 1, { t = time(), msg = msg, link = link })
	local max = db.historySize or 200
	while #e > max do tremove(e) end
	if frame and frame:IsShown() then Core.FillHistory() end
end

function Core.ToggleHistory()
	BuildFrame()
	if frame:IsShown() then frame:Hide() else Core.FillHistory() frame:Show() end
end

local function OnLootMsg(_, msg)
	if not db.history then return end
	if type(msg) ~= "string" or IsSecret(msg) or not msg:find("Hitem") then return end
	Core.AddHistory(msg)
end

-- roll frames ----------------------------------------------------------------------
-- Sentinel look on the group loot frames: quality border on the icon and
-- tinted need/greed/pass/disenchant buttons
local ROLL_TINT = {
	need = { 0.10, 0.85, 0.40 },
	greed = { 0.90, 0.68, 0.20 },
	pass = { 0.90, 0.30, 0.30 },
	de = { 0.70, 0.40, 1.00 },
}

local function TintButton(btn, r, g, b)
	if not btn then return end
	if not btn.suiTint then
		local t = btn:CreateTexture(nil, "BACKGROUND")
		t:SetAllPoints()
		t:SetTexture("Interface\\Buttons\\WHITE8X8")
		btn.suiTint = t
	end
	if r then
		btn.suiTint:SetVertexColor(r, g, b, 0.30)
		btn.suiTint:Show()
	else
		btn.suiTint:Hide()
	end
end

local function QualityColor(quality)
	local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
	if c then return c.r, c.g, c.b end
	return 1, 1, 1
end

-- Where the roll frames actually live: classic GroupLootFrameN globals
-- plus, on this client, the frames managed by GroupLootContainer. The
-- container list is the reason the skin missed the visible frame.
local function EachRollFrame(fn)
	for i = 1, (NUM_GROUP_LOOT_FRAMES or 8) do
		local f = _G["GroupLootFrame" .. i]
		if f then fn(f) end
	end
	local c = _G.GroupLootContainer
	if type(c) ~= "table" then return end
	if type(c.rollFrames) == "table" then
		for _, f in pairs(c.rollFrames) do
			if type(f) == "table" then fn(f) end
		end
	end
	for _, f in ipairs({ c:GetChildren() }) do
		-- roll frames carry the roll buttons/icon frame; skip other children
		if type(f) == "table" and (f.IconFrame or f.LootButtonContainer or f.Timer) then
			fn(f)
		end
	end
end

-- Blizzard chrome sits on BACKGROUND and BORDER layers plus a few named
-- regions; the quality glow (the green box) is one of those textures.
local function StripRollChrome(f)
	for _, region in ipairs({ f:GetRegions() }) do
		if region:IsObjectType("Texture") then
			local layer = region:GetDrawLayer()
			if layer == "BACKGROUND" or layer == "BORDER" then
				region:SetTexture(nil)
			end
		end
	end
	for _, key in ipairs({ "Background", "Border", "NameFrame" }) do
		local r = f[key]
		if r and r.Hide then pcall(r.Hide, r) end
	end
end

-- roll buttons hang on the frame itself on older frames or inside
-- LootButtonContainer on newer ones
local function RollButtons(f)
	local box = f.LootButtonContainer
	local name = f.GetName and f:GetName()
	local function btn(k)
		return (type(box) == "table" and box[k]) or f[k] or (name and _G[name .. k])
	end
	return {
		need = btn("NeedButton"), greed = btn("GreedButton"),
		pass = btn("PassButton"), de = btn("DisenchantButton"),
		tmog = btn("TransmogButton"),
	}
end

local function StyleRollFrame(f)
	if not f or f.suiStyled then return end
	f.suiStyled = true
	StripRollChrome(f)
	if not f.SetBackdrop and BackdropTemplateMixin then Mixin(f, BackdropTemplateMixin) end
	S.Template(f, "raised")
	-- quality border around the item icon (the game's own border region
	-- on IconFrame stays hidden so only ours shows)
	local icon = f.IconFrame or _G[(f.GetName and f:GetName() or "") .. "IconFrame"]
	if icon then
		for _, key in ipairs({ "Border", "IconBorder" }) do
			if icon[key] and icon[key].Hide then pcall(icon[key].Hide, icon[key]) end
		end
		if not icon.suiBorder then
			local border = icon:CreateTexture(nil, "OVERLAY")
			border:SetPoint("TOPLEFT", -1, 1)
			border:SetPoint("BOTTOMRIGHT", 1, -1)
			border:SetColorTexture(1, 1, 1, 0.9)
			icon.suiBorder = border
		end
	end
	-- slim the countdown bar to an accent line at the bottom edge
	local timer = f.Timer
	if type(timer) == "table" and timer.SetStatusBarTexture then
		pcall(timer.SetStatusBarTexture, timer, "Interface\\Buttons\\WHITE8X8")
		pcall(timer.SetStatusBarColor, timer, ACCENT.r, ACCENT.g, ACCENT.b)
		pcall(timer.SetHeight, timer, 3)
	end
	-- Sentinel font + size on the item name
	local nameFS = f.Name
	if type(nameFS) == "table" and nameFS.SetTextColor then
		pcall(S.ApplyFont, nameFS, S.media.font, 11, "")
	end
end

local function UpdateRollFrame(f)
	if not f or type(f) ~= "table" then return end
	if f.IsForbidden and f:IsForbidden() then return end
	if not db.rollSkin then return end
	StyleRollFrame(f)
	local name = f.GetName and f:GetName()
	local icon = f.IconFrame or (name and _G[name .. "IconFrame"])
	local link = f.rollID and GetLootRollItemLink and GetLootRollItemLink(f.rollID)
	local quality = link and GetItemInfo and select(3, GetItemInfo(link))
	if icon and icon.suiBorder then
		if quality then
			icon.suiBorder:SetColorTexture(QualityColor(quality))
			icon.suiBorder:Show()
		else
			icon.suiBorder:Hide()
		end
	end
	local nameFS = f.Name
	if quality and type(nameFS) == "table" and nameFS.SetTextColor then
		nameFS:SetTextColor(QualityColor(quality))
	end
	local btns = RollButtons(f)
	TintButton(btns.need, unpack(ROLL_TINT.need))
	TintButton(btns.greed, unpack(ROLL_TINT.greed))
	TintButton(btns.pass, unpack(ROLL_TINT.pass))
	TintButton(btns.de, unpack(ROLL_TINT.de))
end

-- roll panel -------------------------------------------------------------------
-- the visible roll frames are re-homed into a Sentinel panel: one
-- deterministic column docked to the side of the loot window (the items),
-- scrollable once more rolls are active than fit
local rollPanel, rollScroll, rollChild
local ROLL_GAP, ROLL_VISIBLE = 6, 3

local function BuildRollPanel()
	if rollPanel then return end
	rollPanel = CreateFrame("Frame", "SentiUIRollPanel", UIParent,
		"BackdropTemplate")
	rollPanel:SetFrameStrata("HIGH")
	rollPanel:SetClampedToScreen(true)
	rollPanel:EnableMouse(true)
	S.Template(rollPanel, "panel")
	rollScroll = CreateFrame("ScrollFrame", nil, rollPanel,
		"UIPanelScrollFrameTemplate")
	rollScroll:SetPoint("TOPLEFT", 3, -3)
	rollScroll:SetPoint("BOTTOMRIGHT", -18, 3)
	rollChild = CreateFrame("Frame", nil, rollScroll)
	rollChild:SetSize(1, 1)
	rollScroll:SetScrollChild(rollChild)
	rollPanel:EnableMouseWheel(true)
	rollPanel:SetScript("OnMouseWheel", function(_, delta)
		local cur = rollScroll:GetVerticalScroll() or 0
		local max = math.max(0, (rollChild:GetHeight() or 0)
			- (rollScroll:GetHeight() or 0))
		rollScroll:SetVerticalScroll(
			math.max(0, math.min(max, cur - delta * 60)))
	end)
	rollPanel:Hide()
end

local function FrameDim(f, getter)
	local ok, v = pcall(getter, f)
	if ok and type(v) == "number" and not IsSecret(v) then return v end
	return 0
end

-- a docked roll card owns its row offset; any SetPoint from the game's
-- own container layout snaps back into our column
local function DockRollFrame(f, y)
	f.suiRow = y
	if f:GetParent() ~= rollChild then
		pcall(f.SetParent, f, rollChild)
	end
	if not f.suiDocked then
		f.suiDocked = true
		hooksecurefunc(f, "SetPoint", function(self)
			if self.suiFixing then return end
			self.suiFixing = true
			self:ClearAllPoints()
			self:SetPoint("TOPLEFT", rollChild, "TOPLEFT",
				0, -(self.suiRow or 0))
			self.suiFixing = nil
		end)
		-- wheel over a card scrolls the list too, not just the panel gaps
		pcall(f.EnableMouseWheel, f, true)
		f:HookScript("OnMouseWheel", function(_, delta)
			local wheel = rollPanel and rollPanel:GetScript("OnMouseWheel")
			if wheel then wheel(rollPanel, delta) end
		end)
	end
	f.suiFixing = true
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", rollChild, "TOPLEFT", 0, -y)
	f.suiFixing = nil
end

local function RollSortKey(f)
	local ok, id = pcall(function() return f.rollID end)
	if ok and not IsSecret(id) then return tonumber(id) or 0 end
	return 0
end

local rollList = {}
local function LayoutRollPanel()
	if not db.rollSkin then
		if rollPanel then rollPanel:Hide() end
		return
	end
	BuildRollPanel()
	wipe(rollList)
	EachRollFrame(function(f)
		if (not f.IsForbidden or not f:IsForbidden())
			and f.IsShown and f:IsShown() then
			rollList[#rollList + 1] = f
		end
	end)
	if #rollList == 0 then
		rollPanel:Hide()
		return
	end
	-- oldest roll on top so the order never jumps around
	table.sort(rollList, function(a, b)
		return RollSortKey(a) < RollSortKey(b)
	end)
	local w, h = 0, 0
	for _, f in ipairs(rollList) do
		local fw, fh = FrameDim(f, f.GetWidth), FrameDim(f, f.GetHeight)
		if fw > w then w = fw end
		if fh > h then h = fh end
	end
	if w <= 0 or h <= 0 then
		rollPanel:Hide()
		return
	end
	local y = 0
	for _, f in ipairs(rollList) do
		DockRollFrame(f, y)
		y = y + h + ROLL_GAP
	end
	rollChild:SetSize(w, y)
	local rows = math.min(#rollList, ROLL_VISIBLE)
	rollPanel:SetSize(w + 24, rows * (h + ROLL_GAP) - ROLL_GAP + 8)
	-- dock beside the items first (our loot window, else the game's);
	-- with no loot window up the roll mover's position is the fallback
	rollPanel:ClearAllPoints()
	local lw = _G.SentiUILootWindow
	if lw and lw:IsShown() then
		rollPanel:SetPoint("TOPLEFT", lw, "TOPRIGHT", 4, 0)
	elseif _G.LootFrame and _G.LootFrame:IsShown() then
		rollPanel:SetPoint("TOPLEFT", _G.LootFrame, "TOPRIGHT", 4, 0)
	elseif _G.GroupLootContainer then
		rollPanel:SetPoint("TOPLEFT", _G.GroupLootContainer, "TOPLEFT", 0, 0)
	else
		rollPanel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 14, 320)
	end
	rollPanel:Show()
end

local function UpdateRollFrames()
	EachRollFrame(function(f)
		if f.IsShown and f:IsShown() then UpdateRollFrame(f) end
	end)
	LayoutRollPanel()
end

-- loot window ----------------------------------------------------------------------
local function StyleLootButton(btn)
	if not btn or btn.suiStyled then return end
	btn.suiStyled = true
	local icon = btn.Icon or _G[(btn.GetName and btn:GetName() or "") .. "IconTexture"]
	if icon and not icon.suiBorder then
		local border = icon:CreateTexture(nil, "OVERLAY")
		border:SetPoint("TOPLEFT", -1, 1)
		border:SetPoint("BOTTOMRIGHT", 1, -1)
		border:SetColorTexture(1, 1, 1, 0.9)
		icon.suiBorder = border
	end
end

local function StyleLootFrame()
	local lf = _G.LootFrame
	if not lf or lf.suiStyled then return end
	lf.suiStyled = true
	for _, region in ipairs({ lf:GetRegions() }) do
		if region:IsObjectType("Texture") and region:GetDrawLayer() == "BACKGROUND" then
			region:SetTexture(nil)
		end
	end
	if not lf.SetBackdrop and BackdropTemplateMixin then Mixin(lf, BackdropTemplateMixin) end
	S.Template(lf, "panel")
	for i = 1, 8 do StyleLootButton(_G["LootButton" .. i]) end
end

local function UpdateLootFrame()
	if not db.lootSkin then return end
	StyleLootFrame()
	for i = 1, (LOOT_FRAME_NUM_BUTTONS or 4) do
		local btn = _G["LootButton" .. i]
		if btn and btn:IsShown() then
			local icon = btn.Icon or _G["LootButton" .. i .. "IconTexture"]
			local link = GetLootSlotLink and GetLootSlotLink(i)
			local quality = link and GetItemInfo and select(3, GetItemInfo(link))
			if not quality and GetLootSlotInfo then
				local _, _, _, q = GetLootSlotInfo(i)
				quality = q
			end
			if icon and icon.suiBorder then
				icon.suiBorder:SetColorTexture(QualityColor(quality or 1))
				icon.suiBorder:Show()
			end
		end
	end
end

-- own loot window -------------------------------------------------------------------
-- a Sentinel panel replacing the game's loot frame: icon with a quality
-- border, quality-colored name, count on the right, click to loot
local lootWin, lootRows = nil, {}
local LOOT_ROW_H, LOOT_ROWS_MAX = 22, 10

local function SlotData(i)
	-- GetLootSlotInfo's middle return is quality on item slots and a
	-- currency id on currency slots; the link's real quality wins anyway
	local icon, name, qty, quality, quest
	if GetLootSlotInfo then
		local ok, a, b, c, d, _, _, g = pcall(GetLootSlotInfo, i)
		if ok then
			icon, name, qty = a, b, c
			if type(d) == "number" then quality = d end
			quest = g
		end
	end
	local link = GetLootSlotLink and GetLootSlotLink(i)
	if link and GetItemInfo then
		local q = select(3, GetItemInfo(link))
		if type(q) == "number" then quality = q end
		if not icon then icon = select(10, GetItemInfo(link)) end
	end
	return icon, name, qty, quality, quest, link
end

local function LootRow(i)
	local r = lootRows[i]
	if r then return r end
	r = CreateFrame("Button", nil, lootWin)
	r:SetHeight(LOOT_ROW_H)
	S.Template(r, "inset")
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetPoint("LEFT", 4, 0)
	r.icon:SetSize(16, 16)
	r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	r.border = r:CreateTexture(nil, "OVERLAY")
	r.border:SetPoint("TOPLEFT", r.icon, -1, 1)
	r.border:SetPoint("BOTTOMRIGHT", r.icon, 1, -1)
	r.border:SetColorTexture(1, 1, 1, 0.9)
	r.name = S.Font(r, 11)
	r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
	r.name:SetJustifyH("LEFT")
	r.name:SetWidth(140)
	r.name:SetWordWrap(false)
	r.qty = S.Font(r, 10, S.colors.textDim)
	r.qty:SetPoint("RIGHT", -6, 0)
	r:SetScript("OnClick", function(self, btn)
		if self.slot and btn == "LeftButton" then
			pcall(LootSlot, self.slot)
		end
	end)
	r:SetScript("OnEnter", function(self)
		S.SetBorderLit(self, true)
		if self.slot then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local ok = pcall(GameTooltip.SetLootItem, GameTooltip, self.slot)
			if not ok and self.link then
				pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
			end
			GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", function(self)
		S.SetBorderLit(self, false)
		GameTooltip:Hide()
	end)
	lootRows[i] = r
	return r
end

local function BuildLootWindow()
	if lootWin then return end
	lootWin = CreateFrame("Frame", "SentiUILootWindow", UIParent, "BackdropTemplate")
	lootWin:SetSize(240, 60)
	lootWin:SetPoint("CENTER", 0, -40)
	lootWin:SetFrameStrata("HIGH")
	lootWin:SetToplevel(true)
	lootWin:EnableMouse(true)
	lootWin:SetMovable(true)
	lootWin:RegisterForDrag("LeftButton")
	lootWin:SetScript("OnDragStart", lootWin.StartMoving)
	lootWin:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		-- same store as the mover: nearest-anchor format + MoversChanged
		S.Movers.Save("loot.window")
	end)
	lootWin:Hide()
	S.Template(lootWin, "panel")
	local title = S.Font(lootWin, 12, ACCENT)
	title:SetPoint("TOP", 0, -8)
	title:SetText(LOOT or "Loot")
	local hairline = S.Line(lootWin, ACCENT)
	hairline:SetPoint("TOPLEFT", 10, -24)
	hairline:SetPoint("TOPRIGHT", -10, -24)
	local close = CreateFrame("Button", nil, lootWin, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function()
		pcall(CloseLoot)
		lootWin:Hide()
	end)
	S.Movers.Register(lootWin, "loot.window", L["Loot window"])
end

local function UpdateLootWindow()
	if not db.lootWindow then
		if lootWin then lootWin:Hide() end
		return
	end
	BuildLootWindow()
	local n = GetNumLootItems and GetNumLootItems() or 0
	if n == 0 then
		lootWin:Hide()
		return
	end
	lootWin:SetHeight(34 + math.min(n, LOOT_ROWS_MAX) * LOOT_ROW_H + 8)
	lootWin:Show()
	for i = 1, math.min(n, LOOT_ROWS_MAX) do
		local r = LootRow(i)
		r.slot = i
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", 6, -30 - (i - 1) * LOOT_ROW_H)
		r:SetPoint("TOPRIGHT", -6, -30 - (i - 1) * LOOT_ROW_H)
		local icon, name, qty, quality, quest, link = SlotData(i)
		r.link = link
		pcall(r.icon.SetTexture, r.icon, icon or "Interface\\Icons\\INV_Misc_QuestionMark")
		local r2, g2, b2 = QualityColor(quest and 1 or quality)
		r.border:SetColorTexture(r2, g2, b2)
		if name and not IsSecret(name) then
			r.name:SetText(name)
			if quest then
				r.name:SetTextColor(1, 0.82, 0)
			else
				r.name:SetTextColor(r2, g2, b2)
			end
		elseif link and not IsSecret(link) then
			r.name:SetText(link)
			r.name:SetTextColor(r2, g2, b2)
		end
		r.qty:SetText(type(qty) == "number" and qty > 1 and ("x" .. qty) or "")
		r:Show()
	end
	for i = n + 1, #lootRows do lootRows[i]:Hide() end
end

-- the game's loot frame is re-hidden via an OnShow hook in Core.Enable

-- loot feed -------------------------------------------------------------------------
-- recent own loot as small fading rows: the same item stacks, money pools
-- on one row, hover for the tooltip, right-click dismisses early. Self-loot
-- is matched through the game's own format strings so every language works.
local feed, feedRows, feedEntries = nil, {}, {}
local FEED_ROW_H, FEED_ICON = 20, 16

local function fmtPattern(fmt)
	if type(fmt) ~= "string" or IsSecret(fmt) then return nil end
	local p = fmt:gsub("%%", "\001")
	p = p:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	p = p:gsub("\001s", "(.-)"):gsub("\001d", "(%%d+)")
	return "^" .. p .. "$"
end

local itemPats, moneyPats
local function BuildFeedPatterns()
	itemPats = {}
	for _, g in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF",
		"LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF",
		"LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF" }) do
		local p = fmtPattern(_G[g])
		if p then itemPats[#itemPats + 1] = p end
	end
	moneyPats = {}
	for _, g in ipairs({ "YOU_LOOT_MONEY", "LOOT_MONEY_SPLIT" }) do
		local p = fmtPattern(_G[g])
		if p then moneyPats[#moneyPats + 1] = p end
	end
end

local function MoneyToCopper(text)
	-- "3 Gold, 45 Silver" -> copper, in any locale: the currency words are
	-- the GOLD/SILVER/COPPER globals
	local total, mul = 0, { [GOLD or "Gold"] = 10000, [SILVER or "Silver"] = 100, [COPPER or "Copper"] = 1 }
	for amt, cur in text:gmatch("(%d+)%s*([%aäöüÄÖÜ]+)") do
		if mul[cur] then total = total + tonumber(amt) * mul[cur] end
	end
	return total > 0 and total or nil
end

local function CopperText(copper)
	if GetCoinTextureString then
		local ok, s = pcall(GetCoinTextureString, copper)
		if ok and s then return s end
	end
	if GetMoneyString then
		local ok, s = pcall(GetMoneyString, copper, true)
		if ok and s then return s end
	end
	return nil
end

local function FeedRow(i)
	local r = feedRows[i]
	if r then return r end
	r = CreateFrame("Button", nil, feed)
	r:SetSize(240, FEED_ROW_H)
	S.Template(r, "inset")
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetPoint("LEFT", 3, 0)
	r.icon:SetSize(FEED_ICON, FEED_ICON)
	r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	r.border = r:CreateTexture(nil, "OVERLAY")
	r.border:SetPoint("TOPLEFT", r.icon, -1, 1)
	r.border:SetPoint("BOTTOMRIGHT", r.icon, 1, -1)
	r.border:SetColorTexture(1, 1, 1, 0.9)
	r.text = S.Font(r, 11)
	r.text:SetPoint("LEFT", r.icon, "RIGHT", 7, 0)
	r.text:SetWidth(165)
	r.text:SetJustifyH("LEFT")
	r.text:SetWordWrap(false)
	r.qty = S.Font(r, 10, ACCENT)
	r.qty:SetPoint("RIGHT", -5, 0)
	r:RegisterForClicks("RightButtonUp")
	r:SetScript("OnClick", function(self)
		local e = feedEntries[self.i]
		if e then e.fading, e.alpha = true, math.min(e.alpha or 1, 0.4) end
	end)
	r:SetScript("OnEnter", function(self)
		local e = feedEntries[self.i]
		if e and e.link then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
			GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	feedRows[i] = r
	return r
end

local function FeedLayout()
	local shown = 0
	for i, e in ipairs(feedEntries) do
		local r = FeedRow(i)
		r.i = i
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", feed, "TOPLEFT", 0, -(i - 1) * (FEED_ROW_H + 3))
		if e.money then
			r.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
			r.border:SetColorTexture(0.95, 0.80, 0.30)
			r.text:SetText(e.text or "")
			r.text:SetTextColor(0.95, 0.80, 0.30)
			r.qty:SetText("")
		else
			pcall(r.icon.SetTexture, r.icon, e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
			local r2, g2, b2 = QualityColor(e.quality)
			r.border:SetColorTexture(r2, g2, b2)
			r.text:SetText(e.name or "")
			r.text:SetTextColor(r2, g2, b2)
			r.qty:SetText(e.count > 1 and ("x" .. e.count) or "")
		end
		r:SetAlpha(e.alpha or 1)
		r:Show()
		shown = i
	end
	for i = shown + 1, #feedRows do feedRows[i]:Hide() end
	feed:SetHeight(math.max(1, shown * (FEED_ROW_H + 3)))
end

local function FeedPush(e)
	-- merge: same item stacks, money pools onto a single row
	for _, x in ipairs(feedEntries) do
		if (e.money and x.money) or (e.link and x.link == e.link) then
			if e.money then
				x.copper = (x.copper or 0) + (e.copper or 0)
				x.text = CopperText(x.copper) or e.text
			else
				x.count = x.count + e.count
			end
			x.t = GetTime()
			x.fading, x.alpha = false, 1
			FeedLayout()
			return
		end
	end
	tinsert(feedEntries, 1, e)
	while #feedEntries > (db.feedMax or 6) do tremove(feedEntries) end
	FeedLayout()
end

local function OnFeedLootMsg(_, msg)
	if not db.feed or not feed then return end
	if type(msg) ~= "string" or IsSecret(msg) then return end
	if not itemPats then BuildFeedPatterns() end
	for _, p in ipairs(itemPats) do
		if msg:match(p) then
			local link = msg:match("(|Hitem:.-|h%[.-%]|h)")
			if not link then return end
			local name = link:match("%[(.-)%]") or link
			local count = tonumber(msg:match("x(%d+)")) or 1
			local quality, icon
			if GetItemInfo then
				quality = select(3, GetItemInfo(link))
				icon = select(10, GetItemInfo(link))
			end
			FeedPush({ link = link, name = name, count = count,
				quality = quality, icon = icon, t = GetTime() })
			return
		end
	end
end

local function OnFeedMoneyMsg(_, msg)
	if not db.feed or not feed then return end
	if type(msg) ~= "string" or IsSecret(msg) then return end
	if not moneyPats then BuildFeedPatterns() end
	for _, p in ipairs(moneyPats) do
		local coins = msg:match(p)
		if coins then
			FeedPush({ money = true, copper = MoneyToCopper(coins),
				text = coins, t = GetTime() })
			return
		end
	end
end

local function BuildFeed()
	if feed then return end
	feed = CreateFrame("Frame", "SentiUILootFeed", UIParent)
	feed:SetSize(240, FEED_ROW_H)
	-- default: above the right chat panel; the mover takes it anywhere
	local rp = _G.SentiUIRightChatPanel
	if rp then
		feed:SetPoint("BOTTOMLEFT", rp, "TOPLEFT", 2, 30)
	else
		feed:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -40, 320)
	end
	feed:SetFrameStrata("MEDIUM")
	feed:EnableMouse(false) -- rows take the clicks
	S.Movers.Register(feed, "loot.feed", L["Loot feed"])
	feed:SetScript("OnUpdate", function(_, dt)
		local now, hold = GetTime(), db.feedHold or 4
		local dirty = false
		for i = #feedEntries, 1, -1 do
			local e = feedEntries[i]
			local row = feedRows[i]
			if e.fading then
				e.alpha = (e.alpha or 1) - (dt or 0.016) * 2
				if e.alpha <= 0 then
					tremove(feedEntries, i)
					dirty = true
				elseif row then
					row:SetAlpha(e.alpha)
				end
			elseif now - e.t > hold then
				-- rows under the mouse hold their fade so the tooltip stays
				if not (row and row:IsMouseOver()) then e.fading = true end
			end
		end
		if dirty then FeedLayout() end
	end)
	feed:SetShown(db.feed)
end

-- enable / settings ------------------------------------------------------------------
function Core.SettingChanged(mod, path)
	if not Core.enabled then return end
	if path == "lootSkin" then UpdateLootFrame() end
	if path == "rollSkin" then UpdateRollFrames() end
	if path == "lootWindow" then UpdateLootWindow() end
	if path == "feed" then
		BuildFeed()
		if feed then feed:SetShown(db.feed) end
	end
	if path == "feedMax" then
		while #feedEntries > (db.feedMax or 6) do tremove(feedEntries) end
		FeedLayout()
	end
end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db

	-- LOOT_* fires inside the client's loot-window dispatch; running our
	-- window update there taints the client's follow-up work in that same
	-- dispatch. Flag it and apply a frame later instead.
	local lootDirty
	local function QueueLootUpdate()
		if lootDirty then return end
		lootDirty = true
		C_Timer.After(0, function()
			lootDirty = nil
			S.SafeCall("loot:update", UpdateLootWindow)
		end)
	end
	S.RegisterEvent("LOOT_READY", function(_, autoloot)
		-- LootSlot inside the loot dispatch writes game state tainted;
		-- run the fast-loot pass on the next frame like the window update
		local arg = autoloot
		C_Timer.After(0, function()
			S.SafeCall("loot:ready", OnLootReady, nil, arg)
		end)
		QueueLootUpdate()
	end)
	for _, ev in ipairs({ "LOOT_OPENED", "LOOT_SLOT_CHANGED", "LOOT_SLOT_CLEARED" }) do
		S.RegisterEvent(ev, QueueLootUpdate)
	end
	S.RegisterEvent("LOOT_CLOSED", function()
		if lootWin and lootWin:IsShown() then lootWin:Hide() end
	end)

	-- the game's loot frame must stay out of the way while ours is
	-- enabled; re-skin and re-hide it whenever it shows.
	-- WatchShown, not OnShow: an insecure script on a client frame runs
	-- inside its show dispatch and taints the client's follow-up calls.
	local lf = _G.LootFrame
	if lf then
		S.WatchShown(lf, function(f)
			UpdateLootFrame()
			if db and db.lootWindow then f:Hide() end
		end)
	end

	-- loot feed: own item + money lines become fading rows
	BuildFeed()
	S.RegisterEvent("CHAT_MSG_LOOT", OnFeedLootMsg)
	S.RegisterEvent("CHAT_MSG_MONEY", OnFeedMoneyMsg)

	-- chat filter
	if ChatFrame_AddMessageEventFilter then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", LootFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_MONEY", LootFilter)
	end

	-- loot log
	S.RegisterEvent("CHAT_MSG_LOOT", OnLootMsg)
	SLASH_SENTILOOTLOG1 = "/slootlog"
	SLASH_SENTILOOTLOG2 = "/sll"
	SlashCmdList.SENTILOOTLOG = function() Core.ToggleHistory() end

	-- skins: restyle behind the game's own layout calls
	S.RegisterEvent("START_LOOT_ROLL", function()
		C_Timer.After(0.1, UpdateRollFrames)
	end)
	-- the container owns the visible frames on this client; its own
	-- add/update calls are the moment to skin them
	for _, fnName in ipairs({ "GroupLootContainer_AddFrame", "GroupLootContainer_Update" }) do
		if type(_G[fnName]) == "function" then
			hooksecurefunc(fnName, function() UpdateRollFrames() end)
		end
	end
	-- polling fallback while a roll frame is up (buttons appear per
	-- frame); it also keeps the panel docked and hides it when the
	-- last roll resolves
	local poll = CreateFrame("Frame")
	poll.elapsed = 0
	poll:SetScript("OnUpdate", function(self, dt)
		self.elapsed = self.elapsed + (dt or 0)
		if self.elapsed < 0.5 then return end
		self.elapsed = 0
		local any = false
		EachRollFrame(function(f)
			if f.IsShown and f:IsShown() then any = true end
		end)
		if any or (rollPanel and rollPanel:IsShown()) then
			UpdateRollFrames()
		end
	end)
end
