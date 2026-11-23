-- luacheck: read globals UIParent UISpecialFrames GameTooltip C_Timer GetServerTime
local _, ns = ...

-- Main window: dark Sentinel panel with a left sidebar (grouped nav
-- buttons, gold accent edge on the active one) and a content area on the
-- right. Pages register themselves with UI.RegisterPage and are built on
-- first show. Same layout as My-Social.
local UI = {}
ns.UI = UI

local L = ns.L
local W = ns.Widgets
local Store = ns.Store
local S = SentiUI

local FRAME_NAME = "SentiAccountInfoFrame"
local WIDTH, HEIGHT = 960, 620
local MIN_W, MIN_H = 760, 480
local MAX_W, MAX_H = 1600, 1200
local HEADER = 42
local SIDEBAR = 190
local STATUS_H = 22
local NAV_H = 30
local PORTRAIT = "Interface\\AddOns\\SentiUI_AccountInfo\\Media\\Logo.tga"
-- Delay that bundles bursts of data changes into one refresh.
local REFRESH_DELAY = 0.5

ns.dbDefaults.settings = {
	window = {},
	tab = 1,
}

-- Page icons in the sidebar, keyed by page index.
local PAGE_ICONS = {
	[1] = "Interface\\Icons\\INV_Misc_GroupLooking",
	[2] = "Interface\\Icons\\INV_Misc_Spyglass_03",
	[3] = "Interface\\Icons\\INV_Misc_Bag_10",
	[4] = "Interface\\Icons\\INV_Misc_Statue_02",
	[5] = "Interface\\Icons\\INV_Helmet_08",
	[6] = "Interface\\Icons\\INV_Letter_15",
	[7] = "Interface\\Icons\\INV_Misc_Wrench_01",
	[8] = "Interface\\Icons\\INV_Misc_Coin_02",
	[9] = "Interface\\Icons\\Trade_Engraving",
	[10] = "Interface\\Icons\\INV_Misc_Map_01",
}

local GROUPS = {
	{ header = "NAV_DATA", pages = { 1, 10, 2, 3, 4, 5, 8, 9 } },
	{ header = "NAV_SYSTEM", pages = { 6, 7 } },
}

local pageDefs = {}
local frame

-- builder(content) returns a page object with :Refresh() and optionally
-- :OnShow(); called once, on first show of the page.
function UI.RegisterPage(index, label, builder)
	pageDefs[index] = { label = label, builder = builder }
end

local function SavePosition()
	local point, _, relativePoint, x, y = frame:GetPoint()
	local saved = ns.db.settings.window
	saved.point, saved.relativePoint, saved.x, saved.y = point, relativePoint, x, y
	saved.width, saved.height = frame:GetSize()
end

local function RestorePosition()
	local saved = ns.db.settings.window
	frame:ClearAllPoints()
	if saved.point then
		frame:SetPoint(saved.point, UIParent, saved.relativePoint or saved.point, saved.x or 0, saved.y or 0)
	else
		frame:SetPoint("CENTER")
	end
end

function UI.UpdateStatus()
	if not frame then
		return
	end
	frame.statusLeft:SetText(L.CHARS_TOTAL:format(Store.CharCount())
		.. "    |cff339eff" .. L.CHARS_TOTAL_MONEY:format(Store.TotalMoney() > 0 and W.Money(Store.TotalMoney()) or "0") .. "|r")
	local own = Store.OwnKey()
	local char = own and ns.db.chars[own]
	if char and char.updated then
		frame.statusRight:SetText(L.STATUS_SCANNED:format(
			L.TIME_AGO:format(W.Duration(GetServerTime() - char.updated))))
	else
		frame.statusRight:SetText("")
	end
end

local function PaintNav()
	for index, button in pairs(frame.navButtons) do
		button:SetSelected(index == frame.selectedTab)
	end
end

local function SelectPage(index)
	if not pageDefs[index] then
		index = 1
	end
	ns.db.settings.tab = index
	for i, def in pairs(pageDefs) do
		local content = frame.contents[i]
		if i == index then
			if not def.object then
				def.object = def.builder(content)
			end
			content:Show()
			if def.object.OnShow then
				def.object:OnShow()
			end
			def.object:Refresh()
		else
			content:Hide()
		end
	end
	frame.selectedTab = index
	PaintNav()
	UI.UpdateStatus()
end

function UI.GetFrame()
	return frame
end

function UI.GetCurrentTab()
	local def = frame and pageDefs[frame.selectedTab]
	return def and def.object
end

local refreshTimer
local function RefreshSoon()
	if not frame or not frame:IsShown() or refreshTimer then
		return
	end
	refreshTimer = C_Timer.NewTimer(REFRESH_DELAY, function()
		refreshTimer = nil
		if frame:IsShown() then
			local page = UI.GetCurrentTab()
			if page then
				page:Refresh()
			end
			UI.UpdateStatus()
		end
	end)
end

--------------------------------------------------------------------------------
-- Frame
--------------------------------------------------------------------------------

local function CreateHeader()
	local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	header:SetPoint("TOPLEFT", 1, -1)
	header:SetPoint("TOPRIGHT", -1, -1)
	header:SetHeight(HEADER)
	header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	header:SetBackdropColor(W.BG_RAISED[1], W.BG_RAISED[2], W.BG_RAISED[3], 1)
	header:SetBackdropBorderColor(W.BORDER[1], W.BORDER[2], W.BORDER[3], 1)
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	header:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		SavePosition()
	end)

	local logo = header:CreateTexture(nil, "ARTWORK")
	logo:SetSize(24, 24)
	logo:SetPoint("LEFT", 12, 0)
	logo:SetTexture(PORTRAIT)

	local title = W.Text(header, "GameFontNormalLarge")
	title:SetPoint("LEFT", logo, "RIGHT", 10, 0)
	title:SetText("|cffebad33Senti|r|cffffffffAccountInfo|r")

	local subtitle = W.Text(header, "GameFontDisableSmall", W.MUTED)
	subtitle:SetPoint("LEFT", title, "RIGHT", 10, -2)
	subtitle:SetText("v" .. (ns.version or "?"))

	local close = W.CloseButton(header, 20)
	close:SetPoint("RIGHT", -8, 0)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)
end

local function CreateNavButton(index, parent, label)
	-- the shared Sentinel tab chip: blade + lit active, with the page icon
	local button = S.TabChip(parent, NAV_H)
	button:SetIcon(PAGE_ICONS[index])
	button:SetLabel(label)
	button:SetScript("OnClick", function()
		SelectPage(index)
	end)
	return button
end

local function CreateSidebar()
	local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	sidebar:SetPoint("TOPLEFT", 1, -(HEADER + 2))
	sidebar:SetPoint("BOTTOMLEFT", 1, 1)
	sidebar:SetWidth(SIDEBAR)
	sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	sidebar:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3], 0.9)
	sidebar:SetBackdropBorderColor(W.BORDER[1], W.BORDER[2], W.BORDER[3], 1)

	local scroll, child = W.ScrollArea(sidebar)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -9, 1)

	frame.navButtons = {}
	local y = -10
	for _, group in ipairs(GROUPS) do
		local header = W.Text(child, "GameFontDisableSmall", W.MUTED)
		header:SetPoint("TOPLEFT", 14, y - 6)
		header:SetText(L[group.header])
		y = y - 24
		for _, index in ipairs(group.pages) do
			local def = pageDefs[index]
			if def then
				local button = CreateNavButton(index, child, def.label)
				button:SetPoint("TOPLEFT", 4, y)
				button:SetPoint("TOPRIGHT", -4, y)
				frame.navButtons[index] = button
				y = y - NAV_H - 2
			end
		end
		y = y - 8
	end
	child:SetHeight(-y + 10)
end

local function Create()
	frame = W.Panel(UIParent)
	local saved = ns.db.settings.window
	frame:SetSize(
		math.max(MIN_W, math.min(MAX_W, saved.width or WIDTH)),
		math.max(MIN_H, math.min(MAX_H, saved.height or HEIGHT)))
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	-- Resizable window: the grip in the bottom-right drags the size,
	-- bounds are clamped so the layout never collapses.
	if frame.SetResizable then
		frame:SetResizable(true)
		if frame.SetResizeBounds then
			frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
		elseif frame.SetMinResize then
			frame:SetMinResize(MIN_W, MIN_H)
			frame:SetMaxResize(MAX_W, MAX_H)
		end
		local grip = CreateFrame("Button", nil, frame)
		grip:SetSize(16, 16)
		grip:SetPoint("BOTTOMRIGHT", -1, 1)
		grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
		grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
		grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
		grip:SetScript("OnMouseDown", function(_, button)
			if button == "LeftButton" then
				frame:StartSizing("BOTTOMRIGHT")
			end
		end)
		grip:SetScript("OnMouseUp", function()
			frame:StopMovingOrSizing()
			SavePosition()
		end)
		frame.resizeGrip = grip
	end
	_G[FRAME_NAME] = frame
	-- Escape closes the window - S.EscClosable, not UISpecialFrames: an
	-- addon-written entry taints the game's own Escape dispatch.
	if SentiUI and SentiUI.EscClosable then
		SentiUI.EscClosable(frame)
	end
	RestorePosition()

	CreateHeader()
	CreateSidebar()

	-- Content area right of the sidebar, above the status bar.
	frame.contents = {}
	for index in pairs(pageDefs) do
		local content = CreateFrame("Frame", nil, frame)
		content:SetPoint("TOPLEFT", SIDEBAR + 2, -(HEADER + 2))
		content:SetPoint("BOTTOMRIGHT", -1, STATUS_H + 2)
		content:Hide()
		frame.contents[index] = content
	end

	local statusBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	statusBar:SetPoint("BOTTOMLEFT", SIDEBAR + 2, 1)
	statusBar:SetPoint("BOTTOMRIGHT", -1, 1)
	statusBar:SetHeight(STATUS_H)
	statusBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
	statusBar:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3], 0.9)
	frame.statusLeft = W.Text(statusBar, "GameFontHighlightSmall", W.MUTED)
	frame.statusLeft:SetPoint("LEFT", 10, 0)
	frame.statusRight = W.Text(statusBar, "GameFontHighlightSmall", W.MUTED)
	frame.statusRight:SetPoint("RIGHT", -10, 0)

	frame:SetScript("OnShow", function()
		local page = UI.GetCurrentTab()
		if page then
			if page.OnShow then
				page:OnShow()
			end
			page:Refresh()
		end
		UI.UpdateStatus()
	end)
	local elapsed = 0
	frame:SetScript("OnUpdate", function(_, delta)
		elapsed = elapsed + delta
		if elapsed > 15 then
			elapsed = 0
			UI.UpdateStatus()
		end
	end)
	-- Resizing changes the usable width: let the current page re-layout
	-- (debounced through RefreshSoon so a drag does not rebuild rows
	-- every frame).
	frame:HookScript("OnSizeChanged", function()
		RefreshSoon()
	end)

	local savedTab = ns.db.settings.tab
	SelectPage(pageDefs[savedTab] and savedTab or 1)
end

function UI.Show(pageIndex)
	if not (ns.db and ns.enabled) then
		if ns.db then
			ns:Print(L["AccountInfo is disabled - enable it under SentiUI settings."])
		end
		return
	end
	if not frame then
		Create()
	end
	frame:Show()
	if pageIndex and pageDefs[pageIndex] then
		SelectPage(pageIndex)
	end
end

function UI.Hide()
	if frame then
		frame:Hide()
	end
end

function UI.Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		UI.Show()
	end
end

ns.defaultCommand = UI.Toggle

ns.RegisterCallback(UI, "SAI_CHARS_CHANGED", RefreshSoon)
