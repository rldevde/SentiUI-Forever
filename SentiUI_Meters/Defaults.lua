-- Meters module defaults. Merged into SentiUIDB.modules.Meters at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	-- shared look
	width = 210,
	barHeight = 14,
	rows = 8,
	spacing = 2,

	-- each dock is configured on its own: which metric and which
	-- segment ("current" fight | "overall" data) it renders. The same
	-- values are offered by the dock's own right-click menu.
	dock1 = { enabled = true, mode = "damage", segment = "current" },
	dock2 = { enabled = false, mode = "healing", segment = "current" },
}
