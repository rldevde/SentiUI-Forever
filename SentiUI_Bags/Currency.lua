-- Tracked-currency strip: the currencies the player marked "show on
-- backpack" render as icon + amount in the bags footer. Everything goes
-- through pcall - currency data can be secret on this client, in which
-- case the row just shows the icon without an amount.
local _, ns = ...
local S = SentiUI

local Currency = {}
ns.Currency = Currency

local MAX = 3 -- the client tracks at most this many backpack currencies

local function Info(i)
	if not (C_CurrencyInfo and C_CurrencyInfo.GetBackpackCurrencyInfo) then
		return
	end
	local ok, info = pcall(C_CurrencyInfo.GetBackpackCurrencyInfo, i)
	if ok and type(info) == "table" and not S.IsSecretTable(info) then
		return info
	end
end

function Currency.Layout(w)
	if not w.cur then w.cur = {} end
	local shown = ns.Core.db and ns.Core.db.currency ~= false and w.moneyFS
	for i = 1, MAX do
		local info = shown and Info(i) or nil
		local row = w.cur[i]
		if info and (info.name or info.iconFileID) then
			if not row then
				row = { icon = w.frame:CreateTexture(nil, "ARTWORK") }
				row.icon:SetSize(12, 12)
				row.fs = S.Font(w.frame, 10, nil, "OUTLINE")
				w.cur[i] = row
			end
			if type(info.iconFileID) == "number" then
				row.icon:SetTexture(info.iconFileID)
			end
			row.icon:ClearAllPoints()
			if i == 1 then
				row.icon:SetPoint("RIGHT", w.moneyFS, "LEFT", -10, 0)
			else
				row.icon:SetPoint("RIGHT", w.cur[i - 1].fs, "LEFT", -8, 0)
			end
			local q = info.quantity
			if type(q) == "number" and not S.IsSecret(q) then
				row.fs:SetFormattedText("%d", q)
			else
				row.fs:SetText("")
			end
			row.fs:ClearAllPoints()
			row.fs:SetPoint("RIGHT", row.icon, "LEFT", -3, 0)
			row.icon:Show()
			row.fs:Show()
		elseif row then
			row.icon:Hide()
			row.fs:Hide()
		end
	end
end
