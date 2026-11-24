# Changelog

## 0.3.26 - 2026-11-25

- Who-pinged: a gold label under the map names whoever pinged, and a soft accent ring flash makes the ping hard to miss (the engine draws the ping blip itself; this adds attribution). Toggle under Minimap > Ping info.

## 0.3.25 - 2026-11-24

- Auto profession tracking actually fires now: the old check compared `GetProfessions()` (list indices) against skill-line ids 182/186 and never matched. The tracking list itself is the authority — its entries only exist for types the character can use, so the name match is enough.
- Re-arms after dying: `PLAYER_ALIVE` / `PLAYER_UNGHOST` (plus `SPELLS_CHANGED` for a profession learned mid-session) re-run the auto activation after a beat, since death strips tracking without a loading screen.
- Menu toggles now call the same API the tracking id came from — entries that only exist in the classic `GetTrackingInfo` list get the legacy `SetTracking`, not a `C_Minimap` index that may point at a different entry.

## 0.3.24 - 2026-11-23

- The "+" addon-button collector now accepts module opt-ins via `S.MinimapCollect`: SentiUI addons can file their own minimap buttons to be collected like any other addon's (the Admin module's button uses it).

## 0.3.23 - 2026-11-23

- The SentiUI flyout of the minimap menu is now extensible: modules can file their own rows via `S.MinimapMenuRows` (the new Admin module adds its console entry there, only on admin characters).

## 0.3.22 - 2026-11-23

- Mail indicator reworked: the docked Blizzard mail frame did not show reliably under our layout. The coords bar now carries its own small envelope next to the coordinates, driven by the same three-stage detection the panel plugin uses (HasNewMail -> icon child's IsShown -> GetLatestThreeSenders). Blizzard's frame stays faded while the bar is up and only docks to the map's top-right corner as the fallback with the bar hidden.

## 0.3.21 - 2026-11-23

- The pending-mail icon now sits inside the coords bar right next to the coordinates instead of the map's top-right corner (scaled to fit the 20px strip, falls back to the corner while the bar is hidden). Dock guards are rewritable now so the mail icon can move between the bar and the map when the coords bar is toggled.

## 0.3.20 - 2026-11-23

- Pending mail no longer kills minimap hover: MinimapCluster.IndicatorFrame is a layout container that shows together with the mail icon and - on this client - keeps its own mouse enabled, covering the whole top strip and swallowing every hover below it (zone bar, tracking, menu button, "+" trigger). Mouse is now disabled on the IndicatorFrame/InstanceDifficulty/Tracking containers only (their icon children keep their own mouse), and a width guard disables mouse on any resolved mail element that turns out to be a wide invisible container instead of the ~20px icon.

## 0.3.19 - 2026-11-23

- Addon button collector catches more buttons: the sweep only looked at Minimap's direct Button children whose name matched a "Minimap" pattern. It now also scans MinimapCluster and MinimapBackdrop children, accepts click-scripted frames (not only IsObjectType("Button")), and adds a loose match for clickable 12-64px frames parked on the ring - buttons that never said "Minimap" in their name (e.g. SentiHealButton-style frames) reach the "+" list now. Blizzard's own ring indicators (tracking, mail, difficulty, queue eye, landing page) are SKIP-listed so the wider net does not eat them.

## 0.3.18 - 2026-11-22

- Square-minimap corner brackets ride the generated `MinimapBorder.tga` — one authored gold bracket texture replaces the eight rastered strips (kept out of the accent tint so its gold survives accent customization).

## 0.3.17 - 2026-11-22

- New installer step 'Minimap': shape (square/round) and size sliders, applied live through the module's setting path. The step no longer bails on an unready module - an empty step was cached forever.

## 0.3.16 - 2026-11-22

- The tracking menu now merges both tracking APIs (the modern C_Minimap table shape and the classic positional one) and dedupes by name - on this client each API lists a different subset, so the standard entries only showed up together.
- Auto profession tracking: with Mining or Herbalism the matching tracking (Find Minerals / Find Herbs) turns itself on at login when nothing is tracked yet. A tracking turned off through the menu stays off on the next login.
- New Tracking options group: the magnifier button and the auto profession tracking.

## 0.3.15 - 2026-11-22

- The tracking magnifier is back as our own button: a magnifier at the map's top-left (the classic spot) that shows the active tracking on hover and opens a tracking menu on click - built on the client's own C_Minimap tracking API, since Blizzard's tracking chrome never showed through the dock path. Right-click on the map opens it as the last fallback. Toggle under Minimap > Elements.
- Hover self-heal: the map's mouse and wheel enablement are checked every second - something disabling them killed every hover function (zone text, wheel zoom, tracking) until re-enabled.

## 0.3.14 - 2026-11-22

- New performance icon next to the addon-button collection: a gear that shows home/world latency, framerate, addon memory and the heaviest addons on hover - the panel plugin's minimap twin. Right-click opens the settings. Toggle under Minimap > Elements.
- Zoom buttons are back: small + and - texts at the map's bottom-right corner (where the classic magnifier pair sat), quiet until hovered. The wheel zoom shares the same zoom step now. Toggle under Minimap > Zoom.
- Tracking magnifier gets an explicit Show on dock: the client can keep the frame hidden, and re-anchoring alone never revealed it.

## 0.3.13 - 2026-11-22

- Fixed flapping tooltips when hovering the minimap: interactive Blizzard chrome (zone text button, zoom buttons/hit area, calendar, addon compartment, toggle/world-map buttons) was being hidden while the client's hover scripts kept re-showing it - a show/hide war. These frames are now reparented into a hidden trash frame the ElvUI way: their Show() calls land nowhere, no flicker, no tooltips. Pure visuals still use the alpha fade.

## 0.3.12 - 2026-11-22

- Minimap menu secure rows (Reload, /click micro forwards) no longer replace the template OnClick - hardware clicks now run the macro through the client's own secure dispatch instead of flagged addon code.

## 0.3.11 - 2026-11-22

- The minimap menu's 'Reload' entry is now a real secure macro row (/reload through the engine's macro path) - calling C_UI.Reload from addon code is a blocked call on this client.

## 0.3.10 - 2026-11-22

- The minimap menu now closes on Escape via the shared S.EscClosable helper instead of a UISpecialFrames entry - addon-written entries in that game table taint the Escape dispatch.

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
