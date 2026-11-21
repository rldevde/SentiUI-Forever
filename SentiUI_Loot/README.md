# SentiUI Loot

The loot module for SentiUI, modeled on the Sentinel loot features:
fast looting, less chat spam, a persistent loot log and Sentinel-styled
loot and roll windows.

## Features

- **Own loot window** - a Sentinel panel replaces the game's loot
  frame: every slot as a row with a quality border and a
  quality-colored name, a click loots it, hover shows the item
  tooltip. It is a SentiUI mover (`/sui unlock`); the game's window
  stays hidden while the option is on.
- **Loot feed** - your recent loot as small fading rows. The same
  item stacks its count, money pools on one row, hover shows the
  tooltip, right-click dismisses early. Self-loot is matched through
  the game's own format strings, so it works in every language.
  Mover, with row-count and hold-time settings.
- **Fast loot** - every loot slot is taken the instant the window opens,
  before it can render. Respects the autoloot modifier/cvar unless
  "always" is enabled.
- **Chat filter** - hides item loot messages below a chosen quality and,
  optionally, coin lines.
- **Loot log** - `/slootlog` (or `/sll`) opens a scrollable window with
  every loot line that carried an item, kept across sessions. Hover a
  line for the item tooltip; the Clear button wipes it.
- **Loot window skin** - the game loot window gets the Sentinel dark
  panel plus quality-colored icon borders (only while the own loot
  window is off).
- **Roll panel** - active rolls dock directly beside the loot window
  as a scrollable Sentinel column (oldest on top, wheel-scrollable).
- **Roll frame skin** - group loot rolls get a quality border around the
  item icon and tinted need, greed, pass and disenchant buttons.

## Settings

Open the SentiUI settings (minimap button or `/sui`) → **Loot**. The
module toggle asks for a reload; everything else applies live.
