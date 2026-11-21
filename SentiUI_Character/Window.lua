-- The character window: header, tab strip, paged body, footer.
-- Page "character" holds the gear columns + model + stats; the other pages
-- come from Pages.lua and fill the body area.
local _, ns = ...
local S = SentiUI
local C = S.colors
local L = ns.L

ns.Win = {}
local W = ns.Win

local ROW = 44      -- gear row height
local GAP = 6

local function PlayerColor()
	local _, cls = UnitClass("player")
	local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
	return c or C.accent
end

function W.Build()
	if W.frame then return end
	local f = CreateFrame("Frame", "SentiUICharacter", UIParent)
	W.frame = f
	f:SetSize(880, 580)
	f:SetPoint("CENTER", UIParent, "CENTER", -40, 20)
	f:SetFrameStrata("HIGH")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()
	S.Template(f, "panel")

	-- header --------------------------------------------------------------
	local head = CreateFrame("Frame", nil, f)
	head:SetPoint("TOPLEFT", 1, -1)
	head:SetPoint("TOPRIGHT", -1, -1)
	head:SetHeight(46)
	S.Template(head, "inset")

	f.title = S.Font(head, 15, nil, "OUTLINE")
	f.title:SetPoint("LEFT", 12, 0)

	f.sub = S.Font(head, 10, C.textDim)
	f.sub:SetPoint("LEFT", f.title, "RIGHT", 8, -2)

	local close = CreateFrame("Button", nil, head, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)
	close:SetSize(22, 22)

	-- tab strip -----------------------------------------------------------
	local tabs = CreateFrame("Frame", nil, f)
	tabs:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 6, -4)
	tabs:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", -6, -4)
	tabs:SetHeight(24)
	W.tabs = tabs
	W.tabBtns = {}

	-- body: page host ------------------------------------------------------
	local body = CreateFrame("Frame", nil, f)
	body:SetPoint("TOPLEFT", tabs, "BOTTOMLEFT", -6, -4)
	body:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 34)
	W.body = body

	-- character page -------------------------------------------------------
	local char = CreateFrame("Frame", nil, body)
	char:SetAllPoints()
	W.charPage = char

	W.leftCol = CreateFrame("Frame", nil, char)
	W.leftCol:SetPoint("TOPLEFT", char, "TOPLEFT", 8, 0)
	W.leftCol:SetSize(205, 400)

	W.model = CreateFrame("PlayerModel", nil, char)
	W.model:SetPoint("TOPLEFT", W.leftCol, "TOPRIGHT", 6, -28)
	W.model:SetSize(200, 320)
	W.model:SetScript("OnMouseDown", function(m, btn)
		if btn == "LeftButton" then m.dragX = GetCursorPosition() end
	end)
	W.model:SetScript("OnMouseUp", function(m) m.dragX = nil end)
	W.model:SetScript("OnUpdate", function(m)
		if m.dragX then
			local x = GetCursorPosition()
			m:SetFacing((m:GetFacing() or 0) + (x - m.dragX) * 0.01)
			m.dragX = x
		end
	end)

	W.rightCol = CreateFrame("Frame", nil, char)
	W.rightCol:SetPoint("TOPLEFT", W.model, "TOPRIGHT", 6, 28)
	W.rightCol:SetSize(205, 400)

	W.bottomRow = CreateFrame("Frame", nil, char)
	W.bottomRow:SetPoint("TOP", W.model, "BOTTOM", 0, -2)
	W.bottomRow:SetSize(4 * ROW + 3 * GAP, ROW)

	-- stat panel: docked flush to the right edge of the gear block, full
	-- page height - the scroll frame inside clips the content
	local stats = CreateFrame("Frame", nil, char)
	W.stats = stats
	stats:SetPoint("TOPLEFT", W.rightCol, "TOPRIGHT", 6, -2)
	stats:SetPoint("BOTTOMRIGHT", char, "BOTTOMRIGHT", -6, -2)
	S.Template(stats, "inset")
	stats:SetClipsChildren(true)
	W.statsHost = stats

	-- stat rows scroll inside the panel; a tall group list never paints
	-- past the frame edge
	local ssf = CreateFrame("ScrollFrame", nil, stats,
		"UIPanelScrollFrameTemplate")
	ssf:SetPoint("TOPLEFT", 2, -2)
	ssf:SetPoint("BOTTOMRIGHT", -20, 2)
	local schild = CreateFrame("Frame", nil, ssf)
	schild:SetSize(1, 1)
	ssf:SetScrollChild(schild)
	W.statsRows = schild
	W.statsScroll = ssf
	-- wheel scroll on the whole panel, not just the narrow slider
	stats:EnableMouseWheel(true)
	stats:SetScript("OnMouseWheel", function(_, delta)
		local cur = ssf:GetVerticalScroll() or 0
		local max = math.max(0, (schild:GetHeight() or 0) - (ssf:GetHeight() or 0))
		ssf:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 28)))
	end)

	-- footer --------------------------------------------------------------
	local foot = CreateFrame("Frame", nil, f)
	foot:SetPoint("BOTTOMLEFT", 1, 1)
	foot:SetPoint("BOTTOMRIGHT", -1, 1)
	foot:SetHeight(28)
	S.Template(foot, "inset")

	f.ilvl = S.Font(foot, 11, C.accent)
	f.ilvl:SetPoint("LEFT", 12, 0)
	f.dura = S.Font(foot, 11, C.textDim)
	f.dura:SetPoint("RIGHT", -12, 0)

	-- equipment-set picker, only when the client has sets
	f.sets = CreateFrame("Button", nil, foot)
	f.sets:SetSize(90, 20)
	f.sets:SetPoint("CENTER", 0, 0)
	f.sets.txt = S.Font(f.sets, 11, C.accent2)
	f.sets.txt:SetAllPoints()
	f.sets.txt:SetJustifyH("CENTER")
	f.sets:SetScript("OnClick", function(btn) ns.Win.OpenSetsMenu(btn) end)
	f.sets:Hide()

	-- other pages ----------------------------------------------------------
	W.pageFrames = {}
	for _, id in ipairs(ns.Pages.order) do
		local def = ns.Pages.defs[id]
		local pf = CreateFrame("Frame", nil, body)
		pf:SetAllPoints()
		pf:Hide()
		if def.Build then S.SafeCall("page:" .. id, def.Build, pf) end
		W.pageFrames[id] = pf
	end

	ns.Slots.Build()
	ns.Stats.Build()
	W.Layout()
	W.BuildTabs()
end

-- Tabs --------------------------------------------------------------------

function W.BuildTabs()
	local tabs = W.tabs
	local x = 0
	W.pageOrder = { "character" }
	for _, id in ipairs(ns.Pages.order) do
		local def = ns.Pages.defs[id]
		local ok, avail = pcall(def.Available or function() return true end)
		if ok and avail then W.pageOrder[#W.pageOrder + 1] = id end
	end
	for i, id in ipairs(W.pageOrder) do
		local b = W.tabBtns[i]
		if not b then
			b = CreateFrame("Button", nil, tabs)
			b:SetHeight(22)
			b.txt = S.Font(b, 11)
			b.txt:SetPoint("CENTER")
			b.line = b:CreateTexture(nil, "ARTWORK")
			b.line:SetHeight(2)
			b.line:SetPoint("BOTTOMLEFT", 2, 0)
			b.line:SetPoint("BOTTOMRIGHT", -2, 0)
			W.tabBtns[i] = b
		end
		b.pageId = id
		b.txt:SetText(id == "character" and L["Character"] or ns.Pages.defs[id].label)
		b:SetWidth((b.txt:GetStringWidth() or 40) + 18)
		b:ClearAllPoints()
		b:SetPoint("LEFT", x, 0)
		b:SetScript("OnClick", function() W.ShowPage(id) end)
		b:Show()
		x = x + b:GetWidth() + 4
	end
	for i = #W.pageOrder + 1, #W.tabBtns do W.tabBtns[i]:Hide() end
	W.currentPage = nil
	W.ShowPage("character")
end

function W.ShowPage(id)
	if W.currentPage == id then return end
	W.currentPage = id
	W.charPage:SetShown(id == "character")
	for pid, pf in pairs(W.pageFrames) do pf:SetShown(pid == id) end
	for _, b in ipairs(W.tabBtns) do
		local on = b.pageId == id
		b.txt:SetTextColor(on and C.accent.r or C.textDim.r,
			on and C.accent.g or C.textDim.g, on and C.accent.b or C.textDim.b)
		b.line:SetColorTexture(on and C.accent.r or 1, on and C.accent.g or 1,
			on and C.accent.b or 1, on and 0.8 or 0.08)
	end
	local def = ns.Pages.defs[id]
	if def and def.Refresh and W.pageFrames[id]:IsShown() then
		S.SafeCall("page:" .. id, def.Refresh, W.pageFrames[id])
	end
end

-- Layout (gear columns) ----------------------------------------------------

function W.Layout()
	local db = ns.C.db()
	local showModel = not db or db.model ~= false
	W.model:SetShown(showModel)

	local y = 0
	for _, b in ipairs(W.leftSlots or {}) do
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", W.leftCol, "TOPLEFT", 0, -y)
		y = y + ROW + GAP
	end
	y = 0
	for _, b in ipairs(W.rightSlots or {}) do
		b:ClearAllPoints()
		b:SetPoint("TOPRIGHT", W.rightCol, "TOPRIGHT", 0, -y)
		y = y + ROW + GAP
	end
	for i, b in ipairs(W.bottomSlots or {}) do
		b:ClearAllPoints()
		b:SetPoint("BOTTOMLEFT", W.bottomRow, "BOTTOMLEFT",
			(i - 1) * (ROW + GAP), 0)
	end
	ns.Stats.Layout()
end

-- Equipment-set menu ---------------------------------------------------------

function W.OpenSetsMenu(btn)
	if not C_EquipmentSet or not C_EquipmentSet.GetEquipmentSetIDs then return end
	local ids = C_EquipmentSet.GetEquipmentSetIDs()
	if not ids or #ids == 0 then return end
	local items = {}
	for _, id in ipairs(ids) do
		local name = ns.PlainStr(C_EquipmentSet.GetEquipmentSetInfo(id))
		if name then
			items[#items + 1] = {
				label = name,
				fn = function()
					S.RunOutOfCombat(C_EquipmentSet.UseEquipmentSet, id)
				end,
			}
		end
	end
	if #items > 0 then ns.Menu.Open(btn, items) end
end

local function HeaderText(f)
	local name = ns.PlainStr(GetUnitName("player")) or "?"
	local lvl = ns.Plain(UnitLevel("player"))
	local _, cls = UnitClass("player")
	local cc = PlayerColor()
	f.title:SetText(name)
	f.title:SetTextColor(cc.r, cc.g, cc.b)
	local className = cls and ns.PlainStr(LOCALIZED_CLASS_NAMES_MALE
		and LOCALIZED_CLASS_NAMES_MALE[cls]) or ""
	f.sub:SetText((lvl and (L["Level %s"]):format(lvl) or "")
		.. (className ~= "" and "  " .. className or ""))
end

local function FooterText(f)
	local db = ns.C.db()
	local ilvl = ns.Plain(GetAverageItemLevel and GetAverageItemLevel())
	if ilvl then ilvl = math.floor(ilvl + 0.5) end
	f.ilvl:SetText(ilvl and (L["Item level %d"]):format(ilvl) or "")

	local hasSets = C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs
		and #C_EquipmentSet.GetEquipmentSetIDs() > 0
	f.sets:SetShown(hasSets and true or false)
	if hasSets then f.sets.txt:SetText(L["Sets"] .. " ▾") end

	local cur, max = ns.Slots.TotalDurability()
	if max and max > 0 then
		local pct = math.floor(cur / max * 100 + 0.5)
		f.dura:SetText((L["Durability %d%%"]):format(pct))
		if db.footColors then
			local r = pct < 30 and 0.9 or (pct < 60 and 0.9) or 0.3
			local g = pct < 30 and 0.2 or (pct < 60 and 0.7) or 0.8
			f.dura:SetTextColor(r, g, 0.25)
		else
			f.dura:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b)
		end
	else
		f.dura:SetText("")
	end
end

function W.Refresh()
	local f = W.frame
	if not f or not f:IsShown() then return end
	HeaderText(f)
	FooterText(f)
	if W.currentPage == "character" then
		ns.Slots.Refresh()
		ns.Stats.Refresh()
		if W.model:IsShown() then W.model:SetUnit("player") end
	else
		local def = ns.Pages.defs[W.currentPage]
		if def and def.Refresh then
			S.SafeCall("page:" .. W.currentPage, def.Refresh,
				W.pageFrames[W.currentPage])
		end
	end
end

function W.Show(page)
	W.frame:Show()
	if page and page ~= W.currentPage then W.ShowPage(page) end
	W.Refresh()
end
