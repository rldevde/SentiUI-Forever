-- Gear slots: icon with quality ring, item name, item level line,
-- durability warning and the native inventory-item tooltip.
local _, ns = ...
local S = SentiUI
local C = S.colors
local L = ns.L
local BLANK = S.media.blank

ns.Slots = {}
local Sl = ns.Slots

-- durability, guarded: returns plain numbers or nil
-- secret quality colors come back nil; this client's signature also
-- wants a color object rather than r,g,b - try both forms
local function SetVC(tex, r, g, b)
	if not (r and g and b) then return end
	local ok = pcall(tex.SetVertexColor, tex, { r = r, g = g, b = b })
	if not ok then pcall(tex.SetVertexColor, tex, r, g, b) end
end

local function Durability(slot)
	if type(GetInventoryItemDurability) ~= "function" then return nil, nil end
	local ok, c, m = pcall(GetInventoryItemDurability, slot)
	if not ok then return nil, nil end
	return ns.Plain(c), ns.Plain(m)
end

local ICON = 40
local ROW = 44

-- Classic character-frame layout.
local LEFT = {
	{ 1,  "Head" }, { 2, "Neck" }, { 3, "Shoulder" }, { 15, "Back" },
	{ 5,  "Chest" }, { 4, "Shirt" }, { 19, "Tabard" }, { 9, "Wrist" },
}
local RIGHT = {
	{ 10, "Hands" }, { 6, "Waist" }, { 7, "Legs" }, { 8, "Feet" },
	{ 11, "Finger0" }, { 12, "Finger1" }, { 13, "Trinket0" }, { 14, "Trinket1" },
}
local BOTTOM = {
	{ 16, "MainHand" }, { 17, "SecondaryHand" }, { 18, "Ranged" }, { 0, "Ammo" },
}

local function ItemLink(slot)
	if type(GetInventoryItemLink) ~= "function" then return nil end
	local ok, link = pcall(GetInventoryItemLink, "player", slot)
	link = ok and ns.PlainStr(link) or nil
	if link and link ~= "" then return link end
end

-- itemString fields: enchantID at pos 3, gemIDs at pos 4-7
local function LinkExtras(link)
	local ench, gems = 0, 0
	local f = 0
	for id in link:gmatch(":(%d*)") do
		f = f + 1
		local n = tonumber(id) or 0
		if f == 1 and n > 0 then ench = n
		elseif f >= 2 and f <= 5 and n > 0 then gems = gems + 1 end
	end
	return ench, gems
end

local function QualityColor(link)
	local ok, q = pcall(function()
		return select(3, C_Item.GetItemInfoInstant(link))
	end)
	if not ok then return nil end
	if type(q) ~= "number" or S.IsSecret(q) then return nil end
	local r, g, b
	if C_Item.GetItemQualityColor then
		r, g, b = C_Item.GetItemQualityColor(q)
	end
	-- may hand back a color table instead of channels
	if type(r) == "table" then
		local c = r
		r, g, b = c.r, c.g, c.b
	end
	if not r and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] then
		local c = ITEM_QUALITY_COLORS[q]
		r, g, b = c.r, c.g, c.b
	end
	-- secret channels read as nil through Plain
	r, g, b = ns.Plain(r), ns.Plain(g), ns.Plain(b)
	return r or 1, g or 1, b or 1
end

local function MakeSlot(parent, slot, side)
	local b = CreateFrame("Button", "SentiUICharSlot" .. slot, parent)
	b:SetSize(ROW, ROW)
	b.slot = slot

	-- flat inset box, quality/durability shows as a 1px border color -
	-- no UI-Quickslot2 ring, it renders as a clunky square frame
	b.box = CreateFrame("Frame", nil, b, "BackdropTemplate")
	b.box:SetPoint(side == "left" and "LEFT" or "RIGHT", 0, 0)
	b.box:SetSize(ICON + 4, ICON + 4)
	b.box:SetBackdrop({
		bgFile = BLANK, edgeFile = BLANK, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	b.box:SetBackdropColor(0.06, 0.07, 0.10, 0.9)
	b.box:SetBackdropBorderColor(C.border.r, C.border.g, C.border.b, 1)

	b.icon = b.box:CreateTexture(nil, "ARTWORK")
	b.icon:SetPoint("TOPLEFT", 2, -2)
	b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	-- subtle 2px corner clip via the shared mask helper (b.icon lives on
	-- b.box, IconRound picks the icon's own parent for the mask host)
	S.IconRound(b, 2)

	-- hover sheen inside the box; the quality border color stays untouched
	b.box.hover = b.box:CreateTexture(nil, "OVERLAY")
	b.box.hover:SetAllPoints(b.icon)
	b.box.hover:SetTexture(BLANK)
	b.box.hover:SetVertexColor(1, 1, 1, 0.07)
	b.box.hover:Hide()

	if side ~= "bottom" then
		b.name = S.Font(b, 10)
		b.name:SetWidth(160)
		b.name:SetJustifyH(side == "left" and "LEFT" or "RIGHT")
		b.name:SetWordWrap(false)
		if side == "left" then
			b.name:SetPoint("LEFT", b.box, "RIGHT", 6, 6)
		else
			b.name:SetPoint("RIGHT", b.box, "LEFT", -6, 6)
		end
		b.sub = S.Font(b, 9, C.textDim)
		b.sub:SetWidth(160)
		b.sub:SetJustifyH(b.name:GetJustifyH())
		if side == "left" then
			b.sub:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -1)
		else
			b.sub:SetPoint("TOPRIGHT", b.name, "BOTTOMRIGHT", 0, -1)
		end
	end

	-- ilvl corner badge (ilvlInIcon option)
	b.ilvl = S.Font(b, 9, C.accent, "OUTLINE")
	b.ilvl:SetPoint("BOTTOMRIGHT", b.icon, "BOTTOMRIGHT", -1, 1)
	b.ilvl:Hide()

	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:SetScript("OnClick", function(self, btn)
		Sl.Click(self, btn)
	end)
	b:SetScript("OnEnter", function(self)
		if self.box.hover then self.box.hover:Show() end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local ok = pcall(function()
			GameTooltip:SetInventoryItem("player", self.slot)
		end)
		if ok then GameTooltip:Show() end
	end)
	b:SetScript("OnLeave", function(self)
		if self.box.hover then self.box.hover:Hide() end
		GameTooltip:Hide()
	end)
	return b
end

-- Click behavior: shift = link into chat, ctrl = dress up, alt/right = menu,
-- plain left = pick the item up (hardware click, native behavior).
function Sl.Click(b, btn)
	local link = ItemLink(b.slot)
	if not link then return end
	if IsModifiedClick("CHATLINK") then
		ChatEdit_InsertLink(link)
		return
	end
	if IsModifiedClick("DRESSUP") and DressUpItemLink then
		pcall(DressUpItemLink, link)
		return
	end
	if btn == "RightButton" or IsAltKeyDown() then
		ns.Menu.Open(b, {
			{ label = L["Pick up"], fn = function()
				pcall(PickupInventoryItem, b.slot)
			end },
			{ label = L["Insert into chat"], fn = function()
				ChatEdit_InsertLink(link)
			end },
			{ label = L["Dressing room"], fn = function()
				if DressUpItemLink then pcall(DressUpItemLink, link) end
			end },
		})
		return
	end
	pcall(PickupInventoryItem, b.slot)
end

function Sl.Build()
	if Sl.built then return end
	Sl.built = true
	ns.Win.leftSlots, ns.Win.rightSlots, ns.Win.bottomSlots = {}, {}, {}
	for _, s in ipairs(LEFT) do
		ns.Win.leftSlots[#ns.Win.leftSlots + 1] =
			MakeSlot(ns.Win.leftCol, s[1], "left")
	end
	for _, s in ipairs(RIGHT) do
		ns.Win.rightSlots[#ns.Win.rightSlots + 1] =
			MakeSlot(ns.Win.rightCol, s[1], "right")
	end
	for _, s in ipairs(BOTTOM) do
		ns.Win.bottomSlots[#ns.Win.bottomSlots + 1] =
			MakeSlot(ns.Win.bottomRow, s[1], "bottom")
	end
	Sl.all = {}
	for _, list in ipairs({ ns.Win.leftSlots, ns.Win.rightSlots, ns.Win.bottomSlots }) do
		for _, b in ipairs(list) do Sl.all[#Sl.all + 1] = b end
	end
end

-- Empty-slot placeholder textures: Blizzards per-slot atlas names.
local EMPTY_TEX = {
	[0] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Ammo",
	[1] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Head",
	[2] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Neck",
	[3] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Shoulder",
	[4] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Shirt",
	[5] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Chest",
	[6] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Waist",
	[7] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Legs",
	[8] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Feet",
	[9] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Wrist",
	[10] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Hands",
	[11] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Finger",
	[12] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Finger",
	[13] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Trinket",
	[14] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Trinket",
	[15] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Chest",
	[16] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-MainHand",
	[17] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-SecondaryHand",
	[18] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Ranged",
	[19] = "Interface\\Paperdoll\\UI-PaperDoll-Slot-Tabard",
}

local function RefreshOne(b)
	local db = ns.C.db()
	local link = ItemLink(b.slot)
	local tex
	if type(GetInventoryItemTexture) == "function" then
		local ok, v = pcall(GetInventoryItemTexture, "player", b.slot)
		tex = ok and ns.Plain(v) or nil
	end

	if link and tex then
		b.icon:SetTexture(tex)
		b.icon:SetDesaturated(false)
		SetVC(b.icon, 1, 1, 1)
		local r, g, bl = QualityColor(link)
		if not (r and g and bl) then r, g, bl = 1, 1, 1 end
		b.box:SetBackdropBorderColor(r, g, bl, 1)

		-- name + ilvl lines
		if b.name then
			if db.names then
				local nm = ns.PlainStr(C_Item.GetItemNameByID and C_Item.GetItemNameByID(link))
					or link:match("%[(.-)%]")
				b.name:SetText(nm or "")
				pcall(b.name.SetTextColor, b.name, r, g, bl)
				b.name:Show()
			else
				b.name:Hide()
			end
			if db.itemLevel and not db.ilvlInIcon then
				local il = ns.Plain(C_Item.GetDetailedItemLevelInfo
					and C_Item.GetDetailedItemLevelInfo(link))
				local cur, mx = Durability(b.slot)
				local ench, gems = LinkExtras(link)
				local line = il and tostring(il) or ""
				if mx and mx > 0 and cur then
					line = line .. "  " .. math.floor(cur / mx * 100) .. "%"
				end
				if ench > 0 then line = line .. "  |cff4ec24e" .. L["E"] .. "|r" end
				if gems > 0 then
					line = line .. "  |cff339eff" .. string.rep("•", gems) .. "|r"
				end
				b.sub:SetText(line)
				b.sub:Show()
			else
				b.sub:Hide()
			end
		end
		if db.itemLevel and db.ilvlInIcon then
			local il = ns.Plain(C_Item.GetDetailedItemLevelInfo
				and C_Item.GetDetailedItemLevelInfo(link))
			b.ilvl:SetText(il or "")
			b.ilvl:Show()
		else
			b.ilvl:Hide()
		end

		-- durability warning ring
		local cur, mx = Durability(b.slot)
		if mx and mx > 0 and cur and cur / mx <= (db.repairAt or 0.25) then
			b.box:SetBackdropBorderColor(0.95, 0.25, 0.2, 1)
		end
	else
		b.icon:SetTexture(EMPTY_TEX[b.slot] or "Interface\\Paperdoll\\UI-PaperDoll-Slot-Bag")
		b.icon:SetDesaturated(true)
		SetVC(b.icon, 0.6, 0.6, 0.6)
		b.box:SetBackdropBorderColor(C.border.r, C.border.g, C.border.b, 1)
		b.ilvl:Hide()
		if b.name then b.name:Hide() end
		if b.sub then b.sub:Hide() end
	end
end

function Sl.Refresh()
	for _, b in ipairs(Sl.all or {}) do RefreshOne(b) end
end

-- Sum of equipped durability for the footer (nil when nothing to repair).
function Sl.TotalDurability()
	local cur, max = 0, 0
	for _, b in ipairs(Sl.all or {}) do
		local c, m = Durability(b.slot)
		if c and m and m > 0 then cur = cur + c max = max + m end
	end
	return cur, max
end
