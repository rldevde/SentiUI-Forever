-- In-world way marker for the tracked quest. The client keeps one frame
-- (C_Navigation.GetFrame()) at the screen position of whatever is super
-- tracked - a quest, a waypoint, a corpse - and reports the distance plus
-- whether the spot is off-screen (the engine already clamps the frame to
-- the screen edge and rotates its Arrow).
--
-- The game's own pieces (Icon, IconBorder, DistanceText) are dimmed to
-- alpha 0 and ours ride on the same frame: a gold diamond on the spot
-- with the distance under it. Off-screen the engine's Arrow does the
-- pointing, tinted accent - the engine rotates it correctly, so no
-- rotation math is needed. A separate watcher frame does the ticking:
-- script handlers must never be assigned on engine-owned frames.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Nav = {}
ns.Nav = Nav

local db
local watcher, last
local diamond, glow, dist

local ACC = S.colors.accent
local DIM = { "Icon", "IconBorder", "DistanceText" } -- engine pieces we hide

local function NavFrame()
	if not (C_Navigation and C_Navigation.GetFrame) then return end
	local ok, f = pcall(C_Navigation.GetFrame)
	if ok and f then return f end
end

-- our pieces live on the engine frame so they inherit its position
local function Attach(f)
	if last == f then return end
	Nav.Restore()
	last = f
	for _, k in ipairs(DIM) do
		local p = f[k]
		if p and p.SetAlpha then pcall(p.SetAlpha, p, 0) end
	end
	if not glow then
		glow = f:CreateTexture(nil, "BACKGROUND")
		glow:SetTexture("Interface\\AddOns\\SentiUI_Quests\\Media\\NavDot")
		glow:SetSize(38, 38)
		glow:SetVertexColor(1, 1, 1, 0.55)
		diamond = f:CreateTexture(nil, "ARTWORK")
		diamond:SetTexture("Interface\\AddOns\\SentiUI_Quests\\Media\\NavMarker")
		diamond:SetSize(22, 22)
		dist = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		dist:SetFont(S.media.font, 10, "OUTLINE")
		dist:SetTextColor(1, 1, 1)
	else
		glow:SetParent(f)
		diamond:SetParent(f)
		dist:SetParent(f)
	end
	glow:SetPoint("CENTER", f, "CENTER", 0, 0)
	diamond:SetPoint("CENTER", f, "CENTER", 0, 0)
	dist:SetPoint("TOP", f, "BOTTOM", 0, -3)
end

-- direction trail: small diamonds sprinkled along the screen line from
-- the player (screen center) toward the marker, drifting to the target.
-- The nav frame's position is engine-owned - if GetCenter comes back
-- secret/unreadable the trail just stays off. Declared before Restore:
-- Restore calls HideTrail, so the local must be in scope already
local trail = {}
local TRAIL_MAX = 14
local seg -- cached endpoints: { sx,sy,ex,ey, ang, n }
local trailOK -- Tick decides per state whether the trail may run at all

local function HideTrail()
	seg = nil
	trailOK = false
	for i = 1, #trail do trail[i]:Hide() end
end

-- real atan2: math.atan on this client takes ONE argument (the slope),
-- so the two-arg call just returned atan(dy) - every chevron ended up
-- pointing straight up. Do the quadrant fix ourselves
local function AngleOf(dx, dy)
	if math.abs(dx) < 0.001 then
		return dy >= 0 and math.pi / 2 or -math.pi / 2
	end
	local a = math.atan(dy / dx)
	if dx < 0 then a = a + math.pi end
	return a
end

-- Tick computes the segment once per 0.1 s; Animate repositions the
-- chevrons every frame so the march is smooth, not stepped
-- GetCenter answers in the frame's OWN scale space - if the engine
-- scales the nav frame, every point is off by that factor and the aim
-- drifts a few millimetres. Physical px = coord x scale; convert to
-- UIParent space (physical / uiScale) so both ends share one space
local function Center(f)
	local ok, x, y = pcall(f.GetCenter, f)
	if not ok or type(x) ~= "number" or type(y) ~= "number" then return end
	local okS, es = pcall(f.GetEffectiveScale, f)
	local okU, us = pcall(UIParent.GetEffectiveScale, UIParent)
	local k = (okS and type(es) == "number" and es) or 1
	local u = (okU and type(us) == "number" and us ~= 0 and us) or 1
	return x * k / u, y * k / u
end

local function Trail(f)
	local tx, ty = Center(f)
	if not tx then HideTrail() return end
	local cx, cy = Center(UIParent)
	if not cx then HideTrail() return end
	local dx, dy = tx - cx, ty - cy
	local len = math.sqrt(dx * dx + dy * dy)
	if len < 70 then HideTrail() return end
	-- the end stops a fixed ~22 px short of the marker whatever the
	-- distance, so chevrons can never visually overshoot the diamond
	local ef = math.max(0.2, 1 - 22 / len)
	seg = {
		sx = cx + dx * 0.14, sy = cy + dy * 0.14,
		ex = cx + dx * ef, ey = cy + dy * ef,
		ang = AngleOf(dx, dy),
		n = math.max(3, math.min(TRAIL_MAX, math.floor(len / 36))),
	}
end

local function Animate()
	if not seg then return end
	local drift = (GetTime() * 0.28) % 1
	for i = 1, TRAIL_MAX do
		local d = trail[i]
		if i <= seg.n then
			if not d then
				d = UIParent:CreateTexture(nil, "OVERLAY")
				d:SetTexture("Interface\\AddOns\\SentiUI_Quests\\Media\\NavChevron")
				trail[i] = d
			end
			local frac = ((i - 1) / seg.n + drift) % 1
			-- fade in near the player, fade OUT before the marker - no
			-- chevron ever appears past the target, and the wrap from
			-- end to start happens at alpha 0 so it can't be seen
			local env = math.min(frac / 0.12, 1)
				* math.min((1 - frac) / 0.10, 1)
			local s = 8 + frac * 6
			d:SetRotation(seg.ang)
			d:SetSize(s, s)
			d:ClearAllPoints()
			d:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
				seg.sx + (seg.ex - seg.sx) * frac,
				seg.sy + (seg.ey - seg.sy) * frac)
			d:SetAlpha((0.15 + frac * 0.75) * env)
			d:Show()
		elseif d then
			d:Hide()
		end
	end
end

function Nav.Restore()
	-- put the engine's pieces back and remove ours; called when the nav
	-- frame changes owner or the option goes off
	local f = last or NavFrame()
	if f then
		for _, k in ipairs(DIM) do
			local p = f[k]
			if p and p.SetAlpha then pcall(p.SetAlpha, p, 1) end
		end
		local a = f.Arrow
		if a then
			pcall(a.SetAlpha, a, 1)
			pcall(a.SetVertexColor, a, 1, 1, 1)
		end
	end
	last = nil
	if glow then glow:Hide() end
	if diamond then diamond:Hide() end
	if dist then dist:Hide() end
	HideTrail()
end

local function HideOurs()
	if glow then glow:Hide() end
	if diamond then diamond:Hide() end
	if dist then dist:Hide() end
	HideTrail()
end

local function Tick()
	local f = NavFrame()
	if not f then
		-- nothing tracked right now
		Nav.Restore()
		return
	end
	Attach(f)
	if not f:IsShown() then
		HideOurs()
		return
	end
	local clamped
	if C_Navigation.WasClampedToScreen then
		local ok, c = pcall(C_Navigation.WasClampedToScreen)
		clamped = ok and (c == true or S.IsSecret(c))
	end
	local arrow = f.Arrow
	if clamped then
		-- off-screen: the engine's Arrow points the way - accent-tinted
		HideOurs()
		if arrow then
			pcall(arrow.SetAlpha, arrow, 1)
			pcall(arrow.SetVertexColor, arrow, ACC.r, ACC.g, ACC.b)
		end
	else
		-- arrived: the engine keeps the frame parked on the last spot even
		-- at distance ~0 - hide our pieces (and the arrow) once reached
		local arrived
		if C_Navigation.GetDistance then
			local okA, dA = pcall(C_Navigation.GetDistance)
			arrived = okA and type(dA) == "number" and dA <= 2
		end
		if arrived then
			HideOurs()
			if arrow then pcall(arrow.SetAlpha, arrow, 0) end
			return
		end
		if glow then glow:Show() end
		if diamond then diamond:Show() end
		if arrow then pcall(arrow.SetAlpha, arrow, 0) end
		if dist then
			local okD, d = pcall(C_Navigation.GetDistance)
			if okD and d ~= nil then
				local shown = pcall(dist.SetFormattedText, dist, "%.0f", d)
				dist:SetShown(shown)
			else
				dist:Hide()
			end
		end
		Trail(f)
		trailOK = true
	end
end

-- /sqnav reports which navigation APIs this client actually has
SLASH_SENTIUINAV1 = "/sqnav"
SlashCmdList.SENTIUINAV = function()
	local function has(t, k) return (t and t[k]) and "|cff2ed97eyes|r" or "|cffff4040no|r" end
	print("|cffebad33Nav APIs:|r")
	print(" C_Navigation.GetFrame: " .. has(C_Navigation, "GetFrame"))
	print(" C_Navigation.GetDistance: " .. has(C_Navigation, "GetDistance"))
	print(" C_Navigation.WasClampedToScreen: " .. has(C_Navigation, "WasClampedToScreen"))
	print(" C_SuperTrack.SetSuperTrackedQuestID: " .. has(C_SuperTrack, "SetSuperTrackedQuestID"))
	print(" C_SuperTrack.SetSuperTrackedQuest: " .. has(C_SuperTrack, "SetSuperTrackedQuest"))
	print(" C_QuestLog.GetNextWaypoint: " .. has(C_QuestLog, "GetNextWaypoint"))
	print(" C_QuestLog.GetQuestsOnMap: " .. has(C_QuestLog, "GetQuestsOnMap"))
	print(" C_Map.SetUserWaypoint: " .. has(C_Map, "SetUserWaypoint"))
	print(" UiMapPoint.CreateFromCoordinates: " .. has(UiMapPoint, "CreateFromCoordinates"))
	local f = NavFrame()
	if f then
		local ok, x = pcall(f.GetCenter, f)
		print(" nav frame GetCenter readable: " ..
			((ok and type(x) == "number") and "|cff2ed97eyes|r" or "|cffff4040no|r"))
	else
		print(" nav frame: none right now (nothing tracked)")
	end
end

function Nav.SetDb(d) db = d end

function Nav.Apply()
	if not watcher then watcher = CreateFrame("Frame") end
	local on = db and db.nav ~= false
		and C_Navigation and C_Navigation.GetFrame
	if not on then
		watcher:SetScript("OnUpdate", nil)
		Nav.Restore()
		return
	end
	local acc = 0
	watcher:SetScript("OnUpdate", function(_, dt)
		-- refresh the segment every frame (cheap math, the marker moves
		-- fast at short range) - a stale segment is what let chevrons
		-- slide past the live marker position
		if trailOK and last then Trail(last) end
		Animate()
		acc = acc + (dt or 0.016)
		if acc < 0.1 then return end
		acc = 0
		S.SafeCall("nav:tick", Tick)
	end)
end
