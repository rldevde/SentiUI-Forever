local _, ns = ...
local S = ns.Outfitter
local L = S.L
local GOLD, BLUE, WHITE = S.GOLD, S.BLUE, S.WHITE

local LOGO = "Interface\\AddOns\\SentiUI_Outfitter\\Media\\Logo.tga"
S.LOGO = LOGO

local btn

local function Radius()
	local w = Minimap and Minimap:GetWidth() or 140
	return w / 2 + 10
end

local function UpdatePos()
	if not btn then return end
	local a = math.rad(S.db.minimap.angle or -35)
	btn:ClearAllPoints()
	btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * Radius(), math.sin(a) * Radius())
end

local function CursorAngle()
	local cx, cy = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	px, py = px / scale, py / scale
	return math.deg(math.atan(py - cy, px - cx))
end

function S:InitMinimap()
	if btn or not Minimap then return end

	btn = CreateFrame("Button", "SentiUI_OutfitterMinimapButton", Minimap)
	btn:SetSize(31, 31)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(8)
	btn:SetMovable(true)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:RegisterForDrag("LeftButton")

	-- round logo icon, slightly zoomed so the emblem fills the circle
	btn.icon = btn:CreateTexture(nil, "BACKGROUND")
	btn.icon:SetPoint("TOPLEFT", 5, -5)
	btn.icon:SetPoint("BOTTOMRIGHT", -5, 5)
	btn.icon:SetTexture(LOGO)
	btn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

	-- circular border ring (gold)
	btn.ring = btn:CreateTexture(nil, "OVERLAY")
	btn.ring:SetAllPoints()
	btn.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	btn.hl = btn:CreateTexture(nil, "HIGHLIGHT")
	btn.hl:SetPoint("TOPLEFT", 5, -5)
	btn.hl:SetPoint("BOTTOMRIGHT", -5, 5)
	btn.hl:SetTexture(WHITE)
	btn.hl:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.25)

	local dragging = false
	btn:SetScript("OnDragStart", function(self)
		dragging = true
		self:SetScript("OnUpdate", function()
			S.db.minimap.angle = CursorAngle()
			UpdatePos()
		end)
	end)
	btn:SetScript("OnDragStop", function(self)
		dragging = false
		self:SetScript("OnUpdate", nil)
	end)

	btn:SetScript("OnClick", function(self, b)
		if b == "RightButton" then
			S:ToggleOptions()
		else
			S:ToggleUI()
		end
	end)
	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetText("SentiUI Outfitter", unpack(GOLD))
		GameTooltip:AddLine(L["Click to open the outfit window"], 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["Right-click for settings"], 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["Drag to move around the minimap"], 0.55, 0.55, 0.55)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	UpdatePos()
	btn:SetShown(not S.db.minimap.hide)
end

function S:ApplyMinimapVisibility()
	if btn then btn:SetShown(not S.db.minimap.hide) end
end
