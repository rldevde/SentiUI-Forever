-- The shared window builder behind both views (carried bags + bank): a
-- Sentinel panel with title, optional search box, toolbar buttons, a
-- category-grouped slot grid and a footer (free slots, money, currency).
local _, ns = ...
local S = SentiUI
local L = ns.L

local Core = {}
ns.Core = Core

local db
Core.windows = {}

local PAD, TOOL_H, FOOT_H, HEAD_H, TITLE_H = 10, 26, 20, 20, 18

local BAG_IDS = { 0, 1, 2, 3, 4 }
local BAG_SLOT_IDS = { 1, 2, 3, 4 }
if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then
	BAG_IDS[#BAG_IDS + 1] = Enum.BagIndex.ReagentBag
	BAG_SLOT_IDS[#BAG_SLOT_IDS + 1] = Enum.BagIndex.ReagentBag
end

local function NumSlots(bag)
	if C_Container and C_Container.GetContainerNumSlots then
		local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
		if ok and type(n) == "number" then return n end
	end
	return 0
end

local function SlotInfo(bag, slot)
	if not (C_Container and C_Container.GetContainerItemInfo) then return end
	local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
	if ok and type(info) == "table" and not S.IsSecretTable(info) then
		return info
	end
end

-- window ----------------------------------------------------------------------
local function Footer(w)
	local free = 0
	for _, bag in ipairs(w.bagIds) do
		if C_Container and C_Container.GetContainerNumFreeSlots then
			local ok, n = pcall(C_Container.GetContainerNumFreeSlots, bag)
			if ok and type(n) == "number" and not S.IsSecret(n) then
				free = free + n
			end
		end
	end
	w.freeFS:SetFormattedText("%s |cff%s%d|r", L["Free"], S.Hex(S.colors.accent), free)

	if w.moneyFS then
		local money = 0
		local ok, m = pcall(GetMoney)
		if ok and type(m) == "number" and not S.IsSecret(m) then money = m end
		w.moneyFS:SetFormattedText("|cff%s%d|r |cff%s%d|r |cff%s%d|r",
			"ffd700", math.floor(money / 1e4),
			"c0c0c0", math.floor(money / 100 % 100),
			"b87333", math.floor(money % 100))
	end
	ns.Currency.Layout(w)
end

local function Header(w, i, label, x, y)
	local h = w.headers[i]
	if not h then
		h = CreateFrame("Frame", nil, w.grid)
		h.fs = S.Font(h, 10, S.colors.accent, "OUTLINE")
		h.fs:SetPoint("LEFT", h, "LEFT", 2, 0)
		h.line = h:CreateTexture(nil, "ARTWORK")
		h.line:SetColorTexture(1, 1, 1, 0.10)
		h.line:SetHeight(1)
		h.line:SetPoint("LEFT", h.fs, "RIGHT", 8, 0)
		h.line:SetPoint("RIGHT", h, "RIGHT", -2, 0)
		w.headers[i] = h
	end
	h.fs:SetText(label)
	h:ClearAllPoints()
	h:SetPoint("TOPLEFT", w.grid, "TOPLEFT", x, -y)
	h:SetPoint("RIGHT", w.grid, "RIGHT", -2, 0)
	h:SetHeight(HEAD_H)
	h:Show()
	return HEAD_H
end

local function HideHeaders(w)
	for _, h in pairs(w.headers) do h:Hide() end
end

-- flat or category-grouped slot walk; returns grid height
local function LayoutGrid(w)
	local v = w.view
	local size, gap = v.iconSize, v.spacing
	local cols = math.max(1, v.columns)
	local query = w.query or ""

	-- bucket slots per category in display order
	local flat = not db.categories
	local buckets, order = {}, ns.Categories.ORDER
	if flat then order = { "all" } end
	for _, cat in ipairs(order) do buckets[cat] = {} end
	local used = {}
	for _, bag in ipairs(w.bagIds) do
		for slot = 1, NumSlots(bag) do
			local info = SlotInfo(bag, slot)
			if info or v.emptySlots then
				local key = bag .. ":" .. slot
				used[key] = true
				local cat = flat and "all" or ns.Categories.Of(bag, slot, info)
				local list = buckets[cat] or buckets[order[#order]]
				list[#list + 1] = { bag = bag, slot = slot, info = info }
			end
		end
	end
	for key, b in pairs(ns.Items.slots) do
		if not used[key] and b.ownerGrid == w.grid then b:Hide() end
	end

	local x, y, col = PAD, 2, 0
	HideHeaders(w)
	local function rowBreak()
		if col > 0 then col, x = 0, PAD; y = y + size + gap end
	end
	for ci, cat in ipairs(order) do
		local list = buckets[cat]
		if #list > 0 then
			if not flat then
				rowBreak()
				y = y + Header(w, ci, ns.Categories.Label(cat), PAD, y) + 4
			end
			for _, s in ipairs(list) do
				local b = ns.Items.Get(s.bag, s.slot, w.grid)
				b.view = w.view
				b:SetSize(size, size)
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", w.grid, "TOPLEFT", x, -y)
				b.info = s.info
				ns.Items.Paint(b, s.info)
				local dim = query ~= "" and s.info
					and not (b.searchText or ""):find(query, 1, true)
				ns.Items.SetDimmed(b, dim == true)
				b:Show()
				x = x + size + gap
				col = col + 1
				if col == cols then col, x = 0, PAD; y = y + size + gap end
			end
		end
	end
	return y + (col > 0 and (size + gap) or 0) + 4
end

-- a window parked on fractional pixels loses 1px slot borders on random
-- edges (the top line is usually the first to go). Snap the STORED anchor
-- offsets (GetPoint) to whole units - never GetLeft/GetTop measurements,
-- which on this client sit in a different coordinate space than SetPoint
-- offsets: re-anchoring from measured coords crept the window upward on
-- every refresh. Rounding the stored offsets converges after at most one
-- half-unit nudge, and skipping the SetPoint when already integral avoids
-- re-firing the clamped-to-screen adjustment on every layout.
local function SnapOrigin(w)
	local ok, p, rel, rp, x, y = pcall(w.frame.GetPoint, w.frame, 1)
	if not ok or not p or type(x) ~= "number" or type(y) ~= "number"
		or S.IsSecret(x) or S.IsSecret(y) then
		return
	end
	local rx, ry = math.floor(x + 0.5), math.floor(y + 0.5)
	if rx == x and ry == y then return end
	pcall(w.frame.ClearAllPoints, w.frame)
	pcall(w.frame.SetPoint, w.frame, p, rel or UIParent, rp or p, rx, ry)
end

function Core.Layout(w)
	if not w then for _, x in pairs(Core.windows) do Core.Layout(x) end return end
	SnapOrigin(w)
	local v = w.view
	local gh = LayoutGrid(w)
	local fw = v.columns * v.iconSize + (v.columns - 1) * v.spacing + PAD * 2
	-- the window is at least as wide as its toolbar (search + buttons)
	if w.minW then fw = math.max(fw, w.minW) end
	local toolbar = w.searchBox or w.hasTools
	local topOff = TITLE_H + (toolbar and TOOL_H or 0) + 6
	if w.bagStrip then
		w.bagStrip:UpdatePaint(v.iconSize)
		w.bagStrip:ClearAllPoints()
		w.bagStrip:SetPoint("TOPLEFT", w.frame, "TOPLEFT", PAD, -topOff)
		topOff = topOff + w.bagStrip:GetHeight() + 6
	end
	w.grid:SetSize(fw, gh)
	w.grid:SetPoint("TOPLEFT", w.frame, "TOPLEFT", 0, -topOff)
	w.frame:SetSize(fw, gh + topOff + FOOT_H + 6)
	-- repair button only when auto-repair is off; it runs automatically
	if w.tool_repair then w.tool_repair:SetShown(not db.autoRepair) end
	Footer(w)
end

local function Tool(w, label, tip, fn)
	local b = SentiUI.Widgets.Button(w.frame, label, 58, 20)
	b:SetScript("OnClick", fn)
	return b
end

-- opts: { label, viewKey="bags"|"bank", mover, defaultPos, search, money,
--         tools = { {label, fn}, ... } right-anchored }
function Core.MakeWindow(key, opts)
	local w = { key = key, view = db[opts.viewKey], headers = {}, query = "" }
	w.bagIds = opts.bagIds
	-- deliberately NOT in UISpecialFrames: the client's own special-frame
	-- walk hid our window a tick after it showed (the client closes
	-- members it did not open). ESC still works - it hides the game's
	-- container frames, the state poll then closes ours with them.
	local fname = "SentiUIBagsFrame_" .. key
	w.frame = CreateFrame("Frame", fname, UIParent, "BackdropTemplate")
	if S.CombatDeferWindow then S:CombatDeferWindow(w.frame) end
	w.frame:SetSize(220, 120)
	S.Template(w.frame, "panel")
	w.frame:SetFrameStrata("DIALOG")
	w.frame:EnableMouse(true)
	w.frame:Hide()
	if type(UISpecialFrames) == "table" then
		for i = #UISpecialFrames, 1, -1 do
			if UISpecialFrames[i] == fname then tremove(UISpecialFrames, i) end
		end
	end

	-- title row -----------------------------------------------------------
	local title = S.Font(w.frame, 12, S.colors.accent, "OUTLINE")
	title:SetText("SentiUI |cffd8dbe0" .. opts.label .. "|r")
	title:SetPoint("TOPLEFT", w.frame, "TOPLEFT", PAD, -5)
	w.titleFS = title

	local close = SentiUI.Widgets.Button(w.frame, "×", 18, 16)
	close:SetPoint("TOPRIGHT", w.frame, "TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function()
		-- hide the game's containers directly: calling CloseAllBags from
		-- addon code writes the client's bag bookkeeping tainted
		if ns.Blizzard.CloseGame then ns.Blizzard.CloseGame() end
		Core.ApplyGameState(false)
	end)

	-- drag the window by its title band; the mover DB stays the single
	-- store for the position (Movers.Save), so reset/apply still work
	local drag = CreateFrame("Frame", nil, w.frame)
	drag:SetPoint("TOPLEFT", w.frame, "TOPLEFT", 0, 0)
	drag:SetPoint("TOPRIGHT", w.frame, "TOPRIGHT", -26, 0)
	drag:SetHeight(TITLE_H + 4)
	drag:EnableMouse(true)
	drag:RegisterForDrag("LeftButton")
	drag:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		pcall(w.frame.SetMovable, w.frame, true)
		w.frame:StartMoving()
	end)
	drag:SetScript("OnDragStop", function()
		w.frame:StopMovingOrSizing()
		S.Movers.Save("bags." .. key)
		if S.Movers.Recheck then S.Movers.Recheck() end
	end)

	-- toolbar row -----------------------------------------------------------
	local toolTop = -(TITLE_H + 4)
	w.hasTools = opts.tools and #opts.tools > 0
	local toolW = 0

	if db.search then
		local e = SentiUI.Widgets.EditBox(w.frame, 130, 20)
		e.holder:SetPoint("TOPLEFT", w.frame, "TOPLEFT", PAD, toolTop - 2)
		e.placeholder:SetText(L["Search..."])
		e.onChanged = function(t)
			w.query = (t or ""):lower()
			Core.Layout(w)
		end
		w.searchBox = e
		toolW = 134
	end

	if w.hasTools then
		local anchor
		for i = #opts.tools, 1, -1 do
			local t = opts.tools[i]
			local b = Tool(w, t.label, nil, t.fn)
			if t.key then w["tool_" .. t.key] = b end
			if not anchor then
				b:SetPoint("TOPRIGHT", w.frame, "TOPRIGHT", -PAD, toolTop)
			else
				b:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
			end
			anchor = b
			toolW = toolW + b:GetWidth() + 4
		end
	end
	-- never let the toolbar stick out over the window edges
	w.minW = toolW + PAD * 2

	w.freeFS = S.Font(w.frame, 10, nil, "OUTLINE")
	w.freeFS:SetPoint("BOTTOMLEFT", w.frame, "BOTTOMLEFT", PAD, 6)
	if opts.money then
		w.moneyFS = S.Font(w.frame, 11, nil, "OUTLINE")
		w.moneyFS:SetJustifyH("RIGHT")
		w.moneyFS:SetPoint("BOTTOMRIGHT", w.frame, "BOTTOMRIGHT", -PAD, 6)
	end

	w.grid = CreateFrame("Frame", nil, w.frame)
	w.grid:EnableMouse(false)

	-- equipped-bag slots above the grid (drag to swap bags)
	if opts.slots and ns.Slots then
		ns.Slots.Make(w, opts.slots)
	end

	w.frame:HookScript("OnShow", function()
		S.SafeCall("bags:layout", function() Core.Layout(w) end)
	end)

	-- closing the window clears the client's "new" flags and, for the
	-- carried-bags window, hides the game's containers too so
	-- IsAnyBagOpen() and the next key press stay in agreement.
	-- WatchHide, not OnHide: the window may be closed by game code, so an
	-- OnHide script would run inside that dispatch.
	S.WatchHide(w.frame, function()
		if C_NewItems and C_NewItems.ClearAll then
			pcall(C_NewItems.ClearAll)
		end
		if key == "bags" then ns.Blizzard.CloseGame() end
	end)

	S.Movers.Register(w.frame, "bags." .. key, opts.label, opts.defaultPos)
	Core.windows[key] = w
	return w
end

-- bags window specifics -------------------------------------------------------
local pending
local function Refresh()
	if pending then return end
	pending = true
	C_Timer.After(0.15, function()
		pending = nil
		S.SafeCall("bags:layout", Core.Layout)
	end)
end
Core.Refresh = Refresh

-- game-state mirroring --------------------------------------------------------
-- The game's bag bookkeeping is the single source of truth: our window
-- only ever reflects it. Every hooked bag function funnels into Sync,
-- which runs deferred so the game settles first.
function Core.GameBagOpen()
	if type(IsAnyBagOpen) == "function" then
		local ok, v = pcall(IsAnyBagOpen)
		if ok and type(v) == "boolean" then return v end
	end
	if type(IsBagOpen) == "function" then
		local any = false
		for i = 0, NUM_BAG_SLOTS or 4 do
			local ok, v = pcall(IsBagOpen, i)
			if ok and type(v) == "boolean" then any = true
				if v then return true end
			end
		end
		if any then return false end
	end
	return nil
end

function Core.ApplyGameState(open)
	local w = Core.windows.bags
	if not w then return end
	if open == nil then open = not w.frame:IsShown() end
	w.frame:SetShown(open and true or false)
	if open then Refresh() end
end

local syncPending
function Core.Sync()
	if syncPending then return end
	syncPending = true
	C_Timer.After(0, function()
		syncPending = nil
		-- merchant opened the window explicitly; IsAnyBagOpen() reads
		-- the game's own bag frames (not ours) and would close it again
		if Core.forceOpen then Core.ApplyGameState(true) return end
		local open = Core.GameBagOpen()
		if open == nil then open = Core.gameOpen end -- event-tracked fallback
		-- nil reaches ApplyGameState as a blind toggle: only possible when
		-- neither state functions nor bag events exist on this client
		Core.ApplyGameState(open)
	end)
end

-- manual command only: drives the window directly instead of calling the
-- game's bag functions, whose bookkeeping writes would run tainted here
function Core.Toggle()
	local w = Core.windows.bags
	if not w then return end
	if w.frame:IsShown() then
		ns.Blizzard.CloseGame()
		Core.ApplyGameState(false)
	else
		Core.ApplyGameState(true)
	end
end
function Core.Open() Core.ApplyGameState(true) end
function Core.Close() Core.ApplyGameState(false) end

function Core.Enable(mod)
	db = mod.db
	Core.db = db
	ns.MigrateDefaults(db)
	ns.Items.db = db
	ns.Categories.db = db
	S.SafeCall("bags:build", function()
		Core.MakeWindow("bags", {
			label = L["Bags"], viewKey = "bags", bagIds = BAG_IDS,
			slots = BAG_SLOT_IDS,
			defaultPos = { x = 360, y = -160 }, money = true,
			tools = {
				{ label = L["Sell junk"], fn = function() ns.Merchant.SellJunk() end },
				{ label = L["Sort bags"], fn = function()
					local f = C_Container and (C_Container.SortBags or C_Container.SortBagsRightToLeft)
						or SortBags
					if type(f) == "function" then pcall(f) end
				end },
				{ key = "repair", label = L["Repair"], fn = function() ns.Merchant.Repair() end },
			},
		})
		ns.Bank.Enable()
	end)
	for _, ev in ipairs({
		"BAG_UPDATE", "BAG_UPDATE_DELAYED", "BAG_NEW_ITEMS_UPDATED",
		"BAG_SLOT_FLAGS_UPDATED", "ITEM_LOCK_CHANGED", "PLAYER_MONEY" }) do
		S.RegisterEvent(ev, Refresh)
	end

	-- the game's bag bookkeeping is the source of truth; the open/close
	-- events track it, Sync mirrors the result into our window
	for _, ev in ipairs({ "BAG_OPEN", "BAG_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED" }) do
		S.RegisterEvent(ev, function()
			if ev == "BAG_OPEN" then Core.gameOpen = true
			elseif ev == "BAG_CLOSED" then Core.gameOpen = false end
			Core.Sync()
			Refresh()
		end)
	end
	-- no state poll on purpose: every open/close path goes through the
	-- hooked bag functions, and a poll racing the client's multi-frame
	-- open sequence (IsAnyBagOpen can read false mid-transition) is what
	-- made the window flash open and shut.
	-- manual toggle for testing and keybind-free access
	SLASH_SENTIBAGS1 = "/sbags"
	SlashCmdList.SENTIBAGS = function() Core.Toggle() end
	ns.Merchant.Enable(db)
	ns.Blizzard.Enable()
end

function Core.SettingChanged(mod, path)
	db = mod.db
	Core.db = db
	ns.MigrateDefaults(db)
	ns.Items.db = db
	ns.Categories.db = db
	if path == "sellJunk" or path == "autoRepair" or path == "repairGuild" then
		ns.Merchant.Enable(db)
		return
	end
	Core.Layout()
end
