-- BugSack window: session filters and search on top, an addon-grouped
-- error list on the left, a copyable plain-text detail view on the right.
-- Export swaps the detail pane for one big select-all box so the whole
-- report can go straight into the bugtracker.
local _, ns = ...
local S = SentiUI
local L = ns.L

local type, tostring, ipairs = type, tostring, ipairs
local wipe = wipe or table.wipe or function(t) for k in pairs(t) do t[k] = nil end return t end
local strtrim = strtrim or function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local Grab
local function G() Grab = Grab or ns.Grab return Grab end

local C = S.colors
local ACCENT = C.accent

local W = {}

ns.Window = W

-----------------------------------------------------------------------
-- small widgets
-----------------------------------------------------------------------
local function Btn(parent, text, w)
	-- must be a real Button: a plain Frame does not support OnClick on this
	-- client ("script type not supported by this object")
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 70, 20)
	S.Template(b, "raised")
	b.fs = S.Font(b, 10)
	b.fs:SetPoint("CENTER")
	b.fs:SetText(text)
	b:SetScript("OnEnter", function() S.SetBorderLit(b, true) end)
	b:SetScript("OnLeave", function()
		S.SetBorderLit(b, b.selected == true)
	end)
	function b:SetSelected(v)
		b.selected = v and true or false
		S.SetBorderLit(b, b.selected)
	end
	b:EnableMouse(true)
	return b
end

-----------------------------------------------------------------------
-- state
-----------------------------------------------------------------------
local win
local state = "all"          -- all | current | previous | search
local contents, display = {}, {}
local searchResults = {}
local collapsed = {}
local currentError
local rows = {}
local ROW_H = 20

local filterBtns = {}
local listRows = {}
local searchBox
local listScroll, detailScroll, detailBox, statusLine, hintText
local exportPanel, exportBox, exportTitle
local prevBtn, nextBtn

-----------------------------------------------------------------------
-- list assembly
-----------------------------------------------------------------------
local function applySearch()
	wipe(searchResults)
	local q = searchBox and strtrim(searchBox:GetText() or ""):lower()
	if q == "" then return end
	for _, err in ipairs(G():GetDB()) do
		local hay = tostring(err.message or "") .. "\n"
			.. tostring(err.stack or "") .. "\n" .. tostring(err.locals or "")
		if hay:lower():find(q, 1, true) then
			searchResults[#searchResults + 1] = err
		end
	end
end

local function buildContents()
	if state == "current" then
		return G():GetErrors(G():GetSessionId())
	elseif state == "previous" then
		return G():GetErrors(G():GetSessionId() - 1)
	elseif state == "search" then
		applySearch()
		return searchResults
	end
	return G():GetDB()
end

local function buildDisplay()
	wipe(display)
	local groups, order = G():GetErrorsByAddon(contents)
	for _, name in ipairs(order) do
		display[#display + 1] = { header = name, count = #groups[name] }
		if not collapsed[name] then
			for _, err in ipairs(groups[name]) do
				display[#display + 1] = { err = err }
			end
		end
	end
end

local function firstLine(s)
	s = tostring(s or ""):gsub("|c%x+", ""):gsub("|r", "")
	return (s:match("^([^\n]+)")) or s
end

-----------------------------------------------------------------------
-- detail view
-----------------------------------------------------------------------
local function showError(err)
	currentError = err
	if not err then
		detailBox:SetText(L["No errors in this view."])
		return
	end
	detailBox:SetText(G():FormatErrorPlain(err))
	detailBox:HighlightText(0, 0)
	detailScroll:SetVerticalScroll(0)
end

local function nav(dir)
	-- step through flat error entries, skipping group headers
	for i = 1, #display do
		if display[i].err == currentError then
			local j = i + dir
			while j >= 1 and j <= #display and not display[j].err do
				j = j + dir
			end
			if display[j] and display[j].err then
				showError(display[j].err)
			end
			return
		end
	end
	-- nothing selected: jump to the first/last error
	for i = dir > 0 and 1 or #display,
		dir > 0 and #display or 1, dir do
		if display[i].err then return showError(display[i].err) end
	end
end

-----------------------------------------------------------------------
-- rendering
-----------------------------------------------------------------------
local LIST_W = 300

local function renderList()
	if not listScroll then return end -- window not built (or build failed)
	contents = buildContents()
	buildDisplay()
	local offset = listScroll.offset or 0
	if FauxScrollFrame_Update then
		FauxScrollFrame_Update(listScroll, #display, #listRows, ROW_H)
		offset = FauxScrollFrame_GetOffset and FauxScrollFrame_GetOffset(listScroll) or offset
	end
	offset = math.max(0, math.min(offset, math.max(0, #display - #listRows)))
	for i, row in ipairs(listRows) do
		local d = display[i + offset]
		if not d then
			row:Hide()
		elseif d.header then
			row:SetPoint("TOPLEFT", listScroll, "TOPLEFT", 0, -(i - 1) * ROW_H)
			row.text:SetText((collapsed[d.header] and "|TInterface\\Buttons\\UI-PlusButton-Up:10|t " or "|TInterface\\Buttons\\UI-MinusButton-Up:10|t ")
				.. "|cff" .. S.Hex(ACCENT) .. d.header .. "|r |cff555c70(" .. d.count .. ")|r")
			row.text:SetPoint("LEFT", 4, 0)
			row:Show()
			row.isHeader = d.header
			row.err = nil
		else
			row:SetPoint("TOPLEFT", listScroll, "TOPLEFT", 14, -(i - 1) * ROW_H)
			local t = d.err.time and date("%H:%M:%S", d.err.time) or "--:--:--"
			row.text:SetText(("|cff555c70%s|r %dx %s"):format(t,
				d.err.counter or 1, firstLine(d.err.message)))
			row:Show()
			row.isHeader = nil
			row.err = d.err
			S.SetBorderLit(row, d.err == currentError)
		end
	end
	statusLine:SetText(("%d %s / %d %s"):format(#contents, L["errors shown"],
		G():GetErrorCount(), L["errors"]))
end

function W.Refresh()
	if not win then return end
	if not currentError and #contents > 0 then
		currentError = contents[#contents]
	end
	renderList()
end

local function selectFilter(s)
	state = s
	for _, b in ipairs(filterBtns) do b:SetSelected(b.key == s) end
	if s == "search" and searchBox then
		searchBox:SetFocus()
	end
	renderList()
end

-----------------------------------------------------------------------
-- build
-----------------------------------------------------------------------
local function build()
	win = CreateFrame("Frame", "SentiUIBugSack", UIParent, "BackdropTemplate")
	if S.CombatDeferWindow then S:CombatDeferWindow(win) end
	win:SetSize(760, 500)
	S.Template(win, "panel")
	win:SetPoint("CENTER")
	win:SetFrameStrata("DIALOG")
	win:SetToplevel(true)
	win:EnableMouse(true)
	win:SetMovable(true)
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", win.StartMoving)
	win:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		S.Movers.Save("bugsack.window")
	end)
	win:SetScript("OnShow", function() W.Refresh() end)
	tinsert(UISpecialFrames, "SentiUIBugSack")
	S.Movers.Register(win, "bugsack.window", L["BugSack"])

	local title = S.Font(win, 13, ACCENT, "OUTLINE")
	title:SetPoint("TOPLEFT", 12, -9)
	title:SetText("|cffebad33SentiUI|r |cff339effBugSack|r")
	local line = S.Line(win, ACCENT)
	line:SetPoint("TOPLEFT", 10, -24)
	line:SetPoint("TOPRIGHT", -10, -24)

	local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	-- filter buttons
	local x = 10
	for _, spec in ipairs({
		{ "all", L["All"] }, { "current", L["Current session"] },
		{ "previous", L["Previous session"] },
	}) do
		local b = Btn(win, spec[2], 86)
		b:SetPoint("TOPLEFT", x, -30)
		b.key = spec[1]
		b:SetScript("OnClick", function() selectFilter(b.key) end)
		filterBtns[#filterBtns + 1] = b
		x = x + 92
	end

	-- search box
	searchBox = CreateFrame("EditBox", nil, win, "InputBoxTemplate")
	searchBox:SetSize(180, 20)
	searchBox:SetPoint("TOPLEFT", x + 4, -30)
	searchBox:SetAutoFocus(false)
	searchBox:SetMaxLetters(60)
	S.AttachTooltip(searchBox, L["Search"], L["Search"])
	searchBox:SetScript("OnTextChanged", function(self)
		if strtrim(self:GetText() or "") ~= "" then
			if state ~= "search" then selectFilter("search") end
			applySearch()
			renderList()
		elseif state == "search" then
			selectFilter("all")
		end
	end)
	-- no OnEscapePressed: insecure code in the Escape dispatch taints
	-- the engine's protected spell-stop calls. The window is in
	-- UISpecialFrames, so Escape closes it and drops focus natively.

	statusLine = S.Font(win, 10, C.textDim)
	statusLine:SetPoint("TOPRIGHT", -30, -34)

	-- left list: scrollable rows
	-- template may not exist on this client; a plain ScrollFrame still
	-- works with our own offset fallback below
	local okScroll, ls = pcall(CreateFrame, "ScrollFrame",
		"SentiUIBugSackList", win, "FauxScrollFrameTemplate")
	if not (okScroll and ls) then
		ls = CreateFrame("ScrollFrame", "SentiUIBugSackList", win)
	end
	listScroll = ls
	listScroll:SetPoint("TOPLEFT", 10, -56)
	-- bottom-RIGHT pins the right edge; "BOTTOMLEFT" here would collide
	-- with the TOPLEFT anchor (both constrain the left edge), collapsing
	-- the scroll frame to zero width and clipping every row invisible
	listScroll:SetPoint("BOTTOMRIGHT", win, "BOTTOMLEFT", 10 + LIST_W, 58)
	local listBg = S.Panel(listScroll, LIST_W, 10, "inset")
	listBg:SetPoint("TOPLEFT", 0, 0)
	listBg:SetPoint("BOTTOMRIGHT")
	listScroll:SetScript("OnVerticalScroll", function(self, off)
		if FauxScrollFrame_OnVerticalScroll then
			FauxScrollFrame_OnVerticalScroll(self, off, ROW_H, renderList)
		else
			self.offset = math.floor((off or 0) / ROW_H + 0.5)
			renderList()
		end
	end)
	listScroll:EnableMouseWheel(true)
	listScroll:SetScript("OnMouseWheel", function(self, delta)
		local sb = self.ScrollBar
		if FauxScrollFrame_Update and sb and sb.SetValue then
			sb:SetValue((sb:GetValue() or 0) - delta * ROW_H * 3)
			return
		end
		self.offset = math.max(0,
			math.min((self.offset or 0) - delta * 3,
				math.max(0, #display - #listRows)))
		renderList()
	end)
	for i = 1, 19 do
		-- real Button for OnClick; S.Panel is a Frame, which rejects the
		-- handler on this client
		local row = CreateFrame("Button", nil, listScroll, "BackdropTemplate")
		row:SetSize(LIST_W - 4, ROW_H)
		S.Template(row, "inset")
		row:EnableMouse(true)
		row.text = S.Font(row, 10)
		row.text:SetPoint("LEFT", 6, 0)
		row.text:SetPoint("RIGHT", -4, 0)
		row.text:SetJustifyH("LEFT")
		row.text:SetWordWrap(false)
		row:SetScript("OnClick", function(self)
			if self.isHeader then
				collapsed[self.isHeader] = not collapsed[self.isHeader] or nil
				renderList()
			elseif self.err then
				showError(self.err)
				renderList()
			end
		end)
		row:SetScript("OnEnter", function() S.SetBorderLit(row, true) end)
		row:SetScript("OnLeave", function()
			S.SetBorderLit(row, row.err == currentError)
		end)
		listRows[i] = row
		row:Hide()
	end

	-- right detail: scrollable copyable text
	local detail = S.Panel(win, 0, 0, "inset")
	detail:SetPoint("TOPLEFT", listScroll, "TOPRIGHT", 8, 0)
	detail:SetPoint("BOTTOMRIGHT", -10, 58)
	local okDS, ds = pcall(CreateFrame, "ScrollFrame",
		"SentiUIBugSackDetail", detail, "UIPanelScrollFrameTemplate")
	if not (okDS and ds) then
		ds = CreateFrame("ScrollFrame", "SentiUIBugSackDetail", detail)
	end
	detailScroll = ds
	detailScroll:SetPoint("TOPLEFT", 6, -6)
	detailScroll:SetPoint("BOTTOMRIGHT", -24, 6)
	detailBox = CreateFrame("EditBox", nil, detailScroll)
	detailBox:SetMultiLine(true)
	detailBox:SetAutoFocus(false)
	detailBox:SetFontObject(ChatFontNormal or GameFontHighlight)
	detailBox:SetWidth(400)
	-- no OnEscapePressed (Escape dispatch taint, see searchBox)
	detailScroll:SetScrollChild(detailBox)

	-- bottom bar: nav + actions + the bugtracker hint
	prevBtn = Btn(win, "<", 26)
	prevBtn:SetPoint("BOTTOMLEFT", 10, 10)
	prevBtn:SetScript("OnClick", function() nav(-1) end)
	nextBtn = Btn(win, ">", 26)
	nextBtn:SetPoint("LEFT", prevBtn, "RIGHT", 4, 0)
	nextBtn:SetScript("OnClick", function() nav(1) end)

	local wipeBtn = Btn(win, L["Wipe"], 60)
	wipeBtn:SetPoint("LEFT", nextBtn, "RIGHT", 10, 0)
	wipeBtn:SetScript("OnClick", function()
		if StaticPopupDialogs and StaticPopupDialogs.SENTIUI_BUGSACK_WIPE
			and StaticPopup_Show then
			StaticPopup_Show("SENTIUI_BUGSACK_WIPE")
		else
			G():Reset()
		end
	end)
	local expBtn = Btn(win, L["Export session"], 100)
	expBtn:SetPoint("LEFT", wipeBtn, "RIGHT", 6, 0)
	expBtn:SetScript("OnClick", function() W.OpenExport("session") end)
	local expAllBtn = Btn(win, L["Export all"], 70)
	expAllBtn:SetPoint("LEFT", expBtn, "RIGHT", 6, 0)
	expAllBtn:SetScript("OnClick", function() W.OpenExport("all") end)

	hintText = S.Font(win, 10, C.textDim)
	hintText:SetPoint("BOTTOMRIGHT", -12, 14)
	hintText:SetText(L["Please post bug reports at https://dev.xrl-dev.de/bugtracker"])

	-- export overlay: one big select-all box over the detail area
	exportPanel = S.Panel(win, 0, 0, "inset")
	exportPanel:SetAllPoints(detail)
	exportTitle = S.Font(exportPanel, 11, ACCENT, "OUTLINE")
	exportTitle:SetPoint("TOPLEFT", 8, -8)
	local okES, es = pcall(CreateFrame, "ScrollFrame",
		"SentiUIBugSackExport", exportPanel, "UIPanelScrollFrameTemplate")
	if not (okES and es) then
		es = CreateFrame("ScrollFrame", "SentiUIBugSackExport", exportPanel)
	end
	local exportScroll = es
	exportScroll:SetPoint("TOPLEFT", 6, -28)
	exportScroll:SetPoint("BOTTOMRIGHT", -24, 30)
	exportBox = CreateFrame("EditBox", nil, exportScroll)
	exportBox:SetMultiLine(true)
	exportBox:SetAutoFocus(false)
	exportBox:SetFontObject(ChatFontNormal or GameFontHighlight)
	exportBox:SetWidth(400)
	-- no OnEscapePressed (Escape dispatch taint, see searchBox)
	exportScroll:SetScrollChild(exportBox)
	local copyHint = S.Font(exportPanel, 10, C.textDim)
	copyHint:SetPoint("BOTTOMLEFT", 8, 8)
	copyHint:SetText(L["Ctrl+A selects everything, Ctrl+C copies it - post the report at https://dev.xrl-dev.de/bugtracker please."])
	local backBtn = Btn(exportPanel, L["Back"], 56)
	backBtn:SetPoint("BOTTOMRIGHT", -8, 6)
	backBtn:SetScript("OnClick", function() exportPanel:Hide() end)
	exportPanel:Hide()

	selectFilter("all")
	win:Hide()
end

-----------------------------------------------------------------------
-- public API
-----------------------------------------------------------------------
local buildErrShown
local function ensure()
	if win then return true end
	if InCombatLockdown() then
		S.RunOutOfCombat(function() ensure() if win then win:Show() end end)
		return false
	end
	local ok, err = pcall(build)
	if not ok then
		-- surface the real build failure once instead of leaving a
		-- half-built window whose refresh would error-loop forever
		win = nil
		if not buildErrShown then
			buildErrShown = true
			S.Print("|cffff4444BugSack window build failed: "
				.. tostring(err) .. "|r")
		end
		return false
	end
	return win ~= nil
end

function W.Open()
	if ensure() then win:Show() renderList() end
end

function W.Toggle()
	if ensure() then
		if win:IsShown() then win:Hide() else win:Show() renderList() end
	end
end

function W.ShowError(err)
	if ensure() then
		win:Show()
		state = "all"
		for _, b in ipairs(filterBtns) do b:SetSelected(b.key == "all") end
		renderList()
		showError(err)
	end
end

function W.OpenExport(scope)
	if not ensure() then return end
	win:Show()
	renderList()
	local list = scope == "all" and G():GetDB()
		or G():GetErrors(G():GetSessionId())
	local title = scope == "all" and L["All"] or (L["Session"] .. " " .. G():GetSessionId())
	exportTitle:SetText(title .. " - " .. #list .. " " .. L["errors"])
	exportBox:SetText(G():BuildExport(list, title))
	exportPanel:Show()
	exportBox:SetFocus()
	exportBox:HighlightText()
end

if type(StaticPopupDialogs) == "table" then
	StaticPopupDialogs.SENTIUI_BUGSACK_WIPE = {
		text = ns.L["Confirm wipe"],
		button1 = YES,
		button2 = NO,
		OnAccept = function() ns.Grab:Reset() end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
end
