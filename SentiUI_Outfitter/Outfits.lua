local _, ns = ...
local S = ns.Outfitter
local L = S.L

S.ES = C_EquipmentSet -- shorthand, validated at login

-- ===================================================================
-- Small API helpers (secret-safe)
-- ===================================================================
local function Unsecret(v)
	if v ~= nil and issecretvalue and issecretvalue(v) then return nil end
	return v
end
S.Unsecret = Unsecret

-- this client has no global GetItemInfo / GetItemInfoInstant
local ItemInfoFn = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local ItemInfoInstantFn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

function S:ItemName(link)
	link = Unsecret(link)
	if not (link and ItemInfoFn) then return nil end
	local ok, name = pcall(ItemInfoFn, link)
	return ok and name or nil
end

function S:ItemIDFromLink(link)
	link = Unsecret(link)
	if not link then return nil end
	if not ItemInfoInstantFn then return nil end
	local ok, id = pcall(ItemInfoInstantFn, link)
	if ok and type(id) == "number" and id > 0 then return id end
	return nil
end

function S:LocData(loc)
	-- loc: packed equipment-set location number -> Blizzard location table
	if type(loc) ~= "number" or loc <= 1 then return nil end
	if EquipmentManager_GetLocationData then
		local ok, d = pcall(EquipmentManager_GetLocationData, loc)
		if ok and d then return d end
	end
	if EquipmentManager_UnpackLocation then
		local ok, player, bank, bags, void, slot, bag = pcall(EquipmentManager_UnpackLocation, loc)
		if ok then
			return { isPlayer = player, isBank = bank, isBags = bags,
				isVoidStorage = void, slot = slot, bag = bag }
		end
	end
	return nil
end

function S:LinkFromLocation(loc)
	-- loc: packed equipment-set location number
	local d = self:LocData(loc)
	if not d then return nil end
	if d.isPlayer then
		local ok, link = pcall(GetInventoryItemLink, "player", d.slot)
		return ok and Unsecret(link) or nil
	elseif d.isBags then
		local ok, link = pcall(GetContainerItemLink, d.bag, d.slot)
		if ok and link then return Unsecret(link) end
		if C_Container and C_Container.GetContainerItemLink then
			local ok2, link2 = pcall(C_Container.GetContainerItemLink, d.bag, d.slot)
			if ok2 then return Unsecret(link2) end
		end
	elseif d.isBank then
		-- bank containers use negative bag ids handled by GetContainerItemLink too
		local ok, link = pcall(GetContainerItemLink, d.bag, d.slot)
		if ok and link then return Unsecret(link) end
		if C_Container and C_Container.GetContainerItemLink then
			local ok2, link2 = pcall(C_Container.GetContainerItemLink, d.bag, d.slot)
			if ok2 then return Unsecret(link2) end
		end
	end
	return nil
end

function S:ItemIDFromLocation(loc)
	local link = self:LinkFromLocation(loc)
	if link then return self:ItemIDFromLink(link) end
	-- fallback: direct id lookups
	local d = self:LocData(loc)
	if not d then return nil end
	if d.isBags or d.isBank then
		if C_Container and C_Container.GetContainerItemID then
			local ok, id = pcall(C_Container.GetContainerItemID, d.bag, d.slot)
			if ok and id then return id end
		end
	elseif d.isPlayer then
		local ok, id = pcall(GetInventoryItemID, "player", d.slot)
		if ok and id then return id end
		local ok2, id2 = pcall(GetInventoryItemID, d.slot)
		if ok2 and id2 then return id2 end
	end
	return nil
end

function S:ItemIconFromID(itemID)
	if not itemID then return nil end
	if C_Item and C_Item.GetItemIconByID then
		local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
		if ok and icon then return icon end
	end
	return nil
end

function S:ItemQualityFromLink(link)
	link = Unsecret(link)
	if not (link and ItemInfoFn) then return nil end
	local ok, _, _, quality = pcall(ItemInfoFn, link)
	return ok and quality or nil
end

-- ===================================================================
-- Set list / lookup
-- ===================================================================
local DEFAULT_ICON = 134400

function S:GetSets()
	if not self.ES then return {} end
	local ids = self.ES.GetEquipmentSetIDs()
	local out = {}
	for _, id in ipairs(ids) do
		-- name, icon, setID, isEquipped, numItems, numEquipped, numInventory,
		-- numMissing, numIgnored (extended returns may not exist on this client)
		local ok, name, icon, sid, isEquipped, _, _, _, numMissing =
			pcall(self.ES.GetEquipmentSetInfo, id)
		if ok and name then
			local worn
			if isEquipped ~= nil then worn = not not isEquipped end
			out[#out + 1] = {
				id = id,
				name = name,
				icon = (type(icon) == "number" and icon ~= DEFAULT_ICON) and icon or nil,
				worn = worn,
				missing = (type(numMissing) == "number" and numMissing > 0) or nil,
			}
		end
	end
	-- fill in worn state for clients without the isEquipped return
	for _, set in ipairs(out) do
		if set.worn == nil then set.worn = self:SetWornByLocations(set.id) end
	end
	table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
	return out
end

function S:FindSetID(name)
	if not self.ES or not name or name == "" then return nil end
	local id = self.ES.GetEquipmentSetID(name)
	if id then return id end
	-- case-insensitive fallback
	for _, s in ipairs(self:GetSets()) do
		if s.name:lower() == name:lower() then return s.id end
	end
	return nil
end

function S:GetSetIcon(id)
	local _, icon = self.ES.GetEquipmentSetInfo(id)
	if icon and icon ~= DEFAULT_ICON then return icon end
	return nil
end

function S:GetIgnoredSlots(id)
	if not (self.ES and self.ES.GetIgnoredSlots) then return {} end
	local ok, t = pcall(self.ES.GetIgnoredSlots, id)
	return (ok and t) or {}
end

-- ===================================================================
-- Worn detection (live, independent of who equipped the set)
-- ===================================================================
local function SlotIsEmpty(slotID)
	local ok, id = pcall(GetInventoryItemID, "player", slotID)
	if ok and type(id) == "number" then return id == 0 end
	local ok2, link = pcall(GetInventoryItemLink, "player", slotID)
	return not (ok2 and link)
end

-- fallback worn check: every stored item must currently resolve to a
-- player slot, and every intentionally-empty slot must be empty
function S:SetWornByLocations(id)
	local okL, locations = pcall(function() return self.ES.GetItemLocations(id) end)
	if not (okL and locations) then return false end
	local ignored = self:GetIgnoredSlots(id)
	local any = false
	for slotID, loc in pairs(locations) do
		if not ignored[slotID] then
			if type(loc) == "number" and loc > 1 then
				local d = self:LocData(loc)
				if not (d and d.isPlayer) then return false end
				any = true
			elseif loc == 0 then
				if not SlotIsEmpty(slotID) then return false end
				any = true
			end
		end
	end
	return any
end

function S:IsSetWorn(id)
	if not (self.ES and id) then return false end
	local ok, _, _, _, isEquipped = pcall(self.ES.GetEquipmentSetInfo, id)
	if ok and isEquipped ~= nil then return not not isEquipped end
	return self:SetWornByLocations(id)
end

-- ===================================================================
-- Save / update sets from current gear
-- includeSlots: nil = all slots, or { [slotName]=true } whitelist
-- ===================================================================
-- every mutating C_EquipmentSet call goes through here so failures
-- are visible in chat instead of silently doing nothing. Declared before
-- every caller: Lua locals are only in scope below their declaration.
local function ESCall(method, ...)
	local fn = S.ES and S.ES[method]
	if type(fn) ~= "function" then
		S:Print("C_EquipmentSet." .. method .. " " .. (L and L["is missing on this client"] or "missing"))
		S.lastErr = "missing:" .. method
		return false
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		S.lastErr = method .. ": " .. tostring(err)
		S:Print("C_EquipmentSet." .. method .. " -> " .. tostring(err))
		return false
	end
	return true
end

function S:SetSetIcon(id, icon)
	local ok, name = pcall(self.ES.GetEquipmentSetInfo, id)
	if not (ok and name) then return false end
	return ESCall("ModifyEquipmentSet", id, name, icon or DEFAULT_ICON)
end

function S:ApplySlotIgnores(includeSlots)
	ESCall("ClearIgnoredSlotsForSave")
	if includeSlots then
		for _, s in ipairs(self.SLOTS) do
			if s.id and not includeSlots[s.name] then
				ESCall("IgnoreSlotForSave", s.id)
			end
		end
	end
end

function S:SaveCurrentGear(name, icon, includeSlots)
	if not name or name == "" then return nil, "noname" end
	local okNum, num = pcall(function()
		return (self.ES.GetNumEquipmentSets and self.ES.GetNumEquipmentSets()) or 0
	end)
	if okNum and (num or 0) >= (MAX_EQUIPMENT_SETS_PER_PLAYER or 100) then
		return nil, "full"
	end
	if self:FindSetID(name) then return nil, "exists" end

	self:ApplySlotIgnores(includeSlots)
	if not ESCall("CreateEquipmentSet", name, icon or DEFAULT_ICON) then return nil, "createfailed" end
	local id = self.ES.GetEquipmentSetID(name)
	if id then
		ESCall("SaveEquipmentSet", id, icon or DEFAULT_ICON)
	end
	return id
end

function S:UpdateSetFromCurrent(id, includeSlots)
	if not id then return false end
	self:ApplySlotIgnores(includeSlots)
	local _, icon = self.ES.GetEquipmentSetInfo(id)
	return ESCall("SaveEquipmentSet", id, icon or DEFAULT_ICON)
end

function S:RenameSet(id, name)
	if not id or not name or name == "" then return false end
	local _, icon = self.ES.GetEquipmentSetInfo(id)
	return ESCall("ModifyEquipmentSet", id, name, icon or DEFAULT_ICON)
end

function S:DeleteSet(id)
	if not id then return false end
	return ESCall("DeleteEquipmentSet", id)
end

-- ===================================================================
-- Wearing
-- ===================================================================
function S:WearSet(id)
	if not id then return false end
	local ok, err = pcall(self.ES.UseEquipmentSet, id)
	if not ok then S:Print("UseEquipmentSet -> " .. tostring(err)) end
	if ok then
		local name = self.ES.GetEquipmentSetInfo(id)
		self.activeSet = name
		self:RefreshSets()
		return true
	end
	self.lastErr = err
	return false
end

function S:WearSetByName(name)
	local id = self:FindSetID(name)
	if id then return self:WearSet(id) end
	return false
end

-- ===================================================================
-- Set contents
-- ===================================================================
-- Returns { [slotName] = { icon, link, itemID, name, quality, state } }
-- state: "equipped" | "bags" | "bank" | "missing" | "empty"
function S:GetSetItems(id)
	local items = {}
	if not id then return items end

	local okL, locations = pcall(function() return self.ES.GetItemLocations(id) end)
	local ignored = self:GetIgnoredSlots(id)
	if not okL then locations = nil end

	for _, s in ipairs(self.SLOTS) do
		local slotID = s.id
		if slotID then
			local loc = locations and locations[slotID]
			local isIgnored = ignored[slotID]

			if isIgnored or loc == nil or loc == 0 or loc == 1 then
				items[s.name] = { state = "empty" }
			else
				local d = self:LocData(loc)
				local link = self:LinkFromLocation(loc)
				local itemID = link and self:ItemIDFromLink(link) or self:ItemIDFromLocation(loc)
				local state = "missing"
				if d then
					if d.isPlayer then state = "equipped"
					elseif d.isBags then state = "bags"
					elseif d.isBank then state = "bank" end
				end

				local name = self:ItemName(link)
				if not name and itemID and C_Item and C_Item.GetItemNameByID then
					local okN, nm = pcall(C_Item.GetItemNameByID, itemID)
					if okN then name = nm end
				end

				items[s.name] = {
					state = state,
					link = link,
					itemID = itemID,
					name = name,
					icon = self:ItemIconFromID(itemID),
					quality = link and self:ItemQualityFromLink(link) or nil,
				}
			end
		end
	end
	return items
end

function S:SetHasMissing(id)
	if not self.ES or not id then return false end
	local okL, locations = pcall(function() return self.ES.GetItemLocations(id) end)
	if not okL or not locations then return false end
	local ignored = self:GetIgnoredSlots(id)
	for slotID, loc in pairs(locations) do
		if not ignored[slotID] and type(loc) == "number" and loc > 1 then
			local d = self:LocData(loc)
			if d and not d.isPlayer and not d.isBags and not d.isBank then
				return true
			end
		end
	end
	return false
end

-- ===================================================================
-- Icon collection for the icon picker (guaranteed-valid fileIDs:
-- set items, equipped gear, bag contents, macro icons if available)
-- ===================================================================
local function BagIcon(bag, slot)
	if C_Container and C_Container.GetContainerItemInfo then
		local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
		if ok and type(info) == "table" then return info.iconFileID end
	end
	if GetContainerItemInfo then
		local ok, icon = pcall(GetContainerItemInfo, bag, slot)
		if ok and type(icon) == "number" then return icon end
	end
	return nil
end

local MAX_PICKER_ICONS = 240

function S:CollectIcons(setID)
	local icons, seen = {}, {}
	local function add(icon)
		if type(icon) == "number" and icon > 0 and not seen[icon] then
			seen[icon] = true
			icons[#icons + 1] = icon
		end
	end

	-- 1) icons of items already stored in the set being edited
	if setID then
		local items = self:GetSetItems(setID)
		for _, s in ipairs(self.SLOTS) do
			local it = items[s.name]
			if it and it.icon then add(it.icon) end
		end
	end

	-- 2) currently equipped items
	for _, s in ipairs(self.SLOTS) do
		if s.id then
			local ok, itemID = pcall(GetInventoryItemID, "player", s.id)
			if ok and type(itemID) == "number" and itemID > 0 then
				add(self:ItemIconFromID(itemID))
			else
				local ok2, link = pcall(GetInventoryItemLink, "player", s.id)
				if ok2 and link then
					local iid = self:ItemIDFromLink(link)
					if iid then add(self:ItemIconFromID(iid)) end
				end
			end
		end
	end

	-- 3) bag contents
	for bag = 0, (NUM_BAG_SLOTS or 4) do
		local num = 0
		if C_Container and C_Container.GetContainerNumSlots then
			local ok, n = pcall(C_Container.GetContainerNumSlots, bag)
			num = (ok and n) or 0
		elseif GetContainerNumSlots then
			local ok, n = pcall(GetContainerNumSlots, bag)
			num = (ok and n) or 0
		end
		for slot = 1, num do
			add(BagIcon(bag, slot))
			if #icons >= MAX_PICKER_ICONS then return icons end
		end
	end

	-- 4) generic icon pool, if the client still exposes it
	if type(GetMacroIcons) == "function" and #icons < MAX_PICKER_ICONS then
		local ok, t = pcall(function()
			local out = {}
			GetMacroIcons(out)
			return out
		end)
		if ok and type(t) == "table" then
			for _, icon in ipairs(t) do
				add(icon)
				if #icons >= MAX_PICKER_ICONS then break end
			end
		end
	end

	if #icons == 0 then add(DEFAULT_ICON) end
	return icons
end

-- ===================================================================
-- Tooltip map: itemID -> { setName, ... }
-- ===================================================================
S._itemSets = nil
S._itemSetsItemID = nil -- last hovered? no, just cache marker

function S:InvalidateItemSets()
	S._itemSets = nil
end

function S:BuildItemSets()
	local map = {}
	for _, set in ipairs(self:GetSets()) do
		local okL, locations = pcall(function() return self.ES.GetItemLocations(set.id) end)
		if okL and locations then
			local ignored = self:GetIgnoredSlots(set.id)
			for slotID, loc in pairs(locations) do
				if not ignored[slotID] and type(loc) == "number" and loc > 1 then
					local itemID = self:ItemIDFromLocation(loc)
					if itemID then
						map[itemID] = map[itemID] or {}
						table.insert(map[itemID], set.name)
					end
				end
			end
		end
	end
	-- dedupe names per item
	for itemID, names in pairs(map) do
		local seen, out = {}, {}
		for _, n in ipairs(names) do
			if not seen[n] then seen[n] = true out[#out + 1] = n end
		end
		table.sort(out)
		map[itemID] = out
	end
	S._itemSets = map
	return map
end

function S:GetSetsForItem(itemID)
	if not itemID then return nil end
	local map = S._itemSets or S:BuildItemSets()
	return map[itemID]
end
