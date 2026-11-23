# SentiUI Meters

## 0.1.3 - 2026-11-23

- Running overall: the 'Overall' segment is now a real accumulated total - every session the client reports (expired fights plus the live one) is summed per source and keeps counting through new fights. Interrupts, dispels, deaths and every other metric accumulate the same way.
- Lists survive reloads: the accumulator lives in the saved variables, so overall data is still there after /reload or relog instead of resetting.
- Reset prompt: entering an instance with stored meter data asks whether to reset the lists (Yes = C_DamageMeter.ResetAllCombatSessions + the saved accumulator). The window menu also got a 'Reset data' entry that raises the same prompt.

## 0.1.2 - 2026-11-23

- More windows: the meter menu got a '+ New window' entry that turns on the next pool dock (up to four) and chains it onto the left edge of the previous shown one, toward the action bars - each with its own metric and segment like the first two.
- Menu edge fix: the popup's top border read as missing - the flat 1px backdrop edge was too faint. The menu now draws its own four accent edge strips so the frame is visibly complete.

## 0.1.1 - 2026-11-23

- Fixed window sizes: the meters no longer grow with their entry count - width and a new height setting frame a clipped view the list scrolls inside of, with a gold thumb on the right edge and mouse-wheel scrolling (a full raid's threat list is 40 rows).
- Combat-safe rows: the 40-row pool is created at enable instead of lazily, so threat/damage lists render mid-fight without protected-frame errors and the wheel keeps scrolling in combat.

## 0.1.0 - 2026-11-23

- New module: up to two dockable meter windows beside the loot chat panel. Each dock shows its own metric from the client's damage meter data - damage done, DPS, healing, HPS, absorbs, damage taken, interrupts, dispels or deaths - plus a threat mode via UnitDetailedThreatSituation.
- Per-dock setup: right-click a meter's title to pick its metric and segment (current fight / overall); the same settings live on the Meters options page. Docks are movers and carry the Sentinel panel look with class-colored bars and a gold leader edge.
