-- /sui options page: writes mod.db paths that mirror the addon's own
-- nested db layout (bar.*, ui.*, minimap.*, tooltip.*). SettingChanged
-- in Core.lua dispatches a change to the right subsystem.
local _, ns = ...
local L = ns.Outfitter.L

ns.OPTIONS = {
	pages = {
		{
			id = "outfitter",
			label = L["Outfitter"],
			desc = L["Manage equipment sets: a quick-swap bar, sell protection and a styled sets window."],
			groups = {
				{
					label = L["Outfit bar"],
					items = {
						{ type = "toggle", key = "bar.enabled", label = L["Outfit bar"],
							desc = L["Floating button bar with one button per equipment set."] },
						{ type = "slider", key = "bar.scale", label = L["Scale"],
							min = 0.5, max = 1.5, step = 0.05 },
						{ type = "slider", key = "bar.combatAlpha", label = L["Combat alpha"],
							min = 0, max = 1, step = 0.05 },
						{ type = "toggle", key = "bar.showNames", label = L["Show set names"] },
						{ type = "toggle", key = "bar.vertical", label = L["Vertical bar"] },
						{ type = "toggle", key = "bar.locked", label = L["Lock position"] },
					},
				},
				{
					label = L["Behavior"],
					items = {
						{ type = "dropdown", key = "tooltip.mode", label = L["Set tooltip"],
							desc = L["When the set detail tooltip may appear."],
							values = { ALWAYS = L["Always"], OOC = L["Out of combat"], NEVER = L["Never"] },
							order = { "ALWAYS", "OOC", "NEVER" } },
						{ type = "toggle", key = "ui.protectSell", label = L["Sell protection"],
							desc = L["Outfit items sold by accident are bought back instantly."] },
						{ type = "toggle", key = "ui.bagMarker", label = L["Bag outfit markers"],
							desc = L["Marks bag items that belong to an equipment set."] },
						{ type = "toggle", key = "ui.followChar", label = L["Open with character panel"],
							desc = L["The sets window follows the character sheet."] },
						{ type = "toggle", key = "minimap.hide", label = L["Hide minimap button"] },
					},
				},
			},
		},
	},
}
