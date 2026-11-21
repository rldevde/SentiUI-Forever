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
		if type(n) == "number" and not S.IsSecret(n) and n > 1 then c = n end
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

-- cooldown sweep: the widget compares `start` in Lua and secret times
-- throw under addon taint, so a DurationObject goes first - the C++ side
-- handles secrets with no Lua compare. Without one, raw times are used
-- only while actually readable; if neither works the old sweep simply
-- stays (never Clear an active cooldown just because the values are
-- unreadable).
local function sweep(cd, on, duration, info)
	if type(cd) ~= "table" then return end
	if on then
		if duration and cd.SetCooldownFromDurationObject then
			cd:SetCooldownFromDurationObject(duration)
		elseif info and not S.IsSecret(info.startTime) and not S.IsSecret(info.duration) then
			pcall(CooldownFrame_Set, cd, info.startTime, info.duration,
				info.isEnabled, false, info.modRate)
		end
		return
	end
	if cd.Clear then
		cd:Clear()
	elseif CooldownFrame_Clear then
		pcall(CooldownFrame_Clear, cd)
	end
end

local function PaintCooldown(btn, slot)
	if not GetActionCooldown then return end
	if GetActionTexture(slot) == nil then
		sweep(btn.lossOfControlCooldown, false)
		sweep(btn.cooldown, false)
		sweep(btn.chargeCooldown, false)
		return
	end
	local loc = GetActionLossOfControlCooldownInfo
		and GetActionLossOfControlCooldownInfo(slot)
	local locOn = type(loc) == "table" and loc.isActive == true
	sweep(btn.lossOfControlCooldown, locOn,
		locOn and GetActionLossOfControlCooldownDuration
			and GetActionLossOfControlCooldownDuration(slot), loc)
	local info = GetActionCooldown(slot)
	local on = type(info) == "table" and info.isActive == true
		and not (locOn and loc.shouldReplaceNormalCooldown == true)
	sweep(btn.cooldown, on,
		on and GetActionCooldownDuration and GetActionCooldownDuration(slot), info)
	local charges = GetActionCharges and GetActionCharges(slot)
	local chOn = type(charges) == "table" and charges.isActive == true
	sweep(btn.chargeCooldown, chOn,
		chOn and GetActionChargeDuration and GetActionChargeDuration(slot))
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
	PLAYER_ENTERING_WORLD = "all",
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
		icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
		icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		icon:SetDrawLayer("ARTWORK")
	end
	if btn.cooldown then
		btn.cooldown:ClearAllPoints()
		btn.cooldown:SetAllPoints(icon or btn)
	end
	pcall(btn.SetPushedTexture, btn, BLANK)
	pcall(btn.SetHighlightTexture, btn, BLANK)
	pcall(btn.SetCheckedTexture, btn, BLANK)
	local C = S.colors
	local pushed, hl, checked = btn:GetPushedTexture(), btn:GetHighlightTexture(), btn:GetCheckedTexture()
	if pushed then pushed:SetVertexColor(1, 1, 1, 0.25) SetInside(pushed, btn, 1, 1) end
	if hl then hl:SetVertexColor(1, 1, 1, 0.2) SetInside(hl, btn, 1, 1) end
	if checked then checked:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.4) SetInside(checked, btn, 1, 1) end
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
	btn.count = btn.count or btn.Count or _G[name .. "Count"]
	btn.hotkey = btn.hotkey or btn.HotKey or _G[name .. "HotKey"]
	btn.name = btn.name or btn.Name or _G[name .. "Name"]
	btn.checkedTex = btn.GetCheckedTexture and btn:GetCheckedTexture() or nil
	if btn.cooldown and btn.cooldown.SetSwipeColor then
		pcall(btn.cooldown.SetSwipeColor, btn.cooldown, 0, 0, 0, 0.8)
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
	local bottom = SC(10)
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
		end
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
		end
	end
	local main = _G.MainActionBar
	if type(main) == "table" then
		ns.ParkBar(main)
		if type(main.EnableMouse) == "function" then main:EnableMouse(false) end
	end
	for _, name in ipairs(PARK_LIST) do
		local frame = _G[name]
		if name:find("StatusTrackingBar") then
			-- never reparent these: layout passes (e.g. a minimap zoom)
			-- call manager methods that expect their real parent - they
			-- stay put, events off, alpha 0, mouse off
			if type(frame) == "table" then
				if type(frame.UnregisterAllEvents) == "function" then
					pcall(frame.UnregisterAllEvents, frame)
				end
				if type(frame.SetAlpha) == "function" then frame:SetAlpha(0) end
				if type(frame.EnableMouse) == "function" then frame:EnableMouse(false) end
			end
		else
			ns.ParkBar(frame)
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

-- extra bars vanish while every slot is empty (a layout change - out of
-- combat only, the driver re-asserts its rule on the next state change)
local function CheckEmpty(bar)
	if not bar.dbBar.hideEmpty then return end
	local any = false
	for _, btn in ipairs(bar.buttons) do
		local slot = SlotOf(btn)
		if slot and GetActionTexture(slot) ~= nil then any = true break end
	end
	local h = bar.holder
	if h:IsShown() ~= any then
		S.RunOutOfCombat(h.SetShown, h, any)
	end
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
	end
	if ns.Extras then ns.Extras.SettingChanged(mod, path) end
end
