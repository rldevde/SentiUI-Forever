# SentiUI Quests

Quest tracker module for the SentiUI suite (WoW Forever client). Requires
`SentiUI`; `Questie` is an optional dependency.

## Tracker choice

The settings offer three trackers:

- **SentiUI tracker** — the module's own list (default).
- **Questie's tracker** — only listed while Questie is installed; switching
  to it asks for a reload because Questie builds its tracker while loading.
- **Blizzard tracker** — returns after a reload (the module had starved it).

When Questie is installed, a one-time choice dialog appears after the first
login (never in combat). The answer is stored; change it any time on the
Quests options page.

## SentiUI tracker

- **List filter in the header** — two small buttons switch the list:
  *Zone* shows only the current zone's quests, *All* the whole quest log,
  and with neither active the watched quests (default). The mode is
  saved and also lives as a dropdown on the options page.
- Watched quests grouped by zone, optional `[level]` prefix, objective
  progress with `(n/m)`, completed quests and objectives in green (inline
  `ReadyCheck-Ready` texture — the client font has no `✓` glyph).
- Zone headers are clickable: click a zone name to fold/unfold its quests;
  the folded state is stored per zone (`collapsed`).
- Every quest row has a gold map-pin button on the right. Left-click
  super-tracks the quest and drops the client's own waypoint on its spot
  (route line on the map, edge marker on the minimap), then opens the
  map; right-click clears waypoint and tracking. Clicking the title
  pins the same way, shift-click pastes the clickable quest link into
  an open chat edit box (share it in a channel) - with no chat box open
  it stops tracking the quest (the old
  `QuestLogFrame` is an empty leftover here).
- Usable quest items (`GetQuestLogSpecialItemInfo`) get a secure
  `/use item:<id>` button next to the pin; its macro only updates out of
  combat and hovers show the item tooltip.
- Fixed height with a scroll view: the list clips past `maxHeight`,
  scrolls with the mouse wheel and shows a slim gold scrollbar — the
  window never grows on accept/turn-in.
- Slim Sentinel panel, registered as the `questtracker` mover —
  drag it in move mode (`/sui unlock`).
- Options: width, max height, font size, row spacing, quest levels,
  hide in combat.
- Refreshes on quest events plus a slow ticker; all quest log reads are
  pcall- and secret-guarded.

## Way marker

- Rides `C_Navigation.GetFrame()` — the engine frame at the screen
  position of the super-tracked target: a gold rune diamond with a glow
  orb and the distance under it, the engine's off-screen arrow tinted
  accent. Custom art ships in `Media/` (`NavMarker`, `NavChevron`,
  `NavDot`).
- Chevron trail: soft gold arrows march from the player toward the
  marker, re-anchored every frame, fading in at the player and out just
  before the target. Hidden once within ~2 yards.
- Option: `Way marker` toggle.

## Progress lines & group share

- The game's yellow `UI_INFO_MESSAGE` quest lines are claimed via
  `BLACK_LISTED_MESSAGE_TYPES` and restyled: dim text, count in accent,
  a thin bar underneath, a tick for finished objectives, gold for
  finished quests. Up to three rows; the holder is the
  `quests.progress` mover. On expiry a row flies off to a screen edge
  while it fades — direction via `Row exit` (right / left / fade in
  place), same setting the loot feed uses.
- Optional `Share progress in group`: the same lines (plus quest
  accepted / turned-in) are posted to `PARTY` chat with the game's own
  localized text.
- `/sqtest` paints three sample lines and dumps row diagnostics;
  `/sqnav` reports which navigation APIs the client provides.

## AutoQuest (optional)

- `Auto accept / turn in` walks NPC quest dialogs on its own:
  `QUEST_DETAIL` accepts, `QUEST_PROGRESS` completes when finishable,
  `QUEST_COMPLETE` turns in, `GOSSIP_SHOW`/`QUEST_GREETING` pick a
  **complete** active quest first (turn-ins before new accepts), then
  an offered quest. Steps trigger from the dialog events and a
  0.15s panel poll — `/sqauto` shows which panels the client has.
- A choice of rewards is never picked automatically.
- Hold **SHIFT** to talk to an NPC manually for that interaction.

## How the others step aside

- **Blizzard**: `ObjectiveTrackerManager`'s `AddContainer`,
  `AssignModulesOrder` and `SetModuleContainer` are emptied while this addon
  loads, so the game's tracker never builds a container. What remains is
  set to alpha 0 and made click-through — the frame is never `Hide()`n
  (it is managed and would re-lay out the UI).
- **Questie**: while the SentiUI tracker is in charge,
  `Questie.db.profile.trackerEnabled` is set to `false` and
  `hideUntrackedQuestsMapIcons` to `true`. The previous values are stored in
  `SentiUIDB.modules.Quests.questieOff` and restored when switching back.
  Questie's map/minimap icons, tooltips and everything else keep working.
