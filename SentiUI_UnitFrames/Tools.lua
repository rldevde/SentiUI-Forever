-- Raid tools: a slim tab docked to the top screen edge that unfolds a
-- marker tray while grouped. The tab stays visible and clickable; the
-- tray below holds target markers, world markers, ready check and a pull
-- countdown. Marker buttons are secure (/tm, /wm macros) so they work
-- without protected calls; folding only touches the plain tray frame,
-- which is allowed in combat.
local _, ns = ...
local S = SentiUI
local L = ns.L

local ipairs = ipairs
local CreateFrame = CreateFrame

local T = {}
ns.RaidTools = T

local tab, body
local SIZE, GAP = 22, 4
local COLS = 8

local MARKER_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_%d"

local function Tip(b, title, desc)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(title, 1, 1, 1)
		if desc then GameTooltip:AddLine(desc, 0.7, 0.7, 0.7) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- markers run through the client's own slash commands (/tm, /wm): they
-- execute in the secure macro path, so no protected calls from addon code
local function SecureMark(parent, slash, index)
	local b = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
	b:SetSize(SIZE, SIZE)
	b:RegisterForClicks("AnyUp", "AnyDown")
	b:SetAttribute("type", "macro")
	b:SetAttribute("type1", "macro")
	b:SetAttribute("macrotext", slash .. " " .. index)
	b:SetAttribute("macrotext1", slash .. " " .. index)
	local t = b:CreateTexture(nil, "ARTWORK")
	t:SetPoint("TOPLEFT", 1, -1)
	t:SetPoint("BOTTOMRIGHT", -1, 1)
	t:SetTexture(MARKER_ICON:format(index))
	t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	b.icon = t
	if S.IconRound then S.IconRound(b, 3) end
	return b
end

local function TextButton(parent, w, text, secure)
	local b
	if secure then
		b = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
	else
		b = CreateFrame("Button", nil, parent)
	end
	b:SetSize(w, SIZE)
	b:RegisterForClicks("LeftButtonUp")
	S.Template(b, "raised")
	local fs = ns.Font(b, 10)
	fs:SetAllPoints()
	fs:SetJustifyH("CENTER")
	fs:SetText(text)
	b.label = fs
	return b
end

local function DoPull()
	if C_PartyInfo and C_PartyInfo.DoCountdown then
		if pcall(C_PartyInfo.DoCountdown, 10) then return end
	end
	if PullCountdown then pcall(PullCountdown, 10) end
end

-- fold/unfold the tray: body is a plain frame, so this works in combat
function T.ApplyFold()
	if not body then return end
	local db = ns.db.raidTools or {}
	local folded = db.collapsed == true
	body:SetShown(not folded)
	if tab.sign then tab.sign:SetText(folded and "+" or "-") end
end

local function ToggleFold()
	local db = ns.db.raidTools
	if not db then return end
	db.collapsed = not db.collapsed
	T.ApplyFold()
end

function T.Initialize()
	local db = ns.db.raidTools
	if not db or db.enable == false then return end

	-- the dock tab: slim strip pinned to the top edge, mover target
	local bodyW = 6 + COLS * (SIZE + GAP) - GAP + 6
	tab = CreateFrame("Button", "SentiUI_UF_RaidTools", UIParent,
		"SecureHandlerStateTemplate")
	tab:SetFrameStrata("MEDIUM")
	tab:SetSize(bodyW, 16)
	S.Template(tab, "raised")
	tab:RegisterForClicks("LeftButtonUp")
	tab:SetScript("OnClick", ToggleFold)
	Tip(tab, L["Raid tools"], L["Click to fold the marker tray."])

	local dim = S.colors and S.colors.textDim
	local fs = ns.Font(tab, 10, dim)
	fs:SetPoint("LEFT", 8, 0)
	fs:SetText(L["Raid tools"])
	local sign = ns.Font(tab, 11, dim)
	sign:SetPoint("RIGHT", -7, 0)
	tab.sign = sign

	-- the fold-out tray: plain frame so folding is legal in combat
	body = CreateFrame("Frame", nil, tab)
	body:SetPoint("TOP", tab, "BOTTOM", 0, -2)
	body:SetSize(bodyW, 6 + 3 * (SIZE + GAP) - GAP + 6)
	S.Template(body, "panel")
	body:SetFrameLevel(tab:GetFrameLevel())

	local i = 0
	local function Place(b)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", body, "TOPLEFT", 6 + (i % COLS) * (SIZE + GAP),
			-6 - math.floor(i / COLS) * (SIZE + GAP))
		i = i + 1
	end
	body.marks = {}
	for n = 1, 8 do
		local b = SecureMark(body, "/tm", n)
		Tip(b, L["Target marker"] .. " " .. n)
		Place(b)
		body.marks[n] = b
	end
	body.worlds = {}
	for n = 1, 8 do
		local b = SecureMark(body, "/wm", n)
		Tip(b, L["World marker"] .. " " .. n)
		Place(b)
		body.worlds[n] = b
	end

	local rc = TextButton(body, 56, "RC", true)
	rc:SetAttribute("type1", "macro")
	rc:SetAttribute("macrotext1", "/readycheck")
	Tip(rc, L["Ready check"])
	rc:ClearAllPoints()
	rc:SetPoint("TOPLEFT", body, "TOPLEFT", 6, -6 - 2 * (SIZE + GAP))
	body.rc = rc

	local pull = TextButton(body, 56, "Pull") -- plain: countdown is unprotected
	Tip(pull, L["Pull timer"], L["Starts a 10 second countdown."])
	pull:SetScript("OnClick", DoPull)
	pull:ClearAllPoints()
	pull:SetPoint("LEFT", rc, "RIGHT", GAP, 0)
	body.pull = pull

	-- the tab's own anchor becomes the mover's reset/default point
	tab:SetPoint("TOP", UIParent, "TOP", 0, -4)
	S.Movers.Register(tab, "uf.raidtools", L["Raid tools"], { x = 0, y = 0 })
	RegisterStateDriver(tab, "visibility", "[petbattle][group] show; hide")
	T.ApplyFold()
	T.tab, T.body = tab, body
end
