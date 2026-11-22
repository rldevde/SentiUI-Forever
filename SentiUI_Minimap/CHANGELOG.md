# Changelog

## 0.3.9 - 2026-11-22

- The SetPoint post-hooks on Minimap and the cluster dock guards are replaced by polling: they ran inside the client's layout dispatch (panel opens) and tainted whatever protected work followed.

## 0.3.8

- Interface-dispatch audit: the menu joined UISpecialFrames once instead of on every show (the list grew without bound). Decor-kill and dock-correction hooks no longer hide or re-anchor Blizzard frames inside their show/layout dispatch - watchers poll the transitions and a pump applies corrections a frame later.


## 0.3.7

- Escape-forbidden-call fix: the minimap menu's two `OnHide` hooks ran inside the Escape dispatch (it joins `UISpecialFrames` when shown) - the sub-menu and click watcher now fold into the existing OnUpdate watcher.


## 0.3.6

- Burger menu fixed: every entry with a Blizzard micro button was dead -
  the secure `click` attribute type does not fire on this client, so
  Character/Spellbook/Talents/Quest Log/Social/Guild/Group
  Finder/Achievements/Collections/Main Menu did nothing. Rows now
  dispatch `/click <micro button>` through the client's own secure macro
  engine (the proven path), so the micro handler runs untainted.
- Entries without a micro button got hardened fallbacks: Macros loads
  the LoD addon first (`MacroFrame_LoadUI`), Keybindings tries
  `KeyBindingFrame_LoadUI` + `ToggleFrame`, and a menu first opened in
  combat retries its secure wiring on the next peaceful open instead of
  staying on Lua fallbacks forever.

## 0.3.5

- Mail icon (and other cluster indicators) can finally show: they live
  in the MinimapCluster's low strata, so a button only anchored onto
  the map rendered under it. Docked frames are lifted to the map's own
  strata and level band.

## 0.3.4

- Mail/tracking/difficulty indicators stay docked now: their parent is
  a Blizzard layout frame that re-anchors its children every time one
  shows (pending mail snapped the mail button back into the cluster
  where the panel covered it). A `SetPoint` guard pushes any foreign
  anchor back onto the map, same mechanism the landing-page button
  already used.

## 0.3.3

- Menu entries that open Blizzard panels no longer call the Toggle*
  functions from tainted code at all: rows are secure buttons whose
  `type="click"` forwards the hardware click to the parked micro buttons
  (character, spellbook, talents, quest log, guild, group finder,
  achievements, collections, world map, main menu). The micro button's own
  handler then runs untainted, so its secret compares are allowed. Fixes
  `attempt to compare a secret number value (execution tainted by
  'SentiUI_Minimap')` for real - `securecall` was tested and does NOT
  untaint on this client. Entries without a micro button keep the direct
  call.

## 0.3.2

- Menu entries that toggle Blizzard panels (character, spellbook, talents,
  quest log, ...) now run through `securecall` - the callee executes
  untainted, so Blizzard's own handlers may compare secret values. Fixes
  `attempt to compare a secret number value (execution tainted by
  'SentiUI_Minimap')` when opening the character panel.

## 0.3.1

- Release history is now filed for the in-game changelog
  (SentiUI > Changelog, English + German).

## 0.1.0

- Initial release of the SentiUI minimap module.
- Shape (round/square), scale, border (default/hidden/accent with color),
  rotate-with-player and per-element visibility for zoom buttons, zone text,
  clock, calendar, tracking, mail and the difficulty flag.
- The minimap is registered as a SentiUI mover and can be dragged in move mode.

## 0.2.0

- Reworked into the Sentinel minimap look: the map lives in a holder frame
  (the mover carries map and deco together), square shape gets amber corner
  brackets, round gets the ring + dark halo (`Media/Ring.tga`,
  `Media/CircleMask.tga`).
- Own zone text with pvp coloring: always / mouseover / never + font size.
- Hamburger menu button top-right: opens the game menu dropdown plus a
  SentiUI flyout (settings, move mode, installer, reload).
- Mouse wheel zoom with optional reset-to-out after a pause, right-click
  tracking menu, middle-click calendar.
- Indicators re-dock onto the map (mail top-right, tracking top-left,
  queue tools + landing page bottom-left, difficulty flag top-right);
  clock/calendar/tracking/mail/difficulty can each be hidden.
- `GetMinimapShape()` reports SQUARE/ROUND for other addons.

## 0.3.0

- Rebuilt on the proven `SentinelForeverCore` approach: a dark panel wraps
  the client's own minimap in place (no reparenting — `SetParent` on the
  map is protected-ish on this client) and the panel is the mover.
- `MinimapCluster` stays alive; decorations are faded with `SetAlpha(0)` +
  `EnableMouse(false)` instead of `Hide()` and a 1s ticker keeps them down —
  `GameTimeFrame`/`AddonCompartmentFrame` resurrect on this client.
- Zone bar above and coordinates bar below the map, both with the amber
  accent line; the hamburger button moved into the bottom bar.
- New "+" addon-button collection: every LibDBIcon/named minimap button is
  captured into a dropdown that forwards clicks and tooltips.
- Indicators are re-anchored onto the map without reparenting (tracking
  top-left, mail top-right, queue + landing page bottom-left, difficulty
  flag top-right); clock/calendar dock into the zone bar when shown.
- New options: coordinates bar toggle, addon-button collection toggle.
