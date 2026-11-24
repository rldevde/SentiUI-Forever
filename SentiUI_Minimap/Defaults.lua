-- Minimap module defaults. Merged into SentiUIDB.modules.Minimap at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,
	size = 190,                    -- the map's own size, px
	shape = "square",              -- "round" (ring + halo) | "square" (corner brackets)
	locationText = "show",         -- "show" | "hide" | "mouseover"
	locationFontSize = 11,
	accentColor = { 0.92, 0.68, 0.20 }, -- ring, corner brackets, menu button
	scrollZoom = true,             -- mouse wheel zooms the map
	zoomReset = true,              -- scroll zoom falls back to fully out after a pause
	zoomButtons = true,            -- +/- zoom buttons at the map's bottom-right corner
	perfButton = true,             -- latency/fps/memory icon next to the addon buttons
	trackButton = true,            -- own tracking (magnifier) button at the map's top-left
	autoTrack = true,              -- turn on profession tracking (mining/herbs) at login
	autoTrackOff = {},             -- trackings the user turned off manually stay off
	rotate = false,                -- rotateMinimap cvar, the map turns with the player
	menuButton = true,             -- hamburger button in the bar under the map
	pingInfo = true,               -- who-pinged label + ring flash on minimap pings
	coords = true,                 -- coordinates bar below the map
	addonButtons = true,           -- "+" button collects addon minimap buttons into a dropdown
	hide = {                       -- optional minimap elements
		clock = false,             -- the time manager clock, docks into the zone bar
		calendar = false,          -- the calendar button, docks into the zone bar
		tracking = false,          -- the tracking blip, docked top-left
		mail = false,              -- the mail icon, next to the coordinates
		difficulty = false,        -- dungeon/raid difficulty flag
	},
}
