-- Unspent talent points: the game's micro-button alerts anchor to the
-- parked micro bar and float mid-screen, so the alert frames are
-- suppressed and the hint is re-shown in SentiUI style - a small lit
-- pill above the bottom bars that opens the talent frame on click.
local _, ns = ...
local S = SentiUI
local L = ns.L
local SetFont = ns.SetFont

local CreateFrame, InCombatLockdown = CreateFrame, InCombatLockdown
local format = string.format

-- every *MicroButtonAlert the parked micro buttons can spawn - they all
-- anchor where the button used to be, so each gets a re-hide hook
local ALERT_FRAMES = { "TalentMicroButtonAlert", "CollectionsMicroButtonAlert",
	"LFDMicroButtonAlert", "EJMicroButtonAlert", "HelpMicroButtonAlert",
	"MainMenuMicroButtonAlert" }

local pill
local alertSeen -- the game's talent alert fired: show the pill even
-- when no points API can confirm the count

local function UnspentPoints()
	if type(UnitCharacterPoints) == "function" then
		local ok, n = pcall(UnitCharacterPoints, "player")
		if ok and type(n) == "number" then return n end
	end
	if C_ClassTalents and C_ClassTalents.GetUnspentTalentPoints then
		local ok, n = pcall(C_ClassTalents.GetUnspentTalentPoints)
		if ok and type(n) == "number" then return n end
	end
end

local function OpenTalents()
	if PlayerSpellsUtil and PlayerSpellsUtil.ToggleClassTalentFrame then
		if pcall(PlayerSpellsUtil.ToggleClassTalentFrame) then return end
	end
	if type(ToggleTalentFrame) == "function" and pcall(ToggleTalentFrame) then
		return
	end
	for _, b in ipairs({ _G.TalentMicroButton, _G.PlayerSpellsMicroButton }) do
		if type(b) == "table" and type(b.Click) == "function"
			and pcall(b.Click, b, "LeftButton") then
			return
		end
	end
end

local function EnsurePill()
	if pill then return pill end
	pill = CreateFrame("Button", "SentiUIABTalentPill", UIParent, "SecureActionButtonTemplate")
	pill:RegisterForClicks("LeftButtonUp")
	pill:SetSize(210, 26)
	pill:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 152)
	pill:SetFrameStrata("MEDIUM")
	S.Template(pill, "panel")
	S.SetBorderLit(pill, true) -- gold edge: this is an attention element
	local ic = pill:CreateTexture(nil, "ARTWORK")
	ic:SetSize(18, 18)
	ic:SetPoint("LEFT", 7, 0)
	ic:SetTexture("Interface\\Buttons\\UI-MicroButton-Talents-Up")
	ic:SetTexCoord(0.25, 0.75, 0.18, 0.82) -- trim the button chrome off the icon
	pill.text = pill:CreateFontString(nil, "OVERLAY")
	pill.text:SetPoint("LEFT", ic, "RIGHT", 6, 0)
	pill.text:SetPoint("RIGHT", pill, "RIGHT", -6, 0)
	pill.text:SetJustifyH("LEFT")
	pill.text:SetTextColor(S.colors.text.r, S.colors.text.g, S.colors.text.b)
	SetFont(pill.text, 11)
	pill:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Unspent talent points"], 1, 1, 1)
		GameTooltip:AddLine(L["Click: open talents"], 0.7, 0.7, 0.7)
		GameTooltip:Show()
	end)
	pill:SetScript("OnLeave", function() GameTooltip:Hide() end)
	-- secure click-through to the real micro button: ToggleTalentFrame from
	-- addon code writes the client's window bookkeeping tainted, the same
	-- trap as the bag functions - a /click macro runs the button's own
	-- handler in secure context instead
	local target = _G.TalentMicroButton or _G.PlayerSpellsMicroButton
	if type(target) == "table" and type(target.GetName) == "function" then
		pill:SetAttribute("type1", "macro")
		pill:SetAttribute("macrotext1", "/click " .. target:GetName())
		if SecureActionButton_OnClick then
			pill:SetScript("OnClick", SecureActionButton_OnClick)
		end
	else
		pill:SetScript("OnClick", function()
			if InCombatLockdown() then return end
			OpenTalents()
		end)
	end
	pill:Hide()
	return pill
end

local function UpdatePill()
	local n = UnspentPoints()
	local show = (n and n > 0) or (n == nil and alertSeen)
	if not show then
		if pill then pill:Hide() end
		return
	end
	EnsurePill()
	if n then
		pill.text:SetText(format(L["Unspent talent points: %d"], n))
	else
		pill.text:SetText(L["Unspent talent points"])
	end
	pill:Show()
end

-- WatchShown, not OnShow: an insecure script on a client alert frame runs
-- inside the alert's show dispatch and taints the client's follow-up work.
-- The resolver form keeps polling until the load-on-demand frame exists.
local function HookAlert(name, isTalent)
	S.WatchShown(function() return _G[name] end, function(f)
		f:Hide()
		if isTalent then
			alertSeen = true
			UpdatePill()
		end
	end)
	return true
end

local alertsWired
local function HookAlerts()
	if alertsWired then return true end -- PLAYER_ENTERING_WORLD re-fires
	alertsWired = true
	for i, name in ipairs(ALERT_FRAMES) do
		HookAlert(name, i == 1)
	end
	return true
end

ns.TalentAlert = {}
S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
	HookAlerts()
	UpdatePill()
end)
for _, ev in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE",
	"TRAIT_CONFIG_UPDATED", "SPELLS_CHANGED",
	"ACTIVE_PLAYER_SPECIALIZATION_CHANGED" }) do
	S.RegisterEvent(ev, function()
		-- the game re-evaluates its own alert here; drop our fallback
		-- flag and let it re-fire if points are still unspent
		alertSeen = nil
		UpdatePill()
	end)
end
S.RegisterEvent("PLAYER_LEVEL_UP", function()
	C_Timer.After(0.5, UpdatePill)
end)
