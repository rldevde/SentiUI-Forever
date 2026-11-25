local _, ns = ...
local S = ns.Outfitter
local L = S.L
local GOLD = S.GOLD

local hooked = false

-- ===================================================================
-- itemID extraction per tooltip method (secret-safe, signature-tolerant)
-- ===================================================================
local function IDFromBag(bag, slot)
	if C_Container and C_Container.GetContainerItemID then
		local ok, id = pcall(C_Container.GetContainerItemID, bag, slot)
		if ok and id and id > 0 then return id end
	end
	local ok, link = pcall(GetContainerItemLink, bag, slot)
	if ok and link then return S:ItemIDFromLink(link) end
	return nil
end

local function IDFromInventory(...)
	local args = { ... }
	-- modern signature: (unit, slot); legacy: (slot)
	local slot = args[#args]
	for _, try in ipairs({
		function() return GetInventoryItemID("player", slot) end,
		function() return GetInventoryItemID(slot) end,
	}) do
		local ok, id = pcall(try)
		if ok and id and id > 0 then return id end
	end
	local ok, link = pcall(GetInventoryItemLink, "player", slot)
	if not (ok and link) then ok, link = pcall(GetInventoryItemLink, slot) end
	if ok and link then return S:ItemIDFromLink(link) end
	return nil
end

local function IDFromLink(link)
	return S:ItemIDFromLink(link)
end

local function AddOutfitLine(tooltip, itemID)
	local mode = S.db.tooltip.mode
	if mode == "NEVER" then return end
	if mode == "OOC" and InCombatLockdown() then return end

	local names = S:GetSetsForItem(itemID)
	if not names or #names == 0 then return end

	local text
	if #names <= 3 then
		text = table.concat(names, ", ")
	else
		text = table.concat(names, ", ", 1, 3) .. " (+" .. (#names - 3) .. ")"
	end

	tooltip:AddLine(L["Used in outfits"] .. ": " .. text, GOLD[1], GOLD[2], GOLD[3])
	if S.db.ui.protectSell ~= false then
		tooltip:AddLine(L["Protected from selling"], 1, 0.35, 0.35)
	end
end

function S:InitTooltip()
	if hooked then return end
	hooked = true

	local function Hook(method, fn)
		if GameTooltip[method] then
			hooksecurefunc(GameTooltip, method, fn)
		end
	end

	Hook("SetBagItem", function(self, bag, slot)
		AddOutfitLine(self, IDFromBag(bag, slot))
	end)

	Hook("SetInventoryItem", function(self, ...)
		AddOutfitLine(self, IDFromInventory(...))
	end)

	Hook("SetHyperlink", function(self, link)
		AddOutfitLine(self, IDFromLink(link))
	end)

	Hook("SetContainerItem", function(self, bag, slot)
		AddOutfitLine(self, IDFromBag(bag, slot))
	end)

	Hook("SetMerchantItem", function(self, merchant, slot)
		local ok, link = pcall(GetMerchantItemLink, merchant, slot)
		AddOutfitLine(self, ok and link and IDFromLink(link) or nil)
	end)

	Hook("SetLootItem", function(self, slot)
		local ok, link = pcall(GetLootSlotLink, slot)
		AddOutfitLine(self, ok and link and IDFromLink(link) or nil)
	end)

	Hook("SetBuybackItem", function(self, slot)
		local ok, link = pcall(GetBuybackItemLink, slot)
		AddOutfitLine(self, ok and link and IDFromLink(link) or nil)
	end)

	Hook("SetInboxItem", function(self, index)
		local ok, link = pcall(GetInboxItemLink, index)
		AddOutfitLine(self, ok and link and IDFromLink(link) or nil)
	end)

	Hook("SetQuestItem", function(self, qtype, slot)
		local ok, link = pcall(GetQuestItemLink, qtype, slot)
		AddOutfitLine(self, ok and link and IDFromLink(link) or nil)
	end)

	Hook("SetTradePlayerItem", function(self, slot)
		local ok, link = pcall(GetTradePlayerItemLink, slot)
		AddOutfitLine(self, ok and link and IDFromLink(link) or nil)
	end)

	Hook("SetTradeTargetItem", function(self, slot)
		local ok, link = pcall(GetTradeTargetItemLink, slot)
		AddOutfitLine(self, ok and link and IDFromLink(link) or nil)
	end)

	-- refresh cached item->sets map when gear, bags or sets change
	S:On("PLAYER_EQUIPMENT_CHANGED", function() S:InvalidateItemSets() end)
	S:On("BAG_UPDATE", function() S:InvalidateItemSets() end)
end
