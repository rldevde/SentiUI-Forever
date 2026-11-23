-- Merchant automation: auto-sell grey items and auto repair when a vendor
-- opens, plus the manual "Sell junk" / "Repair" toolbar actions.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Merchant = {}
ns.Merchant = Merchant

local db
local vendorOpen

local BAG_IDS = { 0, 1, 2, 3, 4 }
if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
	BAG_IDS[#BAG_IDS + 1] = Enum.BagIndex.ReagentBag
end

local function UseItem(bag, slot)
	local f = C_Container and C_Container.UseContainerItem or UseContainerItem
	if f then pcall(f, bag, slot) end
end

-- selling a bag item while a merchant is open is not a protected action
function Merchant.SellJunk()
	local sold = 0
	for _, bag in ipairs(BAG_IDS) do
		local n = 0
		if C_Container and C_Container.GetContainerNumSlots then
			local ok, c = pcall(C_Container.GetContainerNumSlots, bag)
			if ok and type(c) == "number" then n = c end
		end
		for slot = 1, n do
			local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
			if ok and type(info) == "table" and not S.IsSecretTable(info) then
				local q, link = info.quality, info.hyperlink
				-- hasNoValue can be secret: the comparison is pcall'd
				local worthless = false
				pcall(function() worthless = info.hasNoValue == true end)
				if type(q) == "number" and not S.IsSecret(q) and q == 0
					and not S.IsSecret(link) and not worthless then
					UseItem(bag, slot)
					sold = sold + (info.stackCount or 1)
				end
			end
		end
	end
	if sold > 0 then
		print("|cffebad33SentiUI|r " .. L["Grey items sold:"] .. " " .. sold)
	elseif vendorOpen then
		print("|cffebad33SentiUI|r " .. L["No grey items."])
	end
end

-- "12g 34s 56c" without the gold coin icons
local function MoneyStr(c)
	local g, s, k = math.floor(c / 1e4), math.floor(c / 100 % 100), math.floor(c % 100)
	local out = {}
	if g > 0 then out[#out + 1] = g .. "g" end
	if s > 0 then out[#out + 1] = s .. "s" end
	if k > 0 or #out == 0 then out[#out + 1] = k .. "c" end
	return table.concat(out, " ")
end

-- guild funds only when the option is on AND the character is actually
-- allowed to withdraw for repairs; otherwise it's own gold
local function GuildRepairOK()
	if not db.repairGuild then return false end
	if type(IsInGuild) == "function" then
		local ok, g = pcall(IsInGuild)
		if not (ok and g == true) then return false end
	end
	if type(CanGuildBankRepair) == "function" then
		local ok, v = pcall(CanGuildBankRepair)
		if ok and v == false then return false end
	end
	if type(GetGuildBankWithdrawMoney) == "function" then
		local ok, v = pcall(GetGuildBankWithdrawMoney)
		v = ok and v
		if type(v) == "number" and not S.IsSecret(v) and v <= 0 then
			return false
		end
	end
	return true
end

-- repair: guild funds first when allowed, otherwise own gold
function Merchant.Repair()
	if not (type(CanMerchantRepair) == "function" and CanMerchantRepair()) then
		return
	end
	local cost = 0
	local costKnown = false
	if type(GetRepairAllCost) == "function" then
		local ok, c = pcall(GetRepairAllCost)
		if ok and type(c) == "number" and not S.IsSecret(c) then
			cost = c
			costKnown = true
		end
	end
	-- skip early return when cost is secret: we can't know the price but
	-- the repair may still be valid; try anyway and let the game decide
	if costKnown and cost <= 0 then return end
	local paid
	local function callRepair(g)
		if type(securecall) == "function" then
			securecall(RepairAllItems, g)
		else
			pcall(RepairAllItems, g)
		end
	end
	if type(RepairAllItems) == "function" then
		if GuildRepairOK() then
			callRepair(true)
			paid = L["guild funds"]
		else
			callRepair(false)
			paid = L["own gold"]
		end
	end
	if paid then
		print("|cffebad33SentiUI|r " .. L["Repaired for"] .. " "
			.. (costKnown and MoneyStr(cost) or "?") .. " (" .. paid .. ")")
	end
end

local hooked
function Merchant.Enable(d)
	db = d
	if hooked then return end -- settings flips call Enable again; handlers
	hooked = true             -- read db live, so register them exactly once
	-- MERCHANT_SHOW fires inside the vendor-window dispatch; item API
	-- calls (UseContainerItem, RepairAllItems) run a frame later so the
	-- client's own merchant work in that dispatch is not tainted.
	-- Opening the bags window always happens regardless of the toggles —
	-- like the game does when a merchant opens.
	S.RegisterEvent("MERCHANT_SHOW", function()
		vendorOpen = true
		-- forceOpen keeps Core.Sync from closing the window right away:
		-- IsAnyBagOpen() reads the game's own bag frames, not ours, and
		-- would report false while the merchant is open.
		if ns.Core then ns.Core.forceOpen = true end
		C_Timer.After(0, function()
			if ns.Core and ns.Core.Open then ns.Core.Open() end
			if db.autoRepair then S.SafeCall("bags:repair", Merchant.Repair) end
			if db.sellJunk then S.SafeCall("bags:sell", Merchant.SellJunk) end
		end)
	end)
	S.RegisterEvent("MERCHANT_CLOSED", function()
		vendorOpen = false
		if ns.Core then
			ns.Core.forceOpen = nil
			ns.Core.Close()
		end
	end)
end
