# SentiUI — Forever

A modular interface suite for the WoW Forever client (Interface 16001 /
Camelot). One core settings addon plus independent modules that register
with it — enable only what you want.

## Install

Clone this repository into your `_forever_/Interface/AddOns` folder so each
`SentiUI*` directory sits next to your other addons, then `/reload`.

```
git clone https://github.com/rldevde/SentiUI-Forever.git .
```

Requires **SentiUI** (the core) — every other folder is an optional module.

## Modules

| Folder | What it replaces |
|---|---|
| `SentiUI` | Core: settings window, minimap button, movers, shared style/locales |
| `SentiUI_ActionBars` | Action bars, stance/pet/totem bars, talent alert pill |
| `SentiUI_Bags` | Combined bag/bank windows |
| `SentiUI_Buffs` | Buff/debuff displays |
| `SentiUI_BugSack` | Error capture and viewer |
| `SentiUI_Character` | Character sheet (paper doll, reputation, stats) |
| `SentiUI_Chat` | Chat windows, tabs, copy |
| `SentiUI_DataBars` | Experience/reputation/tracked bars |
| `SentiUI_Journal` | Dungeon/raid compendium |
| `SentiUI_Loot` | Loot window, rolls, fast loot, loot feed |
| `SentiUI_Messenger` | Whisper conversation window |
| `SentiUI_Minimap` | Minimap restyle + button menu |
| `SentiUI_Nameplates` | Nameplates |
| `SentiUI_Panel` | Info panel bars with plugin buttons |
| `SentiUI_Quests` | Quest log/tracker |
| `SentiUI_Tooltips` | Tooltip restyle and anchoring |
| `SentiUI_Training` | Trainer/profession compendium |
| `SentiUI_UnitFrames` | Player/target/party/raid frames |

## Settings

Open the settings via the minimap button or `/sui`. Each module keeps its
options on its own page; layout is adjusted with unlocked movers.

## License

All rights reserved — source-available, not open source. See `LICENSE`:
you may view and use the code, but not copy, modify or redistribute it.
