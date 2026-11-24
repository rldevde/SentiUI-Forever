-- Window host for the compendium page: Sentinel chrome, draggable,
-- Escape-closable. All content is built by Page.lua (ns.JournalBuild).
local _, ns = ...
local S = SentiUI
local L = ns.L

local K = {}
ns.Journal = K
SentiUIJournal = K -- panel plugin entry point: SentiUIJournal.Toggle()

local frame, page

local function Create()
	local f = CreateFrame("Frame", "SentiUIJournalFrame", UIParent, "BackdropTemplate")
		S.PopIn(f)
	if S.CombatDeferWindow then S:CombatDeferWindow(f) end
	f:SetSize(1060, 620)
	S.Template(f, "panel")
	f:SetFrameStrata("DIALOG")
	f:SetPoint("CENTER")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	S.EscClosable(f)
	f:Hide()

	local title = S.Font(f, 13, S.colors.accent)
	title:SetPoint("TOP", 0, -10)
	title:SetText(L["Compendium"])

	local close = S.Widgets.Close(f, function() f:Hide() end)
	close:SetPoint("TOPRIGHT", -8, -8)

	local accent = f:CreateTexture(nil, "ARTWORK")
	accent:SetHeight(1)
	accent:SetPoint("TOPLEFT", 8, -28)
	accent:SetPoint("TOPRIGHT", -8, -28)
	accent:SetColorTexture(S.colors.accent.r, S.colors.accent.g, S.colors.accent.b, 0.5)

	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", 8, -34)
	content:SetPoint("BOTTOMRIGHT", -8, 8)

	page = ns.JournalBuild(content)
	f:SetScript("OnShow", function() page:OnShow() end)
	return f
end

function K.Close()
	if frame and frame:IsShown() then frame:Hide() end
end

function K.Toggle()
	frame = frame or Create()
	if frame:IsShown() then
		frame:Hide()
	else
		if SentiUITraining and SentiUITraining.Close then SentiUITraining.Close() end
		frame:Show()
	end
end

function K.Open()
	frame = frame or Create()
	if SentiUITraining and SentiUITraining.Close then SentiUITraining.Close() end
	frame:Show()
end
