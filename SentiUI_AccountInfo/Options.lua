-- The module's options, filed under its own "AccountInfo" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "accountinfo",
			label = "AccountInfo",
			desc = L["Account-wide overview of every character: gold, bags, bank, gear, stats, lockouts and a cross-account search."],
			groups = {
				{
					label = "AccountInfo",
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable AccountInfo"], reload = true,
							desc = L["Turns the whole module off after a reload."] },
						{ type = "button", label = L["Open window"], text = L["Open"],
							desc = L["Opens the AccountInfo window - also reachable via /sai and the panel bar."],
							func = function() if ns.UI then ns.UI.Toggle() end end },
					},
				},
			},
		},
	},
}
