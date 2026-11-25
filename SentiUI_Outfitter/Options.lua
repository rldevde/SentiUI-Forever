local _, ns = ...
local S = ns.Outfitter
local L = S.L
local GOLD, BLUE, WHITE = S.GOLD, S.BLUE, S.WHITE
local BG, PANEL = { 0.055, 0.06, 0.075, 0.97 }, { 0.09, 0.10, 0.125, 1 }

local panel

local function Box(parent, bg, border)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
	f:SetBackdropColor(unpack(bg or BG))
	f:SetBackdropBorderColor(unpack(border or { 0.2, 0.22, 0.27, 1 }))
	return f
end

local function Label(parent, text, template, r, g, b)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
	fs:SetText(text or "")
	if r then fs:SetTextColor(r, g, b) end
	return fs
end

local function Button(parent, text, w, h, onClick)
	local b = Box(parent, PANEL)
	b:SetSize(w, h or 22)
	b:EnableMouse(true)
	b.text = Label(b, text, "GameFontHighlightSmall")
	b.text:SetPoint("LEFT", 6, 0)
	b.text:SetPoint("RIGHT", -6, 0)
	b.text:SetWordWrap(false)
	b.text:SetJustifyH("CENTER")
	b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(GOLD)) end)
	b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.2, 0.22, 0.27, 1) end)
	b:SetScript("OnMouseUp", function(self, btn) if btn == "LeftButton" and self:IsMouseOver() and onClick then onClick(self) end end)
	function b:SetText(t) self.text:SetText(t) end
	return b
end

-- ===================================================================
-- Setting rows
-- ===================================================================
local rows = {}

local function AddRow(y, text, controlW)
	local row = Box(panel, PANEL)
	row:SetPoint("TOPLEFT", 12, y)
	row:SetPoint("TOPRIGHT", -12, y)
	row:SetHeight(26)
	local lab = Label(row, text, "GameFontHighlightSmall")
	lab:SetPoint("LEFT", 8, 0)
	return row, lab
end

local function AddToggle(text, get, set)
	local y = -34 - (#rows) * 32
	local row = AddRow(y, text)
	local function setToggleColor(lbl, v)
		if v then lbl:SetTextColor(unpack(GOLD)) else lbl:SetTextColor(0.6, 0.6, 0.6) end
	end
	local b = Button(row, "", 70, 20, function(self)
		local v = not get()
		set(v)
		self.text:SetText(v and L["on"] or L["off"])
		setToggleColor(self.text, v)
		S:Refresh("bar")
	end)
	b:SetPoint("RIGHT", -8, 0)
	local v = get()
	b.text:SetText(v and L["on"] or L["off"])
	setToggleColor(b.text, v)
	rows[#rows + 1] = row
end

local function AddCycle(text, options, get, set)
	local y = -34 - (#rows) * 32
	local row = AddRow(y, text)
	local b = Button(row, "", 110, 20, function(self)
		local cur = get()
		local idx = 1
		for i, o in ipairs(options) do if o.value == cur then idx = i break end end
		idx = idx % #options + 1
		set(options[idx].value)
		self.text:SetText(options[idx].text)
		S:Refresh("bar")
	end)
	b:SetPoint("RIGHT", -8, 0)
	local cur = get()
	for _, o in ipairs(options) do if o.value == cur then b.text:SetText(o.text) break end end
	rows[#rows + 1] = row
end

local function AddNumber(text, get, set, min, max, step)
	local y = -34 - (#rows) * 32
	local row = AddRow(y, text)
	local function fmt(v) return string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "") end
	local minus = Button(row, "-", 22, 20, function()
		set(math.max(min, get() - step))
		row.eb:SetText(fmt(get()))
		S:Refresh("bar")
	end)
	minus:SetPoint("RIGHT", -96, 0)
	local plus = Button(row, "+", 22, 20, function()
		set(math.min(max, get() + step))
		row.eb:SetText(fmt(get()))
		S:Refresh("bar")
	end)
	plus:SetPoint("RIGHT", -70, 0)
	local eb = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
	eb:SetSize(48, 20)
	eb:SetPoint("RIGHT", -118, 0)
	eb:SetAutoFocus(false)
	eb:SetText(fmt(get()))
	eb:SetScript("OnEnterPressed", function(self)
		local v = tonumber(self:GetText())
		if v then set(math.min(max, math.max(min, v))) self:SetText(fmt(get())) S:Refresh("bar") end
		self:ClearFocus()
	end)
	eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	row.eb = eb
	rows[#rows + 1] = row
end

-- ===================================================================
-- Panel
-- ===================================================================
function S:ToggleOptions()
	if not panel then S:BuildOptions() end
	if panel:IsShown() then panel:Hide() else panel:Show() end
end

function S:BuildOptions()
	panel = Box(UIParent, BG, GOLD, "SentiUIOutfitterOptions")
	panel:SetSize(380, 420)
	panel:SetPoint("CENTER")
	panel:SetFrameStrata("FULLSCREEN_DIALOG")
	panel:EnableMouse(true)
	panel:SetMovable(true)
	panel:RegisterForDrag("LeftButton")
	panel:SetScript("OnDragStart", panel.StartMoving)
	panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

	local logo = panel:CreateTexture(nil, "ARTWORK")
	logo:SetSize(26, 26)
	logo:SetPoint("TOPLEFT", 10, -8)
	logo:SetTexture(S.LOGO or "Interface\\AddOns\\SentiUI_Outfitter\\Media\\Logo.tga")
	logo:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	local title = Label(panel, L["Settings"], "GameFontNormalLarge", unpack(GOLD))
	title:SetPoint("LEFT", logo, "RIGHT", 8, -1)

	local close = Button(panel, "X", 22, 20, function() panel:Hide() end)
	close:SetPoint("TOPRIGHT", -8, -8)
	close.text:SetTextColor(1, 0.4, 0.4)

	local db = S.db
	AddToggle(L["Show outfit bar"], function() return db.bar.enabled end, function(v) db.bar.enabled = v end)
	AddToggle(L["Open with character window"], function() return db.ui.followChar end, function(v) db.ui.followChar = v end)
	AddToggle(L["Mark outfit items in bags"], function() return db.ui.bagMarker ~= false end, function(v)
		db.ui.bagMarker = v
		if S.UpdateBadges then S:UpdateBadges() end
	end)
	AddToggle(L["Protect outfit items from selling"], function() return db.ui.protectSell ~= false end, function(v) db.ui.protectSell = v end)
	AddToggle(L["Show minimap button"], function() return not db.minimap.hide end, function(v)
		db.minimap.hide = not v
		if S.ApplyMinimapVisibility then S:ApplyMinimapVisibility() end
	end)
	AddCycle(L["Orientation"], {
		{ value = false, text = L["Horizontal"] },
		{ value = true,  text = L["Vertical"] },
	}, function() return db.bar.vertical end, function(v) db.bar.vertical = v end)
	AddToggle(L["Locked"], function() return db.bar.locked end, function(v) db.bar.locked = v end)
	AddToggle(L["Show names"], function() return db.bar.showNames end, function(v) db.bar.showNames = v end)
	AddNumber(L["Bar scale"], function() return db.bar.scale end, function(v) db.bar.scale = v end, 0.5, 2, 0.1)
	AddNumber(L["Alpha"], function() return db.bar.alpha end, function(v) db.bar.alpha = v end, 0.1, 1, 0.05)
	AddNumber(L["Combat alpha"], function() return db.bar.combatAlpha end, function(v) db.bar.combatAlpha = v end, 0.1, 1, 0.05)
	AddCycle(L["Tooltip display"], {
		{ value = "ALWAYS", text = L["Always"] },
		{ value = "OOC",    text = L["Out of combat only"] },
		{ value = "NEVER",  text = L["Never"] },
	}, function() return db.tooltip.mode end, function(v) db.tooltip.mode = v end)
	AddNumber(L["UI scale"], function() return db.ui.scale end, function(v)
		db.ui.scale = v
		-- apply to main window if open
		if SentiUIOutfitterFrame then SentiUIOutfitterFrame:SetScale(v) end
	end, 0.7, 1.5, 0.05)

	local reset = Button(panel, L["Reset position"], 160, 22, function()
		db.bar.position = nil
		S:ApplyBarLayout()
	end)
	reset:SetPoint("TOP", rows[#rows], "BOTTOM", 0, -8)
	-- fit the panel height to the rows so nothing overlaps
	panel:SetHeight(34 + #rows * 32 + 8 + 22 + 12)
end
