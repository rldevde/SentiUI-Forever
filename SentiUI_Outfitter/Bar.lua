local _, ns = ...
local S = ns.Outfitter
local L = S.L
local GOLD, BLUE, WHITE = S.GOLD, S.BLUE, S.WHITE
local BG, PANEL = { 0.05, 0.055, 0.07, 0.9 }, { 0.09, 0.10, 0.125, 1 }

local bar, buttons, manageBtn

local function Box(parent, bg, border)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
	f:SetBackdropColor(unpack(bg or BG))
	f:SetBackdropBorderColor(unpack(border or { 0.22, 0.24, 0.3, 1 }))
	return f
end

local function Label(parent, text, template, r, g, b)
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
	fs:SetText(text or "")
	if r then fs:SetTextColor(r, g, b) end
	return fs
end

-- crisp 1px border flush with the frame edges (visible edge == hitbox)
local function Border(parent, r, g, b, a)
	local e = {}
	for i = 1, 4 do
		e[i] = parent:CreateTexture(nil, "OVERLAY")
		e[i]:SetTexture(WHITE)
		e[i]:SetColorTexture(r, g, b, a or 1)
	end
	e[1]:SetPoint("TOPLEFT") e[1]:SetPoint("TOPRIGHT") e[1]:SetHeight(1)
	e[2]:SetPoint("BOTTOMLEFT") e[2]:SetPoint("BOTTOMRIGHT") e[2]:SetHeight(1)
	e[3]:SetPoint("TOPLEFT") e[3]:SetPoint("BOTTOMLEFT") e[3]:SetWidth(1)
	e[4]:SetPoint("TOPRIGHT") e[4]:SetPoint("BOTTOMRIGHT") e[4]:SetWidth(1)
	local o = {}
	function o:SetColor(r2, g2, b2, a2)
		for _, t in ipairs(e) do t:SetColorTexture(r2, g2, b2, a2 or 1) end
	end
	return o
end

-- ===================================================================
-- Bar construction
-- ===================================================================
local BTN = 32
local PAD = 3
local MANAGE_W = 18

local function SetBarAlpha()
	if not bar then return end
	local a = S.db.bar.alpha or 1
	if InCombatLockdown() then a = math.min(a, S.db.bar.combatAlpha or a) end
	bar:SetAlpha(a)
end S.SetBarAlpha = SetBarAlpha

local function MakeButton(set)
	-- SecureActionButtonTemplate: type "equipmentset" swaps natively,
	-- weapons also work in combat. LeftButton only.
	local b = CreateFrame("CheckButton", nil, bar, "SecureActionButtonTemplate")
	b.set = set
	b:SetSize(BTN, BTN)

	b.bg = b:CreateTexture(nil, "BACKGROUND")
	b.bg:SetAllPoints()
	b.bg:SetTexture(WHITE)
	b.bg:SetColorTexture(0.10, 0.105, 0.13, 1)

	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	b.icon:SetTexture(set.icon or S.DEFAULT_SET_ICON)

	b.border = Border(b, 0.28, 0.30, 0.36, 1)
	function b:SetEdge(r, g, b2, a) b.border:SetColor(r, g, b2, a) end
	b:SetEdge(0.28, 0.30, 0.36, 1)

	b.hover = b:CreateTexture(nil, "HIGHLIGHT")
	b.hover:SetAllPoints()
	b.hover:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.22)

	if S.db.bar.showNames then
		b.name = Label(b, set.name, "GameFontHighlightSmall")
		b.name:SetPoint("TOP", b, "BOTTOM", 0, -2)
		b.name:SetJustifyH("CENTER")
		b.name:SetWidth(BTN + 44)
	end

	pcall(b.RegisterForClicks, b, "LeftButtonUp")
	if not InCombatLockdown() then
		b:SetAttribute("type", "equipmentset")
		b:SetAttribute("equipmentset", set.name)
	end

	-- fallback if the secure "equipmentset" type isn't implemented on
	-- this client: wear via the API directly (idempotent if both fire)
	b:SetScript("OnClick", function(self, btn)
		if btn == "LeftButton" then S:WearSet(self.set.id) end
	end)
	-- right-click: same menu as the outfit list (works without click
	-- registration so it never triggers the secure swap)
	b:SetScript("OnMouseUp", function(self, btn)
		if btn == "RightButton" and S.OutfitMenu then S:OutfitMenu(self, self.set) end
	end)

	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		if GameTooltip.SetEquipmentSet then
			GameTooltip:SetEquipmentSet(self.set.id)
		else
			GameTooltip:SetText(self.set.name, unpack(GOLD))
			GameTooltip:AddLine(L["Click to wear this outfit"], 0.7, 0.7, 0.7)
			GameTooltip:AddLine(L["Right-click for options"], 0.7, 0.7, 0.7)
		end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return b
end

local function LayoutBar()
	if not bar then return end
	local vertical = S.db.bar.vertical
	local n = #(buttons or {})
	local namesH = S.db.bar.showNames and 14 or 0

	local w, h
	if vertical then
		w = BTN + PAD * 2
		h = PAD + MANAGE_W + PAD + n * (BTN + PAD) + namesH
	else
		w = PAD + MANAGE_W + PAD + n * (BTN + PAD)
		h = BTN + PAD * 2 + namesH
	end
	bar:SetSize(w, h)
	bar:SetScale(S.db.bar.scale or 1)
	-- when locked, let clicks in the gaps pass through instead of
	-- being swallowed by the (undraggable) background frame
	bar:EnableMouse(not S.db.bar.locked)

	manageBtn:ClearAllPoints()
	manageBtn:SetPoint("TOPLEFT", bar, "TOPLEFT", PAD, -PAD)

	for i, b in ipairs(buttons or {}) do
		b:ClearAllPoints()
		if vertical then
			local prev = i == 1 and manageBtn or buttons[i - 1]
			b:SetPoint("TOP", prev, "BOTTOM", 0, -PAD)
			b:SetPoint("CENTER", bar, "CENTER", 0, 0)
			-- align x with the row above
			b:ClearAllPoints()
			b:SetPoint("TOP", prev, "BOTTOM", 0, -PAD)
			b:SetPoint("LEFT", bar, "LEFT", PAD, 0)
		else
			local prev = i == 1 and manageBtn or buttons[i - 1]
			b:SetPoint("LEFT", prev, "RIGHT", PAD, 0)
			b:SetPoint("TOP", prev, "TOP", 0, 0)
		end
	end
end

function S:ApplyBarLayout()
	if not bar then return end
	local pos = S.db.bar.position
	bar:ClearAllPoints()
	if pos and pos.point then
		bar:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or -120, pos.y or 0)
	else
		-- default: right edge, vertically centered
		bar:SetPoint("RIGHT", UIParent, "RIGHT", -8, 0)
	end
	LayoutBar()
end

function S:RefreshBar()
	if not bar then return end
	if InCombatLockdown() then
		SetBarAlpha()
		return
	end

	if buttons then
		for _, b in ipairs(buttons) do b:Hide() b:SetParent(UIParent) end
	end
	buttons = {}

	for _, set in ipairs(S:GetSets()) do
		buttons[#buttons + 1] = MakeButton(set)
	end

	for _, b in ipairs(buttons) do
		if S:IsSetWorn(b.set.id) then
			b:SetEdge(unpack(GOLD))
		else
			b:SetEdge(0.28, 0.30, 0.36, 1)
		end
	end

	LayoutBar()
	bar:SetShown(S.db.bar.enabled and #buttons > 0)
	SetBarAlpha()
end

-- ===================================================================
-- Build
-- ===================================================================
function S:InitBar()
	if bar then return end

	bar = Box(UIParent, BG, { 0.22, 0.24, 0.3, 1 })
	bar:SetFrameStrata("HIGH")
	bar:SetFrameLevel(50)
	bar:SetMovable(true)
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetClampedToScreen(true)
	bar:SetScript("OnDragStart", function(self)
		if not S.db.bar.locked then self:StartMoving() end
	end)
	bar:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint(1)
		S.db.bar.position = { point = point, relPoint = relPoint, x = x, y = y }
	end)

	-- manage button (small "S" opens the outfit window)
	manageBtn = CreateFrame("Button", nil, bar)
	manageBtn:SetSize(MANAGE_W, BTN)
	manageBtn.bg = manageBtn:CreateTexture(nil, "BACKGROUND")
	manageBtn.bg:SetAllPoints()
	manageBtn.bg:SetTexture(WHITE)
	manageBtn.bg:SetColorTexture(0.10, 0.105, 0.13, 1)
	manageBtn.border = Border(manageBtn, GOLD[1], GOLD[2], GOLD[3], 0.85)
	manageBtn.icon = manageBtn:CreateTexture(nil, "ARTWORK")
	manageBtn.icon:SetPoint("TOPLEFT", 1, -1)
	manageBtn.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	manageBtn.icon:SetTexture(S.LOGO or "Interface\\AddOns\\SentiUI_Outfitter\\Media\\Logo.tga")
	manageBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	manageBtn.hover = manageBtn:CreateTexture(nil, "HIGHLIGHT")
	manageBtn.hover:SetAllPoints()
	manageBtn.hover:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.2)
	manageBtn:RegisterForClicks("AnyUp")
	manageBtn:SetScript("OnClick", function() S:ShowUI() end)
	manageBtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:SetText(L["Outfits"], unpack(GOLD))
		GameTooltip:AddLine(L["Click to open the outfit window"], 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	manageBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	buttons = {}
	S:ApplyBarLayout()
	S:RefreshBar()

	S:On("PLAYER_REGEN_DISABLED", SetBarAlpha)
	S:On("PLAYER_REGEN_ENABLED", function()
		SetBarAlpha()
		S:Defer("barrefresh", S.RefreshBar, S)
	end)
	S:On("PLAYER_EQUIPMENT_CHANGED", function() SetBarAlpha() end)
end
