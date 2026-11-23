-- The bank window: same builder as the bags window, fed with the bank
-- container (-1) plus the equipped bank bags and the reagent bank when the
-- client has one. Opens/closes with the game's BANKFRAME events; the
-- Blizzard BankFrame itself is hidden by Blizzard.lua.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Bank = {}
ns.Bank = Bank

local BANK_IDS = { -1 } -- BANK_CONTAINER
local BANK_SLOT_IDS = {}
do
	local n = (type(NUM_BANKBAGSLOTS) == "number" and NUM_BANKBAGSLOTS) or 7
	for i = 6, 5 + n do
		BANK_IDS[#BANK_IDS + 1] = i
		BANK_SLOT_IDS[#BANK_SLOT_IDS + 1] = i
	end
	local reag = (type(REAGENTBANK_CONTAINER) == "number" and REAGENTBANK_CONTAINER)
		or -3
	BANK_IDS[#BANK_IDS + 1] = reag
end

local function SortBank()
	for _, f in ipairs({
		C_Container and C_Container.SortBank,
		C_Container and C_Container.SortBankBags,
		SortBankBags }) do
		if type(f) == "function" then pcall(f) return end
	end
end

function Bank.Open()
	local w = ns.Core.windows.bank
	if not w then return end
	w.frame:Show()
	ns.Core.Refresh()
end

function Bank.Close()
	local w = ns.Core.windows.bank
	if w then w.frame:Hide() end
end

function Bank.Enable()
	-- no own bank window: the Blizzard BankFrame stays visible and
	-- carries its native slot purchase UI. The bank events below still
	-- open the carried-bags window alongside it like the game does.
	for _, ev in ipairs({ "PLAYERBANKSLOTS_CHANGED",
		"PLAYERREAGENTBANKSLOTS_CHANGED", "BANK_TABS_CHANGED" }) do
		S.RegisterEvent(ev, ns.Core.Refresh)
	end
	-- the events fire inside the client's bank open/close dispatch; the
	-- window work goes one frame out so the client's own follow-up in that
	-- dispatch (bank slots carry secret values) runs untainted
	S.RegisterEvent("BANKFRAME_OPENED", function()
		C_Timer.After(0, function()
			S.SafeCall("bags:bank", function()
				Bank.Open()
				ns.Core.Open() -- bags ride along, like the game's own frames
			end)
		end)
	end)
	S.RegisterEvent("BANKFRAME_CLOSED", function()
		C_Timer.After(0, function()
			S.SafeCall("bags:bank", Bank.Close)
		end)
	end)
end
