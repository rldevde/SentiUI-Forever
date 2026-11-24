-- Group frames: a static five-button party block (SecureUnitButtonTemplate
-- + a [unit,exists] visibility state driver, so joins/leaves flip
-- visibility mid-combat without touching protected attributes) and a
-- SecureGroupHeaderTemplate
-- raid grid parented to an unprotected holder - the visibility state
-- driver lives on the holder so a state flip never runs the protected
-- header update (ADDON_ACTION_BLOCKED).
local _, ns = ...
local S = SentiUI
local L = ns.L

local ipairs, pairs, type = ipairs, pairs, type
local format, floor, ceil = string.format, math.floor, math.ceil
local max = math.max
local CreateFrame = CreateFrame

local UF = ns.UF
local G = {}
ns.Group = G

G.partyButtons = {}
G.raidHeader = nil

-- grow directions: how the member chain expands from the first slot
local growthMap = {
	DOWN = { point = "TOPLEFT", rel = "TOPLEFT", x = 0, y = -1, anchor = "TOPLEFT" },
	UP = { point = "BOTTOMLEFT", rel = "BOTTOMLEFT", x = 0, y = 1, anchor = "BOTTOMLEFT" },
	RIGHT = { point = "TOPLEFT", rel = "TOPLEFT", x = 1, y = 0, anchor = "TOPLEFT" },
	LEFT = { point = "TOPRIGHT", rel = "TOPRIGHT", x = -1, y = 0, anchor = "TOPRIGHT" },
}

-- range ticker: dims out-of-range members (party/raid)
local function RangeTick()
	for i = 1, #G.partyButtons do
		local b = G.partyButtons[i]
		if b:IsShown() and b.unit then
			ns.ApplyRangeAlpha(b,
				ns.db.party.rangeFade ~= false and ns.db.rangeFadeAlpha or 1)
		end
	end
	if G.raidHeader then
		for i = 1, 40 do
			local b
			if G.raidHeader.GetFrameRef then
				local ok, c = pcall(G.raidHeader.GetFrameRef, G.raidHeader, "child" .. i)
				b = ok and c
			end
			b = b or _G[G.raidHeader:GetName() .. "UnitButton" .. i]
			if not b then break end
			if b:IsShown() and b.unit then
				ns.ApplyRangeAlpha(b,
					ns.db.raid.rangeFade ~= false and ns.db.rangeFadeAlpha or 1)
			end
		end
	end
end

-- party -------------------------------------------------------------------------
local PARTY_TOKENS = { "player", "party1", "party2", "party3", "party4" }

local function PartyLayout()
	local db = ns.db.party
	if InCombatLockdown() then return S.RunOutOfCombat(PartyLayout) end
	local g = growthMap[db.growth or "DOWN"] or growthMap.DOWN
	local n = 0
	for i, tok in ipairs(PARTY_TOKENS) do
		local b = G.partyButtons[i]
		if not b then break end
		local show = tok ~= "player" or db.showPlayer
		UF.Configure(b) -- anchors/sizes the bars and texts (was never called)
		b:SetSize(db.w, db.h)
		b:ClearAllPoints()
		if g.y ~= 0 then
			b:SetPoint("TOPLEFT", G.partyHolder, "TOPLEFT", 0, (n) * (db.h + db.spacing) * g.y)
		else
			b:SetPoint("TOPLEFT", G.partyHolder, "TOPLEFT", (n) * (db.w + db.spacing) * g.x, 0)
		end
		if show then n = n + 1 end
		b.placed = show
		-- hidden slots collapse: park them offscreen, UnitWatch still drives show/hide
		if not show then
			b:SetPoint("TOPLEFT", G.partyHolder, "TOPLEFT", 0, 0)
		end
	end
	local w = g.y ~= 0 and db.w or (max(1, n) * db.w + max(0, n - 1) * db.spacing)
	local h = g.y ~= 0 and (max(1, n) * db.h + max(0, n - 1) * db.spacing) or db.h
	G.partyHolder:SetSize(max(w, 1), max(h, 1))
	local vis = db.enable and (db.showSolo and "show" or "[group] show; hide") or "hide"
	vis = "[petbattle] hide; [@raid6,exists] hide; " .. vis
	UnregisterStateDriver(G.partyHolder, "visibility")
	RegisterStateDriver(G.partyHolder, "visibility", vis)
end
G.PartyLayout = PartyLayout

function G.CreateParty()
	local db = ns.db.party
	local holder = CreateFrame("Frame", "SentiUI_UF_PartyHolder", UIParent)
	holder:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 60, -280)
	G.partyHolder = holder
	for i, tok in ipairs(PARTY_TOKENS) do
		local b = CreateFrame("Button", "SentiUI_UF_Party" .. i, holder, "SecureUnitButtonTemplate")
		b:SetAttribute("unit", tok)
		b:SetAttribute("toggleForVehicle", true)
		UF.Build(b, "party", db)
		b.showLevel = true
		b.isGroup = true
		b.RoleIcon = b.textHolder:CreateTexture(nil, "OVERLAY")
		b.RoleIcon:SetTexture(ns.RoleIcons)
		b.RoleIcon:SetSize(13, 13)
		-- centered on the top edge, clear of the texts inside and of the
		-- raid-target icon that sits on the corner itself
		b.RoleIcon:SetPoint("CENTER", b, "TOPRIGHT", -14, 0)
		b.RoleIcon:Hide()
		b.ReadyCheck = b.textHolder:CreateFontString(nil, "OVERLAY")
		b.ReadyCheck:SetFont(S.media.font, 12, "OUTLINE")
		b.ReadyCheck:SetPoint("CENTER", b.Health, "CENTER")
		-- engine-side visibility driver: RegisterUnitWatch does not flip
		-- shown state mid-combat on this client, so a join only appeared
		-- after PLAYER_REGEN_ENABLED
		if tok == "player" then
			RegisterStateDriver(b, "visibility", "[petbattle] hide; show")
		else
			RegisterStateDriver(b, "visibility",
				"[petbattle] hide; [@" .. tok .. ",exists] show; hide")
		end
		G.partyButtons[i] = b
		b.Refresh = UF.Refresh
		b:SetScript("OnEvent", function(self, event, unit, ...) UF.OnFrameEvent(self, event, unit, ...) end)
		for ev in pairs({
			UNIT_HEALTH = 1, UNIT_HEALTH_FREQUENT = 1, UNIT_MAXHEALTH = 1,
			UNIT_POWER_UPDATE = 1, UNIT_POWER_FREQUENT = 1, UNIT_MAXPOWER = 1,
			UNIT_DISPLAYPOWER = 1, UNIT_NAME_UPDATE = 1, UNIT_LEVEL = 1,
			UNIT_FACTION = 1, UNIT_AURA = 1, UNIT_THREAT_SITUATION_UPDATE = 1,
			UNIT_CONNECTION = 1, PLAYER_FLAGS_CHANGED = 1, UNIT_FLAGS = 1,
		}) do ns.RegisterUnitEvent(b, ev) end
		if ns.Extras then ns.Extras.RegisterFrameEvents(b) end
		b.unit = tok
		b.nameLen = 14
		UF.Refresh(b)
		-- the player slot stays registered only when "show player" is on;
		-- otherwise UnitWatch would keep showing it over slot 1
		if tok == "player" and not db.showPlayer then
			UnregisterStateDriver(b, "visibility")
			RegisterStateDriver(b, "visibility", "hide")
		end
	end
	-- leader / role / ready check refresh on roster changes
	for _, ev in ipairs({ "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "READY_CHECK",
		"READY_CHECK_CONFIRM", "READY_CHECK_FINISHED" }) do
		ns.RegisterBusEvent(ev, function()
			for i = 1, #G.partyButtons do
				local b = G.partyButtons[i]
				UF.UpdateIcons(b)
				UF.UpdateReadyCheck(b)
			end
		end)
	end
	PartyLayout()
	if ns.Extras then ns.Extras.CreatePartyPets() end
	S.Movers.Register(holder, "uf.party", L["Party"], { x = -420, y = 160 })
end

-- raid ----------------------------------------------------------------------------
local initSnippet = [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute("suiWidth"))
	self:SetHeight(header:GetAttribute("suiHeight"))
	self:SetAttribute("*type1", "target")
	self:SetAttribute("*type2", "togglemenu")
	self:SetAttribute("toggleForVehicle", true)
	header:CallMethod("InitChild", self:GetName())
]]

local function ChildUnitChanged(child, name, value)
	if name == "unit" then
		S.SafeCall("uf:childunit", function()
			child.unit = value
			UF.Refresh(child)
		end)
	end
end

function G.InitChild(header, child)
	if not child or child.suiInit then return end
	child.suiInit = true
	child.isGroup = true
	child.db = ns.db.raid
	UF.Build(child, "raid", ns.db.raid)
	child:HookScript("OnAttributeChanged", ChildUnitChanged)
	child:HookScript("OnShow", function(c)
		if c.unit then S.SafeCall("uf:childshow", UF.Refresh, c) end
	end)
	child.Refresh = UF.Refresh
	child:SetScript("OnEvent", function(self, event, unit, ...) UF.OnFrameEvent(self, event, unit, ...) end)
	for ev in pairs({
		UNIT_HEALTH = 1, UNIT_HEALTH_FREQUENT = 1, UNIT_MAXHEALTH = 1,
		UNIT_POWER_UPDATE = 1, UNIT_POWER_FREQUENT = 1, UNIT_MAXPOWER = 1,
		UNIT_DISPLAYPOWER = 1, UNIT_NAME_UPDATE = 1, UNIT_LEVEL = 1,
		UNIT_FACTION = 1, UNIT_AURA = 1, UNIT_THREAT_SITUATION_UPDATE = 1,
		UNIT_CONNECTION = 1, PLAYER_FLAGS_CHANGED = 1, UNIT_FLAGS = 1,
	}) do ns.RegisterUnitEvent(child, ev) end
	local db = ns.db.raid
	child.RoleIcon = child.textHolder:CreateTexture(nil, "OVERLAY")
	child.RoleIcon:SetTexture(ns.RoleIcons)
	child.RoleIcon:SetSize(11, 11)
	child.RoleIcon:SetPoint("CENTER", child, "TOPRIGHT", -10, 0)
	child.RoleIcon:Hide()
	child.ReadyCheck = child.textHolder:CreateFontString(nil, "OVERLAY")
	child.ReadyCheck:SetFont(S.media.font, 11, "OUTLINE")
	child.ReadyCheck:SetPoint("CENTER", child.Health, "CENTER")
	child.unit = child:GetAttribute("unit")
	child.nameLen = 7
	if ns.Extras then ns.Extras.RegisterFrameEvents(child) end
	UF.Configure(child)
end

function G.ApplyRaidAttributes(header)
	if InCombatLockdown() then return S.RunOutOfCombat(G.ApplyRaidAttributes, header) end
	local db = ns.db.raid
	-- RIGHT: each column fills downward, columns extend right.
	-- DOWN: each row fills rightward, rows extend down.
	local dir = db.growth or "RIGHT"
	local point, xOff, yOff, colAnchor
	if dir == "DOWN" then
		point, xOff, yOff, colAnchor = "LEFT", db.spacing, 0, "TOP"
	else
		point, xOff, yOff, colAnchor = "TOP", 0, -db.spacing, "LEFT"
	end
	header:SetAttribute("suiWidth", db.w)
	header:SetAttribute("suiHeight", db.h)
	header:SetAttribute("point", point)
	header:SetAttribute("xOffset", xOff)
	header:SetAttribute("yOffset", yOff)
	header:SetAttribute("columnAnchorPoint", colAnchor)
	header:SetAttribute("columnSpacing", db.spacing)
	header:SetAttribute("showPlayer", true)
	header:SetAttribute("sortMethod", "INDEX")
	header:SetAttribute("sortDir", "ASC")
	header:SetAttribute("maxColumns", db.maxColumns)
	header:SetAttribute("unitsPerColumn", db.unitsPerColumn)
	header:SetAttribute("groupFilter", "1,2,3,4,5,6,7,8")
	header:SetAttribute("groupBy", db.groupBy == "CLASS" and "CLASS" or db.groupBy == "ROLE" and "ASSIGNEDROLE" or "GROUP")
	header:SetAttribute("groupingOrder",
		db.groupBy == "CLASS" and "WARRIOR,PALADIN,DEATHKNIGHT,DEMONHUNTER,ROGUE,MONK,DRUID,HUNTER,SHAMAN,MAGE,WARLOCK,PRIEST,EVOKER"
		or db.groupBy == "ROLE" and "TANK,HEALER,DAMAGER,NONE"
		or "1,2,3,4,5,6,7,8")
	header:SetAttribute("raidWideSorting", false)

	for i = 1, 40 do
		local child
		if header.GetFrameRef then
			local ok, c = pcall(header.GetFrameRef, header, "child" .. i)
			child = ok and c
		end
		child = child or _G[header:GetName() .. "UnitButton" .. i]
		if not child then break end
		child:SetSize(db.w, db.h)
		child.db = db
		if child.suiInit then UF.Configure(child) end
	end

	local holder = header.holder
	local w, h
	if dir == "DOWN" then
		w = (db.unitsPerColumn) * db.w + (db.unitsPerColumn - 1) * db.spacing
		h = (db.maxColumns) * db.h + (db.maxColumns - 1) * db.spacing
	else
		w = (db.maxColumns) * db.w + (db.maxColumns - 1) * db.spacing
		h = (db.unitsPerColumn) * db.h + (db.unitsPerColumn - 1) * db.spacing
	end
	holder:SetSize(w, h)
	header:ClearAllPoints()
	header:SetPoint("TOPLEFT", holder, "TOPLEFT")

	local vis = db.enable and (db.showSolo and "show" or "[group:raid] show; hide") or "hide"
	RegisterStateDriver(holder, "visibility", "[petbattle] hide; " .. vis)
end

function G.CreateRaid()
	local db = ns.db.raid
	local holder = CreateFrame("Frame", "SentiUI_UF_RaidHolder", UIParent)
	holder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 6, 240)
	holder:SetSize(db.w * 5, db.h * 8)
	local header = CreateFrame("Frame", "SentiUI_UF_RaidHeader", holder, "SecureGroupHeaderTemplate")
	header.holder = holder
	header.InitChild = function(h, childName)
		S.SafeCall("uf:initchild", G.InitChild, h, _G[childName])
	end
	-- the template's own OnEvent/OnUpdate run SecureGroupHeader_Update even
	-- mid-combat (SetPoint on protected children -> ADDON_ACTION_BLOCKED).
	-- Detach them; roster changes re-run the update deferred via the bus.
	header:SetScript("OnEvent", nil)
	header:SetScript("OnUpdate", nil)
	header:UnregisterAllEvents()
	header:SetAttribute("template", "SecureUnitButtonTemplate")
	header:SetAttribute("initialConfigFunction", initSnippet)
	header:SetAttribute("showParty", false)
	header:SetAttribute("showRaid", true)
	header:SetAttribute("showSolo", false)
	header:SetAttribute("showPlayer", true)

	G.raidHeader = header
	G.raidHolder = holder

	S.Movers.Register(holder, "uf.raid", L["Raid"], { x = -460, y = -150 })

	-- pre-create every child out of combat so protected layout never runs later
	G.ApplyRaidAttributes(header)
	UnregisterStateDriver(holder, "visibility")
	holder:Show()
	header:Show()
	header:SetAttribute("startingIndex", -39)
	header:SetAttribute("startingIndex", 1)
	G.ApplyRaidAttributes(header)

	for _, ev in ipairs({ "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED",
		"READY_CHECK", "READY_CHECK_CONFIRM", "READY_CHECK_FINISHED" }) do
		ns.RegisterBusEvent(ev, function()
			S.RunOutOfCombat(function()
				if SecureGroupHeader_Update then
					pcall(SecureGroupHeader_Update, header)
				end
				for i = 1, 40 do
					local c
					if header.GetFrameRef then
						local ok, c2 = pcall(header.GetFrameRef, header, "child" .. i)
						c = ok and c2
					end
					c = c or _G[header:GetName() .. "UnitButton" .. i]
					if not c then break end
					UF.UpdateIcons(c)
					UF.UpdateReadyCheck(c)
				end
			end)
		end)
	end
end

function G.Initialize()
	if ns.db.party.enable then G.CreateParty() end
	if ns.db.raid.enable then G.CreateRaid() end
	C_Timer.NewTicker(0.5, RangeTick)
end
