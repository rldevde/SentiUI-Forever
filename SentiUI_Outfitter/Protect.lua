local _, ns = ...
local S = ns.Outfitter
local L = S.L

-- Sell protection. Selling can't be blocked without tainting the secure
-- bag/merchant code, so a protected item that gets sold is bought back
-- immediately from the vendor's buyback list (same price, nothing lost).
-- need[itemID] = copies that must stay in the possession of the player
-- (bags, equipped or bank) because at least one outfit uses them.

local need = {}
local merchantOpen = false
local busy = false

local function Enabled()
	return S.db and S.db.ui.protectSell ~= false
end

local function Call(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, a, b, c, d = pcall(fn, ...)
	if ok then return a, b, c, d end
	return nil
end

local function HeldCount(itemID)
	local fn = (C_Item and C_Item.GetItemCount) or GetItemCount
	return Call(fn, itemID, true) or 0
end

-- itemID -> highest number of copies one single outfit needs
local function ComputeNeed()
	local out = {}
	for _, set in ipairs(S:GetSets()) do
		local okL, locations = pcall(function() return S.ES.GetItemLocations(set.id) end)
		if okL and locations then
			local ignored = S:GetIgnoredSlots(set.id)
			local perSet = {}
			for slotID, loc in pairs(locations) do
				if not ignored[slotID] and type(loc) == "number" and loc > 1 then
					local itemID = S:ItemIDFromLocation(loc)
					if itemID then perSet[itemID] = (perSet[itemID] or 0) + 1 end
				end
			end
			for itemID, n in pairs(perSet) do
				if n > (out[itemID] or 0) then out[itemID] = n end
			end
		end
	end
	return out
end

-- while the vendor is open the table only grows, so a refresh after a
-- sale can never un-protect the item that was just sold
local function Refresh(reset)
	if not Enabled() then return end
	local fresh = ComputeNeed()
	if reset then need = fresh return end
	for itemID, n in pairs(fresh) do
		if n > (need[itemID] or 0) then need[itemID] = n end
	end
end

function S:IsSellProtected(itemID)
	if not (itemID and Enabled()) then return false end
	if merchantOpen then return (need[itemID] or 0) > 0 end
	local sets = S:GetSetsForItem(itemID)
	return sets ~= nil and #sets > 0
end

local function BuybackLoop()
	if busy or not merchantOpen or not Enabled() then return end
	busy = true
	local n = Call(GetNumBuybackItems) or 0
	local restored
	for i = n, 1, -1 do
		local link = Call(GetBuybackItemLink, i)
		local itemID = link and S:ItemIDFromLink(link)
		local required = itemID and need[itemID]
		if required and HeldCount(itemID) < required then
			Call(BuybackItem, i)
			restored = restored or {}
			restored[#restored + 1] = link
		end
	end
	busy = false
	if restored then
		for _, link in ipairs(restored) do
			S:Print(L["Protected outfit item bought back"] .. ": " .. link)
		end
	end
end

local function Schedule()
	if not merchantOpen then return end
	C_Timer.After(0.25, BuybackLoop)
end

function S:ProtectDebug()
	local n = 0
	for itemID, c in pairs(merchantOpen and need or ComputeNeed()) do
		n = n + 1
		if n <= 8 then S:Print("  protect item " .. itemID .. " x" .. c) end
	end
	S:Print("protected items: " .. n .. ", merchant open: " .. tostring(merchantOpen))
end

function S:InitProtect()
	if S._protectInit then return end
	S._protectInit = true

	S:On("MERCHANT_SHOW", function()
		merchantOpen = true
		Refresh(true)
	end)
	S:On("MERCHANT_CLOSED", function()
		merchantOpen = false
	end)
	S:On("MERCHANT_UPDATE", Schedule)
	S:On("BAG_UPDATE_DELAYED", Schedule)
	S:On("PLAYER_EQUIPMENT_CHANGED", function() if merchantOpen then Refresh(false) end end)
	hooksecurefunc(S, "RefreshSets", function() if merchantOpen then Refresh(false) end end)
end
