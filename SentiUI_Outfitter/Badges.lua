local _, ns = ...
local S = ns.Outfitter

-- Small outfit marker on bag items. Works with the Blizzard bags, ElvUI
-- and DaylightUI by walking the bag windows for ItemButtons and reading
-- their bag/slot, then matching against the outfit item locations.

local LOGO = "Interface\\AddOns\\SentiUI_Outfitter\\Media\\Logo.tga"
local SIZE = 14

local ROOTS = {
	"ContainerFrameCombinedBags", "ElvUI_ContainerFrame", "ElvUI_BankContainerFrame",
	"DaylightUIBag", "DaylightUIBank", "BankFrame",
}
for i = 1, 13 do ROOTS[#ROOTS + 1] = "ContainerFrame" .. i end

local badges = setmetatable({}, { __mode = "k" })
local stats = { buttons = 0, matched = 0, mapSize = 0 }
local hookedRoots = {}
local pending = false

local function Enabled()
	return S.db and S.db.ui.bagMarker ~= false
end

local function Safe(fn, ...)
	local ok, a = pcall(fn, ...)
	if ok then return a end
	return nil
end

-- "bag:slot" -> true for every bag/bank slot that holds an outfit item
local function BuildMap()
	local map = {}
	if not (S.ES and S.ES.GetEquipmentSetIDs and EquipmentManager_GetLocationData) then return map end
	for _, set in ipairs(S:GetSets()) do
		local okL, locations = pcall(function() return S.ES.GetItemLocations(set.id) end)
		if okL and locations then
			local ignored = S:GetIgnoredSlots(set.id)
			for slotID, loc in pairs(locations) do
				if not ignored[slotID] and type(loc) == "number" and loc > 1 then
					local d = Safe(EquipmentManager_GetLocationData, loc)
					if d and (d.isBags or d.isBank) and d.bag and d.slot then
						map[d.bag .. ":" .. d.slot] = true
					end
				end
			end
		end
	end
	return map
end

local function BagSlotOf(btn, parent)
	local bag = btn.BagID or btn.bagID or (btn.GetBagID and Safe(btn.GetBagID, btn))
	if bag == nil and parent and parent.GetID then bag = Safe(parent.GetID, parent) end
	local slot = btn.SlotID or btn.slotID or Safe(btn.GetID, btn)
	if type(bag) ~= "number" or type(slot) ~= "number" or slot < 1 then return nil end
	return bag, slot
end

local function Badge(btn)
	local b = badges[btn]
	if b then return b end
	if InCombatLockdown() then return nil end
	b = CreateFrame("Frame", nil, btn)
	b:SetSize(SIZE, SIZE)
	b:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
	b:SetFrameLevel(btn:GetFrameLevel() + 8)
	b:EnableMouse(false)
	b.back = b:CreateTexture(nil, "BACKGROUND")
	b.back:SetAllPoints()
	b.back:SetColorTexture(0, 0, 0, 0.55)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetPoint("TOPLEFT", 1, -1)
	b.icon:SetPoint("BOTTOMRIGHT", -1, 1)
	b.icon:SetTexture(LOGO)
	b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	badges[btn] = b
	return b
end

local function Walk(frame, depth, map, seen)
	local kids = {}
	local res = { pcall(frame.GetChildren, frame) }
	if res[1] then
		for i = 2, #res do kids[#kids + 1] = res[i] end
	end
	for _, child in ipairs(kids) do
		if not seen[child] then
			seen[child] = true
			if Safe(child.IsObjectType, child, "ItemButton") then
				local bag, slot = BagSlotOf(child, frame)
				local on = bag and map[bag .. ":" .. slot]
				if bag then stats.buttons = stats.buttons + 1 end
				if on then
					stats.matched = stats.matched + 1
					local b = Badge(child)
					if b then b:Show() end
				elseif badges[child] then
					badges[child]:Hide()
				end
			elseif depth > 0 then
				Walk(child, depth - 1, map, seen)
			end
		end
	end
end

local function AnyRootVisible()
	for _, n in ipairs(ROOTS) do
		local f = _G[n]
		if f and Safe(f.IsVisible, f) then return true end
	end
	return false
end

local function Update()
	pending = false
	if not S.db then return end
	if not Enabled() then
		for _, b in pairs(badges) do b:Hide() end
		return
	end
	local map = BuildMap()
	local seen = {}
	stats.buttons, stats.matched, stats.mapSize = 0, 0, 0
	for _ in pairs(map) do stats.mapSize = stats.mapSize + 1 end
	for _, n in ipairs(ROOTS) do
		local f = _G[n]
		if f and Safe(f.IsVisible, f) then
			if not hookedRoots[f] and f.HookScript then
				hookedRoots[f] = true
				f:HookScript("OnShow", function() S:UpdateBadges() end)
			end
			Walk(f, 5, map, seen)
		end
	end
end

function S:BagDebug()
	Update()
	S:Print("outfit slots in bags/bank: " .. stats.mapSize)
	S:Print("bag buttons found: " .. stats.buttons .. ", marked: " .. stats.matched)
	for _, n in ipairs(ROOTS) do
		local f = _G[n]
		if f then S:Print("  " .. n .. " visible=" .. tostring(Safe(f.IsVisible, f))) end
	end
	if stats.buttons == 0 and EnumerateFrames then
		-- no known bag window matched: list visible ItemButtons anywhere
		local found = 0
		local ok, f = pcall(EnumerateFrames)
		while ok and f do
			if Safe(f.IsObjectType, f, "ItemButton") and Safe(f.IsVisible, f) then
				found = found + 1
				if found <= 4 then
					local chain, p = {}, f
					for _ = 1, 5 do
						if not p then break end
						local nm = Safe(p.GetName, p)
						chain[#chain + 1] = (type(nm) == "string" and nm or "?") .. "#" .. tostring(Safe(p.GetID, p))
						p = Safe(p.GetParent, p)
					end
					S:Print("  visible ItemButton: " .. table.concat(chain, " < "))
				end
			end
			ok, f = pcall(EnumerateFrames, f)
		end
		S:Print("visible ItemButtons anywhere: " .. found)
	end
	local map = BuildMap()
	local shown = 0
	for k in pairs(map) do
		shown = shown + 1
		if shown <= 8 then S:Print("  slot " .. k) end
	end
	if S.ProtectDebug then S:ProtectDebug() end
end

function S:UpdateBadges()
	if pending then return end
	pending = true
	C_Timer.After(0.1, Update)
end

function S:InitBadges()
	if S._badgesInit then return end
	S._badgesInit = true
	S:On("BAG_UPDATE_DELAYED", function() S:UpdateBadges() end)
	S:On("PLAYER_EQUIPMENT_CHANGED", function() S:UpdateBadges() end)
	S:On("BANKFRAME_OPENED", function() S:UpdateBadges() end)
	hooksecurefunc(S, "RefreshSets", function() S:UpdateBadges() end)
	-- bag addons rebuild their buttons on their own schedule; a cheap
	-- pass while a bag window is open keeps the marker in place
	C_Timer.NewTicker(1, function()
		if AnyRootVisible() then Update() end
	end)
	S:UpdateBadges()
end
