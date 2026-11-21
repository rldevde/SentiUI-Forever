-- Buffs module defaults, merged into SentiUIDB.modules.Buffs.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	iconSize = 28,
	spacing = 3,
	perRow = 12,      -- icons before the bar wraps to the next line
	growLeft = true, -- icons flow left, away from the minimap edge
	scale = 1,
	border = true,
	debuffColor = true, -- debuff borders tinted by dispel type
	hideBlizzard = true, -- park the stock BuffFrame/DebuffFrame
}
