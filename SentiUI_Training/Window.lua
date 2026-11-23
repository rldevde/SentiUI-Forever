-- The trainers window: class spells, weapon skills and profession
-- recipes, grouped into "learnable now / missing requirements / later /
-- ignored / known". Data lives in ns.Training (Service.lua + Data\*.lua).
local _, ns = ...
local S = SentiUI
local L = ns.L
local T = ns.Training

local ipairs, pairs, type = ipairs, pairs, type
local format = string.format
local strtrim = strtrim or function(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end
local tinsert, sort = table.insert, table.sort
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip

local C = S.colors
local PAD = 10
local ROW_H = 20

local K = {}
ns.Training.Win = K
SentiUITraining = K -- panel plugin entry point: SentiUITraining.Toggle()

-- section headers, in display order (TrText holds the localized labels)
local SECTIONS = {
	{ key = "available", color = "|cff4dd278", tx = "AVAILABLE_HEADER", cost = true },
	{ key = "missingReqs", color = "|cffff8040", tx = "MISSINGREQS_HEADER" },
	{ key = "missingTalent", color = "|cfffff0c0", tx = "MISSINGTALENT_HEADER" },
	{ key = "nextLevel", color = "|cff82c5ff", tx = "NEXTLEVEL_HEADER" },
	{ key = "notLevel", color = "|cff8c919f", tx = "NOTLEVEL_HEADER" },
	{ key = "pet", color = "|cffc586ff", tx = "PET_HEADER" },
	{ key = "ignored", color = "|cff6a6f7d", tx = "IGNORED_HEADER" },
	{ key = "known", color = "|cff5a5f6d", tx = "KNOWN_HEADER" },
}
local WEAPON_SECTIONS = {
	{ key = "weaponAvailable", color = "|cff4dd278", tx = "WEAPON_AVAILABLE_HEADER", cost = true },
	{ key = "weaponNextLevel", color = "|cff82c5ff", tx = "WEAPON_NEXTLEVEL_HEADER" },
	{ key = "weaponNotLevel", color = "|cff8c919f", tx = "WEAPON_NOTLEVEL_HEADER" },
	{ key = "weaponIgnored", color = "|cff6a6f7d", tx = "WEAPON_IGNORED_HEADER" },
	{ key = "weaponKnown", color = "|cff5a5f6d", tx = "WEAPON_KNOWN_HEADER" },
}
local RECIPE_SECTIONS = {
	{ color = "|cff4dd278", tx = "AVAILABLE_HEADER" },
	{ color = "|cffff8040", tx = "MISSINGREQS_HEADER" },
	{ color = "|cff82c5ff", tx = "NEXTLEVEL_HEADER" },
	{ color = "|cff8c919f", tx = "NOTLEVEL_HEADER" },
	{ color = "|cff6a6f7d", tx = "IGNORED_HEADER" },
}

-- small widgets ---------------------------------------------------------------
local function Btn(parent, w, h, label)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 90, h or 22)
	S.Template(b, "raised")
	b.label = S.Font(b, 10)
	b.label:SetPoint("CENTER")
	b.label:SetWidth((w or 90) - 4)
	b.label:SetJustifyH("CENTER")
	b.label:SetText(label or "")
	b:SetScript("OnEnter", function() S.SetBorderLit(b, true) end)
	b:SetScript("OnLeave", function() S.SetBorderLit(b, false) end)
	return b
end

-- a mode/filter chip: the shared Sentinel tab chip (blade + lit active)
local function Chip(parent, onClick)
	local b = S.TabChip(parent, 20)
	b.autoWidth = true
	function b:SetActive(on) self:SetSelected(on) end
	b:SetScript("OnClick", function(self) onClick(self) end)
	return b
end

local function SetWaypoint(pin)
	if not (pin and pin.mapID and C_Map and C_Map.SetUserWaypoint
		and UiMapPoint and UiMapPoint.CreateFromCoordinates) then
		return
	end
	local ok, point = pcall(UiMapPoint.CreateFromCoordinates,
		pin.mapID, pin.x / 100, pin.y / 100)
	if not (ok and point) then return end
	pcall(C_Map.SetUserWaypoint, point)
	if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
		pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
	end
	if WorldMapFrame and WorldMapFrame.SetMapID then
		pcall(function()
			WorldMapFrame:SetMapID(pin.mapID)
			WorldMapFrame:Show()
		end)
	end
end

-- window ----------------------------------------------------------------------
function K.Build()
	if K.frame then return K.frame end
	local f = CreateFrame("Frame", "SentiUITrainingWindow", UIParent, "BackdropTemplate")
	S.EscClosable(f)
	f:SetSize(600, 600)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	S.Template(f, "panel")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not InCombatLockdown() then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	f:SetClampedToScreen(true)
	if S.CombatDeferWindow then S:CombatDeferWindow(f) end
	f:Hide()
	K.frame = f

	local mode = "spells" -- spells | weapons | professions
	local showKnown, showIgnored = false, true
	local profFilter -- profession id or nil = all

	-- header
	local hIcon = f:CreateTexture(nil, "ARTWORK")
	hIcon:SetSize(18, 18)
	hIcon:SetPoint("TOPLEFT", PAD + 4, -9)
	hIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	hIcon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	local title = S.Font(f, 15, C.accent)
	title:SetPoint("TOPLEFT", hIcon, "TOPRIGHT", 8, -1)
	local rule = f:CreateTexture(nil, "ARTWORK")
	rule:SetHeight(1)
	rule:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -44)
	rule:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -44)
	rule:SetColorTexture(C.accent.r, C.accent.g, C.accent.b, 0.35)
	local subtitle = S.Font(f, 10, C.textDim)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
	subtitle:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
	subtitle:SetJustifyH("LEFT")

	local close = S.Widgets.Close(f, function() K.Close() end)
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

	-- search
	local search = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	search:SetSize(170, 20)
	search:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -30)
	search:SetAutoFocus(false)
	search:SetMaxLetters(40)
	local searchLbl = S.Font(f, 9, C.textDim)
	searchLbl:SetPoint("BOTTOMRIGHT", search, "TOPRIGHT", 0, 1)
	searchLbl:SetText(L["Search…"])
	search:SetScript("OnTextChanged", function(_, user)
		if user then K.Refresh() end
	end)
	-- no OnEscapePressed: insecure code in the Escape dispatch taints
	-- the engine's protected spell-stop calls; Escape drops focus
	-- natively

	-- chip rows
	local barChips, profChips = {}, {}
	local function Mode(id, label)
		local chip = Chip(f, function()
			mode = id
			profFilter = nil
			K.Refresh()
		end)
		chip:SetLabel(label)
		chip.mode = id
		barChips[#barChips + 1] = chip
		return chip
	end
	Mode("spells", L["Spells"])
	Mode("weapons", L["Weapon skills"])
	Mode("professions", T.Text("PROFESSIONS"))
	local ignChip = Chip(f, function()
		showIgnored = not showIgnored
		K.Refresh()
	end)
	ignChip:SetLabel(L["Show ignored"])
	local knownChip = Chip(f, function()
		showKnown = not showKnown
		K.Refresh()
	end)
	knownChip:SetLabel(L["Show known"])
	barChips[#barChips + 1] = ignChip
	barChips[#barChips + 1] = knownChip

	-- scroll area inside an inset card with a slim scroll thumb
	local listBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
	S.Template(listBg, "inset")
	local scroll = CreateFrame("ScrollFrame", nil, listBg)
	local holder -- declared above UpdateThumb/Layout: both capture it
	local thumb = scroll:CreateTexture(nil, "OVERLAY")
	thumb:SetWidth(3)
	thumb:SetColorTexture(C.accent.r, C.accent.g, C.accent.b, 0.7)
	thumb:Hide()
	local function UpdateThumb()
		local total = (holder:GetHeight() or 1) - (scroll:GetHeight() or 1)
		if total <= 0 then thumb:Hide() return end
		local h = math.max(24, scroll:GetHeight() * scroll:GetHeight() / holder:GetHeight())
		thumb:SetHeight(h)
		thumb:ClearAllPoints()
		thumb:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", -2,
			-scroll:GetVerticalScroll() / total * (scroll:GetHeight() - h))
		thumb:Show()
	end
	holder = CreateFrame("Frame", nil, scroll)
	holder:SetWidth(520)
	scroll:SetScrollChild(holder)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, d)
		local cur = self:GetVerticalScroll()
		local max = math.max(0, holder:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.min(max, math.max(0, cur - d * 60)))
	end)
	holder.rows, holder.heads = {}, {}

	-- flows chips left to right and wraps; returns the bottom y used
	local function Flow(chips, startY)
		local width = f:GetWidth() or 560
		local x, y, rowH = PAD, startY, 26
		for _, chip in ipairs(chips) do
			if chip:IsShown() then
				local w = chip:GetWidth()
				if x > PAD and x + w > width - PAD then
					x, y = PAD, y - rowH
				end
				chip:ClearAllPoints()
				chip:SetPoint("TOPLEFT", f, "TOPLEFT", x, y)
				x = x + w + 8
			end
		end
		return y - rowH
	end

	local function Layout()
		local bottom = Flow(barChips, -60)
		if mode == "professions" then
			bottom = Flow(profChips, bottom - 2)
		end
		listBg:ClearAllPoints()
		listBg:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, bottom - 4)
		listBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD)
		scroll:ClearAllPoints()
		scroll:SetPoint("TOPLEFT", listBg, "TOPLEFT", 6, -6)
		scroll:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -6, 6)
		holder:SetWidth((f:GetWidth() or 600) - PAD * 2 - 26)
		UpdateThumb()
	end
	f:SetScript("OnSizeChanged", Layout)
	scroll:SetScript("OnVerticalScroll", UpdateThumb)
	holder:SetScript("OnSizeChanged", UpdateThumb)

	local empty = S.Font(f, 11, C.textDim)
	empty:SetPoint("CENTER", f, "CENTER", 0, -20)
	empty:SetWidth(380)
	empty:SetJustifyH("CENTER")
	empty:Hide()

	-- rows ----------------------------------------------------------------------
	local function Row(i, y)
		local row = holder.rows[i]
		if not row then
			row = CreateFrame("Button", nil, holder)
			row:SetHeight(ROW_H)
			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetPoint("LEFT", 4, 0)
			row.icon:SetSize(16, 16)
			row.line = S.Font(row, 10)
			row.line:SetPoint("LEFT", row.icon, "RIGHT", 7, 0)
			row.line:SetPoint("RIGHT", -4, 0)
			row.line:SetJustifyH("LEFT")
			row.line:SetWordWrap(false)
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints()
			row.hl:SetColorTexture(1, 1, 1, 0.05)
			row.zebra = row:CreateTexture(nil, "BACKGROUND")
			row.zebra:SetAllPoints()
			row.zebra:SetColorTexture(1, 1, 1, 0.03)
			row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
			holder.rows[i] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 0, -y)
		row:SetPoint("RIGHT", -6, 0)
		row.zebra:SetShown(i % 2 == 0)
		if row.pin then row.pin:Hide() end
		row.line:ClearAllPoints()
		row.line:SetPoint("LEFT", row.icon, "RIGHT", 7, 0)
		row.line:SetPoint("RIGHT", -4, 0)
		row:Show()
		return row
	end

	local function Head(i, text, color, y)
		local hd = holder.heads[i]
		if not hd then
			hd = S.Font(holder, 11, C.accent)
			holder.heads[i] = hd
		end
		if not hd.rule then
			hd.rule = holder:CreateTexture(nil, "ARTWORK")
			hd.rule:SetHeight(1)
			hd.rule:SetColorTexture(0.92, 0.68, 0.20, 0.25)
		end
		hd:ClearAllPoints()
		hd:SetPoint("TOPLEFT", 4, -y)
		hd:SetText(color .. text .. "|r")
		hd.rule:ClearAllPoints()
		hd.rule:SetPoint("LEFT", hd, "RIGHT", 8, -1)
		hd.rule:SetPoint("RIGHT", holder, "RIGHT", -6, 0)
		hd.rule:Show()
		hd:Show()
		return hd
	end

	local function Area(id)
		return (C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(id))
			or ("#" .. id)
	end

	local function SpellTip(row, entry)
		row:SetScript("OnEnter", function()
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			if entry.tome and entry.itemId and GameTooltip.SetItemByID then
				GameTooltip:SetItemByID(entry.itemId)
			elseif GameTooltip.SetSpellByID and (entry.id or entry.spell) then
				GameTooltip:SetSpellByID(entry.id or entry.spell)
			else
				GameTooltip:SetText(entry.formattedFullName or entry.name or "?")
			end
			if entry.quest then
				local areas = {}
				for _, a in ipairs(entry.quest.areas or {}) do
					areas[#areas + 1] = Area(a)
				end
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(T.Text("QUEST") .. ": " ..
					table.concat(areas, ", "), 0.55, 0.57, 0.62)
				for _, q in ipairs(entry.quest.quests or {}) do
					GameTooltip:AddLine("Quest #" .. q, 0.55, 0.57, 0.62)
				end
			end
			if entry.weapon and entry.trainers then
				GameTooltip:AddLine(" ")
				for _, tr in ipairs(entry.trainers) do
					GameTooltip:AddLine(("%s - %s (%.1f, %.1f)"):format(
						tr.name or "?", tr.zone and Area(tr.zone) or "",
						tr.x or 0, tr.y or 0), 0.55, 0.57, 0.62)
				end
			end
			local rc = entry.recipe
			if rc then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(entry.profession .. " - " .. entry.skillLabel,
					1, 0.82, 0)
				GameTooltip:AddLine(entry.source, 0.55, 0.78, 1)
				if entry.cost and entry.cost > 0 then
					GameTooltip:AddLine(T.FormatCost(entry.cost), 1, 1, 1)
				end
				if entry.repText then
					GameTooltip:AddLine(entry.repText, 1, 0.5, 0.25)
				end
				if entry.requirement then
					GameTooltip:AddLine(entry.requirement, 1, 0.5, 0.25)
				end
				for _, v in ipairs(rc.vendors or {}) do
					GameTooltip:AddLine(("%s: NPC %d - %s"):format(T.Text("VENDOR"),
						v.npc, v.area and Area(v.area) or "?"), 0.55, 0.57, 0.62)
				end
				for _, q in ipairs(rc.quests or {}) do
					GameTooltip:AddLine(("%s #%d - %s%s"):format(T.Text("QUEST"),
						q.id, q.area and Area(q.area) or "?",
						q.faction and (" (" .. q.faction .. ")") or ""),
						0.55, 0.57, 0.62)
				end
			end
			GameTooltip:AddLine(entry.tome and L["Right-click: mark tome as learned"]
				or (T.IsIgnored(entry.id or entry.spell) and L["Right-click: unignore"]
					or L["Right-click: ignore"]), 0.45, 0.47, 0.52)
			GameTooltip:Show()
		end)
	end

	-- professions mode ---------------------------------------------------------
	local function RefreshProfChips(skills)
		for _, c in ipairs(profChips) do c:Hide() end
		local list = { { id = nil, name = L["All"] } }
		for _, s in ipairs(skills) do
			list[#list + 1] = { id = s.id, name = s.name }
		end
		for i, p in ipairs(list) do
			local chip = profChips[i]
			if not chip then
				chip = Chip(f, function(self)
					profFilter = self.pid
					K.Refresh()
				end)
				profChips[i] = chip
			end
			chip.pid = p.id
			chip:SetLabel(p.name)
			chip:SetActive(profFilter == p.id)
			chip:Show()
		end
	end

	local function FillRecipes(query)
		local skills = T.MySkills()
		RefreshProfChips(skills)
		if #skills == 0 then
			subtitle:SetText("")
			empty:SetText(L["No professions learned yet"])
			empty:Show()
			return 0
		end
		local groups = T.BuildRecipes()
		local y, ri, hi, total = 0, 0, 0, 0
		for cat, def in ipairs(RECIPE_SECTIONS) do
			local isIgnored = cat == T.RecipeCat.IGNORED
			if not (isIgnored and not showIgnored) then
				local shown = {}
				for _, r in ipairs(groups[cat]) do
					if (not profFilter or r.professionID == profFilter)
						and (query == "" or r.searchName:find(query, 1, true)) then
						shown[#shown + 1] = r
					end
				end
				if #shown > 0 then
					total = total + (cat == T.RecipeCat.AVAILABLE and #shown or 0)
					hi = hi + 1
					Head(hi, T.Text(def.tx) .. "  |cff8c919f(" .. #shown .. ")|r", def.color, y)
					y = y + 20
					for _, r in ipairs(shown) do
						ri = ri + 1
						local row = Row(ri, y)
						row.icon:SetTexture(r.icon)
						row.icon:SetDesaturated(isIgnored)
						row.icon:Show()
						local cost = (r.cost and r.cost > 0)
							and ("  |cff8c919f" .. T.FormatCost(r.cost) .. "|r") or ""
						row.line:SetText(("|cff8c919f%s|r  %s  |cff82c5ff%s|r  |cff6a6f7d%s|r%s"):format(
							r.skillLabel, r.name, r.source, r.profession, cost))
						SpellTip(row, r)
						row:SetScript("OnClick", function(_, btn)
							if btn == "RightButton" then
								T.SetIgnored(r.spell, not T.IsIgnored(r.spell))
								K.Refresh()
							end
						end)
						y = y + ROW_H
					end
					y = y + 8
				end
			end
		end
		holder:SetHeight(math.max(1, y))
		return total
	end

	-- refresh --------------------------------------------------------------------
	function K.Refresh()
		for _, r in ipairs(holder.rows) do r:Hide() end
		for _, hd in ipairs(holder.heads) do hd:Hide() if hd.rule then hd.rule:Hide() end end
		for _, chip in ipairs(barChips) do
			if chip.mode then chip:SetActive(chip.mode == mode) end
		end
		knownChip:SetActive(showKnown)
		knownChip:SetShown(mode ~= "professions")
		ignChip:SetActive(showIgnored)
		for _, c in ipairs(profChips) do c:SetShown(mode == "professions") end

		title:SetText(L["Trainers"])
		empty:Hide()
		local query = strtrim((search:GetText() or ""):lower())

		if mode == "professions" then
			local n = FillRecipes(query)
			Layout()
			if empty:IsShown() then return end
			subtitle:SetText(("%s - %s: |cff4dd278%d|r"):format(
				T.Text("PROFESSIONS"), L["learnable"], n))
			return
		end

		if not (T and T.ClassData and next(T.ClassData)) then
			subtitle:SetText("")
			empty:SetText("|cffff5555" .. L["No trainer data for this class"] .. "|r")
			empty:Show()
			holder:SetHeight(1)
			Layout()
			return
		end

		local weapons = mode == "weapons"
		local cats, totals = T.BuildData()
		local sections = weapons and WEAPON_SECTIONS or SECTIONS
		local availKey = weapons and "weaponAvailable" or "available"
		local availTotal = weapons and totals.weaponAvailable or totals.available

		local okN, cname = pcall(UnitClass, "player")
		subtitle:SetText(("%s - %s %d - %s: |cff4dd278%d|r  %s"):format(
			(okN and cname) or "?", L["Lv"], UnitLevel("player"),
			L["learnable"], #cats[availKey],
			availTotal > 0 and ("(" .. T.FormatCost(availTotal) .. ")") or ""))

		local y, ri, hi = 0, 0, 0
		local function Section(sec)
			local list = cats[sec.key] or {}
			local isKnown = sec.key == "known" or sec.key == "weaponKnown"
			local isIgnored = sec.key == "ignored" or sec.key == "weaponIgnored"
			if (isKnown and not showKnown) or (isIgnored and not showIgnored) then
				return
			end
			local shown = {}
			for _, e in ipairs(list) do
				local hay = (e.formattedFullName or e.name or ""):lower()
				if query == "" or hay:find(query, 1, true) then
					shown[#shown + 1] = e
				end
			end
			if #shown == 0 then return end
			hi = hi + 1
			local label = T.Text(sec.tx)
			if sec.cost and availTotal > 0 then
				label = label .. "  |cff8c919f(" .. T.FormatCost(availTotal) .. ")|r"
			end
			Head(hi, label .. "  |cff8c919f(" .. #shown .. ")|r", sec.color, y)
			y = y + 20
			for _, e in ipairs(shown) do
				ri = ri + 1
				local row = Row(ri, y)
				row.icon:SetTexture(e.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
				row.icon:SetDesaturated(isKnown or isIgnored)
				row.icon:Show()
				local cost = (e.cost and e.cost > 0) and T.FormatCost(e.cost) or ""
				local lvl = (not isKnown and e.level and e.level > 0)
					and ("|cff8c919f" .. L["Lv"] .. " " .. e.level .. "|r  ") or ""
				row.line:SetText((e.quest and "|cff4dd278[Q]|r " or "") .. lvl
					.. (e.formattedFullName or e.name or "?")
					.. (cost ~= "" and ("  |cff8c919f" .. cost .. "|r") or ""))
				SpellTip(row, e)
				row:SetScript("OnClick", function(_, btn)
					if btn == "RightButton" then
						if e.tome then
							T.SetTomeLearned(e.itemId, not T.IsTomeLearned(e))
						else
							T.SetIgnored(e.id, not T.IsIgnored(e.id))
						end
						K.Refresh()
					end
				end)
				local tr = e.weapon and e.trainers and e.trainers[1]
				local mapID = tr and tr.zone and T.zoneUiMapIds
					and T.zoneUiMapIds[tr.zone]
				if mapID then
					if not row.pin then
						row.pin = Btn(row, 62, 16, L["Waypoint"])
						row.pin:SetPoint("RIGHT", -2, 0)
						row.pin:SetScript("OnClick", function(self)
							SetWaypoint(self.pin)
						end)
					end
					row.pin.pin = { mapID = mapID, x = tr.x, y = tr.y }
					row.pin:Show()
					row.line:SetPoint("RIGHT", row.pin, "LEFT", -6, 0)
				end
				y = y + ROW_H
			end
			y = y + 8
		end
		for _, sec in ipairs(sections) do Section(sec) end
		holder:SetHeight(math.max(1, y))
		Layout()
	end

	f:SetScript("OnShow", function() K.Refresh() end)
	return f
end

function K.Close()
	if K.frame and K.frame:IsShown() then K.frame:Hide() end
end

function K.Toggle()
	K.Build()
	if K.frame:IsShown() then
		K.frame:Hide()
	else
		if SentiUIJournal and SentiUIJournal.Close then SentiUIJournal.Close() end
		K.frame:Show()
	end
end

-- reopening rebuilds the groups: freshly learned spells move sections.
-- SPELLS_CHANGED can fire inside the keybind dispatch that opens the
-- spellbook (K in combat) - a handler running there taints the client's
-- protected FrameShow right after, so the event is only registered while
-- our window is actually shown and needs the refresh
local spellEv = CreateFrame("Frame")
spellEv:SetScript("OnEvent", function()
	if K.frame and K.frame:IsShown() then K.Refresh() end
end)
S.WatchShown(function() return K.frame end,
	function() pcall(spellEv.RegisterEvent, spellEv, "SPELLS_CHANGED") end,
	function() pcall(spellEv.UnregisterEvent, spellEv, "SPELLS_CHANGED") end)
