-- luacheck: read globals GameTooltip C_Item
local _, ns = ...

-- Item search across every known character: bag + bank + worn counts
-- aggregated per item, with an optional per-character filter. Hovering a
-- row shows the item tooltip; the owner breakdown is in the second line.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12
local ROW_H = 34
local MAX_OWNERS_INLINE = 3

local QUALITY_COLOR = {}
local function QualityHex(q)
	if q == nil then
		return "ffffffff"
	end
	if not QUALITY_COLOR[q] then
		local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
		-- c.hex is a full escape ("|cff1eff00") - callers embed it in
		-- "|c%s...|r", so keep only the 8 hex digits.
		QUALITY_COLOR[q] = c and c.hex
			and (c.hex:match("^|c(%x%x%x%x%x%x%x%x)") or c.hex) or "ffffffff"
	end
	return QUALITY_COLOR[q]
end

local function SetItemTooltip(owner, itemID)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	if GameTooltip.SetItemByID then
		GameTooltip:SetItemByID(itemID)
	else
		GameTooltip:SetHyperlink("item:" .. itemID)
	end
	GameTooltip:Show()
end

local function OwnerBreakdown(itemID)
	local parts = {}
	for _, entry in ipairs(Store.OwnersOf(itemID)) do
		local bits = {}
		if entry.bags > 0 then
			bits[#bits + 1] = L.TOOLTIP_BAGS .. " x" .. entry.bags
		end
		if entry.bank > 0 then
			bits[#bits + 1] = L.TOOLTIP_BANK .. " x" .. entry.bank
		end
		if entry.mail and entry.mail > 0 then
			bits[#bits + 1] = L.TOOLTIP_MAIL .. " x" .. entry.mail
		end
		if entry.gear > 0 then
			bits[#bits + 1] = L.TOOLTIP_WORN
		end
		local color = entry.char.class and W.ClassColorHex(entry.char.class) or "ffffffff"
		parts[#parts + 1] = ("|c%s%s|r (%s)"):format(color, ns.ShortName(entry.key),
			table.concat(bits, "·"))
	end
	if #parts > MAX_OWNERS_INLINE then
		local rest = #parts - MAX_OWNERS_INLINE
		for i = #parts, MAX_OWNERS_INLINE + 1, -1 do
			parts[i] = nil
		end
		parts[#parts + 1] = L.TOOLTIP_MORE:format(rest)
	end
	return table.concat(parts, "   ")
end

local function Build(content)
	local page = {}
	local query = ""
	local charFilter -- nil = all characters

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	local header = W.Text(panel, "GameFontNormal", W.GOLD)
	header:SetPoint("TOPLEFT", PAD, -PAD)
	header:SetText(L.SEARCH_TITLE)

	local hint = W.Text(panel, "GameFontDisableSmall", W.MUTED)
	hint:SetPoint("LEFT", header, "RIGHT", 10, 0)
	hint:SetPoint("RIGHT", -PAD, 0)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.SEARCH_HINT)

	local search = W.SearchBox(panel, 220, L.SEARCH_PLACEHOLDER, function(text)
		query = text or ""
		page:Refresh()
	end)
	search:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)

	local dropdown = W.Dropdown(panel, 160, function()
		local out = { { value = false, label = L.SEARCH_ALL_CHARS } }
		for _, key in ipairs(Store.CharKeys()) do
			out[#out + 1] = { value = key, label = ns.ShortName(key) }
		end
		return out
	end, function()
		return charFilter or false
	end, function(value)
		charFilter = value or nil
		page:Refresh()
	end)
	dropdown:SetPoint("LEFT", search, "RIGHT", 10, 0)

	local stats = W.Text(panel, "GameFontDisableSmall", W.MUTED)
	stats:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)

	local scroll, holder = W.ScrollArea(panel)
	scroll:SetPoint("TOPLEFT", PAD, -64)
	scroll:SetPoint("BOTTOMRIGHT", -PAD - 8, PAD)

	local empty = W.Text(panel, "GameFontDisable")
	empty:SetPoint("CENTER")
	empty:SetWidth(440)
	empty:SetJustifyH("CENTER")
	empty:SetText(L.SEARCH_EMPTY)

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

			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetSize(26, 26)
			row.icon:SetPoint("LEFT", 4, 0)
			row.name = W.Text(row, "GameFontHighlight", W.TEXT)
			row.name:SetPoint("TOPLEFT", 38, -5)
			row.owners = W.Text(row, "GameFontDisableSmall", W.MUTED)
			row.owners:SetPoint("TOPLEFT", 38, -19)
			row.owners:SetPoint("RIGHT", -70, 0)
			row.owners:SetJustifyH("LEFT")
			row.owners:SetWordWrap(false)
			row.total = W.Text(row, "GameFontHighlight", W.GOLD)
			row.total:SetPoint("RIGHT", -8, 0)
			pool[used] = row
		end
		row:Show()
		return row
	end

	function page:Refresh()
		used = 0
		for _, row in ipairs(pool) do
			row:Hide()
		end
		local results = Store.SearchItems(query, charFilter)
		empty:SetShown(#results == 0 and query ~= "")
		stats:SetText(#results > 0 and tostring(#results) or "")
		local width = math.max(100, scroll:GetWidth() - 4)
		local y = 0
		for _, item in ipairs(results) do
			local row = Row()
			row:SetWidth(width)
			row:SetPoint("TOPLEFT", 0, y)
			row.icon:SetTexture(item.icon)
			local name = item.name or ("#" .. item.id)
			row.name:SetText(("|c%s%s|r"):format(QualityHex(item.quality), name))
			row.owners:SetText(OwnerBreakdown(item.id))
			row.total:SetText(L.SEARCH_RESULT_TOTAL:format(item.total))
			local id = item.id
			row:SetScript("OnEnter", function(self)
				SetItemTooltip(self, id)
			end)
			row:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			y = y - ROW_H - 4
		end
		holder:SetHeight(math.max(1, -y))
	end

	return page
end

UI.RegisterPage(2, L.TAB_SEARCH, Build)
