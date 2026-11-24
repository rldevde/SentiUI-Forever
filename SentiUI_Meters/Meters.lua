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
-- a session's combatSources can be a SECRET TABLE on this client - type()
-- alone is not enough, iterate-able access must pass the secret checks
local function SourceList(s)
	if type(s) ~= "table" then return nil end
	local cs = s.combatSources
	if type(cs) ~= "table" then return nil end
	if IsSecret(cs) or (S.IsSecretTable and S.IsSecretTable(cs)) then
		return nil
	end
	return cs
end

local function SessionFor(mtype, segment)
	if not (DM and DM.GetCombatSessionFromType and mtype) then return nil end
	local st = (segment == "overall") and SEG_OVERALL or SEG_CURRENT
	local ok, s = pcall(DM.GetCombatSessionFromType, st, mtype)
	if not ok or not SourceList(s) then return nil end
	return s
end

local function SessionByID(id, mtype)
	if not (DM and DM.GetCombatSessionFromID and id) then return nil end
	local ok, s = pcall(DM.GetCombatSessionFromID, id, mtype)
	if not ok or not SourceList(s) then return nil end
	return s
end

-- cfg.segment: "current" | "overall" | "session" (cfg.segId = a past
-- session's id from GetAvailableCombatSessions). A stale/expired id
-- falls back to the live current fight so the dock heals itself
local function SessionForCfg(cfg, mtype)
	if cfg.segment == "session" and IsN(cfg.segId) then
		local s = SessionByID(cfg.segId, mtype)
		if s then return s end
		return SessionFor(mtype, "current")
	end
	return SessionFor(mtype, cfg.segment)
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
		for _, src in ipairs(SourceList(session) or {}) do
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
							spec = Plain(src.specIconID),
							guid = Plain(src.sourceGUID),
							total = 0,
							self_ = Plain(src.isLocalPlayer) == true or nil,
						}
						acc.rows[key] = row
					end
					row.total = row.total + d
					local nm = Plain(src.name)
					if nm then row.name = nm end
					local sp = Plain(src.specIconID)
					if sp then row.spec = sp end
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
			spec = row.spec,
			guid = row.guid
				or ((type(key) == "string" and key:sub(1, 7) == "Player-")
					and key or nil),
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

-- fills scratch with { name, cls, guid, spec, total, aps }; returns
-- count, max
local function CollectMeter(mode, cfg)
	wipe(scratch)
	local s = SessionForCfg(cfg, mode.type)
	local cs = s and SourceList(s)
	if not cs then return 0, 0, true end
	-- combat meter values come back SECRET while a fight runs: keep them
	-- raw (bars/text/guid lookups go through the engine, which reads
	-- secrets fine), and keep the engine's source order since comparing
	-- or sorting secrets in Lua throws
	local anySecret = false
	for _, src in ipairs(cs) do
		local total = src.totalAmount
		if total ~= nil then
			local aps = src.amountPerSecond
			if IsSecret(total) or IsSecret(aps) then anySecret = true end
			scratch[#scratch + 1] = {
				name = src.name, -- may be secret: FontString renders it
				cls = Plain(src.classFilename),
				guid = src.sourceGUID, -- raw: engine accepts secret guids
				spec = Plain(src.specIconID),
				total = total,
				aps = (aps ~= nil) and aps or 0,
				self_ = src.isLocalPlayer == true or nil,
			}
		end
	end
	if not anySecret then
		sort(scratch, function(a, b)
			local va = mode.perSec and a.aps or a.total
			local vb = mode.perSec and b.aps or b.total
			return va > vb
		end)
	end
	local top = scratch[1]
		and (mode.perSec and scratch[1].aps or scratch[1].total) or 0
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
	local any, top, anySecret = false, 0, false
	for _, u in ipairs(units) do
		local okU, ex = pcall(UnitExists, u)
		if okU and ex then
			local okT, tanking, status, pct, rawpct = pcall(UDTS, u, mob)
			if okT then
				-- prefer a plain read; fall back to the raw (secret) value -
				-- the engine formats/scales it, Lua just cannot inspect it
				local p = Plain(pct) or Plain(rawpct)
					or (pct ~= nil and pct or rawpct)
				if p ~= nil then
					any = true
					if IsSecret(p) then anySecret = true
					elseif p > top then top = p end
					local okN, nm = pcall(GetUnitName or UnitName, u)
					local cls
					local okC, _, cf = pcall(UnitClass, u)
					if okC then cls = Plain(cf) end
					scratch[#scratch + 1] = {
						name = (okN and nm) or u, -- raw: may be secret
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
	if not anySecret then
		sort(scratch, function(a, b) return a.total > b.total end)
		top = max(top, 100)
	end
	-- secret top: hand the first row's raw value to the bars; plain top
	-- never drops under 100 % so a pull at 110 % does not overflow
	if IsSecret(top) or top <= 0 then top = scratch[1].total end
	return #scratch, top, false
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
	-- fill is a StatusBar, not a width-driven texture: combat meter values
	-- are SECRET numbers on this client and Lua cannot do width math on
	-- them - the engine scales SetMinMaxValues/SetValue just fine
	r.fill = CreateFrame("StatusBar", nil, r)
	r.fill:SetPoint("TOPLEFT", r, "TOPLEFT", 1, -1)
	r.fill:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -1, 1)
	r.fill:SetStatusBarTexture(BLANK)
	r.fill:SetMinMaxValues(0, 1)
	r.fill:SetValue(0)
	r.fillTex = r.fill:GetStatusBarTexture()
	-- text/icon holder ABOVE the StatusBar: the fill is a widget frame
	-- now, its texture renders on its own frame level over plain row
	-- textures - text created directly on the row got half-painted over
	-- and read as washed-out grey
	r.texts = CreateFrame("Frame", nil, r)
	r.texts:SetAllPoints()
	r.texts:SetFrameLevel(r.fill:GetFrameLevel() + 2)
	-- accent edge for the row leader (rank 1) - signature tick
	r.edge = r.texts:CreateTexture(nil, "OVERLAY")
	r.edge:SetTexture(BLANK)
	r.edge:SetSize(2, 0)
	r.edge:SetPoint("TOPLEFT", r.texts, "TOPLEFT", 0, -1)
	r.edge:SetPoint("BOTTOMLEFT", r.texts, "BOTTOMLEFT", 0, 1)
	r.edge:SetVertexColor(0.92, 0.68, 0.20, 0.0)
	-- spec icon from specIconID (Details reads the same field); hidden
	-- when the client does not expose one - never a placeholder square
	r.icon = r.texts:CreateTexture(nil, "ARTWORK")
	r.icon:SetSize(10, 10)
	r.icon:SetPoint("LEFT", r.texts, "LEFT", 3, 0)
	-- OUTLINE + black drop shadow on row text: the class-colored
	-- fill behind it makes plain 9pt text unreadable
	r.name = S.Font(r.texts, 9, S.colors.text, "OUTLINE")
	r.name:SetPoint("LEFT", r, "LEFT", 4, 0)
	r.name:SetPoint("RIGHT", r, "RIGHT", -64, 0)
	r.name:SetJustifyH("LEFT")
	r.name:SetWordWrap(false)
	r.name:SetShadowOffset(1, -1)
	r.name:SetShadowColor(0, 0, 0, 0.9)
	r.val = S.Font(r.texts, 9, S.colors.text, "OUTLINE")
	r.val:SetPoint("RIGHT", r.texts, "RIGHT", -4, 0)
	r.val:SetJustifyH("RIGHT")
	r.val:SetWordWrap(false)
	r.val:SetShadowOffset(1, -1)
	r.val:SetShadowColor(0, 0, 0, 0.9)
	-- left-click opens the spell breakdown for this source
	r:EnableMouse(true)
	r:SetScript("OnMouseUp", function(self, btn)
		if btn == "LeftButton" and self.src then
			ShowSpells(dock, self.src)
		end
	end)
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
local ShowSpells -- forward: row clicks open the spell breakdown

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
	local segLbl = cfg.segment == "session"
		and (cfg.segName or ("#" .. tostring(cfg.segId)))
		or (cfg.segment == "overall" and L["Overall"] or L["Current fight"])
	d.seg:SetText(mode.key == "threat" and "" or segLbl)
	d.mode = mode -- row clicks read metric+segment for the spell view

	local n, top, err
	if mode.key == "threat" then
		n, top, err = CollectThreat()
	elseif cfg.segment == "overall" then
		n, top, err = CollectOverall(mode)
	else
		n, top, err = CollectMeter(mode, cfg)
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
		-- StatusBar path: secret combat values scale engine-side. A secret
		-- or missing top falls back to a 0..1 range so rows still draw.
		local topv = IsN(top) and max(top, 0.001) or (top ~= nil and top or 1)
		r.fill:SetMinMaxValues(0, topv)
		r.fill:SetValue(v ~= nil and v or 0)
		r.src = src
		if src.spec then
			r.icon:SetTexture(src.spec)
			r.icon:Show()
			r.name:ClearAllPoints()
			r.name:SetPoint("LEFT", r, "LEFT", 16, 0)
			r.name:SetPoint("RIGHT", r, "RIGHT", -64, 0)
		else
			r.icon:Hide()
			r.name:ClearAllPoints()
			r.name:SetPoint("LEFT", r, "LEFT", 4, 0)
			r.name:SetPoint("RIGHT", r, "RIGHT", -64, 0)
		end
		local cr, cg, cb = ClassColor(src.cls)
		-- class colour as a muted tint (58 %): saturated fills made the
		-- white row text unreadable, 38 % killed the colours entirely
		if IsN(cr) and IsN(cg) and IsN(cb) then
			cr, cg, cb = cr * 0.58, cg * 0.58, cb * 0.58
		end
		r.fillTex:SetVertexColor(cr, cg, cb, 0.9)
		r.edge:SetVertexColor(0.92, 0.68, 0.20,
			(i == 1 or src.tank or src.self_) and 0.9 or 0.0)
		-- never compare a (possibly secret) guid in Lua: isLocalPlayer is
		-- the one field the game never keeps secret
		local isMe = src.self_ == true
			or (src.guid ~= nil and not IsSecret(src.guid)
				and src.guid == PlayerGUID())
		if not pcall(r.name.SetText, r.name, src.name or "?") then
			r.name:SetText("?") -- a secret name SetText refused
		end
		local c = isMe and S.colors.accent or S.colors.text
		r.name:SetTextColor(c.r, c.g, c.b)
		if mode.key == "threat" then
			-- engine-side formatting takes secret percents too
			r.val:SetFormattedText("%.0f%%", v ~= nil and v or 0)
		elseif IsN(v) then
			local txt = Abbrev(v)
			if IsN(src.aps) and src.aps > 0 and not mode.perSec then
				txt = txt .. format("  |cff9aa3b5%s|r", Abbrev(src.aps))
			end
			r.val:SetText(txt)
		else
			-- secret number: AbbreviateNumbers formats it engine-side;
			-- the raw value as a last resort
			local shown
			if AbbreviateNumbers then
				local okA, ab = pcall(AbbreviateNumbers, v)
				if okA and ab ~= nil then shown = ab end
			end
			r.val:SetFormattedText("%s", shown ~= nil and shown or v)
		end
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

-- spell breakdown: left-click a row -> the player's top spells for the
-- dock's metric+segment, via GetCombatSessionSourceFrom* (the same read
-- Details uses for its own spell views). Spell ids/names can be secret -
-- every field goes through Plain before it reaches a texture or font
local spellWin
local SPELL_ROWS = 12

local function SpellRow(win, i)
	local r = win.rows[i]
	if r then return r end
	r = CreateFrame("Frame", nil, win)
	r:SetHeight(16)
	r.bg = r:CreateTexture(nil, "BACKGROUND")
	r.bg:SetAllPoints()
	r.bg:SetTexture(BLANK)
	r.bg:SetVertexColor(0.03, 0.04, 0.06, 0.7)
	-- StatusBar for the same reason as the meter rows: spell totals can
	-- be secret during combat, the engine scales the fill for us
	r.fill = CreateFrame("StatusBar", nil, r)
	r.fill:SetPoint("TOPLEFT", r, "TOPLEFT", 1, -1)
	r.fill:SetPoint("BOTTOMRIGHT", r, "BOTTOMRIGHT", -1, 1)
	r.fill:SetStatusBarTexture(BLANK)
	r.fill:SetMinMaxValues(0, 1)
	r.fill:SetValue(0)
	r.fill:GetStatusBarTexture():SetVertexColor(0.92, 0.68, 0.20, 0.25)
	-- same as the meter rows: icon + text must sit above the StatusBar
	r.texts = CreateFrame("Frame", nil, r)
	r.texts:SetAllPoints()
	r.texts:SetFrameLevel(r.fill:GetFrameLevel() + 2)
	r.icon = r.texts:CreateTexture(nil, "ARTWORK", nil, 2)
	r.icon:SetSize(12, 12)
	r.icon:SetPoint("LEFT", r.texts, "LEFT", 3, 0)
	r.name = S.Font(r.texts, 9, S.colors.text, "OUTLINE")
	r.name:SetPoint("LEFT", r.texts, "LEFT", 19, 0)
	r.name:SetPoint("RIGHT", r.texts, "RIGHT", -56, 0)
	r.name:SetJustifyH("LEFT")
	r.name:SetWordWrap(false)
	r.name:SetShadowOffset(1, -1)
	r.name:SetShadowColor(0, 0, 0, 0.9)
	r.val = S.Font(r.texts, 9, S.colors.textDim, "OUTLINE")
	r.val:SetShadowOffset(1, -1)
	r.val:SetShadowColor(0, 0, 0, 0.9)
	r.val:SetPoint("RIGHT", r, "RIGHT", -4, 0)
	r.val:SetJustifyH("RIGHT")
	win.rows[i] = r
	return r
end

local function BuildSpellWin()
	spellWin = CreateFrame("Frame", "SentiUIMeterSpells", UIParent,
		"BackdropTemplate")
	S.Template(spellWin, "raised")
	spellWin:SetClampedToScreen(true)
	spellWin:SetFrameStrata("DIALOG")
	spellWin:EnableMouse(true)
	spellWin.title = S.Font(spellWin, 10, S.colors.accent)
	spellWin.title:SetPoint("TOPLEFT", spellWin, "TOPLEFT", 8, -6)
	spellWin.title:SetPoint("RIGHT", spellWin, "RIGHT", -24, 0)
	spellWin.title:SetJustifyH("LEFT")
	spellWin.sub = S.Font(spellWin, 8, S.colors.textDim)
	spellWin.sub:SetPoint("TOPLEFT", spellWin.title, "BOTTOMLEFT", 0, -2)
	spellWin.sub:SetJustifyH("LEFT")
	local ln = S.Line(spellWin, S.colors.accent)
	ln:SetPoint("TOPLEFT", spellWin, "TOPLEFT", 8, -32)
	ln:SetPoint("TOPRIGHT", spellWin, "TOPRIGHT", -8, -32)
	local cls = CreateFrame("Button", nil, spellWin)
	cls:SetSize(14, 14)
	cls:SetPoint("TOPRIGHT", spellWin, "TOPRIGHT", -4, -4)
	local cfs = S.Font(cls, 10, S.colors.textDim)
	cfs:SetPoint("CENTER")
	cfs:SetText("x")
	cls:SetScript("OnClick", function() spellWin:Hide() end)
	spellWin.rows = {}
	if S.EscClosable then S.EscClosable(spellWin) end
	spellWin:Hide()
end

-- the per-source spell container: FromID for a picked session, FromType
-- for live/overall. Returns nil when the client does not expose it
local function SourceSpells(cfg, mode, guid)
	-- guid can be a secret string mid-fight: type() would reject it but
	-- the engine lookup accepts secrets - only nil is unusable
	if not DM or guid == nil then return nil end
	local ok, s
	if cfg.segment == "session" and IsN(cfg.segId)
		and DM.GetCombatSessionSourceFromID then
		ok, s = pcall(DM.GetCombatSessionSourceFromID,
			cfg.segId, mode.type, guid)
	elseif DM.GetCombatSessionSourceFromType then
		local st = (cfg.segment == "overall") and SEG_OVERALL or SEG_CURRENT
		ok, s = pcall(DM.GetCombatSessionSourceFromType,
			st, mode.type, guid)
	end
	if not ok or type(s) ~= "table" then return nil end
	if IsSecret(s) or (S.IsSecretTable and S.IsSecretTable(s)) then
		return nil
	end
	return s
end

local function SpellName(sp)
	local n = Plain(sp.creatureName)
	if n then return n end
	local id = sp.spellID -- raw: GetSpellInfo resolves secret ids engine-side
	if id ~= nil and C_Spell and C_Spell.GetSpellInfo then
		local ok, info = pcall(C_Spell.GetSpellInfo, id)
		if ok and type(info) == "table"
			and type(info.name) == "string" and not IsSecret(info.name) then
			return info.name
		end
	end
	if IsN(id) then return "#" .. tostring(id) end
	return "?"
end

local spellScratch = {}

ShowSpells = function(d, src)
	local cfg, mode = d.cfg, d.mode
	if not (cfg and mode and mode.type and src.guid) then return end
	if not spellWin then BuildSpellWin() end
	local s = SourceSpells(cfg, mode, src.guid)
	spellWin.title:SetText(tostring(src.name or "?"))
	local segLbl = cfg.segment == "session"
		and (cfg.segName or ("#" .. tostring(cfg.segId)))
		or (cfg.segment == "overall" and L["Overall"] or L["Current fight"])
	spellWin.sub:SetText(mode.label .. " - " .. segLbl)

	wipe(spellScratch)
	local anySecret = false
	if s then
		local cs = s.combatSpells
		if type(cs) == "table"
			and not (S.IsSecretTable and S.IsSecretTable(cs)) then
			for _, sp in ipairs(cs) do
				local total = sp.totalAmount -- raw: may be secret in combat
				if total ~= nil then
					if IsSecret(total) then anySecret = true end
					spellScratch[#spellScratch + 1] = {
						name = SpellName(sp),
						icon = sp.spellID, -- raw: engine resolves secret ids
						total = total,
					}
				end
			end
		end
	end
	if not anySecret then
		sort(spellScratch, function(a, b) return a.total > b.total end)
	end

	local n = min(#spellScratch, SPELL_ROWS)
	local top = n > 0 and spellScratch[1].total or 0
	local topv = IsN(top) and max(top, 0.001) or (top ~= nil and top or 1)
	for i = 1, n do
		local sp = spellScratch[i]
		local r = SpellRow(spellWin, i)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", spellWin, "TOPLEFT", 6, -(36 + (i - 1) * 17))
		r:SetPoint("TOPRIGHT", spellWin, "TOPRIGHT", -6, -(36 + (i - 1) * 17))
		r.fill:SetMinMaxValues(0, topv)
		r.fill:SetValue(sp.total)
		local tex
		if sp.icon and C_Spell and C_Spell.GetSpellTexture then
			local okT, t = pcall(C_Spell.GetSpellTexture, sp.icon)
			if okT then tex = t end
		end
		if tex then r.icon:SetTexture(tex) r.icon:Show()
		else r.icon:Hide() end
		r.name:SetText(sp.name)
		if IsN(sp.total) then
			r.val:SetText(Abbrev(sp.total))
		else
			local shown
			if AbbreviateNumbers then
				local okA, ab = pcall(AbbreviateNumbers, sp.total)
				if okA and ab ~= nil then shown = ab end
			end
			r.val:SetFormattedText("%s", shown ~= nil and shown or sp.total)
		end
		r:Show()
	end
	for i = n + 1, #spellWin.rows do spellWin.rows[i]:Hide() end
	if n == 0 then
		local r = SpellRow(spellWin, 1)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", spellWin, "TOPLEFT", 6, -36)
		r:SetPoint("TOPRIGHT", spellWin, "TOPRIGHT", -6, -36)
		r.fill:SetMinMaxValues(0, 1)
		r.fill:SetValue(0)
		r.icon:Hide()
		r.name:SetText(L["No spell data"])
		r.val:SetText("")
		r:Show()
	end
	spellWin:SetHeight(36 + max(n, 1) * 17 + 10)
	spellWin:SetWidth(230)
	spellWin:ClearAllPoints()
	spellWin:SetPoint("TOPRIGHT", d, "TOPLEFT", -4, 0)
	spellWin:Show()
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
			if self.row.mode then
				cfg.mode = self.row.mode
			else
				cfg.segment = self.row.seg
				cfg.segId, cfg.segName = nil, nil
			end
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
	-- session-history rows are pooled and laid out by ShowMenu; the
	-- separator + tail buttons get anchored below whatever it produced
	menu.sessY = y
	menu.sessRows = {}
	menu.line2 = S.Line(menu, S.colors.border)
	-- tail buttons are re-anchored by ShowMenu below the session rows
	local function Tail(txt, accent, fn)
		local b = CreateFrame("Button", nil, menu)
		b:SetHeight(18)
		local hl2 = b:CreateTexture(nil, "HIGHLIGHT")
		hl2:SetAllPoints()
		hl2:SetColorTexture(0.92, 0.68, 0.20, 0.08)
		b.fs = S.Font(b, 10, accent and S.colors.accent or S.colors.textDim)
		b.fs:SetPoint("LEFT", 8, 0)
		b.fs:SetText(txt)
		b:SetScript("OnClick", fn)
		return b
	end
	-- "+ New window": turns the next pool dock on and chains it to the
	-- left of the shown ones (toward the action bars); hidden once all
	-- four docks are live
	local add = Tail("+ " .. L["New window"], true, function()
		AddDock()
		menu:Hide()
	end)
	menu.addBtn = add
	-- "Reset data": same prompt the instance-join check raises
	local rst = Tail(L["Reset data"], false, function()
		menu:Hide()
		if StaticPopup_Show then
			StaticPopup_Show("SENTIUI_METERS_RESET")
		else
			ResetMeters()
		end
	end)
	menu.resetBtn = rst
	-- "Close window": same effect as the title x - turns this dock off
	local cls = Tail(L["Close window"], false, function()
		if menu.dock and menu.dock.cfg then
			menu.dock.cfg.enabled = false
		end
		menu:Hide()
		Core.RefreshAll()
	end)
	menu.tail = { add, rst, cls }
	menu:SetSize(170, 400)
	menu:SetScript("OnHide", function() menu.dock, menu.cfg = nil, nil end)
	if S.EscClosable then S.EscClosable(menu) end
	menu:Hide()
end

-- pooled session-history row: same look as the static Items, but laid
-- out fresh each open (sessions come and go)
local MAX_SESS_ROWS = 8
local function SessRowAt(i)
	local b = menu.sessRows[i]
	if b then return b end
	b = CreateFrame("Button", nil, menu)
	b:SetHeight(18)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(0.92, 0.68, 0.20, 0.08)
	b.fs = S.Font(b, 10, S.colors.text)
	b.fs:SetPoint("LEFT", 8, 0)
	b.chk = S.Font(b, 10, S.colors.accent)
	b.chk:SetPoint("RIGHT", -4, 0)
	b:SetScript("OnClick", function(self)
		local cfg = menu.cfg
		if not cfg then menu:Hide() return end
		if self.row then
			cfg.segment = "session"
			cfg.segId = self.row.segId
			cfg.segName = self.row.segName
			UpdateDock(menu.dock, cfg)
		end
		menu:Hide()
	end)
	menu.sessRows[i] = b
	return b
end

-- past sessions newest-first; names/ids can be secret so both go
-- through Plain
local function SessionList()
	local list = {}
	if not (DM and DM.GetAvailableCombatSessions) then return list end
	local ok, l = pcall(DM.GetAvailableCombatSessions)
	if not ok or type(l) ~= "table"
		or (S.IsSecretTable and S.IsSecretTable(l)) then
		return list
	end
	for idx = #l, 1, -1 do
		local info = l[idx]
		if type(info) == "table" and not IsSecret(info)
			and not (S.IsSecretTable and S.IsSecretTable(info)) then
			local id = Plain(info.sessionID)
			if id then
				list[#list + 1] = {
					id = id,
					name = Plain(info.name) or (L["Session"] .. " " .. id),
				}
			end
		end
		if #list >= MAX_SESS_ROWS then break end
	end
	return list
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
	-- session history under the two fixed segment rows
	local list = SessionList()
	local y = menu.sessY
	for i = 1, MAX_SESS_ROWS do
		local b = SessRowAt(i)
		local s = list[i]
		if s then
			b.row = { segId = s.id, segName = s.name }
			b.fs:SetText(s.name)
			local on = cfg.segment == "session" and cfg.segId == s.id
			b.chk:SetText(on and "v" or "")
			local c = on and S.colors.accent or S.colors.textDim
			b.fs:SetTextColor(c.r, c.g, c.b)
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -y)
			b:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, -y)
			b:Show()
			y = y + 19
		else
			b:Hide()
		end
	end
	menu.line2:ClearAllPoints()
	menu.line2:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -(y + 2))
	menu.line2:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -8, -(y + 2))
	y = y + 8
	-- "+ New window" only while a pool slot is still off
	local hasFree = NextFreeDock() ~= nil
	for _, btn in ipairs(menu.tail) do
		if btn == menu.addBtn and not hasFree then
			btn:Hide()
		else
			btn:ClearAllPoints()
			btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -y)
			btn:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -6, -y)
			btn:Show()
			y = y + 19
		end
	end
	menu:SetHeight(y + 6)
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
		GameTooltip:AddLine(L["Left-click a row: spell details"], 0.55, 0.57, 0.62)
		GameTooltip:Show()
	end)
	d:SetScript("OnLeave", function() GameTooltip:Hide() end)
	d:SetScript("OnHide", function()
		if menu and menu.dock == d then menu:Hide() end
		if spellWin and spellWin:IsShown() then spellWin:Hide() end
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
		if cfg.enabled then UpdateDock(d, cfg) end
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
	for i = 1, MAX_DOCKS do BuildDock(i) end
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
