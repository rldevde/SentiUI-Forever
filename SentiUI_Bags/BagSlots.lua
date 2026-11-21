-- Equipped-bag strip: one slot button per equippable container (bags
-- 1-4 + reagent bag above the item grid, bank bags in the bank window).
-- Painting reads the character's own inventory slots; swapping goes
-- through the game's PutItemInBag / PickupBagFromSlot, so dragging a
-- bag onto a slot equips it and clicking an occupied one picks it up.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Slots = {}
ns.Slots = Slots

local EMPTY_ICON = "interface\\paperdoll\\ui-paperdoll-slot-bag"
local GAP = 4

local function InvSlot(bag)
	local fn = C_Container and C_Container.ContainerIDToInventoryID
	if not fn then return end
	local ok, v = pcall(fn, bag)
	if ok and type(v) == "number" and not S.IsSecret(v) then return v end
end

local function Paint(b)
	local tex, quality
	if b.inv then
		local ok, t = pcall(GetInventoryItemTexture, "player", b.inv)
		if ok and not S.IsSecret(t) then tex = t end
		local ok2, q = pcall(GetInventoryItemQuality, "player", b.inv)
		if ok2 and type(q) == "number" and not S.IsSecret(q) then quality = q end
	end
	b.icon:SetTexture(tex or EMPTY_ICON)
	if quality and quality > 1 then
		local qc = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
		local r, g, bl = 1, 1, 1
		if qc and type(qc.r) == "number" then r, g, bl = qc.r, qc.g, qc.b end
		S.SetBorderLit(b, true, { r = r, g = g, b = bl })
	else
		S.SetBorderLit(b, false)
	end
	b.icon:SetDesaturated(tex == nil)
	b.icon:SetAlpha(tex and 1 or 0.4)
end

function Slots.PaintStrip(strip, size)
	if not strip then return end
	size = size or strip.size or 32
	strip.size = size
	local x = 0
	for _, b in ipairs(strip.buttons) do
		b.inv = InvSlot(b.bag)
		if not b.inv then
			b:Hide()
		else
			Paint(b)
			b:SetSize(size, size)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", strip, "TOPLEFT", x, 0)
			b:Show()
			x = x + size + GAP
		end
	end
	strip:SetSize(math.max(1, x - GAP), size)
end

local function SlotClick(b)
	local inv = b.inv
	if not inv then return end
	local holds = CursorHasItem and CursorHasItem() or false
	if holds then
		if PutItemInBag then pcall(PutItemInBag, inv) end
	elseif b.hasBag then
		if PickupBagFromSlot then pcall(PickupBagFromSlot, inv) end
	end
end

function Slots.Make(w, bagIds)
	if not (bagIds and #bagIds > 0) then return end
	local strip = CreateFrame("Frame", nil, w.frame)
	strip.buttons = {}
	for i, bag in ipairs(bagIds) do
		local b = CreateFrame("Button", nil, strip, "BackdropTemplate")
		S.Template(b, "inset")
		b.bag = bag
		b.inv = InvSlot(bag)
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetPoint("TOPLEFT", 2, -2)
		b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
		b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		b:RegisterForClicks("LeftButtonUp")
		b:SetScript("OnClick", SlotClick)
		b:SetScript("OnReceiveDrag", SlotClick)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local inv = self.inv
			local shown = false
			if inv and self.hasBag and GameTooltip.SetInventoryItem then
				local ok, ret = pcall(GameTooltip.SetInventoryItem,
					GameTooltip, "player", inv)
				shown = ok and ret == true
			end
			if not shown then
				GameTooltip:AddLine(L["Bag slot"], 0.92, 0.68, 0.20)
				GameTooltip:AddLine(
					L["Drag a bag here to equip it, click an equipped bag to pick it up."],
					0.55, 0.57, 0.62, true)
				GameTooltip:Show()
			end
			S.SetBorderLit(self, true)
		end)
		b:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
			Paint(self)
		end)
		strip.buttons[i] = b
	end
	-- refresh paints pick up hasBag
	function strip:UpdatePaint(size)
		for _, b in ipairs(self.buttons) do
			b.inv = InvSlot(b.bag)
			local t = b.inv and GetInventoryItemTexture
				and select(2, pcall(GetInventoryItemTexture, "player", b.inv))
			b.hasBag = t ~= nil and not S.IsSecret(t)
		end
		Slots.PaintStrip(self, size)
	end
	w.bagStrip = strip
	strip:UpdatePaint(w.view and w.view.iconSize or 32)
end
