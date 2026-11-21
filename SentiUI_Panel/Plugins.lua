-- Plugin registry and buttons. Builtin plugins call ns.RegisterPlugin(def)
-- while their file loads; at boot each def gets a button on its configured
-- bar with optional icon, dim label, text, tooltip, click action and a
-- right-click menu. Shift+drag reorders and moves plugins between bars
-- and zones.
local _, ns = ...
local S = SentiUI
local L = ns.L

local ipairs, pairs, type = ipairs, pairs, type
local format = string.format
local tinsert, sort, tremove = table.insert, table.sort, table.remove
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip

local PAD = 10
local EDGE_PAD = 4
local ICON_GAP = 4
local ICON_SIZE = 15

local P = {}
ns.Plugins = P
P.defs = {}
P.byId = {}
P.eventDefs = {}

-- def: { id, label, icon?, iconSize?, bar?, zone?, order?, shown?, showLabel?,
--        update(def) -> string, tooltip?(tip), click?(button),
--        menu?(def, items), events? = {}, onevent?(def, event, ...) -> false|nil }
function ns.RegisterPlugin(def)
	if type(def) ~= "table" or type(def.id) ~= "string" or type(def.update) ~= "function" then
		return
	end
	def.regIndex = #P.defs + 1
	def.order = def.order or def.regIndex * 10
	P.defs[#P.defs + 1] = def
	P.byId[def.id] = def
end

-- per-plugin saved settings, created lazily with the def's defaults
function P.Cfg(def)
	local all = ns.db.plugins
	local cfg = all[def.id]
	if not cfg then
		cfg = {}
		all[def.id] = cfg
	end
	if cfg.shown == nil then cfg.shown = def.shown ~= false end
	if cfg.showLabel == nil then cfg.showLabel = def.showLabel ~= false end
	if cfg.showIcon == nil then cfg.showIcon = def.icon ~= nil end
	cfg.bar = cfg.bar or def.bar or "bottom"
	cfg.zone = cfg.zone or def.zone or "LEFT"
	cfg.order = cfg.order or def.order
	cfg.opts = cfg.opts or {}
	return cfg
end

function P.Opt(def, k) return P.Cfg(def).opts[k] end
function P.SetOpt(def, k, v) P.Cfg(def).opts[k] = v end

-- defs sorted by saved order, registration order as tie-breaker
function P.Ordered()
	local t = {}
	for _, d in ipairs(P.defs) do
		tinsert(t, d)
	end
	sort(t, function(a, b)
		local oa, ob = P.Cfg(a).order, P.Cfg(b).order
		if oa ~= ob then return oa < ob end
		return a.regIndex < b.regIndex
	end)
	return t
end

-- defs on one bar zone, sorted
function P.ZoneList(bar, zone)
	local t = {}
	for _, d in ipairs(P.defs) do
		local c = P.Cfg(d)
		if c.bar == bar and c.zone == zone then tinsert(t, d) end
	end
	sort(t, function(a, b) return P.Cfg(a).order < P.Cfg(b).order end)
	return t
end

local function RemoveFrom(list, def)
	for i, d in ipairs(list) do
		if d == def then tremove(list, i) return end
	end
end

function P.InsertOrder(def, refDef, before)
	local cfg = P.Cfg(def)
	local list = P.ZoneList(cfg.bar, cfg.zone)
	RemoveFrom(list, def)
	local at = #list + 1
	for i, d in ipairs(list) do
		if d == refDef then
			at = before and i or i + 1
			break
		end
	end
	tinsert(list, at, def)
	for i, d in ipairs(list) do P.Cfg(d).order = i * 10 end
end

function P.AppendOrder(def)
	local cfg = P.Cfg(def)
	local list = P.ZoneList(cfg.bar, cfg.zone)
	RemoveFrom(list, def)
	list[#list + 1] = def
	for i, d in ipairs(list) do P.Cfg(d).order = i * 10 end
end

-- swap def with its neighbour inside the same bar+zone (dir -1/+1)
function P.Move(def, dir)
	local cfg = P.Cfg(def)
	local list = P.ZoneList(cfg.bar, cfg.zone)
	local pos
	for i, d in ipairs(list) do if d == def then pos = i end end
	local other = pos and list[pos + dir]
	if not other then return end
	P.Cfg(def).order, P.Cfg(other).order = P.Cfg(other).order, P.Cfg(def).order
	ns.Bars.Relayout(cfg.bar)
end

-- button ----------------------------------------------------------------------
local function Spawn(def)
	local b = CreateFrame("Button", "SentiUIPanelPlugin_" .. def.id, UIParent)
	b.def = def
	b:RegisterForClicks("AnyUp")
	b:RegisterForDrag("LeftButton")
	b:SetMovable(true)
	b:EnableMouse(true)

	if def.icon then
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetTexture(def.icon)
	end
	b.text = ns.Font(b, ns.db.fontSize)
	def.button = b

	b:SetScript("OnEnter", function(self)
		if not def.tooltip then return end
		local anchor = P.Cfg(def).bar == "bottom" and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
		GameTooltip:SetOwner(self, anchor)
		S.SafeCall(def.id .. ":tooltip", def.tooltip, GameTooltip)
		if def.click then GameTooltip:AddLine(L["Click to open"], 0.6, 0.6, 0.6) end
		GameTooltip:AddLine(L["Right-click: options  |  Shift+drag: move"], 0.5, 0.5, 0.5)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)

	-- secure left-click overlay: protected actions (item use) and game
	-- window toggles cannot run from addon Lua on this client - calling
	-- Toggle*/Open*/Close* writes the client's window bookkeeping tainted
	-- and its next read inside a protected call is refused. An invisible
	-- SecureActionButton handles left-clicks natively: "item" uses the
	-- item, "macro" /clicks a real Blizzard button so the client's own
	-- handler runs secure. Falls back to the insecure def.click when no
	-- secure target resolves.
	local secureTarget
	if def.secureClick then
		local names = type(def.secureClick) == "table" and def.secureClick or { def.secureClick }
		for _, n in ipairs(names) do
			local t = _G[n]
			if type(t) == "table" and t.Click then secureTarget = n break end
		end
	end
	if def.secureItem or secureTarget then
		local sb = CreateFrame("Button", "SentiUIPanelPlugin_" .. def.id .. "_secure",
			b, "SecureActionButtonTemplate")
		sb:SetAllPoints()
		sb:RegisterForClicks("LeftButtonUp", "LeftButtonDown", "RightButtonUp")
		if def.secureItem then
			sb:SetAttribute("type1", "item")
			sb:SetAttribute("item1", def.secureItem)
		else
			sb:SetAttribute("type1", "macro")
			sb:SetAttribute("macrotext1", "/click " .. secureTarget)
		end
		-- keep the template's secure click handler; a plain OnClick
		-- SetScript would stop the attribute action from firing
		if SecureActionButton_OnClick then
			sb:SetScript("OnClick", SecureActionButton_OnClick)
		end
		sb:SetFrameLevel(b:GetFrameLevel() + 1)
		sb:SetScript("OnEnter", function()
			local h = b:GetScript("OnEnter")
			if h then h(b) end
		end)
		sb:SetScript("OnLeave", function() GameTooltip:Hide() end)
		sb:SetScript("PostClick", function(_, button)
			if button == "RightButton" then P.Menu(def, b) end
			if button == "LeftButton" and def.afterClick then
				C_Timer.After(0, function()
					S.SafeCall(def.id .. ":afterClick", def.afterClick, b)
				end)
			end
		end)
	end
	b:SetScript("OnClick", function(self, button)
		if self.dragged or self.dragAttempt then return end
		if button == "RightButton" then
			P.Menu(def, self)
		elseif def.click then
			S.SafeCall(def.id .. ":click", def.click, self, button)
		end
	end)
	b:SetScript("OnDragStart", function(self)
		-- any drag gesture suppresses the click that follows on release
		self.dragAttempt = true
		if not IsShiftKeyDown() then return end
		self.dragged = true
		self:StartMoving()
		self:SetFrameStrata("TOOLTIP")
	end)
	b:SetScript("OnDragStop", function(self)
		C_Timer.After(0, function() self.dragAttempt = nil end)
		if not self.dragged then return end
		self:StopMovingOrSizing()
		self.dragged = nil
		P.Drop(def)
	end)
end

-- recompute the button's width from icon + text, then relayout its bar
function P.SizeButton(def)
	local b = def.button
	local cfg = P.Cfg(def)
	b.text:SetFont(S.media.font, ns.db.fontSize, "")
	local isz = def.iconSize or ICON_SIZE
	local iconW = 0
	if b.icon then
		b.icon:ClearAllPoints()
		if cfg.showIcon then
			b.icon:SetSize(isz, isz)
			b.icon:SetPoint("LEFT", b, "LEFT", PAD / 2, 0)
			b.icon:Show()
			iconW = isz + ICON_GAP
		else
			b.icon:Hide()
		end
	end
	b.text:ClearAllPoints()
	b.text:SetPoint("LEFT", b, "LEFT", PAD / 2 + iconW, 0)
	b.w = PAD + iconW + (b.text:GetStringWidth() or 40)
	b:SetWidth(b.w)
end

function P.UpdateOne(def)
	local b = def.button
	if not b then return end
	local cfg = P.Cfg(def)
	local ok, raw = pcall(def.update, def)
	if not ok then
		-- surface the failing plugin once per session (the ticker re-fires)
		if not def.errShown then
			def.errShown = true
			S.Print(format("|cffff5555panel plugin %s: %s|r", def.id, tostring(raw)))
		end
		raw = ""
	end
	raw = (ok and type(raw) == "string" and raw) or ""
	def.empty = raw == ""
	if cfg.showLabel and not def.empty and not def.noLabel then
		raw = format("|cff%s%s:|r ", ns.dimHex, def.label) .. raw
	end
	local vis = cfg.shown and not def.empty
	if raw ~= def.last or vis ~= def.vis then
		def.last, def.vis = raw, vis
		b.text:SetText(raw)
		-- layout ops on parents of secure children are combat-blocked;
		-- plugin events fire mid-fight, so the resize/relayout defers
		S.RunOutOfCombat(function()
			P.SizeButton(def)
			ns.Bars.Relayout(cfg.bar)
		end)
	end
end

function P.RefreshAll()
	for _, def in ipairs(P.defs) do P.UpdateOne(def) end
end

-- drop the dragged def where the cursor was released
local function CursorPos()
	local s = UIParent:GetEffectiveScale()
	local x, y = GetCursorPosition()
	return x / s, y / s
end

local function InRect(f, x, y)
	local l, bo, w, h = f:GetRect()
	if not l then return false end
	return x >= l and x <= l + w and y >= bo and y <= bo + h
end

function P.Drop(def)
	local cx, cy = CursorPos()
	local targetBar
	for key, bar in pairs(ns.Bars.frames) do
		if bar:IsShown() and InRect(bar, cx, cy) then targetBar = key break end
	end
	local cfg = P.Cfg(def)
	if not targetBar then
		ns.Bars.Relayout(cfg.bar)
		return
	end
	-- hovering another plugin adopts its zone and drops before/after it
	local hover
	for _, d in ipairs(P.defs) do
		local c = P.Cfg(d)
		if d ~= def and c.bar == targetBar and d.button and d.button:IsShown() and InRect(d.button, cx, cy) then
			hover = d
			break
		end
	end
	cfg.bar = targetBar
	if hover then
		cfg.zone = P.Cfg(hover).zone
		local l, _, w = hover.button:GetRect()
		P.InsertOrder(def, hover, cx < l + w / 2)
	else
		local bar = ns.Bars.frames[targetBar]
		local l, _, w = bar:GetRect()
		local r = w > 0 and (cx - l) / w or 0
		cfg.zone = r < 0.34 and "LEFT" or r > 0.66 and "RIGHT" or "CENTER"
		P.AppendOrder(def)
	end
	ns.Bars.Relayout("top")
	ns.Bars.Relayout("bottom")
end

-- back to defaults for every plugin (after /suipanel reset wiped db.plugins)
function P.ResetLayout()
	for _, def in ipairs(P.defs) do
		ns.db.plugins[def.id] = nil
		P.Cfg(def)
		def.last, def.vis = nil, nil
		P.UpdateOne(def)
	end
	ns.Bars.Relayout("top")
	ns.Bars.Relayout("bottom")
end

-- right-click menu ---------------------------------------------------------------
local function ZoneItem(def, zone, label)
	local cfg = P.Cfg(def)
	return {
		text = label, checked = cfg.zone == zone, noClose = true,
		onClick = function()
			cfg.zone = zone
			P.AppendOrder(def)
			ns.Bars.Relayout("top")
			ns.Bars.Relayout("bottom")
		end,
	}
end

local function BarItem(def, bar, label)
	local cfg = P.Cfg(def)
	return {
		text = label, checked = cfg.bar == bar, noClose = true,
		onClick = function()
			cfg.bar = bar
			P.AppendOrder(def)
			ns.Bars.Relayout("top")
			ns.Bars.Relayout("bottom")
		end,
	}
end

function P.Menu(def, button)
	local above = P.Cfg(def).bar == "bottom"
	ns.OpenMenu(button, function()
		local cfg = P.Cfg(def)
		local items = {
			{ text = def.label, isTitle = true },
		}
		if def.menu then
			S.SafeCall(def.id .. ":menu", def.menu, def, items)
		end
		items[#items + 1] = { text = L["Panel"], isTitle = true }
		items[#items + 1] = {
			text = L["Show label"], checked = cfg.showLabel, noClose = true,
			onClick = function()
				cfg.showLabel = not cfg.showLabel
				def.last = nil
				P.UpdateOne(def)
			end,
		}
		if def.icon then
			items[#items + 1] = {
				text = L["Show icon"], checked = cfg.showIcon, noClose = true,
				onClick = function()
					cfg.showIcon = not cfg.showIcon
					P.SizeButton(def)
					ns.Bars.Relayout(cfg.bar)
				end,
			}
		end
		items[#items + 1] = { text = L["Move left"], onClick = function() P.Move(def, -1) end }
		items[#items + 1] = { text = L["Move right"], onClick = function() P.Move(def, 1) end }
		items[#items + 1] = { text = L["Zone"], isTitle = true }
		items[#items + 1] = ZoneItem(def, "LEFT", L["Left"])
		items[#items + 1] = ZoneItem(def, "CENTER", L["Center"])
		items[#items + 1] = ZoneItem(def, "RIGHT", L["Right"])
		items[#items + 1] = { text = L["Bar"], isTitle = true }
		items[#items + 1] = BarItem(def, "top", L["Top"])
		items[#items + 1] = BarItem(def, "bottom", L["Bottom"])
		items[#items + 1] = {
			text = L["Hide plugin"],
			onClick = function()
				cfg.shown = false
				def.vis = nil
				P.UpdateOne(def)
			end,
		}
		return items
	end, above)
end

-- boot ----------------------------------------------------------------------------
function P.Initialize()
	for _, def in ipairs(P.defs) do
		P.Cfg(def)
		Spawn(def)
	end
	-- wire plugin events: one bus handler per event drives all defs
	-- listening to it; onevent returning false skips the update
	for _, def in ipairs(P.defs) do
		if type(def.events) == "table" then
			for _, ev in ipairs(def.events) do
				local bucket = P.eventDefs[ev]
				if not bucket then
					bucket = {}
					P.eventDefs[ev] = bucket
					ns.RegisterBusEvent(ev, function(event, ...)
						for _, d in ipairs(bucket) do
							local skip = d.onevent and S.SafeCall(d.id .. ":event", d.onevent, d, event, ...)
							if skip ~= false then P.UpdateOne(d) end
						end
					end)
				end
				bucket[#bucket + 1] = def
			end
		end
	end

	P.RefreshAll()

	-- fast refresh for clock/fps; roster/friends data arrives via events
	C_Timer.NewTicker(1, function() S.SafeCall("panel:ticker", P.RefreshAll) end)
end
