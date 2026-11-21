# SentiUI Journal

Standalone dungeon compendium for SentiUI - the My-Social dungeon journal
ported into its own module, restyled in the Sentinel look. No dependency
on My-Social: all data and artwork ship with the addon.

## Features

- **Dungeon list** with search (aliases included: "dm", "wc", ...).
- **Header** with artwork banner, icon, level range, location and
  description plus an entrance waypoint button.
- **Bosses tab** - portraits, per-boss levels and loot rows colored by
  item quality with item tooltips.
- **Quests tab** - "my faction" filter, quest book page showing level,
  tags, chains/prerequisites, objective, pickup and turn-in spots with
  waypoint buttons, warnings, notes and reward items.
- **Map tab** - dungeon floor maps with boss, entrance, ladder and quest
  pins, mouse wheel zoom and drag panning; floor choice persists.
- **Panel plugin** ("Compendium") in the lower SentiUI bar; hidden when
  the module is disabled or missing.
- Slash command: `/suij`.

## Notes

- Boss map zoom level and last viewed floor per dungeon persist in
  `SentiUIJournalDB`.
- Waypoints use the native `C_Map` user waypoint API.
