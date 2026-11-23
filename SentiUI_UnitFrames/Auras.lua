-- Auras: engine AuraContainer rows above (buffs) and below (debuffs) the
-- unit frame - the same path the buff bars take. The container assigns
-- auras to buttons inside the engine, so icons show even when the aura
-- data itself is secret (combat, restricted zones): nothing readable ever
-- crosses Lua. For group frames a light readable scan still drives the
-- dispel-type border - it degrades to nothing when data is secret.
--
-- Every engine call is wrapped: AddAuraGroup can refuse in combat or
-- restricted zones, and a throw inside Refresh would kill the cast bar
-- that runs after it. Failed containers are retried on the next update.
local _, ns = ...
local S = SentiUI
local Plain, CanAccess = ns.Plain, ns.CanAccess

local ipairs, type = ipairs, type
local CreateFrame = CreateFrame

local ICON = 18
local GAP = 6 -- minimum breathing room between icons
local nextID = 0

local Auras = {}
ns.Auras = Auras

local FLOWDIRECTION = AnchorUtil and AnchorUtil.FlowDirection
local FLOWAXIS = AnchorUtil and AnchorUtil.FlowLayoutAxis
local SORTMETHOD = _G.AuraContainerSortMethod
local SORTDIRECTION = _G.AuraContainerSortDirection
local DISPELSTYLE = Enum.CustomAuraButtonDispelTypeTextureStyle

local function AuraAt(unit, i, filter)
	if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return nil end
	local ok, a = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
	if not ok or not CanAccess(a) then return nil end
	return a
end

-- first readable dispel type on the unit's debuffs ("Magic", "Curse", ...)
function Auras.DispelType(unit)
	for i = 1, 20 do
		local a = AuraAt(unit, i, "HARMFUL|RAID_PLAYER_DISPELLABLE")
		if not a then a = AuraAt(unit, i, "HARMFUL") end
		if not a then return nil end
		local t = Plain(a.dispelName)
		if type(t) == "string" and t ~= "" then return t end
	end
end

local DISPEL_COLORS = {
	Magic = { 0.20, 0.60, 1.00 }, Curse = { 0.60, 0.20, 1.00 },
	Disease = { 0.60, 0.40, 0.00 }, Poison = { 0.00, 0.60, 0.00 },
	[""] = { 0.80, 0.10, 0.10 }, -- undispellable / bleed
}
Auras.DISPEL_COLORS = DISPEL_COLORS

-- initializeFrame: the engine owns the button and keeps feeding it
-- icon/duration/count; we only attach the widgets it should fill. Works
-- for combat-spawned children too - secret data never enters Lua.
local function InitButton(harmful, size)
	size = size or ICON
	return function(button)
		-- slot fill: an unmanaged dark backdrop. The engine's dispel-type
		-- texture lives on a SEPARATE overlay and only appears with a real
		-- dispel type - it may be scaled past the button, so an always-on
		-- dark managed texture rendered as a blob under the row
		local bg = button:CreateTexture(nil, "BACKGROUND", nil, -2)
		bg:SetAllPoints()
		bg:SetColorTexture(0.13, 0.16, 0.22, 1)
		local dispel = button:CreateTexture(nil, "BACKGROUND", nil, -1)
		dispel:SetAllPoints()
		dispel:SetColorTexture(1, 1, 1, 0.45)
		if button.AddDispelTypeTexture then
			pcall(button.AddDispelTypeTexture, button, dispel, {
				style = DISPELSTYLE and DISPELSTYLE.PreserveAsset or nil,
				showWhenHarmful = harmful,
				showWhenHelpful = false,
				showWithoutDispelType = false,
			})
		else
			dispel:Hide()
		end
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("TOPLEFT", 1, -1)
		icon:SetPoint("BOTTOMRIGHT", -1, 1)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		button:SetIcon(icon)
		-- soft rounded corners via the core's raster caps
		button.icon = icon
		if S.IconRound then S.IconRound(button, 2) end
		-- cooldown widget: the engine feeds it the duration object and
		-- draws the countdown itself
		local cd = CreateFrame("Cooldown", "$parentCooldown", button,
			"CooldownFrameTemplate")
		cd:SetAllPoints(icon)
		cd:SetDrawEdge(false)
		cd:SetHideCountdownNumbers(true) -- no timer numbers on unit-frame icons
		button:SetDurationCooldown(cd)
		local raised = CreateFrame("Frame", nil, button)
		raised:SetAllPoints()
		raised:SetFrameLevel(button:GetFrameLevel() + 3)
		-- media border ring on every aura tile (white, low alpha - a
		-- readable hairline that follows the rounded silhouette)
		local ib = S.Tex and S.Tex("IconBorder")
		if ib then
			local bt = raised:CreateTexture(nil, "OVERLAY")
			bt:SetAllPoints()
			bt:SetTexture(ib)
			bt:SetVertexColor(1, 1, 1, 0.35)
		end
		local count = raised:CreateFontString(nil, "OVERLAY")
		count:SetFont(S.media.font, 8, "OUTLINE")
		count:SetShadowOffset(1, -1)
		count:SetShadowColor(0, 0, 0, 0.9)
		count:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -1)
		button:SetApplicationCount(count)
		button:SetSize(size, size)
	end
end

-- whole creation under one pcall: CreateFrame/AddAuraGroup/flow setup can
-- refuse mid-fight or in restricted zones - nil then, retried next update
function Auras.Create(f, filter, iconSize, maxOverride)
	local size = iconSize or ICON
	local harmful = filter == "HARMFUL"
	local db = f.db or {}
	local maxN = maxOverride
		or (harmful and (db.maxDebuffs or 12) or (db.maxBuffs or 8))
	nextID = nextID + 1
	local ok, c = pcall(function()
		local c = CreateFrame("AuraContainer",
			"SentiUI_UFAura" .. nextID, f, "CustomAuraContainerTemplate")
		c.filter = filter
		c.rowH = size
		c.layout = {
			elementSpacing = GAP, elementWidth = size, elementHeight = size,
			lineSpacing = GAP,
		}
		-- buffs grow right+up from the frame's top edge, debuffs right+down
		-- from its bottom edge
		pcall(c.SetFlowLayoutAnchorPoint, c,
			harmful and "TOPLEFT" or "BOTTOMLEFT")
		pcall(c.SetFlowLayoutGrowthDirection, c,
			FLOWDIRECTION and FLOWDIRECTION.Right,
			FLOWDIRECTION and (harmful and FLOWDIRECTION.Down
				or FLOWDIRECTION.Up))
		pcall(c.SetFlowLayoutPadding, c, 0, 0, 0, 0)
		if FLOWAXIS then
			pcall(c.SetFlowLayoutAxis, c, FLOWAXIS.Horizontal)
		end
		pcall(c.SetFlowLayoutMaximumLineSize, c, (size + GAP) * maxN)
		c:AddAuraGroup("auras", filter, {
			initializeFrame = InitButton(harmful, size),
			maxFrameCount = maxN,
			sortMethod = SORTMETHOD and SORTMETHOD.Default or nil,
			sortDirection = SORTDIRECTION and SORTDIRECTION.Normal or nil,
			layout = c.layout,
		})
		return c
	end)
	if not ok or not c then return nil end
	-- like the buff bars: the container rect stays tiny while the engine
	-- fans the buttons out past it
	c:SetSize(1, 1)
	c:EnableMouse(false)
	c:SetEnabled(true)
	return c
end

-- anchor: buffs above the frame, debuffs below (icons hang outside the
-- frame through the container's flow layout)
function Auras.Layout(f, h, point, rel, x, y)
	h:ClearAllPoints()
	h:SetPoint(point, f, rel, x, y)
end

function Auras.Update(f)
	local unit = f.unit
	if not unit then return end

	-- lazily (re)create the engine rows: a refused AddAuraGroup leaves
	-- f.Buffs/f.Debuffs nil so the next update tries again
	local db = f.db
	if db and db.auras == true then
		if not f.Buffs then
			f.Buffs = Auras.Create(f, "HELPFUL")
			if f.Buffs then
				Auras.Layout(f, f.Buffs, "BOTTOMLEFT", "TOPLEFT", 0, 3)
			end
		end
		if not f.Debuffs then
			f.Debuffs = Auras.Create(f, "HARMFUL")
			if f.Debuffs then
				Auras.Layout(f, f.Debuffs, "TOPLEFT", "BOTTOMLEFT", 0, -3)
			end
		end
	end

	-- external defensives on group cells: a tiny engine-owned corner row,
	-- filtered to buffs flagged EXTERNAL_DEFENSIVE (pain suppression,
	-- ironbark, life cocoon, ...). Engine feeds the icons, secret-safe.
	if (f.key == "party" or f.key == "raid") and db
		and db.defensiveIcons ~= false then
		if not f.Defensives then
			f.Defensives = Auras.Create(f, "HELPFUL|EXTERNAL_DEFENSIVE", 12, 3)
			if f.Defensives then
				Auras.Layout(f, f.Defensives, "BOTTOMLEFT", "TOPLEFT", 1, -1)
			end
		end
	end

	-- dispel border on group frames (readable path - silently degrades
	-- to no border when the client's aura data is secret)
	if f.DispelBorder or f.key == "party" or f.key == "raid" then
		if not f.DispelBorder then
			-- rounded-aware edge strips instead of a square backdrop edge
			f.DispelBorder = ns.EdgeGlow(f, 2)
		end
		local dt = Auras.DispelType(unit)
		local col = dt and (DISPEL_COLORS[dt] or DISPEL_COLORS[""])
		if col then
			f.DispelBorder:SetEdgeColor(col[1], col[2], col[3], 0.95)
			f.DispelBorder:Show()
		else
			f.DispelBorder:Hide()
		end
	end

	for _, h in ipairs({ f.Buffs, f.Debuffs, f.Defensives }) do
		if h then
			-- SetUnit only when it changed; a refused call retries on the
			-- next update instead of aborting Refresh
			if h.unit ~= unit then
				if pcall(h.SetUnit, h, unit) then h.unit = unit end
			end
			h:Show()
		end
	end
end
