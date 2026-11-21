# SentiUI Training

Trainer compendium module for **SentiUI** (WoW Forever / Camelot
client). A window listing everything your class and weapon masters
can still teach you, plus every profession recipe you have not
learned yet — sorted by what you can do about it.

## Features

- **Spells tab**: every spell your class trainer teaches, grouped
  into *Available now* (with the total gold cost), *Missing
  requirements*, *Missing talents*, *Coming soon* (≤ 2 levels away),
  *Not yet available*, *Pet abilities*, *Ignored* and *Already
  known*. Quest-learned spells show a `[Q]` marker.
- **Weapon skills tab**: same grouping for weapon masters, with a
  **Waypoint** button per skill that drops a user waypoint at the
  trainer's location and opens the world map.
- **Professions tab**: every unlearned recipe of your learned
  professions — *Available* (craftable skill range, reputation and
  level met), *Missing requirements*, *Soon*, *Later*, *Ignored* —
  with skill requirement, source type (trainer/vendor/drop/quest)
  and cost; profession filter chips narrow the list.
- **Search** box filters every tab by name.
- **Right-click** a row to ignore/unignore it (warlock tomes are
  marked as learned instead). Ignores and tome marks persist per
  character in `SentiUITrainingDB`.
- Open via the **Trainers** plugin on the SentiUI Panel bottom bar
  or `/suitr`.

## Options

*SentiUI → Training*: enable/disable the module.

## Data

Class spell tables, weapon-skill trainer locations, quest spells,
tomes, trainer factions and the full recipe list ship as vendored
data tables in `Data/` — the same compendium data the My-Social
guild addon uses.
