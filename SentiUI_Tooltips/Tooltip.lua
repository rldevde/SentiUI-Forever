-- Core: config, the fixed/cursor anchor, the hook wiring and enable.
-- Tooltips are shared with secure code, so nothing here replaces game
-- functions: every behavior is a post-hook (TooltipDataProcessor) or a
-- post-hook on GameTooltip_SetDefaultAnchor for placement.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Core = {}
ns.Core = Core

local cfg
function ns.Cfg() return cfg end

local anchor

local function Anchor()
	if anchor then return anchor end
	anchor = CreateFrame("Frame", "SentiUITipAnchor", UIParent)
	anchor:SetSize(200, 80)
	-- parked at the classic tooltip spot; Register captures this as the
	-- reset point before we hand out a center-offset fallback
	anchor:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -260, 220)
	anchor:Hide() -- only the mover handle shows it
	S.Movers.Register(anchor, "tooltip.anchor", L["Tooltips"],
		{ x = -320, y = -180 })
	return anchor
end

-- placement ------------------------------------------------------------------
local function Place(tip)
	local db = cfg
	if db.anchor == "cursor" then
		local ok, x, y = pcall(GetCursorPosition)
		if ok and type(x) == "number" then
			local s = tip.GetEffectiveScale and tip:GetEffectiveScale() or 1
			if type(s) ~= "number" or s <= 0 or S.IsSecret(s) then s = 1 end
			tip:ClearAllPoints()
			tip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
				x / s + db.cursorX, y / s + db.cursorY)
		end
	else
		tip:ClearAllPoints()
		tip:SetPoint("BOTTOMRIGHT", Anchor(), "BOTTOMRIGHT", 0, 0)
	end
end

-- whether a tooltip is anchored to a specific owner on purpose (item link,
-- bag slot, action button) and must keep that spot
local function IntentionallyAnchored(tip)
	local at = tip.GetAnchorType and tip:GetAnchorType() or nil
	if S.IsSecret(at) then at = nil end
	if type(at) ~= "string" then return false end
	-- ANCHOR_NONE = free-floating (default spot) - the fixed point claims
	-- those. ANCHOR_CURSOR is a deliberate at-cursor placement (map POIs,
	-- minimap hovers, chat links): yanking it to the dock is what made
	-- minimap tooltips appear in the wrong place - always respected,
	-- the way DaylightUI/ElvUI leave them at the hovered thing.
	if at == "ANCHOR_CURSOR" then return true end
	return at ~= "ANCHOR_NONE"
end

local function Reposition(tip)
	if tip ~= GameTooltip then return end -- shopping/itemref keep their owners
	if IntentionallyAnchored(tip) then return end
	Place(tip)
end

local hooked = false
local function InstallHooks()
	if hooked then return end
	hooked = true
	-- the game re-anchors the shared tooltip through one function; a
	-- post-hook redirects it to our anchor or the cursor
	if type(GameTooltip_SetDefaultAnchor) == "function" then
		hooksecurefunc("GameTooltip_SetDefaultAnchor",
			function(tip) Reposition(tip) end)
	end
	-- world/unit tooltips don't always pass through the default-anchor
	-- function: check every show so the fixed point really is fixed.
	-- WatchShown, not OnShow: an insecure script on the shared tooltip
	-- runs inside the tooltip dispatch, where the client keeps comparing
	-- secret unit values after the script returns - the crash pattern the
	-- GameTooltip OnTooltipSetUnit hook produced before.
	if type(GameTooltip) == "table" and GameTooltip.IsShown then
		S.WatchShown(GameTooltip, function(tip)
			S.SafeCall("tips:place", Reposition, tip)
		end)
	end
	local TDP = TooltipDataProcessor
	if not (TDP and TDP.AddTooltipPostCall) then return end
	local types = Enum and Enum.TooltipDataType
	-- skin + font pass on anything that shows, including late-built tips
	if TDP.AllTypes then
		TDP.AddTooltipPostCall(TDP.AllTypes, function(tip)
			S.SafeCall("tips:skin", function()
				ns.Skin.Ensure(tip)
				ns.Skin.Fonts(tip)
				ns.Skin.ResetBorder(tip)
				ns.Skin.ResetAccent(tip)
				ns.Skin.Reflow(tip)
				-- hide ARTWORK textures that failed to load (blank white squares)
				ns.Skin.FixBlankIcons(tip)
			end)
		end)
	end
	if types and types.Unit then
		TDP.AddTooltipPostCall(types.Unit, function(tip)
			S.SafeCall("tips:unit", function()
				ns.Skin.Ensure(tip)
				ns.Unit.Apply(tip)
			end)
		end)
	end
	if types and types.Item then
		TDP.AddTooltipPostCall(types.Item, function(tip, data)
			S.SafeCall("tips:item", function()
				ns.Skin.Ensure(tip)
				ns.Item.Apply(tip, data)
				ns.Skin.Reflow(tip)
			end)
		end)
	end
	if types and types.Spell then
		TDP.AddTooltipPostCall(types.Spell, function(tip, data)
			S.SafeCall("tips:spell", function()
				ns.Skin.Ensure(tip)
				ns.Item.Spell(tip, data)
			end)
		end)
	end
end

-- scale ----------------------------------------------------------------------
local function ApplyScale()
	for _, name in ipairs(ns.Skin.NAMED) do
		local tip = _G[name]
		if type(tip) == "table" and tip.SetScale then
			pcall(tip.SetScale, tip, cfg.scale or 1)
		end
	end
end

function Core.Enable(mod)
	cfg = mod.db
	Anchor()
	ns.Unit.StyleBar()
	InstallHooks()
	ns.Skin.All()
	ApplyScale()
end

function Core.SettingChanged(mod, path)
	cfg = mod.db
	if path == "scale" then ApplyScale() end
end
