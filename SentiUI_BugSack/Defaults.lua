-- Module defaults. Merged into SentiUIDB.modules.BugSack at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,   -- installs the grabber (needs reload to fully detach)
	chat = true,      -- clickable chat line on new errors
	mute = false,     -- no warning sound when true
	auto = false,     -- open the window on new errors (never in combat)
}
