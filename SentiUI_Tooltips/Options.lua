local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "general",
			label = L["Tooltips"],
			desc = L["Tooltip settings for SentiUI."],
			groups = {
				{
					label = L["General"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable tooltips"], reload = true,
							desc = L["Turns the tooltip restyle off after a reload."] },
						{ type = "dropdown", key = "anchor", label = L["Anchor"],
							values = { fixed = L["Fixed position"], cursor = L["At cursor"] },
							order = { "fixed", "cursor" } },
						{ type = "slider", key = "cursorX", label = L["Cursor offset X"], min = -60, max = 60, step = 1, unit = "px" },
						{ type = "slider", key = "cursorY", label = L["Cursor offset Y"], min = -60, max = 60, step = 1, unit = "px" },
						{ type = "slider", key = "scale", label = L["Scale"], min = 0.6, max = 1.6, step = 0.05 },
						{ type = "toggle", key = "hideInCombat", label = L["Hide in combat"],
							desc = L["Hold Shift to see the tooltip anyway."] },
						{ type = "button", label = L["Unlock movers"], text = L["Unlock movers"],
							func = function() SentiUI.Movers.SetUnlocked(true) end },
						{ type = "button", label = L["Reset position"], text = L["Reset position"],
							func = function() SentiUI.Movers.Reset("tooltip.anchor") end },
					},
				},
				{
					label = L["Units"],
					items = {
						{ type = "toggle", key = "classColors", label = L["Class-colored name"] },
						{ type = "toggle", key = "classText", label = L["Class name in class color"] },
						{ type = "toggle", key = "levelDiffColor", label = L["Level in difficulty color"] },
						{ type = "toggle", key = "classBorder", label = L["Border in class/reaction color"] },
						{ type = "toggle", key = "coloredEdge", label = L["Colored accent edge"] },
						{ type = "toggle", key = "healthBar", label = L["Health bar"] },
						{ type = "toggle", key = "healthText", label = L["Health numbers on the bar"] },
						{ type = "slider", key = "barHeight", label = L["Bar height"], min = 2, max = 16, step = 1, unit = "px" },
						{ type = "toggle", key = "guildRank", label = L["Guild rank"] },
						{ type = "toggle", key = "myGuild", label = L["Guild member highlight"] },
						{ type = "toggle", key = "myGuildText", label = L["\"My Guild\" text tag"],
							desc = L["Shows a text tag behind your own guild name - off means the accent color alone marks it."] },
						{ type = "toggle", key = "guildFactionColors", label = L["Guild name in faction colors"],
							desc = L["Horde guilds red, Alliance guilds blue - overrides the guild name color below. Your own guild keeps the accent color."] },
						{ type = "color", key = "guildColor", label = L["Guild name color"],
							desc = L["Guild names in this color - your own guild uses the accent color."] },
						{ type = "color", key = "guildRankColor", label = L["Guild rank color"],
							desc = L["The rank tag on the guild line."] },
						{ type = "toggle", key = "roleText", label = L["Group role"] },
						{ type = "toggle", key = "unitStatus", label = L["AFK/DND status"] },
						{ type = "toggle", key = "classification", label = L["Elite/rare/boss badge"] },
						{ type = "toggle", key = "showTarget", label = L["Target of target"] },
						{ type = "toggle", key = "factionColors", label = L["Faction colors"] },
						{ type = "toggle", key = "showRealm", label = L["Realm tag"] },
						{ type = "toggle", key = "showSpec", label = L["Specialization"] },
					},
				},
				{
					label = L["Items"],
					items = {
						{ type = "toggle", key = "qualityBorder", label = L["Quality border"] },
						{ type = "toggle", key = "itemLevel", label = L["Item level"] },
						{ type = "toggle", key = "showIDs", label = L["Show IDs"] },
						{ type = "toggle", key = "stackSize", label = L["Stack size"] },
					},
				},
			},
		},
	},
}
