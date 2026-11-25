-- AccountInfo plugin: the bottom bar shows the character count and the
-- account's total gold from SentiUI_AccountInfo; click opens the
-- window, the menu offers open/rescan and the richest characters.
local _, ns = ...
local S = SentiUI
local L = ns.L
local P = ns.Plugins
local TipHead, TipKV, TipSub = ns.TipHead, ns.TipKV, ns.TipSub
local format, floor = string.format, math.floor

local function AI()
	local a = _G.SentiUI_AccountInfo or _G.SentiAccountInfo
	if a and a.Store and a.db then return a end
end

local function MoneyStr(copper)
	copper = tonumber(copper) or 0
	local g, s = floor(copper / 10000), floor(copper % 10000 / 100)
	if g > 0 then return format("%dg %ds", g, s) end
	if s > 0 then return s .. "s" end
	return copper .. "c"
end

local function CharKeys()
	local a = AI()
	return a and a.Store.CharKeys() or {}
end

ns.RegisterPlugin({
	id = "accountinfo",
	label = "AccountInfo",
	icon = [[Interface\AddOns\SentiUI_AccountInfo\Media\Logo.tga]],
	bar = "bottom", zone = "CENTER", order = 56,
	events = { "PLAYER_MONEY", "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD" },
	update = function()
		local a = AI()
		if not a then return "" end
		return format("|cff%s%s|r |cff8c919f%d|r", ns.accentHex,
			MoneyStr(a.Store.TotalMoney()), a.Store.CharCount())
	end,
	tooltip = function(tip)
		TipHead(tip, "AccountInfo")
		local a = AI()
		if not a then
			tip:AddLine("|cff8c919f" .. L["Module not loaded"] .. "|r")
			return
		end
		TipKV(tip, L["Characters"], a.Store.CharCount())
		TipKV(tip, L["Total gold"], MoneyStr(a.Store.TotalMoney()))
		local own = a.Store.OwnKey()
		local char = own and a.db.chars[own]
		if char and char.money then
			TipKV(tip, a.ShortName(own), MoneyStr(char.money))
		end
		TipSub(tip, L["Click: open window"])
	end,
	click = function()
		local a = AI()
		if a and a.UI then a.UI.Toggle() end
	end,
	menu = function(def, items)
		local a = AI()
		if not a then
			items[#items + 1] = { text = L["Module not loaded"], disabled = true }
			return
		end
		items[#items + 1] = { text = L["Open"], onClick = function() a.UI.Toggle() end }
		if a.Scanner and a.Scanner.Rescan then
			items[#items + 1] = { text = L["Rescan now"], onClick = function()
				S.SafeCall("panel:accountinfo:scan", a.Scanner.Rescan)
			end }
		end
		-- richest characters first
		local chars = {}
		for _, key in ipairs(CharKeys()) do
			local c = a.db.chars[key]
			if c then chars[#chars + 1] = { key = key, money = tonumber(c.money) or 0 } end
		end
		table.sort(chars, function(x, y) return x.money > y.money end)
		items[#items + 1] = { text = " ", disabled = true }
		for i = 1, math.min(5, #chars) do
			local e = chars[i]
			items[#items + 1] = {
				text = a.ShortName(e.key) .. "  |cff8c919f" .. MoneyStr(e.money) .. "|r",
				onClick = function() a.UI.Show() end,
			}
		end
	end,
})
