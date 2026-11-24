-- The module's options, filed under its own "Blessings" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "blessings",
			label = L["Blessings"],
			desc = L["A PallyPower-compatible blessing window in SentiUI style: class rows with per-paladin assignments, missing-blessing tracking, one-click casts and full PLPWR sync with real PallyPower clients. Paladins only."],
			groups = {
				{
					label = L["Blessings"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable blessings module"], reload = true,
							desc = L["Turns the blessing window off after a reload."] },
						{ type = "text", label = L["Speaks PallyPower's protocol (PLPWR): assignments, free assignment and symbol counts sync with every real PallyPower in the group. /sp toggles the window."] },
					},
				},
				{
					label = L["Visibility"],
					items = {
						{ type = "toggle", key = "showSolo", label = L["Show when solo"] },
						{ type = "toggle", key = "showParty", label = L["Show in a group"] },
					},
				},
				{
					label = L["Assignments"],
					items = {
						{ type = "toggle", key = "freeassign", label = L["Free assignment"],
							desc = L["Let anyone in the group change your blessing assignment, like PallyPower's Free Assignment option."] },
						{ type = "toggle", key = "rfbuff", label = L["Righteous Fury reminder"],
							desc = L["Highlights the Righteous Fury button while the buff is missing."] },
					},
				},
			},
		},
	},
}
