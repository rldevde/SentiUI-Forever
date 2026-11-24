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

-- bank bags are containers NUM_BAG_SLOTS+1 .. +NUM_BANKBAGSLOTS; the slot
-- index decides whether it is bought yet (slots sell one at a time)
local function BankSlotIndex(bag)
	local base = (type(NUM_BAG_SLOTS) == "number" and NUM_BAG_SLOTS or 4) + 1
	if type(bag) == "number" and bag > base then
		return bag - base
	end
end

local function PurchasedBankSlots()
	if type(GetNumBankSlots) ~= "function" then return end
	local ok, n = pcall(GetNumBankSlots)
	if ok and type(n) == "number" and not S.IsSecret(n) then return n end
end

-- "12g 34s 56c"
local function MoneyStr(c)
	if type(c) ~= "number" or S.IsSecret(c) then return "?" end
	local g, s, k = math.floor(c / 1e4), math.floor(c / 100 % 100), math.floor(c % 100)
	local out = {}
	if g > 0 then out[#out + 1] = g .. "g" end
	if s > 0 then out[#out + 1] = s .. "s" end
	if k > 0 or #out == 0 then out[#out + 1] = k .. "c" end
	return table.concat(out, " ")
end

local function NextSlotCost()
	if type(GetBankSlotCost) == "function" then
		local ok, c = pcall(GetBankSlotCost, PurchasedBankSlots() or 0)
		if ok and type(c) == "number" and not S.IsSecret(c) then return c end
	end
end

local function InvSlot(bag)
	local fn = C_Container and C_Container.ContainerIDToInventoryID
	if not fn then return end
	local ok, v = pcall(fn, bag)
	if ok and type(v) == "number" and not S.IsSecret(v) then return v end
end

local function Paint(b)
	-- unpurchased bank slot: only the next one in line is clickable, the
	-- rest stay hidden (PaintStrip handles that before we get here)
	if b.buyable then
		b.icon:SetTexture(EMPTY_ICON)
		b.icon:SetDesaturated(true)
		b.icon:SetAlpha(0.45)
		S.SetBorderLit(b, true) -- accent = "you can buy this"
		return
	end
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
	local purchased = PurchasedBankSlots()
	local x = 0
	for _, b in ipairs(strip.buttons) do
		b.inv = InvSlot(b.bag)
		b.buyable = nil
		if b.bankSlot and purchased and b.bankSlot > purchased then
			-- locked beyond the next purchasable slot stay out entirely
			if b.bankSlot == purchased + 1 then
				b.buyable = true
				Paint(b)
				b:SetSize(size, size)
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", strip, "TOPLEFT", x, 0)
				b:Show()
				x = x + size + GAP
			else
				b:Hide()
			end
		elseif not b.inv then
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
	if b.buyable then
		local cost = NextSlotCost()
		local text = L["Buy the next bank slot?"]
		if cost then text = text .. "\n|cffebad33" .. MoneyStr(cost) .. "|r" end
		S.Dialog({
			text = text,
			okText = L["Buy"], cancelText = CANCEL or "Cancel",
			onAccept = function()
				if type(PurchaseSlot) == "function" then
					S.SafeCall("bags:buyslot", PurchaseSlot)
				end
				C_Timer.After(0.2, function()
					local w = ns.Core and ns.Core.windows and ns.Core.windows.bank
					if w and w.bagStrip then w.bagStrip:UpdatePaint() end
				end)
			end,
		})
		return
	end
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
		b.bankSlot = BankSlotIndex(bag)
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
			if self.buyable then
				GameTooltip:AddLine(L["Buy bank slot"], 0.92, 0.68, 0.20)
				local cost = NextSlotCost()
				if cost then
					GameTooltip:AddLine(
						(L["Cost: %s"]):format(MoneyStr(cost)), 1, 1, 1)
				end
				GameTooltip:AddLine(
					L["Click: purchase the slot"], 0.55, 0.57, 0.62, true)
				GameTooltip:Show()
				S.SetBorderLit(self, true)
				return
			end
			local shown = false
			if inv and self.hasBag and GameTooltip.SetInventoryItem then
				local ok, ret = pcall(GameTooltip.SetInventoryItem,
					GameTooltip, "player", inv)
				shown = ok and ret == true
			end
			if not shown then
				GameTooltip:AddLine(L["Bag slot"], 0.92, 0.68, 0.20)
			end
			-- preferred category badge: show what item type this bag is
			-- designated for (set in SentiUI > Bags > Bag preferences)
			local pref = ns.Core and ns.Core.db and ns.Core.db.bagPref
				and ns.Core.db.bagPref[tostring(self.bag)]
			if pref then
				local label = ns.Categories and ns.Categories.Label
					and ns.Categories.Label(pref) or pref
				GameTooltip:AddLine(
					(L["Holds: %s"]):format(label), 0.92, 0.68, 0.20)
			end
			-- bag contents preview: list up to 8 items in the bag
			local bagID = self.bag
			if type(bagID) == "number" and C_Container
				and C_Container.GetContainerItemInfo then
				local n = 0
				local okC, c = pcall(C_Container.GetContainerNumSlots, bagID)
				if okC and type(c) == "number" then n = c end
				local shown_n = 0
				for slot = 1, n do
					if shown_n >= 8 then
						GameTooltip:AddLine("...", 0.55, 0.57, 0.62)
						break
					end
					local ok, info = pcall(C_Container.GetContainerItemInfo,
						bagID, slot)
					if ok and type(info) == "table"
						and not S.IsSecretTable(info) then
						local name = info.hyperlink
						if type(name) == "string" and name ~= ""
							and not S.IsSecret(name) then
							local short = name:match("%[(.-)%]") or name
							GameTooltip:AddLine("• " .. short,
								0.8, 0.82, 0.88)
							shown_n = shown_n + 1
						end
					end
				end
				if shown_n == 0 then
					GameTooltip:AddLine(L["Empty"], 0.45, 0.47, 0.52)
				end
			end
			if not shown then
				GameTooltip:AddLine(
					L["Drag a bag here to equip it, click an equipped bag to pick it up."],
					0.55, 0.57, 0.62, true)
			end
			GameTooltip:Show()
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

-- Bank.BuySlot: toolbar-accessible slot purchase. Tries every API name the
-- client might expose; falls back to StaticPopup_Show for the game's own
-- confirm dialog, then shows the Blizzard BankFrame as last resort.
local function TryPurchase()
	local fns = {
		PurchaseSlot, BankFramePurchaseSlot, PurchaseBankSlot,
		BuyBankSlot,
		C_Bank and C_Bank.PurchaseSlot,
		C_Bank and C_Bank.PurchaseNextBankSlot,
		C_Bank and C_Bank.BuyNextBankSlot,
	}
	for _, fn in ipairs(fns) do
		if type(fn) == "function" then
			-- securecall first: on this client slot purchase may be a
			-- protected function that only runs from game context
			if type(securecall) == "function" then
				securecall(fn)
			else
				S.SafeCall("bags:buyslot", fn)
			end
			return true
		end
	end
	-- BankFrame sub-buttons may carry a working purchase path: look
	-- for the game's own purchase button and click it programmatically
	local bf = _G.BankFrame
	if type(bf) == "table" then
		for _, key in ipairs({ "PurchaseButton", "BuyButton",
			"BankFramePurchaseButton" }) do
			local btn = bf[key] or _G[key]
			if type(btn) == "table" and btn.Click then
				S.SafeCall("bags:buyslot", btn.Click, btn)
				return true
			end
		end
	end
end

-- un-park the Blizzard BankFrame and show it so its native slot
-- purchase buttons work; it was reparented under the hidden holder
-- by Blizzard.lua's Park() call
local function ShowBankFrame()
	local bf = _G.BankFrame
	if type(bf) ~= "table" or not bf.SetParent then return end
	pcall(bf.SetParent, bf, UIParent)
	if bf.Show then pcall(bf.Show, bf) end
end

function Slots.BuySlot()
	local bought = PurchasedBankSlots()
	local total = (type(NUM_BANKBAGSLOTS) == "number" and NUM_BANKBAGSLOTS) or 7
	if bought and bought >= total then
		S.Print(L["All bank slots already purchased."])
		return
	end
	local cost = NextSlotCost()
	local text = L["Buy the next bank slot?"]
	if cost then text = text .. "\n|cffebad33" .. MoneyStr(cost) .. "|r" end
	S.Dialog({
		text = text,
		okText = L["Buy"], cancelText = CANCEL or "Cancel",
		onAccept = function()
			if not TryPurchase() then
				-- StaticPopup_Show("CONFIRM_BUY_BANK_SLOT") is NOT a fallback:
				-- the client's own OnAccept handler calls a nil function on
				-- this build. Un-park the Blizzard BankFrame so its own
				-- slot purchase buttons work (it lives under the hidden
				-- holder from Blizzard.lua's Park()).
				ShowBankFrame()
			end
			C_Timer.After(0.3, function()
				local w = ns.Core and ns.Core.windows and ns.Core.windows.bank
				if w and w.bagStrip then w.bagStrip:UpdatePaint() end
			end)
		end,
	})
end
