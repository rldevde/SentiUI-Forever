local _, ns = ...

-- Settings page: item tooltip counts, a manual rescan and a small
-- database info block.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12

local function Build(content)
	local page = {}

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	local y = -PAD

	local tooltip = W.Checkbox(panel, L.SETTINGS_TOOLTIP,
		ns.db and ns.db.settings.tooltip ~= false, function(checked)
			ns.db.settings.tooltip = checked
		end)
	tooltip:SetPoint("TOPLEFT", PAD, y)
	y = y - 18

	local tipHint = W.Text(panel, "GameFontDisableSmall", W.MUTED)
	tipHint:SetPoint("TOPLEFT", PAD + 28, y)
	tipHint:SetText(L.SETTINGS_TOOLTIP_HINT)
	y = y - 34

	local rescanResult = W.Text(panel, "GameFontHighlightSmall", W.GREEN)
	local rescan = W.Button(panel, L.SETTINGS_RESCAN, nil, function()
		ns.Scanner.Rescan()
		local char = Store.OwnChar()
		if char then
			rescanResult:SetText(L.SETTINGS_RESCAN_DONE:format(
				Store.ItemKindCount(char.bags), Store.ItemKindCount(char.bank)))
		end
	end)
	rescan:SetPoint("TOPLEFT", PAD, y)
	rescanResult:SetPoint("LEFT", rescan, "RIGHT", 10, 0)
	y = y - 44

	local watchHeader = W.Header(panel, L.SETTINGS_WATCH)
	watchHeader:SetPoint("TOPLEFT", PAD, y)
	y = y - 22

	local watchHint = W.Text(panel, "GameFontDisableSmall", W.MUTED)
	watchHint:SetPoint("TOPLEFT", PAD, y)
	watchHint:SetPoint("RIGHT", -PAD, 0)
	watchHint:SetJustifyH("LEFT")
	watchHint:SetText(L.SETTINGS_WATCH_HINT)
	y = y - 18

	local watchBox = W.EditBox(panel, 300, function(text)
		local ids = {}
		for part in (text or ""):gmatch("[^,;%s]+") do
			local id = tonumber(part)
			if id then
				ids[#ids + 1] = id
			end
		end
		if ns.db then
			ns.db.settings.watchlist = (#ids > 0 and ids) or nil
			if ns.Scanner and ns.Scanner.Rescan then
				-- refresh the stored watch results right away
				ns.Scanner.Rescan()
			end
		end
	end)
	watchBox:SetPoint("TOPLEFT", PAD, y)
	y = y - 44

	local div = W.Divider(panel)
	div:SetPoint("TOPLEFT", PAD, y)
	div:SetPoint("TOPRIGHT", -PAD, y)
	y = y - 14

	local dataHeader = W.Header(panel, L.SETTINGS_DATA)
	dataHeader:SetPoint("TOPLEFT", PAD, y)
	y = y - 24

	local dataText = W.Text(panel, "GameFontHighlight", W.TEXT)
	dataText:SetPoint("TOPLEFT", PAD, y)

	-- Rough db size estimate: serialized length / 1024.
	local function DbSizeKB()
		local ok, text = pcall(ns.Serializer.Serialize, ns.db and ns.db.chars or {})
		if ok and text then
			return math.floor(#text / 1024)
		end
		return 0
	end

	function page:Refresh()
		tooltip:SetChecked(ns.db and ns.db.settings.tooltip ~= false)
		local wl = ns.db and ns.db.settings.watchlist
		watchBox:SetText(type(wl) == "table" and table.concat(wl, ", ") or "")
		dataText:SetText(L.SETTINGS_DATA_TEXT:format(Store.CharCount(), DbSizeKB()))
		rescanResult:SetText("")
	end

	return page
end

UI.RegisterPage(7, L.TAB_SETTINGS, Build)
