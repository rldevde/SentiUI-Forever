-- The Sentinel minimap for SentiUI, built the proven SentinelForeverCore way
-- for this client:
--   * a dark panel wraps the client's own Minimap in place - NO reparenting:
--     SetParent on Minimap is protected-ish here, so the panel is the mover
--     and the map is merely anchored inside it
--   * MinimapCluster is NEVER hidden (hiding it takes the whole map)
--   * blizzard decorations are faded with SetAlpha(0) + EnableMouse(false),
--     never Hide()d, and a 1s ticker keeps them down - GameTimeFrame and
--     AddonCompartmentFrame keep coming back to life on this client
--   * zone bar above, coords bar below (burger menu left, performance icon
--     and "+" addon-button collection right), wheel zoom + zoom buttons,
--     pvp-colored zone text
local addonName, ns = ...
local S = SentiUI
local L = ns.L
local C = S.colors

local Core = {}
ns.Core = Core

local BLANK = "Interface\\Buttons\\WHITE8X8"
local RING = "Interface\\AddOns\\SentiUI_Minimap\\Media\\Ring.tga"
local CIRCLE = "Interface\\AddOns\\SentiUI_Minimap\\Media\\CircleMask.tga"
local SUN = "Interface\\AddOns\\SentiUI_Minimap\\Media\\Sun.tga"
local MOON = "Interface\\AddOns\\SentiUI_Minimap\\Media\\Moon.tga"

local mod        -- module def, mod.db filled at enable
local panel, deco, ring, halo, zoneBar, zoneText, coordsBar, coordsText, mailBtn
local menuBtn, menu, suiMenu, addonPop, addonTrigger
local zoomIn, zoomOut
local trackBtn, trackPop
local trackRows = {}
local corners = {}
local miniBorderTex
local moverSet
local built
local captured = {} -- collected addon minimap buttons, [name] = {btn, name}

-- Lets other addons ask which shape the map has (standard convention).
function GetMinimapShape()
	local db = mod and mod.db
	return (db and db.shape == "square") and "SQUARE" or "ROUND"
end

-- Fading ---------------------------------------------------------------------
-- On this client decorations are faded, not hidden: Hide() makes blizzard
-- scripts fight back, alpha + mouse-off sticks.
local function fade(f)
	if type(f) ~= "table" or f == Minimap then return end
	if f.SetAlpha then pcall(f.SetAlpha, f, 0) end
	if f.EnableMouse then pcall(f.EnableMouse, f, false) end
end

local function unfade(f)
	if type(f) ~= "table" then return end
	if f.SetAlpha then pcall(f.SetAlpha, f, 1) end
	if f.EnableMouse then pcall(f.EnableMouse, f, true) end
end

local function resolve(spec)
	if type(spec) == "table" then
		local f = _G[spec[1]]
		for i = 2, #spec do
			if type(f) ~= "table" then return nil end
			f = f[spec[i]]
		end
		return f
	end
	local obj = _G
	for part in spec:gmatch("[^%.]+") do obj = obj and obj[part] end
	return obj
end

-- Everything the Sentinel look removes, resolved freshly each pass - some of
-- these frames are created late or wake up again, so never cache them.
local DECOR_NAMES = {
	"Minimap.backdrop",                               -- the map's round disc
	"MinimapCluster.DielFrame",                       -- the day/night dial
	"MinimapCompassTextureUnderlay",
}

-- Interactive chrome is killed the ElvUI way: reparent into a hidden
-- trash frame. The client hover-shows these over the map (zone text
-- button, zoom buttons, calendar, addon compartment) - fighting that
-- with Hide() is a show/hide war that flaps tooltips like crazy.
-- Inside a hidden parent their Show() lands nowhere: no flicker, no
-- tooltip, no fight.
local KILL_NAMES = {
	"MinimapCluster.ZoneTextButton", "MinimapZoneTextButton",
	"MinimapToggleButton",
	"Minimap.ZoomIn", "Minimap.ZoomOut", "Minimap.ZoomHitArea",
	"MinimapZoomIn", "MinimapZoomOut",
	"GameTimeFrame", "TimeManagerClockButton", "AddonCompartmentFrame",
	"MiniMapWorldMapButton", "MiniMapVoiceChatFrame",
	"MinimapCluster.IndicatorFrame.CraftingOrderFrame",
	"MinimapBackdrop.ExternalEventURLButton",
}

-- Some chrome survives alpha-fading because blizzard scripts SetAlpha(1)
-- again; for those the OnShow-hook route is the reliable kill: Hide() plus
-- a hook that re-hides every time a script pulls it back up.
local STRANGLE_NAMES = {
	"MinimapCompassTexture", "Minimap.CompassTexture", "MinimapBackdrop",
	"MinimapCluster.BorderTop",
	"MinimapBorderTop", "MinimapBorder", "MinimapNorthTag",
	"Minimap.NorthTag",
	"MinimapCluster.MinimapContainer.PlayerCoords",   -- blizzard's own coords
	"MiniMapMailBorder", "MiniMapTrackingBorder", "MiniMapTrackingBackground",
	"MiniMapTrackingButtonBorder", "MiniMapBattlefieldBorder",
	"BattlegroundShine", "LFGIconBorder",
}
local strangled = {}

local function strangle(f)
	if type(f) ~= "table" or f == Minimap then return end
	if f.SetAlpha then pcall(f.SetAlpha, f, 0) end
	if f.EnableMouse then pcall(f.EnableMouse, f, false) end
	if not strangled[f] and f.Hide then
		strangled[f] = true
		pcall(f.Hide, f)
		-- WatchShown, not OnShow: an insecure script on a client frame runs
		-- inside its show dispatch and taints whatever the client does next
		-- there. The alpha is already 0, so a frame-late re-hide is invisible.
		S.WatchShown(f, function(fr)
			pcall(fr.SetAlpha, fr, 0)
			pcall(fr.Hide, fr)
		end)
	elseif f.Hide then
		pcall(f.Hide, f)
	end
end

local trash
local function kill(f)
	if type(f) ~= "table" or f == Minimap then return end
	if not trash then
		trash = CreateFrame("Frame", "SentiUIMinimapTrash", UIParent)
		trash:Hide()
	end
	if f.EnableMouse then pcall(f.EnableMouse, f, false) end
	local ok = false
	if not InCombatLockdown() then
		ok = pcall(f.SetParent, f, trash)
	end
	if ok then
		if f.Hide then pcall(f.Hide, f) end
	else
		fade(f) -- lockdown or SetParent refused: keep it dark and dead
	end
end

function Core.FadeDecor()
	for _, n in ipairs(KILL_NAMES) do kill(resolve(n)) end
	for _, n in ipairs(STRANGLE_NAMES) do strangle(resolve(n)) end
	for _, n in ipairs(DECOR_NAMES) do fade(resolve(n)) end
end

-- Docking ----------------------------------------------------------------------
-- Indicators are re-anchored onto the map WITHOUT SetParent: the anchor
-- follows Minimap wherever the panel takes it, and blizzard's own parent
-- (IndicatorFrame layout etc.) keeps working untouched.
local function dock(f, point, relPoint, x, y, scale, anchor)
	if type(f) ~= "table" then return end
	anchor = anchor or Minimap
	pcall(f.ClearAllPoints, f)
	pcall(f.SetPoint, f, point, anchor, relPoint, x, y)
	if scale then pcall(f.SetScale, f, scale) end
	-- cluster children render in the cluster's low strata - an icon that
	-- only anchors onto the map still draws UNDER it (the mail button
	-- vanished exactly like that). Lift the docked frame to the map's own
	-- strata/level band so it always sits on top of the deco.
	local strata = select(2, pcall(Minimap.GetFrameStrata, Minimap))
	local lvl = select(2, pcall(Minimap.GetFrameLevel, Minimap))
	if strata then pcall(f.SetFrameStrata, f, strata) end
	if type(lvl) == "number" then pcall(f.SetFrameLevel, f, lvl + 9) end
end

-- Blizzard layout frames (MinimapCluster.IndicatorFrame et al.) re-anchor
-- their children every time one of them shows - pending mail snaps the
-- mail button back into the cluster and it vanishes under the panel.
-- A post-hook only FLAGS the drift: re-anchoring inside the client's own
-- SetPoint dispatch taints whatever the client does next in that pass;
-- the pump corrects the anchor a frame later, from a safe dispatch.
local dockGuards = {}
local dockPump
local function keepDocked(f, point, relPoint, x, y, scale, anchor)
	if type(f) ~= "table" then return end
	anchor = anchor or Minimap
	-- the stored entry is rewritable: the mail icon moves between the
	-- coords bar and the map depending on the bar toggle
	local e = f.__sentiDockGuard
	if not e then
		e = { f = f }
		f.__sentiDockGuard = e
		dockGuards[#dockGuards + 1] = e
	end
	e.p, e.rp, e.x, e.y, e.s, e.a = point, relPoint, x, y, scale, anchor
	if not dockPump then
		dockPump = CreateFrame("Frame")
		-- pure polling, no SetPoint hook: a post-hook ran inside the
		-- client's layout dispatch and tainted whatever protected work
		-- followed (panel opens, secret compares)
		dockPump:SetScript("OnUpdate", function()
			for _, g in ipairs(dockGuards) do
				local fr = g.f
				local ok, _, rel = pcall(fr.GetPoint, fr, 1)
				if ok and rel and rel ~= g.a then
					pcall(fr.ClearAllPoints, fr)
					pcall(fr.SetPoint, fr, g.p, g.a, g.rp, g.x, g.y)
					if g.s then pcall(fr.SetScale, fr, g.s) end
				end
			end
		end)
	end
end

-- Mail detection, same triage the panel plugin runs: HasNewMail() is the
-- verdict the engine itself feeds (SentinelForeverCore uses it too), the
-- ICON child's IsShown is the fallback - never the IndicatorFrame
-- container, which is always shown and would stick the signal - and the
-- unread-sender list is the last resort for a missing API.
local function MailWaiting()
	if type(HasNewMail) == "function" then
		local ok, has = pcall(HasNewMail)
		has = ok and has
		if not S.IsSecret(has) and type(has) == "boolean" then return has end
	end
	local cluster = _G.MinimapCluster
	local ind = cluster and (cluster.IndicatorFrame or cluster.MailFrame)
	local f = (ind and type(ind.MailFrame) == "table" and ind.MailFrame)
		or _G.MiniMapMailFrame
	if type(f) == "table" and type(f.IsShown) == "function" then
		local okS, s = pcall(f.IsShown, f)
		if okS and not S.IsSecret(s) then return s == true end
	end
	if type(GetLatestThreeSenders) == "function" then
		local ok2, a = pcall(GetLatestThreeSenders)
		if ok2 and not S.IsSecret(a) then return a ~= nil end
	end
	return false
end

-- Element toggles: shown = unfaded + docked, hidden = faded.
local ELEMENTS = {
	tracking   = { "MiniMapTracking", "MiniMapTrackingButton", "MiniMapTrackingFrame", { "MinimapCluster", "Tracking" }, { "MinimapCluster", "Tracking", "Button" } },
	mail       = { "MiniMapMailFrame", { "MinimapCluster", "IndicatorFrame", "MailFrame" } },
	difficulty = { "MiniMapInstanceDifficulty", "MiniMapChallengeMode", "GuildInstanceDifficulty", { "MinimapCluster", "InstanceDifficulty" } },
}

function Core.PositionIndicators()
	local db = mod.db
	-- tracking: our own Lupe button takes the classic top-left spot when
	-- enabled - blizzard's tracking chrome stays faded then (it never
	-- showed reliably on this client, and two icons would overlap)
	if db.trackButton or db.hide.tracking then
		for _, s in ipairs(ELEMENTS.tracking) do fade(resolve(s)) end
	else
		for _, s in ipairs(ELEMENTS.tracking) do
			local f = resolve(s)
			unfade(f)
			-- docking only re-anchors: a frame the client keeps hidden
			-- never appears, so the magnifier gets an explicit show
			if f and f.Show then pcall(f.Show, f) end
			dock(f, "TOPLEFT", "TOPLEFT", 2, -2, 0.8)
			keepDocked(f, "TOPLEFT", "TOPLEFT", 2, -2, 0.8)
			if f and f.Background then pcall(f.Background.SetAlpha, f.Background, 0) end
		end
	end
	-- mail: top-right next to the menu button, only when mail waits.
	-- MinimapCluster.IndicatorFrame is a pure layout CONTAINER that shows
	-- together with the mail icon - on this client it keeps its own mouse
	-- and covers the whole top strip, killing every hover below it (zone
	-- bar, tracking, menu button). Mouse off on the containers only; the
	-- real icon buttons keep theirs.
	for _, s in ipairs({ { "MinimapCluster", "IndicatorFrame" },
		{ "MinimapCluster", "InstanceDifficulty" },
		{ "MinimapCluster", "Tracking" } }) do
		local c = resolve(s)
		if c and c.EnableMouse then pcall(c.EnableMouse, c, false) end
	end
	-- the mail signal is our own icon in the coords bar, right next to the
	-- coordinates - blizzard's frame visibility is unreliable under our
	-- layout, so it only carries the fallback while the bar is hidden
	local inBar = coordsBar and coordsText and db.coords == true
	local waiting = not db.hide.mail and MailWaiting()
	if mailBtn then mailBtn:SetShown(inBar and waiting) end
	for _, s in ipairs(ELEMENTS.mail) do
		local f = resolve(s)
		if f then
			if inBar or db.hide.mail then
				fade(f)
			else
				unfade(f)
				-- a resolved "mail" element that turns out to be a wide
				-- invisible container must never swallow hover either
				local okW, w = pcall(f.GetWidth, f)
				if okW and type(w) == "number" and not S.IsSecret(w) and w > 64 then
					pcall(f.EnableMouse, f, false)
				end
				dock(f, "TOPRIGHT", "TOPRIGHT", -21, -3, 0.85)
				keepDocked(f, "TOPRIGHT", "TOPRIGHT", -21, -3, 0.85)
			end
		end
	end
	-- difficulty flag: top-right corner
	for _, s in ipairs(ELEMENTS.difficulty) do
		local f = resolve(s)
		if f then
			if db.hide.difficulty then fade(f) else
				unfade(f)
				dock(f, "TOPRIGHT", "TOPRIGHT", 0, 0)
				keepDocked(f, "TOPRIGHT", "TOPRIGHT", 0, 0)
			end
		end
	end
	-- queue tools + expansion landing bottom-left
	for _, n in ipairs({ "MiniMapLFGFrame", "MiniMapBattlefieldFrame", "LFGMinimapFrame", "QueueStatusMinimapButton" }) do
		local f = _G[n]
		if f then
			dock(f, "BOTTOMLEFT", "BOTTOMLEFT", 2, 2)
			local b = _G[n .. "Border"]
			if b then fade(b) end
		end
	end
	local landing = ExpansionLandingPageMinimapButton or GarrisonLandingPageMinimapButton
	if landing then
		dock(landing, "BOTTOMLEFT", "BOTTOMLEFT", 26, 2, 0.6)
		keepDocked(landing, "BOTTOMLEFT", "BOTTOMLEFT", 26, 2, 0.6)
	end
end

function Core.ApplyElements()
	-- the bar renders its own clock and day/night icon; blizzard's clock and
	-- calendar buttons stay faded (GameTimeFrame is in DECOR_NAMES)
	if zoneBar and zoneBar.clockText then
		local showClock = not mod.db.hide.clock
		zoneBar.clockText:SetShown(showClock)
		zoneBar.dayNight:SetShown(showClock and not mod.db.hide.calendar)
		zoneBar.clockBtn:SetShown(showClock)
	end
	Core.PositionIndicators()
end

-- Shape + signature deco -----------------------------------------------------------

local function accent()
	local c = mod.db.accentColor
	return (c and (c[1] or c.r)) or C.accent.r, (c and (c[2] or c.g)) or C.accent.g, (c and (c[3] or c.b)) or C.accent.b
end

function Core.ApplyAccent()
	local r, g, b = accent()
	if ring then ring:SetVertexColor(r, g, b, 1) end
	for _, t in ipairs(corners) do t:SetVertexColor(r, g, b, 1) end
	if zoneBar and zoneBar.line then zoneBar.line:SetVertexColor(r, g, b, 0.9) end
	if coordsBar and coordsBar.line then coordsBar.line:SetVertexColor(r, g, b, 0.9) end
	if menuBtn and menuBtn.lines then
		for _, t in ipairs(menuBtn.lines) do t:SetVertexColor(r, g, b) end
	end
	if addonTrigger then addonTrigger.icon:SetTextColor(r, g, b) end
end

function Core.ApplyShape()
	local square = mod.db.shape == "square"
	if square then
		pcall(Minimap.SetMaskTexture, Minimap, BLANK)
	else
		pcall(Minimap.SetMaskTexture, Minimap, CIRCLE)
	end
	pcall(function() Minimap:SetArchBlobRingAlpha(0) Minimap:SetQuestBlobRingAlpha(0) end)
	if HybridMinimap and HybridMinimap.CircleMask then
		pcall(HybridMinimap.CircleMask.SetTexture, HybridMinimap.CircleMask, square and BLANK or CIRCLE)
	end
	if ring then ring:SetShown(not square) end
	if halo then halo:SetShown(not square) end
	if miniBorderTex then miniBorderTex:SetShown(square) end
	for _, t in ipairs(corners) do t:SetShown(square) end
end

local function buildDeco()
	-- dark halo behind the round map
	halo = Minimap:CreateTexture(nil, "BACKGROUND")
	halo:SetTexture(CIRCLE)
	halo:SetVertexColor(0, 0, 0, 0.75)
	halo:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -5, 5)
	halo:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 5, -5)

	deco = CreateFrame("Frame", "SentiUIMinimapDeco", Minimap)
	deco:SetAllPoints()
	deco:SetFrameLevel(Minimap:GetFrameLevel() + 3)

	-- amber ring with compass ticks for the round map
	ring = deco:CreateTexture(nil, "OVERLAY")
	ring:SetTexture(RING)
	ring:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -3, 3)
	ring:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 3, -3)

	-- amber corner brackets: the Sentinel signature for the square map.
	-- The generated MinimapBorder.tga ships all four brackets in one
	-- texture (authored gold - kept out of the accent-tinted corners
	-- list so its color survives accent customization)
	local mb = S.Tex and S.Tex("MinimapBorder")
	if mb then
		miniBorderTex = deco:CreateTexture(nil, "OVERLAY", nil, 7)
		miniBorderTex:SetTexture(mb)
		miniBorderTex:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -2, 2)
		miniBorderTex:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 2, -2)
	else
		for _, p in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
			for _, horiz in ipairs({ true, false }) do
				local t = deco:CreateTexture(nil, "OVERLAY", nil, 7)
				t:SetTexture(BLANK)
				t:SetPoint(p, Minimap, p, (p:find("LEFT") and -2 or 2), (p:find("TOP") and 2 or -2))
				if horiz then t:SetSize(14, 2) else t:SetSize(2, 14) end
				corners[#corners + 1] = t
			end
		end
	end
end

-- Zone bar above the panel --------------------------------------------------------------

local PVP_COLORS = {
	sanctuary = { 0.41, 0.8, 0.94 }, arena = { 1, 0.1, 0.1 },
	friendly = { 0.1, 1, 0.1 }, hostile = { 1, 0.1, 0.1 },
	contested = { 1, 0.7, 0 }, combat = { 1, 0.1, 0.1 },
}

function Core.UpdateZoneText()
	if not zoneText then return end
	local text = (GetMinimapZoneText and GetMinimapZoneText()) or (GetZoneText and GetZoneText()) or ""
	local pvp = GetZonePVPInfo and GetZonePVPInfo()
	local c = (pvp and PVP_COLORS[pvp]) or { 1, 0.9, 0.7 }
	zoneText:SetText(text)
	zoneText:SetTextColor(c[1], c[2], c[3])
end

local function buildZoneBar()
	-- sibling of the panel, only anchored to it: children of the LOW-strata
	-- panel can be occluded by the reparented map widget on this client
	zoneBar = S.Panel(UIParent, 10, 20, "panel")
	zoneBar:SetFrameStrata("MEDIUM")
	zoneBar:SetPoint("BOTTOMLEFT", panel, "TOPLEFT", 0, 2)
	zoneBar:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", 0, 2)
	zoneBar.line = zoneBar:CreateTexture(nil, "BORDER")
	zoneBar.line:SetTexture(BLANK)
	zoneBar.line:SetHeight(1)
	zoneBar.line:SetPoint("BOTTOMLEFT", zoneBar, "BOTTOMLEFT")
	zoneBar.line:SetPoint("BOTTOMRIGHT", zoneBar, "BOTTOMRIGHT")
	zoneText = S.Font(zoneBar, mod.db.locationFontSize, nil, "OUTLINE")
	zoneText:SetPoint("CENTER", zoneBar, "CENTER")
	zoneText:SetJustifyH("CENTER")
	-- own clock + day/night icon on the right: TimeManagerClockButton is not
	-- guaranteed to exist on this client, so the bar renders the time itself
	zoneBar.clockText = S.Font(zoneBar, math.max(9, (mod.db.locationFontSize or 13) - 1), nil, "OUTLINE")
	zoneBar.clockText:SetPoint("RIGHT", zoneBar, "RIGHT", -6, 0)
	zoneBar.clockText:SetJustifyH("RIGHT")
	zoneBar.dayNight = zoneBar:CreateTexture(nil, "OVERLAY")
	zoneBar.dayNight:SetSize(13, 13)
	zoneBar.dayNight:SetPoint("RIGHT", zoneBar.clockText, "LEFT", -3, 0)
	-- the clock segment doubles as the calendar button
	zoneBar.clockBtn = CreateFrame("Button", nil, zoneBar)
	zoneBar.clockBtn:SetHeight(18)
	zoneBar.clockBtn:SetPoint("RIGHT", zoneBar, "RIGHT", -2, 0)
	zoneBar.clockBtn:SetPoint("LEFT", zoneBar.dayNight, "LEFT", -2, 0)
	zoneBar.clockBtn:RegisterForClicks("AnyUp")
	zoneBar.clockBtn:SetScript("OnClick", function()
		if ToggleCalendar then ToggleCalendar()
		elseif C_Calendar and C_Calendar.OpenCalendar then C_Calendar.OpenCalendar() end
	end)
	zoneBar.clockBtn:SetScript("OnEnter", function(b)
		GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(L["Calendar"])
		GameTooltip:Show()
	end)
	zoneBar.clockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	-- the zone name stays centered in the space LEFT of the clock segment -
	-- bounded on both sides it can never run under the day/night icon or time
	zoneText:ClearAllPoints()
	zoneText:SetPoint("LEFT", zoneBar, "LEFT", 8, 0)
	zoneText:SetPoint("RIGHT", zoneBar.clockBtn, "LEFT", -4, 0)
	zoneText:SetWordWrap(false)
	zoneText:SetMaxLines(1)
end

function Core.ApplyZoneBar()
	if not zoneBar then return end
	local mode = mod.db.locationText
	zoneBar:SetShown(mode == "show" or (mode == "mouseover" and (panel:IsMouseOver() or zoneBar:IsMouseOver())))
	zoneText:SetFont(S.media.font, mod.db.locationFontSize or 13, "OUTLINE")
end

-- Coords bar below the panel: burger left, coords center, "+" right ---------------

-- Entries with a matching Blizzard micro button get a secure click-through:
-- the row is a SecureActionButtonTemplate with type=macro and
-- macrotext "/click <micro button>", so the hardware click is dispatched
-- by the client's own macro engine and the micro button's OnClick runs
-- untainted (the secure `click` type itself does not fire on this build).
-- Calling the Toggle* functions from addon code instead drags our taint
-- into Blizzard's show path, where secret status-bar values fail to
-- compare (seen on the character frame). securecall does NOT untaint on
-- this client - only a real secure click does.
local MENU_ENTRIES = {
	{ "Character", function() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end, { "CharacterMicroButton" } },
	{ "Spellbook", function() if ToggleSpellBook then ToggleSpellBook(BOOKTYPE_SPELL) elseif SpellBookFrame then ToggleFrame(SpellBookFrame) end end, { "PlayerSpellsMicroButton", "SpellbookMicroButton" } },
	{ "Talents", function() if ToggleTalentFrame then ToggleTalentFrame() elseif PlayerTalentFrame then ToggleFrame(PlayerTalentFrame) end end, { "TalentMicroButton", "PlayerSpellsMicroButton" } },
	{ "Quest Log", function() if ToggleQuestLog then ToggleQuestLog() elseif QuestLogFrame then ToggleFrame(QuestLogFrame) end end, { "QuestLogMicroButton" } },
	{ "Social", function() if ToggleFriendsFrame then ToggleFriendsFrame() elseif FriendsFrame then ToggleFrame(FriendsFrame) end end, { "SocialsMicroButton" } },
	{ "Guild", function() if ToggleGuildFrame then ToggleGuildFrame() elseif GuildFrame then ToggleFrame(GuildFrame) end end, { "GuildMicroButton", "CommunitiesMicroButton" } },
	{ "Group Finder", function() if ToggleLFGParentFrame then ToggleLFGParentFrame() elseif LFGParentFrame then ToggleFrame(LFGParentFrame) elseif PVEFrame then ToggleFrame(PVEFrame) end end, { "GroupFinderMicroButton", "LFDMicroButton", "LFGMicroButton", "PVEMicroButton" } },
	{ "Achievements", function() if ToggleAchievementFrame then ToggleAchievementFrame() end end, { "AchievementMicroButton", "AchievementsMicroButton" } },
	{ "Collections", function() if ToggleCollectionsJournal then ToggleCollectionsJournal() end end, { "CollectionsMicroButton" } },
	{ "World Map", function() if ToggleWorldMap then ToggleWorldMap() elseif WorldMapFrame then ToggleFrame(WorldMapFrame) end end, { "WorldMapMicroButton", "MinimapPanelTab" } },
	{ "Macros", function()
		if MacroFrame_LoadUI then MacroFrame_LoadUI() end -- LoD addon
		if ShowMacroFrame then ShowMacroFrame()
		elseif ToggleMacroFrame then ToggleMacroFrame()
		elseif MacroFrame then ToggleFrame(MacroFrame) end
	end },
	{ "Keybindings", function()
		if ToggleKeyBindingFrame then ToggleKeyBindingFrame()
		elseif KeyBindingFrame_LoadUI then
			KeyBindingFrame_LoadUI()
			if KeyBindingFrame then ToggleFrame(KeyBindingFrame) end
		end
	end },
	{ "Options", function() if SettingsPanel then ToggleFrame(SettingsPanel) elseif InterfaceOptionsFrame then ToggleFrame(InterfaceOptionsFrame) end end },
	{ "Main Menu", function() if GameMenuFrame then ToggleFrame(GameMenuFrame) end end, { "MainMenuMicroButton" } },
}

local function clickTarget(entry)
	if type(entry[3]) ~= "table" then return end
	for _, name in ipairs(entry[3]) do
		local f = _G[name]
		if type(f) == "table" and f.Click then return f end
	end
end

local SUI_ENTRIES = {
	{ "Settings", function() S.OptionsPanel.Toggle() end },
	{ "Move frames", function() S.Movers.Toggle() end },
	{ "Run installer", function() S.Installer.Show() end },
	-- third field = secure macro text: the row becomes a real macro
	-- button, because C_UI.Reload from addon code is a blocked call
	{ "Reload", nil, "/reload" },
}

-- other SentiUI modules can file their own row into the flyout (the admin
-- module does) - the rows are iterated live on every menu open
S.MinimapMenuRows = SUI_ENTRIES

local function buildMenu()
	menu = CreateFrame("Frame", "SentiUIMinimapMenu", UIParent, "BackdropTemplate")
	menu:SetFrameStrata("TOOLTIP")
	menu:SetToplevel(true)
	S.Template(menu, "panel")
	menu:SetClampedToScreen(true)
	menu.rows = {}
	menu:Hide()

	suiMenu = CreateFrame("Frame", "SentiUIMinimapMenuSUI", menu, "BackdropTemplate")
	suiMenu:SetFrameStrata("TOOLTIP")
	suiMenu:SetToplevel(true)
	S.Template(suiMenu, "panel")
	suiMenu.rows = {}
	suiMenu:Hide()

	local function makeRow(parent, i)
		-- secure template: rows that forward to a Blizzard micro button need
		-- type=click attributes; a plain OnClick on it still works for the rest
		local b = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
		b:RegisterForClicks("AnyDown", "AnyUp")
		b:SetHeight(18)
		b:SetPoint("LEFT", 4, 0)
		b:SetPoint("RIGHT", -4, 0)
		b.text = S.Font(b, 11)
		b.text:SetPoint("LEFT", 6, 0)
		b.hl = b:CreateTexture(nil, "HIGHLIGHT")
		b.hl:SetAllPoints()
		b.hl:SetTexture(BLANK)
		b.hl:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.18)
		parent.rows[i] = b
		return b
	end

	local suiRow = makeRow(menu, 1)
	suiRow.text:SetText("|cff" .. S.Hex(C.accent) .. "SentiUI|r  »")
	suiRow:SetScript("OnEnter", function()
		for i, e in ipairs(SUI_ENTRIES) do
			local r = suiMenu.rows[i] or makeRow(suiMenu, i)
			r.text:SetText(L[e[1]])
			local secured = false
			if e[3] and not InCombatLockdown() then
				secured = pcall(r.SetAttribute, r, "type", "macro")
					and pcall(r.SetAttribute, r, "type1", "macro")
					and pcall(r.SetAttribute, r, "macrotext", e[3])
					and pcall(r.SetAttribute, r, "macrotext1", e[3])
					or false
			end
			if secured then
				-- no SetScript("OnClick") - the template's own handler must
				-- run, a stored override makes the dispatch insecure and the
				-- macro call gets flagged FORBIDDEN
				r:SetScript("PostClick", function() suiMenu:Hide() menu:Hide() end)
			else
				r:SetScript("PostClick", nil)
				r:SetScript("OnClick", function()
					suiMenu:Hide() menu:Hide()
					if e[2] then
						S.SafeCall("MinimapMenu:" .. e[1], function()
							-- panel toggles must run untainted: Blizzard's own
							-- handlers compare secret values (status bar text)
							if type(securecall) == "function" then return securecall(e[2]) end
							return e[2]()
						end)
					end
				end)
			end
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", suiMenu, "TOPLEFT", 4, -(4 + (i - 1) * 18))
			r:SetPoint("TOPRIGHT", suiMenu, "TOPRIGHT", -4, -(4 + (i - 1) * 18))
			r:Show()
		end
		local w = 110
		for i = 1, #SUI_ENTRIES do
			suiMenu.rows[i].text:SetWidth(0)
			w = math.max(w, suiMenu.rows[i].text:GetStringWidth() + 16)
		end
		suiMenu:SetSize(w, 8 + #SUI_ENTRIES * 18)
		suiMenu:ClearAllPoints()
		suiMenu:SetPoint("BOTTOMRIGHT", menu, "BOTTOMLEFT", -2, 0)
		suiMenu:Show()
	end)

	-- entry wiring lives in its own pass: a first open during combat can
	-- not SetAttribute, so the rows get a retry on the next peaceful open
	local function setupEntries()
		menu.insecure = nil
		for i, e in ipairs(MENU_ENTRIES) do
			local b = menu.rows[i + 1] or makeRow(menu, i + 1)
			b.text:SetText(L[e[1]])
			local target = clickTarget(e)
			local secured = false
			if target and not InCombatLockdown() then
				-- the secure `click` type does not fire on this build - the
				-- macro path does: "/click <micro button>" is dispatched by
				-- the client's own secure engine, so the micro button's
				-- handler runs untainted (SFC proven)
				local tname = target.GetName and target:GetName()
				if type(tname) == "string" and tname ~= "" then
					secured = pcall(b.SetAttribute, b, "type", "macro")
						and pcall(b.SetAttribute, b, "type1", "macro")
						and pcall(b.SetAttribute, b, "macrotext", "/click " .. tname)
						and pcall(b.SetAttribute, b, "macrotext1", "/click " .. tname)
						or false
				end
			elseif target then
				menu.insecure = true -- lockdown blocked the secure wiring
			end
			if secured then
				-- no SetScript("OnClick") - the template's own handler must
				-- run, a stored override makes the dispatch insecure and the
				-- macro call gets flagged FORBIDDEN
				b:SetScript("PostClick", function() menu:Hide() end)
			else
				b:SetScript("PostClick", nil)
				b:SetScript("OnClick", function()
					menu:Hide()
					S.SafeCall("MinimapMenu:" .. e[1], e[2])
				end)
			end
			b:HookScript("OnEnter", function() suiMenu:Hide() end)
		end
	end
	setupEntries()
	menu.setupEntries = setupEntries
	-- once, not per OnShow: re-inserting on every show piled duplicate
	-- entries into the client's special-frame list
	S.EscClosable(menu)
	menu:EnableMouse(true)

	-- no OnHide hooks: OnHide runs inside the Escape dispatch and
	-- taints the engine's protected spell-stop calls. The watcher
	-- polls the hidden transition from OnUpdate (a safe dispatch)
	-- and folds the old OnHide work into it.
	local watcher = CreateFrame("Frame")
	watcher:Hide()
	watcher:SetScript("OnUpdate", function(f)
		if not menu:IsShown() then
			suiMenu:Hide()
			f:Hide()
			return
		end
		if not menu:IsMouseOver() and not suiMenu:IsMouseOver() and not menuBtn:IsMouseOver()
			and (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton")) then
			menu:Hide()
			f:Hide()
		end
	end)
	menu:HookScript("OnShow", function() watcher:Show() end)
end

local function layoutMenu()
	local RH = 18
	for i, b in ipairs(menu.rows) do
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -(4 + (i - 1) * RH))
		b:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, -(4 + (i - 1) * RH))
		b:Show()
	end
	local w = 110
	for _, b in ipairs(menu.rows) do
		b.text:SetWidth(0)
		w = math.max(w, b.text:GetStringWidth() + 16)
	end
	menu:SetSize(w, 8 + #menu.rows * RH)
end

local function buildMenuButton()
	menuBtn = CreateFrame("Button", "SentiUIMinimapMenuButton", coordsBar)
	menuBtn:SetSize(16, 16)
	menuBtn:SetPoint("LEFT", coordsBar, "LEFT", 3, 0)
	menuBtn.lines = {}
	for i = 1, 3 do
		local t = menuBtn:CreateTexture(nil, "ARTWORK")
		t:SetTexture(BLANK)
		t:SetSize(8, 1)
		t:SetPoint("CENTER", menuBtn, "CENTER", 0, 4 - i * 3 + 3)
		menuBtn.lines[i] = t
	end
	menuBtn:RegisterForClicks("AnyUp")
	menuBtn:SetScript("OnClick", function()
		if not menu then buildMenu() end
		if menu.insecure and not InCombatLockdown() then
			menu.setupEntries() -- combat blocked the secure wiring before
		end
		if menu:IsShown() then menu:Hide() return end
		layoutMenu()
		menu:ClearAllPoints()
		menu:SetPoint("BOTTOMLEFT", menuBtn, "TOPLEFT", 0, 3)
		menu:Show()
	end)
	menuBtn:SetScript("OnEnter", function(b)
		GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L["Main Menu"])
		GameTooltip:Show()
	end)
	menuBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- "+" addon-button collection ---------------------------------------------------------
-- Same idea as SentinelMinimapButtonHide / the SFC collector: real minimap
-- buttons are faded out, our dropdown rows forward the click.
local SKIP = {
	Minimap = true, MinimapPing = true, MinimapBackdrop = true,
	MinimapZoomIn = true, MinimapZoomOut = true, MinimapZoneTextButton = true,
	MinimapToggleButton = true, MinimapNorthTag = true, MinimapBorderTop = true,
	MinimapCompassTexture = true, TimeManagerClockButton = true,
	GameTimeFrame = true, AddonCompartmentFrame = true,
	-- Blizzard's own indicators parked on the map ring: they are clickable
	-- 20-40px frames and would be swallowed by the loose match below
	MiniMapTracking = true, MiniMapTrackingFrame = true,
	MiniMapTrackingButton = true, MiniMapTrackingBorder = true,
	MiniMapMailFrame = true, MiniMapMailBorder = true,
	MiniMapInstanceDifficulty = true, MiniMapChallengeMode = true,
	GuildInstanceDifficulty = true, MiniMapBattlefieldFrame = true,
	MiniMapBattlefieldBorder = true, MiniMapLFGFrame = true,
	LFGMinimapFrame = true, QueueStatusMinimapButton = true,
	QueueStatusMinimapButtonBorder = true, MiniMapWorldMapButton = true,
	ExpansionLandingPageMinimapButton = true,
	GarrisonLandingPageMinimapButton = true, MiniMapVoiceChatFrame = true,
	DurabilityFrame = true, VehicleSeatIndicator = true,
	MinimapCluster = true, MinimapZoneText = true,
}
local BUTTON_PATTERNS = { "^LibDBIcon10_", "MinimapButton", "MinimapFrame", "MinimapIcon", "[-_]Minimap[-_]", "Minimap$" }
local PIN_PATTERNS = { "^HandyNotes", "^TomTom", "^HereBeDragons", "^Questie", "^GatherMate", "^pin", "^Pin", "^EasyFind" }

local function matchesAny(name, list)
	for _, p in ipairs(list) do if name:match(p) then return true end end
end

local PIN_TOP = "SentiUIMinimapButton" -- our own settings button, always first

-- module opt-in: SentiUI_* addons register their own minimap button name
-- here to be collected under "+" too (e.g. the admin console's button)
local EXTRA = S.MinimapCollect or {}
S.MinimapCollect = EXTRA

local function wanted(name, child)
	if name == PIN_TOP then return true end
	if not name or name == "" or SKIP[name] then return false end
	if EXTRA[name] then return true end
	if name:find("^SentiUI") or name:find("^SFC") then return false end
	if name:match("^TomCats-") then return true end
	if name:match("%d$") then return false end -- pooled frames (QuestieFrame10, ...)
	if matchesAny(name, PIN_PATTERNS) then return false end
	if matchesAny(name, BUTTON_PATTERNS) then return true end
	-- loose match: a clickable 12-64px frame sitting on the map is an
	-- addon button even when its name never said "Minimap" - catches the
	-- frames SentiHeal/DBM-style addons park on the ring that slipped
	-- through the pattern list
	if type(child) == "table" then
		local okW, w = pcall(child.GetWidth, child)
		local clickable = (child.IsObjectType and child:IsObjectType("Button"))
			or (child.GetScript and (child:GetScript("OnClick")
				or child:GetScript("OnMouseUp") or child:GetScript("OnMouseDown")))
		if clickable and okW and type(w) == "number"
			and not S.IsSecret(w) and w >= 12 and w <= 64 then
			return true
		end
	end
	return false
end

local function takeButton(child)
	local name = child and child.GetName and child:GetName()
	if name and wanted(name, child) and not captured[name] then
		captured[name] = { btn = child, name = name }
	end
	if name and captured[name] then fade(child) end
end

local function capture()
	local lib = _G.LibStub and _G.LibStub.GetLibrary and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
	if lib and lib.GetButtonList then
		for _, n in ipairs(lib:GetButtonList()) do
			local b = lib.GetMinimapButton and lib:GetMinimapButton(n)
			if b then takeButton(b) end
		end
	end
	local libMap = _G.LibStub and _G.LibStub:GetLibrary("LibMapButton-1.1", true)
	if libMap and libMap.buttons then
		for _, b in pairs(libMap.buttons) do takeButton(b) end
	end
	-- addon buttons hang on three parents depending on the addon:
	-- Minimap itself, MinimapCluster, or MinimapBackdrop - scan all three
	-- or the cluster-parented ones never reach the "+" list
	local function scanKids(parent)
		if not (parent and parent.GetChildren) then return end
		for _, child in ipairs({ parent:GetChildren() }) do
			if type(child) == "table" and child.IsObjectType then
				local isBtn = child:IsObjectType("Button")
				local clickable = not isBtn and child.GetScript
					and (child:GetScript("OnClick") or child:GetScript("OnMouseUp")
						or child:GetScript("OnMouseDown"))
				if isBtn or clickable then takeButton(child) end
			end
		end
	end
	scanKids(Minimap)
	scanKids(_G.MinimapCluster)
	scanKids(_G.MinimapBackdrop)
end
Core.Capture = capture

local function prettyName(n)
	n = n:gsub("LibDBIcon10_", ""):gsub("LibDBIcon_", "")
	n = n:gsub("MinimapButton$", ""):gsub("MiniMapButton$", "")
	n = n:gsub("Minimap$", ""):gsub("Button$", ""):gsub("Frame$", "")
	return n ~= "" and n or "?"
end

local function btnIcon(btn)
	local t = btn.icon or (btn.GetNormalTexture and btn:GetNormalTexture())
	if t and t.GetTexture and t:GetTexture() then return t:GetTexture() end
	if btn.GetRegions then
		for _, r in ipairs({ btn:GetRegions() }) do
			if r:IsObjectType("Texture") and r.GetTexture and r:GetTexture() then return r:GetTexture() end
		end
	end
end

local addonRows = {}
local function rebuildRows()
	for _, r in ipairs(addonRows) do r:Hide() end
	local list = {}
	for _, c in pairs(captured) do list[#list + 1] = c end
	table.sort(list, function(a, b)
		if a.name == PIN_TOP then return true end
		if b.name == PIN_TOP then return false end
		return prettyName(a.name) < prettyName(b.name)
	end)
	local y = -4
	for i, c in ipairs(list) do
		local r = addonRows[i]
		if not r then
			r = CreateFrame("Button", nil, addonPop)
			r:SetHeight(20)
			r.icon = r:CreateTexture(nil, "ARTWORK")
			r.icon:SetSize(16, 16)
			r.icon:SetPoint("LEFT", r, "LEFT", 6, 0)
			r.txt = S.Font(r, 10)
			r.txt:SetPoint("LEFT", r.icon, "RIGHT", 5, 0)
			r.txt:SetPoint("RIGHT", r, "RIGHT", -4, 0)
			r.hl = r:CreateTexture(nil, "HIGHLIGHT")
			r.hl:SetAllPoints()
			r.hl:SetTexture(BLANK)
			r.hl:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.15)
			addonRows[i] = r
		end
		local tex = btnIcon(c.btn)
		r.icon:SetTexture(tex or BLANK)
		if not tex then r.icon:SetAlpha(0) else r.icon:SetAlpha(1) end
		r.txt:SetText(prettyName(c.name))
		local col = c.name == PIN_TOP and C.accent or C.text
		r.txt:SetTextColor(col.r, col.g, col.b)
		local src = c.btn
		fade(src)
		r:SetScript("OnClick", function(_, button)
			pcall(src.Click, src, button == "RightButton" and "RightButton" or "LeftButton")
		end)
		r:SetScript("OnEnter", function(self)
			local oe = src.GetScript and src:GetScript("OnEnter")
			if oe then pcall(oe, src) end
			if not GameTooltip:IsShown() then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(prettyName(c.name))
				GameTooltip:Show()
			else
				GameTooltip:ClearAllPoints()
				GameTooltip:SetPoint("LEFT", self, "RIGHT", 4, 0)
			end
		end)
		r:SetScript("OnLeave", function()
			local ol = src.GetScript and src:GetScript("OnLeave")
			if ol then pcall(ol, src) else GameTooltip:Hide() end
		end)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", addonPop, "TOPLEFT", 4, y)
		r:SetPoint("TOPRIGHT", addonPop, "TOPRIGHT", -4, y)
		r:Show()
		y = y - 22
	end
	addonPop:SetHeight(#list > 0 and (-y + 4) or 30)
end

local function buildAddonTrigger()
	addonTrigger = CreateFrame("Button", "SentiUIMinimapAddonsTrigger", coordsBar, "BackdropTemplate")
	addonTrigger:SetSize(16, 16)
	S.Template(addonTrigger, "raised")
	addonTrigger.icon = S.Font(addonTrigger, 13, C.accent)
	addonTrigger.icon:SetPoint("CENTER")
	addonTrigger.icon:SetText("+")
	addonTrigger:SetPoint("RIGHT", coordsBar, "RIGHT", -3, 0)

	addonPop = S.Panel(UIParent, 190, 30, "panel")
	addonPop:SetPoint("BOTTOMRIGHT", addonTrigger, "TOPRIGHT", 0, 3)
	addonPop:SetFrameStrata("HIGH")
	addonPop:SetClampedToScreen(true)
	addonPop:Hide()

	addonTrigger:SetScript("OnClick", function()
		if InCombatLockdown() then return end
		if addonPop:IsShown() then addonPop:Hide() else
			capture()
			rebuildRows()
			addonPop:Show()
		end
	end)
	addonTrigger:SetScript("OnEnter", function(b)
		GameTooltip:SetOwner(b, "ANCHOR_LEFT")
		GameTooltip:AddLine(L["Addon buttons"])
		GameTooltip:AddLine(L["Click to open"], 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	addonTrigger:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local lib = _G.LibStub and _G.LibStub.GetLibrary and _G.LibStub:GetLibrary("LibDBIcon-1.0", true)
	if lib and lib.RegisterCallback then
		pcall(lib.RegisterCallback, lib, "SentiUIMinimap", "LibDBIcon_IconCreated", function(_, b)
			if b then takeButton(b) end
		end)
	end
end

-- performance button --------------------------------------------------------------
-- latency/fps/memory readout pinned next to the "+" collection - the
-- panel plugin's minimap-side twin. Hover shows the stats, right-click
-- opens the SentiUI settings.
local perfBtn

-- secret values throw on read/compare - unwrap them like the panel does
local function Plain(v)
	if v == nil or S.IsSecret(v) then return nil end
	if type(v) == "table" and S.IsSecretTable(v) then return nil end
	return v
end

-- total addon memory (KB) plus the heaviest addons, for the tooltip
local function addonMemory()
	if not UpdateAddOnMemoryUsage then return nil end
	pcall(UpdateAddOnMemoryUsage)
	local get = (C_AddOns and C_AddOns.GetAddOnMemoryUsage) or GetAddOnMemoryUsage
	local num = (C_AddOns and C_AddOns.GetNumAddOns) or GetNumAddOns
	local info = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
	if not (get and num) then return nil end
	local ok, n = pcall(num)
	n = ok and Plain(n) or 0
	local total, top = 0, {}
	for i = 1, n do
		local okM, m = pcall(get, i)
		m = okM and Plain(m)
		if m then
			total = total + m
			local name = i
			if info then
				local okI, an = pcall(info, i)
				if okI then name = Plain(an) or name end
			end
			top[#top + 1] = { name = tostring(name), kb = m }
		end
	end
	table.sort(top, function(a, b) return a.kb > b.kb end)
	return total, top
end

local function buildPerfButton()
	perfBtn = CreateFrame("Button", "SentiUIMinimapPerf", coordsBar)
	perfBtn:SetSize(16, 16)
	perfBtn.icon = perfBtn:CreateTexture(nil, "ARTWORK")
	perfBtn.icon:SetAllPoints()
	perfBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
	perfBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	perfBtn:RegisterForClicks("AnyUp")
	perfBtn:SetScript("OnEnter", function(b)
		GameTooltip:SetOwner(b, "ANCHOR_LEFT")
		GameTooltip:AddLine(L["Performance"])
		local ok, _, _, home, world = pcall(GetNetStats)
		if ok then
			GameTooltip:AddDoubleLine(L["Home latency"], format("%d ms", Plain(home) or 0), 0.7, 0.7, 0.7, 1, 1, 1)
			GameTooltip:AddDoubleLine(L["World latency"], format("%d ms", Plain(world) or 0), 0.7, 0.7, 0.7, 1, 1, 1)
		end
		GameTooltip:AddDoubleLine(L["Framerate"], format("%d", floor(GetFramerate() or 0)), 0.7, 0.7, 0.7, 1, 1, 1)
		local mem, top = addonMemory()
		if mem then
			GameTooltip:AddDoubleLine(L["Addon memory"], format("%.1f MB", mem / 1024), 0.7, 0.7, 0.7, 1, 1, 1)
			if top and #top > 0 then
				GameTooltip:AddLine(L["Top addons"], 0.92, 0.68, 0.2)
				for i = 1, math.min(#top, 5) do
					GameTooltip:AddDoubleLine("  " .. top[i].name, format("%.1f MB", top[i].kb / 1024), 1, 1, 1, 1, 1, 1)
				end
			end
		end
		GameTooltip:AddLine(L["Right-click: Options"], 0.5, 0.5, 0.5)
		GameTooltip:Show()
	end)
	perfBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	perfBtn:SetScript("OnClick", function(_, button)
		if button == "RightButton" and S.OptionsPanel and S.OptionsPanel.Toggle then
			S.OptionsPanel.Toggle()
		end
	end)
end

local function buildCoordsBar()
	coordsBar = S.Panel(UIParent, 10, 20, "panel")
	coordsBar:SetFrameStrata("MEDIUM")
	coordsBar:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -2)
	coordsBar:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT", 0, -2)
	coordsBar.line = coordsBar:CreateTexture(nil, "BORDER")
	coordsBar.line:SetTexture(BLANK)
	coordsBar.line:SetHeight(1)
	coordsBar.line:SetPoint("TOPLEFT", coordsBar, "TOPLEFT")
	coordsBar.line:SetPoint("TOPRIGHT", coordsBar, "TOPRIGHT")
	coordsText = S.Font(coordsBar, 10)
	coordsText:SetPoint("CENTER", coordsBar, "CENTER")
	coordsText:SetJustifyH("CENTER")
	buildMenuButton()
	buildAddonTrigger()
	buildPerfButton()
	-- own mail indicator right next to the coordinates - blizzard's frame
	-- does not show reliably under our layout, so the bar carries a small
	-- envelope driven by MailWaiting() instead
	mailBtn = CreateFrame("Button", "SentiUIMinimapMail", coordsBar)
	mailBtn:SetSize(14, 14)
	mailBtn:SetPoint("LEFT", coordsText, "RIGHT", 4, 0)
	mailBtn.icon = mailBtn:CreateTexture(nil, "ARTWORK")
	mailBtn.icon:SetAllPoints()
	mailBtn.icon:SetTexture("Interface\\Icons\\INV_Letter_15")
	mailBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	mailBtn:SetScript("OnEnter", function(b)
		GameTooltip:SetOwner(b, "ANCHOR_LEFT")
		GameTooltip:AddLine(L["Mail"])
		GameTooltip:AddLine(L["You have unread mail"], 1, 1, 1)
		GameTooltip:AddLine(L["Check your mailbox"], 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	mailBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	mailBtn:Hide()
end

function Core.UpdateCoords()
	if not coordsText then return end
	local ok, pos = pcall(function()
		return C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
	end)
	if ok and pos and pos.x and pos.y then
		local ok2, txt = pcall(string.format, "%.1f, %.1f", pos.x * 100, pos.y * 100)
		coordsText:SetText(ok2 and txt or "")
	else
		coordsText:SetText("")
	end
end

function Core.ApplyBars()
	if coordsBar then coordsBar:SetShown(mod.db.coords == true) end
	if menuBtn then menuBtn:SetShown(mod.db.menuButton == true and mod.db.coords == true) end
	if addonTrigger then addonTrigger:SetShown(mod.db.addonButtons == true and mod.db.coords == true) end
	if menu and mod.db.coords ~= true then menu:Hide() end
	if addonPop and (mod.db.addonButtons ~= true or mod.db.coords ~= true) then addonPop:Hide() end
	if perfBtn then
		local on = mod.db.perfButton == true and mod.db.coords == true
		perfBtn:SetShown(on)
		-- sit left of the "+" trigger while it is up, else take its spot
		perfBtn:ClearAllPoints()
		if addonTrigger and addonTrigger:IsShown() then
			perfBtn:SetPoint("RIGHT", addonTrigger, "LEFT", -4, 0)
		else
			perfBtn:SetPoint("RIGHT", coordsBar, "RIGHT", -3, 0)
		end
	end
	if zoomIn then zoomIn:SetShown(mod.db.zoomButtons == true) end
	if zoomOut then zoomOut:SetShown(mod.db.zoomButtons == true) end
	if trackBtn then
		trackBtn:SetShown(mod.db.trackButton == true)
		if mod.db.trackButton ~= true and trackPop then trackPop:Hide() end
	end
	Core.ApplyZoneBar()
end

-- Mouse ---------------------------------------------------------------------------------

-- shared zoom nudge: scroll wheel and the +/- buttons both land here
local function zoomStep(delta)
	local ok, zoom = pcall(Minimap.GetZoom, Minimap)
	if not ok or type(zoom) ~= "number" or S.IsSecret(zoom) then return end
	local maxZ = 5
	if Minimap.GetZoomLevels then
		local ok2, mz = pcall(Minimap.GetZoomLevels, Minimap)
		if ok2 and type(mz) == "number" and mz > 0 then maxZ = mz end
	end
	pcall(Minimap.SetZoom, Minimap, math.max(0, math.min(maxZ, zoom + delta)))
	if mod.db.zoomReset then
		Core.zoomToken = (Core.zoomToken or 0) + 1
		local token = Core.zoomToken
		C_Timer.After(6, function()
			local ok3, z = pcall(Minimap.GetZoom, Minimap)
			if Core.zoomToken == token and ok3 and z and z > 0 then
				pcall(Minimap.SetZoom, Minimap, 0)
			end
		end)
	end
end

-- own zoom buttons at the map's bottom-right corner (where the classic
-- magnifier pair used to sit): small +/- texts, quiet until hovered
local function buildZoomButtons()
	local function mk(txt, xOff, delta)
		-- parented to our panel, anchored onto the map - same pattern the
		-- docked blizzard elements use (no SetParent on minimap children)
		local b = CreateFrame("Button", "SentiUIMinimapZoom" .. (delta > 0 and "In" or "Out"), panel)
		b:SetSize(14, 14)
		b:SetFrameStrata("MEDIUM")
		b:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", xOff, 2)
		b.fs = S.Font(b, 12, C.accent)
		b.fs:SetPoint("CENTER")
		b.fs:SetText(txt)
		b:SetAlpha(0.5)
		b:SetScript("OnEnter", function(self)
			self:SetAlpha(1)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:AddLine(delta > 0 and L["Zoom in"] or L["Zoom out"])
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function(self)
			self:SetAlpha(0.5)
			GameTooltip:Hide()
		end)
		b:SetScript("OnClick", function() zoomStep(delta) end)
		return b
	end
	zoomIn = mk("+", -16, 1)
	zoomOut = mk("-", -4, -1)
end

-- tracking (Lupe) button ----------------------------------------------------------
-- the classic magnifier at the map's top-left, as our own button + menu:
-- blizzard's tracking chrome is absent or buried on this client and the
-- dock+show path never revealed it. The menu lists the client's tracking
-- types via C_Minimap (classic globals as fallback) and toggles them.
-- both tracking APIs are read and merged (deduped by name): the modern
-- C_Minimap table shape and the classic positional one list different
-- subsets on this client, the standard entries only show up together
local function trackingList()
	local out, seen = {}, {}
	local function add(id, name, active, nested, legacy)
		name = Plain(name)
		if type(name) ~= "string" or name == "" or seen[name] then return end
		seen[name] = true
		out[#out + 1] = { id = id, name = name, active = Plain(active) == true,
			nested = Plain(nested) == true, legacy = legacy == true }
	end
	if C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo then
		local okN, n = pcall(C_Minimap.GetNumTrackingTypes)
		n = okN and Plain(n) or 0
		for i = 1, n do
			local okI, info = pcall(C_Minimap.GetTrackingInfo, i)
			info = okI and Plain(info)
			if type(info) == "table" and not S.IsSecretTable(info) then
				add(i, info.name, info.active, info.nested)
			end
		end
	end
	if GetNumTrackingTypes and GetTrackingInfo then
		local okN, n = pcall(GetNumTrackingTypes)
		n = okN and Plain(n) or 0
		for i = 1, n do
			local okI, name, _, active, _, nested = pcall(GetTrackingInfo, i)
			-- classic ids index the classic list - flag them so toggling
			-- hits the same API the id came from
			if okI then add(i, name, active, nested, true) end
		end
	end
	return out
end

local function setTracking(tt, on)
	if tt.legacy and type(_G.SetTracking) == "function" then
		pcall(_G.SetTracking, tt.id, on)
	elseif C_Minimap and C_Minimap.SetTracking then
		pcall(C_Minimap.SetTracking, tt.id, on)
	elseif type(_G.SetTracking) == "function" then
		pcall(_G.SetTracking, tt.id, on)
	end
end

-- auto profession tracking: with Mining or Herbalism the matching
-- tracking (Find Minerals / Find Herbs) turns itself on when nothing is
-- tracked yet. The tracking list itself is the authority - it only
-- carries types the character can actually use, so matching its names
-- is enough (the old GetProfessions check never fired: that API hands
-- out list indices, not the 182/186 skill-line ids it was compared to).
-- A tracking the user turned off through our menu stays off.
local PROFESSION_TRACK = { "mineral", "kräuter", "kraeut", "herb" }

local function AutoTrack()
	local db = mod and mod.db
	if not (db and db.autoTrack) then return end
	db.autoTrackOff = db.autoTrackOff or {}
	local list = trackingList()
	for _, tt in ipairs(list) do
		if tt.active then return end -- the user's current choice wins
	end
	for _, tt in ipairs(list) do
		if not tt.nested and not tt.active and not db.autoTrackOff[tt.name] then
			local lname = tt.name:lower()
			for _, pat in ipairs(PROFESSION_TRACK) do
				if lname:find(pat, 1, true) then
					setTracking(tt, true)
					return
				end
			end
		end
	end
end

local function trackRow(i)
	local r = trackRows[i]
	if r then return r end
	r = CreateFrame("Button", nil, trackPop)
	r:SetHeight(18)
	r.text = S.Font(r, 11)
	r.text:SetPoint("LEFT", 6, 0)
	r.hl = r:CreateTexture(nil, "HIGHLIGHT")
	r.hl:SetAllPoints()
	r.hl:SetTexture(BLANK)
	r.hl:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.18)
	trackRows[i] = r
	return r
end

local function rebuildTrackRows()
	for _, r in ipairs(trackRows) do r:Hide() end
	local list = trackingList()
	local y = -4
	for i, tt in ipairs(list) do
		local r = trackRow(i)
		r.text:SetText((tt.active and "» " or "    ") .. tt.name)
		local c = tt.active and C.accent or C.text
		r.text:SetTextColor(c.r, c.g, c.b)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", trackPop, "TOPLEFT", 4, y)
		r:SetPoint("TOPRIGHT", trackPop, "TOPRIGHT", -4, y)
		r:SetScript("OnClick", function()
			setTracking(tt, not tt.active)
			-- remember manual offs so the profession auto-activation
			-- does not fight the user's choice on the next login
			local db = mod and mod.db
			if db and db.autoTrack then
				db.autoTrackOff = db.autoTrackOff or {}
				if tt.active then
					db.autoTrackOff[tt.name] = true
				else
					db.autoTrackOff[tt.name] = nil
				end
			end
			C_Timer.After(0.1, rebuildTrackRows)
		end)
		r:Show()
		y = y - 20
	end
	trackPop:SetHeight(#list > 0 and (-y + 4) or 30)
end

local function buildTrackButton()
	trackBtn = CreateFrame("Button", "SentiUIMinimapTracking", panel)
	trackBtn:SetSize(16, 16)
	trackBtn:SetFrameStrata("MEDIUM")
	trackBtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 2, -2)
	trackBtn.icon = trackBtn:CreateTexture(nil, "ARTWORK")
	trackBtn.icon:SetAllPoints()
	trackBtn.icon:SetTexture("Interface\\Icons\\Ability_Tracking")
	trackBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	trackBtn:SetAlpha(0.55)
	trackBtn:RegisterForClicks("AnyUp")

	trackPop = S.Panel(UIParent, 160, 30, "panel")
	trackPop:SetFrameStrata("TOOLTIP")
	trackPop:SetToplevel(true)
	trackPop:SetClampedToScreen(true)
	trackPop:Hide()

	trackBtn:SetScript("OnClick", function()
		if trackPop:IsShown() then trackPop:Hide() return end
		S.SafeCall("minimap:trackrows", rebuildTrackRows)
		trackPop:ClearAllPoints()
		trackPop:SetPoint("TOPLEFT", trackBtn, "BOTTOMLEFT", -2, -2)
		trackPop:Show()
	end)
	trackBtn:SetScript("OnEnter", function(b)
		b:SetAlpha(1)
		GameTooltip:SetOwner(b, "ANCHOR_LEFT")
		GameTooltip:AddLine(L["Tracking"])
		local any = false
		for _, t in ipairs(trackingList()) do
			if t.active then
				GameTooltip:AddLine("  " .. t.name, 0.6, 1, 0.6)
				any = true
			end
		end
		if not any then GameTooltip:AddLine("  " .. L["None"], 0.7, 0.7, 0.7) end
		GameTooltip:AddLine(L["Click: tracking menu"], 0.5, 0.5, 0.5)
		GameTooltip:Show()
	end)
	trackBtn:SetScript("OnLeave", function(b)
		b:SetAlpha(0.55)
		GameTooltip:Hide()
	end)
end

local function hookMouse()
	-- every hook on its own, so one unsupported script doesn't kill the rest
	pcall(Minimap.EnableMouse, Minimap, true)
	pcall(Minimap.EnableMouseWheel, Minimap, true)
	pcall(Minimap.SetScript, Minimap, "OnMouseWheel", function(m, delta)
		if not mod.db.scrollZoom then return end
		zoomStep(delta)
	end)
	pcall(Minimap.HookScript, Minimap, "OnMouseUp", function(_, button)
		if button == "RightButton" then
			local t = resolve("MinimapCluster.Tracking.Button")
			if MiniMapTrackingDropDown and ToggleDropDownMenu then
				ToggleDropDownMenu(1, nil, MiniMapTrackingDropDown, "cursor")
			elseif t and t.OpenMenu then t:OpenMenu()
			elseif t and t.Click then t:Click()
			elseif MiniMapTrackingButton then MiniMapTrackingButton:Click()
			elseif trackBtn and trackBtn:IsShown() then
				-- no blizzard tracking chrome on this client: our own menu
				trackBtn:Click()
			end
		elseif button == "MiddleButton" then
			if ToggleCalendar then ToggleCalendar() end
		end
	end)
	-- zone text on mouseover reads from the panel, the map itself may eat hovers
	panel:HookScript("OnEnter", function()
		if mod.db.locationText == "mouseover" then zoneBar:Show() end
	end)
	panel:HookScript("OnLeave", function()
		if mod.db.locationText == "mouseover" and not zoneBar:IsMouseOver() then zoneBar:Hide() end
	end)
end

-- Build ---------------------------------------------------------------------------------

local function buildPanel()
	panel = CreateFrame("Frame", "SentiUIMinimapPanel", UIParent, "BackdropTemplate")
	S.Template(panel, "panel")
	panel:SetFrameStrata("LOW")
	panel:SetFrameLevel(1)
	panel:SetSize(mod.db.size + 8, mod.db.size + 8)
	panel:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -6, -30)
	panel:EnableMouse(true)

	S.RunOutOfCombat(function()
		-- try SetParent first: if the client allows it the map is immune to
		-- ancestor hiding; if not it stays put and the anchor below still
		-- moves it (its own widget ops are allowed out of combat)
		pcall(Minimap.SetParent, Minimap, panel)
		pcall(Minimap.ClearAllPoints, Minimap)
		pcall(Minimap.SetPoint, Minimap, "TOPLEFT", panel, "TOPLEFT", 4, -4)
		pcall(Minimap.SetSize, Minimap, mod.db.size, mod.db.size)
		-- keep MinimapCluster alive: hiding it takes the whole minimap
		-- with it on this client. Only the decorations go.
	end)
	-- keep the map pinned inside the panel if something re-anchors it:
	-- polled, not hooked - a SetPoint post-hook ran inside the client's
	-- layout dispatch and tainted whatever protected work followed
	C_Timer.NewTicker(0.5, function()
		if InCombatLockdown() then return end
		local ok, _, rel = pcall(Minimap.GetPoint, Minimap, 1)
		if ok and rel and rel ~= panel then
			pcall(Minimap.ClearAllPoints, Minimap)
			pcall(Minimap.SetPoint, Minimap, "TOPLEFT", panel, "TOPLEFT", 4, -4)
		end
	end)
	-- the panel carries the mover: map, bars and deco travel together
	if not moverSet then
		local ratio = panel:GetEffectiveScale() / UIParent:GetEffectiveScale()
		local cx, cy = panel:GetCenter()
		local ux, uy = UIParent:GetCenter()
		if cx and ux then
			S.Movers.Register(panel, "minimap", L["Minimap"], {
				x = (cx - ux) / ratio, y = (cy - uy) / ratio })
			moverSet = true
		end
	end
end

function Core.ApplySize()
	if not panel then return end
	local size = mod.db.size or 190
	panel:SetSize(size + 8, size + 8)
	pcall(Minimap.SetSize, Minimap, size, size)
end

-- The 1s upkeep: zone + coords text, resurrecting decorations, late addon
-- buttons, indicator re-dock. Cheap loops, self-healing.
local function tick()
	if not mod or not mod.db.enabled then return end
	-- hover self-heal: a map without mouse/wheel enabled kills every hover
	-- function (zone text, wheel zoom, tracking menu) until re-enabled
	local okM, mOn = pcall(Minimap.IsMouseEnabled, Minimap)
	if okM and mOn == false then pcall(Minimap.EnableMouse, Minimap, true) end
	local okW, wOn = pcall(Minimap.IsMouseWheelEnabled, Minimap)
	if okW and wOn == false then pcall(Minimap.EnableMouseWheel, Minimap, true) end
	Core.UpdateZoneText()
	Core.UpdateCoords()
	if zoneBar and zoneBar.clockText and zoneBar.clockText:IsShown() then
		-- server time: it follows the in-game day/night cycle (6-18 = day)
		local h, m
		if GetGameTime then
			local ok, hh, mm = pcall(GetGameTime)
			if ok and type(hh) == "number" then h, m = hh, mm end
		end
		if not h then h, m = tonumber(date("%H")), tonumber(date("%M")) end
		if h then
			zoneBar.clockText:SetText(string.format("%d:%02d", h, m))
			zoneBar.dayNight:SetTexture((h >= 6 and h < 18) and SUN or MOON)
		end
	end
	Core.FadeDecor()
	Core.ApplyElements()
	capture()
end

function Core.ApplyAll()
	if not mod.db.enabled then return end
	local function step(name, fn)
		S.RunOutOfCombat(function() S.SafeCall("Minimap:" .. name, fn) end)
	end
	step("size", Core.ApplySize)
	step("deco", function()
		Core.ApplyShape()
		Core.ApplyAccent()
	end)
	step("hide", Core.FadeDecor)
	step("elements", Core.ApplyElements)
	step("bars", Core.ApplyBars)
	step("rotate", function()
		local setCVar = (C_CVar and C_CVar.SetCVar) or SetCVar
		if not setCVar then return end
		local want = mod.db.rotate and "1" or "0"
		local getCVar = (C_CVar and C_CVar.GetCVar) or GetCVar
		if not getCVar or getCVar("rotateMinimap") ~= want then
			pcall(setCVar, "rotateMinimap", want)
		end
	end)
end

-- Every phase on its own SafeCall: one piece failing on this client can't
-- keep the rest of the minimap dead, and the printed error names the phase.
function Core.Enable(m)
	mod = m
	-- one-time migration: earlier builds persisted a round map, a
	-- mouseover-only zone bar and a hidden clock/calendar
	if mod.db._v ~= 3 then
		mod.db._v = 3
		mod.db.shape = "square"
		mod.db.locationText = "show"
		mod.db.locationFontSize = 11
		if type(mod.db.hide) ~= "table" then mod.db.hide = {} end
		mod.db.hide.clock = false
		mod.db.hide.calendar = false
	end
	if built then Core.ApplyAll() return end
	built = true
	local function step(name, fn) S.SafeCall("Minimap:" .. name, fn) end
	step("panel", buildPanel)
	step("deco", buildDeco)
	step("zonebar", buildZoneBar)
	step("coordsbar", buildCoordsBar)
	step("zoombuttons", buildZoomButtons)
	step("trackbutton", buildTrackButton)
	step("mouse", hookMouse)
	step("apply", Core.ApplyAll)
	step("zone", Core.UpdateZoneText)
	step("coords", Core.UpdateCoords)
	C_Timer.NewTicker(1, tick)
	-- profession tracking auto-activation: the tracking list is not
	-- populated right at login, so a couple of delayed passes catch it
	S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(2, function() S.SafeCall("minimap:autotrack", AutoTrack) end)
		C_Timer.After(6, function() S.SafeCall("minimap:autotrack", AutoTrack) end)
	end)
	S.RegisterEvent("SKILL_LINES_CHANGED", function()
		C_Timer.After(1, function() S.SafeCall("minimap:autotrack", AutoTrack) end)
	end)
	-- dying strips the tracking without a loading screen: re-arm a beat
	-- after coming back (ALIVE fires on release AND on accept-rez,
	-- UNGHOST on returning to the body; SPELLS_CHANGED covers a freshly
	-- learned profession skill mid-session)
	for _, ev in ipairs({ "PLAYER_ALIVE", "PLAYER_UNGHOST", "SPELLS_CHANGED" }) do
		S.RegisterEvent(ev, function()
			C_Timer.After(1.5, function() S.SafeCall("minimap:autotrack", AutoTrack) end)
			C_Timer.After(5, function() S.SafeCall("minimap:autotrack", AutoTrack) end)
		end)
	end
end

function Core.SettingChanged(m, path)
	mod = m
	if path == "enabled" then return end -- that option asks for a reload itself
	Core.ApplyAll()
end

S.RegisterEvent("ZONE_CHANGED", function() if mod then Core.UpdateZoneText() end end)
S.RegisterEvent("ZONE_CHANGED_INDOORS", function() if mod then Core.UpdateZoneText() end end)
S.RegisterEvent("ZONE_CHANGED_NEW_AREA", function() if mod then Core.UpdateZoneText() end end)
S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
	if mod then
		S.RunOutOfCombat(function()
			if panel then
				pcall(Minimap.ClearAllPoints, Minimap)
				pcall(Minimap.SetPoint, Minimap, "TOPLEFT", panel, "TOPLEFT", 4, -4)
			end
			Core.PositionIndicators()
		end)
	end
end)
S.RegisterEvent("UPDATE_PENDING_MAIL", function() if mod then Core.PositionIndicators() end end)
-- keep the tracking popup's checkmarks live while it is open
S.RegisterEvent("MINIMAP_UPDATE_TRACKING", function()
	if mod and trackPop and trackPop:IsShown() then
		S.SafeCall("minimap:trackrows", rebuildTrackRows)
	end
end)
