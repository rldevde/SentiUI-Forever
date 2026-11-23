-- The module's options, filed under its own "Meters" section.
local _, ns = ...
local L = ns.L

local modeValues = {}
local modeOrder = {}
for _, m in ipairs(ns.Core and ns.Core.MODES or {}) do
	modeValues[m.key] = m.label
	modeOrder[#modeOrder + 1] = m.key
end

local segValues = { current = L["Current fight"], overall = L["Overall"] }
local segOrder = { "current", "overall" }

local function DockGroup(id, label)
	return {
		label = label,
		items = {
			{ type = "toggle", key = id .. ".enabled", label = L["Enabled"] },
			{ type = "dropdown", key = id .. ".mode", label = L["Metric"],
				values = modeValues, order = modeOrder,
				disabled = function(get) return not get(id .. ".enabled") end },
			{ type = "dropdown", key = id .. ".segment", label = L["Segment"],
				values = segValues, order = segOrder,
				disabled = function(get) return not get(id .. ".enabled") end },
		},
	}
end

ns.OPTIONS = {
	pages = {
		{
			id = "meters",
			label = L["Meters"],
			desc = L["Small dockable meter windows, each showing its own metric (damage, healing, threat ...) from the client's damage meter. Right-click a meter's title to pick its metric and segment."],
			groups = {
				{
					label = L["Meters"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable meters"], reload = true },
						{ type = "slider", key = "width", label = L["Width"], min = 120, max = 400, step = 5, unit = "px" },
						{ type = "slider", key = "height", label = L["Height"], min = 60, max = 400, step = 5, unit = "px",
							desc = L["Fixed body height - the list scrolls inside the window."] },
						{ type = "slider", key = "barHeight", label = L["Bar height"], min = 8, max = 24, step = 1, unit = "px" },
						{ type = "slider", key = "spacing", label = L["Row spacing"], min = 0, max = 6, step = 1, unit = "px" },
					},
				},
				DockGroup("dock1", L["Window 1"]),
				DockGroup("dock2", L["Window 2"]),
				DockGroup("dock3", L["Window 3"]),
				DockGroup("dock4", L["Window 4"]),
			},
		},
	},
}
