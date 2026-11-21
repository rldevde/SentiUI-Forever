-- The module's options, filed under its own "BugSack" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "bugsack",
			label = L["BugSack"],
			desc = L["The SentiUI error grabber: catches Lua errors and forbidden calls, groups them by addon and shows them ready to copy."],
			groups = {
				{
					label = L["BugSack"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Grab errors"], reload = true,
							desc = L["Captures Lua errors, warnings and blocked calls. Needs a reload to take effect fully."] },
						{ type = "toggle", key = "chat", label = L["Chat notice on new errors"],
							desc = L["Prints a clickable line into chat when a new error lands."] },
						{ type = "toggle", key = "mute", label = L["Sound on new errors"],
							invert = true },
						{ type = "toggle", key = "auto", label = L["Auto-open on new errors"],
							desc = L["Opens the BugSack window when an error lands (never in combat)."] },
					},
				},
				{
					label = L["BugSack"],
					items = {
						{ type = "button", label = L["Open BugSack"], text = L["Open"],
							func = function() ns.Window.Toggle() end },
						{ type = "button", label = L["Export session"], text = L["Export"],
							func = function() ns.Window.OpenExport("session") end },
						{ type = "button", label = L["Export all"], text = L["Export"],
							func = function() ns.Window.OpenExport("all") end },
						{ type = "button", label = L["Wipe all errors"], text = L["Wipe"],
							confirm = true, func = function() ns.Grab:Reset() end },
						{ type = "custom", height = 20, noSearch = true,
							build = function(row)
								local S = SentiUI
								local fs = S.Font(row, 10, S.colors.textDim)
								fs:SetPoint("LEFT", 12, 0)
								fs:SetText(L["Please post bug reports at https://dev.xrl-dev.de/bugtracker"])
							end },
					},
				},
			},
		},
	},
}
