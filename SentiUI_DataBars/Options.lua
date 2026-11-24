-- The module's options, filed under its own "Data Bars" section.
local _, ns = ...
local S = SentiUI
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "databars",
			label = L["Data Bars"],
			desc = L["Experience and reputation bars that dock onto the chat panels and can be moved freely."],
			groups = {
				{
					label = L["Data Bars"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable data bars"], reload = true,
							desc = L["Turns all data bars off after a reload."] },
						{ type = "slider", key = "height", label = L["Height"], min = 6, max = 30, step = 1, unit = "px" },
						{ type = "slider", key = "width", label = L["Width"], min = 100, max = 900, step = 5, unit = "px",
							desc = L["Only used when the bar is not docked to a chat panel."] },
						{ type = "dropdown", key = "textMode", label = L["Text"],
							values = { NONE = L["None"], PERCENT = L["Percent"], CURMAX = L["Current / max"],
								CURPERC = L["Current - percent"], REMAINING = L["Remaining"], CURVALUE = L["Current"] },
							order = { "NONE", "PERCENT", "CURMAX", "CURPERC", "REMAINING", "CURVALUE" } },
						{ type = "toggle", key = "mouseover", label = L["Show on mouseover"],
							desc = L["Bars stay invisible until you hover them."] },
						{ type = "toggle", key = "smoothBars", label = L["Smooth bars"],
							desc = L["The fill glides to new values instead of jumping, like the nameplate health bars."] },
						{ type = "toggle", key = "gainText", label = L["Gain flytext"],
							desc = L["\"+N\" numbers pop off the fill's leading edge on XP / reputation gains and rise while they fade."] },
						{ type = "dropdown", key = "orientation", label = L["Orientation"], reload = true,
							values = { HORIZONTAL = L["Horizontal"], VERTICAL = L["Vertical"] },
							order = { "HORIZONTAL", "VERTICAL" },
							desc = L["Vertical bars fill bottom to top. Height stays the bar's thickness, Width becomes its length."] },
					},
				},
				{
					label = L["Experience"],
					items = {
						{ type = "toggle", key = "xp.enable", label = L["Experience bar"] },
						{ type = "toggle", key = "xp.hideAtMaxLevel", label = L["Hide at max level"],
							disabled = function(get) return not get("xp.enable") end },
						{ type = "toggle", key = "xp.showRested", label = L["Show rested XP"],
							desc = L["A lighter segment ahead of the fill shows rested XP."],
							disabled = function(get) return not get("xp.enable") end },
						{ type = "toggle", key = "xp.showQuestXP", label = L["Show pending quest XP"],
							desc = L["A green segment shows XP waiting in completed quests."],
							disabled = function(get) return not get("xp.enable") end },
						{ type = "toggle", key = "xp.trackRate", label = L["Track XP rate"],
							desc = L["Adds XP/hour and time-to-level to the tooltip."],
							disabled = function(get) return not get("xp.enable") end },
					},
				},
				{
					label = L["Reputation"],
					items = {
						{ type = "toggle", key = "rep.enable", label = L["Reputation bar"],
							desc = L["Shows the watched faction in its standing color. Click it to open the reputation frame."] },
					},
				},
			},
		},
	},
}
