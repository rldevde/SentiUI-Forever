-- The module's options, filed under its own "Buffs" section.
local _, ns = ...
local S = SentiUI
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "buffs",
			label = L["Buffs"],
			desc = L["Buffs and debuffs as custom SentiUI icons on movable bars."],
			groups = {
				{
					label = L["Buffs"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable buffs"], reload = true,
							desc = L["Turns the buff and debuff bars off after a reload."] },
						{ type = "slider", key = "iconSize", label = L["Icon size"], min = 16, max = 48, step = 1, unit = "px", reload = true },
						{ type = "slider", key = "spacing", label = L["Icon spacing"], min = 0, max = 12, step = 1, unit = "px" },
						{ type = "slider", key = "perRow", label = L["Icons per row"], min = 4, max = 24, step = 1,
							desc = L["Icons wrap to a new line after this many icons."] },
						{ type = "toggle", key = "growLeft", label = L["Grow left"],
							desc = L["Icons flow to the left instead of to the right."] },
						{ type = "slider", key = "scale", label = L["Scale"], min = 0.5, max = 2, step = 0.05 },
						{ type = "toggle", key = "border", label = L["Sentinel border"], reload = true,
							desc = L["Draws the Sentinel border around every icon."] },
						{ type = "toggle", key = "debuffColor", label = L["Dispel-colored debuffs"], reload = true,
							desc = L["Debuff borders take their dispel type's color (Magic blue, Curse purple, ...)."] },
						{ type = "toggle", key = "hideBlizzard", label = L["Hide Blizzard frames"], reload = true,
							desc = L["Parks the stock buff/debuff frames so only SentiUI bars show."] },
					},
				},
			},
		},
	},
}
