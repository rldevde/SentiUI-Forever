-- SentiUI action bars: the game's own action-button template, detached
-- from its event dispatch and painted from our own events. Same
-- architecture the proven bars use on this client: the template's OnLoad
-- signs every created button up for the game's per-button update lists
-- (ActionBarButtonEventsFrame and friends), and that dispatch runs the
-- game's button code - attributes, shown state - under whoever made the
-- button's taint. In a fight every one of those writes lands as an
-- ADDON_ACTION_BLOCKED "UNKNOWN()". Unlisted buttons and parked game
-- bars make that impossible: nothing shared runs on our buttons, and
-- keybinds keep pressing the game's hidden twins, which the secure page
-- driver points at the slot our button shows.
local _, ns = ...
local S = SentiUI
local L = ns.L

local format, ipairs, math = string.format, ipairs, math
local CreateFrame, InCombatLockdown = CreateFrame, InCombatLockdown
local CA = C_ActionBar or {}

-- strtrim is a FrameXML global and not guaranteed on this client.
local strtrim = strtrim or function(s)
	return (tostring(s or ""):match("^%s*(.-)%s*$"))
end
local GetActionTexture = CA.GetActionTexture or GetActionTexture
local GetActionText = CA.GetActionText or GetActionText
local HasAction = CA.HasAction or HasAction
local GetActionUseCount = CA.GetActionUseCount or GetActionCount
local GetActionDisplayCount = CA.GetActionDisplayCount
local GetActionCharges = CA.GetActionCharges or GetActionCharges
local GetActionCooldown = CA.GetActionCooldown or GetActionCooldown
local GetActionCooldownDuration = CA.GetActionCooldownDuration
local GetActionLossOfControlCooldownInfo = CA.GetActionLossOfControlCooldownInfo
local GetActionLossOfControlCooldownDuration = CA.GetActionLossOfControlCooldownDuration
local GetActionChargeDuration = CA.GetActionChargeDuration
local IsActionInRange = CA.IsActionInRange or IsActionInRange
local IsUsableAction = CA.IsUsableAction or IsUsableAction
local IsCurrentAction = CA.IsCurrentAction or IsCurrentAction
local IsAutoRepeatAction = CA.IsAutoRepeatAction or IsAutoRepeatAction
local GetBindingKey, GetBindingText = GetBindingKey, GetBindingText
local unpack_ = unpack or table.unpack
local BLANK = [[Interface\Buttons\WHITE8X8]]

ns.Core = ns.Core or {}
local Core = ns.Core

-- shared small helpers -------------------------------------------------------
local function logErr(ctx, err)
	S.Print(format("|cffff5555%s: %s\n%s|r", tostring(ctx), tostring(err),
		S.Stack and S.Stack(2) or ""))
end
ns.logErr = logErr

local function SC(n)
	local g = S.DB.General()
	return n * ((g and g.uiScale) or 1)
end
ns.SC = SC

local function KillTexture(t)
	if not t then return end
	pcall(t.SetTexture, t, nil)
	pcall(t.SetAlpha, t, 0)
	pcall(t.Hide, t)
end
ns.KillTexture = KillTexture

local function SetInside(tex, parent, padX, padY)
	padX, padY = padX or 0, padY or 0
	tex:ClearAllPoints()
	tex:SetPoint("TOPLEFT", parent, "TOPLEFT", padX, -padY)
	tex:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padX, padY)
end
ns.SetInside = SetInside

local function SetFont(fs, size, flags)
	if not fs then return end
	-- the client rejects float sizes: round before SetFont
	pcall(fs.SetFont, fs, S.media.font, math.floor((size or 12) + 0.5), flags or "")
	pcall(fs.SetShadowColor, fs, 0, 0, 0, 0)
end
ns.SetFont = SetFont

-- centralised in the core: S.Call is the labelled pcall that names the
-- api + call site (file.lua:line) once when the client refuses it
ns.Call = S.Call
ns.Sec = S.Call

-- template detachment ---------------------------------------------------------
-- ActionBarButtonEventsFrame.frames is an indexed list (nil in place: a
-- removal would shift the game's own entries); the action/update frames
-- key their lists by the button itself.
local function UnlistButton(btn)
	local ef = _G.ActionBarButtonEventsFrame
	local frames = type(ef) == "table" and ef.frames
	if type(frames) ~= "table" then return end
	if frames[#frames] == btn then frames[#frames] = nil return end
	for k, v in pairs(frames) do
		if v == btn then frames[k] = nil return end
	end
end

local function UnwatchButton(btn)
	for _, name in ipairs({ "ActionBarActionEventsFrame", "ActionBarButtonUpdateFrame" }) do
		local f = _G[name]
		if type(f) == "table" and type(f.frames) == "table" then f.frames[btn] = nil end
	end
	btn.eventsRegistered = nil
	btn.needsUpdate = nil
	btn.stateDirty = nil
	btn.flashDirty = nil
	btn.flashing = 0
	if type(btn.Flash) == "table" then btn.Flash:Hide() end
end

-- template methods that re-enter the game's watchers or write attributes
-- from tainted dispatch: silenced on our buttons.
local function stayOut() end

-- painting ----------------------------------------------------------------------
local db
local bars = {}          -- id -> bar { holder=..., buttons=..., def=..., dbBar=... }
local allButtons = {}    -- every created button, in order

local function SlotOf(btn)
	local a = btn:GetAttribute("action")
	if type(a) == "number" then return a end
end

-- the pick-up modifier: Shift only, matching the game's default. The
-- remappable IsModifiedClick("PICKUPACTION") can answer truthy on this
-- client without the key being down, which made EVERY press a pickup.
local function PickupModifierHeld()
	return IsShiftKeyDown and IsShiftKeyDown() == true
end

-- drag-pickup allowed: modifier held, or action bars unlocked
local function CanPickUp()
	if PickupModifierHeld() then return true end
	local ok, locked = pcall(GetCVarBool, "lockActionBars")
	return ok and locked == false
end

-- out-of-range memory: checked on a slow watch while a target exists
local function PaintIcon(btn, slot)
	local icon = btn.icon
	if not icon then return end
	local tex = GetActionTexture(slot)
	icon:SetTexture(tex)
	icon:SetShown(tex ~= nil)
	-- dim the slot body for empty buttons: a full-opacity dark Roundize fill
	-- reads as a prominent black square; 18% makes the slot barely visible
	-- while keeping the grid readable (similar to ElvUI / DaylightUI behavior)
	if btn.SetRoundFill then
		local c = S.colors.bgInset
		btn:SetRoundFill(c.r, c.g, c.b, tex and 1 or 0.18)
	end
end

local function PaintCount(btn, slot)
	local fs = btn.count
	if not fs then return end
	if db.counts == false then fs:SetText("") return end
	local c
	if GetActionTexture(slot) ~= nil and GetActionDisplayCount then
		c = GetActionDisplayCount(slot)
	end
	if (c == nil or S.IsSecret(c)) and GetActionUseCount then
		local n = GetActionUseCount(slot)
		if not S.IsSecret(n) and type(n) == "number" and n > 1 then c = n end
	end
	fs:SetText(c == nil and "" or c)
end

local function PaintName(btn, slot)
	local fs = btn.name
	if not fs then return end
	fs:SetText((db.macroNames ~= false) and GetActionText(slot) or "")
end

local function PaintChecked(btn, slot)
	local cur = IsCurrentAction and IsCurrentAction(slot) == true
	local auto = IsAutoRepeatAction and IsAutoRepeatAction(slot) == true
	local eq = IsEquippedAction and IsEquippedAction(slot) == true
	btn:SetChecked(cur or auto or eq)
	-- green edge for equipped items, accent for the active cast
	if btn.checkedTex then
		if eq and not (cur or auto) then
			btn.checkedTex:SetVertexColor(0.2, 0.9, 0.2, 0.45)
		else
			local C = S.colors
			btn.checkedTex:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.4)
		end
	end
end

local function PaintUsable(btn, slot, usable, noMana)
	local icon = btn.icon
	if not icon then return end
	if usable == nil or noMana == nil then
		usable, noMana = IsUsableAction and IsUsableAction(slot)
	end
	local r, g, b = 1, 1, 1
	if noMana == true then r, g, b = 0.35, 0.5, 1
	elseif usable == false then r, g, b = 0.4, 0.4, 0.4 end
	if btn.outOfRange and db.rangeColor ~= false then r, g, b = 1, 0.25, 0.25 end
	icon:SetVertexColor(r, g, b, 1)
end

local function PaintRange(btn, slot)
	local out = IsActionInRange and IsActionInRange(slot) == false or false
	if btn.outOfRange ~= out then
		btn.outOfRange = out
		PaintUsable(btn, slot)
	end
end

local function PaintEquipped(btn, slot) PaintChecked(btn, slot) end

-- cooldown sweep: never inspect isActive / startTime / duration in Lua -
-- those values are secret/tainted and comparisons throw under addon taint.
-- Pass the raw info table straight to the Blizzard C++ layer: CooldownFrame_Set
-- reads start+duration internally and shows or hides the animation without
-- any Lua logic. DurationObject via SetCooldownFromDurationObject is tried
-- first (zero Lua comparison); CooldownFrame_Set is the main fallback; and
-- cd:SetCooldown (the direct frame method) handles clients where the global
-- does not exist. (AGENTS: "pass raw values to CooldownFrame_Set without
-- inspecting them")
local function sweep(cd, info, durFn)
	if type(cd) ~= "table" then return end
	if type(info) == "table" then
		if durFn then
			local dur = durFn()
			if dur and cd.SetCooldownFromDurationObject then
				pcall(cd.SetCooldownFromDurationObject, cd, dur)
				return
			end
		end
		if CooldownFrame_Set then
			pcall(CooldownFrame_Set, cd, info.startTime, info.duration,
				info.isEnabled, false, info.modRate)
		else
			-- some clients lack the FrameXML global; use the frame method
			pcall(cd.SetCooldown, cd, info.startTime, info.duration,
				info.modRate)
		end
	end
end

local function cdClear(cd)
	if type(cd) ~= "table" then return end
	if cd.Clear then pcall(cd.Clear, cd)
	elseif CooldownFrame_Clear then pcall(CooldownFrame_Clear, cd) end
end

-- cooldown desaturation watch: natural cooldown expiry fires no event
-- on this client, so buttons grayed by an active sweep are re-checked
-- on a frame ticker and un-grayed when the widget stops sweeping
local dimmed, dimWatcher = {}, nil

-- a finished cooldown flashes a warm gold sheen across the icon; pure
-- region ops on the pre-built readyFlash, so it works mid-fight. The
-- ticker sleeps whenever no flash is in flight
local flashes, flashTicker = {}, nil
local function FlashReady(btn)
	if db.readyPulse == false or not btn.readyFlash then return end
	btn._flashT = 0
	flashes[btn] = true
	if flashTicker then flashTicker:Show() return end
	flashTicker = CreateFrame("Frame")
	flashTicker:SetScript("OnUpdate", function(_, dt)
		for b in pairs(flashes) do
			b._flashT = (b._flashT or 0) + (dt or 0.016)
			local t, dur = b._flashT, 0.45
			if t >= dur then
				flashes[b] = nil
				if b.readyFlash then b.readyFlash:Hide() end
			else
				local k = 1 - t / dur
				b.readyFlash:SetAlpha(0.9 * k * k)
				b.readyFlash:Show()
			end
		end
		if not next(flashes) then flashTicker:Hide() end
	end)
end

local function WatchDim(btn)
	dimmed[btn] = true
	if dimWatcher then dimWatcher:Show() return end
	dimWatcher = CreateFrame("Frame")
	local acc = 0
	dimWatcher:SetScript("OnUpdate", function(_, dt)
		acc = acc + (dt or 0.016)
		if acc < 0.1 then return end
		acc = 0
		for b in pairs(dimmed) do
			local cd = b.cooldown
			if not (cd and cd.IsShown and cd:IsShown()) then
				dimmed[b] = nil
				b._cdDim = nil
				if b.icon and b.icon.SetDesaturated then
					pcall(b.icon.SetDesaturated, b.icon, false)
				end
				FlashReady(b)
			end
		end
		if not next(dimmed) then dimWatcher:Hide() end
	end)
end

local function PaintCooldown(btn, slot)
	if not GetActionCooldown then return end
	local icon = btn.icon
	local function setDim(on)
		if btn._cdDim == on then return end
		btn._cdDim = on
		if icon and icon.SetDesaturated then
			pcall(icon.SetDesaturated, icon, on)
		end
	end
	if GetActionTexture(slot) == nil or db.cooldownDim == false then
		cdClear(btn.lossOfControlCooldown)
		cdClear(btn.cooldown)
		cdClear(btn.chargeCooldown)
		setDim(false)
		dimmed[btn] = nil
		return
	end
	local loc = GetActionLossOfControlCooldownInfo
		and GetActionLossOfControlCooldownInfo(slot)
	sweep(btn.lossOfControlCooldown, loc,
		GetActionLossOfControlCooldownDuration
			and function() return GetActionLossOfControlCooldownDuration(slot) end)
	local info = GetActionCooldown(slot)
	sweep(btn.cooldown, info,
		GetActionCooldownDuration
			and function() return GetActionCooldownDuration(slot) end)
	local charges = GetActionCharges and GetActionCharges(slot)
	sweep(btn.chargeCooldown, charges,
		GetActionChargeDuration
			and function() return GetActionChargeDuration(slot) end)
	-- gray while the main cooldown widget sweeps: the widget's shown
	-- state is the only engine-readable flag here - every cooldown
	-- return value can be secret on this client. Charge abilities keep
	-- their color on the charge sweep (chargeCooldown), they only gray
	-- when the main cooldown itself runs.
	local onCD = btn.cooldown and btn.cooldown.IsShown
		and btn.cooldown:IsShown() or false
	setDim(onCD == true)
	if onCD == true then WatchDim(btn) end
end

local function PaintProc(btn, slot)
	local M = ActionButtonSpellAlertManager
	local O = C_SpellActivationOverlay
	if not M or not O or not O.IsSpellOverlayed then return end
	local kind, id = GetActionInfo and GetActionInfo(slot)
	local spell = (kind == "spell" and id)
		or (kind == "macro" and GetMacroSpell and GetMacroSpell(id))
	local on = type(spell) == "number" and O.IsSpellOverlayed(spell) == true
	if btn._proc == on then return end
	btn._proc = on
	if on then M:ShowAlert(btn) else M:HideAlert(btn) end
end

local PAINTERS = {
	{ name = "icon", fn = PaintIcon },
	{ name = "count", fn = PaintCount },
	{ name = "name", fn = PaintName },
	{ name = "checked", fn = PaintChecked },
	{ name = "usable", fn = PaintUsable },
	{ name = "equipped", fn = PaintEquipped },
	{ name = "cooldown", fn = PaintCooldown },
	{ name = "proc", fn = PaintProc },
	{ name = "range", fn = PaintRange },
}

local function Paint(btn, names)
	local slot = SlotOf(btn)
	if not slot then return end
	for _, p in ipairs(PAINTERS) do
		if not names or names[p.name] then
			S.SafeCall("paint:" .. p.name, p.fn, btn, slot)
		end
	end
end

-- events ----------------------------------------------------------------------
-- painters are collected per event and flushed once on the next frame;
-- cooldown events arrive in bursts and only visible buttons repaint
local wanted, pending = {}, false
local queued, queuedAll = {}, false

local function flushWanted()
	pending = false
	local names = wanted
	wanted = {}
	if not next(names) then return end
	for _, btn in ipairs(allButtons) do
		if btn:IsVisible() then Paint(btn, names) else btn.stale = true end
	end
end

local function QueuePaint(names)
	for n in pairs(names) do wanted[n] = true end
	if pending then return end
	pending = true
	C_Timer.After(0, function() S.SafeCall("paint:flush", flushWanted) end)
end

local later
local function flushQueue()
	if queuedAll then
		queuedAll = false
		for btn in pairs(queued) do queued[btn] = nil end
		for _, btn in ipairs(allButtons) do
			if btn:IsVisible() then Paint(btn) else btn.stale = true end
		end
		return
	end
	for btn in pairs(queued) do
		queued[btn] = nil
		Paint(btn)
	end
end
local function Queue(btn)
	queued[btn] = true
	if not later then
		later = true
		C_Timer.After(0, function() later = false S.SafeCall("paint:queue", flushQueue) end)
	end
end
local function QueueAll()
	queuedAll = true
	if not later then
		later = true
		C_Timer.After(0, function() later = false S.SafeCall("paint:queue", flushQueue) end)
	end
end

-- buttons per slot, rebuilt when a slot attribute changes (paging)
local bySlot
local function SlotsChanged() bySlot = nil end
local function ButtonsOn(slot)
	if not bySlot then
		bySlot = {}
		for _, btn in ipairs(allButtons) do
			local a = SlotOf(btn)
			if a then
				bySlot[a] = bySlot[a] or {}
				tinsert(bySlot[a], btn)
			end
		end
	end
	return bySlot[slot]
end
local function PaintSlot(slot, names)
	for _, btn in ipairs(ButtonsOn(slot) or {}) do Paint(btn, names) end
end

local function set(...) local t = {} for _, n in ipairs({ ... }) do t[n] = true end return t end
local USABLE = set("usable")
local CHECKED = set("checked")
local COOLDOWN = set("cooldown")

local EVENTS = {
	ACTIONBAR_SLOT_CHANGED = function(slot)
		if type(slot) == "number" and slot ~= 0 then PaintSlot(slot) else QueueAll() end
	end,
	ACTIONBAR_UPDATE_STATE = CHECKED,
	START_AUTOREPEAT_SPELL = CHECKED,
	STOP_AUTOREPEAT_SPELL = CHECKED,
	PLAYER_ENTER_COMBAT = CHECKED,
	PLAYER_LEAVE_COMBAT = CHECKED,
	PLAYER_EQUIPMENT_CHANGED = set("icon", "count", "equipped"),
	SPELL_UPDATE_ICON = set("icon"),
	BAG_UPDATE_DELAYED = set("count", "usable"),
	ACTIONBAR_UPDATE_COOLDOWN = COOLDOWN,
	SPELL_UPDATE_COOLDOWN = COOLDOWN,
	LOSS_OF_CONTROL_ADDED = COOLDOWN,
	LOSS_OF_CONTROL_UPDATE = COOLDOWN,
	SPELL_UPDATE_CHARGES = set("count", "cooldown"),
	SPELL_UPDATE_USABLE = USABLE,
	ACTIONBAR_UPDATE_USABLE = USABLE,
	PLAYER_MOUNT_DISPLAY_CHANGED = USABLE,
	SPELL_ACTIVATION_OVERLAY_GLOW_SHOW = set("proc"),
	SPELL_ACTIVATION_OVERLAY_GLOW_HIDE = set("proc"),
	-- the payload lists { slot, usable, noMana }: paint straight from it,
	-- asking the api inside the event can still hand back the old answer
	ACTION_USABLE_CHANGED = function(changes)
		if type(changes) ~= "table" then return QueuePaint(USABLE) end
		for _, c in ipairs(changes) do
			if type(c) == "table" and type(c.slot) == "number" then
				if type(c.usable) == "boolean" and type(c.noMana) == "boolean" then
					for _, btn in ipairs(ButtonsOn(c.slot) or {}) do
						S.SafeCall("paint:usable", PaintUsable, btn, c.slot, c.usable, c.noMana)
					end
				else
					PaintSlot(c.slot, USABLE)
				end
			end
		end
	end,
	ACTION_RANGE_CHECK_UPDATE = function(slot, inRange, checksRange)
		for _, btn in ipairs(ButtonsOn(slot) or {}) do
			local out = checksRange == true and inRange == false
			if btn.outOfRange ~= out then
				btn.outOfRange = out
				local s2 = SlotOf(btn)
				if s2 then PaintUsable(btn, s2) end
			end
		end
	end,
	PLAYER_TARGET_CHANGED = function()
		Core.WatchRange()
		QueuePaint(set("usable", "range"))
	end,
	UPDATE_SHAPESHIFT_FORM = "all",
	UPDATE_SHAPESHIFT_FORMS = "all",
	UPDATE_BONUS_ACTIONBAR = "all",
	ACTIONBAR_PAGE_CHANGED = "all",
	UPDATE_VEHICLE_ACTIONBAR = "all",
	UPDATE_OVERRIDE_ACTIONBAR = "all",
	SPELLS_CHANGED = "all",
	PLAYER_ENTERING_WORLD = function()
		QueueAll()
		-- a reload drops every already-running cooldown's events, and PEW
		-- can land before the action data is readable - late cooldown-only
		-- sweeps pick up whatever the first paint missed
		for _, d in ipairs({ 0.5, 1.5, 3 }) do
			C_Timer.After(d, function()
				S.SafeCall("paint:latecd", QueuePaint, COOLDOWN)
			end)
		end
	end,
	UPDATE_BINDINGS = function() Core.UpdateHotkeys() end,
}

local eventsFrame
local function WireEvents()
	if eventsFrame then return end
	eventsFrame = CreateFrame("Frame")
	for ev in pairs(EVENTS) do pcall(eventsFrame.RegisterEvent, eventsFrame, ev) end
	eventsFrame:SetScript("OnEvent", function(_, event, ...)
		local what = EVENTS[event]
		if type(what) == "function" then S.SafeCall("event:" .. event, what, ...)
		elseif what == "all" then QueueAll()
		elseif type(what) == "table" then QueuePaint(what) end
	end)
end

-- range watch: only while a target exists, only paints actual changes
local rangeFrame
function Core.WatchRange()
	if not rangeFrame then rangeFrame = CreateFrame("Frame") end
	local on = UnitExists("target") == true
	if on == (type(rangeFrame:GetScript("OnUpdate")) == "function") then return end
	rangeFrame:SetScript("OnUpdate", on and function(_, dt)
		rangeFrame._in = (rangeFrame._in or 0) - (dt or 0)
		if rangeFrame._in > 0 then return end
		rangeFrame._in = 0.2
		for _, btn in ipairs(allButtons) do
			if btn:IsVisible() then
				local slot = SlotOf(btn)
				if slot and HasAction(slot) then PaintRange(btn, slot) end
			end
		end
	end or nil)
end

-- paging ----------------------------------------------------------------------
-- bar 1's page comes from a state driver in the game's own order; the
-- snippet stores it on the holder, pushes it to every button and copies
-- it onto the game's hidden twin buttons so a keybind casts the slot our
-- button shows. Form/vehicle fallbacks are the client's real indices.
local FALLBACK = { override = 33, vehicle = 31, temp = 32 }
local function index(fn, fb)
	if type(fn) ~= "function" then return fb end
	local ok, v = pcall(fn)
	return (ok and type(v) == "number" and v > 0) and v or fb
end

local CLASS_PAGING = {
	DRUID = "[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:2] 10; [bonusbar:3] 9; [bonusbar:4] 10;",
	ROGUE = "[bonusbar:1] 7;",
	WARRIOR = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9;",
	PRIEST = "[form:1] 7;",
	MONK = "[bonusbar:1] 7; [bonusbar:2] 8;",
	EVOKER = "[bonusbar:1] 7;",
}

local function PageRule()
	local parts = {
		"[overridebar] " .. index(GetOverrideBarIndex, FALLBACK.override),
		"[vehicleui] " .. index(GetVehicleBarIndex, FALLBACK.vehicle),
		"[possessbar] " .. index(GetVehicleBarIndex, FALLBACK.vehicle),
		"[shapeshift] " .. index(GetTempShapeshiftBarIndex, FALLBACK.temp),
		"[bar:2] 2", "[bar:3] 3", "[bar:4] 4", "[bar:5] 5", "[bar:6] 6",
		"[bonusbar:5] 11",
	}
	local _, cls = UnitClass("player")
	parts[#parts + 1] = cls and CLASS_PAGING[cls]
	parts[#parts + 1] = "1"
	return table.concat(parts, "; ")
end

-- holder snippet: the new page onto itself, its buttons (ChildUpdate)
-- and the game's hidden twins so keybinds cast the shown slot. Written
-- only on a real change - an attribute written from insecure code would
-- keep the taint.
local PAGE_SNIPPET = [[
	local page = tonumber(string.match(newstate or "", "%d+")) or 1
	self:SetAttribute("actionpage", page)
	control:ChildUpdate("page", page)
	for i = 1, 12 do
		local t = self:GetFrameRef("senti-twin" .. i)
		if not t then break end
		if t:GetAttribute("actionpage") ~= page then
			t:SetAttribute("actionpage", page)
		end
	end
]]

-- each button: slot = its index + (page - 1) * 12
local CHILD_SNIPPET = [[
	local i = self:GetAttribute("senti-index") or 1
	self:SetAttribute("action", i + ((tonumber(message) or 1) - 1) * 12)
]]

-- the game's hidden buttons the keybinds press
local function TwinRefs(holder, prefix)
	for i = 1, 12 do
		local b = _G[prefix .. i]
		if type(b) == "table" then holder:SetFrameRef("senti-twin" .. i, b) end
	end
end

-- bar factory --------------------------------------------------------------------
local BARS = {
	{ id = 1, key = "bar1", paged = true, command = "ACTIONBUTTON",
		twinPrefix = "ActionButton", away = "[petbattle] hide; " },
	{ id = 2, key = "bar2", page = 6, command = "MULTIACTIONBAR1BUTTON",
		twinPrefix = "MultiBarBottomLeftButton",
		away = "[petbattle][vehicleui][overridebar] hide; " },
	{ id = 3, key = "bar3", page = 5, command = "MULTIACTIONBAR2BUTTON",
		twinPrefix = "MultiBarBottomRightButton",
		away = "[petbattle][vehicleui][overridebar] hide; " },
	{ id = 4, key = "bar4", page = 3, command = "MULTIACTIONBAR3BUTTON",
		twinPrefix = "MultiBarRightButton",
		away = "[petbattle][vehicleui][overridebar] hide; " },
}

-- each Show choice as the tail of the holder's visibility driver
local SHOW = {
	ALWAYS = "show",
	COMBAT = "[combat] show; hide",
	TARGET = "[exists] show; hide",
}

local function VisibilityRule(def, dbBar)
	return def.away .. (SHOW[dbBar.visibility or "ALWAYS"] or SHOW.ALWAYS)
end

local function ApplyVisibility(def)
	local holder = bars[def.id] and bars[def.id].holder
	if not holder then return end
	local run = function()
		pcall(RegisterStateDriver, holder, "visibility", VisibilityRule(def, bars[def.id].dbBar))
	end
	if InCombatLockdown() then S.RunOutOfCombat(run) else run() end
end

-- flat button look: no round mask, no Blizzard border/background art
local function StyleButton(btn, name)
	-- the template ships an inset hit rect (only the artwork core clicks,
	-- not the full frame); our slot IS the whole button, so the press
	-- point must cover all of it
	if btn.SetHitRectInsets then pcall(btn.SetHitRectInsets, btn, 0, 0, 0, 0) end
	for _, key in ipairs({ "NormalTexture", "SlotBackground", "Border", "NewActionTexture",
		"SpellHighlightTexture", "Flash", "FloatingBG", "InterruptDisplay", "SlotArt" }) do
		KillTexture(btn[key])
		KillTexture(_G[name .. key])
	end
	local nt = btn.GetNormalTexture and btn:GetNormalTexture()
	if nt then KillTexture(nt) end
	local icon = btn.icon
	if icon then
		if btn.IconMask and icon.RemoveMaskTexture then pcall(icon.RemoveMaskTexture, icon, btn.IconMask) end
		icon:ClearAllPoints()
		-- 3 px inset keeps the icon inside the PillEdge backdrop fill
		-- area; 1 px lets it bleed into the border arc and look cut off
		icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -3)
		icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -3, 3)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		icon:SetDrawLayer("ARTWORK")
	end
	for _, cd in ipairs({ btn.cooldown, btn.chargeCooldown,
		btn.lossOfControlCooldown }) do
		if type(cd) == "table" then
			cd:ClearAllPoints()
			cd:SetAllPoints(icon or btn)
		end
	end
	local pushTex = S.Tex and S.Tex("ButtonPushed")
	local chkTex = S.Tex and S.Tex("ButtonChecked")
	pcall(btn.SetPushedTexture, btn, pushTex or BLANK)
	pcall(btn.SetHighlightTexture, btn, BLANK)
	pcall(btn.SetCheckedTexture, btn, chkTex or BLANK)
	local C = S.colors
	local pushed, hl, checked = btn:GetPushedTexture(), btn:GetHighlightTexture(), btn:GetCheckedTexture()
	-- ButtonPushed carries its own soft-light fill; the blank fallback
	-- still needs the white tint. ButtonChecked is a gold outline ring
	-- and shows its art as-is instead of an accent fill.
	if pushed then
		if pushTex then pushed:SetVertexColor(1, 1, 1, 1)
		else pushed:SetVertexColor(1, 1, 1, 0.25) end
		SetInside(pushed, btn, 1, 1)
	end
	if hl then hl:SetVertexColor(1, 1, 1, 0.2) SetInside(hl, btn, 1, 1) end
	if checked then
		if chkTex then checked:SetVertexColor(1, 1, 1, 0.9)
		else checked:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.4) end
		SetInside(checked, btn, 1, 1)
	end
	if btn.hotkey then
		btn.hotkey:ClearAllPoints()
		btn.hotkey:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
		btn.hotkey:SetJustifyH("RIGHT")
		btn.hotkey:SetDrawLayer("OVERLAY", 2)
	end
	if btn.count then
		btn.count:ClearAllPoints()
		btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
		btn.count:SetJustifyH("RIGHT")
		btn.count:SetDrawLayer("OVERLAY", 2)
	end
	if btn.name then
		btn.name:ClearAllPoints()
		btn.name:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
		btn.name:SetWidth(SC(34))
		btn.name:SetDrawLayer("OVERLAY", 2)
	end
	S.Template(btn, "inset")
	-- gold border ring: a 1px overlay frame shown on hover and while
	-- a spell is active/auto-repeating — sets the border via backdrop
	local ring = CreateFrame("Frame", nil, btn)
	ring:SetAllPoints()
	ring:SetFrameLevel(btn:GetFrameLevel() + 2)
	if BackdropTemplateMixin and not ring.SetBackdrop then
		Mixin(ring, BackdropTemplateMixin)
		if ring.OnBackdropLoaded then ring:OnBackdropLoaded() end
	end
	if ring.SetBackdrop then
		ring:SetBackdrop({ bgFile = BLANK, edgeFile = BLANK, edgeSize = 1 })
		ring:SetBackdropColor(0, 0, 0, 0)
		ring:SetBackdropBorderColor(C.accent.r, C.accent.g, C.accent.b, 0)
	end
	btn.suiRing = ring
	local function ringAlpha(self, a)
		if self.suiRing and self.suiRing.SetBackdropBorderColor then
			self.suiRing:SetBackdropBorderColor(C.accent.r, C.accent.g, C.accent.b, a)
		end
	end
	btn:HookScript("OnEnter", function(self) ringAlpha(self, 0.7) end)
	btn:HookScript("OnLeave", function(self)
		-- keep ring visible when spell is toggled on
		local slot = SlotOf(self)
		local active = slot and pcall(IsCurrentAction, slot)
			and IsCurrentAction(slot) or false
		local ok2, autoR = pcall(IsAutoRepeatAction, slot or 0)
		ringAlpha(self, (active or (ok2 and autoR)) and 0.55 or 0)
	end)
end

-- kill the mouse on the template's overlay container; may be called
-- repeatedly (the container can be created lazily after the button)
local function FixButtonChrome(btn)
	local toc = btn.TextOverlayContainer
	if type(toc) == "table" and type(toc.EnableMouse) == "function" then
		toc:EnableMouse(false)
	end
end

-- the game's hidden twin knows its true action slot on this client
-- (132-slot map: BottomLeft = 85-96 etc.); read it instead of guessing
local function TwinSlot(prefix, i)
	local t = type(prefix) == "string" and _G[prefix .. i]
	if type(t) ~= "table" then return end
	if type(t.GetActionID) == "function" then
		local ok, a = pcall(t.GetActionID, t)
		if ok and type(a) == "number" and a > 0 then return a end
	end
	if type(t.action) == "number" and t.action > 0 then return t.action end
	if type(t.GetAttribute) == "function" then
		local ok, a = pcall(t.GetAttribute, t, "action")
		if ok and type(a) == "number" and a > 0 then return a end
	end
end

local function MakeButton(holder, def, i)
	local id, page, command = def.id, def.page or 1, def.command
	local name = format("SentiUIActionBar%dButton%d", id, i)
	-- SecureActionButtonTemplate goes last: the plain secure click
	-- handler wins over the template's, which reads its own fields under
	-- addon taint and gets blocked in a fight
	local okBtn, btn = pcall(CreateFrame, "CheckButton", name, holder,
		"ActionBarButtonTemplate, SecureActionButtonTemplate")
	if not okBtn or not btn then
		logErr("ActionBar" .. id, okBtn and "button template missing" or btn)
		return nil
	end
	-- detach from the game's dispatch: its handlers would run the game's
	-- protected writes on this button under our taint in a fight
	UnlistButton(btn)
	UnwatchButton(btn)
	if type(btn.UnregisterActionBarButtonCheckFrames) == "function"
		and type(btn.action) == "number" then
		pcall(btn.UnregisterActionBarButtonCheckFrames, btn, btn.action)
	end
	-- the template's first Update tinted and lit slot 1's state on
	-- every button it made; undo what it painted
	if type(btn.icon) == "table" then btn.icon:SetVertexColor(1, 1, 1) end
	local auto = btn.AutoCastOverlay
	if type(auto) == "table" then
		if type(auto.ShowAutoCastEnabled) == "function" then auto:ShowAutoCastEnabled(false) end
		auto:Hide()
	end
	btn.RegisterActionBarButtonCheckFrames = stayOut
	btn.UnregisterActionBarButtonCheckFrames = stayOut
	btn.UpdatePressAndHoldAction = stayOut
	btn.UpdatePingAttributes = stayOut
	-- the template's Update repaints with the secret-unsafe SetCooldown;
	-- our painters do the work instead
	btn.Update = function(self) Queue(self) end
	-- the template's TextOverlayContainer sits at frame level 500 and on
	-- this client keeps its mouse enabled - it covers the whole button and
	-- swallows every click except the few pixels it leaves uncovered.
	-- It may also appear only lazily, so the 2s sweep below re-checks.
	FixButtonChrome(btn)
	btn:SetID(0)
	btn:SetAttribute("senti-index", i)
	btn:SetAttribute("action", TwinSlot(def.twinPrefix, i) or (i + (page - 1) * 12))
	btn:SetAttribute("_childupdate-page", CHILD_SNIPPET)
	-- every bar clicks THROUGH the game's own twin button (type=click):
	-- the twin holds the client's real action mapping AND its own pickup
	-- modifier logic, so casting and Shift-pickup stay 100% native.
	-- `action` stays set for painting and our drag handlers; bar 1's
	-- twins follow its page via the holder's state snippet.
	local twin = type(def.twinPrefix) == "string" and _G[def.twinPrefix .. i]
	if type(twin) == "table" and twin.Click then
		btn:SetAttribute("type", "click")
		btn:SetAttribute("clickbutton", twin)
	else
		btn:SetAttribute("type", "action")
	end
	btn:SetAttribute("checkselfcast", true)
	btn:SetAttribute("checkfocuscast", true)
	btn:SetAttribute("pressAndHoldAction", true)
	-- both halves: this client fires on whichever half is registered and
	-- honours useOnKeyDown=false poorly, so AnyUp alone never casts
	btn:RegisterForClicks("AnyDown", "AnyUp")
	btn:RegisterForDrag("LeftButton", "RightButton")
	btn.commandName = command .. i   -- the game reads this for keybinds
	-- drag-out still needs our pickup: a drag is not a click, so the twin
	-- never sees it. Shift held or unlocked bars, never in combat.
	btn:SetScript("OnDragStart", function(self)
		if InCombatLockdown() then return end
		if not CanPickUp() then return end
		local slot = SlotOf(self)
		if slot and GetCursorInfo() == nil then pcall(PickupAction, slot) end
	end)
	btn:SetScript("OnDragStop", function(self)
		self:SetChecked(false)
	end)
	btn:SetScript("OnReceiveDrag", function(self)
		if InCombatLockdown() then return end
		local slot = SlotOf(self)
		if slot then pcall(PlaceAction, slot) Queue(self) end
	end)
	btn:HookScript("OnEnter", function(self)
		local slot = SlotOf(self)
		if slot then
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			-- the tooltip fill reads secret action data internally
			if type(securecall) == "function" then
				securecall(GameTooltip.SetAction, GameTooltip, slot)
			else
				pcall(GameTooltip.SetAction, GameTooltip, slot)
			end
		end
	end)
	btn:HookScript("OnLeave", function() GameTooltip:Hide() end)
	btn:HookScript("OnShow", function(self)
		if self.stale then self.stale = nil Paint(self) end
	end)
	btn:HookScript("OnAttributeChanged", function(self, attr)
		if attr == "action" then SlotsChanged() Queue(self) end
	end)
	-- template regions (defensive access)
	btn.icon = btn.icon or btn.Icon or _G[name .. "Icon"]
	btn.cooldown = btn.cooldown or btn.Cooldown or _G[name .. "Cooldown"]
	btn.chargeCooldown = btn.chargeCooldown or btn.ChargeCooldown
		or _G[name .. "ChargeCooldown"]
	btn.lossOfControlCooldown = btn.lossOfControlCooldown
		or btn.LossOfControlCooldown or _G[name .. "LossOfControlCooldown"]
	btn.count = btn.count or btn.Count or _G[name .. "Count"]
	btn.hotkey = btn.hotkey or btn.HotKey or _G[name .. "HotKey"]
	btn.name = btn.name or btn.Name or _G[name .. "Name"]
	btn.checkedTex = btn.GetCheckedTexture and btn:GetCheckedTexture() or nil
	-- ready-flash sheen: built as a region so pulsing it mid-fight only
	-- ever touches a Texture - regions are legal under combat lockdown
	-- where a fresh frame would be born protected
	if not btn.readyFlash then
		local rf = btn:CreateTexture(nil, "OVERLAY", nil, 7)
		rf:SetTexture(BLANK)
		rf:SetVertexColor(1, 0.86, 0.45)
		rf:SetBlendMode("ADD")
		if btn.icon then rf:SetAllPoints(btn.icon) else rf:SetAllPoints(btn) end
		rf:Hide()
		btn.readyFlash = rf
	end
	if btn.cooldown and btn.cooldown.SetSwipeColor then
		pcall(btn.cooldown.SetSwipeColor, btn.cooldown, 0, 0, 0, 0.8)
	end
	-- the template cooldown hides its countdown digits on this client;
	-- unhide them and give the widget a font object it can render with.
	-- SystemFont_Outline_Small carries a dark outline - plain highlight
	-- white is unreadable over bright spell icons.
	-- SetCountdownFont is absent on older builds, so each call is guarded.
	for _, cd in ipairs({ btn.cooldown, btn.chargeCooldown,
		btn.lossOfControlCooldown }) do
		if type(cd) == "table" then
			if cd.SetHideCountdownNumbers then
				pcall(cd.SetHideCountdownNumbers, cd, false)
			end
			if cd.SetShowCountdownNumbers then
				pcall(cd.SetShowCountdownNumbers, cd, true)
			end
			if cd.SetCountdownFont then
				pcall(cd.SetCountdownFont, cd, "SystemFont_Outline_Small")
			end
		end
	end
	-- the template's own handlers (OnHide etc.) call
	-- SetCooldown(start, duration, modRate); those numbers are secret on
	-- this client and SetCooldown refuses secrets under addon taint.
	-- Swallow the throw - the visible cooldown is painted by our painter
	-- via SetCooldownFromDurationObject and by the game's own untainted
	-- cooldown events, so nothing is lost.
	if btn.cooldown and btn.cooldown.SetCooldown
		and not btn.cooldown.suiCdSafe then
		btn.cooldown.suiCdSafe = true
		local rawCd = btn.cooldown.SetCooldown
		btn.cooldown.SetCooldown = function(self, ...)
			pcall(rawCd, self, ...)
		end
	end
	SetFont(btn.count, 10, "OUTLINE")
	SetFont(btn.hotkey, 10, "OUTLINE")
	SetFont(btn.name, 9, "OUTLINE")
	S.SafeCall("StyleButton", StyleButton, btn, name)
	allButtons[#allButtons + 1] = btn
	SlotsChanged()
	return btn
end

local function LayoutBar(bar)
	-- geometry on protected buttons is restricted in combat: the rebuild
	-- waits for the fight to end
	if InCombatLockdown() then
		S.RunOutOfCombat(LayoutBar, bar)
		return
	end
	local dbBar = bar.dbBar
	local size = SC(dbBar.size or 34)
	local spacing = SC(dbBar.spacing or 3)
	local num = math.max(1, math.min(12, dbBar.numButtons or 12))
	local perRow = math.max(1, math.min(num, dbBar.perRow or 12))
	local pad = SC(3)
	local vertical = dbBar.vertical == true
	local cross = math.ceil(num / perRow)
	if vertical then
		bar.holder:SetSize(pad * 2 + cross * size + (cross - 1) * spacing,
			pad * 2 + perRow * size + (perRow - 1) * spacing)
	else
		bar.holder:SetSize(pad * 2 + perRow * size + (perRow - 1) * spacing,
			pad * 2 + cross * size + (cross - 1) * spacing)
	end
	bar.numShown = num
	for i, btn in ipairs(bar.buttons) do
		btn:SetSize(size, size)
		btn:ClearAllPoints()
		if vertical then
			local col = math.floor((i - 1) / perRow)
			local rowI = (i - 1) % perRow
			if i == 1 then
				btn:SetPoint("TOPLEFT", bar.holder, "TOPLEFT", pad, -pad)
			elseif rowI == 0 then
				btn:SetPoint("TOPLEFT", bar.buttons[i - perRow], "TOPRIGHT", spacing, 0)
			else
				btn:SetPoint("TOPLEFT", bar.buttons[i - 1], "BOTTOMLEFT", 0, -spacing)
			end
		else
			local col = (i - 1) % perRow
			local rowI = math.floor((i - 1) / perRow)
			if col == 0 and rowI == 0 then
				btn:SetPoint("TOPLEFT", bar.holder, "TOPLEFT", pad, -pad)
			elseif col == 0 then
				btn:SetPoint("TOPLEFT", bar.buttons[i - perRow], "BOTTOMLEFT", 0, -spacing)
			else
				btn:SetPoint("TOPLEFT", bar.buttons[i - 1], "TOPRIGHT", spacing, 0)
			end
		end
		btn:SetShown(i <= num)
	end
end
Core.LayoutBar = LayoutBar

local function CreateBar(def, dbBar)
	local holder = CreateFrame("Frame", "SentiUIActionBar" .. def.id, UIParent,
		"SecureHandlerStateTemplate")
	holder:SetSize(10, 10)
	holder:SetFrameStrata("LOW")
	holder:SetAttribute("_onstate-page", PAGE_SNIPPET)
	-- dark panel behind the button grid: S.Template paints the inset
	-- fill plus the accent-tinted border directly on the holder, so the
	-- frame edge is flush with the outer button edges (3px pad) instead
	-- of floating as a thin strip. "panel" keeps it subtle, not gold-lit.
	S.Template(holder, "panel")
	local bar = { holder = holder, def = def, dbBar = dbBar, buttons = {} }
	local page = def.page or 1
	for i = 1, 12 do
		bar.buttons[i] = MakeButton(holder, def, i)
		if not bar.buttons[i] then break end
	end
	TwinRefs(holder, def.twinPrefix)
	if def.paged then
		-- the real driver once the client knows its bar indices; until
		-- then the buttons sit on page 1
		local function drive()
			pcall(RegisterStateDriver, holder, "page", PageRule())
		end
		if InCombatLockdown() then S.RunOutOfCombat(drive) else drive() end
	else
		holder:SetAttribute("actionpage", page)
	end
	LayoutBar(bar)
	bars[def.id] = bar
	ApplyVisibility(def)
	return bar
end

local function Restack()
	local positions = S.DB.Positions()
	local bottom = SC(16)
	local prev
	for i = 1, 3 do
		local b = bars[i]
		if b then
			if not positions["bar" .. i] then
				b.holder:ClearAllPoints()
				if prev then
					b.holder:SetPoint("BOTTOMLEFT", prev.holder, "TOPLEFT", 0, SC(2))
				else
					b.holder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, bottom)
				end
			end
			prev = b
		end
	end
	if bars[4] and not positions["bar4"] then
		bars[4].holder:ClearAllPoints()
		bars[4].holder:SetPoint("RIGHT", UIParent, "RIGHT", -SC(6), 0)
	end
end

function Core.ApplySize()
	S.RunOutOfCombat(function()
		for _, bar in pairs(bars) do LayoutBar(bar) end
		Restack()
	end)
end

-- parked game frames ---------------------------------------------------------------
-- the game's bars move under a hidden frame: reparenting is once and
-- final, while Show/Hide from addon code would be the game's own Lua
-- running tainted (and blocked in a fight). Keybinds keep working: a
-- pressed key computes its twin's slot on press.
local parked
function ns.ParkFrame()
	if not parked then
		parked = CreateFrame("Frame", "SentiUIParkedBars", UIParent)
		parked:SetAllPoints(UIParent)
		parked:Hide()
		-- Blizzard scripts call layout methods on GetParent() (the status
		-- tracking manager hit exactly this) - stub them all
		parked.Layout = function() end
		parked.MarkDirty = function() end
		parked.SetNeedsLayout = function() end
		parked.UpdateLayout = function() end
		parked.IsLayoutFrame = function() return false end
	end
	return parked
end
function ns.ParkBar(frame)
	-- some of the named globals are plain controller tables on this
	-- client (BagsBar, MicroButtonAndBagsBar); only real widgets park
	if type(frame) ~= "table" or type(frame.GetParent) ~= "function"
		or type(frame.SetParent) ~= "function" then
		return
	end
	if frame:GetParent() ~= ns.ParkFrame() then
		frame:SetParent(ns.ParkFrame())
	end
end

local MULTI_BARS = { "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight",
	"MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7" }
-- chrome that just goes under the hidden frame (bag, micro, exp, totem)
local PARK_LIST = {
	"MainMenuBar", "OverrideActionBar", "PossessActionBar",
	"MicroButtonAndBagsBar", "MicroMenu", "MicroMenuContainer",
	"BagsBar", "MainMenuBarBagManager",
	"StatusTrackingBarManager", "MainStatusTrackingBarContainer",
	"SecondaryStatusTrackingBarContainer", "MultiCastActionBarFrame",
	"MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
	"CharacterBag2Slot", "CharacterBag3Slot", "KeyRingButton",
	"CharacterMicroButton", "SpellbookMicroButton", "PlayerSpellsMicroButton",
	"ProfessionMicroButton", "TalentMicroButton", "QuestLogMicroButton",
	"WorldMapMicroButton", "GuildMicroButton", "CommunitiesMicroButton",
	"LFDMicroButton", "LFGMicroButton", "GroupFinderMicroButton",
	"AchievementMicroButton", "AchievementsMicroButton", "CollectionsMicroButton",
	"StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton", "EJMicroButton",
	-- the Cooldown Manager viewers hold secret cooldown data
	"EssentialCooldownViewer", "UtilityCooldownViewer",
	"BuffIconCooldownViewer", "BuffBarCooldownViewer",
}

-- the game's own bar buttons come off its event list too: on a slot
-- change in a fight the twin works out its slot and would show or hide
-- its bar's buttons - a protected write. A pressed key needs none of
-- those updates; it reads its slot at press time.
local function UnlistTwins()
	local prefixes = { "ActionButton" }
	for _, name in ipairs(MULTI_BARS) do prefixes[#prefixes + 1] = name .. "Button" end
	for _, prefix in ipairs(prefixes) do
		for i = 1, 12 do
			local b = _G[prefix .. i]
			if type(b) == "table" then UnlistButton(b) end
		end
	end
end

-- a bar holding a protected button turns the game's one-pass layout into
-- blocked calls on a form change; twins live under the hidden frame so
-- their bars hold nothing protected
local function ParkTwins()
	local p = ns.ParkFrame()
	local prefixes = { "ActionButton" }
	for _, name in ipairs(MULTI_BARS) do prefixes[#prefixes + 1] = name .. "Button" end
	for _, prefix in ipairs(prefixes) do
		for i = 1, 12 do
			local b = _G[prefix .. i]
			if type(b) == "table" and type(b.SetParent) == "function"
				and b:GetParent() ~= p then
				b:SetParent(p)
				b:ClearAllPoints()
				b:SetPoint("CENTER", p, "CENTER")
			end
			-- flag so the mouse killer skips it: it is the secure
			-- clickbutton target of our own bar button
			if type(b) == "table" then b._sentiTwin = true end
		end
	end
end

-- frames parked under the hidden holder stay invisible, but on this
-- client their CHILDREN keep their old rects and their mouse - an
-- unnamed MultiBarBottomLeft child at MEDIUM/1001 sat exactly over our
-- extra bar and swallowed every click except a thin rim. Kill the mouse
-- through the whole parked subtree; twins keep theirs (secure click
-- targets, parked at screen center anyway).
local function IsTwin(f)
	-- protected frame fields can answer secret on this client; even the
	-- truthiness test in KillMouseDeep then throws and stops the sweep
	local ok, v = pcall(function() return f._sentiTwin end)
	return ok and not S.IsSecret(v) and v == true
end

local function KillMouseDeep(f)
	-- EnableMouse on a protected child of a parked Blizzard bar is a
	-- forbidden call during combat lockdown; never run this in combat
	if InCombatLockdown() then return end
	if type(f) ~= "table" or IsTwin(f) then return end
	if type(f.EnableMouse) == "function" then pcall(f.EnableMouse, f, false) end
	if type(f.GetChildren) == "function" then
		for _, c in ipairs({ f:GetChildren() }) do KillMouseDeep(c) end
	end
end

local function RecheckPark()
	-- the game re-parents its bars back when it re-lays them out
	if InCombatLockdown() then S.RunOutOfCombat(RecheckPark) return end
	for _, name in ipairs(MULTI_BARS) do
		local bar = _G[name]
		if type(bar) == "table" then
			if type(bar.UnregisterAllEvents) == "function" then
				pcall(bar.UnregisterAllEvents, bar)
			end
			ns.ParkBar(bar)
			KillMouseDeep(bar)
		end
	end
	local main = _G.MainActionBar
	if type(main) == "table" then
		ns.ParkBar(main)
		if type(main.EnableMouse) == "function" then main:EnableMouse(false) end
		KillMouseDeep(main)
	end
	for _, name in ipairs(PARK_LIST) do
		local frame = _G[name]
		-- cooldown viewers stay usable when the opt-in is on - they get a
		-- movable holder and the SentiUI skin instead of the hidden parent
		if db and db.cooldownViewers and name:find("CooldownViewer") then
			-- skip parking
		elseif name:find("StatusTrackingBar") then
			-- never reparent these: layout passes (e.g. a minimap zoom)
			-- call manager methods that expect their real parent - they
			-- stay put, events off, alpha 0, mouse off (the WHOLE subtree:
			-- children kept their own mouse and ate bar clicks)
			if type(frame) == "table" then
				if type(frame.UnregisterAllEvents) == "function" then
					pcall(frame.UnregisterAllEvents, frame)
				end
				if type(frame.SetAlpha) == "function" then frame:SetAlpha(0) end
				KillMouseDeep(frame)
			end
		else
			ns.ParkBar(frame)
			KillMouseDeep(frame)
		end
	end
	UnlistTwins()
	ParkTwins()
end

function Core.HideBlizzard()
	RecheckPark()
	-- per-action updates for every listed button run the game's code on
	-- them; all buttons we care about are unlisted, so the dispatcher has
	-- nothing left to feed
	local ev = _G.ActionBarActionEventsFrame
	if type(ev) == "table" then ev:UnregisterAllEvents() end
	if Core.parkWired then return end
	Core.parkWired = true
	-- the game hands parked frames back to their old parents on its own
	-- layout passes; re-park right behind each of them
	local function soon()
		C_Timer.After(0, function()
			if InCombatLockdown() then S.RunOutOfCombat(RecheckPark)
			else RecheckPark() end
		end)
	end
	for _, ev2 in ipairs({ "PLAYER_TALENT_UPDATE", "PLAYER_SPECIALIZATION_CHANGED",
		"EDIT_MODE_LAYOUTS_UPDATED", "UPDATE_SHAPESHIFT_FORM",
		"UPDATE_VEHICLE_ACTIONBAR", "UPDATE_OVERRIDE_ACTIONBAR" }) do
		S.RegisterEvent(ev2, soon)
	end
	for _, fn in ipairs({ "UpdateMicroButtons", "MicroMenuBar_SetFullScreenFrame",
		"MicroMenuBar_ClearFullScreenFrame" }) do
		if type(_G[fn]) == "function" then hooksecurefunc(fn, soon) end
	end
	-- WatchHide, not OnHide: the manager is a special window, so an
	-- OnHide script would run inside the Escape dispatch and taint
	-- the engine's protected spell-stop calls
	local em = _G.EditModeManagerFrame
	if type(em) == "table" and em.IsShown then S.WatchHide(em, soon) end
end

-- keys ----------------------------------------------------------------------------
-- keybinds press the game's hidden twins natively; only flyout slots are
-- re-pointed at our buttons, since a key on a hidden flyout twin would
-- open the flyout where nobody can pick from it
local keysOwner
function Core.UpdateBindings()
	if InCombatLockdown() then return end
	keysOwner = keysOwner or CreateFrame("Frame", "SentiUIABKeys", UIParent)
	pcall(ClearOverrideBindings, keysOwner)
	for _, btn in ipairs(allButtons) do
		if type(btn.UpdateFlyout) == "function" then pcall(btn.UpdateFlyout, btn) end
		local slot = SlotOf(btn)
		if slot and GetActionInfo and GetActionInfo(slot) == "flyout" then
			for _, key in ipairs({ GetBindingKey(btn.commandName) }) do
				pcall(SetOverrideBindingClick, keysOwner, false, key, btn:GetName(), "LeftButton")
			end
		end
	end
end

-- the key text on each button: read on binding changes, never per paint
function Core.UpdateHotkeys()
	for _, btn in ipairs(allButtons) do
		local hk = btn.hotkey
		if hk then
			local text = ""
			if db.hotkeys then
				local k = GetBindingKey(btn.commandName)
				if type(k) == "string" then
					local t = GetBindingText and GetBindingText(k, true)
					text = (type(t) == "string" and t) or k
				end
			end
			hk:SetText(text)
			hk:Show()
		end
	end
end
Core.RefreshHotkeys = Core.UpdateHotkeys

-- extra bars vanish while every slot is empty. Hide via the visibility
-- driver, not SetShown: the driver re-asserts its rule whenever the engine
-- re-evaluates it, so a bare SetShown gets flipped back and the bar blinks
-- once per check tick.
local function CheckEmpty(bar)
	local h = bar.holder
	if not bar.dbBar.hideEmpty then
		if h._emptyHidden then
			h._emptyHidden = nil
			S.RunOutOfCombat(function() ApplyVisibility(bar.def) end)
		end
		return
	end
	local any = bar.showGrid == true
	if not any then
		for _, btn in ipairs(bar.buttons) do
			local slot = SlotOf(btn)
			if slot then
				local ok, tex = pcall(GetActionTexture, slot)
				if ok and tex ~= nil then any = true break end
			end
		end
	end
	if any == not h._emptyHidden then return end
	h._emptyHidden = not any or nil
	S.RunOutOfCombat(function()
		if h._emptyHidden then
			pcall(UnregisterStateDriver, h, "visibility")
			h:Hide()
		else
			ApplyVisibility(bar.def)
		end
	end)
end

local function CheckAllEmpty()
	for _, bar in pairs(bars) do CheckEmpty(bar) end
end

-- mouseover fade only: alpha on our own holder, allowed in combat
local function BarFade()
	if not db then return end
	local unlocked = S.Movers and S.Movers.unlocked
	for _, bar in pairs(bars) do
		local d = bar.dbBar
		local want = 1
		local hover = bar.holder:IsMouseOver() or unlocked
		if not hover and d.mouseoverFade then want = d.fadeAlpha or 0.3 end
		local cur = bar.holder:GetAlpha()
		if cur ~= want then
			local nxt = cur + (want - cur) * 0.35
			if math.abs(nxt - want) < 0.02 then nxt = want end
			bar.holder:SetAlpha(nxt)
		end
	end
end

-- enable ---------------------------------------------------------------------------
function Core.Enable(mod)
	if Core.enabled then return end
	if InCombatLockdown() then
		-- frames created during combat lockdown are born protected; build
		-- the whole bar set when combat ends instead
		S.RunOutOfCombat(Core.Enable, mod)
		return
	end
	Core.enabled = true
	db = mod.db
	Core.db = db

	for _, def in ipairs(BARS) do
		local dbBar = db[def.key]
		if dbBar and dbBar.enabled then
			def.bar = CreateBar(def, dbBar)
			Core["bar" .. def.id] = def.bar.holder
		end
	end

	-- migrate: extra bars default to hiding while empty (added in 0.1.2)
	if db._v == nil or db._v < 1 then
		db._v = 1
		for _, k in ipairs({ "bar2", "bar3", "bar4" }) do
			if db[k] and db[k].hideEmpty == nil then db[k].hideEmpty = true end
		end
	end

	Restack()
	if bars[1] then S.Movers.Register(bars[1].holder, "bar1", L["Action bar 1"]) end
	if bars[2] then S.Movers.Register(bars[2].holder, "bar2", L["Action bar 2"]) end
	if bars[3] then S.Movers.Register(bars[3].holder, "bar3", L["Action bar 3"]) end
	if bars[4] then S.Movers.Register(bars[4].holder, "bar4", L["Action bar 4"]) end

	-- the game's bars away, its twins unlisted and parked - before any
	-- painting, so no shared dispatch ever touches our buttons. Each step
	-- below runs on its own: one failure may never take the rest down.
	S.SafeCall("hide:blizzard", Core.HideBlizzard)
	S.SafeCall("wire", WireEvents)
	S.SafeCall("range", Core.WatchRange)
	S.SafeCall("bindings", Core.UpdateBindings)
	S.SafeCall("hotkeys", Core.UpdateHotkeys)
	S.SafeCall("paint", QueueAll)
	S.SafeCall("empty", CheckAllEmpty)

	-- pet / stance / totem / extra buttons
	S.SafeCall("extras", function()
		if ns.Extras then ns.Extras.Enable(mod) end
	end)

	-- Blizzard-frame skins + optional cooldown viewers
	S.SafeCall("skins", function()
		if ns.Skins then ns.Skins.Enable(mod) end
	end)

	-- the client's global FX model scenes and the widget containers' model
	-- scenes spawn at high strata with their mouse enabled - wherever they
	-- overlap the bars they swallow the clicks (only an uncovered rim of
	-- each slot stays clickable). Display-only frames: drop their mouse and
	-- keep re-applying, they get recreated late.
	local function UnblockMouse()
		for _, n in ipairs({
			"GlobalFXDialogModelScene", "GlobalFXFullScreenDialogModelScene",
			"GlobalFXMediumModelScene", "GlobalFXBackgroundModelScene",
			"GlobalFXLowModelScene", "GlobalFXWorldModelScene",
		}) do
			local f = _G[n]
			if type(f) == "table" and type(f.EnableMouse) == "function" then
				f:EnableMouse(false)
			end
		end
		for _, n in ipairs({
			"UIWidgetBelowMinimapContainerFrame", "UIWidgetTopCenterContainerFrame",
			"UIWidgetPowerBarContainerFrame", "ObjectiveTrackerUIWidgetContainer",
			"ContainerFrameContainer",
		}) do
			local f = _G[n]
			if type(f) == "table" then
				-- the container itself is a layout frame, never interactive;
				-- children keep their own mouse flags
				if type(f.EnableMouse) == "function" then f:EnableMouse(false) end
				if type(f.GetChildren) == "function" then
					for _, c in ipairs({ f:GetChildren() }) do
						if type(c) == "table" and type(c.EnableMouse) == "function" then
							local isScene = type(c.GetObjectType) == "function"
								and c:GetObjectType() == "ModelScene"
							local cn = type(c.GetName) == "function" and c:GetName() or ""
							if isScene or (type(cn) == "string" and cn:find("ModelScene")) then
								c:EnableMouse(false)
							end
						end
					end
				end
			end
		end
		-- the template's overlay container can spawn lazily per button
		for _, btn in ipairs(allButtons) do FixButtonChrome(btn) end
		-- children of parked bars can be created late too
		if parked then KillMouseDeep(parked) end
		-- unnamed fullscreen ModelScenes (FX layers) never need a mouse
		local f = EnumerateFrames()
		while f do
			if type(f.GetObjectType) == "function"
				and f:GetObjectType() == "ModelScene"
				and type(f.EnableMouse) == "function" then
				pcall(f.EnableMouse, f, false)
			end
			f = EnumerateFrames(f)
		end
	end
	-- not in combat: EnableMouse on protected Blizzard children (inside
	-- parked bars / flyouts) is forbidden mid-fight and this sweep touches
	-- the whole tree - the next tick after REGEN catches up
	C_Timer.NewTicker(2, function()
		if InCombatLockdown() then return end
		pcall(UnblockMouse)
	end)

	-- /suibars foci: prints the mouse-enabled frames under the cursor so a
	-- click blocker can be named instead of guessed
	SLASH_SENTIUIAB1 = "/suibars"
	SlashCmdList.SENTIUIAB = function(msg)
		if strtrim(msg or "") ~= "foci" then
			S.Print("|cffffff00/suibars foci|r - " .. L["list the frames eating clicks under the cursor"])
			return
		end
		-- EnumerateFrames always: it is the same scan /framestack does.
		-- GetMouseFoci is only a supplement - on this client it can return
		-- nothing or a packed table.
		local foci, seen = {}, {}
		local f = EnumerateFrames()
		while f do
			-- IsMouseOver/IsMouseEnabled can return SECRET booleans for
			-- some game frames (aura buttons) - testing one throws
			local okE, en = pcall(f.IsMouseEnabled, f)
			local okO, ov = pcall(f.IsMouseOver, f)
			local secret = S.IsSecret and (S.IsSecret(en) or S.IsSecret(ov))
			if okE and okO and not secret and en and ov and not seen[f] then
				seen[f] = true
				foci[#foci + 1] = f
			end
			f = EnumerateFrames(f)
		end
		if GetMouseFoci then
			for _, v in ipairs({ GetMouseFoci() }) do
				if type(v) == "table" and type(v.GetObjectType) ~= "function" then
					for _, w in pairs(v) do
						if type(w) == "table" and not seen[w] then
							seen[w] = true
							foci[#foci + 1] = w
						end
					end
				elseif type(v) == "table" and not seen[v] then
					seen[v] = true
					foci[#foci + 1] = v
				end
			end
		end
		if #foci == 0 then
			S.Print(L["no mouse-enabled frame under the cursor"])
			return
		end
		for _, f in ipairs(foci) do
			local function call(m)
				local v = type(f[m]) == "function" and select(2, pcall(f[m], f)) or nil
				if v == nil then return "?" end
				return tostring(v)
			end
			local par = type(f.GetParent) == "function"
				and select(2, pcall(f.GetParent, f)) or nil
			local pn = type(par) == "table" and type(par.GetName) == "function"
				and par:GetName() or "?"
			S.Print(format("%s (%s) type=%s strata=%s level=%s parent=%s",
				call("GetName"), tostring(f), call("GetObjectType"),
				call("GetFrameStrata"), call("GetFrameLevel"), tostring(pn)))
			-- for our own buttons also compare the hit rect with the icon's
			-- rect: they must cover the same pixels
			local n = call("GetName")
			if type(n) == "string" and n:find("^SentiUIActionBar%d+Button%d+$")
				and type(f.GetLeft) == "function" then
				pcall(function()
					local l, b = f:GetLeft(), f:GetBottom()
					S.Print(format("   hit rect: %.0f..%.0f x %.0f..%.0f",
						l, b, l + f:GetWidth(), b + f:GetHeight()))
					local ic = f.icon
					if type(ic) == "table" and type(ic.GetLeft) == "function" then
						S.Print(format("   icon rect: %.0f..%.0f x %.0f..%.0f",
							ic:GetLeft(), ic:GetBottom(),
							ic:GetLeft() + ic:GetWidth(),
							ic:GetBottom() + ic:GetHeight()))
					end
				end)
			end
		end
	end

	-- mouseover fade ticks; painting itself is event-driven
	C_Timer.NewTicker(0.05, function() pcall(BarFade) end)
	-- empty-bar check piggybacks on slow repaint events
	C_Timer.NewTicker(1, function() S.SafeCall("empty", CheckAllEmpty) end)

	S.RegisterEvent("UPDATE_BINDINGS", function()
		C_Timer.After(0, function()
			Core.UpdateBindings()
			Core.UpdateHotkeys()
		end)
	end)
	S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(0, function()
			Core.UpdateBindings()
			Core.UpdateHotkeys()
			RecheckPark()
		end)
	end)
	-- late-loading Blizzard pieces re-take their parents
	S.RegisterEvent("ADDON_LOADED", function(_, name)
		if name and name:find("^SentiUI") then return end
		C_Timer.After(0.2, RecheckPark)
	end)
	S.RegisterEvent("PLAYER_REGEN_ENABLED", function()
		C_Timer.After(0, function()
			Core.UpdateBindings()
			Core.UpdateHotkeys()
		end)
	end)
	-- dragging a spell shows empty bars again so it can be dropped on them
	S.RegisterEvent("ACTIONBAR_SHOWGRID", function()
		for _, bar in pairs(bars) do bar.showGrid = true end
		CheckAllEmpty()
	end)
	S.RegisterEvent("ACTIONBAR_HIDEGRID", function()
		for _, bar in pairs(bars) do bar.showGrid = nil end
		CheckAllEmpty()
	end)
	-- a form learned or lost shifts form numbers; rebuild the rule
	S.RegisterEvent("UPDATE_SHAPESHIFT_FORMS", function()
		local h = bars[1] and bars[1].holder
		if not h then return end
		local run = function()
			pcall(UnregisterStateDriver, h, "page")
			pcall(RegisterStateDriver, h, "page", PageRule())
		end
		if InCombatLockdown() then S.RunOutOfCombat(run) else run() end
	end)
end

function Core.SettingChanged(mod, path)
	if not Core.enabled then return end
	if path and path:match("^bar%d") then
		local id = tonumber(path:match("^bar(%d)"))
		local def = BARS[id]
		if def and bars[id] then ApplyVisibility(def) end
		Core.ApplySize()
		Core.UpdateBindings()
		Core.UpdateHotkeys()
	elseif path == "hotkeys" or path == "counts" or path == "macroNames" or path == "rangeColor" then
		Core.UpdateHotkeys()
		QueueAll()
	elseif path == "cooldownDim" then
		-- turned off: strip the gray from every button still dimmed
		if db.cooldownDim == false then
			for b in pairs(dimmed) do
				b._cdDim = nil
				if b.icon and b.icon.SetDesaturated then
					pcall(b.icon.SetDesaturated, b.icon, false)
				end
			end
			wipe(dimmed)
		end
		QueuePaint(COOLDOWN)
	end
	if ns.Extras then ns.Extras.SettingChanged(mod, path) end
	if ns.Skins then ns.Skins.SettingChanged(path) end
end
