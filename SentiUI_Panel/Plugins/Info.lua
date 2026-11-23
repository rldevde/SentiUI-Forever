-- Info plugins: clock, location, performance, played, session, speed,
-- volume, calendar events and minimap tracking.
local _, ns = ...
local S = SentiUI
local L = ns.L
local P = ns.Plugins
local Plain = ns.Plain
local TipHead, TipKV, TipSub = ns.TipHead, ns.TipKV, ns.TipSub
local SecureAPI = ns.SecureAPI
local format, floor = string.format, math.floor
local date = date

local AH = "|cff" .. ns.accentHex
local DH = "|cff" .. ns.dimHex

-- Clock -------------------------------------------------------------------------
ns.RegisterPlugin({
	id = "clock",
	label = L["Clock"],
	icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	bar = "bottom", zone = "CENTER", order = 10,
	update = function(def)
		local fmt = P.Opt(def, "seconds") and "%H:%M:%S" or "%H:%M"
		return AH .. date(fmt) .. "|r"
	end,
	tooltip = function(tip)
		TipHead(tip, L["Clock"])
		TipKV(tip, L["Local time"], date("%H:%M:%S"))
		local h, m = GetGameTime()
		TipKV(tip, L["Server time"], format("%02d:%02d", Plain(h) or 0, Plain(m) or 0))
		TipKV(tip, L["Date"], date("%A, %d.%m.%Y"))
	end,
	secureClick = { "GameTimeFrame" },
	click = function() if ToggleCalendar then SecureAPI(ToggleCalendar) end end,
	menu = function(def, items)
		items[#items + 1] = {
			text = L["Show seconds"], checked = P.Opt(def, "seconds"), noClose = true,
			onClick = function()
				P.SetOpt(def, "seconds", not P.Opt(def, "seconds"))
				def.last = nil
				P.UpdateOne(def)
			end,
		}
		items[#items + 1] = { text = L["Stopwatch"], isTitle = true }
		for _, mins in ipairs({ 5, 10, 25 }) do
			items[#items + 1] = {
				text = format(L["%d min"], mins),
				onClick = function()
					if Stopwatch_StartCountdown then
						SecureAPI(Stopwatch_StartCountdown, mins * 60)
						if Stopwatch_Play then SecureAPI(Stopwatch_Play) end
					end
				end,
			}
		end
	end,
})

-- Location ----------------------------------------------------------------------
local function ZoneText()
	local ok, z = pcall(GetZoneText)
	return ok and Plain(z) or nil
end

local function SubZoneText()
	local ok, s = pcall(GetSubZoneText)
	return ok and Plain(s) or nil
end

-- zone text color by PvP type, like Blizzard's zone text
local PVP_COLORS = {
	friendly = "55ff55", hostile = "ff5555", contested = "ffcc33",
	sanctuary = "66ccff", arena = "ff5555",
}

local function PvPType()
	local ok, t = pcall(GetZonePVPInfo)
	return ok and Plain(t) or nil
end

local function IsRestingNow()
	local ok, r = pcall(IsResting)
	return ok and Plain(r) or false
end

local function Coords()
	if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
	local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
	mapID = ok and Plain(mapID)
	if not mapID then return end
	local ok2, pos = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
	if not ok2 or not ns.CanAccess(pos) then return end
	local x, y = Plain(pos.x), Plain(pos.y)
	if x and y then return x * 100, y * 100 end
end
ns.PanelCoords = Coords

ns.RegisterPlugin({
	id = "location",
	label = L["Location"],
	icon = "Interface\\Icons\\INV_Misc_Map_01",
	bar = "bottom", zone = "LEFT", order = 10,
	shown = false,
	events = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA",
		"PLAYER_UPDATE_RESTING", "PLAYER_ENTERING_WORLD" },
	update = function(def)
		local zone = ZoneText() or "?"
		local color = PVP_COLORS[PvPType()] or ns.accentHex
		local parts = { "|cff" .. color .. zone .. "|r" }
		if P.Opt(def, "subzone") ~= false then
			local sub = SubZoneText()
			if sub and sub ~= "" and sub ~= zone then
				parts[#parts + 1] = DH .. sub .. "|r"
			end
		end
		if P.Opt(def, "coords") ~= false then
			local x, y = Coords()
			if x then parts[#parts + 1] = format("%.1f, %.1f", x, y) end
		end
		if IsRestingNow() then
			parts[#parts + 1] = "|cff8f8fff(zzz)|r"
		end
		return table.concat(parts, "  ")
	end,
	tooltip = function(tip)
		TipHead(tip, L["Location"])
		TipKV(tip, L["Zone"], ZoneText() or "-")
		local sub = SubZoneText()
		if sub and sub ~= "" then TipKV(tip, L["Subzone"], sub) end
		local x, y = Coords()
		if x then TipKV(tip, L["Coordinates"], format("%.1f, %.1f", x, y)) end
		local pvp = PvPType()
		if pvp then TipKV(tip, L["PvP type"], L[pvp] or pvp) end
		TipKV(tip, L["Resting"], IsRestingNow() and L["Yes"] or L["No"])
		local okInst, inside = pcall(IsInInstance)
		if okInst and Plain(inside) and GetInstanceInfo then
			local okI, name, _, diffID, diffName = pcall(GetInstanceInfo)
			if okI and Plain(name) then
				TipKV(tip, L["Instance"], format("%s (%s)", name, Plain(diffName) or Plain(diffID) or ""))
			end
		end
	end,
	menu = function(def, items)
		items[#items + 1] = {
			text = L["Show coordinates"], checked = P.Opt(def, "coords") ~= false, noClose = true,
			onClick = function()
				P.SetOpt(def, "coords", P.Opt(def, "coords") == false)
				def.last = nil
				P.UpdateOne(def)
			end,
		}
		items[#items + 1] = {
			text = L["Show subzone"], checked = P.Opt(def, "subzone") ~= false, noClose = true,
			onClick = function()
				P.SetOpt(def, "subzone", P.Opt(def, "subzone") == false)
				def.last = nil
				P.UpdateOne(def)
			end,
		}
	end,
})

-- Performance ---------------------------------------------------------------------
local function Latency()
	local ok, _, _, home, world = pcall(GetNetStats)
	if not ok then return nil end
	return Plain(world) or Plain(home)
end

-- total addon memory (KB) plus the heaviest addons, for the tooltip
local function AddonMemory()
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

ns.RegisterPlugin({
	id = "performance",
	label = L["Performance"],
	icon = "Interface\\Icons\\INV_Misc_Gear_01",
	-- the readout lives as an icon on the minimap now; the bar entry
	-- stays available but off on fresh profiles
	shown = false,
	bar = "bottom", zone = "RIGHT", order = 10,
	update = function(def)
		local parts = {}
		if P.Opt(def, "fps") ~= false then
			parts[#parts + 1] = format("%s%d|r fps", AH, floor(GetFramerate() or 0))
		end
		if P.Opt(def, "latency") ~= false then
			parts[#parts + 1] = format("%s%d|r ms", AH, Latency() or 0)
		end
		return table.concat(parts, "  ")
	end,
	tooltip = function(tip)
		local ok, _, _, home, world = pcall(GetNetStats)
		TipHead(tip, L["Performance"])
		if ok then
			TipKV(tip, L["Home latency"], format("%d ms", Plain(home) or 0))
			TipKV(tip, L["World latency"], format("%d ms", Plain(world) or 0))
		end
		TipKV(tip, L["Framerate"], format("%d", floor(GetFramerate() or 0)))
		local mem, top = AddonMemory()
		if mem then
			TipKV(tip, L["Addon memory"], format("%.1f MB", mem / 1024))
			if top and #top > 0 then
				TipSub(tip, L["Top addons"])
				for i = 1, math.min(#top, 5) do
					tip:AddDoubleLine("  " .. top[i].name, format("%.1f MB", top[i].kb / 1024), 1, 1, 1, 1, 1, 1)
				end
			end
		end
	end,
	menu = function(def, items)
		items[#items + 1] = {
			text = L["Show FPS"], checked = P.Opt(def, "fps") ~= false, noClose = true,
			onClick = function()
				P.SetOpt(def, "fps", P.Opt(def, "fps") == false)
				def.last = nil
				P.UpdateOne(def)
			end,
		}
		items[#items + 1] = {
			text = L["Show latency"], checked = P.Opt(def, "latency") ~= false, noClose = true,
			onClick = function()
				P.SetOpt(def, "latency", P.Opt(def, "latency") == false)
				def.last = nil
				P.UpdateOne(def)
			end,
		}
	end,
})

-- Played ---------------------------------------------------------------------------
local function FmtPlayed(sec)
	sec = Plain(sec)
	if not sec then return nil end
	local d = floor(sec / 86400)
	local h = floor((sec % 86400) / 3600)
	local m = floor((sec % 3600) / 60)
	if d > 0 then return format("%dd %dh", d, h) end
	if h > 0 then return format("%dh %dm", h, m) end
	return format("%dm", m)
end

ns.RegisterPlugin({
	id = "played",
	label = L["Played"],
	icon = "Interface\\Icons\\Spell_Holy_BorrowedTime",
	bar = "top", zone = "RIGHT", order = 10,
	events = { "TIME_PLAYED_MSG", "PLAYER_ENTERING_WORLD" },
	onevent = function(def, event, ...)
		if event ~= "TIME_PLAYED_MSG" then return end
		local total, levelTime = ...
		def.total, def.levelTime = Plain(total), Plain(levelTime)
		ns.db.played = { total = def.total, levelTime = def.levelTime }
	end,
	update = function(def)
		def.total = def.total or (ns.db.played and ns.db.played.total)
		def.levelTime = def.levelTime or (ns.db.played and ns.db.played.levelTime)
		local t = FmtPlayed(def.total)
		return t and AH .. t .. "|r" or ""
	end,
	tooltip = function(tip)
		TipHead(tip, L["Played"])
		local def = P.byId.played
		TipKV(tip, L["Total played"], FmtPlayed(def and def.total) or "-")
		TipKV(tip, L["This level"], FmtPlayed(def and def.levelTime) or "-")
		TipSub(tip, L["Click: refresh"])
	end,
	click = function()
		SecureAPI(RequestTimePlayed)
	end,
})

-- Session --------------------------------------------------------------------------
local function MoneyDelta(m)
	m = Plain(m) or 0
	local sign = m < 0 and "-" or "+"
	return format("%s%.2f|cffffd700g|r", sign, math.abs(m) / 10000)
end

local function PerHour(amount, secs)
	secs = Plain(secs) or 0
	if secs < 60 then return 0 end
	return amount / secs * 3600
end

local function SessionSample(def)
	if def.t0 then return end
	def.t0 = GetTime()
	def.g0 = Plain(GetMoney()) or 0
	def.xp0 = Plain(UnitXP("player")) or 0
end

ns.RegisterPlugin({
	id = "session",
	label = L["Session"],
	icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	bar = "top", zone = "CENTER", order = 60,
	events = { "PLAYER_MONEY", "PLAYER_XP_UPDATE", "PLAYER_ENTERING_WORLD" },
	update = function(def)
		SessionSample(def)
		local dt = GetTime() - def.t0
		local gph = PerHour((Plain(GetMoney()) or 0) - def.g0, dt)
		if math.abs(gph) < 0.005 then return "" end
		return format("%s|cffffd700g/h|r", gph >= 0 and "+" or "", gph)
	end,
	tooltip = function(tip)
		local def = P.byId.session
		if not def then return end
		SessionSample(def)
		local dt = GetTime() - def.t0
		TipHead(tip, L["Session"])
		TipKV(tip, L["Time"], SecondsToTime and SecondsToTime(floor(dt)) or floor(dt) .. "s")
		local g = (Plain(GetMoney()) or 0) - def.g0
		TipKV(tip, L["Gold"], format("%s (%.2f/h)", MoneyDelta(g), PerHour(g / 10000, dt)))
		local cur, max = Plain(UnitXP("player")), Plain(UnitXPMax("player"))
		if cur and max and max > 0 then
			local gained = math.max(0, cur - def.xp0)
			TipKV(tip, L["XP gained"], format("%s (%.0f/h)",
				BreakUpLargeNumbers and BreakUpLargeNumbers(gained) or gained, PerHour(gained, dt)))
			local rate = PerHour(gained, dt)
			if rate > 0 then
				local ttl = (max - cur) / rate * 3600
				TipKV(tip, L["Time to level"], SecondsToTime and SecondsToTime(floor(ttl)) or "?")
			end
			local rested = Plain(GetXPExhaustion and GetXPExhaustion() or nil)
			if rested and rested > 0 then
				TipKV(tip, L["Rested"], BreakUpLargeNumbers and BreakUpLargeNumbers(rested) or rested)
			end
		end
	end,
})

-- Speed -----------------------------------------------------------------------------
local BASE_SPEED = 7 -- run speed in yards/second
local function SpeedPct()
	local ok, s = pcall(GetUnitSpeed, "player")
	s = ok and Plain(s)
	if not s then return nil end
	return floor(s / BASE_SPEED * 100 + 0.5)
end

ns.RegisterPlugin({
	id = "speed",
	label = L["Speed"],
	icon = "Interface\\Icons\\Ability_Rogue_Sprint",
	bar = "top", zone = "CENTER", order = 30,
	update = function()
		local pct = SpeedPct()
		return pct and format("%s%d%%|r", AH, pct) or ""
	end,
	tooltip = function(tip)
		TipHead(tip, L["Speed"])
		TipKV(tip, L["Current"], format("%d%%", SpeedPct() or 0))
		TipKV(tip, L["Run speed"], "100%")
	end,
})

-- Volume ----------------------------------------------------------------------------
local function GetVol(cvar)
	local ok, v = pcall(GetCVar, cvar)
	v = ok and Plain(v)
	return tonumber(v) or 0
end

-- legacy SetCVar is protected on this client (the pcall caught the
-- error but the blocked-action event still logged UNKNOWN()); the
-- native setter is C_CVar.SetCVar
local function SndCVar(name, value)
	local f = C_CVar and C_CVar.SetCVar
	if f then pcall(f, name, value) end
end

local function SoundOn()
	local ok, v = pcall(GetCVarBool, "Sound_EnableAllSound")
	return ok and Plain(v) or false
end

ns.RegisterPlugin({
	id = "volume",
	label = L["Volume"],
	icon = "Interface\\Icons\\INV_Misc_Bell_01",
	bar = "top", zone = "RIGHT", order = 20,
	update = function()
		if not SoundOn() then return "|cffff5555" .. L["Muted"] .. "|r" end
		return format("%s%d%%|r", AH, floor(GetVol("Sound_MasterVolume") * 100 + 0.5))
	end,
	tooltip = function(tip)
		TipHead(tip, L["Volume"])
		TipKV(tip, L["Master volume"], format("%d%%", floor(GetVol("Sound_MasterVolume") * 100 + 0.5)))
		TipKV(tip, L["Music"], format("%d%%", floor(GetVol("Sound_MusicVolume") * 100 + 0.5)))
		TipKV(tip, L["Effects"], format("%d%%", floor(GetVol("Sound_SFXVolume") * 100 + 0.5)))
		TipKV(tip, L["Sound enabled"], SoundOn() and L["On"] or L["Off"])
	end,
	click = function()
		SndCVar("Sound_EnableAllSound", SoundOn() and "0" or "1")
	end,
	menu = function(def, items)
		items[#items + 1] = {
			text = L["Sound enabled"], checked = SoundOn(), noClose = true,
			onClick = function()
				SndCVar("Sound_EnableAllSound", SoundOn() and "0" or "1")
				P.UpdateOne(def)
			end,
		}
		items[#items + 1] = { text = L["Master volume"], isTitle = true }
		for _, v in ipairs({ 0, 25, 50, 75, 100 }) do
			items[#items + 1] = {
				text = v .. "%", checked = floor(GetVol("Sound_MasterVolume") * 100 + 0.5) == v,
				noClose = true,
				onClick = function()
					SndCVar("Sound_MasterVolume", tostring(v / 100))
					P.UpdateOne(def)
				end,
			}
		end
	end,
})

-- Calendar events --------------------------------------------------------------------
local FIXED = {
	{ L["Lunar Festival"],  { 1, 20 }, 24 },
	{ L["Love is in the Air"], { 2, 11 }, 6 },
	{ L["Noblegarden"],     { 4, 21 }, 7 },
	{ L["Children's Week"], { 5, 1 }, 7 },
	{ L["Midsummer Fire Festival"], { 6, 21 }, 14 },
	{ L["Brewfest"],        { 9, 20 }, 16 },
	{ L["Hallow's End"],    { 10, 18 }, 14 },
	{ L["Winter Veil"],     { 12, 15 }, 18 },
}
local DIM = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function DayOfWeek(y, m, d)
	if m < 3 then m, y = m + 12, y - 1 end
	local K, J = y % 100, floor(y / 100)
	local h = (d + floor(13 * (m + 1) / 5) + K + floor(K / 4)
		+ floor(J / 4) + 5 * J) % 7
	return h == 0 and 6 or h - 1
end

local function DmfStart(y, m)
	local dow = DayOfWeek(y, m, 1)
	if not dow then return nil end
	return (7 - dow) % 7 + 1
end

local function Events()
	local today = date("*t")
	local y, m, d = today.year, today.month, today.day
	local running, next, nextIn = {}, nil, math.huge
	local fs = DmfStart(y, m)
	if fs then
		if d >= fs and d < fs + 7 then
			running[#running + 1] = { name = L["Darkmoon Faire"], left = fs + 7 - d - 1 }
		else
			local t = fs - d
			if t <= 0 then
				local m2 = m % 12 + 1
				local nfs = DmfStart(m == 12 and y + 1 or y, m2)
				if nfs then t = DIM[m] - d + nfs end
			end
			if t and t > 0 and t < nextIn then nextIn, next = t, L["Darkmoon Faire"] end
		end
	end
	for _, e in ipairs(FIXED) do
		local name, start, len = e[1], e[2], e[3]
		if start[1] == m and d >= start[2] and d < start[2] + len then
			running[#running + 1] = { name = name, left = start[2] + len - d - 1 }
		else
			local t
			if start[1] == m and d < start[2] then
				t = start[2] - d
			elseif start[1] == (m % 12) + 1 then
				t = DIM[m] - d + start[2]
			end
			if t and t < nextIn then nextIn, next = t, name end
		end
	end
	return running, next, nextIn
end

ns.RegisterPlugin({
	id = "events",
	label = L["Events"],
	icon = "Interface\\Icons\\INV_Misc_Ticket_Darkmoon_01",
	bar = "top", zone = "RIGHT", order = 95,
	events = { "PLAYER_ENTERING_WORLD" },
	update = function()
		local running, next = Events()
		if #running > 0 then
			return AH .. running[1].name .. "|r"
		end
		if not next then return "" end
		return DH .. next .. "|r"
	end,
	tooltip = function(tip)
		local running, next, nextIn = Events()
		TipHead(tip, L["Events"])
		if #running > 0 then
			TipSub(tip, L["Running"])
			for _, e in ipairs(running) do
				tip:AddDoubleLine("  " .. e.name, format(L["%dd left"], e.left), 1, 1, 1, 0.9, 0.7, 0.3)
			end
		else
			tip:AddLine(L["No event running"], 0.7, 0.7, 0.7)
		end
		if next then
			TipKV(tip, L["Next"], format("%s (%dd)", next, nextIn))
		end
	end,
})

-- Tracking ------------------------------------------------------------------------------
local function TrackingList()
	local out = {}
	if C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo then
		local okN, n = pcall(C_Minimap.GetNumTrackingTypes)
		n = okN and Plain(n) or 0
		for i = 1, n do
			local okI, info = pcall(C_Minimap.GetTrackingInfo, i)
			info = okI and Plain(info)
			if ns.CanAccess(info) and Plain(info.name) then
				out[#out + 1] = {
					id = i, name = info.name,
					active = Plain(info.active) == true,
					nested = Plain(info.nested) == true,
				}
			end
		end
	elseif GetNumTrackingTypes and GetTrackingInfo then
		local okN, n = pcall(GetNumTrackingTypes)
		n = okN and Plain(n) or 0
		for i = 1, n do
			local okI, name, _, active, _, nested = pcall(GetTrackingInfo, i)
			name = okI and Plain(name)
			if name then
				out[#out + 1] = { id = i, name = name, active = Plain(active) == true,
					nested = Plain(nested) == true }
			end
		end
	end
	return out
end

local function SetTracking(id, on)
	if C_Minimap and C_Minimap.SetTracking then
		SecureAPI(C_Minimap.SetTracking, id, on)
	elseif _G.SetTracking then
		SecureAPI(_G.SetTracking, id, on)
	end
end

ns.RegisterPlugin({
	id = "tracking",
	label = L["Tracking"],
	icon = "Interface\\Icons\\Ability_Tracking",
	bar = "top", zone = "LEFT", order = 30,
	events = { "PLAYER_ENTERING_WORLD", "MINIMAP_UPDATE_TRACKING" },
	update = function()
		for _, t in ipairs(TrackingList()) do
			if t.active then return AH .. t.name .. "|r" end
		end
		return DH .. L["None"] .. "|r"
	end,
	tooltip = function(tip)
		TipHead(tip, L["Tracking"])
		local any = false
		for _, t in ipairs(TrackingList()) do
			if t.active then
				tip:AddLine("  " .. t.name, 0.6, 1, 0.6)
				any = true
			end
		end
		if not any then tip:AddLine("  " .. L["None"], 0.7, 0.7, 0.7) end
		TipSub(tip, L["Click: tracking menu"])
	end,
	click = function(b)
		P.Menu(P.byId["tracking"], b)
	end,
	menu = function(def, items)
		local list = TrackingList()
		if #list == 0 then
			items[#items + 1] = { text = L["(none)"], disabled = true }
			return
		end
		for _, tt in ipairs(list) do
			items[#items + 1] = {
				text = tt.name,
				checked = tt.active,
				noClose = true,
				disabled = tt.nested,
				onClick = function()
					SetTracking(tt.id, not tt.active)
					def.last = nil
					P.UpdateOne(def)
				end,
			}
		end
	end,
})
