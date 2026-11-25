local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	{
		label = L["General"],
		items = {
			{ type = "toggle", key = "enabled", label = L["Enable"] },
			{ type = "slider", key = "width", label = L["Plate width"], min = 60, max = 240, step = 1, unit = "px" },
			{ type = "slider", key = "barHeight", label = L["Health bar height"], min = 4, max = 30, step = 1, unit = "px" },
			{ type = "slider", key = "castHeight", label = L["Cast bar height"], min = 6, max = 24, step = 1, unit = "px" },
			{ type = "slider", key = "scale", label = L["Global scale"], min = 0.6, max = 1.6, step = 0.05 },
			{ type = "toggle", key = "cvarEnemies", label = L["Enemy plates (CVar)"] },
			{ type = "toggle", key = "cvarFriends", label = L["Friendly plates (CVar)"] },
			{ type = "toggle", key = "friendlyBars", label = L["Show friendly plates"] },
			{ type = "toggle", key = "friendlyNameOnly", label = L["Friendly: name only"] },
		},
	},
	{
		label = L["Health"],
		items = {
			{ type = "toggle", key = "classColors", label = L["Class-colored bars"] },
			{ type = "toggle", key = "tapGrey", label = L["Grey tapped targets"], desc = L["Mobs tapped by another group paint grey - no kill credit for you."] },
			{ type = "toggle", key = "showLevel", label = L["Show level"] },
			{ type = "toggle", key = "healthText", label = L["Health text"] },
			{ type = "toggle", key = "smoothBars", label = L["Smooth bars"],
				desc = L["Health fills ease to the new value instead of snapping."] },
			{ type = "toggle", key = "absorbBar", label = L["Absorb bar"],
				desc = L["Thin shield sliver across the top of the health fill."] },
		},
	},
	{
		label = L["Threat"],
		items = {
			{ type = "toggle", key = "threat", label = L["Threat colors"] },
			{ type = "dropdown", key = "threatRole", label = L["Tank mode"], options = {
				{ value = "auto", label = L["Auto (role/spec)"] },
				{ value = "tank", label = L["Always tank"] },
				{ value = "dps", label = L["Never tank"] },
			} },
		},
	},
	{
		label = L["Cast bar"],
		items = {
			{ type = "toggle", key = "castBar", label = L["Show cast bar"] },
			{ type = "toggle", key = "castIcon", label = L["Show cast icon"] },
		},
	},
	{
		label = L["Auras"],
		items = {
			{ type = "toggle", key = "debuffs", label = L["Show debuffs"] },
			{ type = "slider", key = "maxDebuffs", label = L["Max debuffs"], min = 0, max = 10, step = 1 },
			{ type = "toggle", key = "onlyMyDebuffs", label = L["Only my debuffs"] },
		},
	},
	{
		label = L["Extras"],
		items = {
			{ type = "toggle", key = "targetHighlight", label = L["Target highlight"] },
			{ type = "toggle", key = "raidIcon", label = L["Raid target icon"] },
			{ type = "toggle", key = "eliteMarker", label = L["Elite/rare marker"] },
			{ type = "toggle", key = "questMark", label = L["Quest mob marker"],
				desc = L["Gold ! beside a plate when the mob is needed for one of your quests."] },
			{ type = "toggle", key = "targetGlow", label = L["Target glow"] },
			{ type = "toggle", key = "executeGlow", label = L["Execute spark"] },
			{ type = "slider", key = "executePct", label = L["Execute threshold"], min = 10, max = 40, step = 5, unit = "%",
				disabled = function(get) return get("executeGlow") == false end },
			{ type = "toggle", key = "gradientFill", label = L["Gradient fill"] },
			{ type = "toggle", key = "dimOthers", label = L["Dim non-target plates"] },
			{ type = "toggle", key = "comboPips", label = L["Combo points"] },
		},
	},
}
