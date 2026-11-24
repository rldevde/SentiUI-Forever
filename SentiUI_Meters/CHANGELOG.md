# SentiUI Meters

## 0.3.3 - 2026-11-24

- Meter rows get the real contrast fix: the class-colored fill renders as a dark muted tint (38 % brightness, Details-style) instead of a saturated fill — white row text now sits on a dark bar and stays readable while the class color remains recognizable.

## 0.3.2 - 2026-11-24

- Row text readable on bright class fills: meter and spell-breakdown name/value strings move from `OUTLINE` to `THICKOUTLINE` plus a black drop shadow.

## 0.3.1 - 2026-11-24

- Meters render live data during combat now: every damage/healing read was filtered through the secret check, and the client marks `totalAmount`/`amountPerSecond` as secret mid-fight — so the docks showed "No data" exactly while you were fighting. Secret values are now passed through untouched: row fills are StatusBars (the engine scales `SetMinMaxValues`/`SetValue` on secret numbers), amounts print via `SetFormattedText`/`AbbreviateNumbers`, row order comes from the engine's own sorting, your own row is flagged by `isLocalPlayer` (never secret), and spell ids/names/guids go to the API raw since lookups accept secrets. The overall accumulator keeps plain numbers only, so Overall freezes mid-fight but never breaks.

## 0.3.0 - 2026-11-23

- Reworked the Details way: no more embedded Blizzard session windows at all — every dock renders `C_DamageMeter` data itself, so the `Blizzard_DamageMeter` error class is gone for good.
- New: spec icons on rows (`specIconID`), a real **session history** in the right-click menu (named past fights via `GetAvailableCombatSessions`), and a **spell breakdown** window on left-clicking a player row (top spells per metric+segment via `GetCombatSessionSourceFrom*`).
- Secret-table guards now cover `combatSources`, session lists and spell containers.

## 0.2.3 - 2026-11-23

- DamageMeter errors eliminated at the root: docks now only **adopt** session windows Blizzard spawned itself (windows born under our taint keep it, and every secret comparison their handlers hit gets blamed on us). Metric/segment/look are written as plain window fields + `needsSourceWindowRefresh` so the manager's own untainted pass applies them, and dock visibility drives `SetAlpha`/`EnableMouse` instead of `Show`/`Hide` — no call into Blizzard internals remains that could reach a secret read. Docks without a spare window fall back to the custom renderer and keep retrying.

## 0.2.2 - 2026-11-23

- Fixed the `Blizzard_DamageMeter` "secret durationSeconds" error: Blizzard's session-timer path compares a secret number and throws whenever it runs inside our tainted call (`Show → UpdateShownState → UpdateSessionTimerState`). The timer is stripped chrome for us anyway, so windows we own get the whole session-timer path stubbed out before `Show()` can reach it.

## 0.2.1 - 2026-11-23

- Hardened every call into the Blizzard DamageMeter objects: session-window enumeration, entry-frame walks, children/regions, anchoring and Show/Hide are all pcall'd now — an error raised inside Blizzard code showed up as a `Blizzard_DamageMeter` error, not ours. `SetSession` also falls back to the bare `(type)` signature if the `(type, id)` form is rejected.

## 0.2.0 - 2026-11-23

- Native meter windows: every dock now hosts one of Blizzard's own DamageMeter session windows (DamageMeter:ShowNewSessionWindow) parked inside its view - the client's trusted code refreshes the rows itself, so the meter updates live in combat and scrolls natively. The window's own chrome is stripped, class colours + bar metrics applied, metric and segment per dock via SetDamageMeterType/SetSession. Threat stays on the custom renderer (no DamageMeterType exists for it); docks without a native window fall back to it as well.

## 0.1.6 - 2026-11-23

- Fold + close: every window title now carries a '>' fold button and an 'x' close button (the menu got a 'Close window' row too). Folding shrinks the window to a slim gold-caret strip on its loot-facing edge; clicking the strip unfolds it. Closing disables the dock - '+ New window' or the Meters options brings it back.

## 0.1.5 - 2026-11-23

- Row text readability: names and values now render with an outline and full text color instead of dim-on-dark-fill; the inline per-second value was brightened.

## 0.1.4 - 2026-11-23

- Slimmer windows: default width 210 -> 160 px (existing installs parked on the old default are migrated; the Width slider still allows any size).

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
