-- SentiUI pet, stance and totem bars plus the extra/zone/vehicle buttons.
-- Pet and stance adopt the game's own buttons into our holders, so their
-- updates, tooltips and keybinds stay the game's - nothing of theirs runs
-- under addon taint. Totem bar: GetTotemInfo slots with a cooldown sweep.
-- Extra buttons: Blizzard's ExtraAbilityContainer gets a movable holder;
-- a secure /leavevehicle exit button and a taxi landing button are added.
local _, ns = ...
local S = SentiUI
local L = ns.L
local SC, SetFont = ns.SC, ns.SetFont
local Call = ns.Call -- labelled pcall: names the api when the client blocks it
local Sec = ns.Sec   -- same wrapper kept for secret-reading calls

local ipairs = ipairs
local CreateFrame, InCombatLockdown = CreateFrame, InCombatLockdown

local Extras = {}
ns.Extras = Extras

local db

-- pet + stance rows --------------------------------------------------------------
-- hidden wherever the game hides its secondary bars
local AWAY = "[petbattle][vehicleui][overridebar] hide; "

-- moves the game's own buttons prefix1..n into our holder; their clicks,
-- casts, tooltips and updates stay entirely the game's
local function Adopt(holder, prefix, n)
	local list = {}
	for i = 1, n do
		local b = _G[prefix .. i]
		if type(b) == "table" then
			b:SetParent(holder)
			b:ClearAllPoints()
			list[#list + 1] = b
		end
	end
	return list
end

local function forms()
	local n = type(GetNumShapeshiftForms) == "function" and GetNumShapeshiftForms() or 0
	return tonumber(n) or 0
end

-- lays out adopted buttons; they are protected, so geometry and scale
-- only change out of combat
local function LayoutRow(holder, buttons, cfg)
	local size, gap = SC(cfg.size or 26), SC(cfg.spacing or 3)
	local inset = SC(4)
	local n = #buttons
	local base = n > 0 and buttons[1]:GetWidth()
	local scale = (type(base) == "number" and base > 0) and size / base or 1
	for i, b in ipairs(buttons) do
		b:SetScale(scale)
		b:ClearAllPoints()
		if cfg.vertical then
			b:SetPoint("TOP", holder, "TOP", 0, -(inset + (i - 1) * (size + gap)) / scale)
		else
			b:SetPoint("LEFT", holder, "LEFT", (inset + (i - 1) * (size + gap)) / scale, 0)
		end
	end
	local w = inset * 2 + n * size + math.max(n - 1, 0) * gap
	if cfg.vertical then
		holder:SetSize(size + inset * 2, math.max(w, 1))
	else
		holder:SetSize(math.max(w, 1), size + inset * 2)
	end
end

local function ApplySmallDriver(holder, rule)
	local run = function()
		pcall(RegisterStateDriver, holder, "visibility", rule)
	end
	if InCombatLockdown() then S.RunOutOfCombat(run) else run() end
end

local function RelayoutStance()
	local bar = Extras.stance
	if not bar then return end
	local run = function()
		ApplySmallDriver(bar, AWAY .. (db.stanceBar.enabled and forms() > 0 and "show" or "hide"))
		LayoutRow(bar, bar.buttons, db.stanceBar)
	end
	if InCombatLockdown() then S.RunOutOfCombat(run) else run() end
end

local function CreatePetStance()
	local core = ns.Core

	-- stance bar: StanceBar parks (its events keep updating the adopted
	-- buttons, untainted); the bar itself knows which forms exist
	local stance = CreateFrame("Frame", "SentiUIStanceBar", UIParent,
		"SecureHandlerStateTemplate")
	stance:SetFrameStrata("MEDIUM")
	ns.ParkBar(_G.StanceBar)
	stance.buttons = db.stanceBar.enabled and Adopt(stance, "StanceButton", 10) or {}
	Extras.stance = stance

	-- pet bar: PetActionBar is not parked - its OnUpdate still colors the
	-- buttons out of range; it is only faded and unclickable
	local petBar = _G.PetActionBar
	if type(petBar) == "table" then
		petBar:SetAlpha(0)
		petBar:EnableMouse(false)
	end
	local pet = CreateFrame("Frame", "SentiUIPetBar", UIParent,
		"SecureHandlerStateTemplate")
	pet:SetFrameStrata("MEDIUM")
	pet.buttons = db.petBar.enabled and Adopt(pet, "PetActionButton", 10) or {}
	Extras.pet = pet

	-- anchor above the bottom bar stack, then movers take over
	local anchor = core.bar2 or core.bar1 or UIParent
	stance:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, SC(4))
	pet:SetPoint("BOTTOMLEFT", stance, "TOPLEFT", 0, SC(30))

	S.Movers.Register(pet, "petbar", L["Pet bar"])
	S.Movers.Register(stance, "stancebar", L["Stance bar"])

	ApplySmallDriver(stance, AWAY .. (db.stanceBar.enabled and forms() > 0 and "show" or "hide"))
	ApplySmallDriver(pet, AWAY .. (db.petBar.enabled and "show; " or "hide; ") .. "[nopet] hide; ")
	LayoutRow(stance, stance.buttons, db.stanceBar)
	LayoutRow(pet, pet.buttons, db.petBar)

	-- forms come and go (talents, level): re-count and re-drive
	S.RegisterEvent("UPDATE_SHAPESHIFT_FORMS", RelayoutStance)
end

-- totem bar ---------------------------------------------------------------------
local TOTEM_SLOTS = 4

local function UpdateTotems(self)
	local cfg = db.totemBar
	if not cfg.enabled then
		if not InCombatLockdown() then self.bar:Hide() end
		return
	end
	local any = false
	for i, b in ipairs(self.totemButtons) do
		local ok, have, _, start, duration, icon = Call("GetTotemInfo", GetTotemInfo, i)
		if ok and not S.IsSecret(have) and have then
			b.icon:SetTexture(icon)
			-- the cooldown widget compares `start` in Lua: secret totem
			-- times would throw under addon taint, so skip the sweep then
			if not S.IsSecret(start) and not S.IsSecret(duration) then
				Call("CooldownFrame_Set", CooldownFrame_Set, b.cooldown, start, duration, 1)
			end
			b:Show()
			any = true
		else
			b:Hide()
		end
	end
	self.bar:SetShown(any)
end

local function LayoutTotems()
	local cfg = db.totemBar
	local bar = Extras.totemBar
	if not bar then return end
	local size, gap = SC(cfg.size or 30), SC(cfg.spacing or 3)
	for i, b in ipairs(Extras.totemButtons) do
		b:SetSize(size, size)
		b:ClearAllPoints()
		if cfg.vertical then
			b:SetPoint("TOP", bar, "TOP", 0, -(SC(3) + (i - 1) * (size + gap)))
		else
			b:SetPoint("LEFT", bar, "LEFT", SC(3) + (i - 1) * (size + gap), 0)
		end
	end
	if cfg.vertical then
		bar:SetSize(size + SC(6), SC(6) + TOTEM_SLOTS * size + (TOTEM_SLOTS - 1) * gap)
	else
		bar:SetSize(SC(6) + TOTEM_SLOTS * size + (TOTEM_SLOTS - 1) * gap, size + SC(6))
	end
end

local function CreateTotems()
	local _, class = UnitClass("player")
	if class ~= "SHAMAN" or not GetTotemInfo then return end
	local bar = CreateFrame("Frame", "SentiUITotemBar", UIParent)
	S.Template(bar, "panel")
	bar:SetPoint("BOTTOM", UIParent, "BOTTOM", -SC(150), SC(230))
	bar:SetFrameStrata("MEDIUM")
	Extras.totemBar = bar
	Extras.totemButtons = {}
	for i = 1, TOTEM_SLOTS do
		local b = CreateFrame("Button", "SentiUITotem" .. i, bar)
		b:RegisterForClicks("RightButtonUp")
		S.Template(b, "inset")
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetPoint("TOPLEFT", 1, -1)
		b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
		b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		b.cooldown = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
		b.cooldown:SetAllPoints(b.icon)
		pcall(b.cooldown.SetDrawEdge, b.cooldown, false)
		b:SetScript("OnClick", function() Call("DestroyTotem", DestroyTotem, i) end)
		b:SetScript("OnEnter", function(self)
			Call("GameTooltip:SetOwner", GameTooltip.SetOwner, GameTooltip, self, "ANCHOR_TOP")
			if not Sec("GameTooltip:SetTotem", GameTooltip.SetTotem, GameTooltip, i) then GameTooltip:AddLine(L["Totem bar"]) end
			GameTooltip:AddLine(L["Right-click: destroy totem"], 0.6, 0.6, 0.6)
			GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		b:Hide()
		Extras.totemButtons[i] = b
	end
	LayoutTotems()
	-- the game's own totem frame is replaced
	if _G.TotemFrame then Call("TotemFrame:SetAlpha", _G.TotemFrame.SetAlpha, _G.TotemFrame, 0) end
	S.Movers.Register(bar, "totembar", L["Totem bar"])
	local function Refresh() if db then pcall(UpdateTotems, Extras) end end
	S.RegisterEvent("PLAYER_TOTEM_UPDATE", Refresh)
	S.RegisterEvent("PLAYER_ENTERING_WORLD", Refresh)
	S.RegisterEvent("PLAYER_REGEN_ENABLED", Refresh)
	C_Timer.NewTicker(1, Refresh)
	Refresh()
end


local function MakeHolder(name, point, x, y, w, h, key, title)
	local holder = CreateFrame("Frame", name, UIParent)
	holder:SetSize(SC(w or 64), SC(h or 64))
	holder:SetPoint(point or "BOTTOM", UIParent, point or "BOTTOM", SC(x or 0), SC(y or 300))
	S.Movers.Register(holder, key, title)
	return holder
end

local hooked = {}
local function Attach(frame, holder, point)
	if not frame or not holder then return end
	point = point or "CENTER"
	Call("attach:SetParent", frame.SetParent, frame, holder)
	Call("attach:ClearAllPoints", frame.ClearAllPoints, frame)
	Call("attach:SetPoint", frame.SetPoint, frame, point, holder, point, 0, 0)
	-- keep Blizzard's layout managers away from it
	frame.ignoreInLayout = true
	frame.ignoreFramePositionManager = true
	if hooked[frame] then return end
	hooked[frame] = true
	hooksecurefunc(frame, "SetParent", function(self, parent)
		if parent == holder or InCombatLockdown() then return end
		-- yield to another addon's holder frame instead of fighting it:
		-- two holder hooks ping-ponged ExtraAbilityContainer into a
		-- stack overflow once both suites were loaded
		local pn = type(parent) == "table" and parent.GetName
			and parent:GetName() or nil
		if pn and pn ~= holder:GetName() and pn:find("Holder") then return end
		self:SetParent(holder)
	end)
	hooksecurefunc(frame, "SetPoint", function(self, _, relative)
		if relative == holder or self.sentiFixing or InCombatLockdown() then return end
		self.sentiFixing = true
		self:ClearAllPoints()
		self:SetPoint(point, holder, point, 0, 0)
		self.sentiFixing = nil
	end)
end

-- frames that only need a movable home: global name, mover key, title,
-- holder anchor / offset / size and the point the frame hangs from
local HOMES = {
	{ "VehicleSeatIndicator", "vehicleseats", "Vehicle seats", "RIGHT", -24, -140, 110, 110, "CENTER" },
	{ "TalkingHeadFrame", "talkinghead", "Talking head", "BOTTOM", 0, 330, 570, 155, "CENTER" },
	{ "GroupLootContainer", "lootrolls", "Loot rolls", "BOTTOMLEFT", 14, 320, 260, 60, "BOTTOM" },
	{ "AlertFrame", "alerts", "Alerts", "BOTTOMRIGHT", -14, 340, 260, 60, "BOTTOM" },
	{ "MirrorTimerContainer", "mirrortimers", "Breath & timers", "TOP", 0, -150, 220, 50, "TOP" },
	{ "LossOfControlFrame", "lossofcontrol", "Loss of control", "CENTER", 0, 140, 200, 80, "CENTER" },
}

-- vehicle exit button (secure: /leavevehicle, shown by the client's own
-- [canexitvehicle] condition, so it also works in combat)
local function CreateVehicleExit()
	if Extras.exit then return end
	local holder = MakeHolder("SentiUIVehicleExitHolder", "BOTTOM", 150, 230, 40, 40,
		"vehicleexit", L["Vehicle exit button"])
	local b = CreateFrame("Button", "SentiUIVehicleExit", holder, "SecureActionButtonTemplate")
	b:SetAllPoints(holder)
	b:RegisterForClicks("AnyUp", "AnyDown")
	b:SetAttribute("type", "macro")
	b:SetAttribute("type1", "macro")
	b:SetAttribute("macrotext", "/leavevehicle")
	b:SetAttribute("macrotext1", "/leavevehicle")
	S.Template(b, "raised")
	local t = b:CreateTexture(nil, "ARTWORK")
	t:SetPoint("CENTER")
	t:SetSize(22, 22)
	t:SetTexture("Interface\\AddOns\\SentiUI_ActionBars\\Media\\Exit")
	b:SetScript("OnEnter", function(self)
		Call("GameTooltip:SetOwner", GameTooltip.SetOwner, GameTooltip, self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Leave vehicle"])
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	local ok, err = Call("RegisterStateDriver", RegisterStateDriver, b, "visibility", "[canexitvehicle][vehicleui] show; hide")
	if not ok then ns.logErr("VehicleExit driver", err) end
	Extras.exit = b

	-- taxi: early landing is not protected, so a plain button can do it
	local tx = CreateFrame("Button", "SentiUITaxiExit", holder)
	tx:SetAllPoints(holder)
	tx:SetFrameLevel(b:GetFrameLevel() + 5)
	S.Template(tx, "raised")
	local tt = tx:CreateTexture(nil, "ARTWORK")
	tt:SetPoint("CENTER")
	tt:SetSize(22, 22)
	tt:SetTexture("Interface\\AddOns\\SentiUI_ActionBars\\Media\\Land")
	tx:SetScript("OnClick", function() Call("TaxiRequestEarlyLanding", TaxiRequestEarlyLanding) end)
	tx:SetScript("OnEnter", function(self)
		Call("GameTooltip:SetOwner", GameTooltip.SetOwner, GameTooltip, self, "ANCHOR_TOP")
		GameTooltip:AddLine(L["Land at the next stop"])
		GameTooltip:Show()
	end)
	tx:SetScript("OnLeave", function() GameTooltip:Hide() end)
	tx:Hide()
	local acc = 0
	local watcher = CreateFrame("Frame")
	watcher:SetScript("OnUpdate", function(_, e)
		acc = acc + e
		if acc < 0.5 then return end
		acc = 0
		local ok2, on = Call("UnitOnTaxi", UnitOnTaxi, "player")
		on = ok2 and not S.IsSecret(on) and on == true
		local okSh, shown = Call("tx:IsShown", tx.IsShown, tx)
		if okSh and on ~= shown then Call("tx:SetShown", tx.SetShown, tx, on) end
		-- the taxi counts as a vehicle UI: keep the exit button invisible
		-- then (alpha only, it is a protected button)
		Call("vehicleexit:SetAlpha", b.SetAlpha, b, on and 0 or 1)
	end)
end

local function SetupExtras()
	if InCombatLockdown() then
		S.RunOutOfCombat(SetupExtras)
		return
	end
	if not db.extras.enabled then return end
	Extras.holders = Extras.holders or {}
	Extras.boss = Extras.boss or MakeHolder("SentiUIExtraButtonHolder", "BOTTOM", -160, 300, 64, 64,
		"extrabutton", L["Extra action button"])
	local container = _G.ExtraAbilityContainer
	if container then
		-- one container holds both the extra action and the zone ability button
		pcall(Attach, container, Extras.boss)
	else
		pcall(Attach, _G.ExtraActionBarFrame, Extras.boss)
		if _G.ZoneAbilityFrame then
			Extras.zone = Extras.zone or MakeHolder("SentiUIZoneAbilityHolder", "BOTTOM", 160, 300, 64, 64,
				"zoneability", L["Zone ability button"])
			pcall(Attach, _G.ZoneAbilityFrame, Extras.zone)
		end
	end
	for _, h in ipairs(HOMES) do
		local frame = _G[h[1]]
		if frame then
			local holder = Extras.holders[h[2]]
			if not holder then
				holder = MakeHolder("SentiUI" .. h[1] .. "Holder", h[4], h[5], h[6], h[7], h[8], h[2], L[h[3]])
				Extras.holders[h[2]] = holder
			end
			pcall(Attach, frame, holder, h[9])
		end
	end
	pcall(CreateVehicleExit)
end

function Extras.Enable(mod)
	db = mod.db
	CreatePetStance()
	CreateTotems()
	SetupExtras()
	-- some of these frames are created on demand
	local pending
	S.RegisterEvent("ADDON_LOADED", function()
		if pending then return end
		pending = true
		C_Timer.After(0.5, function()
			pending = false
			SetupExtras()
		end)
	end)
end

function Extras.SettingChanged(mod, path)
	if path and path:match("^petBar%.") then
		if Extras.pet then
			S.RunOutOfCombat(function()
				ApplySmallDriver(Extras.pet, AWAY
					.. (db.petBar.enabled and "show; " or "hide; ") .. "[nopet] hide; ")
				LayoutRow(Extras.pet, Extras.pet.buttons, db.petBar)
			end)
		end
	elseif path and path:match("^stanceBar%.") then
		if Extras.stance then RelayoutStance() end
	elseif path and path:match("^totemBar%.") then
		S.RunOutOfCombat(function()
			LayoutTotems()
			UpdateTotems(Extras)
		end)
	elseif path == "extras.enabled" then
		S.RunOutOfCombat(SetupExtras)
	end
end
