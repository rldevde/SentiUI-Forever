-- The SentiUI minimap button: draggable around the minimap edge, left click
-- opens the settings, right click toggles move mode.
local _, S = ...
local L = S.L

local MB = {}
S.MinimapButton = MB

function MB.Position(btn)
	btn = btn or _G.SentiUIMinimapButton
	if not btn then return end
	local angle = math.rad((S.DB.General().minimap and S.DB.General().minimap.angle) or 220)
	local r = Minimap:GetWidth() / 2
	btn:ClearAllPoints()
	btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * (r + 5), math.sin(angle) * (r + 5))
end

local function create()
	local store = S.DB.General().minimap
	local btn = CreateFrame("Button", "SentiUIMinimapButton", Minimap)
	btn:SetSize(31, 31)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(8)
	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local overlay = btn:CreateTexture(nil, "OVERLAY")
	overlay:SetSize(53, 53)
	overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	overlay:SetPoint("TOPLEFT")

	local background = btn:CreateTexture(nil, "BACKGROUND")
	background:SetSize(20, 20)
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetPoint("TOPLEFT", 7, -5)

	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(S.media.logo)
	icon:SetSize(17, 17)
	icon:SetPoint("TOPLEFT", 7, -6)

	btn:RegisterForClicks("AnyUp")
	btn:RegisterForDrag("LeftButton")
	btn:SetScript("OnDragStart", function(b)
		b:SetScript("OnUpdate", function()
			b.dragged = true
			local mx, my = Minimap:GetCenter()
			local scale = Minimap:GetEffectiveScale()
			local cx, cy = GetCursorPosition()
			cx, cy = cx / scale - mx, cy / scale - my
			store.angle = math.deg(math.atan(cy, cx))
			MB.Position(b)
		end)
	end)
	btn:SetScript("OnDragStop", function(b)
		b:SetScript("OnUpdate", nil)
		C_Timer.After(0, function() b.dragged = nil end)
	end)
	btn:SetScript("OnClick", function(b, button)
		if b.dragged then return end
		if button == "RightButton" then
			S.Movers.Toggle()
		else
			S.OptionsPanel.Toggle()
		end
	end)
	btn:SetScript("OnEnter", function(b)
		GameTooltip:SetOwner(b, "ANCHOR_LEFT")
		GameTooltip:AddLine("|cffebad33SentiUI|r")
		GameTooltip:AddLine(L["Left-click: settings - right-click: move frames - drag: move button"], 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	return btn
end

-- Shows or removes the button to match general.minimap.hide.
function MB.Sync()
	if not S.DB.General then return end
	local store = S.DB.General().minimap
	if not store then return end
	local btn = _G.SentiUIMinimapButton
	if store.hide then
		if btn then btn:Hide() end
		return
	end
	btn = btn or create()
	MB.Position(btn)
	btn:Show()
end
