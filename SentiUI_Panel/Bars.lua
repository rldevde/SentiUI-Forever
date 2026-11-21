-- Panel bars: thin full-width bars on the top and/or bottom screen edge.
-- Bars anchor to WorldFrame so they sit on the real screen edge even while
-- the viewport shrinks UIParent for "Adjust UI". Each bar lays out its
-- plugins in LEFT / CENTER / RIGHT zones; right-click on empty space opens
-- the bar menu; auto-hide fades the bar until the mouse nears the edge.
local _, ns = ...
local S = SentiUI
local L = ns.L
local Plain = ns.Plain

local ipairs, pairs = ipairs, pairs
local tinsert = table.insert
local CreateFrame = CreateFrame

local EDGE_PAD = 4
local MIN_GAP = 8 -- floor for the per-zone plugin spacing

local Bars = {}
ns.Bars = Bars
Bars.frames = {}

-- a bar's context menu (right-click on empty space)
local function BarMenu(key)
	local bar = Bars.frames[key]
	ns.OpenMenu(bar, function()
		local cfg = ns.db.bars[key]
		local P = ns.Plugins
		local items = {
			{ text = key == "top" and L["Top bar"] or L["Bottom bar"], isTitle = true },
			{
				text = L["Enabled"], checked = cfg.enabled, noClose = true,
				onClick = function() cfg.enabled = not cfg.enabled Bars.ApplyAll() end,
			},
			{
				text = L["Auto-hide"], checked = cfg.autoHide, noClose = true,
				onClick = function() cfg.autoHide = not cfg.autoHide Bars.ApplyBar(key) end,
			},
			{
				text = L["Adjust UI"], checked = cfg.adjustUI, noClose = true,
				onClick = function() cfg.adjustUI = not cfg.adjustUI Bars.ApplyAll() end,
			},
			{
				text = L["Hide in combat"], checked = cfg.hideInCombat, noClose = true,
				onClick = function() cfg.hideInCombat = not cfg.hideInCombat Bars.ApplyBar(key) end,
			},
			{
				text = L["Show border"], checked = cfg.border, noClose = true,
				onClick = function() cfg.border = not cfg.border Bars.ApplyBar(key) end,
			},
			{
				text = L["Gloss"], checked = cfg.gloss ~= false, noClose = true,
				onClick = function() cfg.gloss = cfg.gloss == false and true or false Bars.ApplyBar(key) end,
			},
			{
				text = L["Class-colored border"], checked = cfg.classColor, noClose = true,
				onClick = function() cfg.classColor = not cfg.classColor Bars.ApplyBar(key) end,
			},
			{ text = L["Bar height"], isTitle = true },
			{
				text = "-", noClose = true,
				onClick = function() cfg.height = math.max(14, cfg.height - 1) Bars.ApplyBar(key) Bars.Relayout(key) Bars.ApplyAll() end,
			},
			{
				text = "+", noClose = true,
				onClick = function() cfg.height = math.min(40, cfg.height + 1) Bars.ApplyBar(key) Bars.Relayout(key) Bars.ApplyAll() end,
			},
		}
		local hidden = {}
		for _, def in ipairs(P.defs) do
			if not P.Cfg(def).shown then hidden[#hidden + 1] = def end
		end
		items[#items + 1] = { text = L["Hidden plugins"], isTitle = true }
		if #hidden == 0 then
			items[#items + 1] = { text = L["(none)"], disabled = true }
		else
			for _, def in ipairs(hidden) do
				items[#items + 1] = {
					text = def.label, noClose = true,
					onClick = function()
						local c = P.Cfg(def)
						c.shown = true
						def.vis = nil
						P.UpdateOne(def)
					end,
				}
			end
		end
		items[#items + 1] = {
			text = L["Options"],
			onClick = function() if S.OptionsPanel and S.OptionsPanel.Toggle then S.OptionsPanel.Toggle() end end,
		}
		return items
	end, key == "bottom")
end

-- fade the bar in/out while auto-hide is on
local function WatchAutoHide(bar, key)
	local elapsed, cur = 0, 1
	bar.watcher = CreateFrame("Frame")
	bar.watcher:SetScript("OnUpdate", function(_, dt)
		elapsed = elapsed + dt
		if elapsed < 0.05 then return end
		local step = elapsed * 8
		elapsed = 0
		local cfg = ns.db.bars[key]
		if not cfg.autoHide or not bar:IsShown() then
			if cur ~= 1 then cur = 1 bar:SetAlpha(1) end
			return
		end
		-- slightly inflated hit rect so the bar pops up before the exact edge
		local over = bar:IsMouseOver(4, 4, -4, -4)
		local target = over and 1 or (cfg.fadeIdle or 0)
		if cur < target then cur = math.min(1, cur + step)
		elseif cur > target then cur = math.max(0, cur - step) end
		if cur ~= bar:GetAlpha() then bar:SetAlpha(cur) end
	end)
end

local function MakeBar(key)
	local bar = CreateFrame("Frame", "SentiUIPanelBar" .. key, UIParent, "BackdropTemplate")
	bar.key = key
	bar:EnableMouse(true)
	bar:SetFrameStrata("MEDIUM")
	bar:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then BarMenu(key) end
	end)
	S.Template(bar, "panel")
	-- accent line on the inner edge (toward the screen middle)
	ns.AccentEdge(bar, key == "top" and "BOTTOM" or "TOP")
	Bars.frames[key] = bar
	WatchAutoHide(bar, key)
	return bar
end

local ApplyBarStructure -- defined below; ApplyBar defers into it

-- (re)anchor + (re)style a bar from its settings
function Bars.ApplyBar(key)
	local bar = Bars.frames[key]
	local cfg = ns.db.bars[key]
	-- combat-hide rides on a secure driver: insecure Show/Hide of a
	-- frame that holds secure children is blocked during lockdown
	-- (ADDON_ACTION_BLOCKED), the driver hides natively instead
	if RegisterStateDriver and UnregisterStateDriver then
		if cfg.enabled and cfg.hideInCombat then
			RegisterStateDriver(bar, "visibility", "[combat] hide; show")
		else
			UnregisterStateDriver(bar, "visibility")
		end
	end
	S.RunOutOfCombat(ApplyBarStructure, key, cfg)
end

-- layout/aesthetic work; runs outside lockdown (structural calls on
-- parents of secure children are protected in combat)
ApplyBarStructure = function(key, cfg)
	local bar = Bars.frames[key]
	bar:Hide()
	local m = cfg.margin
	bar:ClearAllPoints()
	if key == "top" then
		bar:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", m, -m)
		bar:SetPoint("TOPRIGHT", WorldFrame, "TOPRIGHT", -m, -m)
	else
		bar:SetPoint("BOTTOMLEFT", WorldFrame, "BOTTOMLEFT", m, m)
		bar:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", -m, m)
	end
	bar:SetHeight(cfg.height)
	local c = S.colors
	bar:SetBackdropColor(c.bg.r, c.bg.g, c.bg.b, cfg.alpha)
	-- class color theme: border + accent edge tinted to the player class
	local bc = c.border
	if cfg.classColor then
		local ok, _, cls = pcall(UnitClass, "player")
		local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
		local cc = ok and colors and Plain(cls) and colors[Plain(cls)]
		if cc then bc = cc end
	end
	if bar.SetBackdropBorderColor then
		bar:SetBackdropBorderColor(bc.r, bc.g, bc.b, cfg.border and 1 or 0)
	end
	if bar.accentEdge then
		if cfg.classColor and bc ~= c.border then
			bar.accentEdge:SetVertexColor(bc.r, bc.g, bc.b, 1)
		else
			bar.accentEdge:SetVertexColor(c.accent.r, c.accent.g, c.accent.b, 0.6)
		end
		bar.accentEdge:SetShown(cfg.border)
	end
	ns.Gloss(bar, cfg.gloss ~= false)
	-- the visibility driver owns the in-combat state; show/hide here
	-- only covers the enabled flag
	bar:SetShown(cfg.enabled)
end

-- place every visible plugin of one bar into its zone chain
function Bars.Relayout(key)
	local bar = Bars.frames[key]
	if not bar then return end
	local P = ns.Plugins
	if not P then return end
	local cfg = ns.db.bars[key]
	local zones = { LEFT = {}, CENTER = {}, RIGHT = {} }
	for _, def in ipairs(P.Ordered()) do
		local pcfg = P.Cfg(def)
		local b = def.button
		if b and b:GetParent() == bar and pcfg.bar ~= key then
			-- moved to another bar since the last layout: detach here
			b:Hide()
		end
		if pcfg.bar == key and b then
			b:SetParent(bar)
			b:ClearAllPoints()
			b:SetHeight(cfg.height)
			b:SetFrameStrata(bar:GetFrameStrata())
			b:SetFrameLevel(bar:GetFrameLevel() + 2)
			local vis = pcfg.shown and not def.empty
			b:SetShown(vis)
			if vis then
				local z = zones[pcfg.zone] or zones.LEFT
				tinsert(z, def)
			end
		end
	end
	local gap = math.max(ns.db.spacing or 0, MIN_GAP)
	-- left zone: left to right in order, remembering its consumed width
	local prev
	local leftW = 0
	for _, def in ipairs(zones.LEFT) do
		def.button:SetPoint("LEFT", prev or bar, prev and "RIGHT" or "LEFT", prev and gap or EDGE_PAD, 0)
		leftW = leftW + (def.button.w or 40) + (prev and gap or EDGE_PAD)
		prev = def.button
	end
	-- right zone: built from the screen edge inward, last in order = far right
	prev = nil
	local rightW = 0
	for i = #zones.RIGHT, 1, -1 do
		local b = zones.RIGHT[i].button
		b:SetPoint("RIGHT", prev or bar, prev and "LEFT" or "RIGHT", prev and -gap or -EDGE_PAD, 0)
		rightW = rightW + (b.w or 40) + (prev and gap or EDGE_PAD)
		prev = b
	end
	-- center zone: centered as one block, clamped into the space between
	-- the left and right zones so it can never overlap them
	local cw = -gap
	for _, def in ipairs(zones.CENTER) do cw = cw + (def.button.w or 40) + gap end
	local barW = bar:GetWidth() or 0
	local lo = leftW > 0 and leftW + gap or leftW
	local hi = barW - (rightW > 0 and rightW + gap or rightW)
	local startX = barW / 2 - cw / 2
	if hi - lo < cw then
		-- not enough room: squash the group right after the left zone
		startX = lo
	elseif startX < lo then
		startX = lo
	elseif startX + cw > hi then
		startX = hi - cw
	end
	prev = nil
	for i, def in ipairs(zones.CENTER) do
		if i == 1 then
			def.button:SetPoint("LEFT", bar, "LEFT", startX, 0)
		else
			def.button:SetPoint("LEFT", prev, "RIGHT", gap, 0)
		end
		prev = def.button
	end
end

function Bars.ApplyAll()
	for key in pairs(Bars.frames) do
		Bars.ApplyBar(key)
		S.RunOutOfCombat(Bars.Relayout, key)
	end
	ns.Viewport.Apply()
end

function Bars.Initialize()
	MakeBar("top")
	MakeBar("bottom")
	Bars.ApplyAll()
	for _, ev in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }) do
		ns.RegisterBusEvent(ev, function(event)
			Bars.inCombat = event == "PLAYER_REGEN_DISABLED"
			Bars.ApplyAll()
		end)
	end
end
