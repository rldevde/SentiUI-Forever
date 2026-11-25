-- luacheck: read globals StaticPopupDialogs StaticPopup_Show
local _, ns = ...

-- Sync page: explains the two ways to see characters from other WoW
-- accounts (same-PC script, export/import string) and hosts the
-- export/import fields plus the "remove imported" cleanup.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

-- strtrim is a FrameXML global and not guaranteed on this client.
local strtrim = strtrim or function(s)
	return (tostring(s or ""):match("^%s*(.-)%s*$"))
end

local PAD = 12

StaticPopupDialogs["SAI_DELETE_IMPORTED"] = {
	text = L.SYNC_DELETE_IMPORTED_CONFIRM,
	button1 = L.DELETE,
	button2 = CANCEL,
	OnAccept = function()
		Store.DeleteImported()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function Build(content)
	local page = {}

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	local scroll, holder
	local function Layout()
		-- Reflow by measured text heights: works at any window width.
		local w = holder:GetWidth()
		if not w or w < 200 then
			return
		end
		local y = -PAD
		local function Place(f, dy)
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", PAD, y)
			y = y - dy
		end
		Place(page.title, 32)
		Place(page.pcHeader, 22)
		page.pcText:ClearAllPoints()
		page.pcText:SetPoint("TOPLEFT", PAD, y)
		page.pcText:SetPoint("RIGHT", -PAD, 0)
		y = y - (page.pcText:GetStringHeight() + 16)
		page.div1:ClearAllPoints()
		page.div1:SetPoint("TOPLEFT", PAD, y)
		page.div1:SetPoint("TOPRIGHT", -PAD, y)
		y = y - 14
		Place(page.strHeader, 22)
		page.strText:ClearAllPoints()
		page.strText:SetPoint("TOPLEFT", PAD, y)
		page.strText:SetPoint("RIGHT", -PAD, 0)
		y = y - (page.strText:GetStringHeight() + 14)
		Place(page.labelLabel, 20)
		Place(page.accountBox, 26)
		Place(page.exportHint, 18)
		page.exportArea:ClearAllPoints()
		page.exportArea:SetPoint("TOPLEFT", PAD, y)
		page.exportArea:SetPoint("TOPRIGHT", -PAD, y)
		y = y - 88
		Place(page.importHint, 18)
		page.importArea:ClearAllPoints()
		page.importArea:SetPoint("TOPLEFT", PAD, y)
		page.importArea:SetPoint("TOPRIGHT", -PAD, y)
		y = y - 68
		Place(page.importBtn, 30)
		Place(page.deleteBtn, 24)
		holder:SetHeight(-y + 10)
	end
	scroll, holder = W.ScrollArea(panel, Layout)
	scroll:SetPoint("TOPLEFT", 1, -1)
	scroll:SetPoint("BOTTOMRIGHT", -9, 1)

	page.title = W.Text(holder, "GameFontNormal", W.GOLD)
	page.title:SetText(L.SYNC_TITLE)

	-- Same-PC accounts -------------------------------------------------
	page.pcHeader = W.Header(holder, L.SYNC_PC_TITLE)

	page.pcText = W.Text(holder, "GameFontHighlight", W.TEXT)
	page.pcText:SetJustifyH("LEFT")
	page.pcText:SetWordWrap(true)
	page.pcText:SetText(L.SYNC_PC_TEXT)

	page.div1 = W.Divider(holder)

	-- Export / import string --------------------------------------------
	page.strHeader = W.Header(holder, L.SYNC_STRING_TITLE)

	page.strText = W.Text(holder, "GameFontHighlight", W.TEXT)
	page.strText:SetJustifyH("LEFT")
	page.strText:SetWordWrap(true)
	page.strText:SetText(L.SYNC_STRING_TEXT)

	page.labelLabel = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	page.labelLabel:SetText(L.SYNC_ACCOUNT_LABEL)

	page.accountBox = W.EditBox(holder, 200)

	local exportBtn = W.Button(holder, L.SYNC_EXPORT, 110)
	exportBtn:SetPoint("LEFT", page.accountBox, "RIGHT", 10, 0)

	local csvBtn = W.Button(holder, L.SYNC_CSV, 110)
	csvBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)

	page.exportHint = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	page.exportHint:SetText(L.SYNC_EXPORT_HINT)

	page.exportArea = W.TextArea(holder, 100, 80)
	page.exportArea:SetHeight(80)
	page.exportArea.editBox:SetScript("OnMouseDown", function(self)
		self:HighlightText()
	end)

	page.importHint = W.Text(holder, "GameFontDisableSmall", W.MUTED)
	page.importHint:SetText(L.SYNC_IMPORT_HINT)

	page.importArea = W.TextArea(holder, 100, 60)
	page.importArea:SetHeight(60)

	local importBtn = W.Button(holder, L.SYNC_IMPORT, 110)

	local importResult = W.Text(holder, "GameFontHighlightSmall", W.GREEN)
	importResult:SetPoint("LEFT", importBtn, "RIGHT", 10, 0)
	page.importBtn = importBtn

	page.deleteBtn = W.LinkButton(holder, L.SYNC_DELETE_IMPORTED, function()
		StaticPopup_Show("SAI_DELETE_IMPORTED")
	end)

	exportBtn:SetScript("OnClick", function()
		local text = ns.Transfer.Export(strtrim(page.accountBox:GetText() or ""))
		page.exportArea:SetText(text or "")
		importResult:SetText("")
	end)

	csvBtn:SetScript("OnClick", function()
		-- Flat CSV of every character for spreadsheets: one row per
		-- char with the core snapshot fields.
		local lines = { "name;realm;account;class;level;ilvl;gold;guild;zone;lastScan" }
		for _, key in ipairs(Store.CharKeys()) do
			local char = ns.db.chars[key]
			local realm = key:match("%-(.+)$") or ""
			local gold = math.floor((char.money or 0) / 10000 + 0.5)
			lines[#lines + 1] = ("%s;%s;%s;%s;%s;%s;%s;%s;%s;%s"):format(
				char.name or ns.ShortName(key), realm,
				Store.AccountOf(char) or "", char.class or "",
				char.level or "", (char.stats and char.stats.itemLevel) or "",
				gold, char.guild or "",
				(char.stats and char.stats.zone) or "",
				char.updated and date("%Y-%m-%d %H:%M", char.updated) or "")
		end
		page.exportArea:SetText(table.concat(lines, "\n"))
		importResult:SetText(L.SYNC_CSV_DONE:format(#lines - 1))
	end)

	importBtn:SetScript("OnClick", function()
		local count = ns.Transfer.Import(page.importArea:GetText())
		if count then
			W.Color(importResult, W.GREEN)
			importResult:SetText(L.SYNC_IMPORT_DONE:format(count))
			page.importArea:SetText("")
		else
			W.Color(importResult, W.RED)
			importResult:SetText(L.SYNC_IMPORT_FAIL)
		end
	end)

	function page:Refresh()
		Layout()
	end

	return page
end

UI.RegisterPage(6, L.TAB_SYNC, Build)
