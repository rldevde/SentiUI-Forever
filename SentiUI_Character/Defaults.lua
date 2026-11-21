-- Character module defaults. Merged into SentiUIDB.modules.Character at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,
	names = true,          -- item names beside the icons; off gives the model room
	itemLevel = true,      -- item level line under each name
	ilvlInIcon = false,    -- item level inside the icon's corner instead
	repairAt = 0.25,       -- durability at or below this warns on the slot
	zebra = true,          -- alternate stat rows on a faint stripe
	footColors = true,     -- footer ilvl in gear quality, durability green->red
	model = true,          -- 3D character model in the middle
	statsOpen = "all",     -- "all" | "main" (Attributes + class group)
}
