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

local frame, titleText, bodyText, counter, backBtn, nextBtn, stepHost, finishBtn
local stepIndex = 1
local stepFrames = {} -- lazily built content frame per step

Inst.steps = {}

--- Append a step { title = "...", text = "..." | function() return "..." end,
--- build = function(host) return frame end }.
function Inst.AddStep(step)
	Inst.steps[#Inst.steps + 1] = step
end

--- Append a module-provided step; it is placed before the final "Done"
--- step, so module content never shows after the finish page.
function Inst.AddModuleStep(step)
	if type(step) ~= "table" then return end
	local at = #Inst.steps
	for i = 1, #Inst.steps do
		if Inst.steps[i].last then at = i - 1 break end
	end
	table.insert(Inst.steps, at + 1, step)
end

local function markDone()
	S.DB.General().installDone = true
end

local function stepText(i)
	local t = Inst.steps[i].text
	return type(t) == "function" and t() or t
end

-- the visible secure Finish button, built the proven DaylightUI way:
-- parented to UIParent (never inside a window whose scripts could touch
-- the dispatch), laid over the Next button on show, both click phases
-- plus useOnKeyDown=false - without that attribute the dispatch follows
-- the key-down CVar and ignores the Up click, so the macro never fired.
-- Textures and strings are not scripts - a SecureActionButton may carry
-- them safely.
local function buildFinish()
	if finishBtn or InCombatLockdown() then return end
	finishBtn = CreateFrame("Button", "SentiUIInstallerFinish", UIParent, "SecureActionButtonTemplate")
	finishBtn:SetSize(110, 26)
	finishBtn:RegisterForClicks("AnyDown", "AnyUp")
	pcall(finishBtn.SetAttribute, finishBtn, "type", "macro")
	pcall(finishBtn.SetAttribute, finishBtn, "type1", "macro")
	pcall(finishBtn.SetAttribute, finishBtn, "macrotext", "/reload")
	pcall(finishBtn.SetAttribute, finishBtn, "macrotext1", "/reload")
	pcall(finishBtn.SetAttribute, finishBtn, "useOnKeyDown", false)
	S.Template(finishBtn, "raised")
	S.SetBorderLit(finishBtn, true)
	local t = S.Font(finishBtn, 11, C.accent)
	t:SetAllPoints()
	t:SetJustifyH("CENTER")
	t:SetText(L["Finish & reload"])
	if finishBtn.SetHighlightTexture then
		pcall(finishBtn.SetHighlightTexture, finishBtn, "Interface\\Buttons\\WHITE8X8", "ADD")
		local hl = finishBtn.GetHighlightTexture and finishBtn:GetHighlightTexture()
		if hl then pcall(hl.SetVertexColor, hl, C.accent.r, C.accent.g, C.accent.b, 0.25) end
	end
	finishBtn:Hide()
end

local function showStep(i)
	local n = #Inst.steps
	stepIndex = math.max(1, math.min(i, n))
	local st = Inst.steps[stepIndex]
	titleText:SetText(L[st.title] or st.title or "")
	bodyText:SetText(stepText(stepIndex) or "")
	counter:SetText(stepIndex .. " / " .. n)
	backBtn:SetEnabled(stepIndex > 1)
	if stepIndex == n then
		-- the finish button may be missing when the frame was built during
		-- combat (secure attributes cannot be set there) - retry lazily
		if not finishBtn then buildFinish() end
		-- mark done when the finish step shows: the secure button carries
		-- no addon scripts, so there is no PostClick to save it later.
		-- Closing via X marks done the same way.
		markDone()
	end
	-- the last step swaps Next for the visible secure Finish button; if
	-- the secure build failed (combat) Next stays with its no-reload
	-- fallback click instead of a dead-looking button
	nextBtn:SetShown(stepIndex ~= n or not finishBtn)
	nextBtn:SetText((stepIndex == n and L["Finish & reload"] or L["Next"]) or "")
	if finishBtn then
		finishBtn:SetShown(stepIndex == n)
		if stepIndex == n then
			-- laid over Next, one level up - the DaylightUI placement
			finishBtn:ClearAllPoints()
			finishBtn:SetAllPoints(nextBtn)
			finishBtn:SetFrameStrata("DIALOG")
			finishBtn:SetFrameLevel((nextBtn:GetFrameLevel() or 1) + 5)
		end
	end

	-- per-step interactive content
	for _, f in pairs(stepFrames) do if f then f:Hide() end end
	local f = stepFrames[stepIndex]
	if f == nil and type(st.build) == "function" and stepHost then
		local ok, built = pcall(st.build, stepHost)
		if not ok then
			-- a swallowed build error shows as a mysteriously empty step
			print("|cffebad33SentiUI|r installer step '" .. tostring(st.title) .. "' failed: " .. tostring(built))
			f = nil
		elseif built then
			f = built
		else
			-- a nil build (module not ready) is not cached: the next visit
			-- retries instead of leaving the step empty forever
			print("|cffebad33SentiUI|r installer step '" .. tostring(st.title) .. "' is not ready yet - it builds on the next visit.")
			f = nil
		end
		stepFrames[stepIndex] = f
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
	-- inset past the corner arc so the line ends on the straight edge
	edge:SetPoint("TOPLEFT", 7, 0)
	edge:SetPoint("TOPRIGHT", -7, 0)

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

	-- Next first, Back anchored to ITS left: the pair can never overlap,
	-- no matter how wide the localized labels get ("Fertig & neu laden")
	nextBtn = W.Button(frame, L["Next"], 140, 26)
	nextBtn:SetPoint("BOTTOMRIGHT", -16, 16)
	nextBtn:SetScript("OnClick", function()
		if stepIndex < #Inst.steps then
			showStep(stepIndex + 1)
		else
			-- the visible secure Finish button normally takes this click
			-- and runs /reload; reaching this means it could not be built
			-- (combat) - finish without the reload instead of a blocked call
			markDone()
			frame:Hide()
		end
	end)
	backBtn = W.Button(frame, L["Back"], 90, 26)
	backBtn:SetPoint("RIGHT", nextBtn, "LEFT", -8, 0)
	backBtn:SetScript("OnClick", function() showStep(stepIndex - 1) end)
	-- C_UI.Reload is a protected call on this client: the finish step shows
	-- a real secure macro button instead (built lazily, see buildFinish).
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
	-- shared with the settings' Interface page (S.ApplyGameScale)
	S.ApplyGameScale(v)
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
		-- persist the untouched current scale too: the slider only fires
		-- on real changes, and the client keeps neither the CVar nor an
		-- untouched choice across relogs
		S.DB.General().gameScale = cur

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
	build = function(host)
		local f = CreateFrame("Frame", nil, host)
		f:SetAllPoints()
		local b1 = W.Button(f, L["Unlock move mode"], 180, 24)
		b1:SetPoint("TOPLEFT", 0, -2)
		b1:SetScript("OnClick", function()
			if S.Movers and S.Movers.Toggle then S.Movers.Toggle() end
		end)
		local b2 = W.Button(f, L["Open settings"], 140, 24)
		b2:SetPoint("LEFT", b1, "RIGHT", 12, 0)
		b2:SetScript("OnClick", function()
			if S.OptionsPanel and S.OptionsPanel.Toggle then S.OptionsPanel.Toggle() end
		end)
		return f
	end,
}
Inst.AddStep {
	title = "Modules",
	text = L["INSTALLER_MODULES_HEADER"],
	build = function(host)
		local f = CreateFrame("Frame", nil, host)
		f:SetAllPoints()
		local scroll, child = W.Scroll(f)
		scroll:SetPoint("TOPLEFT", 0, 0)
		scroll:SetPoint("BOTTOMRIGHT", -6, 0)
		child:SetWidth(496)
		local list = {}
		for name, mod in S.Modules() do list[#list + 1] = { name = name, mod = mod } end
		table.sort(list, function(a, b)
			return (a.mod.label or a.name) < (b.mod.label or b.name)
		end)
		local y = -2
		for _, e in ipairs(list) do
			local row = CreateFrame("Button", nil, child)
			row:SetHeight(20)
			row:SetPoint("TOPLEFT", 0, y)
			row:SetPoint("TOPRIGHT", 0, y)
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints()
			row.hl:SetTexture("Interface\\Buttons\\WHITE8X8")
			row.hl:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.12)
			local cb = W.Check(row)
			cb:SetPoint("LEFT", 2, 0)
			cb:SetChecked(S:Get(e.name, "enabled") ~= false)
			local lab = S.Font(row, 11)
			lab:SetPoint("LEFT", cb, "RIGHT", 6, 0)
			lab:SetText(e.mod.label or e.name)
			-- the write lands in the module db; the finish reload applies it
			cb.onChanged = function(v) S:Set(e.name, "enabled", v) end
			row:SetScript("OnClick", function() cb:Click() end)
			y = y - 20
		end
		child:SetHeight(-y + 2)
		return f
	end,
}
Inst.AddStep {
	title = "Done",
	text = L["INSTALLER_DONE"],
	last = true,
}

-- First-run popup, a moment after login and never during combat.
S.RegisterEvent("PLAYER_LOGIN", function()
	-- re-apply the game UI scale chosen in the installer: the client
	-- does not persist uiScale in config-cache.wtf
	local gs = S.DB.General().gameScale
	if type(gs) == "number" then
		C_Timer.After(0.5, function() applyUIScale(gs) end)
	end
	if S.DB.General().installDone then return end
	C_Timer.After(1.5, function()
		if not InCombatLockdown() then
			Inst.Show()
		end
	end)
end)
