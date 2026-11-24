# SentiUI Meters

Dockable meter windows for SentiUI. Up to four small panels sit beside the
loot chat panel at the bottom of the screen. Every window renders
`C_DamageMeter` session data itself (the same read Details uses) - no
Blizzard session windows are embedded, no combat log parsing, no external
meter addon required.

## Metrics per window

Damage done, DPS, healing done, HPS, absorbs, damage taken, interrupts,
dispels, deaths - plus a **Threat** mode that shows every group member's
scaled threat on your current target (`UnitDetailedThreatSituation`).
Rows carry the player's spec icon (`specIconID`) when the client exposes
one.

Each window is configured on its own: right-click a window's title for the
metric and segment menu - besides **Current fight** and **Overall** it
lists the **session history** the client reports
(`GetAvailableCombatSessions`), so a past fight can be revisited by name.
The SentiUI options page (SentiUI > Meters) offers the same choices.
A `+ New window` entry at the bottom of that menu turns on the next free
window (up to four); it docks onto the left edge of the last shown one,
toward the action bars. `Reset data` wipes all lists after a confirmation
prompt - the same prompt pops up on instance entry while stored data
exists. `Close window` turns the dock off (same as the title `x`);
`+ New window` or the options bring it back.

The title `>` button folds a window into a slim strip on its loot-facing
edge; clicking the strip unfolds it.

## Spell details

Left-click a player's row to open the **spell breakdown** for that source
(`GetCombatSessionSourceFromType/ID`): the top spells for the window's
metric and segment with icons, sorted by amount - the same drill-down
Details offers. Works for current, overall and picked sessions alike;
when the client does not expose the container the window says so.

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

- Overall is a real accumulated total: every session the client reports
  (expired fights + the live one) is summed per source into saved
  variables - it keeps counting through fights and survives /reload.
- Secret-value safe: sessions and spell containers can be secret tables
  on this client; guarded reads skip them and a "Data hidden" hint shows
  instead. Individual combat values (totals, rates, names, guids) ARE
  secret mid-fight - they pass through to the engine untouched: bar
  fills are StatusBars, amounts print via engine formatting, and the
  self row is flagged by the never-secret isLocalPlayer field.
- Threat mode needs an attackable target; without one the window shows
  "No target".

- `S` in a dock header shares the top five to party chat.
