local _, ns = ...
local S = ns.Outfitter
local L = S.L
local GOLD, BLUE, WHITE = S.GOLD, S.BLUE, S.WHITE
local BG, PANEL = { 0.055, 0.06, 0.075, 0.97 }, { 0.09, 0.10, 0.125, 1 }

local QUALITY_COLORS = {
	[0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 }, [2] = { 0.12, 0.66, 0.12 },
	[3] = { 0.0, 0.44, 0.87 }, [4] = { 0.64, 0.21, 0.93 }, [5] = { 1.0, 0.5, 0.0 },
}

local QUALITY_HEX = {
	[0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd",
	[4] = "a335ee", [5] = "ff8000", [6] = "e6cc80", [7] = "00ccff",
}

-- ===================================================================
-- Widgets (SentiHeal look)
-- ===================================================================
local function Box(parent, bg, border, name)
	local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
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
	b:SetScript("OnMouseUp", function(self, btn) if btn == "LeftButton" and self:IsMouseOver() and not self.disabled and onClick then onClick(self) end end)
	function b:SetText(t) self.text:SetText(t) end
	function b:SetEnabled(en)
		self.disabled = not en
		self.text:SetAlpha(en and 1 or 0.4)
	end
	return b
end

-- ===================================================================
-- Prompt + confirm dialogs
-- ===================================================================
local prompt, confirmDlg, clickCatcher

local function ClosePopups()
	if prompt then prompt:Hide() end
	if confirmDlg then confirmDlg:Hide() end
	if S.iconPicker then S.iconPicker:Hide() end
	if S.slotPicker then S.slotPicker:Hide() end
	if S.ctxMenu then S.ctxMenu:Hide() end
	if clickCatcher then clickCatcher:Hide() end
end

-- invisible full-screen button just below the popup: any click outside
-- the popup closes it (dropdown behavior); ESC via UISpecialFrames
local function ShowClickCatcher(popup)
	if not clickCatcher then
		clickCatcher = CreateFrame("Button", nil, UIParent)
		clickCatcher:SetAllPoints(UIParent)
		clickCatcher:RegisterForClicks("AnyUp", "AnyDown")
		clickCatcher:SetScript("OnClick", ClosePopups)
	end
	clickCatcher:SetFrameStrata(popup:GetFrameStrata() or "FULLSCREEN_DIALOG")
	clickCatcher:SetFrameLevel(math.max(0, (popup:GetFrameLevel() or 1) - 1))
	clickCatcher:Show()
end

local function SetupPopup(f, name)
	if name and UISpecialFrames then tinsert(UISpecialFrames, name) end
	-- if the popup closes by itself (ESC), drop the catcher too
	f:HookScript("OnHide", function()
		if clickCatcher then clickCatcher:Hide() end
	end)
end

function S:Prompt(title, text, onAccept)
	ClosePopups()
	if not prompt then
		prompt = Box(UIParent, BG, GOLD, "SentiUIOutfitterPrompt")
		SetupPopup(prompt, "SentiUIOutfitterPrompt")
		prompt:SetSize(340, 110)
		prompt:SetPoint("CENTER")
		prompt:SetFrameStrata("FULLSCREEN_DIALOG")
		prompt:EnableMouse(true)
		prompt:SetMovable(true)
		prompt:RegisterForDrag("LeftButton")
		prompt:SetScript("OnDragStart", prompt.StartMoving)
		prompt:SetScript("OnDragStop", prompt.StopMovingOrSizing)
		prompt.title = Label(prompt, "", "GameFontNormal", unpack(GOLD))
		prompt.title:SetPoint("TOPLEFT", 12, -10)
		local eb = CreateFrame("EditBox", nil, prompt, "InputBoxTemplate")
		eb:SetSize(300, 22)
		eb:SetPoint("TOPLEFT", 18, -36)
		eb:SetAutoFocus(false)
		eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() prompt:Hide() end)
		eb:SetScript("OnEnterPressed", function(self)
			local fn = prompt.onAccept
			prompt:Hide()
			if fn then fn(self:GetText()) end
		end)
		prompt.eb = eb
		prompt.ok = Button(prompt, L["OK"], 80, 22, function()
			local fn = prompt.onAccept
			prompt:Hide()
			if fn then fn(prompt.eb:GetText()) end
		end)
		prompt.ok:SetPoint("BOTTOMRIGHT", -96, 10)
		prompt.cancel = Button(prompt, L["Cancel"], 80, 22, function() prompt:Hide() end)
		prompt.cancel:SetPoint("BOTTOMRIGHT", -10, 10)
	end
	prompt.title:SetText(title or "")
	prompt.onAccept = onAccept
	prompt.eb:SetText(text or "")
	prompt.eb:SetFocus()
	prompt.eb:HighlightText()
	prompt:Show()
	ShowClickCatcher(prompt)
end

function S:Confirm(title, text, onYes)
	ClosePopups()
	if not confirmDlg then
		confirmDlg = Box(UIParent, BG, GOLD, "SentiUIOutfitterConfirm")
		SetupPopup(confirmDlg, "SentiUIOutfitterConfirm")
		confirmDlg:SetSize(320, 100)
		confirmDlg:SetPoint("CENTER")
		confirmDlg:SetFrameStrata("FULLSCREEN_DIALOG")
		confirmDlg:EnableMouse(true)
		confirmDlg:SetMovable(true)
		confirmDlg:RegisterForDrag("LeftButton")
		confirmDlg:SetScript("OnDragStart", confirmDlg.StartMoving)
		confirmDlg:SetScript("OnDragStop", confirmDlg.StopMovingOrSizing)
		confirmDlg.title = Label(confirmDlg, "", "GameFontNormal", unpack(GOLD))
		confirmDlg.title:SetPoint("TOPLEFT", 12, -10)
		confirmDlg.msg = Label(confirmDlg, "", "GameFontHighlightSmall", 1, 1, 1)
		confirmDlg.msg:SetPoint("TOPLEFT", 12, -34)
		confirmDlg.msg:SetPoint("BOTTOMRIGHT", -12, 34)
		confirmDlg.msg:SetJustifyH("LEFT")
		confirmDlg.msg:SetWordWrap(true)
		confirmDlg.yes = Button(confirmDlg, L["OK"], 80, 22, function()
			local fn = confirmDlg.onYes
			confirmDlg:Hide()
			if fn then fn() end
		end)
		confirmDlg.yes:SetPoint("BOTTOMRIGHT", -96, 10)
		confirmDlg.no = Button(confirmDlg, L["Cancel"], 80, 22, function() confirmDlg:Hide() end)
		confirmDlg.no:SetPoint("BOTTOMRIGHT", -10, 10)
	end
	confirmDlg.title:SetText(title or "")
	confirmDlg.msg:SetText(text or "")
	confirmDlg.onYes = onYes
	confirmDlg:Show()
	ShowClickCatcher(confirmDlg)
end

-- ===================================================================
-- Context menu
-- ===================================================================
function S:OpenMenu(anchor, items)
	ClosePopups()
	if not S.ctxMenu then
		local m = Box(UIParent, BG, GOLD, "SentiUIOutfitterMenu")
		SetupPopup(m, "SentiUIOutfitterMenu")
		m:SetFrameStrata("FULLSCREEN_DIALOG")
		m:EnableMouse(true)
		-- gold accent line along the top edge
		m.topline = m:CreateTexture(nil, "OVERLAY")
		m.topline:SetPoint("TOPLEFT", 1, -1)
		m.topline:SetPoint("TOPRIGHT", -1, -1)
		m.topline:SetHeight(2)
		m.topline:SetTexture(WHITE)
		m.topline:SetColorTexture(unpack(GOLD))
		m.rows = {}
		for i = 1, 8 do
			local r = CreateFrame("Button", nil, m)
			r:SetSize(160, 20)
			r:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 22)
			r.hl = r:CreateTexture(nil, "HIGHLIGHT")
			r.hl:SetAllPoints()
			r.hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.25)
			r.text = Label(r, "", "GameFontHighlightSmall")
			r.text:SetPoint("LEFT", 6, 0)
			r.text:SetPoint("RIGHT", -6, 0)
			r.text:SetWordWrap(false)
			r:SetScript("OnClick", function(self)
				m:Hide()
				if self.fn then self.fn() end
			end)
			m.rows[i] = r
		end
		S.ctxMenu = m
	end
	local m = S.ctxMenu
	local w = 120
	for i, r in ipairs(m.rows) do
		local it = items[i]
		if it then
			r.text:SetText(it.text)
			r.fn = it.fn
			w = math.max(w, math.ceil(r.text:GetStringWidth() or 0) + 20)
			r:Show()
		else
			r:Hide()
		end
	end
	for _, r in ipairs(m.rows) do r:SetWidth(w - 8) end
	m:SetSize(w + 10, #items * 22 + 8)
	m:ClearAllPoints()
	m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	m:Show()
	-- keep the menu on screen when anchored on the right edge
	local right = m:GetRight()
	if right and right > GetScreenWidth() then
		m:ClearAllPoints()
		m:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
	end
	ShowClickCatcher(m)
end

-- ===================================================================
-- Icon picker popup: paged grid of valid icon fileIDs collected from
-- the outfit's items, equipped gear and bag contents (S:CollectIcons)
-- ===================================================================
local PICKER_COLS, PICKER_ROWS = 6, 5

function S:LayoutIconPicker()
	local p = S.iconPicker
	if not p then return end
	local perPage = PICKER_COLS * PICKER_ROWS
	local start = (p.offset or 0) * perPage
	for i, b in ipairs(p.buttons) do
		local icon = p.icons and p.icons[start + i]
		if icon then
			b.iconID = icon
			b.icon:SetTexture(icon)
			b.sel:SetShown(icon == p.current)
			b:Show()
		else
			b.iconID = nil
			b:Hide()
		end
	end
	local pages = math.max(1, math.ceil(#(p.icons or {}) / perPage))
	p.page:SetText(pages > 1 and (((p.offset or 0) + 1) .. "/" .. pages) or "")
end

function S:OpenIconPicker(current, onPick, setID)
	ClosePopups()
	if not S.iconPicker then
		local p = Box(UIParent, BG, GOLD, "SentiUIOutfitterIconPicker")
		SetupPopup(p, "SentiUIOutfitterIconPicker")
		p:SetFrameStrata("FULLSCREEN_DIALOG")
		p:SetSize(24 + PICKER_COLS * 40, 34 + PICKER_ROWS * 40 + 34)
		p:EnableMouse(true)
		p:SetMovable(true)
		p:RegisterForDrag("LeftButton")
		p:SetScript("OnDragStart", p.StartMoving)
		p:SetScript("OnDragStop", p.StopMovingOrSizing)
		p.title = Label(p, L["Choose icon"], "GameFontNormal", unpack(GOLD))
		p.title:SetPoint("TOPLEFT", 12, -10)
		p.page = Label(p, "", "GameFontHighlightSmall", 0.65, 0.65, 0.65)
		p.page:SetPoint("TOPRIGHT", -12, -12)
		p.buttons = {}
		for i = 1, PICKER_COLS * PICKER_ROWS do
			local b = CreateFrame("Button", nil, p)
			b:SetSize(34, 34)
			b:SetPoint("TOPLEFT", 12 + ((i - 1) % PICKER_COLS) * 40,
				-34 - math.floor((i - 1) / PICKER_COLS) * 40)
			b.icon = b:CreateTexture(nil, "ARTWORK")
			b.icon:SetAllPoints()
			b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
			b.sel = b:CreateTexture(nil, "OVERLAY")
			b.sel:SetAllPoints()
			b.sel:SetTexture(WHITE)
			b.sel:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.35)
			b.sel:Hide()
			b.hl = b:CreateTexture(nil, "HIGHLIGHT")
			b.hl:SetAllPoints()
			b.hl:SetColorTexture(BLUE[1], BLUE[2], BLUE[3], 0.25)
			b:RegisterForClicks("AnyUp")
			b:SetScript("OnClick", function(self)
				p:Hide()
				if p.onPick and self.iconID then p.onPick(self.iconID) end
			end)
			p.buttons[i] = b
		end
		p:EnableMouseWheel(true)
		p:SetScript("OnMouseWheel", function(_, d)
			local perPage = PICKER_COLS * PICKER_ROWS
			local pages = math.max(1, math.ceil(#(p.icons or {}) / perPage))
			p.offset = math.max(0, math.min(pages - 1, (p.offset or 0) - d))
			S:LayoutIconPicker()
		end)
		p.done = Button(p, L["Done"], 80, 20, function() p:Hide() end)
		p.done:SetPoint("BOTTOM", 0, 8)
		S.iconPicker = p
	end
	local p = S.iconPicker
	p.icons = S:CollectIcons(setID)
	p.current = current
	p.offset = 0
	p.onPick = onPick
	S:LayoutIconPicker()
	p:ClearAllPoints()
	p:SetPoint("CENTER")
	p:Show()
	ShowClickCatcher(p)
end

-- ===================================================================
-- Slot picker: choose which equipment slots an outfit stores
-- ===================================================================
local slotPicker
local pickerChecks = {}
local pickerRows = {}

function S:OpenSlotPicker(title, initial, onDone)
	ClosePopups()
	if not slotPicker then
		slotPicker = Box(UIParent, BG, GOLD, "SentiUIOutfitterSlotPicker")
		S.slotPicker = slotPicker
		SetupPopup(slotPicker, "SentiUIOutfitterSlotPicker")
		slotPicker:SetFrameStrata("FULLSCREEN_DIALOG")
		slotPicker:SetSize(300, 420)
		slotPicker:SetPoint("CENTER")
		slotPicker:EnableMouse(true)
		slotPicker:SetMovable(true)
		slotPicker:RegisterForDrag("LeftButton")
		slotPicker:SetScript("OnDragStart", slotPicker.StartMoving)
		slotPicker:SetScript("OnDragStop", slotPicker.StopMovingOrSizing)
		slotPicker.title = Label(slotPicker, "", "GameFontNormal", unpack(GOLD))
		slotPicker.title:SetPoint("TOPLEFT", 12, -10)
		slotPicker.hint = Label(slotPicker, L["Only selected slots are stored"], "GameFontHighlightSmall", 0.65, 0.65, 0.65)
		slotPicker.hint:SetPoint("TOPLEFT", 12, -30)

		pickerChecks = {}
		pickerRows = {}
		for i, s in ipairs(S.SLOTS) do
			local col = (i - 1) % 2
			local rowI = math.floor((i - 1) / 2)
			local r = CreateFrame("Button", nil, slotPicker)
			r:SetSize(136, 20)
			r:SetPoint("TOPLEFT", 12 + col * 142, -52 - rowI * 22)
			r.check = r:CreateTexture(nil, "ARTWORK")
			r.check:SetSize(14, 14)
			r.check:SetPoint("LEFT", 0, 0)
			r.check:SetTexture(WHITE)
			r.check:SetColorTexture(0.15, 0.16, 0.2, 1)
			r.checkEdge = r:CreateTexture(nil, "OVERLAY")
			r.checkEdge:SetAllPoints(r.check)
			r.checkEdge:SetTexture(WHITE)
			r.checkEdge:SetVertexColor(0.4, 0.42, 0.48, 1)
			r.mark = r:CreateTexture(nil, "ARTWORK")
			r.mark:SetSize(10, 10)
			r.mark:SetPoint("CENTER", r.check, "CENTER", 0, 0)
			r.mark:SetTexture(WHITE)
			r.mark:SetColorTexture(unpack(GOLD))
			r.mark:SetShown(false)
			r.label = Label(r, "", "GameFontHighlightSmall")
			r.label:SetPoint("LEFT", r.check, "RIGHT", 5, 0)
			r.label:SetPoint("RIGHT", -2, 0)
			r.label:SetJustifyH("LEFT")
			r:SetScript("OnClick", function(self)
				pickerChecks[self.slotName] = not pickerChecks[self.slotName]
				self.mark:SetShown(pickerChecks[self.slotName])
			end)
			pickerChecks[s.name] = true
			slotPicker[s.name] = r
			pickerRows[#pickerRows + 1] = r
		end

		slotPicker.all = Button(slotPicker, L["All slots"], 80, 20, function()
			for _, r in ipairs(pickerRows) do pickerChecks[r.slotName] = true r.mark:SetShown(true) end
		end)
		slotPicker.all:SetPoint("BOTTOMLEFT", 12, 46)
		slotPicker.none = Button(slotPicker, L["None"], 80, 20, function()
			for _, r in ipairs(pickerRows) do pickerChecks[r.slotName] = false r.mark:SetShown(false) end
		end)
		slotPicker.none:SetPoint("LEFT", slotPicker.all, "RIGHT", 6, 0)
		slotPicker.ok = Button(slotPicker, L["OK"], 80, 20, function()
			local fn = slotPicker.onDone
			slotPicker:Hide()
			if fn then fn(pickerChecks) end
		end)
		slotPicker.ok:SetPoint("BOTTOMRIGHT", -96, 12)
		slotPicker.cancel = Button(slotPicker, L["Cancel"], 80, 20, function() slotPicker:Hide() end)
		slotPicker.cancel:SetPoint("BOTTOMRIGHT", -10, 12)
	end

	slotPicker.title:SetText(title or L["Select slots to save"])
	for _, s in ipairs(S.SLOTS) do
		local r = slotPicker[s.name]
		if r then
			r.slotName = s.name
			local checked = initial and initial[s.name]
			if checked == nil then checked = true end
			pickerChecks[s.name] = checked
			r.mark:SetShown(checked)
			local link = S.Unsecret(GetInventoryItemLink("player", s.id))
			local iname = S:ItemName(link) or ""
			r.label:SetText(S:SlotLabel(s.name) .. (iname ~= "" and (" - " .. iname) or ""))
		end
	end
	slotPicker.onDone = onDone
	slotPicker:Show()
	ShowClickCatcher(slotPicker)
end

function S:WithSlotPick(title, initial, onDone)
	self:OpenSlotPicker(title, initial, function(checked)
		local include = {}
		for name, v in pairs(checked) do if v then include[name] = true end end
		onDone(include)
	end)
end

-- ===================================================================
-- Outfit list (Outfitter style: outfit rows with expandable item list)
-- ===================================================================
local frame, listBg, rows
local selectedSet
local expanded = {} -- setID -> bool
local flat = {}     -- flattened display items
local listOffset = 0
local autoShown = false
local userClosed = false
local charFrames = {}
local hooked = {}
local updatingScroll = false
local ROW_H = 20
local MAX_ROWS = 24
local LIST_TOP = 24

local function VisibleRows()
	if not listBg then return MAX_ROWS end
	return math.max(1, math.min(MAX_ROWS,
		math.floor((listBg:GetHeight() - LIST_TOP - 6) / ROW_H)))
end

local function BuildFlat()
	wipe(flat)
	local sets = S:GetSets()
	for _, set in ipairs(sets) do
		flat[#flat + 1] = { type = "outfit", set = set }
		if expanded[set.id] then
			local items = S:GetSetItems(set.id)
			for _, s in ipairs(S.SLOTS) do
				local it = items[s.name]
				if it and it.state ~= "empty" then
					flat[#flat + 1] = { type = "item", set = set, slot = s, item = it }
				end
			end
		end
	end
end

local function RefreshRow(row, entry)
	row.entry = entry
	row.hl:SetAlpha(0)
	row.expander:SetText("")
	row.check:Hide()
	row.check.mark:Hide()
	row.icon:Hide()
	row.text:SetText("")
	row.sub:SetText("")
	row.missing:Hide()
	row.arrow:Hide()
	row:Show()

	if entry.type == "outfit" then
		local set = entry.set
		row.expander:SetText(expanded[set.id] and "-" or "+")
		row.expander:SetTextColor(0.7, 0.7, 0.7)
		-- Outfitter style: gold-filled checkbox = outfit is worn right now
		row.check:Show()
		row.check.mark:SetShown(set.worn == true)
		row.icon:Show()
		row.icon:SetTexture(set.icon or S.DEFAULT_SET_ICON)
		row.icon:SetSize(16, 16)
		row.icon:ClearAllPoints()
		row.icon:SetPoint("LEFT", 34, 0)
		row.text:ClearAllPoints()
		row.text:SetPoint("LEFT", row.icon, "RIGHT", 5, 0)
		row.text:SetPoint("RIGHT", -20, 0)
		row.text:SetText(set.name)
		row.text:SetTextColor(1, 1, 1)
		local missing = set.missing
		if missing == nil then missing = S:SetHasMissing(set.id) end
		row.missing:SetShown(missing == true)
		if selectedSet and selectedSet.id == set.id then
			row.hl:SetAlpha(0.18)
			row.hl:SetColorTexture(unpack(GOLD))
		else
			row.hl:SetColorTexture(BLUE[1], BLUE[2], BLUE[3])
		end
		row.arrow:Show()
	elseif entry.type == "item" then
		local it = entry.item
		local q = QUALITY_COLORS[it.quality or 1] or { 1, 1, 1 }
		row.icon:Show()
		row.icon:SetTexture(it.icon or S.DEFAULT_SET_ICON)
		row.icon:SetSize(14, 14)
		row.icon:ClearAllPoints()
		row.icon:SetPoint("LEFT", 40, 0)
		row.text:ClearAllPoints()
		row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
		row.text:SetPoint("RIGHT", -20, 0)
		row.text:SetText(it.name or "?")
		row.text:SetTextColor(q[1], q[2], q[3])
		row.sub:SetText(S:SlotLabel(entry.slot.name))
		if it.state == "missing" then
			row.sub:SetTextColor(1, 0.3, 0.3)
		elseif it.state == "bank" then
			row.sub:SetTextColor(0.6, 0.5, 1)
		elseif it.state == "bags" then
			row.sub:SetTextColor(0.7, 0.7, 0.7)
		else
			row.sub:SetTextColor(0.4, 0.8, 0.4)
		end
	end
end

local function RefreshList()
	if not listBg then return end
	BuildFlat()
	local visible = VisibleRows()
	local maxOff = math.max(0, #flat - visible)
	listOffset = math.max(0, math.min(listOffset, maxOff))
	local sb = listBg.scrollbar
	if sb then
		updatingScroll = true
		sb:SetMinMaxValues(0, maxOff)
		sb:SetValue(listOffset)
		updatingScroll = false
		sb:SetShown(maxOff > 0)
	end
	listBg.empty:SetShown(#flat == 0)
	for i, r in ipairs(rows) do
		local e = (i <= visible) and flat[listOffset + i] or nil
		if e then RefreshRow(r, e) else r:Hide() end
	end
	listBg.count:SetText(#(S:GetSets()) .. " " .. L["Outfits"])
end
S.RefreshUI = RefreshList

local function SelectSet(set)
	selectedSet = set
	RefreshList()
end

local function ToggleExpand(set)
	expanded[set.id] = not expanded[set.id]
	RefreshList()
end

local function WearSet(set)
	S:WearSet(set.id)
	RefreshList()
end

local function NewOutfit()
	S:Prompt(L["New outfit"], "", function(name)
		name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then return end
		if S:FindSetID(name) then
			S:Print(L["Outfit"] .. " '" .. name .. "' " .. L["already exists"])
			return
		end
		S:WithSlotPick(L["New outfit"] .. ": " .. name, nil, function(include)
			local id, err = S:SaveCurrentGear(name, nil, include)
			if id then
				S:Print(L["Outfit saved"] .. ": " .. name)
				S:RefreshSets()
				for _, set in ipairs(S:GetSets()) do
					if set.id == id then SelectSet(set) break end
				end
			elseif err == "full" then
				S:Print(L["Maximum number of equipment sets reached"])
			else
				S:Print(tostring(err))
			end
		end)
	end)
end

function S:OutfitMenu(anchor, set)
	if not set then return end
	S:OpenMenu(anchor, {
		{ text = L["Wear"], fn = function() S:WearSet(set.id) S:RefreshSets() end },
		{ text = L["Update with current gear"], fn = function()
			local ignored = S:GetIgnoredSlots(set.id)
			local initial = {}
			for _, s in ipairs(S.SLOTS) do initial[s.name] = not (s.id and ignored[s.id]) end
			S:WithSlotPick(L["Update"] .. ": " .. set.name, initial, function(include)
				S:UpdateSetFromCurrent(set.id, include)
				S:Print(L["Outfit updated"] .. ": " .. set.name)
				S:RefreshSets()
			end)
		end },
		{ text = L["Rename"], fn = function()
			S:Prompt(L["Rename"], set.name, function(name)
				name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
				if name ~= "" and name ~= set.name then
					S:RenameSet(set.id, name)
					S:Print(L["Outfit renamed"] .. ": " .. name)
					S:RefreshSets()
				end
			end)
		end },
		{ text = L["Icon"], fn = function()
			S:OpenIconPicker(set.icon, function(icon)
				S:SetSetIcon(set.id, icon)
				S:RefreshSets()
			end, set.id)
		end },
		{ text = L["Delete"], fn = function()
			S:Confirm(L["Delete"], set.name .. "?", function()
				S:DeleteSet(set.id)
				if selectedSet and selectedSet.id == set.id then selectedSet = nil end
				S:Print(L["Outfit deleted"] .. ": " .. set.name)
				S:RefreshSets()
			end)
		end },
	})
end

local function OutfitMenu(row)
	if row.entry then S:OutfitMenu(row, row.entry.set) end
end

local function OnRowClick(row, btn)
	local e = row.entry
	if not e then return end
	if e.type == "outfit" then
		local set = e.set
		if btn == "RightButton" then
			OutfitMenu(row)
		else
			-- left click: select + wear (Outfitter checkmark style)
			SelectSet(set)
			WearSet(set)
		end
	else
		-- item row: show item tooltip via shift? just select parent
		SelectSet(e.set)
	end
end

local function OnExpandClick(row)
	local e = row.entry
	if e and e.type == "outfit" then ToggleExpand(e.set) end
end

-- ===================================================================
-- Build
-- ===================================================================
function S:InitUI()
	if frame then return end
	S:InitSlots()

	frame = Box(UIParent, BG, GOLD, "SentiUIOutfitterFrame")
	frame:SetSize(250, 460)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("MEDIUM")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetScale(S.db.ui.scale or 1)
	frame:SetShown(false)
	frame:HookScript("OnHide", function()
		if autoShown then
			autoShown = false
			userClosed = true
		end
		ClosePopups()
	end)

	-- title
	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(20, 20)
	logo:SetPoint("TOPLEFT", 10, -8)
	logo:SetTexture(S.LOGO or "Interface\\AddOns\\SentiUI_Outfitter\\Media\\Logo.tga")
	logo:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	local title = Label(frame, "|cffebad33SentiUI Outfitter|r", "GameFontNormal", unpack(GOLD))
	title:SetPoint("LEFT", logo, "RIGHT", 6, -1)

	local close = Button(frame, "X", 22, 20, function() frame:Hide() end)
	close:SetPoint("TOPRIGHT", -8, -8)
	close.text:SetTextColor(1, 0.4, 0.4)

	-- list background
	listBg = Box(frame, { 0.04, 0.045, 0.06, 1 }, { 0.16, 0.18, 0.22, 1 })
	listBg:SetPoint("TOPLEFT", 8, -34)
	listBg:SetPoint("BOTTOMRIGHT", -8, 40)
	if listBg.SetClipsChildren then listBg:SetClipsChildren(true) end
	frame.listBg = listBg

	listBg.count = Label(listBg, "", "GameFontHighlightSmall", unpack(GOLD))
	listBg.count:SetPoint("TOPLEFT", 8, -6)

	listBg.empty = Label(listBg, L["No outfits yet - save your current gear to create one"], "GameFontHighlightSmall", 0.7, 0.7, 0.7)
	listBg.empty:SetPoint("TOPLEFT", 8, -26)
	listBg.empty:SetPoint("TOPRIGHT", -8, -26)
	listBg.empty:SetJustifyH("LEFT")
	listBg.empty:SetWordWrap(true)

	-- rows: expander / worn-checkbox / icon / name / menu arrow (Outfitter style)
	rows = {}
	for i = 1, MAX_ROWS do
		local r = CreateFrame("Button", nil, listBg)
		r:SetPoint("TOPLEFT", 6, -LIST_TOP - (i - 1) * ROW_H)
		r:SetPoint("TOPRIGHT", -14, -LIST_TOP - (i - 1) * ROW_H)
		r:SetHeight(ROW_H)
		r:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		r.hl = r:CreateTexture(nil, "BACKGROUND")
		r.hl:SetAllPoints()
		r.hl:SetColorTexture(BLUE[1], BLUE[2], BLUE[3])
		r.hl:SetAlpha(0)

		r.hover = r:CreateTexture(nil, "HIGHLIGHT")
		r.hover:SetAllPoints()
		r.hover:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.10)

		r.expanderBtn = CreateFrame("Button", nil, r)
		r.expanderBtn:SetSize(16, ROW_H)
		r.expanderBtn:SetPoint("LEFT", 0, 0)
		r.expander = r.expanderBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		r.expander:SetAllPoints()
		r.expander:SetJustifyH("CENTER")
		r.expanderBtn:SetScript("OnClick", function() OnExpandClick(r) end)

		r.check = CreateFrame("Button", nil, r, "BackdropTemplate")
		r.check:SetSize(12, 12)
		r.check:SetPoint("LEFT", 18, 0)
		r.check:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
		r.check:SetBackdropColor(0.13, 0.14, 0.18, 1)
		r.check:SetBackdropBorderColor(0.4, 0.42, 0.48, 1)
		r.check:RegisterForClicks("LeftButtonUp")
		r.check.mark = r.check:CreateTexture(nil, "OVERLAY")
		r.check.mark:SetPoint("TOPLEFT", 2, -2)
		r.check.mark:SetPoint("BOTTOMRIGHT", -2, 2)
		r.check.mark:SetTexture(WHITE)
		r.check.mark:SetColorTexture(unpack(GOLD))
		r.check.mark:Hide()
		r.check:SetScript("OnClick", function()
			local e = r.entry
			if e and e.type == "outfit" then WearSet(e.set) end
		end)
		r.check:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Click to wear this outfit"], unpack(GOLD))
			GameTooltip:Show()
		end)
		r.check:SetScript("OnLeave", function() GameTooltip:Hide() end)

		r.icon = r:CreateTexture(nil, "ARTWORK")
		r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

		r.text = Label(r, "", "GameFontHighlightSmall")
		r.text:SetJustifyH("LEFT")

		r.sub = Label(r, "", "GameFontHighlightSmall")
		r.sub:SetPoint("RIGHT", -4, 0)
		r.sub:SetJustifyH("RIGHT")

		r.missing = Label(r, "!", "GameFontNormal", 1, 0.3, 0.3)
		r.missing:Hide()

		r.arrow = CreateFrame("Button", nil, r)
		r.arrow:SetSize(16, ROW_H)
		r.arrow:SetPoint("RIGHT", -1, 0)
		r.arrowText = Label(r.arrow, "v", "GameFontHighlightSmall", unpack(GOLD))
		r.arrowText:SetPoint("CENTER", 0, -1)
		r.arrow.hl = r.arrow:CreateTexture(nil, "HIGHLIGHT")
		r.arrow.hl:SetAllPoints()
		r.arrow.hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.25)
		r.arrow:SetScript("OnClick", function()
			local e = r.entry
			if e and e.type == "outfit" then S:OutfitMenu(r.arrow, e.set) end
		end)
		r.missing:SetPoint("RIGHT", r.arrow, "LEFT", -2, 0)

		r:SetScript("OnClick", function(self, btn) OnRowClick(self, btn) end)

		r:SetScript("OnEnter", function(self)
			local e = self.entry
			if not e then return end
			if e.type == "outfit" then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(e.set.name, unpack(GOLD))
				GameTooltip:AddLine(L["Click to wear this outfit"], 0.7, 0.7, 0.7)
				GameTooltip:AddLine(L["Right-click for options"], 0.7, 0.7, 0.7)
				GameTooltip:Show()
			elseif e.type == "item" and e.item.link then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetHyperlink(e.item.link)
				GameTooltip:Show()
			end
		end)
		r:SetScript("OnLeave", function() GameTooltip:Hide() end)

		rows[i] = r
	end

	listBg:EnableMouseWheel(true)
	listBg:SetScript("OnMouseWheel", function(_, d)
		listOffset = math.max(0, math.min(#flat - 1, listOffset - d * 3))
		RefreshList()
	end)

	-- thin scrollbar on the right edge (Outfitter style)
	local sb = CreateFrame("Slider", nil, listBg)
	sb:SetPoint("TOPRIGHT", -3, -LIST_TOP)
	sb:SetPoint("BOTTOMRIGHT", -3, 4)
	sb:SetWidth(10)
	sb:SetOrientation("VERTICAL")
	sb:SetValueStep(1)
	sb:SetObeyStepOnDrag(true)
	sb:SetMinMaxValues(0, 0)
	sb.track = sb:CreateTexture(nil, "BACKGROUND")
	sb.track:SetAllPoints()
	sb.track:SetTexture(WHITE)
	sb.track:SetColorTexture(0.1, 0.11, 0.14, 1)
	sb.thumb = sb:CreateTexture(nil, "OVERLAY")
	sb.thumb:SetTexture(WHITE)
	sb.thumb:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.7)
	sb.thumb:SetSize(8, 24)
	sb:SetThumbTexture(sb.thumb)
	sb:SetScript("OnValueChanged", function(_, v)
		if updatingScroll then return end
		listOffset = math.floor(v + 0.5)
		RefreshList()
	end)
	listBg.scrollbar = sb

	-- bottom bar: New outfit + Settings (everything else lives in the row menus)
	local newBtn = Button(frame, "+ " .. L["New outfit"], 120, 22, NewOutfit)
	newBtn:SetPoint("BOTTOMLEFT", 10, 10)
	local setBtn = Button(frame, L["Settings"], 100, 22, function() S:ToggleOptions() end)
	setBtn:SetPoint("BOTTOMRIGHT", -10, 10)
	frame.newBtn = newBtn

	RefreshList()
	S:WatchCharacterFrame()
end

function S:ToggleUI()
	if not frame then return end
	if frame:IsShown() then
		frame:Hide()
	else
		S:RefreshSets()
		frame:Show()
	end
end

function S:ShowUI() if frame then frame:Show() S:RefreshSets() end end

function S:ScanCharFrames()
	S:Print("followChar: " .. tostring(S.db and S.db.ui and S.db.ui.followChar))
	S:Print("ui frame: " .. tostring(frame) .. " shown=" .. tostring(frame and frame:IsShown()))
	local n = 0
	for _, f in ipairs(charFrames) do
		local ok, shown = pcall(function() return f:IsShown() end)
		S:Print("  " .. tostring(f.GetName and f:GetName() or f) .. " shown=" .. tostring(ok and shown))
		n = n + 1
	end
	if n == 0 then S:Print("  (no character frames found)") end
end

-- ===================================================================
-- Follow the character window: show our outfit window next to whatever
-- character UI is active (Blizzard, DaylightUI, ElvUI, custom).
-- ===================================================================
local rescanCounter = 0


-- window-level frames only, ordered by preference for anchoring
local CHAR_NAMES = {
	"DaylightUICharacter", "ElvUICharacterFrame", "CharacterFrame",
	"PaperDollFrame", "OutfitterFrame",
}

local function CollectCharFrames()
	wipe(charFrames)
	local seen = {}
	local function add(f)
		if f and not seen[f] then seen[f] = true charFrames[#charFrames + 1] = f end
	end
	for _, n in ipairs(CHAR_NAMES) do add(_G[n]) end
	-- EnumerateFrames here is step-based: EnumerateFrames(prev) -> next
	if EnumerateFrames then
		local ok, f = pcall(EnumerateFrames)
		while ok and f do
			-- GetName can taint-error on protected frames (Cooldowns etc.)
			local okN, n = pcall(function() return f:GetName() end)
			if okN and type(n) == "string" then
				local ln = n:lower()
				if (ln:find("character") or ln:find("paperdoll")) and not ln:find("inspect") then
					add(f)
				end
			end
			ok, f = pcall(EnumerateFrames, f)
		end
	end
end

local function IsWindowCandidate(f)
	-- real windows are wide; filters out slots/tabs/buttons.
	-- pcall: visibility/width can taint-error on protected frames
	if not f.IsVisible then return false end
	local ok, w = pcall(function() return f:GetWidth() end)
	return ok and type(w) == "number" and w > 200
end

local function FrameVisible(f)
	local ok, v = pcall(function() return f:IsVisible() end)
	return ok and v == true or v == 1
end

local function VisibleCharFrame()
	-- prefer named windows
	for _, n in ipairs(CHAR_NAMES) do
		local f = _G[n]
		if f and FrameVisible(f) then return f end
	end
	for _, f in ipairs(charFrames) do
		if IsWindowCandidate(f) and FrameVisible(f) then return f end
	end
	return nil
end

-- Outfitter-style toggle button pinned to the character window
local charBtn
local function EnsureCharButton(anchor)
	if not charBtn then
		charBtn = Button(UIParent, L["Outfits"], 58, 16, function() S:ToggleUI() end)
		charBtn.text:SetTextColor(unpack(GOLD))
		charBtn:SetFrameStrata("HIGH")
	end
	if charBtn:GetParent() ~= anchor then charBtn:SetParent(anchor) end
	charBtn:ClearAllPoints()
	charBtn:SetPoint("TOPRIGHT", anchor, "TOPRIGHT", -28, -30)
	charBtn:Show()
end

local function ShowWithChar(anchor)
	if not frame or frame:IsShown() then return end
	if not S.db.ui.followChar then return end
	if not (anchor and FrameVisible(anchor)) then return end

	frame:Show()
	S:RefreshSets()
	autoShown = true

	-- Outfitter style: dock to the RIGHT of the character window,
	-- same top edge and roughly the same height
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, -30)
	local right = frame:GetRight()
	if not right or right > GetScreenWidth() - 4 then
		frame:ClearAllPoints()
		frame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", 0, -30)
		local left = frame:GetLeft()
		if not left or left < 4 then
			frame:ClearAllPoints()
			frame:SetPoint("CENTER")
		end
	end

	local ok, ah = pcall(function() return anchor:GetHeight() end)
	if ok and type(ah) == "number" and ah > 220 then
		frame:SetHeight(math.max(320, math.min(560, ah - 20)))
	end
	RefreshList()
end

local function HideWithChar()
	autoShown = false
	if frame and frame:IsShown() then
		frame:Hide()
	end
end

-- direct hooks: react instantly when a known character frame opens/closes
local function HookCharFrame(f)
	if not f or hooked[f] or not f.HookScript then return end
	hooked[f] = true
	f:HookScript("OnShow", function(self)
		userClosed = false
		if frame and not frame:IsShown() then ShowWithChar(self) end
	end)
	f:HookScript("OnHide", function()
		userClosed = false
		if autoShown then HideWithChar() end
	end)
end

local function HookKnownFrames()
	-- only hook window-level frames; child frames toggle OnHide
	-- constantly (tabs, panes) and would close our window
	for _, n in ipairs(CHAR_NAMES) do HookCharFrame(_G[n]) end
	for _, f in ipairs(charFrames) do
		if IsWindowCandidate(f) then HookCharFrame(f) end
	end
end

function S:WatchCharacterFrame()
	CollectCharFrames()
	HookKnownFrames()
	C_Timer.NewTicker(5, function()
		rescanCounter = rescanCounter + 1
		if rescanCounter % 4 == 0 then CollectCharFrames() HookKnownFrames() end
	end)
	C_Timer.NewTicker(0.4, function()
		if not frame then return end
		local shown = VisibleCharFrame()
		if shown then
			if S.db.ui.followChar then
				EnsureCharButton(shown)
			elseif charBtn then
				charBtn:Hide()
			end
			if not frame:IsShown() and not userClosed then ShowWithChar(shown) end
		else
			userClosed = false
			if charBtn then charBtn:Hide() end
			if autoShown then HideWithChar() end
		end
	end)
end
