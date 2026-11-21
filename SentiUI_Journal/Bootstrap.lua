-- Shared base for the journal module: saved variables, the small widget
-- vocabulary the compendium pages use, and the protected-call helpers.
local _, ns = ...
local S = SentiUI

SentiUIJournalDB = SentiUIJournalDB or {}
ns.db = SentiUIJournalDB

function ns.MarkCall() end -- API-call accounting is a My-Social service

-- true when calling this API would taint or pop the blocked dialog
function ns.Protected(fn)
	return type(issecurefunction) == "function"
		and issecurefunction(fn) == true
end

-- widgets ----------------------------------------------------------------------
local W = {}
ns.Widgets = W
local C = S.colors
W.GOLD = { C.accent.r, C.accent.g, C.accent.b }
W.MUTED = { C.textDim.r, C.textDim.g, C.textDim.b }

function W.Text(parent, template, color)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
	local c = color or { C.text.r, C.text.g, C.text.b }
	fs:SetTextColor(c[1], c[2], c[3])
	return fs
end

function W.Panel(parent, bg, border)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	S.Template(f, "inset")
	if bg then f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1) end
	if border then f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1) end
	return f
end

-- ScrollFrame + child holder; the native UpdateScrollChildRect stays in charge
function W.ScrollArea(parent)
	local scroll = CreateFrame("ScrollFrame", nil, parent)
	local holder = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(holder)
	local function fit() holder:SetWidth(math.max(1, scroll:GetWidth() or 1)) end
	scroll:SetScript("OnSizeChanged", fit)
	fit()
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, d)
		local max = self:GetVerticalScrollRange()
		self:SetVerticalScroll(math.min(max, math.max(0, self:GetVerticalScroll() - d * 40)))
	end)
	return scroll, holder
end

-- pill chip with label/active styling
function W.Chip(parent, onClick)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetHeight(20)
	S.Template(b, "inset")
	b.fs = S.Font(b, 10, S.colors.textDim)
	b.fs:SetPoint("CENTER")
	b.fs:SetJustifyH("CENTER")
	function b:SetLabel(t)
		self.fs:SetText(t)
		self:SetWidth((self.fs:GetStringWidth() or 40) + 18)
	end
	function b:SetActive(on)
		local c = on and S.colors.accent or S.colors.textDim
		self.fs:SetTextColor(c.r, c.g, c.b)
		S.SetBorderLit(self, on == true)
	end
	b:SetScript("OnClick", function(self) onClick(self) end)
	return b
end

-- accent-colored text link, used for waypoint and follow-up buttons
function W.LinkButton(parent, text, onClick)
	local b = CreateFrame("Button", nil, parent)
	b.fs = S.Font(b, 10, S.colors.accent2)
	b.fs:SetPoint("CENTER")
	b.fs:SetText(text or "")
	b:SetSize((b.fs:GetStringWidth() or 40) + 12, 16)
	function b:SetText(t)
		b.fs:SetText(t)
		b:SetWidth((b.fs:GetStringWidth() or 40) + 12)
	end
	b:SetScript("OnEnter", function() b.fs:SetTextColor(1, 1, 1) end)
	b:SetScript("OnLeave", function()
		local c = S.colors.accent2
		b.fs:SetTextColor(c.r, c.g, c.b)
	end)
	b:SetScript("OnClick", function(self) onClick(self) end)
	return b
end

-- hint-labeled edit box; onChange fires on user input
function W.SearchBox(parent, w, hint, onChange)
	local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	e:SetSize(w or 160, 20)
	e:SetAutoFocus(false)
	e:SetMaxLetters(60)
	local h = S.Font(e, 10, S.colors.textDim)
	h:SetPoint("LEFT", e, "LEFT", 6, 0)
	h:SetText(hint or "")
	local function upd()
		h:SetShown((e:GetText() or "") == "")
	end
	e:SetScript("OnTextChanged", function(self, user)
		upd()
		if user and onChange then onChange(self) end
	end)
	-- no OnEditFocusLost/OnEscapePressed: they run insecure Lua inside
	-- the Escape dispatch and taint the engine's protected spell-stop
	-- calls. Escape drops focus natively; OnTextChanged keeps the hint
	-- in sync.
	upd()
	return e
end

-- raised template button - Blizzard templates call the protected
-- SetPassThroughButtons on this client, so buttons are homegrown
function W.Button(parent, w, h, label)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 90, h or 22)
	S.Template(b, "raised")
	b.fs = S.Font(b, 10)
	b.fs:SetPoint("CENTER")
	b.fs:SetJustifyH("CENTER")
	function b:SetText(t) self.fs:SetText(t) end
	function b:GetText() return self.fs:GetText() end
	b:SetText(label or "")
	b:SetScript("OnEnter", function() S.SetBorderLit(b, true) end)
	b:SetScript("OnLeave", function() S.SetBorderLit(b, false) end)
	return b
end
