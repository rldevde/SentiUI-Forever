-- The module's options, filed under its own "Action Bars" section.
local _, ns = ...
local L = ns.L

local function barItems(key)
	return {
		{ type = "toggle", key = key .. ".enabled", label = L["Enable this bar"], reload = true,
			desc = L["Turns every action bar change off after a reload."] },
		{ type = "slider", key = key .. ".size", label = L["Button size"], min = 20, max = 48, step = 1, unit = "px" },
		{ type = "slider", key = key .. ".spacing", label = L["Button spacing"], min = 0, max = 10, step = 1, unit = "px" },
		{ type = "slider", key = key .. ".numButtons", label = L["Buttons"], min = 1, max = 12, step = 1 },
		{ type = "slider", key = key .. ".perRow", label = L["Buttons per row"], min = 1, max = 12, step = 1 },
		{ type = "toggle", key = key .. ".vertical", label = L["Vertical"],
			desc = L["Arrange the buttons in columns instead of rows."] },
		{ type = "dropdown", key = key .. ".visibility", label = L["Visibility"],
			values = { ALWAYS = L["Always"], COMBAT = L["In combat"], TARGET = L["With target"] },
			order = { "ALWAYS", "COMBAT", "TARGET" } },
		{ type = "toggle", key = key .. ".hideEmpty", label = L["Hide when empty"],
			desc = L["The bar vanishes while every slot is empty."] },
		{ type = "toggle", key = key .. ".mouseoverFade", label = L["Mouseover fade"],
			desc = L["Fade the bar out until the mouse is over it."] },
		{ type = "slider", key = key .. ".fadeAlpha", label = L["Fade alpha"], min = 0, max = 1, step = 0.05,
			disabled = function(get) return not get(key .. ".mouseoverFade") end },
	}
end

local function rowBar(key, title, desc)
	return {
		label = title,
		desc = desc,
		items = barItems(key),
	}
end

ns.OPTIONS = {
	pages = {
		{
			id = "bars",
			label = L["Action Bars"],
			desc = L["The SentiUI action bars: main, multi, pet, stance, totem and extra buttons."],
			groups = {
				{
					label = L["Action Bars"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable action bars"], reload = true,
							desc = L["Turns every action bar change off after a reload."] },
						{ type = "toggle", key = "hotkeys", label = L["Key bindings"],
							desc = L["Show key binding text on the buttons."] },
						{ type = "toggle", key = "counts", label = L["Counts"],
							desc = L["Show item and charge counts."] },
						{ type = "toggle", key = "macroNames", label = L["Macro names"],
							desc = L["Show the macro name under the icon."] },
						{ type = "toggle", key = "rangeColor", label = L["Range coloring"],
							desc = L["Tint buttons red while the target is out of range."] },
						{ type = "toggle", key = "cooldownDim", label = L["Cooldown dim"],
							desc = L["Desaturate the icon while its cooldown runs; it gets its color back the moment the spell is usable again."] },
						{ type = "toggle", key = "readyPulse", label = L["Ready pulse"],
							desc = L["A warm gold flash sweeps the icon when a watched cooldown finishes."] },
					},
				},
				rowBar("bar1", L["Action bar 1"],
					L["The paged main bar: follows forms, stances, vehicles and manual paging."]),
				rowBar("bar2", L["Action bar 2"], L["A static extra bar."]),
				rowBar("bar3", L["Action bar 3"], L["A static extra bar, hidden while every slot is empty."]),
				rowBar("bar4", L["Action bar 4"], L["The vertical side bar, hidden while every slot is empty."]),
				{
					label = L["Position"],
					items = {
						{ type = "text", label = L["Every bar is a registered mover: unlock move mode and drag it. Right-click a handle to reset."] },
						{ type = "button", label = L["Move frames"], text = L["Unlock"],
							func = function() SentiUI.Movers.SetUnlocked(true) end },
						{ type = "button", label = L["Reset positions"], text = L["Reset"],
							func = function()
								for _, k in ipairs({ "bar1", "bar2", "bar3", "bar4", "petbar", "stancebar", "totembar" }) do
									SentiUI.Movers.Reset(k)
								end
							end },
					},
				},
			},
		},
		{
			id = "class",
			label = L["Class & pet"],
			desc = L["Pet actions, forms/stances and shaman totems."],
			groups = {
				{
					label = L["Pet bar"],
					desc = L["The pet action bar, shown while a pet is out."],
					items = {
						{ type = "toggle", key = "petBar.enabled", label = L["Enable this bar"], reload = true },
						{ type = "slider", key = "petBar.size", label = L["Button size"], min = 16, max = 40, step = 1, unit = "px" },
						{ type = "slider", key = "petBar.spacing", label = L["Button spacing"], min = 0, max = 10, step = 1, unit = "px" },
						{ type = "toggle", key = "petBar.vertical", label = L["Vertical"],
							desc = L["Arrange the buttons in columns instead of rows."] },
					},
				},
				{
					label = L["Stance bar"],
					desc = L["Forms and stances: druid forms, warrior stances, stealth, shadowform."],
					items = {
						{ type = "toggle", key = "stanceBar.enabled", label = L["Enable this bar"], reload = true },
						{ type = "slider", key = "stanceBar.size", label = L["Button size"], min = 16, max = 40, step = 1, unit = "px" },
						{ type = "slider", key = "stanceBar.spacing", label = L["Button spacing"], min = 0, max = 10, step = 1, unit = "px" },
						{ type = "toggle", key = "stanceBar.vertical", label = L["Vertical"],
							desc = L["Arrange the buttons in columns instead of rows."] },
					},
				},
				{
					label = L["Totem bar"],
					desc = L["Shaman totem slots. Right-click a totem to destroy it."],
					items = {
						{ type = "toggle", key = "totemBar.enabled", label = L["Enable this bar"], reload = true },
						{ type = "slider", key = "totemBar.size", label = L["Button size"], min = 16, max = 40, step = 1, unit = "px" },
						{ type = "slider", key = "totemBar.spacing", label = L["Button spacing"], min = 0, max = 10, step = 1, unit = "px" },
						{ type = "toggle", key = "totemBar.vertical", label = L["Vertical"],
							desc = L["Arrange the buttons in columns instead of rows."] },
					},
				},
			},
		},
		{
			id = "extras",
			label = L["Extra buttons"],
			desc = L["The quest extra action button, the zone ability button and the vehicle/taxi exit button get movable holders."],
			groups = {
				{
					label = L["Extra buttons"],
					items = {
						{ type = "toggle", key = "extras.enabled", label = L["Enable extra buttons"], reload = true,
							desc = L["Turns every action bar change off after a reload."] },
						{ type = "toggle", key = "cooldownViewers", label = L["Cooldown viewers"], reload = true,
							desc = L["Un-park the Cooldown Manager viewers and give them the SentiUI skin plus movable positions."] },
						{ type = "text", label = L["Every bar is a registered mover: unlock move mode and drag it. Right-click a handle to reset."] },
						{ type = "button", label = L["Move frames"], text = L["Unlock"],
							func = function() SentiUI.Movers.SetUnlocked(true) end },
					},
				},
			},
		},
	},
}
