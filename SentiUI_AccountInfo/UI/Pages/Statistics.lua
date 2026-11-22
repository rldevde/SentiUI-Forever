-- luacheck: read globals GetServerTime GetAchievementInfo
local _, ns = ...

-- Statistics page: two sub-tabs ("Reiter").
--   Overview: sortable table of every known character — level, item
--     level, gold, playtime, achievement points, zone, last seen.
--   Details: one character's stats — XP/rested, location, hearthstone,
--     collections, free bag slots and professions.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12
local ROW_H = 26
local TAB_H = 24

local function TimeAgo(ts)
	if not ts then
		return L.NEVER
	end
	return L.TIME_AGO:format(W.Duration(GetServerTime() - ts))
end

local function NilDash(v)
	return v == nil and "-" or tostring(v)
end

--------------------------------------------------------------------------------
-- Columns for the overview table
--------------------------------------------------------------------------------

local COLUMNS = {
	{ key = "name", label = L.STAT_COL_NAME, width = 170,
		value = function(k, c)
			local color = c.class and W.ClassColorHex(c.class) or "ffffffff"
			return ("|c%s%s|r"):format(color, c.name or ns.ShortName(k))
		end,
		sort = function(_, c) return (c.name or ""):lower() end },
	{ key = "level", label = L.STAT_COL_LEVEL, width = 50,
		value = function(_, c) return c.level and tostring(c.level) or "-" end,
		sort = function(_, c) return c.level or 0 end },
	{ key = "ilvl", label = L.STAT_COL_ILVL, width = 60,
		value = function(_, c) return c.stats and c.stats.itemLevel
			and tostring(c.stats.itemLevel) or "-" end,
		sort = function(_, c) return (c.stats and c.stats.itemLevel) or 0 end },
	{ key = "money", label = L.STAT_COL_MONEY, width = 120,
		value = function(_, c) return W.Money(c.money or 0) end,
		sort = function(_, c) return c.money or 0 end },
	{ key = "played", label = L.STAT_COL_PLAYED, width = 90,
		value = function(_, c) return c.played and c.played.total
			and W.Playtime(c.played.total) or "-" end,
		sort = function(_, c) return (c.played and c.played.total) or 0 end },
	{ key = "achv", label = L.STAT_COL_ACHV, width = 70,
		value = function(_, c) return c.stats and c.stats.achievementPoints
			and tostring(c.stats.achievementPoints) or "-" end,
		sort = function(_, c) return (c.stats and c.stats.achievementPoints) or 0 end },
	{ key = "zone", label = L.STAT_COL_ZONE, width = 130,
		value = function(_, c) return c.stats and c.stats.zone or "-" end,
		sort = function(_, c) return (c.stats and c.stats.zone) or "" end },
	{ key = "seen", label = L.STAT_COL_SEEN, width = 90,
		value = function(_, c) return TimeAgo(c.updated) end,
		sort = function(_, c) return c.updated or 0 end },
}

--------------------------------------------------------------------------------
-- Page
--------------------------------------------------------------------------------

-- Total pixel width of all columns; the table shrinks proportionally
-- when the window is narrower than this.
local COL_TOTAL = 0
for _, c in ipairs(COLUMNS) do
	COL_TOTAL = COL_TOTAL + c.width
end

local function Build(content)
	local page = {}
	local subTab = 1
	local sortKey = "name"
	local sortAsc = true
	local selected -- char key for the details tab

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	-- Sub-tab row ("Reiter") ---------------------------------------------
	local tabs = {}
	local tabHolder = CreateFrame("Frame", nil, panel)
	tabHolder:SetPoint("TOPLEFT", PAD, -8)
	tabHolder:SetPoint("TOPRIGHT", -PAD, -8)
	tabHolder:SetHeight(TAB_H)

	local function PaintTabs()
		for i, tab in ipairs(tabs) do
			local active = i == subTab
			tab.edge:SetShown(active)
			tab:SetBackdropColor(active and W.BG_RAISED[1] or W.BG_INSET[1],
				active and W.BG_RAISED[2] or W.BG_INSET[2],
				active and W.BG_RAISED[3] or W.BG_INSET[3], 1)
			W.Color(tab.text, active and W.GOLD or W.TEXT)
		end
	end

	local function SelectTab(i)
		subTab = i
		PaintTabs()
		for j, f in ipairs(page.subFrames) do
			f:SetShown(j == i)
		end
		page:Refresh()
	end

	for i, label in ipairs({ L.STAT_TAB_OVERVIEW, L.STAT_TAB_DETAILS,
		L.STAT_TAB_COMPARE }) do
		local tab = CreateFrame("Button", nil, tabHolder, "BackdropTemplate")
		tab:SetSize(120, TAB_H)
		tab:SetPoint("LEFT", (i - 1) * 124, 0)
		tab:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		tab:SetBackdropBorderColor(W.BORDER[1], W.BORDER[2], W.BORDER[3], 1)
		tab.edge = tab:CreateTexture(nil, "BORDER")
		tab.edge:SetPoint("TOPLEFT")
		tab.edge:SetPoint("TOPRIGHT")
		tab.edge:SetHeight(2)
		tab.edge:SetColorTexture(0.92, 0.68, 0.20, 1)
		tab.text = W.Text(tab, "GameFontHighlight", W.TEXT)
		tab.text:SetPoint("CENTER")
		tab.text:SetText(label)
		tab:SetScript("OnClick", function()
			SelectTab(i)
		end)
		tabs[i] = tab
	end

	page.subFrames = {}
	for i = 1, 3 do
		local f = CreateFrame("Frame", nil, panel)
		f:SetPoint("TOPLEFT", 1, -(10 + TAB_H + 6))
		f:SetPoint("BOTTOMRIGHT", -1, 1)
		f:Hide()
		page.subFrames[i] = f
	end

	-- Honest marker for characters never logged in since install: their
	-- snapshot simply does not exist yet, the "-" columns are not data.
	local scanHint = W.Text(tabHolder, "GameFontDisableSmall", W.MUTED)
	scanHint:SetPoint("RIGHT", 0, 0)
	scanHint:SetJustifyH("RIGHT")

	--------------------------------------------------------------------------------
	-- Sub-tab 1: sortable overview table
	--------------------------------------------------------------------------------
	local overview = page.subFrames[1]
	local headerHolder = CreateFrame("Frame", nil, overview, "BackdropTemplate")
	headerHolder:SetPoint("TOPLEFT", PAD, -6)
	headerHolder:SetPoint("TOPRIGHT", -PAD, -6)
	headerHolder:SetHeight(22)
	headerHolder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
	headerHolder:SetBackdropColor(W.BG_RAISED[1], W.BG_RAISED[2], W.BG_RAISED[3], 1)

	local colHeaders = {}
	for _, col in ipairs(COLUMNS) do
		local h = CreateFrame("Button", nil, headerHolder)
		h:SetHeight(22)
		h.text = W.Text(h, "GameFontHighlightSmall", W.MUTED)
		h.text:SetPoint("LEFT", 6, 0)
		h.text:SetText(col.label)
		h:SetScript("OnClick", function()
			if sortKey == col.key then
				sortAsc = not sortAsc
			else
				sortKey = col.key
				sortAsc = true
			end
			page:Refresh()
		end)
		colHeaders[col.key] = h
	end

	local scroll, holder = W.ScrollArea(overview)
	scroll:SetPoint("TOPLEFT", PAD, -30)
	scroll:SetPoint("BOTTOMRIGHT", -PAD - 8, PAD)

	local pool = {}
	local used = 0
	local function Row()
		used = used + 1
		local row = pool[used]
		if not row then
			row = CreateFrame("Frame", nil, holder, "BackdropTemplate")
			row:SetHeight(ROW_H)
			row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
			row.cells = {}
			for _, col in ipairs(COLUMNS) do
				local cell = W.Text(row, "GameFontHighlightSmall", W.TEXT)
				cell:SetWidth(col.width - 8)
				cell:SetJustifyH("LEFT")
				cell:SetWordWrap(false)
				row.cells[col.key] = cell
			end
			pool[used] = row
		end
		row:Show()
		return row
	end

	local function RefreshOverview()
		-- Scale columns into the available width so the table never
		-- runs off the right edge of the window.
		local scale = math.min(1, math.max(200, scroll:GetWidth()) / COL_TOTAL)
		local hx = 0
		for _, col in ipairs(COLUMNS) do
			local h = colHeaders[col.key]
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", hx, 0)
			h:SetWidth(col.width * scale)
			hx = hx + col.width * scale
		end
		for key, h in pairs(colHeaders) do
			local col
			for _, c in ipairs(COLUMNS) do
				if c.key == key then
					col = c
				end
			end
			if key == sortKey then
				W.Color(h.text, W.GOLD)
				h.text:SetText(col.label .. (sortAsc
					and " |TInterface\\Buttons\\Arrow-Up-Up:0|t"
					or " |TInterface\\Buttons\\Arrow-Down-Up:0|t"))
			else
				W.Color(h.text, W.MUTED)
				h.text:SetText(col.label)
			end
		end

		used = 0
		for _, row in ipairs(pool) do
			row:Hide()
		end
		local keys = Store.CharKeys()
		local unscanned = 0
		for _, key in ipairs(keys) do
			if not (ns.db.chars[key] and ns.db.chars[key].statsAt) then
				unscanned = unscanned + 1
			end
		end
		scanHint:SetText(unscanned > 0 and L.STAT_UNSCANNED_N:format(unscanned) or "")
		table.sort(keys, function(a, b)
			local ca, cb = ns.db.chars[a], ns.db.chars[b]
			local va, vb
			for _, col in ipairs(COLUMNS) do
				if col.key == sortKey then
					va, vb = col.sort(a, ca), col.sort(b, cb)
				end
			end
			if va == vb then
				return a < b
			end
			if sortAsc then
				return va < vb
			end
			return va > vb
		end)
		local y = 0
		for i, key in ipairs(keys) do
			local char = ns.db.chars[key]
			local row = Row()
			row:SetPoint("TOPLEFT", 0, y)
			row:SetPoint("TOPRIGHT", 0, y)
			row:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3],
				i % 2 == 0 and 0.35 or 0.6)
			local cx = 6
			for _, col in ipairs(COLUMNS) do
				local cell = row.cells[col.key]
				cell:ClearAllPoints()
				cell:SetPoint("LEFT", cx, 0)
				cell:SetWidth(col.width * scale - 8)
				cell:SetText(col.value(key, char))
				cx = cx + col.width * scale
			end
			y = y - ROW_H
		end
		holder:SetHeight(math.max(1, -y))
	end

	--------------------------------------------------------------------------------
	-- Sub-tab 2: per-character details
	--------------------------------------------------------------------------------
	local detail = page.subFrames[2]

	local dropdown = W.Dropdown(detail, 200, function()
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
	dropdown:SetPoint("TOPLEFT", PAD, -6)

	local dscroll, dholder = W.ScrollArea(detail)
	dscroll:SetPoint("TOPLEFT", 1, -38)
	dscroll:SetPoint("BOTTOMRIGHT", -9, 1)

	local dLines = {}
	local function GetLine(i)
		local line = dLines[i]
		if not line then
			line = CreateFrame("Frame", nil, dholder)
			line:SetHeight(18)
			line.label = W.Text(line, "GameFontHighlightSmall", W.MUTED)
			line.label:SetPoint("LEFT", 0, 0)
			line.label:SetWidth(190)
			line.value = W.Text(line, "GameFontHighlightSmall", W.TEXT)
			line.value:SetPoint("LEFT", 200, 0)
			line.value:SetPoint("RIGHT", 0, 0)
			line.value:SetJustifyH("LEFT")
			dLines[i] = line
		end
		return line
	end

	local function RefreshDetails()
		for _, line in ipairs(dLines) do
			line:Hide()
		end
		local key = selected or Store.OwnKey()
		local char = key and Store.Char(key)
		local y = -6
		local lineIdx = 0
		if not char then
			dholder:SetHeight(10)
			return
		end
		local s = char.stats or {}
		if not char.statsAt then
			local line = GetLine(1)
			lineIdx = 1
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", PAD, y)
			line:SetPoint("TOPRIGHT", -PAD, y)
			line.label:SetText("")
			line.value:SetText("|cffffd100" .. L.STAT_NOT_SCANNED .. "|r")
			line:Show()
			y = y - 26
		end
		local function Place(label, value)
			lineIdx = lineIdx + 1
			local line = GetLine(lineIdx)
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", PAD, y)
			line:SetPoint("TOPRIGHT", -PAD, y)
			line.label:SetText(label)
			line.value:SetText(value)
			line:Show()
		end
		local function Row(label, value)
			Place(label, value)
			y = y - 18
		end
		local function Section(label)
			y = y - 8
			Place("|cffebad33" .. label .. "|r", "")
			y = y - 24
		end

		Section(L.STAT_SEC_CHAR)
		local color = char.class and W.ClassColorHex(char.class) or "ffffffff"
		Row(L.STAT_NAME, ("|c%s%s|r%s"):format(color,
			char.name or ns.ShortName(key),
			char.guild and ("  <" .. char.guild .. ">") or ""))
		Row(L.STAT_LEVEL, char.level and L.CHAR_LEVEL:format(char.level) or "-")
		if s.maxLevel then
			Row(L.STAT_MAXLEVEL, "|cff4dd25d" .. L.YES .. "|r")
		end
		Row(L.STAT_ITEMLEVEL, NilDash(s.itemLevel))
		Row(L.STAT_SPEC, (s.spec and s.spec.name)
			and (s.spec.name .. (s.spec.role and ("  |cff8c919f" .. s.spec.role .. "|r") or ""))
			or "-")
		Row(L.STAT_MONEY, W.Money(char.money or 0))

		Section(L.STAT_SEC_PROGRESS)
		if s.maxLevel then
			Row(L.STAT_XP, L.STAT_MAXLEVEL_REACHED)
		elseif s.xp and s.xpMax and s.xpMax > 0 then
			Row(L.STAT_XP, ("%d / %d  (%.1f%%)"):format(s.xp, s.xpMax,
				s.xp / s.xpMax * 100))
		else
			Row(L.STAT_XP, "-")
		end
		if s.rested and s.xpMax and s.xpMax > 0 then
			Row(L.STAT_RESTED, ("%s  (%.0f%%)"):format(tostring(s.rested),
				s.rested / s.xpMax * 100))
			local eta = Store.RestedSeconds(s)
			if eta == 0 then
				Row(L.STAT_RESTED_ETA, "|cff4dd25d" .. L.STAT_RESTED_FULL .. "|r")
			elseif eta then
				Row(L.STAT_RESTED_ETA, W.Duration(eta))
			end
		else
			Row(L.STAT_RESTED, "-")
		end
		if char.played and char.played.total then
			Row(L.STAT_PLAYED_TOTAL, W.Playtime(char.played.total)
				.. "  |cff8c919f" .. TimeAgo(char.playedAt) .. "|r")
		else
			Row(L.STAT_PLAYED_TOTAL, "-")
		end
		Row(L.STAT_PLAYED_LEVEL, char.played and char.played.level
			and W.Playtime(char.played.level) or "-")

		Section(L.STAT_SEC_WORLD)
		local zone = s.zone or "-"
		if s.subzone then
			zone = zone .. " — " .. s.subzone
		end
		Row(L.STAT_ZONE, zone)
		Row(L.STAT_BIND, s.bind or "-")
		if s.bagSlots then
			Row(L.STAT_FREEBAGS, ("%d / %d"):format(s.freeBagSlots or 0, s.bagSlots))
		else
			Row(L.STAT_FREEBAGS, "-")
		end
		if char.mail then
			Row(L.STAT_MAIL, L.STAT_MAIL_FMT:format(char.mail.count or 0,
				Store.ItemKindCount(char.mail.items), W.Money(char.mail.money or 0)))
		elseif char.mailAt then
			Row(L.STAT_MAIL, "-")
		end
		Row(L.STAT_DURABILITY, s.durability and (s.durability .. "%") or "-")
		if char.quests then
			Row(L.STAT_QUESTS, tostring(char.quests.count or 0))
		end
		if s.pvpHK or s.pvpRank then
			Row(L.STAT_PVP, ("%s%s"):format(tostring(s.pvpHK or 0),
				s.pvpRank and ("  |cff8c919f" .. s.pvpRank .. "|r") or ""))
		end

		Section(L.STAT_SEC_COLLECTIONS)
		Row(L.STAT_ACHV_POINTS, NilDash(s.achievementPoints))
		Row(L.STAT_ACHV_DONE, NilDash(s.achievements))
		Row(L.STAT_MOUNTS, NilDash(s.mounts))
		Row(L.STAT_PETS, NilDash(s.pets))
		Row(L.STAT_TOYS, NilDash(s.toys))
		Row(L.STAT_TITLES, NilDash(s.titles))
		Row(L.STAT_EQUIP_SETS, s.equipSets and tostring(#s.equipSets) or "-")

		Section(L.STAT_SEC_PROFESSIONS)
		if s.professions and #s.professions > 0 then
			for _, prof in ipairs(s.professions) do
				local pct = prof.max > 0 and ("  (%.0f%%)"):format(prof.cur / prof.max * 100) or ""
				Row(prof.name, ("%d / %d%s"):format(prof.cur, prof.max, pct))
			end
		else
			Row(L.STAT_PROFESSIONS, "-")
		end
		local cds = Store.ProfCooldowns(key)
		if #cds > 0 then
			local now = GetServerTime()
			for _, cd in ipairs(cds) do
				Row(cd.n, "|cffebad33" .. W.Duration(cd.x - now) .. "|r")
			end
		end

		-- Achievement watchlist (IDs configured on the settings tab):
		-- shows this character's stored earned flag.
		local wl = ns.db.settings and ns.db.settings.watchlist
		if type(wl) == "table" and #wl > 0 then
			Section(L.STAT_WATCH)
			for _, id in ipairs(wl) do
				id = tonumber(id)
				if id then
					local name
					if GetAchievementInfo then
						local ok, _, n = pcall(GetAchievementInfo, id)
						name = ok and n or nil
					end
					local earned = s.watch and s.watch[id]
					Row(name or ("#" .. id), earned == true
						and "|cff4dd25d✓|r" or "|cffe04d4d✗|r")
				end
			end
		end

		y = y - 14
		Place("", L.CHAR_LAST_SEEN:format(TimeAgo(char.updated)))
		y = y - 22
		dholder:SetHeight(-y + PAD)
	end

	--------------------------------------------------------------------------------
	-- Sub-tab 3: side-by-side comparison of two characters
	--------------------------------------------------------------------------------
	local compare = page.subFrames[3]
	local cmpSel = {}
	local function CmpDropdown(i)
		local dd = W.Dropdown(compare, 200, function()
			local out = { { value = "", label = "-" } }
			for _, key in ipairs(Store.CharKeys()) do
				out[#out + 1] = { value = key, label = ns.ShortName(key) }
			end
			return out
		end, function()
			return cmpSel[i] or (i == 1 and Store.OwnKey()) or ""
		end, function(value)
			cmpSel[i] = (value ~= "" and value) or nil
			page:Refresh()
		end)
		dd:SetPoint("TOPLEFT", i == 1 and PAD + 100 or PAD + 380, -6)
		return dd
	end
	CmpDropdown(1)
	CmpDropdown(2)

	local cscroll, cholder = W.ScrollArea(compare)
	cscroll:SetPoint("TOPLEFT", 1, -38)
	cscroll:SetPoint("BOTTOMRIGHT", -9, 1)

	local cLines = {}
	local function CLine(i)
		local line = cLines[i]
		if not line then
			line = CreateFrame("Frame", nil, cholder)
			line:SetHeight(18)
			line.label = W.Text(line, "GameFontHighlightSmall", W.MUTED)
			line.label:SetPoint("LEFT", 0, 0)
			line.label:SetWidth(90)
			line.left = W.Text(line, "GameFontHighlightSmall", W.TEXT)
			line.left:SetPoint("LEFT", 100, 0)
			line.left:SetWidth(270)
			line.left:SetJustifyH("LEFT")
			line.right = W.Text(line, "GameFontHighlightSmall", W.TEXT)
			line.right:SetPoint("LEFT", 380, 0)
			line.right:SetPoint("RIGHT", 0, 0)
			line.right:SetJustifyH("LEFT")
			cLines[i] = line
		end
		return line
	end

	-- value(key, char) -> display string ("-" for missing data).
	local CMP_ROWS = {
		{ L.STAT_LEVEL, function(_, c) return c.level and L.CHAR_LEVEL:format(c.level) or "-" end },
		{ L.STAT_ITEMLEVEL, function(_, c) return c.stats and NilDash(c.stats.itemLevel) or "-" end },
		{ L.STAT_SPEC, function(_, c) return c.stats and c.stats.spec
			and c.stats.spec.name or "-" end },
		{ L.STAT_MONEY, function(_, c) return W.Money(c.money or 0) end },
		{ L.STAT_COL_PLAYED, function(_, c) return c.played and c.played.total
			and W.Playtime(c.played.total) or "-" end },
		{ L.STAT_ACHV_POINTS, function(_, c) return c.stats
			and NilDash(c.stats.achievementPoints) or "-" end },
		{ L.STAT_MOUNTS, function(_, c) return c.stats and NilDash(c.stats.mounts) or "-" end },
		{ L.STAT_PETS, function(_, c) return c.stats and NilDash(c.stats.pets) or "-" end },
		{ L.STAT_DURABILITY, function(_, c) return c.stats and c.stats.durability
			and (c.stats.durability .. "%") or "-" end },
		{ L.STAT_QUESTS, function(_, c) return c.quests
			and tostring(c.quests.count or 0) or "-" end },
		{ L.STAT_PVP, function(_, c) return c.stats and NilDash(c.stats.pvpHK) or "-" end },
		{ L.STAT_COL_ZONE, function(_, c) return c.stats and c.stats.zone or "-" end },
		{ L.STAT_COL_SEEN, function(_, c) return TimeAgo(c.updated) end },
	}

	local function RefreshCompare()
		for _, line in ipairs(cLines) do
			line:Hide()
		end
		local lc = cmpSel[1] and Store.Char(cmpSel[1])
			or Store.Char(Store.OwnKey())
		local rc = cmpSel[2] and Store.Char(cmpSel[2]) or nil
		local y = -6
		for i, def in ipairs(CMP_ROWS) do
			local line = CLine(i)
			line:ClearAllPoints()
			line:SetPoint("TOPLEFT", PAD, y)
			line:SetPoint("TOPRIGHT", -PAD, y)
			line.label:SetText(def[1])
			line.left:SetText(lc and def[2](cmpSel[1] or Store.OwnKey(), lc) or "-")
			line.right:SetText(rc and def[2](cmpSel[2], rc) or "-")
			line:Show()
			y = y - 20
		end
		cholder:SetHeight(-y + PAD)
	end

	function page:Refresh()
		if subTab == 1 then
			RefreshOverview()
		elseif subTab == 2 then
			RefreshDetails()
		else
			RefreshCompare()
		end
	end

	function page:OnShow()
		PaintTabs()
	end

	SelectTab(1)
	return page
end

UI.RegisterPage(4, L.TAB_STATISTICS, Build)
