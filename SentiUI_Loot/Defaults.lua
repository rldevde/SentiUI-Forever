-- Loot module defaults. Merged into SentiUIDB.modules.Loot at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	-- fast loot: every slot is taken the moment LOOT_READY fires, before
	-- the loot window can render its list
	fastLoot = true,
	fastLootAlways = false,        -- ignore the autoloot modifier and cvar

	-- chat filter: hide loot spam below a quality, plus coin lines
	filter = true,
	filterQuality = 0,             -- item messages below this quality hide (0-7)
	hideCoin = false,

	-- loot log: every loot line with an item link lands in a window
	history = true,
	historySize = 200,

	-- own loot window replaces the game's frame entirely
	lootWindow = true,

	-- loot feed: your recent loot as small fading rows
	feed = true,
	feedMax = 6,                   -- rows visible at once
	feedHold = 4,                  -- seconds a row stays after its last loot

	-- skins: Sentinel look on the loot window and the group roll frames
	lootSkin = true,
	rollSkin = true,
}
