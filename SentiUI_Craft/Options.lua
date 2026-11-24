-- The module's options, filed under its own "Professions" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "professions",
			label = L["Professions"],
			desc = L["A professions window in SentiUI style: recipe list with search and filters, difficulty colors, material counts, and a create footer with amounts. The game's window stays parked under it for NPC and guild lists."],
			groups = {
				{
					label = L["Professions"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable professions module"], reload = true,
							desc = L["Turns the custom professions window off after a reload; the game's own window opens professions again."] },
						{ type = "text", label = L["The professions key (K) opens the last used profession in this window; press it again to close."] },
					},
				},
				{
					label = L["Recipe list"],
					items = {
						{ type = "toggle", key = "rarityNames", label = L["Rarity colors"],
							desc = L["Recipe names take the rarity color of what they make. Off, they show how likely a skill-up is."] },
					},
				},
			},
		},
	},
}
