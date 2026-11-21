-- The module's options, filed under its own "Loot" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "loot",
			label = L["Loot"],
			desc = L["Fast looting, a loot-spam chat filter, a persistent loot log and Sentinel-styled loot and roll windows."],
			groups = {
				{
					label = L["Loot"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable loot module"], reload = true,
							desc = L["Turns every loot change off after a reload."] },
						{ type = "button", label = L["Loot History"], text = L["Open"],
							func = function() ns.Core.ToggleHistory() end },
					},
				},
				{
					label = L["Fast loot"],
					desc = L["Every slot is taken the moment the loot window opens."],
					items = {
						{ type = "toggle", key = "fastLoot", label = L["Enable fast loot"] },
						{ type = "toggle", key = "fastLootAlways", label = L["Always fast loot"],
							desc = L["Loot instantly even without the autoloot modifier or cvar."] },
					},
				},
				{
					label = L["Chat filter"],
					desc = L["Hides loot spam in the chat windows."],
					items = {
						{ type = "toggle", key = "filter", label = L["Enable filter"] },
						{ type = "slider", key = "filterQuality", label = L["Hide below quality"], min = 0, max = 6, step = 1,
							desc = L["Item loot messages below this quality are hidden. 0 poor, 1 common, 2 uncommon, 3 rare, 4 epic, 5 legendary, 6 heirloom."] },
						{ type = "toggle", key = "hideCoin", label = L["Hide coin messages"],
							desc = L["Money loot lines disappear from the chat."] },
					},
				},
				{
					label = L["Loot log"],
					desc = L["Every loot line with an item lands in a window: /slootlog or the button above."],
					items = {
						{ type = "toggle", key = "history", label = L["Keep loot log"] },
						{ type = "slider", key = "historySize", label = L["Entries"], min = 20, max = 500, step = 20,
							disabled = function(get) return not get("history") end },
					},
				},
				{
					label = L["Loot window"],
					desc = L["A Sentinel panel replaces the game's loot window."],
					items = {
						{ type = "toggle", key = "lootWindow", label = L["Own loot window"],
							desc = L["Every loot slot as a row with quality border and colored name; a click loots it. The window is a mover."] },
					},
				},
				{
					label = L["Loot feed"],
					desc = L["Your recent loot as small fading rows."],
					items = {
						{ type = "toggle", key = "feed", label = L["Show feed"],
							desc = L["Items stack by count, money pools on one row; hover shows the tooltip, right-click dismisses. The feed is a mover."] },
						{ type = "slider", key = "feedMax", label = L["Rows"], min = 2, max = 12, step = 1,
							disabled = function(get) return not get("feed") end },
						{ type = "slider", key = "feedHold", label = L["Hold seconds"], min = 1, max = 15, step = 0.5,
							disabled = function(get) return not get("feed") end },
					},
				},
				{
					label = L["Skins"],
					desc = L["Sentinel look on the game's loot windows."],
					items = {
						{ type = "toggle", key = "lootSkin", label = L["Game loot window"],
							desc = L["Dark panel and quality-colored icon borders on the loot window."],
							disabled = function(get) return get("lootWindow") end },
						{ type = "toggle", key = "rollSkin", label = L["Roll frames"],
							desc = L["Quality border on the item icon and tinted need, greed, pass and disenchant buttons."] },
					},
				},
			},
		},
	},
}
