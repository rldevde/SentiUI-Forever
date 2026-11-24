-- Professions module defaults. Merged into SentiUIDB.modules.Professions
-- at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	-- list
	rarityNames = false,    -- color recipe names by crafted item rarity
	collapsed = {},         -- "profName:catName" -> true (saved folds)

	-- window spot saved by the mover (mover key "professions.window")
}
