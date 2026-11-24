-- UnitFrames module defaults, merged into SentiUIDB.modules.UnitFrames.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	fontSize = 11,
	healthColorMode = "CLASS",   -- CLASS | REACTION | STATIC
	healthTextMode = "VALUE",    -- PERCENT | VALUE | BOTH
	smoothBars = true,
	rangeFadeAlpha = 0.55,       -- alpha for out-of-range party/raid members
	healPredict = true,

	player = {
		enable = true, w = 220, h = 34, power = true, castbar = true,
		auras = true, classPower = true, combatText = true,
		portrait = "class", powerH = 8,
	},
	target = {
		enable = true, w = 220, h = 34, power = true, castbar = true,
		auras = true, maxBuffs = 8, maxDebuffs = 12, threatPct = true,
		portrait = "class", powerH = 8,
	},
	tot = { enable = true, w = 110, h = 20, power = false, auras = false,
		portrait = "off" },
	pet = { enable = true, w = 110, h = 20, power = false, auras = false,
		portrait = "off" },
	focus = { enable = false, w = 160, h = 26, power = true, auras = false,
		castbar = true, portrait = "off" },

	party = {
		enable = true, w = 150, h = 30, spacing = 4, growth = "DOWN",
		showPlayer = false, power = true, rangeFade = true,
		showRole = true, auras = false, showPets = true,
		defensiveIcons = true,    -- external defensive icons on party cells
		cooldownIcons = true,     -- interrupt/defensive cooldowns under the cell
		portrait = "class",       -- class icon tile on the left edge
	},
	raidTools = { enable = true, collapsed = false }, -- top-edge foldable marker tray
	altPower = true,               -- replacement for PlayerPowerBarAlt
	lowHP = true,                  -- red vignette pulse under lowHPPct health
	lowHPPct = 35,                 -- percent
	levelFlash = true,             -- gold screen flash on level ups
	shotLevelUp = false,           -- screenshot on level up
	shotAchieve = false,           -- screenshot on earned achievements
	raid = {
		enable = true, w = 74, h = 26, spacing = 3, power = false,
		growth = "RIGHT",         -- columns grow to the right, members stack upward
		groupBy = "GROUP",        -- GROUP | CLASS | ROLE
		showSolo = false,
		unitsPerColumn = 5, maxColumns = 8,
		rangeFade = true, showRole = true, readyCheck = true,
		auras = false,            -- opt-in: aura icons on the small raid cells
		defensiveIcons = true,    -- external defensive icons on raid cells
		cooldownIcons = false,    -- opt-in: interrupt/defensive cooldowns (cramped cells)
		portrait = "off",         -- opt-in: class icon/3D portrait on raid cells
	},
	boss = { enable = true, w = 160, h = 26, power = true },
	arena = { enable = true, w = 160, h = 26, power = true },

	hideBlizzard = {
		player = true, target = true, pet = true, focus = true,
		party = true, raid = true, castbar = true, boss = true,
	},
}
