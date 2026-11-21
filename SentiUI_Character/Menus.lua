-- Small popup menu used by slot clicks (equip/link/dress up) and the
-- equipment-set picker in the footer.
local _, ns = ...
local S = SentiUI
local C = S.colors

ns.Menu = {}
local M = ns.Menu

local menu, catcher

local function Ensure()
	if menu then return end
	menu = CreateFrame("Frame", "SentiUICharMenu", UIParent)
	menu:SetFrameStrata("TOOLTIP")
	menu:SetWidth(170)
	S.Template(menu, "panel")
	menu:Hide()

	catcher = CreateFrame("Button", nil, UIParent)
	catcher:SetFrameStrata("FULLSCREEN_DIALOG")
	catcher:SetAllPoints(UIParent)
	catcher:EnableMouse(true)
	catcher:SetPropagateMouseClicks(true)
	catcher:RegisterForClicks("AnyUp", "AnyDown")
	catcher:SetScript("OnClick", M.Close)
	catcher:SetScript("OnHide", function() menu:Hide() end)
	catcher:Hide()
end

-- items: { {label=..., fn=..., disabled=bool, hint=str}, ... }
function M.Open(anchor, items)
	Ensure()
	menu.items = items
	for _, b in ipairs(menu.btns or {}) do b:Hide() end
	menu.btns = menu.btns or {}
	local y = -8
	for i, it in ipairs(items) do
		local b = menu.btns[i]
		if not b then
			b = CreateFrame("Button", nil, menu)
			b:SetHeight(20)
			b.label = S.Font(b, 11)
			b.label:SetPoint("LEFT", 10, 0)
			b.hi = b:CreateTexture(nil, "BACKGROUND")
			b.hi:SetAllPoints()
			b.hi:SetColorTexture(C.accent.r, C.accent.g, C.accent.b, 0.12)
			b.hi:Hide()
			b:SetScript("OnEnter", function() b.hi:Show() end)
			b:SetScript("OnLeave", function() b.hi:Hide() end)
			menu.btns[i] = b
		end
		b:SetPoint("TOPLEFT", 4, y)
		b:SetPoint("TOPRIGHT", -4, y)
		b.label:SetText(it.label)
		if it.disabled then
			b.label:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b)
			b:SetScript("OnClick", nil)
		else
			b.label:SetTextColor(1, 1, 1)
			b:SetScript("OnClick", function()
				M.Close()
				S.SafeCall("charmenu", it.fn)
			end)
		end
		b:Show()
		y = y - 20
	end
	menu:SetHeight(-y + 8)
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, -2)
	catcher:Show()
	menu:Show()
end

function M.Close()
	if menu then menu:Hide() end
	if catcher then catcher:Hide() end
end
