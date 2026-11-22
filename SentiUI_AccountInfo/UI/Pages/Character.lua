-- luacheck: read globals GameTooltip GetServerTime
local _, ns = ...

-- Character detail: worn gear, bags and bank of the selected character
-- as icon grids with quality borders and stack counts. Data comes from
-- the stored snapshot — other characters are never touched in-game.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12
local CELL = 38
local GAP = 5
local ROW_H = CELL + GAP

local function QualityRGB(q)
	local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
	if c and q > 1 then
		return c.r, c.g, c.b
	end
	return 0.25, 0.25, 0.28
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

local function Build(content)
	local page = {}
	local selected -- char key, nil = own

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	-- Grid column count follows the viewport width so the cells never
	-- run off the right edge when the window is resized.
	local cols = 14
	local scroll, holder = W.ScrollArea(panel, function(width)
		local n = math.max(4, math.floor((width - PAD * 2 + GAP) / ROW_H))
		if n ~= cols then
			cols = n
			page:Refresh()
		end
	end)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -9, 1)

	local head = W.Text(holder, "GameFontNormal", W.GOLD)
	head:SetPoint("TOPLEFT", PAD, -PAD)
	head:SetText(L.TAB_CHARACTER)

	local dropdown = W.Dropdown(holder, 200, function()
		local out = {}
		for _, key in ipairs(Store.CharKeys()) do
			out[#out + 1] = { value = key, label = ns.ShortName(key) }
		end
		return out
	end, function()
		return selected or Store.OwnKey() or ""
	end, function(value)
		selected = value
		page:Refresh()
	end)
	dropdown:SetPoint("TOPLEFT", PAD, -34)

	local info = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	info:SetPoint("LEFT", dropdown, "RIGHT", 12, 0)

	local hint = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	hint:SetPoint("TOPLEFT", PAD, -62)
	hint:SetText(L.DETAIL_BANK_HINT)

	-- Section headers + icon cell pools.
	local sections = {}
	local function Section(name)
		local s = { name = name, cells = {}, used = 0 }
		s.header = W.Text(holder, "GameFontNormal", W.GOLD)
		s.empty = W.Text(holder, "GameFontDisableSmall", W.MUTED)
		s.empty:SetText(L.DETAIL_EMPTY)
		sections[#sections + 1] = s
		return s
	end
	local gearSec = Section("gear")
	local bagsSec = Section("bags")
	local bankSec = Section("bank")
	local mailSec = Section("mail")

	local setsText = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	setsText:SetPoint("RIGHT", -PAD, 0)
	setsText:SetJustifyH("LEFT")

	local statsText = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	statsText:SetJustifyH("LEFT")

	local noteHead = W.Text(holder, "GameFontNormal", W.GOLD)
	noteHead:SetText(L.DETAIL_NOTE)

	local noteBox = W.EditBox(holder, 320, function(text)
		local key = selected or Store.OwnKey()
		local char = key and Store.Char(key)
		if char then
			char.note = (text ~= "" and text) or nil
		end
	end)
	noteBox:SetMaxLetters(200)

	local actHead = W.Text(holder, "GameFontNormal", W.GOLD)
	actHead:SetText(L.DETAIL_ACTIVITY)
	local actText = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	actText:SetJustifyH("LEFT")
	actText:SetJustifyV("TOP")
	actText:SetWordWrap(true)

	local questHead = W.Text(holder, "GameFontNormal", W.GOLD)
	questHead:SetText(L.DETAIL_QLIST)
	local questText = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	questText:SetJustifyH("LEFT")
	questText:SetJustifyV("TOP")
	questText:SetWordWrap(true)

	local function Cell(sec)
		sec.used = sec.used + 1
		local b = sec.cells[sec.used]
		if not b then
			b = CreateFrame("Button", nil, holder, "BackdropTemplate")
			b:SetSize(CELL, CELL)
			b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
				edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
			b:SetBackdropColor(0.1, 0.1, 0.12, 0.85)
			b.icon = b:CreateTexture(nil, "ARTWORK")
			b.icon:SetPoint("TOPLEFT", 3, -3)
			b.icon:SetPoint("BOTTOMRIGHT", -3, 3)
			b.count = W.Text(b, "GameFontHighlightSmall", W.WHITE)
			b.count:SetPoint("BOTTOMRIGHT", -2, 2)
			b.count:SetJustifyH("RIGHT")
			sec.cells[sec.used] = b
		end
		b:Show()
		return b
	end

	-- Lays a list of { id, count } into a section's grid at y; returns
	-- the y offset below it.
	local function FillGrid(sec, title, list, y, emptyText)
		sec.header:SetPoint("TOPLEFT", PAD, y)
		sec.header:SetText(title)
		y = y - 22
		for _, b in ipairs(sec.cells) do
			b:Hide()
		end
		sec.used = 0
		if #list == 0 then
			sec.empty:SetPoint("TOPLEFT", PAD, y)
			sec.empty:SetText(emptyText or L.DETAIL_EMPTY)
			sec.empty:Show()
			return y - 18
		end
		sec.empty:Hide()
		local x = 0
		for _, item in ipairs(list) do
			local b = Cell(sec)
			b:SetPoint("TOPLEFT", PAD + x, y)
			b.icon:SetTexture(Store.ItemIcon(item.id))
			local r, g, bl = QualityRGB(item.quality or Store.ItemQuality(item.id))
			b:SetBackdropBorderColor(r, g, bl, 1)
			b.count:SetText(item.count and item.count > 1 and item.count or "")
			local id = item.id
			b:SetScript("OnEnter", function(self)
				SetItemTooltip(self, id)
			end)
			b:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			x = x + CELL + GAP
			if x + CELL > cols * (CELL + GAP) then
				x = 0
				y = y - ROW_H
			end
		end
		return y - CELL - 14
	end

	local function SortedCounts(counts)
		local list = {}
		for id, count in pairs(counts or {}) do
			list[#list + 1] = { id = id, count = count,
				name = Store.ItemName(id), quality = Store.ItemQuality(id) }
		end
		table.sort(list, function(a, b)
			if (a.quality or 0) ~= (b.quality or 0) then
				return (a.quality or 0) > (b.quality or 0)
			end
			return (a.name or "") < (b.name or "")
		end)
		return list
	end

	local function GearList(gear)
		local list = {}
		if gear then
			for slot = 1, 19 do
				local id = gear[slot]
				if id then
					list[#list + 1] = { id = id, count = 1, slot = slot,
						name = Store.ItemName(id), quality = Store.ItemQuality(id) }
				end
			end
		end
		return list
	end

	function page:SelectChar(key)
		selected = key
		if dropdown.Refresh then
			dropdown:Refresh()
		end
		self:Refresh()
	end

	function page:Refresh()
		local key = selected or Store.OwnKey()
		local char = key and Store.Char(key)
		if not char then
			info:SetText("")
		else
			local color = char.class and W.ClassColorHex(char.class) or "ffffffff"
			info:SetText(("|c%s%s|r%s"):format(color, char.name or ns.ShortName(key),
				char.guild and ("  <" .. char.guild .. ">") or ""))
		end
		if dropdown.Refresh then
			dropdown:Refresh()
		end
		local y = -86
		char = char or {}
		y = FillGrid(gearSec, L.DETAIL_GEAR, GearList(char.gear), y)
		local sets = char.stats and char.stats.equipSets
		if sets and #sets > 0 then
			local names = {}
			for _, set in ipairs(sets) do
				names[#names + 1] = set.name
			end
			setsText:ClearAllPoints()
			setsText:SetPoint("TOPLEFT", PAD, y)
			setsText:SetText(L.DETAIL_SETS .. "  " .. table.concat(names, "  ·  "))
			setsText:Show()
			y = y - 18
		else
			setsText:Hide()
		end
		y = FillGrid(bagsSec, L.DETAIL_BAGS, SortedCounts(char.bags), y)
		y = FillGrid(bankSec, L.DETAIL_BANK, SortedCounts(char.bank), y,
			not char.bankAt and L.CHAR_BANK_NEVER or L.DETAIL_EMPTY)
		y = FillGrid(mailSec, L.DETAIL_MAIL,
			SortedCounts(char.mail and char.mail.items), y,
			not char.mailAt and L.DETAIL_MAIL_NEVER or L.DETAIL_EMPTY)

		-- Compact fact line: durability, quest log, profession cooldowns,
		-- mail expiry - all from the stored snapshot.
		local facts = {}
		local s = char.stats or {}
		if s.durability then
			facts[#facts + 1] = (s.durability < 50 and "|cffe04d4d" or "")
				.. L.DETAIL_DURA:format(s.durability)
				.. (s.durability < 50 and "|r" or "")
		end
		if char.quests then
			facts[#facts + 1] = L.DETAIL_QUESTS:format(char.quests.count or 0)
		end
		local cds = Store.ProfCooldowns(key)
		if #cds > 0 then
			local now = GetServerTime()
			local bits = {}
			for _, cd in ipairs(cds) do
				bits[#bits + 1] = ("%s |cffebad33%s|r"):format(cd.n,
					W.Duration(cd.x - now))
			end
			facts[#facts + 1] = L.DETAIL_PROFCD .. "  " .. table.concat(bits, "  ")
		end
		if char.mail and char.mail.expireDays and char.mail.expireDays <= 3 then
			facts[#facts + 1] = "|cffe04d4d"
				.. L.DETAIL_MAIL_EXPIRE:format(char.mail.expireDays) .. "|r"
		end
		if #facts > 0 then
			statsText:ClearAllPoints()
			statsText:SetPoint("TOPLEFT", PAD, y)
			statsText:SetText(table.concat(facts, "   ·   "))
			statsText:Show()
			y = y - 20
		else
			statsText:Hide()
		end

		noteHead:ClearAllPoints()
		noteHead:SetPoint("TOPLEFT", PAD, y)
		noteBox:ClearAllPoints()
		noteBox:SetPoint("TOPLEFT", PAD + 70, y + 4)
		noteBox:SetWidth(math.max(120, (scroll:GetWidth() or 400) - PAD * 2 - 70))
		if noteBox:GetText() ~= (char.note or "") then
			noteBox:SetText(char.note or "")
		end
		y = y - 30

		-- Recent changes: item/gold deltas captured by the scanner.
		local lines = {}
		local act = char.activity
		if act then
			for i = #act, math.max(1, #act - 4), -1 do
				local e = act[i]
				local ago = W.Duration(GetServerTime() - (e.t or 0))
				local bits = {}
				if e.items then
					for id, d in pairs(e.items) do
						local name = Store.ItemName(id) or ("#" .. id)
						bits[#bits + 1] = (d > 0 and "|cff4dd25d+" or "|cffe04d4d")
							.. d .. "x " .. name .. "|r"
					end
				end
				if e.gold and e.gold ~= 0 then
					local g = math.floor(math.abs(e.gold) / 10000 + 0.5)
					bits[#bits + 1] = (e.gold > 0 and "|cff4dd25d+" or "|cffe04d4d-")
						.. g .. "g|r"
				end
				lines[#lines + 1] = ("|cff8c919f%s|r  %s"):format(ago,
					table.concat(bits, "  "))
			end
		end
		if #lines > 0 then
			actHead:ClearAllPoints()
			actHead:SetPoint("TOPLEFT", PAD, y)
			actText:ClearAllPoints()
			actText:SetPoint("TOPLEFT", PAD, y - 18)
			actText:SetWidth(math.max(120, (scroll:GetWidth() or 400) - PAD * 2))
			actText:SetText(table.concat(lines, "\n"))
			actHead:Show()
			actText:Show()
			y = y - 20 - #lines * 15
		else
			actHead:Hide()
			actText:Hide()
		end

		-- Quest titles from the stored quest-log snapshot.
		local qlist = char.quests and char.quests.list
		if qlist and #qlist > 0 then
			questHead:ClearAllPoints()
			questHead:SetPoint("TOPLEFT", PAD, y)
			questHead:SetText(L.DETAIL_QLIST .. "  |cff8c919f("
				.. (char.quests.count or #qlist) .. ")|r")
			questText:ClearAllPoints()
			questText:SetPoint("TOPLEFT", PAD, y - 18)
			questText:SetWidth(math.max(120, (scroll:GetWidth() or 400) - PAD * 2))
			local shown = math.min(#qlist, 25)
			local titles = {}
			for i = 1, shown do
				titles[#titles + 1] = "· " .. qlist[i]
			end
			if #qlist > shown then
				titles[#titles + 1] = ("|cff8c919f… +%d|r"):format(#qlist - shown)
			end
			questText:SetText(table.concat(titles, "\n"))
			questHead:Show()
			questText:Show()
			y = y - 20 - #titles * 15
		else
			questHead:Hide()
			questText:Hide()
		end
		holder:SetHeight(-y + PAD)
	end

	return page
end

UI.RegisterPage(3, L.TAB_CHARACTER, Build)
