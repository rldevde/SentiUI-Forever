-- The module's options, filed under its own "Minimap" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "minimap",
			label = L["Minimap"],
			desc = L["The Sentinel minimap: shape, size, deco and its elements."],
			groups = {
				{
					label = L["Minimap"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Restyle the minimap"], reload = true,
							desc = L["Turns every minimap change off after a reload."] },
						{ type = "dropdown", key = "shape", label = L["Shape"],
							desc = L["Square gets the amber corner brackets, round gets the ring and halo."],
							values = { square = L["Square"], round = L["Round"] },
							order = { "square", "round" } },
						{ type = "slider", key = "size", label = L["Size"], min = 140, max = 320, step = 2, unit = "px" },
						{ type = "color", key = "accentColor", label = L["Accent color"],
							desc = L["Ring, corner brackets and the menu button."] },
						{ type = "toggle", key = "coords", label = L["Coordinates bar"],
							desc = L["The bar under the map with coordinates, the menu button and the addon button collection."] },
						{ type = "toggle", key = "menuButton", label = L["Menu button"],
							desc = L["The hamburger button in the bar under the map opens the game menu."] },
						{ type = "toggle", key = "addonButtons", label = L["Addon buttons"],
							desc = L["The + button collects every addon minimap button into a dropdown."] },
						{ type = "toggle", key = "rotate", label = L["Rotate with player"],
							desc = L["The map rotates with your facing instead of showing a rotating arrow."] },
					},
				},
				{
					label = L["Zone text"],
					items = {
						{ type = "dropdown", key = "locationText", label = L["Zone text"],
							values = { show = L["Always"], mouseover = L["Mouseover"], hide = L["Never"] },
							order = { "show", "mouseover", "hide" } },
						{ type = "slider", key = "locationFontSize", label = L["Font size"], min = 9, max = 20, step = 1,
							disabled = function(get) return get("locationText") == "hide" end },
					},
				},
				{
					label = L["Zoom"],
					items = {
						{ type = "toggle", key = "scrollZoom", label = L["Mouse wheel zoom"] },
						{ type = "toggle", key = "zoomReset", label = L["Zoom resets after a pause"],
							desc = L["A few seconds after the last scroll the map zooms fully out again."],
							disabled = function(get) return not get("scrollZoom") end },
					},
				},
				{
					label = L["Elements"],
					desc = L["Which parts of the minimap stay visible."],
					items = {
						{ type = "toggle", key = "hide.clock", label = L["Hide clock"] },
						{ type = "toggle", key = "hide.calendar", label = L["Hide calendar button"] },
						{ type = "toggle", key = "hide.tracking", label = L["Hide tracking icon"],
							desc = L["Otherwise it docks into the map's top-left corner."] },
						{ type = "toggle", key = "hide.mail", label = L["Hide mail icon"],
							desc = L["Otherwise it sits top-right when new mail arrives."] },
						{ type = "toggle", key = "hide.difficulty", label = L["Hide difficulty flag"] },
					},
				},
				{
					label = L["Position"],
					items = {
						{ type = "text", label = L["The whole minimap is a registered mover: unlock move mode and drag it. Right-click its handle to reset."] },
						{ type = "button", label = L["Move frames"], text = L["Unlock"],
							func = function() SentiUI.Movers.SetUnlocked(true) end },
						{ type = "button", label = L["Reset position"], text = L["Reset"],
							func = function() SentiUI.Movers.Reset("minimap") end },
					},
				},
			},
		},
	},
}
