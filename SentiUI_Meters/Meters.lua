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
local MAX_ROWS = 30
local TICK = 0.4

local Core = {}
ns.Core = Core
local db
local docks = {}
local ticker

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
local function SessionFor(mtype, segment)
	if not (DM and DM.GetCombatSessionFromType and mtype) then return nil end
	local st = (segment == "overall") and SEG_OVERALL or SEG_CURRENT
	local ok, s = pcall(DM.GetCombatSessionFromType, st, mtype)
	if not ok or type(s) ~= "table" or type(s.combatSources) ~= "table" then
		return nil
	end
	return s
end

local scratch = {}
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
	r = CreateFrame("Frame", nil, dock)
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
	r.name = S.Font(r, 9)
	r.name:SetPoint("LEFT", r, "LEFT", 4, 0)
	r.name:SetPoint("RIGHT", r, "RIGHT", -64, 0)
	r.name:SetJustifyH("LEFT")
	r.name:SetWordWrap(false)
	r.val = S.Font(r, 9, S.colors.textDim)
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

local function UpdateDock(d, cfg)
	local mode = ModeFor(cfg.mode)
	d.title:SetText(mode.label)
	d.seg:SetText(mode.key == "threat" and ""
		or (cfg.segment == "overall" and L["Overall"] or L["Current fight"]))

	local n, top, err
	if mode.key == "threat" then
		n, top, err = CollectThreat()
	else
		n, top, err = CollectMeter(mode, cfg.segment)
	end

	local h = db.barHeight
	local gap = db.spacing
	local show = min(n, db.rows)
	for i = 1, show do
		local src = scratch[i]
		local r = RowAt(d, i)
		r:SetHeight(h)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", d, "TOPLEFT", 4,
			-(HEADER_H + 4 + (i - 1) * (h + gap)))
		r:SetPoint("RIGHT", d, "RIGHT", -4, 0)
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
			txt = txt .. format("  |cff6a6f7d%s|r", Abbrev(src.aps))
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

	local bodyH = (show > 0) and (show * (h + gap)) or h
	d:SetSize(db.width, HEADER_H + 4 + bodyH + 6)
end

Core.UpdateDock = UpdateDock

-- mode/segment menu: one shared popup, rows built once - opening only
-- re-marks the checks against the dock it currently serves
local menu
local function BuildMenu()
	menu = CreateFrame("Frame", "SentiUIMeterMenu", UIParent,
		"BackdropTemplate")
	S.Template(menu, "raised")
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
	menu:SetSize(170, y + 6)
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
	d.title:SetPoint("RIGHT", d, "RIGHT", -46, 0)
	d.title:SetJustifyH("LEFT")
	d.seg = S.Font(d, 8, S.colors.textDim)
	d.seg:SetPoint("TOPRIGHT", d, "TOPRIGHT", -8, -6)
	d.seg:SetJustifyH("RIGHT")
	local hl = S.Line(d, S.colors.accent)
	hl:SetPoint("TOPLEFT", d, "TOPLEFT", 6, -HEADER_H + 2)
	hl:SetPoint("TOPRIGHT", d, "TOPRIGHT", -6, -HEADER_H + 2)

	d.hint = S.Font(d, 9, S.colors.textDim)
	d.hint:SetPoint("CENTER", d, "CENTER", 0, -4)
	d.rows = {}

	d:SetScript("OnMouseUp", function(self, btn)
		if btn == "RightButton" then
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
	end)

	d.cfg = db["dock" .. i]
	docks[i] = d
	return d
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
			elseif i > 1 and docks[i - 1] then
				d:SetPoint("TOPRIGHT", docks[i - 1], "TOPLEFT", -6, 0)
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

function Core.Enable(mod)
	db = mod.db
	for i = 1, 2 do BuildDock(i) end
	Layout()
	for i, d in ipairs(docks) do
		S.Movers.Register(d, "meter." .. i, L["Meter"] .. " " .. i)
	end
	RefreshAll()
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
		for _, r in ipairs(d.rows) do r:SetHeight(db.barHeight) end
	end
	RefreshAll()
end
