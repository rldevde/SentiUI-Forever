-- luacheck: read globals CreateFrame GameTooltip C_Item GetItemInfo math date C_Map C_SuperTrack UiMapPoint WorldMapFrame ToggleWorldMap securecall
local _, ns = ...
local S = SentiUI
local strtrim = strtrim or function(s) return s and s:match("^%s*(.-)%s*$") or "" end

-- Dungeon compendium: boss lists with levels and loot tables plus the
-- quest log for every dungeon, from the vendored compendium data set
-- (ns.DB / ns.ORDER / ns.BOSS_LEVELS). No sync - pure local browsing.
local L = ns.L
local W = ns.Widgets

local PAD = 12
local ROW_H = 22

local QUALITY_HEX = {
	[0] = "9d9d9d", [1] = "ffffff", [2] = "1eff00", [3] = "0070dd",
	[4] = "a335ee", [5] = "ff8000", [6] = "e6cc80",
}

-- content localization: database keys stay English, display text follows
-- the client locale through the vendored ContentLocales tables
local LOCALE_ALIAS = { esMX = "esES", ptPT = "ptBR" }
local function CL()
	local locs = ns.ContentLocales
	if not locs then
		return nil
	end
	local lang = GetLocale and GetLocale() or "enUS"
	return locs[lang] or locs[LOCALE_ALIAS[lang]]
end

local function LocDungeon(name, field)
	local c = CL()
	local e = c and c.dungeons and c.dungeons[name]
	return (e and e[field]) or nil
end

local function LocBoss(name)
	local c = CL()
	return (c and c.bosses and c.bosses[name]) or name
end

local function LocQuest(id, field)
	local c = CL()
	local e = id and c and c.quests and c.quests[id]
	return (e and e[field]) or nil
end

local function LocPlace(text)
	local c = CL()
	return (c and c.places and c.places[text]) or text
end

-- renamed header artwork per dungeon (Media\Compendium)
local MEDIA = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\"
local DUNGEON_ART = {
	["Ruins of Lordaeron"] = "Lordaeron",
	["Scarlet Monastery: Graveyard"] = "MonasteryG",
	["Scarlet Monastery: Library"] = "MonasteryL",
	["The Drowned City"] = "Drowned",
	["Scarlet Monastery: Armory"] = "MonasteryA",
	["Scarlet Monastery: Cathedral"] = "MonasteryC",
	["Razorfen Downs"] = "RFDowns",
	["Uldaman"] = "Uldaman",
	["Krol'dok Stronghold"] = "Kroldok",
	["Zul'Farrak"] = "ZFarrak",
	["Maraudon"] = "Maraudon",
	["Alcaz Prison"] = "Alcaz",
	["Sunken Temple"] = "Temple",
	["Blackrock Depths"] = "Depths",
	["Lower Blackrock Spire"] = "LowerSpire",
	["Upper Blackrock Spire"] = "UpperSpire",
	["Dire Maul: East"] = "DireMaul",
	["Dire Maul: West"] = "DireMaulW",
	["Dire Maul: North"] = "DireMaulN",
	["Blackmaw Hold"] = "Blackmaw",
	["Stratholme: Living"] = "Stratholme",
	["Stratholme: Undead"] = "StratholmeU",
	["Scholomance"] = "Scholomance",
	["Shaper's Terrace"] = "Terrace",
}

-- "Wrist, Cloth" -> translate each part; unknown parts pass through
local function LocSlot(slot)
	local c = CL()
	if not (c and slot) then
		return slot
	end
	local out = {}
	for part in tostring(slot):gmatch("[^,]+") do
		local p = strtrim(part)
		out[#out + 1] = (c.slotParts and c.slotParts[p])
			or (c.replacements and c.replacements[p]) or p
	end
	return table.concat(out, ", ")
end

-- Drops a user waypoint on the world map, super-tracks it and opens the
-- map on the zone. Silently skipped when the client lacks the waypoint
-- API; every call is guarded because the frames may not exist yet.
local function SetWaypoint(pin)
	if not (pin and pin.mapID and C_Map and C_Map.SetUserWaypoint
		and UiMapPoint and UiMapPoint.CreateFromCoordinates) then
		S.Print(L.DJ_NO_WAYPOINT)
		return
	end
	local ok, point = pcall(UiMapPoint.CreateFromCoordinates, pin.mapID, pin.x, pin.y)
	if not (ok and point) then
		return
	end
	-- Waypoint APIs are protected on some builds of this client: a bare call
	-- raises an action-blocked warning pcall cannot catch, so they go
	-- through securecall which lets the client run them in secure context.
	local function WaypointCall(label, fn, ...)
		if type(fn) ~= "function" then
			return false
		end
		ns.MarkCall("map " .. label)
		if type(securecall) == "function" then
			return pcall(securecall, fn, ...)
		end
		return pcall(fn, ...)
	end
	WaypointCall("ClearUserWaypoint", C_Map.ClearUserWaypoint)
	local set = WaypointCall("SetUserWaypoint", C_Map.SetUserWaypoint, point)
	if set and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
		WaypointCall("SetSuperTrackedUserWaypoint", C_SuperTrack.SetSuperTrackedUserWaypoint, true)
	end
	if not set then
		S.Print(L.DJ_NO_WAYPOINT)
	end
	if WorldMapFrame and WorldMapFrame.SetMapID then
		WaypointCall("WorldMapFrame", function()
			WorldMapFrame:SetMapID(pin.mapID)
			WorldMapFrame:Show()
		end)
	elseif type(ToggleWorldMap) == "function" then
		WaypointCall("ToggleWorldMap", ToggleWorldMap)
	end
end

local function HookTip(btn)
	btn:HookScript("OnEnter", function(self)
		if self.tipTitle and GameTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tipTitle, 1, 1, 1)
			if self.tipText then
				GameTooltip:AddLine(self.tipText, nil, nil, nil, true)
			end
			GameTooltip:Show()
		end
	end)
	btn:HookScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
end

local function ItemIcon(id)
	if not id then return nil end
	if C_Item and C_Item.GetItemIconByID then
		local ok, tex = pcall(C_Item.GetItemIconByID, id)
		if ok and tex then return tex end
	end
	if GetItemIcon then
		local ok, tex = pcall(GetItemIcon, id)
		if ok and tex then return tex end
	end
	return nil
end

local function QuestDone(id)
	if not id then return false end
	local fn = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted)
		or IsQuestFlaggedCompleted
	if type(fn) ~= "function" then return false end
	local ok, done = pcall(fn, id)
	return ok and done == true
end

local function ItemLink(item)
	local id, name, slot, quality = item[1], item[2], item[3], item[4]
	local display = name
	if id and C_Item and C_Item.GetItemNameByID then
		display = C_Item.GetItemNameByID(id) or name
	elseif id and GetItemInfo then
		display = GetItemInfo(id) or name
	end
	local hex = QUALITY_HEX[quality or 3] or "ffffff"
	slot = LocSlot(slot)
	return ("|cff%s%s|r%s"):format(hex, display or "?",
		slot and slot ~= "" and ("  |cff8c919f(" .. slot .. ")|r") or "")
end

local function Build(content)
	local page = {}
	local selected
	local lastSelected
	local detailTab = "bosses"

	---------------------------------------------------------
	-- left column: dungeon list
	---------------------------------------------------------
	local left = W.Panel(content)
	left:SetPoint("TOPLEFT", 10, -10)
	left:SetPoint("BOTTOMLEFT", 10, 10)
	left:SetWidth(230)

	local search = W.SearchBox(left, 200, L.HIST_SEARCH, function()
		page:Refresh()
	end)
	search:SetPoint("TOPLEFT", PAD, -PAD)
	local searchBox = search.editBox or search

	local lscroll, lholder = W.ScrollArea(left)
	lscroll:SetPoint("TOPLEFT", PAD, -44)
	lscroll:SetPoint("BOTTOMRIGHT", -PAD, PAD)
	lholder.rows = {}

	---------------------------------------------------------
	-- right column: detail
	---------------------------------------------------------
	local right = W.Panel(content)
	right:SetPoint("TOPLEFT", left, "TOPRIGHT", 8, 0)
	right:SetPoint("BOTTOMRIGHT", -10, 10)

	-- header: dungeon artwork as a wide banner; name and meta sit on
	-- the dimmed lower edge. Dungeons without art fall back to icon +
	-- text header. Header height is stored in headerH and everything
	-- below it (description, chips, content) anchors off that.
	local ART_H = 96
	local art = right:CreateTexture(nil, "BACKGROUND")
	art:SetPoint("TOPLEFT", PAD, -PAD)
	art:SetPoint("TOPRIGHT", -PAD, -PAD)
	art:SetHeight(ART_H)
	art:SetTexCoord(0, 1, 0.12, 0.78)
	art:Hide()
	local artDim = right:CreateTexture(nil, "BACKGROUND", nil, 1)
	artDim:SetAllPoints(art)
	artDim:SetColorTexture(0, 0, 0, 0.35)
	artDim:Hide()
	local artFade = right:CreateTexture(nil, "BACKGROUND", nil, 2)
	artFade:SetPoint("BOTTOMLEFT", art)
	artFade:SetPoint("BOTTOMRIGHT", art)
	artFade:SetHeight(28)
	artFade:SetColorTexture(0, 0, 0, 0.55)
	artFade:Hide()

	local dIcon = right:CreateTexture(nil, "ARTWORK")
	dIcon:SetSize(32, 32)
	local dName = W.Text(right, "GameFontNormal", W.GOLD)
	local dMeta = W.Text(right, "GameFontDisableSmall", W.MUTED)
	local dDesc = W.Text(right, "GameFontDisableSmall", W.MUTED)
	dDesc:SetPoint("RIGHT", -PAD, 0)
	dDesc:SetJustifyH("LEFT")
	local headerH = 40

	local wpBtn = W.LinkButton(right, L.DJ_WAYPOINT, function(self)
		SetWaypoint(self.pin)
	end)
	wpBtn:SetPoint("TOPRIGHT", -PAD, -PAD)
	wpBtn:Hide()
	HookTip(wpBtn)

	local chips = {}
	for i, t in ipairs({ { id = "bosses", label = "DJ_BOSSES" }, { id = "quests", label = "DJ_QUESTS" }, { id = "map", label = "DJ_MAP" } }) do
		local chip = W.Chip(right, function()
			detailTab = t.id
			page:Refresh()
		end)
		chip.t = t.id
		chip:SetLabel(L[t.label])
		chip:SetPoint("TOPLEFT", PAD + (i - 1) * 90, -96)
		chips[#chips + 1] = chip
	end

	local rscroll, rholder = W.ScrollArea(right)
	rscroll:SetPoint("BOTTOMRIGHT", -PAD, PAD)
	rholder.rows = {}

	---------------------------------------------------------
	-- map tab: see UI\DungeonMap.lua
	---------------------------------------------------------
	local focusBoss
	local mapShownFor
	local mapView = ns.DungeonMap.Create(right, {
		dungeons = function()
			return ns.DB or {}
		end,
		locBoss = LocBoss,
		locQuest = LocQuest,
		locDungeon = function(name)
			return LocDungeon(name, "name")
		end,
		onBoss = function(idx)
			detailTab = "bosses"
			focusBoss = idx
			page:Refresh()
		end,
	})
	local mapFrame = mapView.panel
	mapFrame:SetPoint("BOTTOMRIGHT", -PAD, PAD)
	mapFrame:Hide()

	local function DrawMap()
		local spec = ns.DUNGEON_MAPS and ns.DUNGEON_MAPS[selected]
		if mapShownFor ~= selected then
			mapShownFor = selected
			mapView:Show(selected, spec)
		else
			mapView:Render()
		end
	end

	---------------------------------------------------------
	-- quest book: list on the left, opened page on the right
	---------------------------------------------------------
	local onlyMine = true
	local selQuest
	local FillQuests

	local factionChip = W.Chip(right, function(self)
		onlyMine = not onlyMine
		self:SetActive(onlyMine)
		page:Refresh()
	end)
	factionChip:SetLabel(L.DJ_ONLY_MINE)
	factionChip:SetActive(true)
	factionChip:Hide()

	local questFrame = CreateFrame("Frame", nil, right)
	questFrame:SetPoint("BOTTOMRIGHT", -PAD, PAD)
	questFrame:Hide()

	local qList = W.Panel(questFrame)
	qList:SetPoint("TOPLEFT")
	qList:SetPoint("BOTTOMLEFT")
	qList:SetWidth(214)
	local qlScroll, qlHolder = W.ScrollArea(qList)
	qlScroll:SetPoint("TOPLEFT", 4, -4)
	qlScroll:SetPoint("BOTTOMRIGHT", -4, 4)
	qlHolder.rows = {}

	local qPage = W.Panel(questFrame, { 0.075, 0.066, 0.052, 0.96 }, { 0.36, 0.28, 0.13, 1 })
	qPage:SetPoint("TOPLEFT", qList, "TOPRIGHT", 6, 0)
	qPage:SetPoint("BOTTOMRIGHT")
	local qpScroll, qpHolder = W.ScrollArea(qPage)
	qpScroll:SetPoint("TOPLEFT", 16, -12)
	qpScroll:SetPoint("BOTTOMRIGHT", -16, 12)

	local qp = { fs = {}, lines = {}, pins = {}, items = {} }

	local function QItem(n)
		local b = qp.items[n]
		if not b then
			b = CreateFrame("Button", nil, qpHolder)
			b:SetHeight(22)
			b.icon = b:CreateTexture(nil, "ARTWORK")
			b.icon:SetSize(18, 18)
			b.icon:SetPoint("LEFT", 2, 0)
			b.text = W.Text(b, "GameFontHighlightSmall")
			b.text:SetPoint("LEFT", b.icon, "RIGHT", 8, 0)
			b.hl = b:CreateTexture(nil, "HIGHLIGHT")
			b.hl:SetAllPoints()
			b.hl:SetColorTexture(1, 1, 1, 0.06)
			b:SetScript("OnEnter", function(self)
				if self.itemId and GameTooltip then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetItemByID(self.itemId)
					GameTooltip:Show()
				end
			end)
			b:SetScript("OnLeave", function()
				if GameTooltip then
					GameTooltip:Hide()
				end
			end)
			qp.items[n] = b
		end
		return b
	end

	local function QPin(n)
		local b = qp.pins[n]
		if not b then
			b = W.LinkButton(qpHolder, L.DJ_SHOW_MAP, function(self)
				SetWaypoint(self.pin)
			end)
			HookTip(b)
			qp.pins[n] = b
		end
		return b
	end

	local qLink = W.LinkButton(qpHolder, "", function(self)
		if self.target then
			selQuest = self.target
			FillQuests(self.dungeon)
		end
	end)
	qLink:Hide()

	local function Difficulty(level)
		if level and GetQuestDifficultyColor then
			local c = GetQuestDifficultyColor(level)
			if c then
				return ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255)
			end
		end
		return "|cffebad33"
	end

	local PROF_NAMES = {
		BLACKSMITHING = "Blacksmithing", MINING = "Mining",
	}
	local function FactionName(f)
		if f == "Alliance" then
			return FACTION_ALLIANCE or L["Alliance"]
		elseif f == "Horde" then
			return FACTION_HORDE or L["Horde"]
		end
		return f
	end

	local function StartsInside(text)
		return type(text) == "string" and text:lower():find("inside ", 1, true) ~= nil
	end

	local function TurnInInside(text, dungeonName)
		if type(text) ~= "string" or text == "" then
			return false
		end
		local t = text:lower()
		if t:find("outside", 1, true) then
			return false
		end
		if t:find("inside", 1, true) then
			return true
		end
		local place = t:match(",%s*([^,]-)%s*$")
		if not place or place == "" or type(dungeonName) ~= "string" then
			return false
		end
		local name = dungeonName:lower()
		return place == name or place == (name:match("^(.-):") or name)
	end

	-- a start item that drops from this dungeon's loot means the quest
	-- starts inside, whatever the pickup text says
	local function StartItemDropsIn(q, d)
		local item = type(q) == "table" and q.startItem
		local id = type(item) == "table" and item[1]
		if not (id and d) then
			return false
		end
		for _, boss in ipairs(d.bosses or {}) do
			for _, loot in ipairs(boss.loot or {}) do
				if type(loot) == "table" and loot[1] == id then
					return true
				end
			end
		end
		return false
	end

	-- the quest itself is gated behind a chain: it is picked up where the
	-- first chain step starts, which can be inside this dungeon
	local function ChainStartsInside(q, d)
		local chain = q and q.id and ns.QUEST_PREREQ_CHAINS and ns.QUEST_PREREQ_CHAINS[q.id]
		if type(chain) ~= "table" or #chain == 0 then
			return nil
		end
		for _, step in ipairs(chain) do
			if type(step) == "table" and step.id ~= q.id then
				local details = ns.QUEST_PREREQ_DETAILS and ns.QUEST_PREREQ_DETAILS[step.id] or {}
				return details.startsInDungeon == true or StartsInside(details.pickup)
					or StartItemDropsIn(details, d)
			end
		end
		return nil
	end

	local function PickupInside(q, d)
		return StartsInside(q.pickup) or StartItemDropsIn(q, d) or ChainStartsInside(q, d) == true
	end

	local function QuestsFor(d)
		local out = {}
		local mine = UnitFactionGroup and UnitFactionGroup("player")
		for idx, q in ipairs(d.quests or {}) do
			local other = q.faction and q.faction ~= "Both" and q.faction ~= mine
			if not (onlyMine and other) and not q.hideFromMainList then
				out[#out + 1] = { q = q, idx = idx }
			end
		end
		table.sort(out, function(a, b)
			local la, lb = a.q.level or 0, b.q.level or 0
			if la ~= lb then
				return la < lb
			end
			return a.idx < b.idx
		end)
		return out
	end

	local function QuestTags(q)
		local tags = {}
		if q.faction and q.faction ~= "Both" then
			tags[#tags + 1] = FactionName(q.faction)
		end
		if q.optional then
			tags[#tags + 1] = L.DJ_OPTIONAL
		end
		if q.repeatable then
			tags[#tags + 1] = L.DJ_REPEATABLE
		end
		if q.profession then
			tags[#tags + 1] = L[PROF_NAMES[q.profession] or q.profession]
		end
		if q.unavailable then
			tags[#tags + 1] = L.DJ_UNAVAILABLE
		end
		return tags
	end

	function FillQuests(d)
		local list = QuestsFor(d)

		-- selection must belong to the visible list
		local found
		for _, e in ipairs(list) do
			if e.q == selQuest then
				found = true
				break
			end
		end
		if not found then
			selQuest = list[1] and list[1].q or nil
		end

		-- left: the quest list
		for _, r in ipairs(qlHolder.rows) do
			r:Hide()
		end
		local ly = 0
		for i, e in ipairs(list) do
			local q = e.q
			local row = qlHolder.rows[i]
			if not row then
				row = CreateFrame("Button", nil, qlHolder)
				row:SetHeight(36)
				row.hl = row:CreateTexture(nil, "BACKGROUND")
				row.hl:SetAllPoints()
				row.hl:SetColorTexture(0.92, 0.68, 0.20, 0.14)
				row.bar = row:CreateTexture(nil, "ARTWORK")
				row.bar:SetPoint("TOPLEFT")
				row.bar:SetPoint("BOTTOMLEFT")
				row.bar:SetWidth(2)
				row.bar:SetColorTexture(0.92, 0.68, 0.20, 1)
				row.mark = row:CreateTexture(nil, "ARTWORK")
				row.mark:SetSize(12, 14)
				row.mark:SetPoint("LEFT", 8, 0)
				row.title = W.Text(row, "GameFontHighlightSmall")
				row.title:SetPoint("TOPLEFT", 26, -5)
				row.title:SetWordWrap(false)
				row.sub = W.Text(row, "GameFontDisableSmall", W.MUTED)
				row.sub:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
				row.sub:SetPoint("RIGHT", -6, 0)
				row.sub:SetWordWrap(false)
				row.over = row:CreateTexture(nil, "HIGHLIGHT")
				row.over:SetAllPoints()
				row.over:SetColorTexture(1, 1, 1, 0.05)
				qlHolder.rows[i] = row
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -ly)
			row:SetPoint("RIGHT", 0, 0)
			local on = q == selQuest
			row.hl:SetShown(on)
			row.bar:SetShown(on)
			row.mark:SetTexture(q.repeatable and "Interface\\GossipFrame\\DailyQuestIcon"
				or "Interface\\GossipFrame\\AvailableQuestIcon")
			row.title:SetText(Difficulty(q.level) .. (LocQuest(q.id, "name") or q.name or "?") .. "|r")
			if not row.inside then
				local ic = CreateFrame("Frame", nil, row)
				ic:SetSize(15, 15)
				ic:SetPoint("RIGHT", -6, 0)
				ic:EnableMouse(true)
				ic.tex = ic:CreateTexture(nil, "OVERLAY")
				ic.tex:SetAllPoints()
				ic.tex:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
				ic.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				ic:SetScript("OnEnter", function(self)
					if GameTooltip then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(L.DJ_IN_DUNGEON)
						GameTooltip:Show()
					end
				end)
				ic:SetScript("OnLeave", function()
					if GameTooltip then
						GameTooltip:Hide()
					end
				end)
				row.inside = ic
			end
			row.inside:SetShown(PickupInside(q, d))
			row.title:SetPoint("RIGHT", -24, 0)
			local tags = QuestTags(q)
			row.sub:SetText(("%s %s%s"):format(L.DJ_LEVEL, q.level or "?",
				#tags > 0 and ("  ·  " .. table.concat(tags, " · ")) or ""))
			row:SetScript("OnClick", function()
				selQuest = q
				qpScroll:SetVerticalScroll(0)
				FillQuests(d)
			end)
			row:Show()
			ly = ly + 36
		end
		qlHolder:SetHeight(math.max(1, ly))
		qlScroll:UpdateScrollChildRect()

		-- right: the opened page
		for _, f in ipairs(qp.fs) do
			f:Hide()
		end
		for _, t in ipairs(qp.lines) do
			t:Hide()
		end
		for _, b in ipairs(qp.pins) do
			b:Hide()
		end
		for _, b in ipairs(qp.items) do
			b:Hide()
		end
		qLink:Hide()

		local q = selQuest
		local y, nfs, nln, npin, nit = 0, 0, 0, 0, 0
		local pw = math.max(220, (qpScroll:GetWidth() or 0))

		local function FS(font)
			nfs = nfs + 1
			local f = qp.fs[nfs]
			if not f then
				f = qpHolder:CreateFontString(nil, "OVERLAY", font)
				f:SetJustifyH("LEFT")
				f:SetWordWrap(true)
				qp.fs[nfs] = f
			end
			f:SetFontObject(font)
			f:ClearAllPoints()
			f:Show()
			return f
		end
		local function Body(text, font, indent)
			indent = indent or 0
			local f = FS(font or "GameFontHighlightSmall")
			f:SetWidth(pw - indent - 4)
			f:SetSpacing(2)
			f:SetPoint("TOPLEFT", qpHolder, "TOPLEFT", indent, -y)
			f:SetText(text)
			y = y + (f:GetStringHeight() or 14) + 6
			return f
		end
		local function Head(text)
			y = y + 10
			local f = FS("GameFontNormalSmall")
			f:SetWidth(0)
			f:SetPoint("TOPLEFT", qpHolder, "TOPLEFT", 0, -y)
			f:SetText("|cff339eff" .. text .. "|r")
			nln = nln + 1
			local t = qp.lines[nln]
			if not t then
				t = qpHolder:CreateTexture(nil, "ARTWORK")
				t:SetHeight(1)
				t:SetColorTexture(0.92, 0.68, 0.20, 0.22)
				qp.lines[nln] = t
			end
			t:ClearAllPoints()
			t:SetPoint("TOPLEFT", qpHolder, "TOPLEFT", 0, -(y + 15))
			t:SetPoint("RIGHT", qpHolder, "RIGHT", -4, 0)
			t:Show()
			local headY = y
			y = y + 22
			return headY, f
		end
		local icons = qp.icons or {}
		qp.icons = icons
		for _, ic in ipairs(icons) do
			ic:Hide()
		end
		local nic = 0
		local function DungeonIcon(hf)
			nic = nic + 1
			local ic = icons[nic]
			if not ic then
				ic = CreateFrame("Frame", nil, qpHolder)
				ic:SetSize(14, 14)
				ic:EnableMouse(true)
				ic.tex = ic:CreateTexture(nil, "OVERLAY")
				ic.tex:SetAllPoints()
				ic.tex:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
				ic.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				ic:SetScript("OnEnter", function(self)
					if GameTooltip then
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						GameTooltip:SetText(L.DJ_IN_DUNGEON)
						GameTooltip:Show()
					end
				end)
				ic:SetScript("OnLeave", function()
					if GameTooltip then
						GameTooltip:Hide()
					end
				end)
				icons[nic] = ic
			end
			ic:ClearAllPoints()
			ic:SetPoint("LEFT", hf, "RIGHT", 8, -1)
			ic:Show()
		end
		local function WP(headY, pin)
			if not pin then
				return
			end
			npin = npin + 1
			local b = QPin(npin)
			b.pin = pin
			b.tipTitle = pin.label or L.DJ_SHOW_MAP
			b.tipText = pin.detail
			b:ClearAllPoints()
			b:SetPoint("TOPRIGHT", qpHolder, "TOPRIGHT", -6, -headY)
			b:Show()
		end

		if not q then
			Body("|cff8c919f" .. (#(d.quests or {}) == 0 and L.DJ_NO_QUESTS or L.DJ_PICK_QUEST) .. "|r")
		else
			local title = FS("GameFontNormalLarge")
			title:SetWidth(pw - 4)
			title:SetPoint("TOPLEFT", qpHolder, "TOPLEFT", 0, -y)
			title:SetText("|cffebad33" .. (LocQuest(q.id, "name") or q.name or "?") .. "|r")
			y = y + (title:GetStringHeight() or 20) + 4

			local meta = { L.DJ_LEVEL .. " " .. (q.level or "?") }
			if q.requires and q.requires > 1 then
				meta[#meta + 1] = L.DJ_REQUIRES .. " " .. q.requires
			end
			for _, tg in ipairs(QuestTags(q)) do
				meta[#meta + 1] = tg
			end
			Body("|cff8c919f" .. table.concat(meta, "   ·   ") .. "|r", "GameFontDisableSmall")

			local rewards = LocQuest(q.id, "rewards") or q.rewards or q.rewardSummary
			local summary = {}
			local xp = rewards and rewards:match("([%d%.,]+)%s*XP") or (q.liveXPFallback and tostring(q.liveXPFallback))
			if xp then
				summary[#summary + 1] = "|cff4dd278" .. xp .. " XP|r"
			end
			if rewards then
				local money = {}
				for num, cur in rewards:gmatch("(%d+)([gsc])") do
					money[#money + 1] = num .. cur
				end
				if #money > 0 then
					summary[#summary + 1] = "|cffe6c35a" .. table.concat(money, " ") .. "|r"
				end
				for rname, rval in rewards:gmatch("([%a\128-\255' %-]+)%+(%d+)") do
					summary[#summary + 1] = "|cff82c5ff" .. strtrim(rname) .. " +" .. rval .. "|r"
				end
			end
			if #summary > 0 then
				Body(table.concat(summary, "    "), "GameFontHighlightSmall")
			end

			local warning = LocQuest(q.id, "warning") or q.warning
			if warning then
				Body("|cffff8040" .. L.DJ_WARNING .. ": " .. warning .. "|r")
			end

			local chain = q.id and ns.QUEST_PREREQ_CHAINS and ns.QUEST_PREREQ_CHAINS[q.id]
			if chain and #chain > 0 then
				Head(L.DJ_REQUIRES_CHAIN)
				for i, step in ipairs(chain) do
					local details = ns.QUEST_PREREQ_DETAILS and ns.QUEST_PREREQ_DETAILS[step.id] or {}
					local target
					for _, e in ipairs(list) do
						if e.q.id and e.q.id == step.id then
							target = e.q
							break
						end
					end
					local lineY = y
					local done = QuestDone(step.id)
					local mark = (details.startsInDungeon or StartItemDropsIn(details, d)
						or TurnInInside(details.turnin, d.name))
						and " |TInterface\\Icons\\INV_Misc_Rune_01:12:12:0:-1|t" or ""
					local stepName = details.name or step.name or ("#" .. tostring(step.id))
					local num = done and ("|cff4dd278%d.|r"):format(i)
						or ("|cffebad33%d.|r"):format(i)
					local suffix = details.level
						and ("  |cff8c919f(" .. L.DJ_LEVEL .. " " .. details.level .. ")|r") or ""
					local tag = done and ("  |cff4dd278(" .. L.DJ_DONE .. ")|r") or ""
					if done then
						Body(num .. " |cff8c919f" .. stepName .. "|r" .. suffix .. tag .. mark)
					elseif target then
						Body(num .. " |cff339eff" .. stepName .. "|r" .. suffix .. mark)
					else
						Body(num .. " " .. stepName .. suffix .. mark)
					end
					if details.map then
						WP(lineY, details.map)
					end
				end
			end

			local objective = LocQuest(q.id, "objective") or q.objective
			if objective then
				local hy2 = Head(L.DJ_OBJECTIVE)
				WP(hy2, q.objectiveMap)
				Body("|cfffff0c0" .. objective .. "|r")
			end

			local pin = (ns.QUEST_START_MAPS and q.id and ns.QUEST_START_MAPS[q.id]) or q.startMap
			local pickup = LocQuest(q.id, "pickup") or (q.pickup and LocPlace(q.pickup))
			if pickup or q.startItem or q.startObject then
				local hy, hf = Head(L.DJ_PICKUP)
				WP(hy, pin)
				if PickupInside(q, d) then
					DungeonIcon(hf)
				end
				if pickup then
					Body("|cffd8dae0" .. pickup .. "|r")
				end
				if q.startItem then
					local iname = q.startItem[2]
					if q.startItem[1] and C_Item and C_Item.GetItemNameByID then
						local okN, n = pcall(C_Item.GetItemNameByID, q.startItem[1])
						if okN and n then iname = n end
					end
					Body("|cff8c919f" .. L.DJ_STARTS .. " " .. (iname or "")
						.. (q.startItem[4] and (" - " .. q.startItem[4]) or "") .. "|r")
				elseif q.startObject then
					Body("|cff8c919f" .. L.DJ_STARTS .. " " .. (q.startObject[1] or "")
						.. (q.startObject[3] and (" - " .. q.startObject[3]) or "") .. "|r")
				end
			end

			local turnin = LocQuest(q.id, "turnin") or (q.turnin and LocPlace(q.turnin))
			if turnin then
				local hy, hf = Head(L.DJ_TURNIN)
				if TurnInInside(q.turnin, d.name) then
					DungeonIcon(hf)
				end
				for _, spot in ipairs(ns.TURNIN_SPOTS or {}) do
					if spot.targetName and q.turnin and q.turnin:find(spot.targetName, 1, true) then
						WP(hy, spot)
						break
					end
				end
				Body("|cffd8dae0" .. turnin .. "|r")
			end

			local note = LocQuest(q.id, "note") or q.note
			if note then
				Head(L.DJ_NOTES)
				Body("|cffa8acb8" .. note:gsub("\n", "\n") .. "|r")
			end

			if q.noteQuestLink then
				Head(L.DJ_CHAIN)
				local target
				for _, e in ipairs(list) do
					if e.q.id and e.q.id == q.noteQuestLink.id then
						target = e.q
						break
					end
				end
				local label = LocQuest(q.noteQuestLink.id, "name") or q.noteQuestLink.name or "?"
				if target then
					qLink.target, qLink.dungeon = target, d
					qLink:SetText(L.DJ_NEXT_QUEST:format(label))
					qLink:ClearAllPoints()
					qLink:SetPoint("TOPLEFT", qpHolder, "TOPLEFT", 0, -y)
					qLink:Show()
					y = y + 22
				else
					Body("|cff339eff" .. L.DJ_NEXT_QUEST:format(label) .. "|r")
				end
			end

			local hasItems = q.rewardItems and #q.rewardItems > 0
			if (rewards and rewards ~= "") or hasItems then
				Head(L.DJ_REWARDS)
				if rewards and rewards ~= "" then
					local text = rewards:gsub("^Choose:[^\n]*\n?", ""):gsub("\n", "   ·   ")
					if text ~= "" then
						Body("|cff4dd278" .. text .. "|r")
					end
				end
				if hasItems then
					Body("|cff8c919f" .. (q.rewardChoice and L.DJ_CHOOSE or L.DJ_RECEIVE) .. ":|r")
					for _, it in ipairs(q.rewardItems) do
						nit = nit + 1
						local b = QItem(nit)
						b.itemId = it[1]
						local nm = it[2]
						if it[1] and C_Item and C_Item.GetItemNameByID then
							nm = C_Item.GetItemNameByID(it[1]) or nm
						end
						local icon = it[1] and ((C_Item and C_Item.GetItemIconByID
							and C_Item.GetItemIconByID(it[1])) or (GetItemIcon and GetItemIcon(it[1])))
						b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
						b.text:SetText(("|cff%s%s|r"):format(QUALITY_HEX[it[3] or 3] or "ffffff", nm or "?"))
						b:ClearAllPoints()
						b:SetPoint("TOPLEFT", qpHolder, "TOPLEFT", 6, -y)
						b:SetPoint("RIGHT", qpHolder, "RIGHT", -4, 0)
						b:Show()
						y = y + 24
					end
				end
			end
		end
		qpHolder:SetHeight(math.max(1, y + 12))
		qpScroll:UpdateScrollChildRect()
	end

	local empty = W.Text(right, "GameFontDisable")
	empty:SetPoint("CENTER")
	empty:SetWidth(360)
	empty:SetJustifyH("CENTER")
	empty:SetText(L.DJ_EMPTY)

	---------------------------------------------------------
	local function FillDetail(d)
		for _, r in ipairs(rholder.rows) do
			r:Hide()
		end
		for _, chip in ipairs(chips) do
			chip:SetActive(chip.t == detailTab)
		end
		local isMap = detailTab == "map"
		local isQuests = detailTab == "quests"
		mapFrame:SetShown(isMap)
		questFrame:SetShown(isQuests)
		rscroll:SetShown(detailTab == "bosses")
		factionChip:SetShown(isQuests)
		if isMap then
			DrawMap()
			return
		end
		if isQuests then
			FillQuests(d)
			return
		end
		local y = 0
		local i = 0
		local bossY = {}
		local function Row(i, h)
			local row = rholder.rows[i]
			if not row then
				row = CreateFrame("Button", nil, rholder)
				row:SetHeight(ROW_H)
				row.line = W.Text(row, "GameFontHighlightSmall")
				row.line:SetPoint("LEFT", 4, 0)
				row.line:SetPoint("RIGHT", -4, 0)
				row.line:SetJustifyH("LEFT")
				row.line:SetWordWrap(false)
				rholder.rows[i] = row
			end
			row:SetHeight(h or ROW_H)
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -y)
			row:SetPoint("RIGHT", -8, 0)
			row.line:ClearAllPoints()
			row.line:SetPoint("LEFT", 4, 0)
			row.line:SetPoint("RIGHT", -8, 0)
			row.line:SetWordWrap(false)
			if row.pin then
				row.pin:Hide()
			end
			if row.lootIcon then
				row.lootIcon:Hide()
				row.lootBg:Hide()
			end
			if row.portrait then
				row.portrait:Hide()
				row.ring:Hide()
			end
			row:Show()
			y = y + (h or ROW_H)
			return row
		end
		if detailTab == "bosses" then
			local levels = ns.BOSS_LEVELS and ns.BOSS_LEVELS[selected]
			for bi, boss in ipairs(d.bosses or {}) do
				i = i + 1
				bossY[bi] = y
				local row = Row(i, 34)
				row.item = nil
				row:SetScript("OnEnter", nil)
				if not row.portrait then
					row.portrait = row:CreateTexture(nil, "ARTWORK")
					row.portrait:SetSize(28, 28)
					row.portrait:SetPoint("LEFT", 4, 0)
					row.ring = row:CreateTexture(nil, "OVERLAY")
					row.ring:SetSize(44, 44)
					row.ring:SetPoint("CENTER", row.portrait, "CENTER", 0, 0)
					row.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
					row.ring:SetTexCoord(0, 0.6, 0, 0.6)
				end
				local has = ns.BossPortrait and ns.BossPortrait.Set(row.portrait, boss)
				if not has then
					row.portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
					row.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				end
				row.portrait:Show()
				row.ring:Show()
				row.line:ClearAllPoints()
				row.line:SetPoint("LEFT", 40, 0)
				row.line:SetPoint("RIGHT", -8, 0)
				local lv = levels and levels[boss.name]
				row.line:SetText(("|cffebad33%s|r%s"):format(LocBoss(boss.name),
					lv and ("  |cff8c919f" .. L.DJ_LEVEL .. " " .. lv .. "|r") or ""))
				local loot = {}
				for _, item in ipairs(boss.loot or {}) do
					loot[#loot + 1] = item
				end
				if ns.GetBossSharedLoot then
					for _, item in ipairs(ns.GetBossSharedLoot(selected, boss) or {}) do
						loot[#loot + 1] = item
					end
				end
				for _, item in ipairs(loot) do
					i = i + 1
					local lrow = Row(i, 22)
					if not lrow.lootIcon then
						lrow.lootBg = lrow:CreateTexture(nil, "BORDER")
						lrow.lootBg:SetSize(20, 20)
						lrow.lootBg:SetPoint("LEFT", 38, 0)
						lrow.lootBg:SetColorTexture(0, 0, 0, 0.5)
						lrow.lootIcon = lrow:CreateTexture(nil, "ARTWORK")
						lrow.lootIcon:SetSize(16, 16)
						lrow.lootIcon:SetPoint("CENTER", lrow.lootBg, "CENTER")
						lrow.lootIcon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
					end
					lrow.lootIcon:SetTexture(ItemIcon(item[1])
						or "Interface\\Icons\\INV_Misc_QuestionMark")
					lrow.lootIcon:Show()
					lrow.lootBg:Show()
					lrow.line:ClearAllPoints()
					lrow.line:SetPoint("LEFT", 64, 0)
					lrow.line:SetPoint("RIGHT", -8, 0)
					lrow.line:SetText(ItemLink(item))
					lrow.item = item[1]
					lrow:SetScript("OnEnter", function(self)
						if self.item and GameTooltip then
							GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
							GameTooltip:SetItemByID(self.item)
							GameTooltip:Show()
						end
					end)
					lrow:SetScript("OnLeave", function()
						if GameTooltip then
							GameTooltip:Hide()
						end
					end)
				end
			end
		end
		rholder:SetHeight(math.max(1, y))
		rscroll:UpdateScrollChildRect()
		if focusBoss and bossY[focusBoss] then
			local target = bossY[focusBoss]
			focusBoss = nil
			C_Timer.After(0, function()
				rscroll:UpdateScrollChildRect()
				rscroll:SetVerticalScroll(math.max(0, math.min(rscroll:GetVerticalScrollRange(), target)))
			end)
		end
	end

	local function Dungeons()
		local out = {}
		local query = strtrim((searchBox.GetText and searchBox:GetText() or ""):lower())
		local aliases = ns.DUNGEON_SEARCH_ALIASES or {}
		for _, name in ipairs(ns.ORDER or {}) do
			local d = ns.DB and ns.DB[name]
			if d then
				local hay = name:lower()
				for _, a in ipairs(aliases[name] or {}) do
					hay = hay .. " " .. a
				end
				if query == "" or hay:find(query, 1, true) then
					out[#out + 1] = { name = name, d = d }
				end
			end
		end
		return out
	end

	function page:Refresh()
		for _, r in ipairs(lholder.rows) do
			r:Hide()
		end
		local list = Dungeons()
		local y = 0
		for i, e in ipairs(list) do
			local row = lholder.rows[i]
			if not row then
				row = CreateFrame("Button", nil, lholder)
				row:SetHeight(22)
				row.name = W.Text(row, "GameFontHighlightSmall")
				row.name:SetPoint("LEFT", 6, 0)
				row.lv = W.Text(row, "GameFontDisableSmall", W.MUTED)
				row.lv:SetPoint("RIGHT", -6, 0)
				row.hl = row:CreateTexture(nil, "BACKGROUND")
				row.hl:SetAllPoints()
				row.hl:SetColorTexture(0.92, 0.68, 0.20, 0.12)
				row.hl:Hide()
				lholder.rows[i] = row
			end
			row.name:SetText(LocDungeon(e.name, "name") or e.name)
			row.lv:SetText(e.d.level or "")
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", 0, -y)
			row:SetPoint("RIGHT", -6, 0)
			row.hl:SetShown(e.name == selected)
			row:Show()
			row:SetScript("OnClick", function()
				selected = e.name
				page:Refresh()
			end)
			y = y + 22
		end
		lholder:SetHeight(math.max(1, y))
		lscroll:UpdateScrollChildRect()

		local d = selected and ns.DB and ns.DB[selected]
		if selected ~= lastSelected then
			lastSelected = selected
			mapShownFor = nil
			focusBoss = nil
			selQuest = nil
			rscroll:SetVerticalScroll(0)
			qpScroll:SetVerticalScroll(0)
			qlScroll:SetVerticalScroll(0)
		end
		if not (ns.ORDER and ns.ORDER[1]) then
			empty:SetText("|cffff5555" .. L.DJ_NO_DATA .. "|r")
		else
			empty:SetText(L.DJ_EMPTY)
		end
		empty:SetShown(not d)
		if d then
			local artFile = DUNGEON_ART[selected]
			local mspec = ns.DUNGEON_MAPS and ns.DUNGEON_MAPS[selected]
			local mfl = mspec and mspec.floors and mspec.floors[1]
			local hasArt = artFile ~= nil or (mfl ~= nil and mfl.texture ~= nil)
			if artFile then
				art:SetTexture(MEDIA .. artFile .. ".tga")
				art:SetTexCoord(0, 1, 0.12, 0.78)
			elseif hasArt then
				-- no banner of its own: use a wide slice of the first floor map
				local r, b = mfl.texRight or 1, mfl.texBottom or 1
				art:SetTexture(mfl.texture)
				art:SetTexCoord(0, r, b * 0.30, b * 0.58)
			end
			if hasArt then
				art:Show()
				artDim:Show()
				artFade:Show()
				dIcon:Hide()
				headerH = ART_H
				dName:ClearAllPoints()
				dName:SetPoint("BOTTOMLEFT", art, "BOTTOMLEFT", 10, 6)
				dMeta:ClearAllPoints()
				dMeta:SetPoint("BOTTOMLEFT", dName, "TOPLEFT", 0, 2)
			else
				art:Hide()
				artDim:Hide()
				artFade:Hide()
				dIcon:Show()
				headerH = 40
				dIcon:ClearAllPoints()
				dIcon:SetPoint("TOPLEFT", PAD, -PAD)
				dName:ClearAllPoints()
				dName:SetPoint("LEFT", dIcon, "RIGHT", 10, 8)
				dMeta:ClearAllPoints()
				dMeta:SetPoint("TOPLEFT", dName, "BOTTOMLEFT", 0, -2)
			end
			for i, chip in ipairs(chips) do
				chip:ClearAllPoints()
				chip:SetPoint("TOPLEFT", PAD + (i - 1) * 96, -(PAD + headerH + 46))
			end
			local contentTop = -(PAD + headerH + 76)
			rscroll:SetPoint("TOPLEFT", PAD, contentTop)
			mapFrame:SetPoint("TOPLEFT", PAD, contentTop)
			questFrame:SetPoint("TOPLEFT", PAD, contentTop)
			factionChip:ClearAllPoints()
			factionChip:SetPoint("TOPRIGHT", -PAD, -(PAD + headerH + 46))
			dIcon:SetTexture(d.icon or "Interface\\Icons\\INV_Misc_Book_09")
			dName:SetText(LocDungeon(selected, "name") or selected)
			local loc = LocDungeon(selected, "location") or d.location
			dMeta:SetText((d.level and (L.DJ_LEVEL .. " " .. d.level) or "")
				.. (loc and ("  ·  " .. loc) or ""))
			dDesc:ClearAllPoints()
			dDesc:SetPoint("TOPLEFT", PAD, -(PAD + headerH + 6))
			dDesc:SetPoint("RIGHT", -PAD, 0)
			dDesc:SetHeight(34)
			dDesc:SetText(LocDungeon(selected, "description") or d.description or "")
			wpBtn.pin = d.entrance
			wpBtn:SetShown(d.entrance ~= nil)
			wpBtn.tipTitle = d.entrance and (d.entrance.label or L.DJ_WAYPOINT)
			wpBtn.tipText = d.entrance and d.entrance.detail
			FillDetail(d)
		end
	end

	function page:OnShow()
		if not selected and ns.ORDER then
			selected = ns.ORDER[1]
		end
		page:Refresh()
	end

	return page
end

ns.JournalBuild = Build
