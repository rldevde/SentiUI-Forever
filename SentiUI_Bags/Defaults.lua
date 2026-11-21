-- Bags module defaults. Merged into SentiUIDB.modules.Bags at enable.
local _, ns = ...

-- one visual profile per view: the carried-bags window and the bank
-- window get their own grid/overlay settings, everything is switchable
local function view(iconSize)
	return {
		iconSize = iconSize or 34,   -- px per slot
		spacing = 3,               -- px between slots
		columns = 10,              -- slots per row
		emptySlots = true,         -- draw empty slots too
		qualityBorder = true,      -- border takes the item's quality color
		showIlvl = true,           -- gear shows its item level, bottom left
		showJunkIcon = true,       -- grey items get a coin mark
	}
end

ns.DEFAULTS = {
	enabled = true,

	bags = view(34),
	bank = view(30),

	-- window behavior
	search = true,          -- search box on top of both windows
	categories = true,      -- group items under category headers
	showNew = true,         -- fresh loot lands in a "New" section first
	currency = true,        -- tracked currencies row in the footer

	-- merchant automation
	sellJunk = false,       -- auto-sell grey items when a vendor opens
	autoRepair = false,     -- auto repair at repair-capable vendors
	repairGuild = false,    -- try guild funds first
}

-- flat keys from 0.1.0 moved into db.bags; fold them over once so old
-- profiles keep their tuning instead of snapping back to defaults
function ns.MigrateDefaults(db)
	if not db.bags then db.bags = {} end
	local moved
	for _, k in ipairs({ "iconSize", "spacing", "columns", "emptySlots",
		"qualityBorder", "showIlvl", "showJunkIcon" }) do
		if db[k] ~= nil then
			db.bags[k] = db[k]
			db[k] = nil
			moved = true
		end
	end
	return moved
end
