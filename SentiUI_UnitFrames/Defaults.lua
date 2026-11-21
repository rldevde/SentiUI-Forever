-- UnitFrames module defaults, merged into SentiUIDB.modules.UnitFrames.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	fontSize = 11,
	healthColorMode = "CLASS",   -- CLASS | REACTION | STATIC
	healthTextMode = "BOTH",     -- PERCENT | VALUE | BOTH
	smoothBars = true,
	rangeFadeAlpha = 0.55,       -- alpha for out-of-range party/raid members
	healPredict = true,

	player = {
		enable = true, w = 220, h = 34, power = true, castbar = true,
		auras = true, classPower = true, combatText = true,
	},
	target = {
		enable = true, w = 220, h = 34, power = true, castbar = true,
		auras = true, maxBuffs = 8, maxDebuffs = 12, threatPct = true,
	},
	tot = { enable = true, w = 110, h = 20, power = false, auras = false },
	pet = { enable = true, w = 110, h = 20, power = false, auras = false },
	focus = { enable = false, w = 160, h = 26, power = true, auras = false,
		castbar = true },

	party = {
		enable = true, w = 150, h = 30, spacing = 4, growth = "DOWN",
		showPlayer = false, power = true, rangeFade = true,
		showRole = true, auras = false, showPets = true,
	},
	raid = {
		enable = true, w = 74, h = 26, spacing = 3, power = false,
		growth = "RIGHT",         -- columns grow to the right, members stack upward
		groupBy = "GROUP",        -- GROUP | CLASS | ROLE
		showSolo = false,
		unitsPerColumn = 5, maxColumns = 8,
		rangeFade = true, showRole = true, readyCheck = true,
		auras = false,            -- opt-in: aura icons on the small raid cells
	},
	boss = { enable = true, w = 160, h = 26, power = true },
	arena = { enable = true, w = 160, h = 26, power = true },

	hideBlizzard = {
		player = true, target = true, pet = true, focus = true,
		party = true, raid = true, castbar = true, boss = true,
	},
}
