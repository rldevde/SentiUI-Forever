-- Quests module defaults. Merged into SentiUIDB.modules.Quests at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,
	tracker = "sentiui",          -- "sentiui" | "questie" | "blizzard"
	width = 260,
	maxHeight = 420,              -- view height of the scroll window
	fixedHeight = true,           -- tracker keeps maxHeight, list scrolls inside
	fontSize = 12,
	spacing = 2,
	nav = true,                   -- in-world way marker on the tracked quest
	progress = true,              -- Sentinel progress lines instead of the game's
	feedExit = "right",           -- "left"|"right" fly to that screen edge,
	                              -- "fade" fades in place
	shareProgress = true,         -- post objective progress to the party chat
	autoQuest = false,            -- auto accept / turn in at NPCs (shift skips)
	autoQuestSkipTrivial = true,  -- skip gray/trivial quests on auto-accept
	questLevels = true,           -- "[15] Title" in the list
	hideInCombat = false,
	collapsed = {},               -- zone header name -> true (folded)
	filter = "watched",           -- "watched" | "zone" | "all"
	questieOff = nil,             -- Questie settings we flipped (restored on switch)
}
