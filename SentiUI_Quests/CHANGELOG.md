# Changelog

## 0.4.15 - 2026-11-25

- Completion toasts: a big card pops mid-screen when a quest is finished (and a matching card per finished objective) - fades in, holds ~3s, lifts out. Both are separate toggles (Completion toast / Objective toast under Quests) and share the progress-feed pipeline, so they ride on the progress lines being enabled.

## 0.4.14 - 2026-11-24

- Quest progress lines get the loot feed's exit animation: expired rows fly off to a screen edge while they fade - direction is a setting (Row exit: right / left / fade in place, right by default). The flight is measured once from the row's spot to off-screen and eases in quadratically, accelerating as the alpha dies; an in-place update on the same objective recalls a mid-flight row.

## 0.4.13 - 2026-11-24

- Quest progress lines (loot/kill counters mid-screen) now paint live during combat: `Paint` only touches regions, so entries no longer expire unseen inside the queue before the after-combat repaint could run.
- Tracker keeps counting in combat: when quest log reads come back secret under lockdown, each quest falls back to its last readable objective render — and a fully secret collect pass keeps the previous row set instead of blanking the tracker.
- Secret progress message text goes to the row raw (the engine prints it) instead of being dropped.
- More refresh triggers: `UNIT_QUEST_LOG_CHANGED`, `QUEST_WATCH_UPDATE`, `QUEST_ITEM_UPDATE` and `BAG_UPDATE_DELAYED` now schedule a recount so looting a quest item mid-fight updates immediately.

## 0.4.12 - 2026-11-23

- Zone detection reworked: "here" is now a SET of header names built from zone/subzone/minimap/instance text plus every map name up the player's map chain — a plain `GetRealZoneText` compare missed quests filed under a subzone or instance header (e.g. Northshire Valley vs Elwynn Forest, The Stockade).
- Headers that still match no name count as "here" when one of their quests is pinned on the player's zone map (`C_QuestLog.GetQuestsOnMap`).
- Ordering: the current zone's header block sorts first, other "here" headers next, the rest keeps log order.
- A header with a secret title no longer swallows the quests below it under the previous zone.

## 0.4.11 - 2026-11-23

- Pin and quest text are separate targets now: clicking a row's pin only marks the way (track + waypoint) and the tracker stays put - the map no longer pops open. Clicking the quest text still opens the quest on the map.
- Visual pass on the tracker: gold hairline under the title and a gold underline on zone header rows.

## 0.4.10 - 2026-11-23

- Questie tracker actually turns off now: the profile flag only gates Questie's startup - an already-built Questie_BaseFrame stayed visible until reload. The tracker frame itself is now hidden with an OnShow re-hide guard while our tracker is in charge, plus a poll that installs the guard if the frame is born late (Questie builds it in a startup coroutine).

## 0.4.9 - 2026-11-22

- Quest share fix: SendChatMessage fired directly inside the UI_INFO_MESSAGE event dispatch - a forbidden call on this client. The party share now defers through C_Timer into its own pass, prefers C_ChatInfo.SendChatMessage, and bails in combat.

## 0.4.8 - 2026-11-22

- AutoQuest fix: step detection ran only on dialog panel frame names, which never matched on this client - nothing auto-accepted or turned in. The QUEST_*/GOSSIP_* events now set a pending flag the 0.15s poll consumes outside the event dispatch, and the flag re-triggers a step on repeat visits (accept -> gossip -> accept chains).
- Turn-in order: gossip and greeting selection now pick only COMPLETE active quests (isComplete / IsActiveQuestComplete) before offered quests - an unfinished active no longer stalls the flow. /sqauto lists which dialog panels the client actually has.

## 0.4.7 - 2026-11-22

- The tracker-choice prompt and the 'reload required?' confirms now use the shared own dialog instead of StaticPopupDialogs; the tracker window closes on Escape via S.EscClosable. Removes addon-written entries from game tables the Escape dispatch reads.
## 0.4.6

- AutoQuest: quest, gossip and accept-confirm dialogs are now detected by a frame-visibility poll (step transitions) instead of QUEST_*/GOSSIP_* events that fire inside the NPC dialog dispatch.


## 0.4.5

- Quest item button, round 2: the green placeholder square was the
  client's missing-texture render - the icon picker now only accepts
  fileIDs above 100 or real path strings and prefers the second return
  (usable-flags in slot three no longer get mistaken for a texture).
  The secure button also passes the raw itemID to the `item` attribute
  now; `item:<id>` is macro syntax and does not resolve as an
  attribute, which left the button dead.

## 0.4.4

- Quest item button fixed: the item icon never showed because
  `GetQuestLogSpecialItemInfo` returns `(id, texture)` on this client
  while the code read the texture from the third return - the icon is
  now picked from whichever return is actually a texture, with
  `C_Item.GetItemIconByID` as fallback. The button also switched from a
  `/use` macro to the native `item` secure action, so quest items are
  clickable again.

## 0.4.3

- Auto-accept skips trivial/gray quests by default (new option) across
  QUEST_DETAIL, gossip lists and the legacy quest greeting; manual
  acceptance and Shift-override unchanged.

## 0.4.2

- Quest titles use real difficulty colors now (gray/green/yellow/
  orange/red) via `GetQuestDifficultyColor` with level-threshold
  fallback.

## 0.4.1

- The tracker no longer vanishes completely when the active filter
  matches nothing: with **Zone** or **All** active the frame stays up
  (header + filter buttons remain clickable) and shows a dim
  "No quests in this zone" note instead. The default watched list
  still hides when empty.

## 0.4.0

- Shift-click a quest with the chat edit box open to paste its clickable
  quest link into the message - share quests in say/party/guild channels
  like the stock tracker. With no chat box open shift-click still
  untracks.

## 0.3.9

- Fixed tracker size: a new **Fixed size** option (default on) keeps the
  tracker at the configured height whether the list is short or long -
  the scroll view clips inside the box instead of the window growing and
  shrinking with content. The *Max height* slider is now
  *Tracker height*.

## 0.3.8

- Tracker list filter: two small buttons in the header switch the list
  between watched quests (default, both dim), this zone's quests and the
  whole quest log - so the tracker stops flooding when the log is full.
  The active mode wears the accent color, clicking it again returns to
  watched. The filter is also a dropdown under SentiUI > Quests and is
  remembered.

## 0.3.7

- Fixed `ADDON_ACTION_FORBIDDEN` spam in combat
  (`Frame:ClearAllPoints`/`SetPoint`): the progress holder and rows
  could be born protected when created during lockdown. `Progress.Apply`
  defers out of combat, the row pool and `Paint` never run under
  lockdown (entries queue and repaint on regen), and the tracker wheel
  scroll no longer re-anchors frames mid-fight.

## 0.3.6

- Progress lines no longer wrap to a second row when the text is long:
  the font string has no width limit now, the row sizes itself to the
  text up to a 560px cap, the font steps down one size first when a
  line would still overflow, and the count underline follows the real
  row width.

## 0.3.5

- The progress rows no longer sit permanently on screen: they were
  created visible (with the bar at full width = three bare gold
  lines) and only got hidden on the first paint. Rows are now born
  hidden and only show while a live progress entry exists.

## 0.3.4

- Progress rows now use the shared `S.ApplyFont` path (Font object +
  verification instead of bare `SetFont`) - the same technique
  Daylight UI uses for guaranteed text on this client.

## 0.3.3

- Progress line text finally renders: the rows used `S.Font` ->
  `SetFont(STANDARD_TEXT_FONT)` which silently fails on this client,
  so bars showed with no text. Rows now use the same recipe as the
  tracker - a `GameFontNormal`-templated FontString restyled through a
  candidate list (media font, `STANDARD_TEXT_FONT`, `FRIZQT`) with a
  secret guard.

## 0.3.2

- Fixed the doubled share line: quest turn-ins posted "Quest complete:
  Quest complete: <title>" - the turn-in handler prepended the label
  and `Share()` prepended it again.
- AutoQuest: `QUEST_ACCEPT_CONFIRM` now confirms escort-style accept
  prompts too, and `/sqauto` prints whether the option is on and which
  dialog events actually registered on this client (events the client
  lacks fail silently).

## 0.3.1

- Progress rows restyled: the bare 150px accent bar under a row whose
  text failed to render looked like stray gold lines floating on
  screen. Rows now have a full-width dim backdrop + accent edge + a
  thin count track under the text; the text gets a guaranteed client
  font fallback, an explicit color and a width clip inside the row.

## 0.3.0

- Quest accept and turn-in now post to the party chat too
  (`shareProgress` covers the whole quest flow, not just objective
  counts).
- AutoQuest: optional auto accept / turn-in - accepts on
  `QUEST_DETAIL`, completes on `QUEST_PROGRESS`, turns in on
  `QUEST_COMPLETE`, and picks quests from gossip and greeting dialogs.
  A reward choice is never auto-picked; holding SHIFT talks to the NPC
  manually.


## 0.2.17

- Chevrons aimed a few millimetres off the marker: `GetCenter` answers
  in the frame's own scale space, so a scaled nav frame put the aim
  point radially off. Coordinates are now converted through the
  effective scale into UIParent space before the direction is
  computed.


## 0.2.16

- Group posting of quest progress silently never sent:
  `SendChatMessage` may only exist as `C_ChatInfo.SendChatMessage` on
  this client (the `pcall` swallowed the nil call) and `IsInGroup`
  may be missing. `Share` now resolves either send path and checks
  `IsInGroup` or `GetNumGroupMembers`.


## 0.2.15

- Fixed the pin crash (`Tracker.lua:218 attempt to call a nil value`):
  `PinQuest` called `OpenOnMap`, which was only declared as a local
  further down the file - the reference resolved to a nil global and
  every pin click died at the last step. `OpenOnMap` now sits above
  `PinQuest`.


## 0.2.14

- Chevrons overshot a moving marker: the trail segment was only
  recomputed every 0.1 s, so at close range the chevrons slid past
  where the marker had already moved to. The segment now refreshes
  every frame (cheap math; the heavy reads stay on the 0.1 s tick)
  and the line ends a fixed ~22 px before the marker instead of a
  percentage, so it can never reach past the diamond.


## 0.2.13

- Reverted the rotation flip - the original angle was right, negating
  pointed the arrows down. The real miss was the trail ending at 88%
  plus a wide fade: the chevrons now run to 97% of the distance with
  the fade squeezed into the last 10%, so they visibly arrive at the
  marker while the wrap still happens at low alpha.


## 0.2.12

- Chevrons aimed at a mirrored direction - `SetRotation` turns
  clockwise on this client while our `atan2` angle is
  counter-clockwise. The rotation is negated now, so the arrows lie
  along the actual line to the marker.


## 0.2.11

- Chevrons pointed straight up no matter where the target was:
  `math.atan` on this client takes one argument, so the two-arg call
  returned `atan(dy)` - ~90 degrees for any positive dy. A real
  `atan2` (slope + quadrant fix) now computes the direction, so the
  arrows actually aim at the marker.


## 0.2.10

- Trail polish: chevrons now fade in near the player and fade OUT
  before the marker - the wrap around the loop happens at alpha 0, so
  nothing ever jumps past the target. Positions are cached per tick
  and the march re-animates every frame, so the flow is smooth instead
  of stepping at 10 Hz.


## 0.2.9

- Real art instead of placeholder pixels: `NavMarker.tga` (gold rune
  diamond with halo), `NavChevron.tga` (soft arrow) and `NavDot.tga`
  (glow orb) ship in `Media/`. The marker uses the new diamond over an
  orb glow; the trail is now chevrons actually pointing at the target,
  marching toward it with a size and fade ramp - the screen-space
  `Line` approach was dropped.


## 0.2.8

- The direction trail looks like a trail now: where the client's `Line`
  widget exists, a soft wide gold glow under a thin bright stroke runs
  from the player to the marker, inset a little at both ends. On
  clients without it the dots stay, but with a size and alpha ramp
  drifting toward the target instead of flat identical pixels.


## 0.2.7

- Fixed a constant nav:tick error (attempt to call a nil value):
  `Nav.Restore` called `HideTrail` before the local function was
  declared, so the reference resolved to a nil global. The trail code
  is now declared ahead of `Restore`.


## 0.2.6

- The way marker no longer lingers at the destination: once the engine
  reports a distance of 2 yards or less, our diamond, distance text,
  trail and the arrow hide - the engine keeps its frame parked on the
  last spot, this just stops drawing on it.


## 0.2.5

- `/sqtest` now also dumps the row's font string state (font, text,
  string width, alpha, shown) and how many progress message types we
  claim - so the missing-text issue can be pinned down instead of
  guessed.


## 0.2.4

- Direction trail: small gold diamonds drift along the screen line from
  the player to the way marker (off while the nav frame's position is
  unreadable).
- Pin now has fallbacks for clients without `GetNextWaypoint` /
  `UiMapPoint` / `SetSuperTrackedQuestID` (current-map quest pins,
  plain-coord `SetUserWaypoint`, `SetSuperTrackedQuest`).
- Row left-click now pins the way too (map + waypoint); the pin is
  bigger, has its own tooltip, and falls back to a gold diamond if
  `Pin.tga` does not load.
- `/sqnav` prints which navigation APIs this client actually has.


## 0.2.3

- Progress rows showed their bar but no text: the line's font string
  is now built with the shared `S.Font` factory (the one every SentiUI
  text uses) instead of a manual `GameFontNormal` template + `SetFont`,
  and `SetText` is pcall-guarded. `/sqtest` paints three sample lines
  so the styling can be checked without a quest update.

## 0.2.2

- Pin click now drops the client's own waypoint on the quest's spot
  (`C_QuestLog.GetNextWaypoint` + `C_Map.SetUserWaypoint`) — that's
  what draws the route line on the world map and the edge marker on
  the minimap, on top of super-tracking the quest for the way marker.
  Right-click a pin to clear waypoint + tracking.

## 0.2.1

- Progress lines (new `progress` option): the game's yellow
  quest-progress text mid-screen is claimed via the client's own
  `BLACK_LISTED_MESSAGE_TYPES` and ours show instead — dim line, count
  in accent, a thin gold bar, a tick for finished objectives and gold
  for a finished quest. It's a mover.
- Share progress in group (new `shareProgress` option): objective
  progress and quest completion are posted to the party chat — the
  game's own localized lines, so they read right for everyone.

## 0.2.0

- Fixed-height tracker: the list caps at a "Max height" setting and
  clips into a scroll view — the mouse wheel scrolls the rows and a
  slim gold bar shows the position, instead of the tracker growing
  down the screen whenever quests come and go.
- Way marker (new `nav` option): an in-world marker rides the client's
  tracked position — a gold diamond with the distance under it on the
  spot, and an accent-tinted arrow at the screen edge pointing the way
  while the target is off-screen. Click a quest's pin in the tracker
  to make it the tracked target.

## 0.1.9

- Fixed the tracker rendering nothing at all: the objective-line list was
  declared inside the quest branch but used by the structural pass below
  it - out of scope, so `Refresh` errored on the first watched quest and
  every row stayed hidden.
- Pressing ESC on the "Which quest tracker?" popup no longer switches to
  Questie's tracker - closing the dialog only dismisses it now.

## 0.1.8

- The quest-item tooltip fill (`GameTooltip:SetHyperlink`) runs untainted
  via `securecall` - its internals read secret item data.

## 0.1.7

- Reworked `Refresh` so no `Button` widget method (`Show`, `Hide`,
  `SetPoint`, `ClearAllPoints`, `SetWidth`, `SetHeight`, `EnableMouse`,
  `SetAttribute`, `SetAlpha`) is ever called during combat lockdown.
  In combat only regions update - `FontString:SetText`, `Texture:SetTexture`
  and plain table fields are always allowed, so progress stays live while
  the structural pass is deferred to `PLAYER_REGEN_ENABLED` (`dirty` flag).
  Stale leftover rows get their text cleared so nothing ghosts mid-fight.
  This removes the forbidden-call spam for good, independent of why a row
  might count as protected on this client.
- `frame:Hide()` calls in `SetMode`/the empty path are combat-guarded too.

## 0.1.6

- Fixed `ADDON_ACTION_FORBIDDEN` spam (`Button:Show`/`SetPoint`/`SetWidth`/
  `SetHeight`/`EnableMouse`): any frame created during combat lockdown is
  born protected, and the tracker built new row frames mid-refresh - which
  could happen in combat. The tracker frame and a 45-row pool are now
  created while out of combat; Refresh never grows the pool mid-fight.

## 0.1.5

- Zone headers are collapsible: click a zone name to fold or unfold its
  quests (stored per zone in `collapsed`).
- Usable quest items get a secure `/use item:<id>` button next to the quest
  row (GetQuestLogSpecialItemInfo); the macro only updates out of combat.
- Every quest row has a gold map-pin button opening the world map on that
  quest (same path as clicking the title).
- Completion marker is now an inline `ReadyCheck-Ready` texture - the `✓`
  glyph rendered as an empty box with the client font.

## 0.1.4

- Clicking a quest now opens the world map centered on the quest's map and
  pings it (C_Map.OpenWorldMap + MapCanvas.PingQuestID) - the old
  QuestLogFrame it used before is an empty leftover window on this client.

## 0.1.3

- Fixed "FontString:SetText(): Font not set": the tracker's font strings are
  created with the GameFontNormal font object, so a font is always set;
  SetFont just restyles it (plain font paths can fail on this client).

## 0.1.2

- The tracker was empty: watched quests are now found through the client's
  own watch list (C_QuestLog.GetNumQuestWatches +
  GetQuestIDForQuestWatchIndex), with the older per-quest APIs as fallback.
- Objectives read C_QuestLog.GetQuestObjectives first (the client's table
  API), GetQuestObjectiveInfo stays as the fallback.

## 0.1.1

- Hardened every quest data read against secret values and secret tables:
  watch-type, completion and objective flags are checked with IsSecret
  before any comparison, and log info tables are skipped when they are not
  accessible - this was the source of the repeating refresh error.

## 0.1.0

- First release: the SentiUI quest tracker module.
- Tracker choice: the SentiUI tracker, Questie's tracker (when installed) or
  the Blizzard tracker. Questie users get a one-time choice dialog on first
  login; the setting lives on the Quests options page afterwards.
- SentiUI tracker: slim Sentinel-styled list of watched quests grouped by
  zone, optional [level] prefix, objective progress, completed quests and
  objectives in green. Click a quest to open its log entry, shift-click to
  stop tracking.
- While the SentiUI tracker is in charge, Questie's tracker steps aside
  (`trackerEnabled`) and its untracked-quest map icons hide; the original
  values are restored when switching back. Questie's map and minimap icons
  keep working either way.
- The Blizzard objective tracker is starved before it initializes (its
  manager functions are emptied at load) and the leftover frame is muted
  visually; it returns after a reload when the Blizzard tracker is picked
  or the module is disabled.
- Options: tracker choice, width, font size, row spacing, quest levels,
  hide in combat; the tracker is a SentiUI mover.
- Release history shows on SentiUI > Changelog (English + German).
