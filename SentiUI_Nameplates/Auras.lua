-- Debuff row above the name, driven by an engine AuraContainer - the same
-- path the buff bars take. The container assigns auras to buttons inside
-- the engine, so icons show even when the aura data itself is secret
-- (combat, restricted zones): nothing readable ever crosses Lua.
--
-- The row is split into three aura groups so you can see WHO applied a
-- debuff: yours get the gold accent edge, your group's a blue edge, and
-- debuffs from outside the group are desaturated with the plain dark
-- edge. The engine sorts each group's auras into it - no Lua reads.
local _, ns = ...
local S = SentiUI

local Auras = {}
ns.Auras = Auras

local FLOWDIRECTION = AnchorUtil and AnchorUtil.FlowDirection
local FLOWAXIS = AnchorUtil and AnchorUtil.FlowLayoutAxis
local SORTMETHOD = _G.AuraContainerSortMethod
local SORTDIRECTION = _G.AuraContainerSortDirection
local DISPELSTYLE = Enum.CustomAuraButtonDispelTypeTextureStyle

local ICON = 16
local GAP = 4 -- minimum breathing room between icons

local ACCENT = { 0.92, 0.68, 0.20 } -- Sentinel gold: your debuffs
local GROUPC = { 0.20, 0.62, 1.00 } -- secondary blue: party/raid debuffs

-- initializeFrame: the engine owns the button and keeps feeding it
-- icon/duration/count; we only attach the widgets it should fill plus the
-- source-colored back edge. Works for combat-spawned children too.
local function InitButton(edge, desaturate)
	return function(button)
		local back = button:CreateTexture(nil, "BACKGROUND", nil, -2)
		back:SetPoint("TOPLEFT", -1, 1)
		back:SetPoint("BOTTOMRIGHT", 1, -1)
		back:SetColorTexture(edge[1], edge[2], edge[3], 1)
		local dispel = button:CreateTexture(nil, "BACKGROUND", nil, -1)
		dispel:SetAllPoints()
		dispel:SetColorTexture(0.13, 0.16, 0.22, 1)
		if button.AddDispelTypeTexture then
			pcall(button.AddDispelTypeTexture, button, dispel, {
				style = DISPELSTYLE and DISPELSTYLE.PreserveAsset or nil,
				showWhenHarmful = true,
				showWhenHelpful = false,
				showWithoutDispelType = true,
			})
		end
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("TOPLEFT", 1, -1)
		icon:SetPoint("BOTTOMRIGHT", -1, 1)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		if desaturate then icon:SetDesaturated(true) end
		button:SetIcon(icon)
		local cd = CreateFrame("Cooldown", "$parentCooldown", button,
			"CooldownFrameTemplate")
		cd:SetAllPoints(icon)
		cd:SetDrawEdge(false)
		cd:SetHideCountdownNumbers(true) -- no timer numbers on plate icons
		button:SetDurationCooldown(cd)
		local raised = CreateFrame("Frame", nil, button)
		raised:SetAllPoints()
		raised:SetFrameLevel(button:GetFrameLevel() + 3)
		local count = raised:CreateFontString(nil, "OVERLAY")
		count:SetFont(S.media.font, 8, "OUTLINE")
		count:SetShadowOffset(1, -1)
		count:SetShadowColor(0, 0, 0, 0.9)
		count:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -1)
		button:SetApplicationCount(count)
		button:SetSize(ICON, ICON)
	end
end

local DARK = { 0.13, 0.16, 0.22 }

local nextID = 0

local function MakeContainer(p, mineOnly, maxN)
	nextID = nextID + 1
	local c = CreateFrame("AuraContainer",
		"SentiUI_NPAura" .. nextID, p, "CustomAuraContainerTemplate")
	c.layout = {
		elementSpacing = GAP, elementWidth = ICON, elementHeight = ICON,
		lineSpacing = GAP,
	}
	pcall(c.SetFlowLayoutAnchorPoint, c, "BOTTOMLEFT")
	pcall(c.SetFlowLayoutGrowthDirection, c,
		FLOWDIRECTION and FLOWDIRECTION.Right,
		FLOWDIRECTION and FLOWDIRECTION.Up)
	pcall(c.SetFlowLayoutPadding, c, 0, 0, 0, 0)
	if FLOWAXIS then
		pcall(c.SetFlowLayoutAxis, c, FLOWAXIS.Horizontal)
	end
	pcall(c.SetFlowLayoutMaximumLineSize, c, (ICON + GAP) * maxN)
	local params = {
		maxFrameCount = maxN,
		sortMethod = SORTMETHOD and SORTMETHOD.Default or nil,
		sortDirection = SORTDIRECTION and SORTDIRECTION.Normal or nil,
		layout = c.layout,
	}
	-- yours first, then the group's, then everyone else's; each group's
	-- initializeFrame paints its own source edge. AddAuraGroup can refuse
	-- in combat or restricted zones - nil then, retried next update.
	params.initializeFrame = InitButton(ACCENT, false)
	if not pcall(c.AddAuraGroup, c, "mine", "HARMFUL|PLAYER", params) then
		c:Hide()
		c:SetParent(nil)
		return nil
	end
	if not mineOnly then
		params.initializeFrame = InitButton(GROUPC, false)
		pcall(c.AddAuraGroup, c, "group", "HARMFUL|RAID|!PLAYER", params)
		params.initializeFrame = InitButton(DARK, true)
		pcall(c.AddAuraGroup, c, "other", "HARMFUL|!PLAYER|!RAID", params)
	end
	c:SetSize(1, 1)
	c:EnableMouse(false)
	c:SetEnabled(true)
	return c
end

function Auras.Clear(p)
	if p.auraC then p.auraC:Hide() end
end

function Auras.Update(p)
	local db = ns.Cfg()
	if not db.debuffs or not p.unit or p.friendly then
		return Auras.Clear(p)
	end
	local maxN = db.maxDebuffs or 5
	local mineOnly = db.onlyMyDebuffs ~= false
	-- a mode or count change needs a fresh container - group filters are
	-- fixed at AddAuraGroup time
	local kind = mineOnly and "mine" or "split"
	if p.auraC and (p.auraC.kind ~= kind or p.auraC.maxN ~= maxN) then
		p.auraC:Hide()
		p.auraC:SetParent(nil)
		p.auraC = nil
	end
	if not p.auraC then
		local ok, c = pcall(MakeContainer, p, mineOnly, maxN)
		if ok and c then
			c.kind = kind
			c.maxN = maxN
			p.auraC = c
		end
	end
	if not p.auraC then return end
	-- icons sit left-aligned above the name row
	p.auraC:ClearAllPoints()
	p.auraC:SetPoint("BOTTOMLEFT", p.name, "TOPLEFT", 0, 2)
	if p.auraC.unit ~= p.unit then
		if pcall(p.auraC.SetUnit, p.auraC, p.unit) then
			p.auraC.unit = p.unit
		end
	end
	p.auraC:Show()
end
