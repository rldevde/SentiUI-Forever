-- The module's options, filed under its own "Panel" section.
-- Per-plugin visibility toggles are generated from the registry so new
-- plugins appear automatically.
local _, ns = ...
local S = SentiUI
local L = ns.L

local format = string.format

local function BarGroup(key, label)
	return {
		label = label,
		items = {
			{ type = "toggle", key = "bars." .. key .. ".enabled", label = L["Enabled"],
				desc = L["Show this bar at the screen edge."] },
			{ type = "slider", key = "bars." .. key .. ".height", label = L["Height"], min = 14, max = 40, step = 1, unit = "px" },
			{ type = "slider", key = "bars." .. key .. ".alpha", label = L["Opacity"], min = 0.2, max = 1, step = 0.02 },
			{ type = "slider", key = "bars." .. key .. ".margin", label = L["Margin"], min = 0, max = 40, step = 1, unit = "px",
				desc = L["Distance from the screen edge."] },
			{ type = "toggle", key = "bars." .. key .. ".autoHide", label = L["Auto-hide"],
				desc = L["Fade the bar out until the mouse nears the screen edge."] },
			{ type = "slider", key = "bars." .. key .. ".fadeIdle", label = L["Idle opacity"], min = 0, max = 1, step = 0.05,
				desc = L["Alpha while auto-hide is faded out."] },
			{ type = "toggle", key = "bars." .. key .. ".adjustUI", label = L["Adjust UI"],
				desc = L["Shrink the game UI so frames stay clear of the bar (Titan-style viewport)."] },
			{ type = "toggle", key = "bars." .. key .. ".hideInCombat", label = L["Hide in combat"] },
			{ type = "toggle", key = "bars." .. key .. ".border", label = L["Show border"] },
			{ type = "toggle", key = "bars." .. key .. ".gloss", label = L["Gloss"],
				desc = L["Subtle light strip along the top of the bar."] },
			{ type = "toggle", key = "bars." .. key .. ".classColor", label = L["Class-colored border"],
				desc = L["Tint the border and accent edge in your class color."] },
		},
	}
end

local pages = {
	{
		id = "panel",
		label = L["Panel"],
		desc = L["Titan-style info bars at the screen edges with plugins, kill statistics and toasts."],
		groups = {
			{
				label = L["Panel"],
				items = {
					{ type = "toggle", key = "enabled", label = L["Enable panel"], reload = true,
						desc = L["Turns all panel bars off after a reload."] },
					{ type = "slider", key = "fontSize", label = L["Font size"], min = 8, max = 18, step = 1, unit = "px" },
					{ type = "slider", key = "spacing", label = L["Plugin spacing"], min = 8, max = 24, step = 1, unit = "px" },
					{ type = "button", label = L["Reset layout"], text = L["Reset"],
						func = function()
							wipe(ns.db.plugins)
							ns.Plugins.ResetLayout()
						end,
						desc = L["Puts every plugin back on its default bar and zone."] },
				},
			},
			BarGroup("top", L["Top bar"]),
			BarGroup("bottom", L["Bottom bar"]),
			{
				label = L["Notifications"],
				items = {
					{ type = "toggle", key = "notify.mail", label = L["New mail toast"] },
					{ type = "toggle", key = "notify.dura", label = L["Low durability toast"] },
					{ type = "toggle", key = "notify.bags", label = L["Full bags toast"] },
					{ type = "toggle", key = "notify.rare", label = L["Rare spotted toast"] },
				},
			},
		},
	},
}

-- plugin visibility page: one toggle per registered plugin, grouped by the
-- bar it currently sits on
local pluginItems = {}
for _, def in ipairs(ns.Plugins.defs) do
	pluginItems[#pluginItems + 1] = {
		type = "toggle", key = "plugins." .. def.id .. ".shown", label = def.label,
		desc = format("%s: %s / %s", L["Default"], def.bar or "bottom", (def.zone or "LEFT"):lower()),
	}
end
table.sort(pluginItems, function(a, b) return a.label < b.label end)
pages[#pages + 1] = {
	id = "panelplugins",
	label = L["Plugins"],
	desc = L["Show or hide individual panel plugins. Zone, order and bar are set by right-click on the plugin or by shift-dragging it."],
	groups = {
		{ label = L["Plugins"], items = pluginItems },
	},
}

ns.OPTIONS = { pages = pages }

-- live-apply settings where possible
function ns.SettingChanged(mod, path)
	if not ns.db then return end
	local bar = path and path:match("^bars%.(%a+)%.")
	if bar then
		ns.Bars.ApplyBar(bar)
		ns.Bars.Relayout(bar)
		if path:match("adjustUI$") or path:match("margin$") or path:match("height$") or path:match("enabled$") then
			ns.Viewport.Apply()
		end
		return
	end
	if path == "fontSize" or path == "spacing" then
		ns.Plugins.RefreshAll()
		ns.Bars.Relayout("top")
		ns.Bars.Relayout("bottom")
		return
	end
	local pid = path and path:match("^plugins%.([%w_]+)%.")
	local def = pid and ns.Plugins.byId[pid]
	if def then
		def.last = nil
		ns.Plugins.UpdateOne(def)
	end
end
