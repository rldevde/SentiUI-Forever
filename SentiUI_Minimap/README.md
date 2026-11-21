# SentiUI Minimap

Minimap module for the SentiUI suite (WoW Forever client). Requires `SentiUI`.

## What it does

- Wraps the client's own minimap in a dark Sentinel panel; the panel is the
  SentiUI mover (the map itself is never reparented).
- Zone bar above the map (PvP-colored zone text, configurable font size) and
  coordinates bar below it; both with the amber accent line.
- Hamburger menu in the bottom bar: opens the game menu dropdown plus a
  SentiUI flyout (settings, move mode, installer, reload). Entries that
  match a Blizzard micro button dispatch `/click <micro button>` through
  the secure macro engine (the `click` attribute type does not fire on
  this client); entries without one use guarded Lua fallbacks.
- Addon-button collection: LibDBIcon and named minimap buttons gather into a
  "+" dropdown that forwards clicks and tooltips.
- Clock with a day/night symbol next to it (sun by day, moon at night, from
  `GetGameTime`); clicking the clock opens the calendar.
- Indicators re-dock onto the map: tracking top-left, mail top-right, queue
  tools + landing page bottom-left, difficulty flag top-right.
- Mouse wheel zoom (optional reset-to-out), right-click tracking menu,
  middle-click calendar.
- `GetMinimapShape()` reports `SQUARE`/`ROUND` for other addons.

## Blizzard chrome suppression

Decorations are faded (`SetAlpha(0)` + `EnableMouse(false)`) and kept down by
a 1s ticker plus `OnShow` hooks on stubborn frames — `GameTimeFrame`,
`TimeManagerClockButton`, `AddonCompartmentFrame`, zoom buttons, borders and
backdrops resurrect on this client. The Forever-specific leftovers are also
covered: `MinimapCluster.DielFrame` (the day/night dial),
`MinimapCompassTextureUnderlay`, `MinimapContainer.PlayerCoords` and
`IndicatorFrame.CraftingOrderFrame`.

## Options

Own "Minimap" section in the settings: panel/mover, shape (round/square),
scale, border, zone text mode + size, coordinates, clock/calendar, tracking,
mail, difficulty, addon-button collection, zoom behavior.
