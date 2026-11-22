-- luacheck: read globals GameTooltip GetServerTime StaticPopupDialogs StaticPopup_Show
local _, ns = ...

-- Characters page: every known character grouped by account, with money,
-- item counts and last-scan time. Rows come from a pool; the list is
-- rebuilt on each refresh.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12
local ROW_H = 40
local HEADER_H = 26

StaticPopupDialogs["SAI_DELETE_CHAR"] = {
	text = L.CHAR_DELETE_CONFIRM,
	button1 = L.DELETE,
	button2 = CANCEL,
	OnAccept = function(_, data)
		if data then
			Store.DeleteChar(data)
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function TimeAgo(ts)
	if not ts then
		return L.NEVER
	end
	return L.TIME_AGO:format(W.Duration(GetServerTime() - ts))
end

local function Build(content)
	local page = {}
	local classFilter -- nil = all
	local sortMode = "name" -- name | level | gold

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	-- Class filter: options are rebuilt from the classes actually present
	-- in the snapshot list.
	local filter = W.Dropdown(panel, 150, function()
		local seen, out = {}, { { value = "", label = L.FILTER_ALL_CLASSES } }
		for _, key in ipairs(Store.CharKeys()) do
			local cls = ns.db.chars[key] and ns.db.chars[key].class
			if cls and not seen[cls] then
				seen[cls] = true
				local color = W.ClassColorHex(cls)
				out[#out + 1] = { value = cls,
					label = ("|c%s%s|r"):format(color, cls) }
			end
		end
		return out
	end, function()
		return classFilter or ""
	end, function(value)
		classFilter = (value ~= "" and value) or nil
		page:Refresh()
	end)
	filter:SetPoint("TOPRIGHT", -8, -6)
	filter:SetFrameLevel(panel:GetFrameLevel() + 5)

	-- Sort order for the character rows inside each account group.
	local sorter = W.Dropdown(panel, 120, function()
		return {
			{ value = "name", label = L.SORT_NAME },
			{ value = "level", label = L.SORT_LEVEL },
			{ value = "gold", label = L.SORT_GOLD },
		}
	end, function()
		return sortMode
	end, function(value)
		sortMode = value or "name"
		page:Refresh()
	end)
	sorter:SetPoint("TOPRIGHT", filter, "TOPLEFT", -8, 0)
	sorter:SetFrameLevel(panel:GetFrameLevel() + 5)

	local scroll, holder = W.ScrollArea(panel)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -9, 1)

	local pool = {}
	local used = 0

	local function Row()
		used = used + 1
		local row = pool[used]
		if not row then
			row = CreateFrame("Button", nil, holder, "BackdropTemplate")
			row:SetHeight(ROW_H)
			row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
			row:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3], 0.6)
			row:SetBackdropBorderColor(0, 0, 0, 0)
			row:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
			row:GetHighlightTexture():SetVertexColor(0.92, 0.68, 0.20, 0.06)

			row.spec = row:CreateTexture(nil, "ARTWORK")
			row.spec:SetSize(16, 16)
			row.spec:SetPoint("TOPLEFT", 10, -7)
			row.name = W.Text(row, "GameFontHighlight", W.TEXT)
			row.name:SetPoint("TOPLEFT", row.spec, "TOPRIGHT", 6, 1)
			row.info = W.Text(row, "GameFontDisableSmall", W.MUTED)
			row.info:SetPoint("LEFT", row.name, "RIGHT", 8, -1)
			row.sub = W.Text(row, "GameFontDisableSmall", W.MUTED)
			row.sub:SetPoint("TOPLEFT", 10, -22)
			row.money = W.Text(row, "GameFontHighlight", W.TEXT)
			row.money:SetPoint("RIGHT", -30, 0)
			row.del = W.CloseButton(row, 18)
			row.del:SetPoint("RIGHT", -6, 0)
			W.Tooltip(row.del, L.CHAR_DELETE_TIP)
			pool[used] = row
		end
		row:Show()
		return row
	end

	local headerPool = {}
	local headerUsed = 0
	local function AccountHeader()
		headerUsed = headerUsed + 1
		local h = headerPool[headerUsed]
		if not h then
			h = CreateFrame("Frame", nil, holder)
			h:SetHeight(HEADER_H)
			h.label = W.Text(h, "GameFontNormal", W.GOLD)
			h.label:SetPoint("LEFT", 2, 0)
			h.money = W.Text(h, "GameFontHighlightSmall", W.MUTED)
			h.money:SetPoint("RIGHT", -4, 0)
			h.line = h:CreateTexture(nil, "ARTWORK")
			h.line:SetHeight(1)
			h.line:SetPoint("BOTTOMLEFT", 0, 0)
			h.line:SetPoint("BOTTOMRIGHT", 0, 0)
			h.line:SetColorTexture(0.92, 0.68, 0.20, 0.35)
			headerPool[headerUsed] = h
		end
		h:Show()
		return h
	end

	local function FillRow(row, key, char, isOwn)
		local color = char.class and W.ClassColorHex(char.class) or "ffffffff"
		local specIcon = char.stats and char.stats.spec and char.stats.spec.icon
		row.spec:SetTexture(specIcon or 134400)
		row.spec:SetShown(specIcon ~= nil)
		row.name:SetText(("|c%s%s|r"):format(color, char.name or ns.ShortName(key)))
		local info = {}
		if char.level then
			info[#info + 1] = L.CHAR_LEVEL:format(char.level)
		end
		if char.guild then
			info[#info + 1] = "<" .. char.guild .. ">"
		end
		row.info:SetText(table.concat(info, "  "))
		local sub = {}
		sub[#sub + 1] = L.CHAR_BAGS_COUNT:format(Store.ItemKindCount(char.bags))
		if char.bankAt then
			sub[#sub + 1] = L.CHAR_BANK_COUNT:format(Store.ItemKindCount(char.bank))
		else
			sub[#sub + 1] = L.CHAR_BANK_NEVER
		end
		sub[#sub + 1] = L.CHAR_LAST_SEEN:format(TimeAgo(char.updated))
		row.sub:SetText(table.concat(sub, "  ·  "))
		row.money:SetText(W.Money(char.money or 0))
		row.key = key
		row.del:SetShown(not isOwn)
		row.del:SetScript("OnClick", function()
			StaticPopup_Show("SAI_DELETE_CHAR", ns.ShortName(key), nil, key)
		end)
		row:SetScript("OnClick", function()
			UI.Show(3)
			local detail = UI.GetCurrentTab()
			if detail and detail.SelectChar then
				detail:SelectChar(key)
			end
		end)
	end

	function page:Refresh()
		-- Reset pool markers and hide leftovers.
		used = 0
		headerUsed = 0
		for _, row in ipairs(pool) do
			row:Hide()
		end
		for _, h in ipairs(headerPool) do
			h:Hide()
		end
		local width = math.max(100, scroll:GetWidth() - 4)
		local y = -6
		local lastAccount, accountMoney, lastHeader
		local ownKey = Store.OwnKey()
		-- Group filtered keys by account (keeps first-seen order), then
		-- sort within each group by the chosen mode.
		local groups, order = {}, {}
		for _, key in ipairs(Store.CharKeys()) do
			local char = ns.db.chars[key]
			if not classFilter or char.class == classFilter then
				local account = Store.AccountOf(char) or L.ACCOUNT_THIS
				local g = groups[account]
				if not g then
					g = {}
					groups[account] = g
					order[#order + 1] = account
				end
				g[#g + 1] = key
			end
		end
		for _, account in ipairs(order) do
			local keys = groups[account]
			table.sort(keys, function(a, b)
				local ca, cb = ns.db.chars[a], ns.db.chars[b]
				if sortMode == "gold" then
					return (ca.money or 0) > (cb.money or 0)
				elseif sortMode == "level" then
					return (ca.level or 0) > (cb.level or 0)
				end
				return tostring(ca.name or ns.ShortName(a))
					< tostring(cb.name or ns.ShortName(b))
			end)
			local accountMoney = 0
			for _, key in ipairs(keys) do
				accountMoney = accountMoney + (tonumber(ns.db.chars[key].money) or 0)
			end
			local lastHeader = AccountHeader()
			lastHeader:SetPoint("TOPLEFT", 0, y)
			lastHeader:SetPoint("TOPRIGHT", 0, y)
			lastHeader.label:SetText(account)
			lastHeader.money:SetText(W.Money(accountMoney))
			y = y - HEADER_H
			for _, key in ipairs(keys) do
				local row = Row()
				row:SetWidth(width)
				row:SetPoint("TOPLEFT", 0, y)
				FillRow(row, key, ns.db.chars[key], key == ownKey)
				y = y - ROW_H - 4
			end
		end
		holder:SetHeight(-y + 10)
	end

	return page
end

UI.RegisterPage(1, L.TAB_CHARACTERS, Build)
