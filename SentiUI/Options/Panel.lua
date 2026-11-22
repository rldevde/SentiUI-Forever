-- The settings window. Navigation on the left (sections, pages, search),
-- the current page on the right: header plus scrolling cards. Pages come
-- from the registry, so modules show up without window code here.
local _, S = ...
local Options, W = S.Options, S.Widgets
local L = S.L
local C = S.colors
local T = Options.Text

-- strtrim is not guaranteed on this client
local strtrim = strtrim or function(s) return (tostring(s):match("^%s*(.-)%s*$")) end

local Panel = {}
S.OptionsPanel = Panel

Panel.SIZE = { 940, 620 }
Panel.MIN = { 780, 520 }
Panel.NAV_W = 216
Panel.ROW_H = 26
Panel.MIN_QUERY = 2
Panel.CONTROL_W = 240  -- room kept on a row's right for its widget

local frame, navScroll, navChild, searchBox, contentScroll, contentChild
local headerTitle, headerSection, headerDesc, resetPage
local current -- the page table currently shown
local navButtons, navExtras, cardPool = {}, {}, {}
local refreshPending = false

-- ---------------------------------------------------------------------
-- Rows
-- ---------------------------------------------------------------------

local function fmtSlider(item, v)
	v = tonumber(v) or 0
	if item.unit == "%" then
		local p = (item.max and item.max <= 1) and v * 100 or v
		return string.format("%d%%", math.floor(p + 0.5))
	end
	local text
	if item.step and item.step >= 1 then
		text = string.format("%d", math.floor(v + 0.5))
	elseif item.step and item.step > 0 then
		text = string.format("%g", v)
	else
		text = string.format("%.2f", v)
	end
	if item.unit then text = text .. item.unit end
	return text
end

local KIND = { toggle = "check", slider = "slider", dropdown = "dropdown", color = "swatch", button = "btn", custom = "custom" }

local builders = {}

function builders.check(row, page, item)
	local cb = row.control
	if not cb then
		cb = W.Check(row)
		cb:SetPoint("RIGHT", -12, 0)
		row.control = cb
	end
	cb:SetChecked(Options.Get(page, item) and true or false)
	cb.onChanged = function(v) Options.Set(page, item, v) end
	cb:Show()
end

function builders.slider(row, page, item)
	local val = row.sideText
	if not val then
		val = S.Font(row, 11, C.textDim)
		val:SetPoint("RIGHT", -12, 0)
		val:SetWidth(56)
		val:SetJustifyH("RIGHT")
		row.sideText = val
	end
	val:SetText(fmtSlider(item, Options.Get(page, item)))
	val:Show()
	local sl = row.control
	if not sl then
		sl = W.Slider(row, item.min, item.max, item.step or 0)
		sl:SetPoint("RIGHT", -72, 0)
		sl:SetWidth(150)
		row.control = sl
	else
		sl:SetRange(item.min, item.max, item.step or 0)
	end
	sl:SetValue(tonumber(Options.Get(page, item)) or item.min, true)
	sl.onChanged = function(v, final)
		val:SetText(fmtSlider(item, v))
		Options.sliderHeld = not final
		Options.Set(page, item, v)
		if final then
			Options.sliderHeld = false
			Panel.Refresh()
		end
	end
	sl:Show()
end

function builders.dropdown(row, page, item)
	local dd = row.control
	if not dd then
		dd = W.Dropdown(row, 170)
		dd:SetPoint("RIGHT", -12, 0)
		row.control = dd
	end
	local values, order = item.values, item.order
	if item.choices then
		local ok, v, o = pcall(item.choices)
		if ok then values, order = v, o end
	end
	dd:SetOptions(values, order)
	dd:SetValue(Options.Get(page, item))
	dd.onPick = function(k)
		if Options.Set(page, item, k) then dd:SetValue(k) end
	end
	dd:Show()
end

function builders.color(row, page, item)
	local sw = row.control
	if not sw then
		sw = W.Swatch(row, item.alpha)
		sw:SetPoint("RIGHT", -12, 0)
		row.control = sw
	end
	local v = Options.Get(page, item)
	if type(v) == "table" then sw:SetColor(v[1] or v.r, v[2] or v.g, v[3] or v.b, v[4] or v.a) end
	sw.onChanged = function(r, g, b, a)
		Options.Set(page, item, { r, g, b, a })
	end
	sw:Show()
end

function builders.button(row, page, item)
	local b = row.control
	local caption = item.text
	if type(caption) == "function" then
		local ok, s = pcall(caption)
		caption = ok and s or nil
	end
	if not b then
		b = W.Button(row, "", 60, 20)
		b:SetPoint("RIGHT", -12, 0)
		row.control = b
	end
	b:SetText(T(caption or item.label))
	b:FitWidth(28)
	b:SetScript("OnClick", function()
		if item.confirm then
			Panel.pendingConfirm = item.func
			StaticPopup_Show("SENTIUI_CONFIRM")
		elseif item.func then
			-- unguarded clicks die silently into the error bag; a SafeCall
			-- puts the failure into chat where it can be seen
			S.SafeCall("button:" .. tostring(item.label or "?"), item.func)
		end
	end)
	b:Show()
end

function builders.custom(row, page, item)
	-- Custom rows build their own content once per item; different items never
	-- share a row (the page builder below only reuses a row whose item matches).
	if row.customItem == item then
		if item.update then pcall(item.update, row) end
		return
	end
	row.customItem = item
	if item.build then
		local ok, err = pcall(item.build, row)
		if not ok then S.Print(string.format("|cffff5555%s: %s|r", tostring(page.id), tostring(err))) end
	end
	row.update = item.update and function() pcall(item.update, row) end or nil
end

local function newRow(card)
	local row = CreateFrame("Frame", nil, card)
	row:SetHeight(Panel.ROW_H)
	row.label = S.Font(row, 11)
	row.hover = row:CreateTexture(nil, "BACKGROUND")
	row.hover:SetTexture(S.media.blank)
	row.hover:SetVertexColor(1, 1, 1, 0.04)
	row.hover:SetAllPoints()
	row.hover:Hide()
	row.free = true
	return row
end

-- Reuses a pooled row of the same card when its kind and item fit.
local function rowFor(card, page, item)
	local kind = KIND[item.type]
	local candidate
	for _, row in ipairs(card.rows) do
		if row.free and row.kind == kind then
			if kind ~= "custom" or row.customItem == nil or row.customItem == item then
				candidate = row
				break
			end
		end
	end
	if not candidate then
		candidate = newRow(card)
		candidate.kind = kind
		card.rows[#card.rows + 1] = candidate
	end
	candidate.free = nil
	return candidate
end

local function configureRow(row, card, page, item, w)
	row.item, row.page = item, page
	-- hide a control left over from another kind, plus any side text
	if row.control and row.kind ~= KIND[item.type] then row.control:Hide(); row.control = nil end
	if row.sideText and item.type ~= "slider" then row.sideText:Hide() end

	row.label:ClearAllPoints()
	row.label:SetPoint("LEFT", 10, 0)
	if item.type == "text" then
		-- explicit width + wrap: the row height is measured off the
		-- wrapped label later, so long changelog lines get real space
		row.label:SetWidth(math.max(10, w - 20))
		if row.label.SetWordWrap then
			pcall(row.label.SetWordWrap, row.label, true)
		end
		row.label:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b)
	else
		row.label:SetWidth(0)
		if row.label.SetWordWrap then
			pcall(row.label.SetWordWrap, row.label, false)
		end
		row.label:SetPoint("RIGHT", -Panel.CONTROL_W - 8, 0)
		row.label:SetTextColor(C.text.r, C.text.g, C.text.b)
	end
	row.label:SetText(Options.Label(item))

	if row.hoverTex then row.hoverTex:Hide() end

	local build = builders[item.type == "toggle" and "check" or item.type]
	if build then build(row, page, item) end

	local off = Options.IsDisabled(page, item)
	row:SetAlpha(off and 0.4 or 1)
	if row.control and row.control.EnableMouse then row.control:EnableMouse(not off) end

	if item.desc then
		row:EnableMouse(true)
		row:SetScript("OnEnter", function(f)
			f.hover:Show()
			GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
			GameTooltip:AddLine(Options.Label(item), C.text.r, C.text.g, C.text.b)
			GameTooltip:AddLine(T(item.desc), 1, 1, 1, true)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function(f) f.hover:Hide(); GameTooltip:Hide() end)
	else
		row:SetScript("OnEnter", function(f) f.hover:Show() end)
		row:SetScript("OnLeave", function(f) f.hover:Hide() end)
	end

	row:SetWidth(w)
end

-- ---------------------------------------------------------------------
-- Cards / page content
-- ---------------------------------------------------------------------

local function cardAt(i)
	local card = cardPool[i]
	if not card then
		card = S.Panel(contentChild, 10, 10, "raised")
		card.label = S.Font(card, 12, C.accent)
		card.label:SetPoint("TOPLEFT", 10, -8)
		card.desc = S.Font(card, 10, C.textDim)
		card.desc:SetPoint("TOPLEFT", card.label, "BOTTOMLEFT", 0, -3)
		card.desc:SetPoint("RIGHT", card, "RIGHT", -10, 0)
		card.rows = {}
		cardPool[i] = card
	end
	return card
end

local function buildPage()
	for _, card in ipairs(cardPool) do
		card:Hide()
		for _, row in ipairs(card.rows) do row:Hide(); row.free = true end
	end
	if not current then return end

	local w = math.max(300, contentScroll:GetWidth() - 10)
	local y = -4
	local ci = 0
	for _, group in ipairs(Options.Groups(current)) do
		ci = ci + 1
		local card = cardAt(ci)
		card:ClearAllPoints()
		card:SetPoint("TOPLEFT", 0, y)
		card:SetWidth(w)
		card.label:SetText(T(group.label or ""))
		if group.desc then
			card.desc:SetText(T(group.desc))
			card.desc:Show()
		else
			card.desc:Hide()
		end

		local ry = group.desc and -42 or -28
		for _, item in ipairs(group.items or {}) do
			if not Options.IsHidden(current, item) then
				local row = rowFor(card, current, item)
				configureRow(row, card, current, item, w)
				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", 0, ry)
				row.revealTop = y + ry
				row:Show()
				local h = item.type == "custom" and (item.height or Panel.ROW_H) or Panel.ROW_H
				if item.type == "text" then
					-- long changelog/info lines wrap onto several lines -
					-- measure the wrapped label so rows never overlap
					local okh, sh = pcall(row.label.GetStringHeight, row.label)
					if okh and type(sh) == "number" and not S.IsSecret(sh) and sh > 0 then
						h = math.max(h, sh + 12)
					end
				end
				row:SetHeight(h)
				ry = ry - h - 2
			end
		end
		card:SetHeight(math.max(34, -ry + 8))
		card:Show()
		y = y - card:GetHeight() - 8
	end
	contentChild:SetSize(w, -y + 4)
	local keep = math.min(contentScroll.offset or 0, math.max(0, -y - contentScroll:GetHeight()))
	contentScroll:Scroll(keep)
end

-- Flashes a row once so a search hit is easy to spot on the target page.
local function flashRow(row)
	if not row.flash then
		local t = row:CreateTexture(nil, "OVERLAY", nil, 2)
		t:SetTexture(S.media.blank)
		t:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 1)
		t:SetAllPoints()
		t:SetAlpha(0)
		local g = row:CreateAnimationGroup()
		local fadeIn = g:CreateAnimation("Alpha")
		fadeIn:SetTarget(t)
		fadeIn:SetFromAlpha(0)
		fadeIn:SetToAlpha(0.28)
		fadeIn:SetDuration(0.15)
		local fadeOut = g:CreateAnimation("Alpha")
		fadeOut:SetTarget(t)
		fadeOut:SetFromAlpha(0.28)
		fadeOut:SetToAlpha(0)
		fadeOut:SetDuration(1.4)
		fadeOut:SetStartDelay(0.2)
		row.flash, row.flashAnim = t, g
	end
	row.flashAnim:Stop()
	row.flashAnim:Play()
end

-- Opens a page, then scrolls the matching row into view and flashes it.
function Panel.Reveal(id, item)
	Panel.Show(id)
	if not item then return end
	for _, card in ipairs(cardPool) do
		if card:IsShown() then
			for _, row in ipairs(card.rows) do
				if row:IsShown() and not row.free and row.item == item then
					contentScroll:Scroll(math.max(0, -(row.revealTop or 0) - 24))
					flashRow(row)
					return
				end
			end
		end
	end
end

-- ---------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------

local function navButton(i)
	local b = navButtons[i]
	if b then return b end
	b = CreateFrame("Button", nil, navChild)
	b:SetHeight(22)
	b.text = S.Font(b, 11)
	b.text:SetPoint("LEFT", 18, 0)
	b.text:SetPoint("RIGHT", -4, 0)
	b.hl = b:CreateTexture(nil, "BACKGROUND")
	b.hl:SetTexture(S.media.blank)
	b.hl:SetVertexColor(1, 1, 1, 0.05)
	b.hl:SetAllPoints()
	b.hl:Hide()
	b.marker = b:CreateTexture(nil, "ARTWORK")
	b.marker:SetTexture(S.media.blank)
	b.marker:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 1)
	b.marker:SetPoint("TOPLEFT", 8, -4)
	b.marker:SetPoint("BOTTOMLEFT", 8, 4)
	b.marker:SetWidth(2)
	b.marker:Hide()
	b:SetScript("OnEnter", function(f)
		if f.page ~= current then f.hl:Show() end
	end)
	b:SetScript("OnLeave", function(f) f.hl:SetShown(f.page == current) end)
	b:SetScript("OnClick", function(f) Panel.Reveal(f.page.id, f.item) end)
	navButtons[i] = b
	return b
end

local function navExtra(i)
	local fs = navExtras[i]
	if not fs then
		fs = S.Font(navChild, 10, C.textDim)
		fs:SetHeight(18)
		navExtras[i] = fs
	end
	return fs
end

local function buildNav()
	for _, b in ipairs(navButtons) do b:Hide() end
	for _, e in ipairs(navExtras) do e:Hide() end
	local y, bi, ei = -2, 0, 0
	local navW = Panel.NAV_W - 14

	local query = strtrim(searchBox:GetText() or "")
	if #query >= Panel.MIN_QUERY then
		local head = navExtra(1); ei = 1
		head:ClearAllPoints()
		head:SetPoint("TOPLEFT", 6, y)
		head:SetText(string.upper(T("Results")))
		head:Show()
		y = y - 20
		local found = 0
		for _, page in Options.Pages() do
			for _, group in ipairs(Options.Groups(page)) do
				for _, item in ipairs(group.items or {}) do
					if found <= 40 and Options.Matches(page, group, item, query) then
						found = found + 1
						bi = bi + 1
						local b = navButton(bi)
						b.page = page
						b.item = item
						b.text:SetText(Options.Label(item) .. "  " .. S.DimText(T(page.label)))
						b:ClearAllPoints()
						b:SetPoint("TOPLEFT", 0, y)
						b:SetWidth(navW)
						b.marker:Hide()
						b:Show()
						y = y - 22
					end
				end
			end
		end
		head:SetText(string.upper(T("Results")) .. "  " .. S.DimText("(" .. found .. ")"))
		if found == 0 then
			ei = ei + 1
			local none = navExtra(ei)
			none:ClearAllPoints()
			none:SetPoint("TOPLEFT", 8, y)
			none:SetText(T("No results"))
			none:Show()
			y = y - 20
		end
	else
		for _, section in ipairs(Options.Sections()) do
			ei = ei + 1
			local head = navExtra(ei)
			head:ClearAllPoints()
			head:SetPoint("TOPLEFT", 6, y)
			head:SetText(string.upper(T(section.label)))
			head:Show()
			y = y - 20
			for _, page in ipairs(section.pages) do
				bi = bi + 1
				local b = navButton(bi)
				b.page = page
				b.item = nil
				b.text:SetText(T(page.label))
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", 0, y)
				b:SetWidth(navW)
				b.marker:SetShown(page == current)
				b.hl:SetShown(page == current)
				b:Show()
				y = y - 22
			end
			y = y - 6
		end
	end
	navChild:SetSize(navW, -y + 4)
	navScroll.UpdateBar()
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------

function Panel.Refresh()
	if refreshPending then return end
	refreshPending = true
	C_Timer.After(0, function()
		refreshPending = false
		if not frame or not frame:IsShown() then return end
		if current and not Options.GetPage(current.id) then
			current = nil
			for id in Options.Pages() do Panel.Show(id); return end
		end
		buildNav()
		buildPage()
	end)
end

function Panel.Show(id)
	local page = id and Options.GetPage(id)
	if page then current = page end
	if not frame then Panel.Build() end
	if not current then
		for pid in Options.Pages() do current = Options.GetPage(pid); break end
	end
	if current then
		headerTitle:SetText(T(current.label or ""))
		local secLabel = ""
		for _, s in ipairs(Options.Sections()) do
			if s.id == current.section then secLabel = T(s.label); break end
		end
		headerSection:SetText(secLabel)
		headerDesc:SetText(T(current.desc or ""))
		resetPage:Show()
		if current.onShow then S.SafeCall("page:" .. current.id, current.onShow, current) end
	end
	buildNav()
	buildPage()
	frame:Show()
end

function Panel.Hide()
	if frame then frame:Hide() end
end

function Panel.IsShown()
	return frame ~= nil and frame:IsShown() == true
end

function Panel.Toggle()
	if frame and frame:IsShown() then
		Panel.Hide()
	elseif current then
		Panel.Show(current.id)
	else
		Panel.Show()
	end
end

local function placeInner()
	local w, h = frame:GetSize()
	headerDesc:SetWidth(math.max(100, w - Panel.NAV_W - 120))
	navScroll:SetPoint("TOPLEFT", 10, -74)
	navScroll:SetSize(Panel.NAV_W, h - 84)
	contentScroll:ClearAllPoints()
	contentScroll:SetPoint("TOPLEFT", Panel.NAV_W + 18, -96)
	contentScroll:SetPoint("BOTTOMRIGHT", -12, 12)
end

function Panel.Build()
	if frame then return end
	frame = CreateFrame("Frame", "SentiUISettingsFrame", UIParent, "BackdropTemplate")
	if S.CombatDeferWindow then S:CombatDeferWindow(frame) end
	frame:SetSize(Panel.SIZE[1], Panel.SIZE[2])
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("HIGH")
	S.Template(frame, "panel")
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	if frame.SetResizable then
		frame:SetResizable(true)
		if frame.SetMinResize then frame:SetMinResize(Panel.MIN[1], Panel.MIN[2]) end
		if frame.SetMaxResize then frame:SetMaxResize(1400, 900) end
	end
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(f)
		-- drag by the title band only
		local y = select(2, GetCursorPosition()) / f:GetEffectiveScale()
		if y > f:GetTop() - 40 then f:StartMoving() end
	end)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	tinsert(UISpecialFrames, "SentiUISettingsFrame")

	-- title band
	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(22, 22)
	logo:SetPoint("TOPLEFT", 12, -9)
	logo:SetTexture(S.media.logo)
	local title = S.Font(frame, 14, C.accent)
	title:SetPoint("TOPLEFT", 40, -14)
	title:SetText("SentiUI")
	local subtitle = S.Font(frame, 11, C.textDim)
	subtitle:SetPoint("LEFT", title, "RIGHT", 8, 0)
	subtitle:SetText(L["Settings"])
	local close = W.Close(frame, function() Panel.Hide() end)
	close:SetPoint("TOPRIGHT", -10, -10)
	local rule = S.Line(frame, C.border, 1)
	rule:SetPoint("TOPLEFT", 0, -40)
	rule:SetPoint("TOPRIGHT", 0, -40)

	-- nav: search box + scrollable section tree
	searchBox = W.EditBox(frame, Panel.NAV_W, 22)
	searchBox.holder:SetPoint("TOPLEFT", 10, -48)
	searchBox.placeholder:SetText(L["Search settings..."])
	searchBox.onChanged = function() buildNav() end
	-- accent edge so the field reads as interactive
	local sbEdge = searchBox.holder:CreateTexture(nil, "ARTWORK")
	sbEdge:SetTexture(S.media.blank)
	sbEdge:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.9)
	sbEdge:SetPoint("TOPLEFT", 1, -1)
	sbEdge:SetPoint("BOTTOMLEFT", 1, 1)
	sbEdge:SetWidth(2)
	-- Enter jumps straight to the first result
	searchBox:SetScript("OnEnterPressed", function(f)
		f:ClearFocus()
		local b = navButtons[1]
		if b and b.item then Panel.Reveal(b.page.id, b.item) end
	end)

	navScroll, navChild = W.Scroll(frame)
	navScroll:SetPoint("TOPLEFT", 10, -74)

	-- vertical divider between nav and content
	local divider = S.Line(frame, C.border, 1)
	divider:SetPoint("TOPLEFT", Panel.NAV_W + 14, -46)
	divider:SetPoint("BOTTOMLEFT", Panel.NAV_W + 14, 10)
	divider:SetWidth(1)

	-- content header
	headerTitle = S.Font(frame, 15)
	headerTitle:SetPoint("TOPLEFT", Panel.NAV_W + 26, -52)
	headerSection = S.Font(frame, 11, C.textDim)
	headerSection:SetPoint("LEFT", headerTitle, "RIGHT", 10, -1)
	headerDesc = S.Font(frame, 10, C.textDim)
	headerDesc:SetPoint("TOPLEFT", headerTitle, "BOTTOMLEFT", 0, -4)
	resetPage = W.Button(frame, L["Reset page"], 90, 20)
	resetPage:SetPoint("TOPRIGHT", -14, -50)
	resetPage:SetScript("OnClick", function()
		if not current then return end
		Panel.pendingReset = current
		StaticPopup_Show("SENTIUI_RESET_PAGE")
	end)

	contentScroll, contentChild = W.Scroll(frame)

	-- resize grip, bottom right
	local grip = CreateFrame("Button", nil, frame)
	grip:SetSize(14, 14)
	grip:SetPoint("BOTTOMRIGHT", -2, 2)
	grip.tex = grip:CreateTexture(nil, "OVERLAY")
	grip.tex:SetAllPoints()
	grip.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetScript("OnMouseDown", function()
		frame:StartSizing("BOTTOMRIGHT")
		grip:SetScript("OnUpdate", function()
			if not IsMouseButtonDown("LeftButton") then
				frame:StopMovingOrSizing()
				grip:SetScript("OnUpdate", nil)
				placeInner()
				buildPage()
			end
		end)
	end)

	frame:SetScript("OnSizeChanged", placeInner)
	placeInner()
end

S.On("SettingChanged", function()
	if Options.sliderHeld then return end
	Panel.Refresh()
end)
S.On("OptionsChanged", Panel.Refresh)
S.On("MoversChanged", Panel.Refresh)

StaticPopupDialogs["SENTIUI_CONFIRM"] = {
	text = L["Are you sure?"],
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function()
		if Panel.pendingConfirm then Panel.pendingConfirm() end
		Panel.pendingConfirm = nil
	end,
	OnCancel = function() Panel.pendingConfirm = nil end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

StaticPopupDialogs["SENTIUI_RESET_PAGE"] = {
	text = L["Reset every setting on this page?"],
	button1 = YES or "Yes",
	button2 = NO or "No",
	OnAccept = function()
		if Panel.pendingReset then
			Options.ResetPage(Panel.pendingReset)
			Panel.pendingReset = nil
		end
	end,
	OnCancel = function() Panel.pendingReset = nil end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
