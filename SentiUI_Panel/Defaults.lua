-- Panel module defaults. Merged into SentiUIDB.modules.Panel at enable.
-- Per-plugin settings live under plugins.<id> and are created lazily by
-- the registry (shown / showLabel / showIcon / bar / zone / order / opts).
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	fontSize = 11,
	spacing = 8,          -- px gap between plugins inside a zone (floor: 8)

	bars = {
		top = {
			enabled = false, height = 22, alpha = 0.92, border = true,
			autoHide = false, adjustUI = true, hideInCombat = false,
			margin = 0, gloss = true, fadeIdle = 0, classColor = false,
		},
		bottom = {
			enabled = true, height = 22, alpha = 0.92, border = true,
			autoHide = false, adjustUI = true, hideInCombat = false,
			margin = 0, gloss = true, fadeIdle = 0, classColor = false,
		},
	},

	plugins = {}, -- [id] = { shown, showLabel, showIcon, bar, zone, order, opts = {} }
	chars = {},   -- ["Name @ Realm"] = money, for the gold tooltip
	played = nil, -- { total, levelTime } cached /played values

	notify = { mail = true, dura = true, bags = true, rare = true },
}
