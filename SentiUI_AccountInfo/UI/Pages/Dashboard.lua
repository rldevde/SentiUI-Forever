-- luacheck: read globals GetServerTime Auctionator C_AddOns
local _, ns = ...

-- Dashboard: account-wide overview drawn from the stored snapshots -
-- gold per character bars, class and level distribution, totals.
-- All bars are plain textures, no chart library needed.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12
local BAR_H = 18
local BAR_GAP = 3
local LABEL_W = 150
local VALUE_W = 110
local MAX_BARS = 40

local function Build(content)
	local page = {}

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	local scroll, holder = W.ScrollArea(panel, function()
		page:Refresh()
	end)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -9, 1)

	local summary = W.Text(holder, "GameFontNormal", W.GOLD)
	summary:SetPoint("TOPLEFT", PAD, -PAD)

	local summarySub = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	summarySub:SetPoint("TOPLEFT", PAD, -34)
	summarySub:SetPoint("RIGHT", -PAD, 0)
	summarySub:SetJustifyH("LEFT")

	local warnLine = W.Text(holder, "GameFontHighlightSmall", W.MUTED)
	warnLine:SetPoint("TOPLEFT", PAD, -50)
	warnLine:SetPoint("RIGHT", -PAD, 0)
	warnLine:SetJustifyH("LEFT")

	local sections = {}
	local function Section()
		local s = { used = 0, bars = {} }
		s.header = W.Header(holder, "")
		sections[#sections + 1] = s
		return s
	end
	local goldSec = Section()
	local classSec = Section()
	local levelSec = Section()

	local function Bar(sec)
		sec.used = sec.used + 1
		local b = sec.bars[sec.used]
		if not b then
			b = CreateFrame("Frame", nil, holder)
			b:SetHeight(BAR_H)
			b.label = W.Text(b, "GameFontHighlightSmall", W.TEXT)
			b.label:SetPoint("LEFT", 0, 0)
			b.label:SetWidth(LABEL_W)
			b.label:SetWordWrap(false)
			b.label:SetJustifyH("LEFT")
			b.track = b:CreateTexture(nil, "BACKGROUND")
			b.track:SetHeight(BAR_H - 6)
			b.track:SetColorTexture(1, 1, 1, 0.05)
			b.fill = b:CreateTexture(nil, "ARTWORK")
			b.fill:SetHeight(BAR_H - 6)
			b.value = W.Text(b, "GameFontHighlightSmall", W.MUTED)
			b.value:SetPoint("RIGHT", 0, 0)
			b.value:SetWidth(VALUE_W)
			b.value:SetJustifyH("LEFT")
			sec.bars[sec.used] = b
		end
		b:Show()
		return b
	end

	-- entries = { {label, value, r,g,b, text} }; bars fill the remaining
	-- width proportional to the biggest value.
	local function FillBars(sec, title, entries, y)
		sec.header:ClearAllPoints()
		sec.header:SetPoint("TOPLEFT", PAD, y)
		sec.header:SetText(title)
		y = y - 24
		for _, b in ipairs(sec.bars) do
			b:Hide()
		end
		sec.used = 0
		if #entries == 0 then
			return y
		end
		local max = 0
		for _, e in ipairs(entries) do
			if e.value > max then
				max = e.value
			end
		end
		local barX = PAD + LABEL_W + 6
		local barMax = math.max(40, (holder:GetWidth() or 400) - barX - VALUE_W - PAD)
		for i, e in ipairs(entries) do
			if i > MAX_BARS then
				break
			end
			local b = Bar(sec)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", PAD, y)
			b:SetPoint("TOPRIGHT", -PAD, y)
			b.label:SetText(e.label)
			b.track:ClearAllPoints()
			b.track:SetPoint("LEFT", barX, 0)
			b.track:SetWidth(barMax)
			b.fill:ClearAllPoints()
			b.fill:SetPoint("LEFT", barX, 0)
			b.fill:SetWidth(math.max(1, barMax * (max > 0 and e.value / max or 0)))
			b.fill:SetColorTexture(e.r or 0.92, e.g or 0.68, e.b or 0.20, 0.85)
			b.value:SetText(e.text or tostring(e.value))
			y = y - BAR_H - BAR_GAP
		end
		return y - 10
	end

	local function ClassRGB(classFile)
		local hex = classFile and W.ClassColorHex(classFile) or nil
		if hex and #hex >= 8 then
			return tonumber(hex:sub(3, 4), 16) / 255,
				tonumber(hex:sub(5, 6), 16) / 255,
				tonumber(hex:sub(7, 8), 16) / 255
		end
		return W.GOLD[1], W.GOLD[2], W.GOLD[3]
	end

	function page:Refresh()
		local keys = Store.CharKeys()
		local totalMoney = Store.TotalMoney()
		local accounts = {}
		local totalItems = 0
		for _, key in ipairs(keys) do
			local char = ns.db.chars[key]
			accounts[Store.AccountOf(char) or L.ACCOUNT_THIS] = true
			totalItems = totalItems + Store.ItemKindCount(char.bags)
				+ Store.ItemKindCount(char.bank)
		end
		local nAccounts = 0
		for _ in pairs(accounts) do
			nAccounts = nAccounts + 1
		end
		summary:SetText(L.DASH_SUMMARY:format(Store.CharCount(),
			W.Money(totalMoney), nAccounts))

		-- Totals: combined playtime, honorable kills and - when
		-- Auctionator is loaded - the estimated auction value of every
		-- stored bag/bank item.
		local played, hks = 0, 0
		for _, key in ipairs(keys) do
			local char = ns.db.chars[key]
			played = played + (char.played and char.played.total or 0)
			hks = hks + (char.stats and char.stats.pvpHK or 0)
		end
		local sub = { L.DASH_SUMMARY_SUB:format(totalItems) }
		if played > 0 then
			sub[#sub + 1] = L.DASH_TOTAL_PLAYED:format(W.Playtime(played))
		end
		if hks > 0 then
			sub[#sub + 1] = L.DASH_TOTAL_HK:format(hks)
		end
		local api = Auctionator and Auctionator.API
			and Auctionator.API.v1 and Auctionator.API.v1.GetAuctionPriceByItemID
		if api then
			local worth = 0
			for _, key in ipairs(keys) do
				local char = ns.db.chars[key]
				for _, tbl in ipairs({ char.bags, char.bank }) do
					for id, n in pairs(tbl or {}) do
						local ok, price = pcall(api, "SentiAccountInfo", id)
						if ok and type(price) == "number" then
							worth = worth + price * (n or 1)
						end
					end
				end
			end
			if worth > 0 then
				sub[#sub + 1] = L.DASH_TOTAL_WORTH:format(
					W.Money(math.floor(worth + 0.5)))
			end
		end
		summarySub:SetText(table.concat(sub, "   ·   "))

		-- Warnings: stale snapshots, expiring mail, low durability.
		local warn = {}
		local stale = Store.StaleChars(7)
		if #stale > 0 then
			local names = {}
			for i = 1, math.min(4, #stale) do
				names[#names + 1] = ns.ShortName(stale[i].key)
			end
			warn[#warn + 1] = "|cffebad33" .. L.DASH_WARN_STALE:format(
				#stale, table.concat(names, ", ")
					.. (#stale > 4 and "…" or "")) .. "|r"
		end
		for _, key in ipairs(keys) do
			local char = ns.db.chars[key]
			if char.mail and char.mail.expireDays and char.mail.expireDays <= 3 then
				warn[#warn + 1] = "|cffe04d4d" .. L.DASH_WARN_MAIL:format(
					ns.ShortName(key), char.mail.expireDays) .. "|r"
			end
			local dura = char.stats and char.stats.durability
			if dura and dura < 50 then
				warn[#warn + 1] = "|cffe04d4d" .. L.DASH_WARN_DURA:format(
					ns.ShortName(key), dura) .. "|r"
			end
			-- Currency near cap (>= 90% of max).
			for _, cur in ipairs(char.currencies or {}) do
				if cur.max and cur.max > 0 and cur.qty
					and cur.qty >= cur.max * 0.9 then
					warn[#warn + 1] = "|cffebad33" .. L.DASH_WARN_CAP:format(
						ns.ShortName(key), cur.name or "?") .. "|r"
				end
			end
			-- Lockout expiring within 24h.
			for _, lo in ipairs(char.lockouts or {}) do
				local left = lo.resetAt and (lo.resetAt - GetServerTime())
				if left and left > 0 and left < 86400 then
					warn[#warn + 1] = "|cffebad33" .. L.DASH_WARN_LOCK:format(
						ns.ShortName(key), lo.name or "?") .. "|r"
					break
				end
			end
			-- Bags nearly full (< 10% free).
			local s = char.stats
			if s and s.bagSlots and s.bagSlots > 0
				and (s.freeBagSlots or 0) < s.bagSlots * 0.1 then
				warn[#warn + 1] = "|cffebad33" .. L.DASH_WARN_BAGS:format(
					ns.ShortName(key), s.freeBagSlots or 0) .. "|r"
			end
		end
		warnLine:SetText(table.concat(warn, "   ·   "))
		warnLine:SetShown(#warn > 0)

		-- Gold per character, richest first.
		local goldEntries = {}
		for _, key in ipairs(keys) do
			local char = ns.db.chars[key]
			if (char.money or 0) > 0 then
				local r, g, b = ClassRGB(char.class)
				local delta = Store.GoldDelta(key, 7)
				local text = W.Money(char.money)
				if delta and delta ~= 0 then
					local g = math.floor(math.abs(delta) / 10000 + 0.5)
					text = text .. (delta > 0
						and ("  |cff4dd25d+%dg|r"):format(g)
						or ("  |cffe04d4d-%dg|r"):format(g))
				end
				goldEntries[#goldEntries + 1] = {
					label = char.name or ns.ShortName(key),
					value = char.money,
					text = text,
					r = r, g = g, b = b,
				}
			end
		end
		table.sort(goldEntries, function(a, b)
			return a.value > b.value
		end)

		-- Class distribution.
		local classCounts = {}
		for _, key in ipairs(keys) do
			local char = ns.db.chars[key]
			local cls = char.class or "?"
			classCounts[cls] = (classCounts[cls] or 0) + 1
		end
		local classEntries = {}
		for cls, n in pairs(classCounts) do
			local r, g, b = ClassRGB(cls ~= "?" and cls or nil)
			classEntries[#classEntries + 1] = {
				label = cls, value = n, text = tostring(n), r = r, g = g, b = b }
		end
		table.sort(classEntries, function(a, b)
			return a.value > b.value
		end)

		-- Level distribution, highest level first.
		local levelCounts = {}
		for _, key in ipairs(keys) do
			local char = ns.db.chars[key]
			local lvl = tonumber(char.level) or 0
			levelCounts[lvl] = (levelCounts[lvl] or 0) + 1
		end
		local levelEntries = {}
		for lvl, n in pairs(levelCounts) do
			levelEntries[#levelEntries + 1] = {
				label = L.CHAR_LEVEL:format(lvl), value = n, text = tostring(n),
				lvl = lvl,
				r = W.BLUE[1], g = W.BLUE[2], b = W.BLUE[3] }
		end
		table.sort(levelEntries, function(a, b)
			return a.lvl > b.lvl
		end)

		local y = warnLine:IsShown() and -70 or -56
		y = FillBars(goldSec, L.DASH_GOLD, goldEntries, y)
		y = FillBars(classSec, L.DASH_CLASSES, classEntries, y)
		y = FillBars(levelSec, L.DASH_LEVELS, levelEntries, y)
		holder:SetHeight(-y + PAD)
	end

	return page
end

UI.RegisterPage(10, L.TAB_DASHBOARD, Build)
