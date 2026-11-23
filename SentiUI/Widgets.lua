-- The controls option rows are built from. Everything is hand-drawn in the
-- Sentinel look; no template dependencies beyond BackdropTemplate.
local _, S = ...
local C = S.colors
local BLANK = S.media.blank

local W = {}
S.Widgets = W

-- button ---------------------------------------------------------------------------
function W.Button(parent, text, w, h)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 90, h or 22)
	b.minW = w or 90
	S.Template(b, "raised")
	b.label = S.Font(b, 11)
	b.label:SetPoint("CENTER")
	b:SetScript("OnEnter", function(f) S.SetBorderLit(f, true) end)
	b:SetScript("OnLeave", function(f) S.SetBorderLit(f, false) end)
	function b:FitWidth(pad)
		self:SetWidth(math.max(self.minW or 40, self.label:GetStringWidth() + (pad or 24)))
	end
	-- the button grows to its caption, so translations can't spill out
	function b:SetText(t)
		if issecretvalue and issecretvalue(t) then t = "" end
		if type(t) ~= "string" and type(t) ~= "number" then t = "" end
		self.label:SetText(t)
		self:FitWidth()
	end
	b:SetText(text)
	return b
end

-- checkbox ---------------------------------------------------------------------------
function W.Check(parent)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(16, 16)
	local chkOn = S.Tex and S.Tex("CheckOn")
	local chkOff = S.Tex and S.Tex("CheckEmpty")
	if chkOn and chkOff then
		-- full widget art: dark box, gold check
		S.Template(b, "none")
		local off = b:CreateTexture(nil, "BACKGROUND")
		off:SetAllPoints()
		off:SetTexture(chkOff)
		b.mark = b:CreateTexture(nil, "OVERLAY")
		b.mark:SetAllPoints()
		b.mark:SetTexture(chkOn)
	else
		S.Template(b, "inset")
		b.mark = b:CreateTexture(nil, "OVERLAY")
		b.mark:SetTexture(BLANK)
		b.mark:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 1)
		b.mark:SetPoint("TOPLEFT", 3, -3)
		b.mark:SetPoint("BOTTOMRIGHT", -3, 3)
	end
	b.mark:Hide()
	b.checked = false
	function b:SetChecked(v)
		self.checked = v and true or false
		self.mark:SetShown(self.checked)
	end
	function b:GetChecked() return self.checked end
	b:SetScript("OnClick", function(f)
		f:SetChecked(not f:GetChecked())
		if f.onChanged then f.onChanged(f:GetChecked()) end
	end)
	b:SetScript("OnEnter", function(f) S.SetBorderLit(f, true) end)
	b:SetScript("OnLeave", function(f) S.SetBorderLit(f, false) end)
	return b
end

-- slider -----------------------------------------------------------------------------
function W.Slider(parent, min, max, step)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(170, 18)
	f.min, f.max, f.step = min or 0, max or 1, step or 0
	f.value = f.min
	f:EnableMouse(true)

	f.track = f:CreateTexture(nil, "BACKGROUND")
	f.track:SetTexture(BLANK)
	f.track:SetVertexColor(C.bgInset.r, C.bgInset.g, C.bgInset.b, 1)
	f.track:SetPoint("LEFT", 4, 0)
	f.track:SetPoint("RIGHT", -4, 0)
	f.track:SetHeight(4)

	f.fill = f:CreateTexture(nil, "ARTWORK")
	f.fill:SetTexture(BLANK)
	f.fill:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.75)
	f.fill:SetPoint("LEFT", 4, 0)
	f.fill:SetHeight(4)

	f.thumb = CreateFrame("Button", nil, f, "BackdropTemplate")
	f.thumb:SetSize(10, 16)
	S.Template(f.thumb, "raised")
	S.SetBorderLit(f.thumb, true)
	local thTex = S.Tex and S.Tex("SliderThumb")
	if thTex then
		local ti = f.thumb:CreateTexture(nil, "OVERLAY")
		ti:SetTexture(thTex)
		ti:SetSize(6, 10)
		ti:SetPoint("CENTER")
		ti:SetVertexColor(C.accent.r, C.accent.g, C.accent.b)
	end
	f.thumb:SetScript("OnMouseDown", function() f:GetScript("OnMouseDown")(f) end)

	local function frac()
		if f.max <= f.min then return 0 end
		return (f.value - f.min) / (f.max - f.min)
	end

	local function place()
		local w = f:GetWidth() - 8
		local x = frac() * w
		f.thumb:ClearAllPoints()
		f.thumb:SetPoint("CENTER", f, "LEFT", 4 + x, 0)
		f.fill:SetWidth(math.max(1, x))
	end

	local function valueAtCursor()
		local x = GetCursorPosition() / f:GetEffectiveScale()
		local w = f:GetWidth() - 8
		local t = w > 0 and math.max(0, math.min(1, (x - f:GetLeft() - 4) / w)) or 0
		local v = f.min + t * (f.max - f.min)
		if f.step and f.step > 0 then
			v = f.min + math.floor((v - f.min) / f.step + 0.5) * f.step
		end
		return math.max(f.min, math.min(f.max, v))
	end

	function f:SetValue(v, silent)
		v = math.max(self.min, math.min(self.max, tonumber(v) or self.min))
		self.value = v
		place()
		if not silent and self.onChanged then self.onChanged(v, true) end
	end
	function f:GetValue() return self.value end
	function f:SetRange(min, max, step)
		self.min, self.max = min, max
		if step ~= nil then self.step = step end
		self:SetValue(self.value, true)
	end

	f:SetScript("OnMouseDown", function()
		f.dragging = true
		f:SetValue(valueAtCursor(), true)
		if f.onChanged then f.onChanged(f.value, false) end
		f:SetScript("OnUpdate", function()
			if not IsMouseButtonDown("LeftButton") then
				f.dragging = nil
				f:SetScript("OnUpdate", nil)
				if f.onChanged then f.onChanged(f.value, true) end
				return
			end
			local v = valueAtCursor()
			if v ~= f.value then
				f:SetValue(v, true)
				if f.onChanged then f.onChanged(v, false) end
			end
		end)
	end)
	f:SetScript("OnSizeChanged", place)
	place()
	return f
end

-- dropdown ----------------------------------------------------------------------------
local openPopup

function W.Dropdown(parent, w)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 170, 22)
	S.Template(b, "raised")
	b.text = S.Font(b, 11)
	b.text:SetPoint("LEFT", 8, 0)
	b.text:SetPoint("RIGHT", -20, 0)
	local ddTex = S.Tex and S.Tex("DropdownArrow")
	if ddTex then
		b.arrow = b:CreateTexture(nil, "OVERLAY")
		b.arrow:SetTexture(ddTex)
		b.arrow:SetSize(10, 8)
		b.arrow:SetPoint("RIGHT", -6, 0)
		b.arrow:SetVertexColor(C.textDim.r, C.textDim.g, C.textDim.b)
	else
		b.arrow = S.Font(b, 11, C.textDim)
		b.arrow:SetPoint("RIGHT", -7, 0)
		b.arrow:SetText("v")
	end
	b.values, b.order = {}, {}
	b:SetScript("OnEnter", function(f) S.SetBorderLit(f, true) end)
	b:SetScript("OnLeave", function(f)
		if not (openPopup and openPopup.owner == f) then S.SetBorderLit(f, false) end
	end)

	function b:SetOptions(values, order)
		self.values = values or {}
		self.order = order
		if not self.order then
			self.order = {}
			for k in pairs(self.values) do self.order[#self.order + 1] = k end
			table.sort(self.order, function(a, c) return tostring(self.values[a]) < tostring(self.values[c]) end)
		end
	end
	function b:SetValue(k)
		self.value = k
		self.text:SetText(self.values[k] or tostring(k))
	end
	function b:ClosePopup()
		if openPopup and openPopup.owner == self then openPopup:Hide() end
	end
	b:SetScript("OnClick", function(f)
		if openPopup and openPopup.owner == f and openPopup:IsShown() then
			f:ClosePopup()
		else
			W.OpenDropdown(f)
		end
	end)
	return b
end

-- One shared popup for every dropdown: an invisible catch-all button behind a
-- list of option buttons. Clicking a row picks and closes; clicking away closes.
local popup
local function ensurePopup()
	if popup then return popup end
	popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	popup:SetFrameStrata("FULLSCREEN_DIALOG")
	popup:SetClampedToScreen(true)
	popup:EnableMouse(true)
	popup:Hide()

	popup.catcher = CreateFrame("Button", nil, popup)
	popup.catcher:SetAllPoints(UIParent)
	popup.catcher:SetScript("OnClick", function() popup:Hide() end)

	popup.list = CreateFrame("Frame", nil, popup, "BackdropTemplate")
	S.Template(popup.list, "panel")
	popup.list:SetClampedToScreen(true)
	popup.list:SetFrameLevel(popup:GetFrameLevel() + 2)
	popup.rows = {}
	popup:SetScript("OnHide", function()
		if popup.owner then S.SetBorderLit(popup.owner, false); popup.owner = nil end
	end)
	openPopup = popup
	return popup
end

function W.OpenDropdown(dd)
	local p = ensurePopup()
	p.owner = dd
	local rows = p.rows
	local width = math.max(dd:GetWidth(), 120)
	local y = -4
	for i, key in ipairs(dd.order) do
		local r = rows[i]
		if not r then
			r = CreateFrame("Button", nil, p.list)
			r:SetHeight(20)
			r:SetPoint("LEFT", 4, 0)
			r:SetPoint("RIGHT", -4, 0)
			r.label = S.Font(r, 11)
			r.label:SetPoint("LEFT", 6, 0)
			r.hl = r:CreateTexture(nil, "BACKGROUND")
			r.hl:SetTexture(BLANK)
			r.hl:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.15)
			r.hl:SetAllPoints()
			r.hl:Hide()
			r:SetScript("OnEnter", function(f) f.hl:Show() end)
			r:SetScript("OnLeave", function(f) f.hl:Hide() end)
			r:SetScript("OnClick", function(f)
				local owner = p.owner
				p:Hide()
				if owner and owner.onPick then owner.onPick(f.key) end
			end)
			rows[i] = r
		end
		r.key = key
		r.label:SetText(dd.values[key] or tostring(key))
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", 4, y)
		r:SetPoint("RIGHT", -4, 0)
		r:Show()
		y = y - 20
	end
	for i = #dd.order + 1, #rows do rows[i]:Hide() end
	p.list:SetSize(width + 8, -y + 8)
	p.list:ClearAllPoints()
	p.list:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
	p:Show()
end

-- color swatch -----------------------------------------------------------------------------
local function pickColor(r, g, b, a, hasAlpha, cb)
	if not ColorPickerFrame then return end
	local info = {
		r = r, g = g, b = b,
		hasOpacity = hasAlpha == true,
		opacity = 1 - (a or 1),
		previousValues = { r = r, g = g, b = b, opacity = 1 - (a or 1) },
	}
	info.swatchFunc = function()
		local nr, ng, nb = ColorPickerFrame:GetColorRGB()
		local na = 1
		if hasAlpha and ColorPickerFrame.GetColorAlpha then na = 1 - ColorPickerFrame:GetColorAlpha() end
		cb(nr, ng, nb, na)
	end
	info.cancelFunc = function(prev)
		prev = prev or info.previousValues
		local na = a or 1
		if hasAlpha and prev.opacity then na = 1 - prev.opacity end
		cb(prev.r or r, prev.g or g, prev.b or b, na)
	end
	local ok = pcall(function()
		if ColorPickerFrame.SetupColorPickerAndShow then
			ColorPickerFrame:SetupColorPickerAndShow(info)
		else
			ColorPickerFrame.func = info.swatchFunc
			ColorPickerFrame.cancelFunc = info.cancelFunc
			ColorPickerFrame.hasOpacity = info.hasOpacity
			ColorPickerFrame.opacity = info.opacity
			ColorPickerFrame.previousValues = info.previousValues
			ColorPickerFrame:SetColorRGB(r, g, b)
			ColorPickerFrame:Show()
			ColorPickerFrame:Raise()
		end
	end)
	if not ok then S.Print(S.L["The color picker could not be opened."]) end
end

function W.Swatch(parent, hasAlpha)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(30, 18)
	S.Template(b, "inset")
	b.fill = b:CreateTexture(nil, "ARTWORK")
	b.fill:SetTexture(BLANK)
	b.fill:SetPoint("TOPLEFT", 2, -2)
	b.fill:SetPoint("BOTTOMRIGHT", -2, 2)
	b.r, b.g, b.b, b.a = 1, 1, 1, 1
	b.hasAlpha = hasAlpha
	function b:SetColor(r, g, b2, a)
		self.r, self.g, self.b, self.a = r or 1, g or 1, b2 or 1, a or 1
		self.fill:SetVertexColor(self.r, self.g, self.b, self.a)
	end
	b:SetScript("OnClick", function(f)
		pickColor(f.r, f.g, f.b, f.a, f.hasAlpha, function(nr, ng, nb, na)
			f:SetColor(nr, ng, nb, na)
			if f.onChanged then f.onChanged(nr, ng, nb, na) end
		end)
	end)
	b:SetScript("OnEnter", function(f) S.SetBorderLit(f, true) end)
	b:SetScript("OnLeave", function(f) S.SetBorderLit(f, false) end)
	return b
end

-- editbox (search) --------------------------------------------------------------------------
function W.EditBox(parent, w, h)
	local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	holder:SetSize(w or 160, h or 22)
	S.Template(holder, "inset")
	local e = CreateFrame("EditBox", nil, holder)
	e:SetPoint("TOPLEFT", 6, -2)
	e:SetPoint("BOTTOMRIGHT", -6, 2)
	e:SetFont(S.media.font, 11, "")
	e:SetTextColor(C.text.r, C.text.g, C.text.b)
	e:SetAutoFocus(false)
	e.placeholder = S.Font(holder, 11, C.textDim)
	e.placeholder:SetPoint("LEFT", 6, 0)
	e:SetScript("OnTextChanged", function(f)
		f.placeholder:SetShown(f:GetText() == "")
		if f.onChanged then f.onChanged(f:GetText()) end
	end)
	-- no OnEscapePressed/OnEditFocusLost: they run insecure Lua inside
	-- the Escape key dispatch and taint the engine's protected
	-- SpellStopCasting/SpellStopTargeting calls right after it
	-- (ADDON_ACTION_FORBIDDEN). Escape drops focus natively; the lit
	-- border reset is polled from a timer instead, which runs in its
	-- own dispatch.
	e:SetScript("OnEnterPressed", function(f) f:ClearFocus() end)
	e:SetScript("OnEditFocusGained", function(f)
		S.SetBorderLit(holder, true)
		local t
		t = C_Timer.NewTicker(0.1, function()
			if not f:HasFocus() then
				S.SetBorderLit(holder, false)
				t:Cancel()
			end
		end)
	end)
	e.holder = holder
	return e
end

-- close X --------------------------------------------------------------------------------------
function W.Close(parent, onClick)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(20, 20)
	S.Template(b, "raised")
	b.label = S.Font(b, 12, C.textDim)
	b.label:SetPoint("CENTER", 0, 1)
	b.label:SetText("x")
	b:SetScript("OnClick", onClick)
	b:SetScript("OnEnter", function(f) f.label:SetTextColor(C.accent.r, C.accent.g, C.accent.b); S.SetBorderLit(f, true) end)
	b:SetScript("OnLeave", function(f) f.label:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b); S.SetBorderLit(f, false) end)
	return b
end

-- scroll area --------------------------------------------------------------------------------------
-- A plain ScrollFrame + child, a mouse wheel and a thin scrollbar that only
-- shows when the content is taller than the view.
function W.Scroll(parent)
	local sf = CreateFrame("ScrollFrame", nil, parent)
	local child = CreateFrame("Frame", nil, sf)
	child:SetSize(1, 1)
	sf:SetScrollChild(child)
	sf.offset = 0
	sf:EnableMouseWheel(true)

	local bar = CreateFrame("Frame", nil, sf, "BackdropTemplate")
	bar:SetWidth(6)
	bar:SetPoint("TOPRIGHT", sf, "TOPRIGHT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 0, 0)
	S.Template(bar, "inset")
	bar.thumb = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	bar.thumb:SetWidth(4)
	bar.thumb:SetPoint("TOP", 0, -1)
	S.Template(bar.thumb, "raised")
	bar:Hide()

	local function range()
		return math.max(0, child:GetHeight() - sf:GetHeight()), sf:GetHeight(), child:GetHeight()
	end

	function sf.Scroll(f, offset)
		local r = range()
		f.offset = math.max(0, math.min(r, offset))
		f:SetVerticalScroll(f.offset)
		f.UpdateBar()
	end

	function sf.UpdateBar()
		local r, view, content = range()
		if r <= 0 then bar:Hide(); return end
		bar:Show()
		local h = math.max(18, view * view / content)
		bar.thumb:SetHeight(h - 2)
		local y = 1 + (sf.offset / r) * (view - h)
		bar.thumb:ClearAllPoints()
		bar.thumb:SetPoint("TOP", 0, -y)
	end

	sf:SetScript("OnMouseWheel", function(f, delta) f:Scroll(f.offset - delta * 42) end)

	bar.thumb:EnableMouse(true)
	bar.thumb:SetScript("OnMouseDown", function()
		local startY = select(2, GetCursorPosition()) / bar:GetEffectiveScale()
		local startOff = sf.offset
		bar:SetScript("OnUpdate", function()
			if not IsMouseButtonDown("LeftButton") then
				bar:SetScript("OnUpdate", nil)
				return
			end
			local y = select(2, GetCursorPosition()) / bar:GetEffectiveScale()
			local r, view, content = range()
			if content - view > 0 then
				local thumbH = bar.thumb:GetHeight()
				sf:Scroll(startOff + (startY - y) / math.max(1, view - thumbH) * (content - view))
			end
		end)
	end)

	sf:SetScript("OnSizeChanged", function(f) f:Scroll(f.offset) end)
	return sf, child
end

-- shared confirm / prompt dialog ---------------------------------------------------
-- One modal dialog for the whole suite. Deliberately NOT a StaticPopupDialogs
-- entry: the client records who wrote each table value and the game's own
-- Escape path reads StaticPopupDialogs - an addon-written entry marks the
-- dispatch tainted, so the protected call it makes next (SpellStopCasting)
-- gets ADDON_ACTION_FORBIDDEN blamed on whoever wrote it. An own frame plus
-- S.EscClosable keeps Escape closing without touching the game's tables.
local dlg

local function GetDialog()
	if dlg then return dlg end
	dlg = CreateFrame("Frame", "SentiUIDialog", UIParent, "BackdropTemplate")
	dlg:SetSize(380, 120)
	dlg:SetPoint("CENTER", 0, 80)
	dlg:SetFrameStrata("FULLSCREEN_DIALOG")
	dlg:SetToplevel(true)
	dlg:EnableMouse(true)
	S.Template(dlg, "panel")
	S.EscClosable(dlg)

	dlg.msg = S.Font(dlg, 11)
	dlg.msg:SetPoint("TOPLEFT", 18, -16)
	dlg.msg:SetPoint("TOPRIGHT", -18, -16)
	dlg.msg:SetJustifyH("CENTER")
	dlg.msg:SetSpacing(3)

	dlg.edit = W.EditBox(dlg, 340, 22)
	dlg.edit.holder:SetPoint("BOTTOM", dlg, "BOTTOM", 0, 44)
	dlg.edit.holder:Hide()
	dlg.edit:SetScript("OnEnterPressed", function(e)
		local h = dlg.ok:GetScript("OnClick")
		if h then h(dlg.ok) end
		e:ClearFocus()
	end)

	dlg.cancel = W.Button(dlg, CANCEL or "Cancel", 100, 22)
	dlg.cancel:SetPoint("BOTTOMLEFT", dlg, "BOTTOM", 4, 12)
	dlg.cancel:SetScript("OnClick", function()
		dlg:Hide()
		if dlg.onCancel then S.SafeCall("dialog:cancel", dlg.onCancel) end
	end)

	dlg.ok = W.Button(dlg, ACCEPT or "Accept", 100, 22)
	dlg.ok:SetPoint("BOTTOMRIGHT", dlg, "BOTTOM", -4, 12)
	dlg.ok:SetScript("OnClick", function()
		local text = dlg.edit.holder:IsShown() and dlg.edit:GetText() or nil
		dlg:Hide()
		if dlg.onAccept then S.SafeCall("dialog:accept", dlg.onAccept, text) end
	end)

	dlg:Hide()
	return dlg
end

-- opts: text, okText, cancelText, hideCancel, editText (shows an input box),
-- onAccept(textOrNil), onCancel, focusEdit, readOnly,
-- secureAccept = "/reload" (or any macro): the ok button runs the macro
-- through a secure overlay instead of addon code - needed for protected
-- calls like reloads
function S.Dialog(opts)
	local d = GetDialog()
	if d.secOverlay then d.secOverlay:Hide() end
	d.msg:SetText(opts.text or "")
	local hasEdit = opts.editText ~= nil
	d.edit:SetText(opts.editText or "")
	d.edit.holder:SetShown(hasEdit)
	d.edit:SetEnabled(not opts.readOnly)
	if opts.readOnly then
		d.edit:HighlightText()
		d.edit:SetTextColor(C.accent2.r, C.accent2.g, C.accent2.b)
	else
		d.edit:SetTextColor(C.text.r, C.text.g, C.text.b)
	end
	d.ok:SetText(opts.okText or ACCEPT or "Accept")
	d.onAccept = opts.onAccept
	d.onCancel = opts.onCancel
	if opts.hideCancel then
		d.cancel:Hide()
		d.ok:ClearAllPoints()
		d.ok:SetPoint("BOTTOM", 0, 12)
	else
		d.cancel:Show()
		d.cancel:SetText(opts.cancelText or CANCEL or "Cancel")
		d.ok:ClearAllPoints()
		d.ok:SetPoint("BOTTOMRIGHT", d, "BOTTOM", -4, 12)
	end
	if opts.secureAccept == "/reload" then
		-- no addon scripts on the secure button (an insecure script taints
		-- the dispatch): the dialog simply stays until the reload fires -
		-- or stays open as feedback when the reload was blocked.
		if not d.secOverlay then
			d.secOverlay = S.SecureReload(d.ok)
		end
		if d.secOverlay then d.secOverlay:Show() end
	elseif d.secOverlay then
		d.secOverlay:Hide()
	end
	d:SetHeight(opts.editText ~= nil and 150 or 110)
	d:Show()
	if hasEdit then
		if opts.readOnly then d.edit:HighlightText() end
		if opts.focusEdit ~= false then C_Timer.After(0, function() d.edit:SetFocus() end) end
	end
	return d
end

function S.Confirm(text, onAccept, opts)
	opts = opts or {}
	opts.text = text
	opts.onAccept = onAccept
	return S.Dialog(opts)
end
