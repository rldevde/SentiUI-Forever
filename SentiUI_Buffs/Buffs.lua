-- Buff/debuff bars built on the client's own AuraContainer - the same
-- engine path ElvUI uses on modern clients (SecureAuraHeaderTemplate is
-- gone). The container assigns auras to buttons inside the engine, so
-- slots appear and disappear correctly even in combat and secret aura
-- data never crosses addon Lua. Our part is initializeFrame: it wires
-- our textures, cooldown and font strings into the engine-owned button.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Core = {}
ns.Core = Core

local db -- live module db after Enable
Core.bars = {}

local FLOWDIRECTION = AnchorUtil and AnchorUtil.FlowDirection
local FLOWAXIS = AnchorUtil and AnchorUtil.FlowLayoutAxis
local SORTMETHOD = _G.AuraContainerSortMethod
local SORTDIRECTION = _G.AuraContainerSortDirection
local ENCHANTSLOT = _G.AuraContainerItemEnchantmentSlot
local ENCHANTPLACE = _G.CustomAuraContainerItemEnchantmentPlacement
local DISPELSTYLE = Enum.CustomAuraButtonDispelTypeTextureStyle

local SENTI_GOLD = { 0.92, 0.68, 0.20 }

-- ---------------------------------------------------------------------------
-- initializeFrame - called by the container for every spawned AuraButton.
-- The engine owns the button and keeps feeding it icon/duration/count data;
-- we only attach the widgets it should fill. Works for combat-spawned
-- children too, since the engine calls it again for each new button.
-- ---------------------------------------------------------------------------

-- compact duration formatter ("45s"/"10m"/"2h"/"3d") for SetDurationText
local durFormatter
local function GetDurFormatter()
	if durFormatter ~= nil then return durFormatter or nil end
	durFormatter = false
	local make = C_StringUtil and C_StringUtil.CreateNumericRuleFormatter
	if type(make) ~= "function" then return nil end
	local rounding = Enum and Enum.NumericRuleFormatRounding
	local steps = {
		{ threshold = 0, format = "" },
		{ threshold = 1, format = "%ds" },
		{ threshold = 60, format = "%dm", step = 1,
			components = { { div = 60, step = 1 } } },
		{ threshold = 3600, format = "%dh", step = 1,
			components = { { div = 3600, step = 1 } } },
		{ threshold = 86400, format = "%dd", step = 1,
			components = { { div = 86400, step = 1 } } },
	}
	if rounding and rounding.Down then
		for _, s in ipairs(steps) do s.rounding = rounding.Down end
	end
	local ok, f = pcall(make)
	if ok and f and pcall(f.SetBreakpoints, f, steps) then
		durFormatter = f
	end
	return durFormatter or nil
end

local function InitButton(button)
	local size = db.iconSize

	-- ring behind the icon: the engine tints it by dispel type on debuffs
	-- when debuffColor is on, otherwise it stays our gold everywhere
	local dispel = button:CreateTexture(nil, "BACKGROUND", nil, -1)
	dispel:SetAllPoints()
	dispel:SetColorTexture(SENTI_GOLD[1], SENTI_GOLD[2], SENTI_GOLD[3], 1)
	button.sentiDispel = dispel
	if db.debuffColor and button.AddDispelTypeTexture then
		local show = db.border ~= false
		pcall(button.AddDispelTypeTexture, button, dispel, {
			style = DISPELSTYLE and DISPELSTYLE.PreserveAsset or nil,
			showWhenHarmful = show,
			showWhenHelpful = false,
			showWithoutDispelType = show,
		})
	else
		dispel:SetShown(db.border ~= false)
	end

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", -1, 1)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button:SetIcon(icon)
	button.sentiIcon = icon

	-- cooldown widget: the engine feeds it the duration object and draws
	-- the swipe - its own countdown numbers stay OFF, our text sits below
	local cd = CreateFrame("Cooldown", "$parentCooldown", button,
		"CooldownFrameTemplate")
	cd:SetAllPoints(icon)
	cd:SetDrawEdge(false)
	cd:SetHideCountdownNumbers(true)
	button:SetDurationCooldown(cd)
	button.sentiCooldown = cd

	-- stacks, top right on the icon
	local raised = CreateFrame("Frame", nil, button)
	raised:SetAllPoints()
	raised:SetFrameLevel(button:GetFrameLevel() + 3)
	local count = raised:CreateFontString(nil, "OVERLAY")
	count:SetFont(S.media.font, 10, "OUTLINE")
	count:SetShadowOffset(1, -1)
	count:SetShadowColor(0, 0, 0, 0.9)
	count:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -1)
	button:SetApplicationCount(count)

	-- duration text: a fontstring of ours under the icon that the engine
	-- fills via SetDurationText - small, outlined, secret-safe
	local textSize = math.max(8, math.floor(size * 0.32))
	local dur = raised:CreateFontString(nil, "OVERLAY")
	dur:SetFont(S.media.font, textSize, "OUTLINE")
	dur:SetShadowOffset(1, -1)
	dur:SetShadowColor(0, 0, 0, 0.9)
	dur:SetPoint("TOP", icon, "BOTTOM", 0, -1)
	if button.SetDurationText then
		local fmt = GetDurFormatter()
		if not (fmt and pcall(button.SetDurationText, button, dur,
			{ textFormatter = fmt })) then
			pcall(button.SetDurationText, button, dur)
		end
	end

	-- right-click cancels buffs through the engine's own secure path
	if button.SetCancelAuraButtons then
		pcall(button.SetCancelAuraButtons, button, "RightButtonUp")
	end

	button:SetSize(size, size)
end

-- ---------------------------------------------------------------------------
-- Containers
-- ---------------------------------------------------------------------------

local function ConfigureContainer(c)
	local size = db.iconSize
	local step = size + db.spacing
	c.layout.elementSpacing = db.spacing
	c.layout.elementWidth = size
	c.layout.elementHeight = size
	-- +10px row gap: the small duration text lives under each icon now
	c.layout.lineSpacing = db.spacing + 10

	if db.growLeft then
		pcall(c.SetFlowLayoutAnchorPoint, c, "TOPRIGHT")
		pcall(c.SetFlowLayoutGrowthDirection, c,
			FLOWDIRECTION and FLOWDIRECTION.Left,
			FLOWDIRECTION and FLOWDIRECTION.Down)
	else
		pcall(c.SetFlowLayoutAnchorPoint, c, "TOPLEFT")
		pcall(c.SetFlowLayoutGrowthDirection, c,
			FLOWDIRECTION and FLOWDIRECTION.Right,
			FLOWDIRECTION and FLOWDIRECTION.Down)
	end
	pcall(c.SetFlowLayoutPadding, c, 0, 0, 0, 0)
	if FLOWAXIS then
		pcall(c.SetFlowLayoutAxis, c, FLOWAXIS.Horizontal)
	end
	pcall(c.SetFlowLayoutMaximumLineSize, c, step * db.perRow)
	pcall(c.SetScale, c, db.scale or 1)
end

local function BuildContainer(scope, key, label, filter, default)
	local c = CreateFrame("AuraContainer",
		"SentiUI_Buffs" .. scope .. "Container", UIParent,
		"CustomAuraContainerTemplate")
	c:SetFrameStrata("MEDIUM")
	c:SetSize(db.iconSize, db.iconSize)
	c:EnableMouse(false)
	c.filter = filter
	c.layout = {}

	ConfigureContainer(c)

	local params = {
		initializeFrame = InitButton,
		maxFrameCount = 40,
		sortMethod = SORTMETHOD and SORTMETHOD.Default or nil,
		sortDirection = SORTDIRECTION and SORTDIRECTION.Normal or nil,
		layout = c.layout,
	}
	c:AddAuraGroup("auras", filter, params)

	-- weapon enchants ride ahead of the buffs on the buff bar
	if filter == "HELPFUL" and c.AddItemEnchantment and ENCHANTSLOT then
		c:AddItemEnchantment(ENCHANTSLOT.MainHand,
			{ initializeFrame = InitButton })
		c:AddItemEnchantment(ENCHANTSLOT.OffHand,
			{ initializeFrame = InitButton })
		if c.SetItemEnchantmentLayout and ENCHANTPLACE then
			c:SetItemEnchantmentLayout({
				elementSpacing = db.spacing,
				placement = ENCHANTPLACE.BeforeAuraGroups,
			})
		end
	end

	c:SetUnit("player")

	-- the mover holds a separate holder frame, not the container: the
	-- container is only one icon big while the buttons fan out past its
	-- rect, so a holder sized like the row gives a real grab handle. The
	-- container anchors to the holder's TOPRIGHT and follows it - but the
	-- client owns the container's geometry and can re-anchor it on every
	-- aura update, so the anchor is re-applied after each layout tick and
	-- after every mover move (same pattern DaylightUI uses).
	local holder = CreateFrame("Frame",
		"SentiUI_Buffs" .. scope .. "Holder", UIParent)
	local width = math.min(db.perRow, 8) * (db.iconSize + db.spacing)
	holder:SetSize(math.max(60, width), db.iconSize)
	c.holder = holder
	Core.PlaceContainer(c)

	c:SetEnabled(true)
	c:Show() -- first update

	-- the client can steal the container's anchor at any layout pass - not
	-- just on UNIT_AURA - so a light watch re-pins it to the holder
	-- whenever the two drift apart (skipped in combat; SetPoint is
	-- protected on this frame then). The watch sits on a helper frame:
	-- the AuraContainer's own OnUpdate is a forbidden script handler.
	local acc = 0
	local watch = CreateFrame("Frame", nil, holder)
	watch:SetScript("OnUpdate", function(_, e)
		acc = acc + e
		if acc < 0.5 then return end
		acc = 0
		if InCombatLockdown() then return end
		local ok, _, relTo = pcall(c.GetPoint, c, 1)
		if ok and relTo ~= c.holder then
			Core.PlaceContainer(c)
		end
	end)

	Core.bars[scope] = c
	S.Movers.Register(holder, key, label, default, {
		onMoved = function() Core.PlaceContainer(c) end,
	})
	return c
end

-- the client can reset the container's anchor on its own layout passes;
-- pin it back onto the holder (out of combat only - SetPoint is protected
-- on this frame while restricted)
function Core.PlaceContainer(c)
	if not c or not c.holder then return end
	S.RunOutOfCombat(function()
		pcall(function()
			c:ClearAllPoints()
			c:SetPoint("TOPRIGHT", c.holder, "TOPRIGHT", 0, 0)
		end)
	end)
end

local replacePending
local function ReplaceContainers()
	if replacePending then return end
	replacePending = true
	C_Timer.After(0.2, function()
		replacePending = nil
		for _, c in pairs(Core.bars) do
			Core.PlaceContainer(c)
		end
	end)
end

-- mover defaults are screen-center offsets; compute them from the real
-- minimap rect so the bars dock next to it wherever it lives
-- mover defaults are screen-center offsets for the HOLDER's center; the
-- container pins its TOPRIGHT to the holder's TOPRIGHT, so the icon row's
-- top-right edge is what docks next to the minimap
local function MinimapPos(ox, oy)
	local map = Minimap or _G.MinimapCluster
	local ok, l, t = pcall(function()
		return map and map:GetLeft(), map and map:GetTop() end)
	local w, h = UIParent:GetSize()
	local size = db.iconSize or 28
	local width = math.min(db.perRow or 12, 8) * (size + (db.spacing or 3))
	width = math.max(60, width)
	if ok and l and t and w then
		return { x = l - 6 - width / 2 - w / 2 + (ox or 0),
			y = t - 2 - size / 2 - h / 2 + (oy or 0) }
	end
	-- no minimap rect: park top-right, where the minimap usually lives
	return { x = (w or 0) / 2 - 230 - width / 2 + (ox or 0),
		y = (h or 0) / 2 - 40 + (oy or 0) }
end

local parked
local function ParkBlizzard()
	if parked or not db.hideBlizzard then return end
	parked = CreateFrame("Frame")
	parked:Hide()
	-- Blizzard scripts call layout methods on GetParent() - stub them
	parked.Layout = function() end
	parked.MarkDirty = function() end
	parked.SetNeedsLayout = function() end
	parked.UpdateLayout = function() end
	parked.IsLayoutFrame = function() return false end
	for _, f in ipairs({ BuffFrame, DebuffFrame,
		TemporaryEnchantFrame }) do
		if f then
			pcall(function()
				f:UnregisterAllEvents()
				f:Hide()
				f:SetParent(parked)
				if f.SetScript then f:SetScript("OnShow", f.Hide) end
			end)
		end
	end
end

-- the container's provider refuses to wire its AuraButtons when it is
-- created inside a restricted caller - build it from a clean timer tick
local function BuildAll()
	BuildContainer("buff", "buffs.buff", L["Buff bar"], "HELPFUL",
		MinimapPos(0, 0))
	BuildContainer("debuff", "buffs.debuff", L["Debuff bar"], "HARMFUL",
		MinimapPos(0, -(db.iconSize + db.spacing + 8)))
	ParkBlizzard()
end

function Core.Apply()
	for _, c in pairs(Core.bars) do
		ConfigureContainer(c)
		pcall(c.UpdateAllAuras, c)
	end
end

function Core.SettingChanged() Core.Apply() end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db

	if InCombatLockdown() then
		S.RunOutOfCombat(function()
			C_Timer.After(0, BuildAll)
		end)
	else
		C_Timer.After(0, BuildAll)
	end

	-- the client can take the container's anchor back on aura updates -
	-- pin it to the holder again (debounced, deferred out of combat)
	S.RegisterEvent("UNIT_AURA", function(_, unit)
		if unit == "player" then ReplaceContainers() end
	end)
	S.RegisterEvent("PLAYER_REGEN_ENABLED", Core.Apply)
end
