-- Meters module defaults. Merged into SentiUIDB.modules.Meters at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	-- shared look: fixed window size, the rows scroll inside when a
	-- metric lists more than fits (raid threat has up to 40 entries)
	width = 160,
	height = 170,
	barHeight = 14,
	spacing = 2,

	-- each dock is configured on its own: which metric and which
	-- segment ("current" fight | "overall" data) it renders. The same
	-- values are offered by the dock's own right-click menu.
	dock1 = { enabled = true, mode = "damage", segment = "current" },
	dock2 = { enabled = false, mode = "healing", segment = "current" },
	dock3 = { enabled = false, mode = "threat", segment = "current" },
	dock4 = { enabled = false, mode = "dps", segment = "overall" },
}
