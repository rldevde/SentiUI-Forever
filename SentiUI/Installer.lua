-- SentiUI installer: a small step wizard for first-run setup.
-- Steps are plain entries { title, text, build? } — `text` may be a string or
-- a function evaluated when the step shows; `build(host)` may return a frame
-- with interactive widgets shown inside the step's content area.
local _, S = ...
local L = S.L
local C = S.colors
local W = S.Widgets

local Inst = {}
S.Installer = Inst

local frame, titleText, bodyText, counter, backBtn, nextBtn, stepHost, reloadOverlay
local stepIndex = 1
local stepFrames = {} -- lazily built content frame per step

Inst.steps = {}

--- Append a step { title = "...", text = "..." | function() return "..." end,
--- build = function(host) return frame end }.
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
	nextBtn:SetText((stepIndex == n and L["Finish & reload"] or L["Next"]) or "")
	if reloadOverlay then reloadOverlay:SetShown(stepIndex == n) end

	-- per-step interactive content
	for _, f in pairs(stepFrames) do if f then f:Hide() end end
	local f = stepFrames[stepIndex]
	if f == nil and type(st.build) == "function" and stepHost then
		local ok, built = pcall(st.build, stepHost)
		f = ok and built or nil
		stepFrames[stepIndex] = f or false
	end
	if f then f:Show() end
end

local function build()
	local C_ = C
	frame = CreateFrame("Frame", "SentiUIInstaller", UIParent, "BackdropTemplate")
	frame:SetSize(560, 380)
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

	-- interactive area below the text; steps build into it on demand
	stepHost = CreateFrame("Frame", nil, frame)
	stepHost:SetPoint("TOPLEFT", 20, -196)
	stepHost:SetSize(520, 120)

	backBtn = W.Button(frame, L["Back"], 90, 26)
	backBtn:SetPoint("BOTTOMRIGHT", -120, 16)
	backBtn:SetScript("OnClick", function() showStep(stepIndex - 1) end)

	nextBtn = W.Button(frame, L["Next"], 110, 26)
	nextBtn:SetPoint("BOTTOMRIGHT", -16, 16)
	nextBtn:SetScript("OnClick", function()
		if stepIndex < #Inst.steps then
			showStep(stepIndex + 1)
		else
			-- the secure overlay normally eats this click and runs /reload;
			-- reaching this means it could not be built (combat) - finish
			-- without the reload instead of a blocked call
			markDone()
			frame:Hide()
		end
	end)
	-- C_UI.Reload is a protected call on this client: the real reload runs
	-- through a secure macro overlay, visible only on the last step
	reloadOverlay = S.SecureReload(nextBtn, function()
		markDone()
		frame:Hide()
	end)
	if reloadOverlay then reloadOverlay:Hide() end
end

function Inst.Show()
	if not frame then build() end
	if #Inst.steps == 0 then return end
	showStep(1)
	frame:Show()
end

-- interface scale step ---------------------------------------------------------
local function recommendedScale()
	local h = GetScreenHeight and GetScreenHeight() or 0
	if type(h) ~= "number" or h <= 0 then h = 1080 end
	local v = 768 / h
	v = math.floor(v / 0.05 + 0.5) * 0.05
	return math.max(0.5, math.min(1.2, v))
end

local function currentUIScale()
	local v = C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("uiScale")
	return tonumber(v) or 1
end

local function applyUIScale(v)
	if not (C_CVar and C_CVar.SetCVar) then return end
	pcall(C_CVar.SetCVar, "useUiScale", "1")
	pcall(C_CVar.SetCVar, "uiScale", string.format("%.2f", v))
end

-- Built-in steps. Modules can append more from their files.
Inst.AddStep {
	title = "Welcome to SentiUI",
	text = function() return string.format(L["INSTALLER_WELCOME"], S.version) end,
}
Inst.AddStep {
	title = "Interface scale",
	text = L["INSTALLER_SCALE_TEXT"],
	build = function(host)
		local f = CreateFrame("Frame", nil, host)
		f:SetAllPoints()

		local lab = S.Font(f, 11, C.textDim)
		lab:SetPoint("TOPLEFT", 0, -4)
		lab:SetText(L["Game UI scale"])

		local val = S.Font(f, 11, C.accent)
		val:SetPoint("LEFT", lab, "RIGHT", 10, 0)

		local sl = W.Slider(f, 0.5, 1.5, 0.05)
		sl:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 0, -10)
		sl:SetWidth(280)

		local rec = W.Button(f, L["Recommended"], 110, 22)
		rec:SetPoint("LEFT", sl, "RIGHT", 16, 0)
		rec:SetScript("OnClick", function() sl:SetValue(recommendedScale()) end)

		sl.onChanged = function(v)
			val:SetText(string.format("%.2fx", v))
			applyUIScale(v)
		end
		local cur = currentUIScale()
		sl:SetValue(cur, true)
		val:SetText(string.format("%.2fx", cur))

		local note = S.Font(f, 10, C.textDim)
		note:SetPoint("TOPLEFT", sl, "BOTTOMLEFT", 0, -16)
		note:SetWidth(500)
		note:SetJustifyH("LEFT")
		note:SetText(L["INSTALLER_SCALE_NOTE"])
		return f
	end,
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
