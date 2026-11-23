-- SentiUI meters: up to two small dock windows, each rendering one metric
-- (damage, DPS, healing, threat ...) from the client's own damage meter
-- data (C_DamageMeter), plus a threat mode via UnitDetailedThreatSituation.
-- By default they sit next to the loot chat panel; every dock is a mover
-- and right-clicking a dock's title picks its metric + segment.
local _, ns = ...
local S = SentiUI
local L = ns.L
local IsSecret = S.IsSecret

local _G = _G
local format, floor, max, min = string.format, math.floor, math.max, math.min
local sort, tinsert, ipairs, type, tostring = table.sort, table.insert, ipairs, type, tostring
local pcall, wipe = pcall, wipe

local DM = C_DamageMeter
local DT = Enum and Enum.DamageMeterType or {}
local SEG = Enum and Enum.DamageMeterSessionType or {}
-- session type fallbacks mirror what the client reports when the enum
-- fields are missing: 0 = overall data, 1 = current fight
local SEG_OVERALL = SEG.Overall or 0
local SEG_CURRENT = SEG.Current or 1

local BLANK = "Interface\\Buttons\\WHITE8X8"
local HEADER_H = 20
local MAX_ROWS = 40 -- a full raid's threat list fits in the scroll
local MAX_DOCKS = 4 -- fixed window pool; "+ New window" enables the next
local TICK = 0.4

local Core = {}
ns.Core = Core
local db
local docks = {}
local ticker
local accStore, seenStore -- SavedVariables: running totals + last reads

local function IsN(v) return type(v) == "number" and not IsSecret(v) end
local function Plain(v)
	return (v ~= nil and not IsSecret(v)) and v or nil
end

local function Abbrev(n)
	if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
	if n >= 1e6 then return format("%.1fM", n / 1e6) end
	if n >= 1e3 then return format("%.1fk", n / 1e3) end
	return tostring(floor(n))
end

-- metric catalog -----------------------------------------------------------
-- mode.type = Enum.DamageMeterType; a nil type means the enum is missing
-- on this client and the mode can only render the "no data" hint. Threat
-- needs no meter session and works either way.
local MODES = {
	{ key = "damage", label = L["Damage done"], type = DT.DamageDone },
	{ key = "dps", label = L["DPS"], type = DT.Dps, perSec = true },
	{ key = "healing", label = L["Healing done"], type = DT.HealingDone },
	{ key = "hps", label = L["HPS"], type = DT.Hps, perSec = true },
	{ key = "absorbs", label = L["Absorbs"], type = DT.Absorbs },
	{ key = "dt", label = L["Damage taken"], type = DT.DamageTaken },
	{ key = "interrupts", label = L["Interrupts"], type = DT.Interrupts },
	{ key = "dispels", label = L["Dispels"], type = DT.Dispels },
	{ key = "deaths", label = L["Deaths"], type = DT.Deaths },
	{ key = "threat", label = L["Threat"] },
}
local ModeByKey = {}
for _, m in ipairs(MODES) do ModeByKey[m.key] = m end
Core.MODES = MODES

local function ModeFor(key)
	return ModeByKey[key] or MODES[1]
end

-- native session windows -----------------------------------------------------
-- Blizzard's own DamageMeter session windows update themselves with
-- trusted code - they refresh in combat where our Lua rows can't. Each
-- dock claims one and anchors it inside its view; threat mode keeps the
-- custom renderer (no DamageMeterType exists for it).
local DMGR = DamageMeter -- the Blizzard manager global (may be nil early)

local function AcquireWindow(i)
	if not (DMGR and type(DMGR.ForEachSessionWindow) == "function") then
		return nil
	end
	-- diff the set: ShowNewSessionWindow's return is unreliable, the new
	-- window simply appears in the enumeration
	local before = {}
	DMGR:ForEachSessionWindow(function(w)
		if w then before[w] = true end
	end)
	if type(DMGR.ShowNewSessionWindow) == "function" then
		pcall(DMGR.ShowNewSessionWindow, DMGR)
	end
	local found
	DMGR:ForEachSessionWindow(function(w)
		if w and not before[w] and not w._sentiDock and not found then
			found = w
		end
	end)
	if not found then
		-- nothing new spawned (pool cap?) - reuse an untagged window
		DMGR:ForEachSessionWindow(function(w)
			if w and not w._sentiDock and not found then found = w end
		end)
	end
	if found then found._sentiDock = i end
	return found
end

-- the session window ships its own header/dropdown/chrome; we keep only
-- the direct child that hosts the entry rows and fade the rest
local function StripNativeChrome(w)
	local keep
	if type(w.ForEachEntryFrame) == "function" then
		w:ForEachEntryFrame(function(e)
			if keep then return end
			local p = e and e.GetParent and e:GetParent()
			while p and p.GetParent and p:GetParent() and p:GetParent() ~= w do
				p = p:GetParent()
			end
			if p and p:GetParent() == w then keep = p end
		end)
	end
	for _, c in ipairs({ w:GetChildren() }) do
		if c ~= keep and type(c) == "table" then
			pcall(c.SetAlpha, c, 0)
			pcall(c.EnableMouse, c, false)
		end
	end
	for _, r in ipairs({ w:GetRegions() }) do
		if r and r.SetAlpha then pcall(r.SetAlpha, r, 0) end
	end
end

local function NativeLooks(w)
	if not DMGR then return end
	if type(DMGR.SetUseClassColor) == "function" then
		pcall(DMGR.SetUseClassColor, DMGR, true)
	end
	if type(DMGR.SetShowBarIcons) == "function" then
		pcall(DMGR.SetShowBarIcons, DMGR, true)
	end
	if type(DMGR.SetBarHeight) == "function" then
		pcall(DMGR.SetBarHeight, DMGR, db.barHeight)
	end
	if type(DMGR.SetBarSpacing) == "function" then
		pcall(DMGR.SetBarSpacing, DMGR, db.spacing)
	end
	if w.RefreshLayout then pcall(w.RefreshLayout, w) end
end

-- parked OVER the dock's view (no reparent - the manager may re-anchor
-- its children internally); it follows our frame through its anchors
local function EmbedNative(d, i)
	local w = AcquireWindow(i)
	if not w then return nil end
	d.native = w
	w:ClearAllPoints()
	w:SetPoint("TOPLEFT", d.view, "TOPLEFT", 0, 0)
	w:SetPoint("BOTTOMRIGHT", d.view, "BOTTOMRIGHT", 0, 0)
	if w.SetFrameLevel and d.view.GetFrameLevel then
		pcall(w.SetFrameLevel, w, d.view:GetFrameLevel() + 5)
	end
	StripNativeChrome(w)
	NativeLooks(w)
	w:Show()
	return w
end

-- Show/Hide on a Blizzard session window is protected under lockdown;
-- queue it once per desired state instead of spamming protected calls
-- from the ticker
local function NativeShown(w, on)
	if not w or w._wantShown == on then return end
	w._wantShown = on
	S.RunOutOfCombat(function()
		if on then w:Show() else w:Hide() end
	end)
end

-- applies the dock's metric+segment to its native window; threat (no
-- DamageMeterType) and missing windows return false = custom renderer
local function ApplyNative(d, cfg, mode)
	local w = d.native
	if not w then return false end
	if not mode.type then NativeShown(w, false) return false end
	if d._nMode ~= cfg.mode or d._nSeg ~= cfg.segment then
		d._nMode, d._nSeg = cfg.mode, cfg.segment
		pcall(w.SetDamageMeterType, w, mode.type)
		local st = (cfg.segment == "overall") and SEG_OVERALL or SEG_CURRENT
		if type(w.SetSession) == "function" then
			pcall(w.SetSession, w, st, 0)
		end
	end
	NativeShown(w, true)
	for _, r in ipairs(d.rows) do r:Hide() end
	d.hint:Hide()
	if d.bar then d.bar:Hide() end
	if d.thumb then d.thumb:Hide() end
	return true
end

-- native window acquisition is protected work (spawning + anchoring a
-- Blizzard frame) and DamageMeter may load after us - retry lazily
local function EnsureNative(d, i, tries)
	if d.native then return end
	DMGR = DMGR or DamageMeter
	if not (DMGR and type(DMGR.ForEachSessionWindow) == "function") then
		if (tries or 0) < 10 then
			C_Timer.After(3, function() EnsureNative(d, i, (tries or 0) + 1) end)
		end
		return
	end
	S.RunOutOfCombat(function()
		if not d.native then EmbedNative(d, i) end
	end)
end

-- class color for a source; classFilename can be missing on pets/secret
local function ClassColor(cls)
	if type(cls) == "string" then
		local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
		if c then return c.r, c.g, c.b end
		if C_ClassColor and C_ClassColor.GetClassColor then
			local ok, cc = pcall(C_ClassColor.GetClassColor, cls)
			if ok and cc and not IsSecret(cc) then
				return cc:GetRGB()
			end
		end
	end
	local c = S.colors.accent2
	return c.r, c.g, c.b
end

-- data ---------------------------------------------------------------------
local function SessionFor(mtype, segment)
	if not (DM and DM.GetCombatSessionFromType and mtype) then return nil end
	local st = (segment == "overall") and SEG_OVERALL or SEG_CURRENT
	local ok, s = pcall(DM.GetCombatSessionFromType, st, mtype)
	if not ok or type(s) ~= "table" or type(s.combatSources) ~= "table" then
		return nil
	end
	return s
end

local function SessionByID(id, mtype)
	if not (DM and DM.GetCombatSessionFromID and id) then return nil end
	local ok, s = pcall(DM.GetCombatSessionFromID, id, mtype)
	if not ok or type(s) ~= "table" or type(s.combatSources) ~= "table" then
		return nil
	end
	return s
end

local function SessDur(v)
	if not (DM and DM.GetSessionDurationSeconds) then return 0 end
	local ok, d = pcall(DM.GetSessionDurationSeconds, v)
	if ok and IsN(d) then return d end
	return 0
end

local scratch = {}

-- the running "overall" is OUR OWN accumulator fed by every session the
-- client reports - expired IDs plus the live current one. Totals persist
-- in SavedVariables, so the list survives reloads; only positive deltas
-- are added, so re-reading the same session never double counts.
local function AccFor(mkey)
	local a = accStore[mkey]
	if not a then a = { dur = 0, rows = {} }; accStore[mkey] = a end
	if not a.rows then a.rows = {} end
	return a
end

local function UpdateAccum(mkey, mtype)
	local acc = AccFor(mkey)
	local seen = seenStore[mkey] or {}
	local newSeen = {}
	local hadSessions = next(seen) ~= nil
	local liveSessions = 0
	local function Feed(skey, session, dur)
		local prev = seen[skey]
		local rec = { dur = dur or 0 }
		local dd = (dur or 0) - (prev and prev.dur or 0)
		if dd > 0 then acc.dur = (acc.dur or 0) + dd end
		for _, src in ipairs(session.combatSources) do
			local total = Plain(src.totalAmount)
			if total then
				local key = Plain(src.sourceGUID) or Plain(src.name) or "?"
				rec[key] = total
				local d = total - (prev and prev[key] or 0)
				if d > 0 then
					local row = acc.rows[key]
					if not row then
						row = {
							name = Plain(src.name) or "?",
							cls = Plain(src.classFilename),
							total = 0,
							self_ = Plain(src.isLocalPlayer) == true or nil,
						}
						acc.rows[key] = row
					end
					row.total = row.total + d
					local nm = Plain(src.name)
					if nm then row.name = nm end
				end
			end
		end
		newSeen[skey] = rec
	end
	if DM and DM.GetAvailableCombatSessions then
		local ok, list = pcall(DM.GetAvailableCombatSessions)
		if ok and type(list) == "table" then
			for _, info in ipairs(list) do
				local id = info and Plain(info.sessionID)
				if id then
					liveSessions = liveSessions + 1
					local s = SessionByID(id, mtype)
					if s then
						local d = Plain(info.durationSeconds) or SessDur(id)
						Feed("s" .. tostring(id), s, d)
					end
				end
			end
		end
	end
	local cur = SessionFor(mtype, "current")
	if cur then Feed("cur", cur, SessDur(SEG_CURRENT)) end
	-- full external reset: every session we remembered is gone and the
	-- client stores nothing - drop the accumulated totals as well
	if hadSessions and liveSessions == 0 and not cur then
		acc.dur = 0
		wipe(acc.rows)
	end
	seenStore[mkey] = newSeen
end

-- overall = accumulated totals across all fights, counting live
local function CollectOverall(mode)
	wipe(scratch)
	if not (mode.type and DM) then return 0, 0, true end
	UpdateAccum(mode.key, mode.type)
	local acc = accStore[mode.key]
	local dur = (acc and acc.dur) or 0
	local top = 0
	for key, row in pairs(acc and acc.rows or {}) do
		local r = {
			name = row.name,
			cls = row.cls,
			guid = (type(key) == "string" and key:sub(1, 7) == "Player-")
				and key or nil,
			total = row.total or 0,
			aps = dur > 0 and (row.total or 0) / dur or 0,
			self_ = row.self_,
		}
		scratch[#scratch + 1] = r
		local v = mode.perSec and r.aps or r.total
		if v > top then top = v end
	end
	sort(scratch, function(a, b)
		local va = mode.perSec and a.aps or a.total
		local vb = mode.perSec and b.aps or b.total
		return va > vb
	end)
	return #scratch, top, false
end

-- fills scratch with { name, cls, guid, total, aps }; returns count, max
local function CollectMeter(mode, segment)
	wipe(scratch)
	local s = SessionFor(mode.type, segment)
	if not s then return 0, 0, true end
	local top = 0
	for _, src in ipairs(s.combatSources) do
		local total = Plain(src.totalAmount) or 0
		local aps = Plain(src.amountPerSecond) or 0
		local row = {
			name = Plain(src.name) or "?",
			cls = Plain(src.classFilename),
			guid = Plain(src.sourceGUID),
			total = total,
			aps = aps,
		}
		scratch[#scratch + 1] = row
		local v = mode.perSec and aps or total
		if v > top then top = v end
	end
	sort(scratch, function(a, b)
		local va = mode.perSec and a.aps or a.total
		local vb = mode.perSec and b.aps or b.total
		return va > vb
	end)
	return #scratch, top, false
end

-- threat mode: every group member's scaled threat on the current target;
-- UnitDetailedThreatSituation answers can be secret on this client
local function CollectThreat()
	local mob = "target"
	local okE, exists = pcall(UnitExists, mob)
	if not (okE and exists) then return 0, 0, "notarget" end
	local okA, canAtk = pcall(UnitCanAttack, "player", mob)
	if not (okA and canAtk and not IsSecret(canAtk)) then
		return 0, 0, "notarget"
	end
	wipe(scratch)
	local units = { "player" }
	if IsInRaid and IsInRaid() then
		for i = 1, 40 do units[#units + 1] = "raid" .. i end
	elseif IsInGroup and IsInGroup() then
		for i = 1, 4 do units[#units + 1] = "party" .. i end
	end
	local UDTS = UnitDetailedThreatSituation
	if type(UDTS) ~= "function" then return 0, 0, "notarget" end
	local any, top = false, 0
	for _, u in ipairs(units) do
		local okU, ex = pcall(UnitExists, u)
		if okU and ex then
			local okT, tanking, status, pct, rawpct = pcall(UDTS, u, mob)
			if okT then
				local p = Plain(pct) or Plain(rawpct)
				if p then
					any = true
					if p > top then top = p end
					local okN, nm = pcall(GetUnitName or UnitName, u)
					local cls
					local okC, _, cf = pcall(UnitClass, u)
					if okC then cls = Plain(cf) end
					scratch[#scratch + 1] = {
						name = (okN and Plain(nm)) or u,
						cls = cls,
						total = p, aps = 0,
						tank = (tanking == true or status == 3) and true or nil,
						self_ = u == "player",
					}
				end
			end
		end
	end
	if not any then return 0, 0, "hidden" end
	sort(scratch, function(a, b) return a.total > b.total end)
	return #scratch, max(top, 100), false
end

-- rows ---------------------------------------------------------------------
local function RowAt(dock, i)
	local r = dock.rows[i]
	if r then return r end
	r = CreateFrame("Frame", nil, dock.content)
	r.bg = r:CreateTexture(nil, "BACKGROUND")
	r.bg:SetAllPoints()
	r.bg:SetTexture(BLANK)
	r.bg:SetVertexColor(0.03, 0.04, 0.06, 0.85)
	r.fill = r:CreateTexture(nil, "ARTWORK")
	r.fill:SetTexture(BLANK)
	r.fill:SetPoint("LEFT", r, "LEFT", 1, 0)
	r.fill:SetPoint("TOP", r, "TOP", 0, -1)
	r.fill:SetPoint("BOTTOM", r, "BOTTOM", 0, 1)
	-- accent edge for the row leader (rank 1) - signature tick
	r.edge = r:CreateTexture(nil, "OVERLAY")
	r.edge:SetTexture(BLANK)
	r.edge:SetSize(2, 0)
	r.edge:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -1)
	r.edge:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 0, 1)
	r.edge:SetVertexColor(0.92, 0.68, 0.20, 0.0)
	-- OUTLINE on row text: the class-colored fill behind it makes plain
	-- 9pt dim text nearly unreadable
	r.name = S.Font(r, 9, S.colors.text, "OUTLINE")
	r.name:SetPoint("LEFT", r, "LEFT", 4, 0)
	r.name:SetPoint("RIGHT", r, "RIGHT", -64, 0)
	r.name:SetJustifyH("LEFT")
	r.name:SetWordWrap(false)
	r.val = S.Font(r, 9, S.colors.text, "OUTLINE")
	r.val:SetPoint("RIGHT", r, "RIGHT", -4, 0)
	r.val:SetJustifyH("RIGHT")
	r.val:SetWordWrap(false)
	dock.rows[i] = r
	return r
end

local myGUID
local function PlayerGUID()
	if not myGUID then
		local ok, g = pcall(UnitGUID, "player")
		if ok then myGUID = Plain(g) end
	end
	return myGUID
end

local SetScroll -- forward: UpdateDock clamps the offset, defined below

-- collapsed = a slim strip on the loot-facing edge: the dock's anchor
-- holds its RIGHT side, so shrinking the width folds the window toward
-- the loot panel exactly. The strip is one big unfold button.
local FOLD_W = 16
local function ApplyFold(d, cfg)
	local c = cfg.collapsed == true
	if d.view then d.view:SetShown(not c) end
	if d.title then d.title:SetShown(not c) end
	if d.seg then d.seg:SetShown(not c) end
	if d.hline then d.hline:SetShown(not c) end
	if d.foldBtn then d.foldBtn:SetShown(not c) end
	if d.closeBtn then d.closeBtn:SetShown(not c) end
	if d.hint then d.hint:Hide() end
	if d.bar then d.bar:Hide() end
	if d.thumb then d.thumb:Hide() end
	if d.native then NativeShown(d.native, not c) end
	if c then
		d:SetSize(FOLD_W, HEADER_H + 4 + db.height + 6)
		if d.strip then
			d.strip:ClearAllPoints()
			d.strip:SetPoint("CENTER", d, "CENTER", 0, 0)
			d.strip:Show()
		end
	else
		d:SetSize(db.width, HEADER_H + 4 + db.height + 6)
		if d.strip then d.strip:Hide() end
	end
end

local function UpdateDock(d, cfg)
	local mode = ModeFor(cfg.mode)
	ApplyFold(d, cfg)
	if cfg.collapsed then return end
	d.title:SetText(mode.label)
	d.seg:SetText(mode.key == "threat" and ""
		or (cfg.segment == "overall" and L["Overall"] or L["Current fight"]))

	-- native path: a Blizzard session window renders this metric and
	-- updates itself (combat-safe, real-time, own scrolling)
	if mode.key ~= "threat" and ApplyNative(d, cfg, mode) then
		d.contentH = 1
		return
	end
	if d.native then NativeShown(d.native, false) end

	local n, top, err
	if mode.key == "threat" then
		n, top, err = CollectThreat()
	elseif cfg.segment == "overall" then
		n, top, err = CollectOverall(mode)
	else
		n, top, err = CollectMeter(mode, cfg.segment)
	end

	local h = db.barHeight
	local gap = db.spacing
	local show = min(n, MAX_ROWS)
	for i = 1, show do
		local src = scratch[i]
		local r = RowAt(d, i)
		r:SetHeight(h)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", d.content, "TOPLEFT", 0,
			-((i - 1) * (h + gap)))
		r:SetPoint("RIGHT", d.content, "RIGHT", -8, 0)
		local v = mode.perSec and src.aps or src.total
		local frac = (IsN(v) and IsN(top) and top > 0) and min(v / top, 1) or 0
		r.fill:SetWidth(max((db.width - 10) * frac, frac > 0 and 2 or 0.001))
		local cr, cg, cb = ClassColor(src.cls)
		r.fill:SetVertexColor(cr, cg, cb, 0.85)
		r.edge:SetVertexColor(0.92, 0.68, 0.20,
			(i == 1 or src.tank or src.self_) and 0.9 or 0.0)
		local isMe = (src.guid and src.guid == PlayerGUID()) or src.self_
		local nm = src.name or "?"
		r.name:SetText(nm)
		if isMe then
			local c = S.colors.accent
			r.name:SetTextColor(c.r, c.g, c.b)
		else
			local c = S.colors.text
			r.name:SetTextColor(c.r, c.g, c.b)
		end
		local txt = Abbrev(IsN(v) and v or 0)
		if mode.key == "threat" then
			txt = format("%d%%", floor(v + 0.5))
		elseif src.aps > 0 and not mode.perSec and mode.key ~= "threat" then
			txt = txt .. format("  |cff9aa3b5%s|r", Abbrev(src.aps))
		end
		r.val:SetText(txt)
		r:Show()
	end
	for i = show + 1, #d.rows do d.rows[i]:Hide() end

	-- hint line when nothing renders
	local hint
	if err == "notarget" then hint = L["No target"]
	elseif err == "hidden" then hint = L["Data hidden"]
	elseif n == 0 then hint = L["No data"] end
	d.hint:SetText(hint or "")
	d.hint:SetShown(hint ~= nil)

	-- fixed window: the rows scroll inside the clipped view instead of
	-- the frame growing with the entry count
	d.contentH = max(show * (h + gap), 1)
	d.content:SetSize(db.width - 16, d.contentH)
	SetScroll(d, d.scroll or 0)
end

Core.UpdateDock = UpdateDock

-- scroll: the content child slides inside the clipped view; a slim bar
-- on the right edge shows position when the list is taller than it
local function UpdateThumb(d)
	if not d.view then return end
	local vh = d.view:GetHeight()
	if not vh or vh <= 0 or (d.contentH or 0) <= vh then
		if d.bar then d.bar:Hide() end
		if d.thumb then d.thumb:Hide() end
		return
	end
	d.bar:ClearAllPoints()
	d.bar:SetPoint("TOPRIGHT", d.view, "TOPRIGHT", 0, 0)
	d.bar:SetPoint("BOTTOMRIGHT", d.view, "BOTTOMRIGHT", 0, 0)
	d.bar:SetWidth(3)
	d.bar:Show()
	local th = max(14, vh * vh / d.contentH)
	local span = max(d.contentH - vh, 1)
	local frac = max(0, min((d.scroll or 0) / span, 1))
	d.thumb:ClearAllPoints()
	d.thumb:SetPoint("TOPRIGHT", d.view, "TOPRIGHT", 0, -frac * (vh - th))
	d.thumb:SetSize(3, th)
	d.thumb:Show()
end

SetScroll = function(d, v)
	-- all frames here are built at enable, so re-anchoring is allowed
	-- in combat too - the threat list must scroll mid-fight
	local vh = d.view and d.view:GetHeight() or 0
	local span = max((d.contentH or 0) - vh, 0)
	d.scroll = max(0, min(v or 0, span))
	if d.content then
		d.content:ClearAllPoints()
		d.content:SetPoint("TOPLEFT", d.view, "TOPLEFT", 0, d.scroll)
	end
	UpdateThumb(d)
end

-- mode/segment menu: one shared popup, rows built once - opening only
-- re-marks the checks against the dock it currently serves
local menu
local AddDock, NextFreeDock, ResetMeters -- forward: menu rows call these

local function BuildMenu()
	menu = CreateFrame("Frame", "SentiUIMeterMenu", UIParent,
		"BackdropTemplate")
	S.Template(menu, "raised")
	-- explicit accent frame on top of the backdrop edge: the flat 1px
	-- border rendered too faint on the popup - the top edge read as
	-- missing entirely. Four strips, guaranteed visible.
	local acc = S.colors.accent
	local ea = 0.5
	local et = menu:CreateTexture(nil, "OVERLAY", nil, 2)
	et:SetTexture(BLANK) et:SetHeight(1) et:SetVertexColor(acc.r, acc.g, acc.b, ea)
	et:SetPoint("TOPLEFT") et:SetPoint("TOPRIGHT")
	local eb = menu:CreateTexture(nil, "OVERLAY", nil, 2)
	eb:SetTexture(BLANK) eb:SetHeight(1) eb:SetVertexColor(acc.r, acc.g, acc.b, ea)
	eb:SetPoint("BOTTOMLEFT") eb:SetPoint("BOTTOMRIGHT")
	local el = menu:CreateTexture(nil, "OVERLAY", nil, 2)
	el:SetTexture(BLANK) el:SetWidth(1) el:SetVertexColor(acc.r, acc.g, acc.b, ea)
	el:SetPoint("TOPLEFT") el:SetPoint("BOTTOMLEFT")
	local er = menu:CreateTexture(nil, "OVERLAY", nil, 2)
	er:SetTexture(BLANK) er:SetWidth(1) er:SetVertexColor(acc.r, acc.g, acc.b, ea)
	er:SetPoint("TOPRIGHT") er:SetPoint("BOTTOMRIGHT")
	menu:SetFrameStrata("TOOLTIP")
	menu:SetClampedToScreen(true)
	menu:EnableMouse(true)
	menu.rows = {}
	local y = 6
	local function Item(row)
		local b = CreateFrame("Button", nil, menu)
		b:SetHeight(18)
		b:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -y)
		b:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, -y)
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(0.92, 0.68, 0.20, 0.08)
		b.fs = S.Font(b, 10, S.colors.text)
		b.fs:SetPoint("LEFT", 8, 0)
		b.chk = S.Font(b, 10, S.colors.accent)
		b.chk:SetPoint("RIGHT", -4, 0)
		b.fs:SetText(row.label)
		b.row = row
		b:SetScript("OnClick", function(self)
			local cfg = menu.cfg
			if not cfg then menu:Hide() return end
			if self.row.mode then cfg.mode = self.row.mode
			else cfg.segment = self.row.seg end
			UpdateDock(menu.dock, cfg)
			menu:Hide()
		end)
		menu.rows[#menu.rows + 1] = b
		y = y + 19
	end
	for _, m in ipairs(MODES) do Item({ label = m.label, mode = m.key }) end
	local ln = S.Line(menu, S.colors.border)
	ln:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -(y + 2))
	ln:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -8, -(y + 2))
	y = y + 8
	Item({ label = L["Current fight"], seg = "current" })
	Item({ label = L["Overall"], seg = "overall" })
	local ln2 = S.Line(menu, S.colors.border)
	ln2:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -(y + 2))
	ln2:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -8, -(y + 2))
	y = y + 8
	-- "+ New window": turns the next pool dock on and chains it to the
	-- left of the shown ones (toward the action bars); hidden once all
	-- four docks are live
	local add = CreateFrame("Button", nil, menu)
	add:SetHeight(18)
	add:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -y)
	add:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, -y)
	local addHl = add:CreateTexture(nil, "HIGHLIGHT")
	addHl:SetAllPoints()
	addHl:SetColorTexture(0.92, 0.68, 0.20, 0.08)
	add.fs = S.Font(add, 10, S.colors.accent)
	add.fs:SetPoint("LEFT", 8, 0)
	add.fs:SetText("+ " .. L["New window"])
	add:SetScript("OnClick", function()
		AddDock()
		menu:Hide()
	end)
	menu.addBtn = add
	y = y + 19
	-- "Reset data": same prompt the instance-join check raises
	local rst = CreateFrame("Button", nil, menu)
	rst:SetHeight(18)
	rst:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -y)
	rst:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, -y)
	local rstHl = rst:CreateTexture(nil, "HIGHLIGHT")
	rstHl:SetAllPoints()
	rstHl:SetColorTexture(0.92, 0.68, 0.20, 0.08)
	rst.fs = S.Font(rst, 10, S.colors.textDim)
	rst.fs:SetPoint("LEFT", 8, 0)
	rst.fs:SetText(L["Reset data"])
	rst:SetScript("OnClick", function()
		menu:Hide()
		if StaticPopup_Show then
			StaticPopup_Show("SENTIUI_METERS_RESET")
		else
			ResetMeters()
		end
	end)
	menu.resetBtn = rst
	y = y + 19
	-- "Close window": same effect as the title x - turns this dock off
	local cls = CreateFrame("Button", nil, menu)
	cls:SetHeight(18)
	cls:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -y)
	cls:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, -y)
	local clsHl = cls:CreateTexture(nil, "HIGHLIGHT")
	clsHl:SetAllPoints()
	clsHl:SetColorTexture(0.92, 0.68, 0.20, 0.08)
	cls.fs = S.Font(cls, 10, S.colors.textDim)
	cls.fs:SetPoint("LEFT", 8, 0)
	cls.fs:SetText(L["Close window"])
	cls:SetScript("OnClick", function()
		if menu.dock and menu.dock.cfg then
			menu.dock.cfg.enabled = false
		end
		menu:Hide()
		Core.RefreshAll()
	end)
	y = y + 19
	menu.baseH = y + 6
	menu:SetSize(170, menu.baseH)
	menu:SetScript("OnHide", function() menu.dock, menu.cfg = nil, nil end)
	if S.EscClosable then S.EscClosable(menu) end
	menu:Hide()
end

local function ShowMenu(dock, cfg)
	if not menu then BuildMenu() end
	menu.dock, menu.cfg = dock, cfg
	for _, b in ipairs(menu.rows) do
		local on = (b.row.mode and b.row.mode == cfg.mode)
			or (b.row.seg and b.row.seg == cfg.segment)
		b.chk:SetText(on and "v" or "")
		b.fs:SetTextColor(
			(on and S.colors.accent or S.colors.text).r,
			(on and S.colors.accent or S.colors.text).g,
			(on and S.colors.accent or S.colors.text).b)
	end
	-- "+ New window" only while a pool slot is still off; the menu
	-- shrinks by a row when it is hidden
	local hasFree = NextFreeDock() ~= nil
	menu.addBtn:SetShown(hasFree)
	menu:SetHeight(menu.baseH - (hasFree and 0 or 19))
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", dock, "BOTTOMLEFT", 0, -2)
	menu:Show()
end

-- docks --------------------------------------------------------------------
local function BuildDock(i)
	local d = CreateFrame("Frame", "SentiUIMeterDock" .. i, UIParent,
		"BackdropTemplate")
	S.Template(d, "panel")
	d:SetFrameStrata("LOW")
	d:SetClampedToScreen(true)
	d:EnableMouse(true)

	d.title = S.Font(d, 10, S.colors.accent)
	d.title:SetPoint("TOPLEFT", d, "TOPLEFT", 8, -4)
	d.title:SetPoint("RIGHT", d, "RIGHT", -66, 0)
	d.title:SetJustifyH("LEFT")
	d.seg = S.Font(d, 8, S.colors.textDim)
	d.seg:SetPoint("TOPRIGHT", d, "TOPRIGHT", -38, -6)
	d.seg:SetJustifyH("RIGHT")
	local hl = S.Line(d, S.colors.accent)
	hl:SetPoint("TOPLEFT", d, "TOPLEFT", 6, -HEADER_H + 2)
	hl:SetPoint("TOPRIGHT", d, "TOPRIGHT", -6, -HEADER_H + 2)
	d.hline = hl

	-- header buttons: > folds the window into a strip on its loot-side
	-- edge, x turns the dock off ("+ New window" / options bring it back)
	local function headBtn(txt, xoff, tip)
		local b = CreateFrame("Button", nil, d)
		b:SetSize(14, 14)
		b:SetPoint("TOPRIGHT", d, "TOPRIGHT", xoff, -3)
		b.fs = S.Font(b, 10, S.colors.textDim)
		b.fs:SetPoint("CENTER")
		b.fs:SetText(txt)
		b:SetScript("OnEnter", function(s)
			s.fs:SetTextColor(1, 1, 1)
			if tip and GameTooltip then
				GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
				GameTooltip:AddLine(tip, 0.8, 0.8, 0.8)
				GameTooltip:Show()
			end
		end)
		b:SetScript("OnLeave", function(s)
			s.fs:SetTextColor(S.colors.textDim.r, S.colors.textDim.g,
				S.colors.textDim.b)
			if tip and GameTooltip then GameTooltip:Hide() end
		end)
		return b
	end
	d.foldBtn = headBtn(">", -6, L["Fold toward the loot window"])
	d.foldBtn:SetScript("OnClick", function()
		d.cfg.collapsed = true
		UpdateDock(d, d.cfg)
	end)
	d.closeBtn = headBtn("x", -20, L["Close window"])
	d.closeBtn:SetScript("OnClick", function()
		d.cfg.enabled = false
		Core.RefreshAll()
		S.Print(L["Window closed - '+ New window' in another meter menu or the Meters options brings it back."])
	end)
	-- the collapsed strip: one gold caret, the whole stub unfolds on click
	d.strip = S.Font(d, 11, S.colors.accent)
	d.strip:SetText("<")
	d.strip:Hide()

	-- clipped view + content child: the rows live in `content`, the
	-- wheel slides it inside `view` and a slim bar shows the position
	d.view = CreateFrame("Frame", nil, d)
	d.view:SetPoint("TOPLEFT", d, "TOPLEFT", 4, -(HEADER_H + 4))
	d.view:SetPoint("BOTTOMRIGHT", d, "BOTTOMRIGHT", -4, 4)
	pcall(d.view.SetClipsChildren, d.view, true)
	d.content = CreateFrame("Frame", nil, d.view)
	d.content:SetPoint("TOPLEFT", d.view, "TOPLEFT", 0, 0)
	d.view:EnableMouseWheel(true)
	d.view:SetScript("OnMouseWheel", function(self, delta)
		SetScroll(d, (d.scroll or 0) - delta * (db.barHeight + db.spacing) * 3)
	end)
	d.bar = d:CreateTexture(nil, "OVERLAY")
	d.bar:SetColorTexture(0.13, 0.16, 0.22, 0.9)
	d.thumb = d:CreateTexture(nil, "OVERLAY")
	d.thumb:SetColorTexture(0.92, 0.68, 0.20, 0.95)
	d.bar:Hide()
	d.thumb:Hide()
	d.contentH = 1
	d.scroll = 0

	d.hint = S.Font(d, 9, S.colors.textDim)
	d.hint:SetPoint("CENTER", d.view, "CENTER")
	d.rows = {}

	d:SetScript("OnMouseUp", function(self, btn)
		if btn == "LeftButton" and self.cfg and self.cfg.collapsed then
			self.cfg.collapsed = false
			UpdateDock(self, self.cfg)
		elseif btn == "RightButton" then
			ShowMenu(self, self.cfg)
		end
	end)
	d:SetScript("OnEnter", function(self)
		if not GameTooltip then return end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Right-click: meter settings"], 0.55, 0.57, 0.62)
		GameTooltip:Show()
	end)
	d:SetScript("OnLeave", function() GameTooltip:Hide() end)
	d:SetScript("OnHide", function()
		if menu and menu.dock == d then menu:Hide() end
		-- the native window is parked over us, not parented: take it down
		if d.native then NativeShown(d.native, false) end
	end)

	-- fixed size from the start: width/height are settings, the list
	-- scrolls inside instead of resizing the window
	d:SetSize(db.width, HEADER_H + 4 + db.height + 6)
	-- warm the row pool out of combat: a row frame created mid-fight is
	-- protected and every SetPoint/Show on it would fire FORBIDDEN
	for i = 1, MAX_ROWS do RowAt(d, i):Hide() end

	d.cfg = db["dock" .. i]
	docks[i] = d
	return d
end

-- the previous SHOWN dock: new windows chain onto the enabled ones,
-- skipping disabled gaps in the pool
local function PrevShown(i)
	for j = i - 1, 1, -1 do
		if docks[j] and db["dock" .. j] and db["dock" .. j].enabled then
			return docks[j]
		end
	end
end

-- default anchor: beside the loot chat panel (the right chat dock);
-- a saved mover position overrides this on the next login anyway
local function Layout()
	local loot = _G.SentiUIRightChatPanel
	for i, d in ipairs(docks) do
		if not S.DB.Positions()["meter." .. i] then
			d:ClearAllPoints()
			if i == 1 and loot then
				d:SetPoint("TOPRIGHT", loot, "TOPLEFT", -6, 0)
			elseif i > 1 and PrevShown(i) then
				-- chained toward the action bars: each new window docks
				-- onto the left edge of the previous shown one
				d:SetPoint("TOPRIGHT", PrevShown(i), "TOPLEFT", -6, 0)
			else
				d:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 200)
			end
		end
	end
end

local function RefreshAll()
	for i, d in ipairs(docks) do
		local cfg = db["dock" .. i]
		d:SetShown(cfg.enabled == true)
		if cfg.enabled then
			EnsureNative(d, i)
			UpdateDock(d, cfg)
		elseif d.native then NativeShown(d.native, false) end
	end
end
Core.RefreshAll = RefreshAll
Core.Layout = Layout

-- first pool slot that is still off; "+ New window" consumes it
NextFreeDock = function()
	for i = 1, MAX_DOCKS do
		local cfg = db["dock" .. i]
		if cfg and not cfg.enabled then return i end
	end
end

AddDock = function()
	local i = NextFreeDock()
	if not i then return end
	db["dock" .. i].enabled = true
	Layout() -- chains the new window onto the previous shown dock
	RefreshAll()
end

-- wipe: the client's sessions AND our own accumulated overall rows
ResetMeters = function()
	if DM and DM.ResetAllCombatSessions then
		pcall(DM.ResetAllCombatSessions)
	end
	if accStore then wipe(accStore) end
	if seenStore then wipe(seenStore) end
	RefreshAll()
end

-- any stored data worth a reset prompt?
local function HasMeterData()
	for _, a in pairs(accStore or {}) do
		if a.rows then
			for _, r in pairs(a.rows) do
				if (r.total or 0) > 0 then return true end
			end
		end
	end
	if DM and DM.GetAvailableCombatSessions then
		local ok, l = pcall(DM.GetAvailableCombatSessions)
		if ok and type(l) == "table" and #l > 0 then return true end
	end
	local s = SessionFor(DT.DamageDone, "current")
	return s ~= nil and #s.combatSources > 0
end

-- entering an instance asks once whether to reset the meter lists;
-- the flag releases when the player leaves so the next entry asks again
local resetAsked
local function CheckInstance()
	local inInst = IsInInstance and IsInInstance() or false
	if inInst and not resetAsked and HasMeterData() then
		resetAsked = true
		if StaticPopup_Show then
			StaticPopup_Show("SENTIUI_METERS_RESET")
		elseif S.Print then
			S.Print(L["Meter data - reset via the window menu."])
		end
	elseif not inInst then
		resetAsked = false
	end
end

function Core.Enable(mod)
	db = mod.db
	-- persisted running totals + per-session last reads (the accumulator
	-- is SavedVariables on purpose: lists must survive reloads)
	db.acc = db.acc or {}
	db.seen = db.seen or {}
	accStore, seenStore = db.acc, db.seen
	-- width slimmed down in 0.1.4: migrate installs still parked on the
	-- old default (a hand-picked width is left alone)
	if db.width == 210 then db.width = 160 end
	for i = 1, MAX_DOCKS do
		local d = BuildDock(i)
		EnsureNative(d, i)
	end
	Layout()
	for i, d in ipairs(docks) do
		S.Movers.Register(d, "meter." .. i, L["Meter"] .. " " .. i)
	end
	RefreshAll()
	-- reset prompt on instance entry (the client keeps sessions across
	-- reloads, so without a wipe the lists would never clear)
	if StaticPopupDialogs then
		StaticPopupDialogs["SENTIUI_METERS_RESET"] = {
			text = L["Reset damage meter data?"],
			button1 = YES or "Yes",
			button2 = NO or "No",
			OnAccept = ResetMeters,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
	end
	S.RegisterEvent("PLAYER_ENTERING_WORLD", CheckInstance)
	S.RegisterEvent("ZONE_CHANGED_NEW_AREA", CheckInstance)
	-- the chat panels may not exist yet when we enable; retry the
	-- default anchor once they had time to spawn (saved positions win)
	C_Timer.After(3, Layout)
	if not ticker then
		ticker = C_Timer.NewTicker(TICK, function()
			for i, d in ipairs(docks) do
				if d:IsShown() then S.SafeCall("meter:upd", UpdateDock, d, d.cfg) end
			end
		end)
	end
	-- clicking anywhere else closes the mode menu
	S.RegisterEvent("PLAYER_REGEN_DISABLED", function()
		if menu then menu:Hide() end
	end)
end

function Core.SettingChanged()
	if not db then return end
	for _, d in ipairs(docks) do
		d:SetSize(db.width, HEADER_H + 4 + db.height + 6)
		for _, r in ipairs(d.rows) do r:SetHeight(db.barHeight) end
	end
	RefreshAll()
end
