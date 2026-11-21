local _, ns = ...

ns.DEFAULTS = {
	enabled = true,
	-- anchor: "fixed" parks tooltips on the movable anchor frame,
	-- "cursor" spawns them at the mouse with cursorX/cursorY offsets
	anchor = "fixed",
	cursorX = 14,
	cursorY = 14,
	scale = 1,
	hideInCombat = false, -- shift brings a hidden tooltip back
	-- units
	classColors = true,   -- unit name in class color
	classBorder = true,   -- border in class/reaction color
	classText = true,     -- class name in class color inside the level line
	coloredEdge = true,   -- top accent edge in unit/quality color
	levelDiffColor = true,-- level number in difficulty color (skull->grey)
	showSpec = true,      -- specialization of players (live/inspect)
	showRealm = true,     -- "-Realm" tag for cross-realm players
	healthBar = true,
	barHeight = 6,
	healthText = false,   -- current/max numbers on the bar
	guildRank = true,
	myGuild = true,       -- own guild name in accent on the guild line
	myGuildText = false,  -- "My Guild" text tag behind it (off: color only)
	guildColor = { r = 0.20, g = 0.62, b = 1.00 },     -- guild name (own guild uses accent)
	guildFactionColors = true, -- guild name in faction color instead (horde red / alliance blue)
	guildRankColor = { r = 0.92, g = 0.68, b = 0.20 }, -- rank tag on the guild line
	showTarget = true,    -- "target of target" line
	unitStatus = true,    -- AFK/DND tag on the name
	classification = true,-- elite/rare/boss badge
	roleText = true,      -- tank/healer/damage for group members
	factionColors = true, -- horde/alliance tag on the name line
	-- items
	qualityBorder = true, -- border in item quality color (uncommon+)
	itemLevel = true,
	showIDs = false,      -- item/spell IDs
	stackSize = false,
}
