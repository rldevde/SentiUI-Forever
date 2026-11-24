-- Combat text module defaults. Merged into SentiUIDB.modules.CombatText.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	fontSize = 14,        -- base row size; crits scale up from it
	hold = 2.2,           -- seconds a row sits before it exits
	feedExit = "right",   -- "right" | "left" | "fade" - where rows fly off
	crits = true,         -- crit entries render bigger + gold
	damage = true,        -- incoming damage
	heals = true,         -- incoming healing
	misses = true,        -- miss/dodge/parry/block/resist
	gains = true,         -- energize / leech / absorb
}
