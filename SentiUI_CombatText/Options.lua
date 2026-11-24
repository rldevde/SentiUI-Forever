-- The module's options, filed under its own "Combat Text" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "combattext",
			label = L["Combat Text"],
			desc = L["Incoming damage, healing, misses and gains as a scrolling feed you can move anywhere."],
			groups = {
				{
					label = L["Combat text"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable combat text"], reload = true,
							desc = L["Turns the feed off after a reload."] },
						{ type = "slider", key = "fontSize", label = L["Font size"], min = 10, max = 28, step = 1 },
						{ type = "slider", key = "hold", label = L["Hold time"], min = 1, max = 8, step = 0.5, unit = "s" },
						{ type = "dropdown", key = "feedExit", label = L["Exit direction"],
							desc = L["Where rows fly when their time is up."],
							values = { right = L["Fly right"], left = L["Fly left"], fade = L["Fade in place"] },
							order = { "right", "left", "fade" } },
						{ type = "toggle", key = "crits", label = L["Crit emphasis"],
							desc = L["Critical hits render bigger and gold."] },
					},
				},
				{
					label = L["Shown events"],
					items = {
						{ type = "toggle", key = "damage", label = L["Damage taken"] },
						{ type = "toggle", key = "heals", label = L["Heals received"] },
						{ type = "toggle", key = "misses", label = L["Misses"],
							desc = L["Miss, dodge, parry, block and resist entries."] },
						{ type = "toggle", key = "gains", label = L["Resource gains"],
							desc = L["Energize, leech and absorb entries."] },
					},
				},
			},
		},
	},
}
