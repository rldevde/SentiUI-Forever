-- Data bars module defaults. Merged into SentiUIDB.modules.DataBars at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	-- shared look
	height = 14,
	width = 400,          -- only used when not anchored to a chat panel
	mouseover = false,    -- hide until hovered
	textMode = "CURPERC", -- "NONE" | "PERCENT" | "CURMAX" | "CURPERC" | "REMAINING"
	orientation = "HORIZONTAL",

	xp = {
		enable = true,
		hideAtMaxLevel = true,
		showRested = true,    -- lighter segment for rested XP ahead
		showQuestXP = true,   -- green segment for XP waiting in completed quests
		trackRate = true,     -- XP/hour + time-to-level in the tooltip
	},

	rep = {
		enable = true,
	},
}
