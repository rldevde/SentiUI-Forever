local _, ns = ...
local S = ns.Outfitter
local L = S.L

-- ===================================================================
-- Equipment slots. Order = display order in the outfit detail grid.
-- slotID is resolved lazily via GetInventorySlotInfo(slotName).
-- ===================================================================
S.SLOTS = {
	{ name = "HeadSlot",        label = "HEADSLOT" },
	{ name = "NeckSlot",        label = "NECKSLOT" },
	{ name = "ShoulderSlot",    label = "SHOULDERSLOT" },
	{ name = "BackSlot",        label = "BACKSLOT" },
	{ name = "ChestSlot",       label = "CHESTSLOT" },
	{ name = "ShirtSlot",       label = "SHIRTSLOT" },
	{ name = "TabardSlot",      label = "TABARDSLOT" },
	{ name = "WristSlot",       label = "WRISTSLOT" },
	{ name = "HandsSlot",       label = "HANDSSLOT" },
	{ name = "WaistSlot",       label = "WAISTSLOT" },
	{ name = "LegsSlot",        label = "LEGSSLOT" },
	{ name = "FeetSlot",        label = "FEETSLOT" },
	{ name = "Finger0Slot",     label = "FINGER0SLOT" },
	{ name = "Finger1Slot",     label = "FINGER1SLOT" },
	{ name = "Trinket0Slot",    label = "TRINKET0SLOT" },
	{ name = "Trinket1Slot",    label = "TRINKET1SLOT" },
	{ name = "MainHandSlot",    label = "MAINHANDSLOT" },
	{ name = "SecondaryHandSlot", label = "SECONDARYHANDSLOT" },
}

S.SLOT_BY_NAME = {}
S.SLOT_BY_ID = {}
S.SLOT_IDS = {} -- slotName -> equipment set slotID

function S:InitSlots()
	for _, s in ipairs(self.SLOTS) do
		local id = GetInventorySlotInfo(s.name)
		s.id = id
		self.SLOT_BY_NAME[s.name] = s
		if id then self.SLOT_BY_ID[id] = s end
		self.SLOT_IDS[s.name] = id
	end
end

function S:SlotLabel(name)
	local s = self.SLOT_BY_NAME[name]
	if not s then return name end
	local g = _G[s.label]
	return g or s.label
end

-- Icons for the picker are collected at runtime via S:CollectIcons()
-- (set items + equipped gear + bag contents -> always valid fileIDs).
S.DEFAULT_SET_ICON = 134400 -- Blizzard default equipment-set icon
