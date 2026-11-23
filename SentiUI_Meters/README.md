# SentiUI Meters

Dockable meter windows for SentiUI. Up to four small panels sit beside the
loot chat panel at the bottom of the screen, each rendering its own metric
from the client's built-in damage meter data (`C_DamageMeter`) - no combat
log parsing and no external meter addon required.

## Metrics per window

Damage done, DPS, healing done, HPS, absorbs, damage taken, interrupts,
dispels, deaths - plus a **Threat** mode that shows every group member's
scaled threat on your current target (`UnitDetailedThreatSituation`).

Each window is configured on its own: right-click a window's title for the
metric and segment menu (current fight / overall), or use the SentiUI
options page (SentiUI > Meters). A `+ New window` entry at the bottom of
that menu turns on the next free window (up to four); it docks onto the
left edge of the last shown one, toward the action bars.

## Layout

- Fixed size per window: `Width` and `Height` in the options frame a
  clipped view the list scrolls inside of - the window never grows with
  the entry count. A gold thumb on the right edge shows the position;
  the mouse wheel scrolls, also in combat (a raid threat list is 40
  rows).
- Default anchor: left edge of the right chat panel (the loot window);
  window 2 stacks left of window 1. Every window is a mover - drag it in
  the SentiUI move mode (`/sui` > Movers) to park it anywhere.
- Sentinel look: dark panel, gold title hairline, class-colored flat bars,
  gold edge on the row leader (and on tanks/yourself in threat mode).

## Notes

- Secret-value safe: meter answers can be secret on this client; such rows
  are skipped and a "Data hidden" hint shows instead.
- Threat mode needs an attackable target; without one the window shows
  "No target".
