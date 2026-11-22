-- luacheck: read globals C_ClassColor C_Texture RAID_CLASS_COLORS GameTooltip math C_Timer
local _, ns = ...

-- Small widget kit for the window, same Sentinel look as My-Social.
local W = {}
ns.Widgets = W

-- Sentinel palette (same family as My-Social/SentinelPanel/SentinelLoot).
W.GOLD = { 0.92, 0.68, 0.20 } -- accent #EBAD33
W.ACCENT = W.GOLD
W.BLUE = { 0.20, 0.62, 1.00 } -- #339EFF
W.BG = { 0.043, 0.051, 0.071 } -- #0B0D12
W.BG_RAISED = { 0.075, 0.086, 0.114 } -- #13161D
W.BG_INSET = { 0.028, 0.033, 0.047 } -- #07090C
W.BORDER = { 0.133, 0.157, 0.220 } -- #222838
W.TEXT = { 0.92, 0.93, 0.96 }
W.WHITE = { 1, 1, 1 }
W.MUTED = { 0.55, 0.57, 0.64 }
W.GREEN = { 0.30, 0.85, 0.47 }
W.RED = { 0.90, 0.30, 0.30 }

local WHITE8 = "Interface\\Buttons\\WHITE8x8"
local BACKDROP = { bgFile = WHITE8, edgeFile = WHITE8, edgeSize = 1 }

local function Color(region, color, alpha)
	region:SetTextColor(color[1], color[2], color[3], alpha or 1)
end
W.Color = Color

-- Dark inset panel with a thin border.
function W.Panel(parent, bg, border)
	local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	panel:SetBackdrop(BACKDROP)
	bg = bg or { W.BG[1], W.BG[2], W.BG[3], 0.92 }
	border = border or { W.BORDER[1], W.BORDER[2], W.BORDER[3], 1 }
	panel:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
	panel:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
	return panel
end

function W.Text(parent, font, color)
	local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
	if color then
		Color(text, color)
	end
	text:SetJustifyH("LEFT")
	return text
end

-- Section heading in gold.
function W.Header(parent, label, font)
	local text = W.Text(parent, font or "GameFontNormal", W.GOLD)
	text:SetText(label)
	return text
end

function W.Button(parent, label, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetText(label)
	local fs = button:GetFontString()
	local natural = width
	if fs and not natural then
		fs:ClearAllPoints()
		fs:SetPoint("LEFT", 0, 0)
		natural = fs:GetStringWidth() + 30
	end
	button:SetSize(natural or 80, 24)
	if fs then
		fs:ClearAllPoints()
		fs:SetPoint("TOPLEFT", 8, 0)
		fs:SetPoint("BOTTOMRIGHT", -8, 0)
		fs:SetJustifyH("CENTER")
		fs:SetMaxLines(1)
	end
	if onClick then
		button:SetScript("OnClick", onClick)
	end
	return button
end

-- Small link-style text button.
function W.LinkButton(parent, label, onClick)
	local button = CreateFrame("Button", nil, parent)
	local text = W.Text(button, "GameFontDisableSmall")
	text:SetPoint("LEFT")
	button:SetFontString(text)
	button:SetNormalFontObject("GameFontDisableSmall")
	button:SetHighlightFontObject("GameFontHighlightSmall")
	button:SetText(label)
	button:SetSize(text:GetStringWidth() + 2, 16)
	button:SetScript("OnClick", onClick)
	local base = button.SetText
	function button:SetText(value)
		base(self, value)
		self:SetSize(math.max(16, text:GetStringWidth() + 2), 16)
	end
	return button
end

-- Single-line input. onChange(text) runs on user input.
function W.EditBox(parent, width, onChange)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width, 20)
	box:SetAutoFocus(false)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)
	box:SetScript("OnTextChanged", function(self, userInput)
		if userInput and onChange then
			onChange(self:GetText())
		end
	end)
	return box
end

-- Rounded-look search field with a magnifier and placeholder text.
function W.SearchBox(parent, width, placeholder, onChange)
	local box = CreateFrame("EditBox", nil, parent, "SearchBoxTemplate")
	box:SetSize(width, 22)
	box:SetAutoFocus(false)
	if box.Instructions then
		box.Instructions:SetText(placeholder)
		box.Instructions:SetWordWrap(false)
		box.Instructions:SetMaxLines(1)
		box.Instructions:SetJustifyH("LEFT")
		box.Instructions:ClearAllPoints()
		box.Instructions:SetPoint("LEFT", 20, 0)
		box.Instructions:SetWidth(math.max(20, width - 46))
	end
	box:HookScript("OnTextChanged", function(self, userInput)
		if userInput and onChange then
			onChange(self:GetText())
		end
	end)
	-- The clear button changes the text without userInput.
	if box.clearButton then
		box.clearButton:HookScript("OnClick", function()
			if onChange then
				onChange("")
			end
		end)
	end
	return box
end

-- Multi-line text field. The edit box is the child of a ScrollFrame so
-- long texts scroll with the wheel. :SetText / :GetText on the frame.
function W.TextArea(parent, width, height, onChange)
	local frame = W.Panel(parent, { 0, 0, 0, 1 }, { 0.133, 0.157, 0.22, 1 })
	frame:SetSize(width, height)

	local scroll = CreateFrame("ScrollFrame", nil, frame)
	scroll:SetPoint("TOPLEFT", 7, -6)
	scroll:SetPoint("BOTTOMRIGHT", -7, 6)

	local box = CreateFrame("EditBox", nil, scroll)
	box:SetMultiLine(true)
	box:SetAutoFocus(false)
	box:SetFontObject("ChatFontNormal")
	box:SetWidth(width - 14)
	scroll:SetScrollChild(box)
	box:SetScript("OnEscapePressed", box.ClearFocus)

	local function Wheel(self, delta)
		local range = scroll:GetVerticalScrollRange()
		scroll:SetVerticalScroll(math.max(0, math.min(range, scroll:GetVerticalScroll() - delta * 30)))
	end
	scroll:SetScript("OnMouseWheel", Wheel)
	box:SetScript("OnMouseWheel", Wheel)
	frame:EnableMouse(true)
	frame:SetScript("OnMouseDown", function()
		box:SetFocus()
	end)

	box:SetScript("OnTextChanged", function(self, userInput)
		scroll:UpdateScrollChildRect()
		if userInput and onChange then
			onChange(self:GetText())
		end
	end)
	-- The edit box follows the frame width so the whole widget can be
	-- edge-anchored (LEFT + RIGHT) inside resizable layouts.
	scroll:SetScript("OnSizeChanged", function(_, w)
		box:SetWidth(w)
	end)

	frame.editBox = box
	function frame:SetText(text)
		box:SetText(text or "")
	end
	function frame:GetText()
		return box:GetText()
	end
	return frame
end

-- Dropdown button. setup(root) fills the menu (MenuUtil descriptions).
function W.Menu(parent, width, setup)
	local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	dropdown:SetWidth(width)
	dropdown:SetupMenu(function(_, root)
		setup(root)
	end)
	function dropdown:Refresh()
		self:GenerateMenu()
	end
	return dropdown
end

-- Dropdown with radio entries: options = list or function returning
-- { value, label }; get() returns the selected value, set(value) stores it.
function W.Dropdown(parent, width, options, get, set)
	return W.Menu(parent, width, function(root)
		local list = type(options) == "function" and options() or options
		if #list > 20 and root.SetScrollMode then
			root:SetScrollMode(20 * 20)
		end
		for _, option in ipairs(list) do
			root:CreateRadio(option.label, function()
				return get() == option.value
			end, function()
				set(option.value)
			end)
		end
	end)
end

function W.Tooltip(frame, title, text)
	frame:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if title then
			GameTooltip:SetText(title, 1, 1, 1)
			if text then
				GameTooltip:AddLine(text, nil, nil, nil, true)
			end
		elseif text then
			GameTooltip:SetText(text, 1, 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	frame:HookScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

-- Scrollable area: ScrollFrame + scroll child + mouse wheel + a slim
-- scrollbar that only shows while the child is taller than the viewport.
-- Returns scroll, child — anchor children into child and give child an
-- explicit height (width follows the scroll frame automatically).
-- onResize(width) fires whenever the viewport width changes.
function W.ScrollArea(parent, onResize)
	local scroll = CreateFrame("ScrollFrame", nil, parent)
	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(1, 1)
	scroll:SetScrollChild(child)

	local bar = CreateFrame("Slider", nil, scroll)
	bar:SetWidth(7)
	bar:SetPoint("TOPRIGHT", -1, -2)
	bar:SetPoint("BOTTOMRIGHT", -1, 2)
	bar:SetOrientation("VERTICAL")
	bar:SetMinMaxValues(0, 0)
	bar:SetValueStep(32)
	bar.track = bar:CreateTexture(nil, "BACKGROUND")
	bar.track:SetAllPoints()
	bar.track:SetColorTexture(1, 1, 1, 0.05)
	bar:SetThumbTexture(WHITE8)
	bar.thumb = bar:GetThumbTexture()
	bar.thumb:SetSize(7, 40)
	bar.thumb:SetColorTexture(0.92, 0.68, 0.20, 0.5)
	bar:Hide()

	local function Range()
		local range = scroll:GetVerticalScrollRange()
		bar:SetMinMaxValues(0, range)
		bar:SetShown(range > 1)
	end
	scroll:SetScript("OnScrollRangeChanged", Range)
	scroll:SetScript("OnVerticalScroll", function(_, offset)
		bar:SetValue(offset)
	end)
	scroll:SetScript("OnSizeChanged", function(self, width)
		child:SetWidth(width)
		Range()
		if onResize then
			onResize(width)
		end
	end)
	scroll:SetScript("OnMouseWheel", function(_, delta)
		scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScrollRange(),
			scroll:GetVerticalScroll() - delta * 36)))
	end)
	bar:SetScript("OnValueChanged", function(_, value)
		scroll:SetVerticalScroll(value)
	end)
	child:SetScript("OnSizeChanged", function()
		scroll:UpdateScrollChildRect()
		Range()
	end)
	return scroll, child
end

-- Horizontal 1 px line.
function W.Divider(parent)
	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetHeight(1)
	line:SetColorTexture(0.133, 0.157, 0.22, 0.8)
	return line
end

-- Gold × close button, Sentinel style.
function W.CloseButton(parent, size)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	size = size or 20
	button:SetSize(size, size)
	button:SetBackdrop(BACKDROP)
	button:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3], 0.9)
	button:SetBackdropBorderColor(W.BORDER[1], W.BORDER[2], W.BORDER[3], 1)
	local text = W.Text(button, "GameFontHighlight", W.MUTED)
	text:SetPoint("CENTER", 0, 1)
	text:SetText("×")
	button.text = text
	button:SetScript("OnEnter", function()
		button:SetBackdropBorderColor(W.GOLD[1], W.GOLD[2], W.GOLD[3], 1)
		Color(text, W.GOLD)
	end)
	button:SetScript("OnLeave", function()
		button:SetBackdropBorderColor(W.BORDER[1], W.BORDER[2], W.BORDER[3], 1)
		Color(text, W.MUTED)
	end)
	return button
end

-- Checkbox with a label. :SetChecked(bool), onToggle(checked).
function W.Checkbox(parent, label, checked, onToggle)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(20, 20)
	local box = CreateFrame("Frame", nil, button, "BackdropTemplate")
	box:SetSize(16, 16)
	box:SetPoint("LEFT")
	box:SetBackdrop(BACKDROP)
	box:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3], 1)
	box:SetBackdropBorderColor(W.BORDER[1], W.BORDER[2], W.BORDER[3], 1)
	button.box = box
	local mark = box:CreateTexture(nil, "ARTWORK")
	mark:SetPoint("TOPLEFT", 2, -2)
	mark:SetPoint("BOTTOMRIGHT", -2, 2)
	mark:SetColorTexture(W.GOLD[1], W.GOLD[2], W.GOLD[3], 1)
	button.mark = mark
	local text = W.Text(button, "GameFontHighlight", W.TEXT)
	text:SetPoint("LEFT", box, "RIGHT", 8, 0)
	text:SetText(label or "")
	button.text = text
	button:SetWidth(20 + 8 + math.max(0, text:GetStringWidth()))
	function button:SetChecked(value)
		self.checked = value and true or false
		mark:SetShown(self.checked)
	end
	button:SetScript("OnClick", function()
		button:SetChecked(not button.checked)
		if onToggle then
			onToggle(button.checked)
		end
	end)
	button:SetChecked(checked)
	return button
end

--------------------------------------------------------------------------------
-- Colors and formatting
--------------------------------------------------------------------------------

function W.ClassColorHex(classFile)
	if C_ClassColor and C_ClassColor.GetClassColor then
		local color = C_ClassColor.GetClassColor(classFile)
		if color then
			return color:GenerateHexColor()
		end
	end
	local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
	return color and color.colorStr or "ffffffff"
end

-- "3 h", "2 d" for seconds.
function W.Duration(seconds)
	local L = ns.L
	seconds = math.max(0, seconds or 0)
	if seconds < 3600 then
		return L.DURATION_MINUTES:format(math.max(1, math.floor(seconds / 60)))
	elseif seconds < 86400 then
		return L.DURATION_HOURS:format(math.floor(seconds / 3600))
	end
	local days = math.floor(seconds / 86400)
	return (days == 1 and L.DURATION_DAY or L.DURATION_DAYS):format(days)
end

-- "12d 5h" / "5h 20m" / "20m" for long durations in seconds.
function W.Playtime(seconds)
	local L = ns.L
	seconds = math.max(0, math.floor(seconds or 0))
	local days = math.floor(seconds / 86400)
	local hours = math.floor(seconds / 3600) % 24
	local mins = math.floor(seconds / 60) % 60
	if days > 0 then
		return ("%dd %dh"):format(days, hours)
	elseif hours > 0 then
		return ("%dh %dm"):format(hours, mins)
	end
	return ("%dm"):format(mins)
end

local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:0:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:0:0|t"

-- "12g 34s 56c" with coin icons for a copper amount.
function W.Money(copper)
	copper = tonumber(copper) or 0
	local gold = math.floor(copper / 10000)
	local silver = math.floor(copper / 100) % 100
	local rest = copper % 100
	local out = {}
	if gold > 0 then
		out[#out + 1] = "|cffffd700" .. gold .. "|r" .. GOLD_ICON
	end
	if silver > 0 or gold > 0 then
		out[#out + 1] = "|cffc7c7cf" .. silver .. "|r" .. SILVER_ICON
	end
	out[#out + 1] = "|cffeda55f" .. rest .. "|r" .. COPPER_ICON
	return table.concat(out, " ")
end
