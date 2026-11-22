-- luacheck: read globals FACTION_STANDING_LABEL1
local _, ns = ...

-- Currencies & reputation page: one character dropdown plus two
-- sub-tabs. Currencies shows the stored C_CurrencyInfo snapshot per
-- character; reputation shows standing + progress per faction.
-- Snapshots update live for the own character.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12
local ROW_H = 24
local TAB_H = 24

local function StandingLabel(reaction)
	local label = _G["FACTION_STANDING_LABEL" .. tostring(reaction or 4)]
	if type(label) == "string" then
		return label
	end
	return "-"
end

local function Build(content)
	local page = {}
	local subTab = 1
	local selected

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	-- Sub-tab row -------------------------------------------------------
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

	for i, label in ipairs({ L.CURR_TAB_CURRENCIES, L.CURR_TAB_REPUTATION }) do
		local tab = CreateFrame("Button", nil, tabHolder, "BackdropTemplate")
		tab:SetSize(140, TAB_H)
		tab:SetPoint("LEFT", (i - 1) * 144, 0)
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

	-- Character dropdown --------------------------------------------------
	local dropdown = W.Dropdown(panel, 200, function()
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
	dropdown:SetPoint("TOPLEFT", PAD, -(16 + TAB_H))

	page.subFrames = {}
	for i = 1, 2 do
		local f = CreateFrame("Frame", nil, panel)
		f:SetPoint("TOPLEFT", 1, -(16 + TAB_H + 30))
		f:SetPoint("BOTTOMRIGHT", -1, 1)
		f:Hide()
		page.subFrames[i] = f
	end

	--------------------------------------------------------------------------------
	-- Sub-tab 1: currencies
	--------------------------------------------------------------------------------
	local curFrame = page.subFrames[1]
	local cscroll, cholder = W.ScrollArea(curFrame)
	cscroll:SetPoint("TOPLEFT", PAD, -6)
	cscroll:SetPoint("BOTTOMRIGHT", -PAD - 8, PAD)

	local cEmpty = W.Text(curFrame, "GameFontDisable")
	cEmpty:SetPoint("CENTER")
	cEmpty:SetWidth(440)
	cEmpty:SetJustifyH("CENTER")

	local cpool = {}
	local cused = 0
	local function CRow()
		cused = cused + 1
		local row = cpool[cused]
		if not row then
			row = CreateFrame("Frame", nil, cholder, "BackdropTemplate")
			row:SetHeight(ROW_H)
			row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetSize(18, 18)
			row.icon:SetPoint("LEFT", 4, 0)
			row.name = W.Text(row, "GameFontHighlight", W.TEXT)
			row.name:SetPoint("LEFT", 28, 0)
			row.name:SetPoint("RIGHT", -140, 0)
			row.name:SetJustifyH("LEFT")
			row.name:SetWordWrap(false)
			row.qty = W.Text(row, "GameFontHighlight", W.GOLD)
			row.qty:SetPoint("RIGHT", -8, 0)
			row.qty:SetJustifyH("RIGHT")
			cpool[cused] = row
		end
		row:Show()
		return row
	end

	local function RefreshCurrencies()
		cused = 0
		for _, row in ipairs(cpool) do
			row:Hide()
		end
		local key = selected or Store.OwnKey()
		local char = key and Store.Char(key)
		local list = char and char.currencies or nil
		cEmpty:SetText(char and L.CURR_EMPTY or L.CHAR_NONE)
		cEmpty:SetShown(not (list and #list > 0))
		local width = math.max(100, cscroll:GetWidth() - 4)
		local y = 0
		for i, cur in ipairs(list or {}) do
			local row = CRow()
			row:SetWidth(width)
			row:SetPoint("TOPLEFT", 0, y)
			row:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3],
				i % 2 == 0 and 0.35 or 0.6)
			row.icon:SetTexture(cur.icon or 134400)
			row.name:SetText(cur.name or "?")
			row.qty:SetText(cur.max and cur.max > 0
				and tostring(cur.qty) .. " / " .. tostring(cur.max)
				or tostring(cur.qty))
			y = y - ROW_H
		end
		cholder:SetHeight(math.max(1, -y))
	end

	--------------------------------------------------------------------------------
	-- Sub-tab 2: reputation
	--------------------------------------------------------------------------------
	local repFrame = page.subFrames[2]
	local rscroll, rholder = W.ScrollArea(repFrame)
	rscroll:SetPoint("TOPLEFT", PAD, -6)
	rscroll:SetPoint("BOTTOMRIGHT", -PAD - 8, PAD)

	local rEmpty = W.Text(repFrame, "GameFontDisable")
	rEmpty:SetPoint("CENTER")
	rEmpty:SetWidth(440)
	rEmpty:SetJustifyH("CENTER")

	local rpool = {}
	local rused = 0
	local function RRow()
		rused = rused + 1
		local row = rpool[rused]
		if not row then
			row = CreateFrame("Frame", nil, rholder, "BackdropTemplate")
			row:SetHeight(ROW_H)
			row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
			row.name = W.Text(row, "GameFontHighlight", W.TEXT)
			row.name:SetPoint("LEFT", 6, 0)
			row.name:SetPoint("RIGHT", -260, 0)
			row.name:SetJustifyH("LEFT")
			row.name:SetWordWrap(false)
			row.bar = row:CreateTexture(nil, "ARTWORK")
			row.bar:SetHeight(10)
			row.bar:SetColorTexture(0.20, 0.62, 1.00, 0.85)
			row.track = row:CreateTexture(nil, "BACKGROUND")
			row.track:SetHeight(10)
			row.track:SetColorTexture(1, 1, 1, 0.06)
			row.stand = W.Text(row, "GameFontHighlightSmall", W.MUTED)
			row.stand:SetJustifyH("RIGHT")
			row.stand:SetPoint("RIGHT", -8, 0)
			rpool[rused] = row
		end
		row:Show()
		return row
	end

	local function RefreshReputation()
		rused = 0
		for _, row in ipairs(rpool) do
			row:Hide()
		end
		local key = selected or Store.OwnKey()
		local char = key and Store.Char(key)
		local list = char and char.reputations or nil
		rEmpty:SetText(char and L.REP_EMPTY or L.CHAR_NONE)
		rEmpty:SetShown(not (list and #list > 0))
		local width = math.max(100, rscroll:GetWidth() - 4)
		local barX = width - 200
		local y = 0
		for i, rep in ipairs(list or {}) do
			local row = RRow()
			row:SetWidth(width)
			row:SetPoint("TOPLEFT", 0, y)
			row:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3],
				i % 2 == 0 and 0.35 or 0.6)
			row.name:SetText((rep.atWar and "|cffe04d4d" or "")
				.. (rep.name or "?"))
			-- Friendship factions show their personal level label
			-- ("Buddy", "Pal", ...) instead of the generic standing.
			row.stand:SetText(rep.friend or StandingLabel(rep.reaction))
			local span = (rep.max or 0) - (rep.min or 0)
			local frac = (span > 0 and rep.value)
				and math.min(1, math.max(0, (rep.value - rep.min) / span)) or 1
			row.track:ClearAllPoints()
			row.track:SetPoint("LEFT", math.min(barX, width - 210), 0)
			row.track:SetWidth(120)
			row.bar:ClearAllPoints()
			row.bar:SetPoint("LEFT", math.min(barX, width - 210), 0)
			row.bar:SetWidth(math.max(1, 120 * frac))
			y = y - ROW_H
		end
		rholder:SetHeight(math.max(1, -y))
	end

	function page:Refresh()
		if subTab == 1 then
			RefreshCurrencies()
		else
			RefreshReputation()
		end
	end

	function page:OnShow()
		PaintTabs()
	end

	SelectTab(1)
	return page
end

UI.RegisterPage(8, L.TAB_CURRENCYREP, Build)
