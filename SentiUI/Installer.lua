-- SentiUI installer: a small step wizard for first-run setup.
-- Steps are plain entries { title, text } — `text` may be a string or a
-- function evaluated when the step shows. Modules may append steps with
-- SentiUI.Installer.AddStep { ... } from their own files.
local _, S = ...
local L = S.L
local C = S.colors
local W = S.Widgets

local Inst = {}
S.Installer = Inst

local frame, titleText, bodyText, counter, backBtn, nextBtn
local stepIndex = 1

Inst.steps = {}

--- Append a step { title = "...", text = "..." | function() return "..." end }.
function Inst.AddStep(step)
	Inst.steps[#Inst.steps + 1] = step
end

local function markDone()
	S.DB.General().installDone = true
end

local function stepText(i)
	local t = Inst.steps[i].text
	return type(t) == "function" and t() or t
end

local function showStep(i)
	local n = #Inst.steps
	stepIndex = math.max(1, math.min(i, n))
	local st = Inst.steps[stepIndex]
	titleText:SetText(L[st.title] or st.title or "")
	bodyText:SetText(stepText(stepIndex) or "")
	counter:SetText(stepIndex .. " / " .. n)
	backBtn:SetEnabled(stepIndex > 1)
	nextBtn:SetText((stepIndex == n and L["Finish"] or L["Next"]) or "")
end

local function build()
	local C_ = C
	frame = CreateFrame("Frame", "SentiUIInstaller", UIParent, "BackdropTemplate")
	frame:SetSize(560, 330)
	S.Template(frame, "panel")
	frame:SetPoint("CENTER", 0, 80)
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:Hide()
	S.EscClosable(frame)

	local edge = S.Line(frame, C_.accent, 2)
	edge:SetPoint("TOPLEFT", 0, 0)
	edge:SetPoint("TOPRIGHT", 0, 0)

	local close = W.Button(frame, "x", 24, 24)
	close:SetPoint("TOPRIGHT", -10, -10)
	close:SetScript("OnClick", function() markDone(); frame:Hide() end)

	local logo = frame:CreateTexture(nil, "ARTWORK")
	logo:SetSize(44, 44)
	logo:SetPoint("TOPLEFT", 16, -16)
	logo:SetTexture(S.media.logo)

	titleText = S.Font(frame, 16, C_.accent)
	titleText:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -4)

	counter = S.Font(frame, 10, C_.textDim)
	counter:SetPoint("RIGHT", close, "LEFT", -10, 0)

	bodyText = S.Font(frame, 12)
	bodyText:SetPoint("TOPLEFT", 20, -76)
	bodyText:SetWidth(520)
	bodyText:SetJustifyH("LEFT")
	bodyText:SetJustifyV("TOP")
	bodyText:SetSpacing(4)

	backBtn = W.Button(frame, L["Back"], 90, 26)
	backBtn:SetPoint("BOTTOMRIGHT", -120, 16)
	backBtn:SetScript("OnClick", function() showStep(stepIndex - 1) end)

	nextBtn = W.Button(frame, L["Next"], 110, 26)
	nextBtn:SetPoint("BOTTOMRIGHT", -16, 16)
	nextBtn:SetScript("OnClick", function()
		if stepIndex < #Inst.steps then
			showStep(stepIndex + 1)
		else
			markDone()
			frame:Hide()
		end
	end)
end

function Inst.Show()
	if not frame then build() end
	if #Inst.steps == 0 then return end
	showStep(1)
	frame:Show()
end

-- Built-in steps. Modules can append more from their files.
Inst.AddStep {
	title = "Welcome to SentiUI",
	text = function() return string.format(L["INSTALLER_WELCOME"], S.version) end,
}
Inst.AddStep {
	title = "Your controls",
	text = L["INSTALLER_CONTROLS"],
}
Inst.AddStep {
	title = "Modules",
	text = function()
		local names = {}
		for name, mod in S.Modules() do
			names[#names + 1] = mod.label or name
		end
		if #names == 0 then
			return L["INSTALLER_MODULES_NONE"]
		end
		return string.format(L["INSTALLER_MODULES_LIST"], table.concat(names, ", "))
	end,
}
Inst.AddStep {
	title = "Done",
	text = L["INSTALLER_DONE"],
}

-- First-run popup, a moment after login and never during combat.
S.RegisterEvent("PLAYER_LOGIN", function()
	if S.DB.General().installDone then return end
	C_Timer.After(1.5, function()
		if not InCombatLockdown() then
			Inst.Show()
		end
	end)
end)
