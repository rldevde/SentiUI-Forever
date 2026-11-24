local _, ns = ...

ns.DEFAULTS = {
	enabled = true,
	width = 130,
	barHeight = 11,
	castHeight = 12,
	scale = 1,
	friendlyBars = true,     -- show plates for friendly units
	friendlyNameOnly = true, -- friendly = name + guild only, no bar
	cvarEnemies = true,      -- nameplateShowEnemies
	cvarFriends = false,     -- nameplateShowFriends
	classColors = true,      -- players: health fill in class color
	tapGrey = true,          -- mobs tapped by another group paint grey
	showLevel = true,
	healthText = false,      -- % text on the health bar
	threat = true,           -- threat-colored health fill
	threatRole = "auto",     -- auto | tank | dps
	castBar = true,
	castIcon = true,
	debuffs = true,
	maxDebuffs = 5,
	onlyMyDebuffs = true,
	targetHighlight = true,
	raidIcon = true,
	eliteMarker = true,
	smoothBars = true,       -- health fills ease to their new value
}
