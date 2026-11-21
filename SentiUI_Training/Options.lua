-- Options page for the training module.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	{
		type = "group",
		label = L["Trainers"],
		items = {
			{ type = "toggle", key = "enabled", label = L["Enable training window"], reload = true },
			{ type = "text", label = L["The window opens from the SentiUI panel plugin 'Training' or /suitr."] },
		},
	},
}
