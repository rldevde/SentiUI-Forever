-- Module options, filed under "Character" in the SentiUI settings.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "character",
			label = L["Character"],
			desc = L["The SentiUI character window: gear, stats and model."],
			groups = {
				{
					label = L["Character window"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable character module"], reload = true,
							desc = L["The Blizzard character window returns after a reload with this module off."] },
						{ type = "toggle", key = "model", label = L["Character model"],
							desc = L["Show the 3D character model in the middle."] },
						{ type = "toggle", key = "names", label = L["Item names"],
							desc = L["Show the item name next to each gear icon; off gives the model more room."] },
						{ type = "toggle", key = "itemLevel", label = L["Item level"],
							desc = L["Show the item level under each item name."] },
						{ type = "toggle", key = "ilvlInIcon", label = L["Item level in icon"],
							desc = L["Show the item level in the icon's corner instead of the text line."] },
						{ type = "slider", key = "repairAt", label = L["Repair warning at"],
							min = 0, max = 1, step = 0.05, unit = "%",
							desc = L["Gear at or below this durability is marked."] },
					},
				},
				{
					label = L["Attributes"],
					items = {
						{ type = "toggle", key = "zebra", label = L["Zebra rows"],
							desc = L["Alternate stat rows on a faint stripe."] },
						{ type = "dropdown", key = "statsOpen", label = L["Stat groups open"],
							desc = L["Which stat groups start expanded."],
							values = { all = L["All groups"], main = L["Main groups only"] },
							order = { "all", "main" } },
						{ type = "toggle", key = "footColors", label = L["Colored footer"],
							desc = L["Footer item level in gear quality, durability from green to red."] },
					},
				},
			},
		},
	},
}
