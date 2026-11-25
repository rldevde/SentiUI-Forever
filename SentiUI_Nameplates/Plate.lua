-- The custom plate: flat Sentinel bars on a frame anchored to the game's
-- nameplate driver (which keeps doing the world->screen positioning). The
-- game's own unit frame is parked by the Manager; our frame never takes
-- mouse so unit clicks still reach the driver.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Plate = {}
ns.Plate = Plate

local BLANK = S.media.blank
local ACC, BLUE = S.colors.accent, S.colors.accent2

local CLASS_FALLBACK = {
	WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 },
	HUNTER = { 0.67, 0.83, 0.45 }, ROGUE = { 1.00, 0.96, 0.41 },
	PRIEST = { 1.00, 1.00, 1.00 }, DEATHKNIGHT = { 0.77, 0.12, 0.23 },
	SHAMAN = { 0.00, 0.44, 0.87 }, MAGE = { 0.25, 0.78, 0.92 },
	WARLOCK = { 0.53, 0.53, 0.93 }, MONK = { 0.00, 1.00, 0.59 },
	DRUID = { 1.00, 0.49, 0.04 }, DEMONHUNTER = { 0.64, 0.19, 0.79 },
	EVOKER = { 0.20, 0.58, 0.50 },
}
local REACTION_FALLBACK = {
	[1] = { 0.79, 0.15, 0.12 }, [2] = { 0.79, 0.15, 0.12 },
	[3] = { 0.85, 0.30, 0.12 }, [4] = { 0.78, 0.65, 0.12 },
	[5] = { 0.30, 0.85, 0.28 }, [6] = { 0.30, 0.85, 0.28 },
	[7] = { 0.30, 0.85, 0.28 }, [8] = { 0.30, 0.85, 0.28 },
}
local THREAT_COLORS = {
	good = { 0.16, 0.70, 0.55 }, -- holding it (tank) / safe (dps)
	warn = { 0.95, 0.55, 0.15 }, -- slipping / pulling soon
	bad = { 0.90, 0.15, 0.18 },  -- lost it (tank) / on you (dps)
}

local function plain(v)
	if S.IsSecret(v) then return nil end
	return v
end

-- class color, proven client path: numeric classID (3rd UnitClass return)
-- -> C_CreatureInfo.GetClassInfo -> RAID_CLASS_COLORS, fallbacks behind it
local function ClassColor(unit)
	local ok, _, tok, classID = pcall(UnitClass, unit)
	if ok then
		tok, classID = plain(tok), plain(classID)
		local c
		if type(tok) == "string" then
			c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[tok]
				or CLASS_FALLBACK[tok]
		end
		if not c and type(classID) == "number"
			and C_CreatureInfo and C_CreatureInfo.GetClassInfo then
			local okC, info = pcall(C_CreatureInfo.GetClassInfo, classID)
			info = okC and plain(info)
			local okF, file = pcall(function()
				return info and info.classFile end)
			file = okF and plain(file)
			if type(file) == "string" then
				c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[file]
					or CLASS_FALLBACK[file]
			end
		end
		if type(c) == "table" and not S.IsSecretTable(c) then
			if c.r then return c.r, c.g, c.b end
			return c[1], c[2], c[3]
		end
	end
	-- engine fallback: secret rgb straight to the setter
	if UnitClassBase and C_ClassColor and C_ClassColor.GetClassColor then
		local okU, _, file = pcall(UnitClassBase, unit)
		if okU and file then
			local okC, col = pcall(C_ClassColor.GetClassColor, file)
			if okC and type(col) == "table" then
				local okR, r, g, b = pcall(function()
					return col.r, col.g, col.b end)
				if okR and ((issecretvalue and issecretvalue(r)) or r ~= nil)
					then return r, g, b end
			end
		end
	end
end

local function ReactionColor(unit)
	local r = plain(UnitReaction(unit, "player"))
	local c = type(r) == "number" and REACTION_FALLBACK[math.floor(r)]
		or REACTION_FALLBACK[5]
	return c[1], c[2], c[3]
end

-- raw health values (possibly secret) into the StatusBar setters - each
-- call on its own so one rejected secret cannot kill the other. The
-- interpolation enum rides SetValue's second arg: the engine eases the
-- fill instead of snapping it (smoothBars).
-- shield sliver on the health bar: reads go straight into the StatusBar
-- setters so secret absorb amounts still scale engine-side
function Plate.Absorb(p, unit)
	local a = p.absorb
	if not a then return end
	local db = ns.Cfg()
	if db.absorbBar == false then a:Hide() return end
	local ok = pcall(function()
		local ab = UnitGetTotalAbsorbs(unit)
		a:SetMinMaxValues(0, UnitHealthMax(unit))
		a:SetValue(ab or 0)
	end)
	a:SetShown(ok)
end

local function hp_apply(p, unit)
	pcall(p.hp.SetMinMaxValues, p.hp, 0, UnitHealthMax(unit))
	local db = ns.Cfg()
	local interp = db.smoothBars ~= false
		and Enum and Enum.StatusBarInterpolation
		and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
	pcall(p.hp.SetValue, p.hp, UnitHealth(unit), interp)
	Plate.Absorb(p, unit)
end

-- health %: the engine percent API accepts secret values and still
-- returns a readable number; both calls stay inside pcall because even
-- comparing a secret to nil throws - fall back to plain math when absent
local function hp_text(p, unit)
	local scale = CurveConstants and CurveConstants.ScaleTo100
	local ok, v = UnitHealthPercent
		and pcall(UnitHealthPercent, unit, true, scale)
	local okS, s = ok and pcall(format, "%d%%", v)
	if okS and type(s) == "string" then
		p.hpText:SetText(s)
		return
	end
	-- secret numbers pass type() as "number" and issecretvalue does not flag
	-- them - only the compare throws, so the whole fallback math is pcall'd
	local okF, txt = pcall(function()
		local cur, max = plain(UnitHealth(unit)), plain(UnitHealthMax(unit))
		if type(cur) == "number" and type(max) == "number" and max > 0 then
			return math.floor(cur / max * 100 + 0.5) .. "%"
		end
		return ""
	end)
	p.hpText:SetText(okF and txt or "")
end

-- font strings do not clip text at their anchors: a name longer than the
-- space before the level field has to be cut down with "..." instead
local function FitName(p, name)
	if not pcall(function()
		if type(name) ~= "string" or name == "" then return end
		p.name:SetText(name)
		local w = p.name:GetStringWidth()
		if type(w) ~= "number" then return end
		local lw = (p.level:IsShown() and p.level:GetStringWidth()) or 0
		local avail = p.hpBox:GetWidth() - lw - 8
		while type(avail) == "number" and avail > 0 and w > avail and #name > 4 do
			name = name:sub(1, -2)
			p.name:SetText(name .. "…")
			w = p.name:GetStringWidth()
		end
	end) then pcall(p.name.SetText, p.name, name) end
end

-- "is this plate's unit the current target" - sticky against unreadable
-- reads: UnitIsUnit can come back secret/nil on this client, and a bare
-- "== true" would flicker the gold edge dark↔gold on every bad tick.
-- p._target keeps the last readable answer instead.
local function TargetFlag(p)
	local ok, v = pcall(UnitIsUnit, p.unit, "target")
	local pv = ok and plain(v)
	if pv == true then p._target = true
	elseif pv == false then p._target = false end
	return p._target == true
end

local function IsPlayerUnit(unit)
	local isP = plain(UnitIsPlayer(unit))
	if isP == nil then
		local guid = plain(UnitGUID(unit))
		if type(guid) == "string" then isP = guid:sub(1, 7) == "Player-" end
	end
	return isP
end

-- tapped by someone outside your group: no credit, painted grey like
-- the game's own plates (grey wins over threat/class/reaction)
local TAP_COLOR = { 0.45, 0.47, 0.53 }

local function Tapped(unit)
	if not (UnitIsTapDenied and ns.Cfg().tapGrey) then return false end
	if plain(UnitPlayerControlled(unit)) == true then return false end
	return plain(UnitIsTapDenied(unit)) == true
end

-- health fill: tapped > threat (attackable, in combat) > class (player)
-- > reaction
local function FillColor(p, unit)
	local db = ns.Cfg()
	if Tapped(unit) then return TAP_COLOR[1], TAP_COLOR[2], TAP_COLOR[3] end
	local attack = plain(UnitCanAttack(unit, "player"))
		or plain(UnitCanAttack("player", unit))
	-- unreadable (secret) must not block threat colors: only a plain
	-- "cannot attack" skips them
	if db.threat and attack ~= false then
		local key = ns.Threat.ColorKey(ns.Threat.State(unit))
		local c = key and THREAT_COLORS[key]
		if c then return c[1], c[2], c[3] end
	end
	if db.classColors and IsPlayerUnit(unit) == true then
		local r, g, b = ClassColor(unit)
		if r ~= nil then return r, g, b end
	end
	return ReactionColor(unit)
end

-- a 1px border that follows the rounded box silhouette: four edge strips
-- plus quarter arcs (the window accent-edge recipe) - the old square
-- BackdropTemplate edge was the pixelated look. box:SetEdgeColor recolors
-- the whole outline for the target highlight.
local EDGE_C = { r = 0.13, g = 0.16, b = 0.22 }
-- square 1px border: four straight strips, no corner arcs - the
-- rounded look rastered arcs that read as chevrons on thin bars
local function EdgeFrame(host, thick)
	thick = thick or 1
	local e = CreateFrame("Frame", nil, host)
	e:SetAllPoints()
	e:SetFrameLevel(host:GetFrameLevel() + 2)
	e.parts = {}
	local function tex()
		local t = e:CreateTexture(nil, "OVERLAY")
		t:SetTexture(BLANK)
		-- 1px strips on driver-scaled plates alias away when snapped to
		-- the pixel grid - let them rasterize freely instead
		if t.SetSnapToPixelGrid then pcall(t.SetSnapToPixelGrid, t, false) end
		e.parts[#e.parts + 1] = t
		return t
	end
	-- top and bottom own the corner pixels; the sides are inset by
	-- `thick` so no two strips share a pixel and z-fight at the corners
	local top = tex()
	top:SetPoint("TOPLEFT") top:SetPoint("TOPRIGHT") top:SetHeight(thick)
	local bottom = tex()
	bottom:SetPoint("BOTTOMLEFT") bottom:SetPoint("BOTTOMRIGHT")
	bottom:SetHeight(thick)
	local left = tex()
	left:SetPoint("TOPLEFT", 0, -thick) left:SetPoint("BOTTOMLEFT", 0, thick)
	left:SetWidth(thick)
	local right = tex()
	right:SetPoint("TOPRIGHT", 0, -thick) right:SetPoint("BOTTOMRIGHT", 0, thick)
	right:SetWidth(thick)
	return e
end

-- aggro ring colors keyed by the role-aware Threat.ColorKey:
-- bad  = mob is on you as dps / loose mob as tank - pulsing red
-- warn = about to pull - static orange
-- good = held/safe - no ring (the threat-colored fill already shows it)
local AGGRO_EDGE = {
	bad = { 0.95, 0.20, 0.22 },
	warn = { 0.98, 0.60, 0.15 },
}

local function UpdateAggro(p)
	local g = p.aggro
	if not g then return end
	local db = ns.Cfg()
	if not db.threat or p.friendly or not p.hpBox:IsShown() then
		g:SetScript("OnUpdate", nil)
		g:Hide()
		return
	end
	local key = ns.Threat.ColorKey(ns.Threat.State(p.unit))
	local c = key and AGGRO_EDGE[key]
	if not c then
		g:SetScript("OnUpdate", nil)
		g:Hide()
		return
	end
	for _, t in ipairs(g.parts) do
		t:SetVertexColor(c[1], c[2], c[3], 1)
	end
	if key == "bad" then
		-- soft pulse so "you have aggro" pops out of a pack of plates;
		-- OnUpdate stops on its own when the frame hides
		g:SetScript("OnUpdate", function(self, dt)
			self._t = (self._t or 0) + dt
			local a = 0.45 + 0.55 * math.abs(math.sin(self._t * 6))
			for _, t in ipairs(self.parts) do t:SetAlpha(a) end
		end)
	else
		g:SetScript("OnUpdate", nil)
		for _, t in ipairs(g.parts) do t:SetAlpha(0.9) end
	end
	g:Show()
end

-- factory ----------------------------------------------------------------------
function Plate.Create(parent)
	local p = CreateFrame("Frame", nil, parent)
	p:EnableMouse(false)

	-- health bar box: flat square panel + square 1px edge
	local box = CreateFrame("Frame", nil, p)
	local boxBg = box:CreateTexture(nil, "BACKGROUND")
	boxBg:SetAllPoints()
	boxBg:SetColorTexture(0.03, 0.035, 0.05, 0.9)
	box.edge = EdgeFrame(box)
	function box:SetEdgeColor(r, g, b, a)
		self.edge._col = { r, g, b, a or 1 }
		for _, t in ipairs(self.edge.parts) do
			t:SetVertexColor(r, g, b, a or 1)
		end
	end
	box:SetEdgeColor(EDGE_C.r, EDGE_C.g, EDGE_C.b, 1)
	p.hpBox = box

	-- aggro effect ring: a second edge fully OUTSIDE the box silhouette
	-- (-2px ring, 2px strips) so it never covers the gold target edge
	local aggro = EdgeFrame(box, 2)
	aggro:ClearAllPoints()
	aggro:SetPoint("TOPLEFT", box, "TOPLEFT", -2, 2)
	aggro:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", 2, -2)
	aggro:SetFrameLevel(box:GetFrameLevel() + 4)
	aggro:Hide()
	p.aggro = aggro

	local hp = CreateFrame("StatusBar", nil, box)
	hp:SetPoint("TOPLEFT", 1, -1)
	hp:SetPoint("BOTTOMRIGHT", -1, 1)
	hp:SetStatusBarTexture(BLANK)
	hp:SetMinMaxValues(0, 1)
	hp:SetValue(1)
	-- suite look: darker unfilled area + the top-fade gloss the other
	-- SentiUI bars carry (unit frames use the same recipe)
	local hpBg = hp:CreateTexture(nil, "BACKGROUND")
	hpBg:SetAllPoints()
	hpBg:SetColorTexture(0, 0, 0, 0.55)
	local hpGloss = hp:CreateTexture(nil, "OVERLAY")
	hpGloss:SetAllPoints()
	hpGloss:SetTexture(BLANK)
	if CreateColor then
		hpGloss:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.18), CreateColor(1, 1, 1, 0))
	end
	p.hp = hp

	-- absorb sliver: thin bar across the top of the fill showing the
	-- shield amount; a StatusBar so secret values scale engine-side
	local absorb = CreateFrame("StatusBar", nil, hp)
	absorb:SetPoint("TOPLEFT", 0, 0)
	absorb:SetPoint("TOPRIGHT", 0, 0)
	absorb:SetHeight(2)
	absorb:SetStatusBarTexture(BLANK)
	absorb:SetStatusBarColor(0.85, 0.80, 0.55, 0.9)
	absorb:SetMinMaxValues(0, 1)
	absorb:SetValue(0)
	absorb:Hide()
	p.absorb = absorb

	-- parented to the bar so it draws over the gloss overlay, not under it
	p.hpText = S.Font(hp, 9, nil, "OUTLINE")
	p.hpText:SetDrawLayer("OVERLAY", 2)
	p.hpText:SetPoint("RIGHT", hp, "RIGHT", -3, 0)
	p.hpText:SetJustifyH("RIGHT")

	p.name = S.Font(p, 11, nil, "OUTLINE")
	p.name:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 1, 2)
	p.name:SetJustifyH("LEFT")
	p.name:SetWordWrap(false)

	p.level = S.Font(p, 10, S.colors.textDim, "OUTLINE")
	p.level:SetPoint("BOTTOMRIGHT", box, "TOPRIGHT", -1, 2)
	p.level:SetJustifyH("RIGHT")
	p.level:SetWordWrap(false)

	p.elite = S.Font(p, 10, ACC, "OUTLINE")
	p.elite:SetPoint("RIGHT", p.level, "LEFT", -4, 0)
	p.elite:SetJustifyH("RIGHT")

	-- quest-mob mark: gold "!" hanging off the box's left edge
	p.quest = S.Font(p, 12, ACC, "OUTLINE")
	p.quest:SetPoint("RIGHT", box, "LEFT", -3, 1)
	p.quest:SetText("!")
	p.quest:Hide()

	-- raid target icon: classic overhead spot - centered above the name,
	-- not beside it (beside-the-name was unreadable on this plate scale)
	p.raidIcon = p:CreateTexture(nil, "OVERLAY")
	p.raidIcon:SetSize(18, 18)
	p.raidIcon:SetPoint("BOTTOM", box, "TOP", 0, 16)

	-- skull glyph for "??"-level bosses (media replaces the ?? text)
	local skull = S.Tex and S.Tex("BossSkull")
	if skull then
		p.bossSkull = p:CreateTexture(nil, "OVERLAY")
		p.bossSkull:SetTexture(skull)
		p.bossSkull:SetSize(14, 14)
		p.bossSkull:SetPoint("BOTTOMRIGHT", box, "TOPRIGHT", -1, 2)
		p.bossSkull:Hide()
	end

	-- cast bar box under the health bar - same flat square panel + edge
	local cbox = CreateFrame("Frame", nil, p)
	local cboxBg = cbox:CreateTexture(nil, "BACKGROUND")
	cboxBg:SetAllPoints()
	cboxBg:SetColorTexture(0.03, 0.035, 0.05, 0.9)
	cbox.edge = EdgeFrame(cbox)
	for _, t in ipairs(cbox.edge.parts) do
		t:SetVertexColor(EDGE_C.r, EDGE_C.g, EDGE_C.b, 1)
	end
	p.castBox = cbox

	p.castIcon = cbox:CreateTexture(nil, "ARTWORK")
	p.castIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local cast = CreateFrame("StatusBar", nil, cbox)
	cast:SetStatusBarTexture(BLANK)
	cast:SetStatusBarColor(ACC.r, ACC.g, ACC.b)
	local castBg = cast:CreateTexture(nil, "BACKGROUND")
	castBg:SetAllPoints()
	castBg:SetColorTexture(0, 0, 0, 0.55)
	local castGloss = cast:CreateTexture(nil, "OVERLAY")
	castGloss:SetAllPoints()
	castGloss:SetTexture(BLANK)
	if CreateColor then
		castGloss:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.16), CreateColor(1, 1, 1, 0))
	end
	p.cast = cast

	-- spark riding the fill's right edge; same recipe as the unit-frame
	-- cast bar, anchored to the statusbar texture so it follows the fill
	local spark = cast:CreateTexture(nil, "OVERLAY", nil, 3)
	local sparkTex = S.Tex and S.Tex("BarSpark")
	if sparkTex then
		spark:SetTexture(sparkTex)
		spark:SetSize(8, 16)
	else
		spark:SetTexture(BLANK)
		spark:SetSize(2, 12)
	end
	spark:SetVertexColor(1, 0.88, 0.55, 0.9)
	spark:SetBlendMode("ADD")
	spark:SetPoint("CENTER", cast:GetStatusBarTexture(), "RIGHT")

	p.castText = S.Font(cast, 9, nil, "OUTLINE")
	p.castText:SetDrawLayer("OVERLAY", 2)
	p.castText:SetJustifyH("LEFT")

	-- remaining cast time, right aligned inside the bar
	p.castTime = S.Font(cast, 8, S.colors.textDim, "OUTLINE")
	p.castTime:SetDrawLayer("OVERLAY", 2)
	p.castTime:SetJustifyH("RIGHT")
	cast.timeText = p.castTime -- read by Cast.lua's fill drivers

	-- end-of-cast flash on the cast box: full-bar overlay Cast.lua
	-- recolors (gold = finished, red = interrupted) and fades out
	p.castFlash = cast:CreateTexture(nil, "OVERLAY", nil, 3)
	p.castFlash:SetAllPoints()
	p.castFlash:SetTexture(BLANK)
	p.castFlash:SetBlendMode("ADD")
	p.castFlash:Hide()

	-- uninterruptible badge on the cast icon, like the unit-frame shield
	p.castShield = cbox:CreateTexture(nil, "OVERLAY", nil, 2)
	p.castShield:SetTexture((S.Tex and S.Tex("CastShield"))
		or "Interface\\Icons\\Spell_Holy_DevotionAura")
	p.castShield:SetSize(11, 11)
	p.castShield:SetPoint("CENTER", p.castIcon, "CENTER", 0, 0)
	p.castShield:Hide()

	p:Hide()
	return p
end

-- per-setting layout ------------------------------------------------------------
function Plate.Layout(p)
	local db = ns.Cfg()
	local w, h = db.width or 130, db.barHeight or 11
	p:SetScale(db.scale or 1)

	local friendlyNameOnly = p.friendly and db.friendlyNameOnly
	p.name:ClearAllPoints()
	if friendlyNameOnly then
		p.name:SetPoint("BOTTOM", p, "TOP", 0, -6)
		p.name:SetJustifyH("CENTER")
	else
		p.name:SetPoint("BOTTOMLEFT", p.hpBox, "TOPLEFT", 1, 2)
		-- clip the name before the level field instead of running into it
		p.name:SetPoint("RIGHT", p.level, "LEFT", -4, 0)
		p.name:SetJustifyH("LEFT")
	end

	p.hpBox:ClearAllPoints()
	p.hpBox:SetPoint("CENTER", p, "CENTER", 0, 0)
	p.hpBox:SetSize(w, h)
	p.hpBox:SetShown(not friendlyNameOnly)
	p.level:SetShown(db.showLevel and not friendlyNameOnly)
	p.elite:SetShown(false)

	p.castBox:ClearAllPoints()
	p.castBox:SetPoint("TOP", p.hpBox, "BOTTOM", 0, -1)
	local iconW = (db.castBar and db.castIcon) and db.castHeight or 0
	p.castBox:SetSize(w + iconW, db.castHeight or 12)
	p.castIcon:SetSize(db.castHeight or 12, db.castHeight or 12)
	p.castIcon:ClearAllPoints()
	p.castIcon:SetPoint("TOPLEFT", p.castBox, "TOPLEFT", 1, -1)
	p.castIcon:SetShown(iconW > 0)
	p.cast:ClearAllPoints()
	p.cast:SetPoint("TOPLEFT", p.castBox, "TOPLEFT", 1 + iconW, -1)
	p.cast:SetPoint("BOTTOMRIGHT", p.castBox, "BOTTOMRIGHT", -1, 1)
	p.castText:ClearAllPoints()
	p.castText:SetPoint("LEFT", p.cast, "LEFT", 3, 0)
	-- the timer claims the last ~20 px of the bar
	p.castText:SetPoint("RIGHT", p.cast, "RIGHT", -24, 0)
	p.castTime:ClearAllPoints()
	p.castTime:SetPoint("RIGHT", p.cast, "RIGHT", -3, 0)
	p.castBox:SetShown(false)

	p.hpText:SetShown(db.healthText and not friendlyNameOnly)

	-- debuff icons come from the engine aura container (Auras.lua) - no
	-- per-plate icon frames needed here
	local total = math.max(h + (db.castHeight or 12) + 8, 20)
	p:SetSize(w, total)
end

-- per-unit paint ----------------------------------------------------------------
local ELITE_LABELS = {
	worldboss = "Boss", rareelite = "Rare elite",
	rare = "Rare", elite = "Elite",
}

function Plate.Update(p)
	local db = ns.Cfg()
	local unit = p.unit
	if not unit or plain(UnitExists(unit)) ~= true then p:Hide() return end
	p:Show()

		-- friendly handling
	local attack = plain(UnitCanAttack("player", unit))
		or plain(UnitCanAttack(unit, "player"))
	p.friendly = attack ~= true
	p.attack = attack
	if p.friendly and not db.friendlyBars then p:Hide() return end
	Plate.Layout(p)
	UpdateAggro(p) -- also clears the ring on friendly plates
	if p.friendly and db.friendlyNameOnly then
		p.hpBox:Hide()
		-- name (+ guild) as the whole plate
		local okN, name = pcall(GetUnitName, unit, true)
		name = okN and name or select(2, pcall(UnitName, unit))
		pcall(p.name.SetText, p.name, name)
		local r, g, b = ClassColor(unit)
		if r ~= nil then pcall(p.name.SetTextColor, p.name, r, g, b, 1)
		else p.name:SetTextColor(0.55, 0.57, 0.64) end
		ns.Cast.Stop(p)
		ns.Auras.Clear(p)
		p.raidIcon:Hide()
		p.elite:Hide()
		return
	end

	-- name
	local okN, name = pcall(GetUnitName, unit, true)
	name = okN and name or select(2, pcall(UnitName, unit))
	FitName(p, name)

	-- current target reads gold on both the edge ring and the name so the
	-- focus plate pops out of the pack; reused for the edge below
	local isTarget = db.targetHighlight and TargetFlag(p)

	-- name color: target accent > tapped grey > player class > white
	if isTarget then
		p.name:SetTextColor(ACC.r, ACC.g, ACC.b)
	elseif Tapped(unit) then
		p.name:SetTextColor(TAP_COLOR[1], TAP_COLOR[2], TAP_COLOR[3])
	elseif db.classColors and IsPlayerUnit(unit) == true then
		local r, g, b = ClassColor(unit)
		if r ~= nil then pcall(p.name.SetTextColor, p.name, r, g, b, 1)
		else p.name:SetTextColor(1, 1, 1) end
	else
		p.name:SetTextColor(1, 1, 1)
	end

	-- level - "lvl <= 0" on a secret level throws, so compare inside pcall;
	-- colored by difficulty like the game's own target frame (red above
	-- you, yellow at level, gray only when truly trivial)
	if db.showLevel then
		local okL, txt, lvl = pcall(function()
			local l = plain(UnitLevel(unit))
			if type(l) ~= "number" then return "" end
			return (l <= 0 and "??" or l), l
		end)
		local boss = okL and type(lvl) == "number" and lvl <= 0
		if p.bossSkull then
			p.bossSkull:SetShown(boss == true)
			p.level:SetShown(not boss)
		end
		p.level:SetText(boss and "" or (okL and txt or ""))
		local c = okL and S.LevelColor(unit, lvl)
		if c then
			pcall(p.level.SetTextColor, p.level, c.r, c.g, c.b, 1)
		else
			p.level:SetTextColor(0.55, 0.57, 0.64)
		end
	end

	-- elite/rare badge
	if db.eliteMarker then
		local cls = plain(UnitClassification(unit))
		local key = ELITE_LABELS[cls]
		if key then
			p.elite:SetText(L[key])
			p.elite:Show()
		else p.elite:Hide() end
	end

	-- quest-mob mark: unit name inside an unfinished objective line
	if p.quest then
		p.quest:SetShown(db.questMark ~= false and not p.friendly
			and ns.Quest.IsQuestMob(unit))
	end

	-- health values may be secret - straight into the setters
	hp_apply(p, unit)

	if db.healthText then hp_text(p, unit) end

	-- fill color
	local fr, fg, fb = FillColor(p, unit)
	if fr ~= nil then pcall(p.hp.SetStatusBarColor, p.hp, fr, fg, fb) end

	-- target accent border: square edge goes Sentinel gold
	if isTarget then
		p.hpBox:SetEdgeColor(ACC.r, ACC.g, ACC.b, 1)
	else
		p.hpBox:SetEdgeColor(EDGE_C.r, EDGE_C.g, EDGE_C.b, 1)
	end

	-- raid target icon
	if db.raidIcon then
		local idx = plain(GetRaidTargetIndex, unit)
		if type(idx) == "number" and idx >= 1 and idx <= 8 then
			p.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. idx)
			p.raidIcon:Show()
		else p.raidIcon:Hide() end
	end

	ns.Auras.Update(p)
end

-- the volatile slice of Update: health values + fill + target border. The
-- 0.25s ticker runs this because health and threat events are unreliable
-- for nameplate units on this client.
function Plate.RefreshColors(p)
	local db = ns.Cfg()
	if not p.unit or p.friendly or not p.hpBox:IsShown() then return end
	hp_apply(p, p.unit)
	if db.healthText then hp_text(p, p.unit) end
	local fr, fg, fb = FillColor(p, p.unit)
	if fr ~= nil then pcall(p.hp.SetStatusBarColor, p.hp, fr, fg, fb) end
	local isTarget = db.targetHighlight and TargetFlag(p)
	if isTarget then
		p.hpBox:SetEdgeColor(ACC.r, ACC.g, ACC.b, 1)
	else
		p.hpBox:SetEdgeColor(EDGE_C.r, EDGE_C.g, EDGE_C.b, 1)
	end
	UpdateAggro(p)
end
