# SentiUI — Forever

**A complete, modular interface suite for the WoW Forever client.**
Dark Sentinel panels, gold accents — every piece optional, everything configurable.

![Client](https://img.shields.io/badge/Client-WoW%20Forever%20%2F%20Camelot-ebad33)
![Interface](https://img.shields.io/badge/Interface-16001-ebad33)
![Addons](https://img.shields.io/badge/Addons-19-339eff)
![Locales](https://img.shields.io/badge/Locales-EN%20%2B%20DE-339eff)
![License](https://img.shields.io/badge/License-Source--available-lightgrey)

---

## ✨ What is SentiUI?

SentiUI replaces the Blizzard interface piece by piece — **not** as one
monolith, but as a small core plus independent `SentiUI_*` modules. Disable
the modules you don't want; the rest keeps working. All modules share the
same look, the same settings window and the same profile system.

- 🎛️ **One settings hub** — `/sui` or the minimap button; every module gets
  its own options page.
- 📐 **Unlock & move** — `/sui unlock` puts grippy handles on every movable
  frame; positions are saved per profile.
- 🧙 **First-run installer** — `/sui install` walks you through the basics
  and finishes with a proper reload.
- 👤 **Profiles** — layouts and options live in SavedVariables per
  profile; switch or copy them freely.
- 🧩 **Panel plugins** — two info bars with clock, gold, bags, mail,
  friends, guild, performance, professions and more; show/hide each plugin.
- 🌍 **Bilingual** — English and German; every user-facing string is
  localized.
- 📋 **In-game changelog** — every module reports what's new under
  *SentiUI → Changelog*.

## 📦 Modules

| Module | What it does |
|---|---|
| 🏠 **SentiUI** | Core: settings window, minimap button, movers, installer, profiles, shared style & locales, changelog, diagnostics |
| 👤 **SentiUI_AccountInfo** | Account-wide character database: dashboard, bags/bank/mail/quests per char, professions & recipes, currencies & reputation, lockouts incl. "who is *not* saved", item tooltips showing who owns what, sync via export/import strings — plus a panel plugin |
| ⚔️ **SentiUI_ActionBars** | Styled action bars, stance/pet/totem bars, micro menu, talent alert pill |
| 🎒 **SentiUI_Bags** | Combined bag & bank windows, quality borders, sorting — including purchasable bank bag slots |
| ✨ **SentiUI_Buffs** | Buff & debuff displays in the suite's style |
| 🐞 **SentiUI_BugSack** | Error grabber: captures Lua errors & blocked calls, grouped per addon and session, ready to copy |
| 🪪 **SentiUI_Character** | Character sheet: paper doll, stats, reputation |
| 💬 **SentiUI_Chat** | Restyled chat with left/right docks and an automatic *Loot* window: loot, money, XP & reputation lines leave the general chat |
| 📊 **SentiUI_DataBars** | Experience, reputation and other tracked progress bars |
| 📖 **SentiUI_Journal** | Dungeon/raid compendium |
| 💰 **SentiUI_Loot** | Own loot window with icons & quality colors, fast loot (hold your autoloot modifier for manual), Sentinel-styled group roll cards, loot feed |
| 📨 **SentiUI_Messenger** | Whisper conversations in a dedicated window |
| 🗺️ **SentiUI_Minimap** | Minimap restyle with a button menu and macro rows |
| 🎯 **SentiUI_Nameplates** | Custom nameplates |
| 📏 **SentiUI_Panel** | The two info bars + plugin system (30+ plugins, each hideable) |
| 📜 **SentiUI_Quests** | Quest log & tracker, auto-quest handling, navigation |
| 💡 **SentiUI_Tooltips** | Tooltip restyle and anchoring |
| 🎓 **SentiUI_Training** | Trainer/profession compendium |
| ❤️ **SentiUI_UnitFrames** | Player, target, party & raid frames |

## 🚀 Install

Clone this repository into your `_forever_/Interface/AddOns` folder so
each `SentiUI*` directory sits next to your other addons, then `/reload`:

```
git clone https://github.com/rldevde/SentiUI-Forever.git .
```

**Requires:** `SentiUI` (the core). Every other folder is an optional
module — but at least the enabled ones must match interface `16001`.

## ⌨️ Slash commands

| Command | Action |
|---|---|
| `/sui` | Open the settings window |
| `/sui unlock` / `/sui lock` | Toggle the frame movers |
| `/sui reset` | Reset all frame positions |
| `/sui install` | Re-run the first-run installer |
| `/sui minimap` | Toggle the minimap button |
| `/sai` | AccountInfo window (import/export/rescan subcommands) |
| `/sbs` | BugSack error window |
| `/sbags` | Toggle the bag window |
| `/suibars` | Action bar settings |
| `/spnl` | Panel settings |
| `/smsg` | Messenger window |
| `/slootlog` | Loot feed |
| `/suij` | Journal/compendium |
| `/suitr` | Training compendium |
| `/sqauto` | Auto-quest toggle |
| `/sqnav` | Quest navigation |
| `/snptest` | Nameplate test mode |

## ⚙️ Settings & layout

Open the settings via the **minimap button**, the addon compartment or
`/sui`. The left column lists every loaded module — each manages its own
page. Layout is adjusted with the movers (`/sui unlock`): drag the gold
handles, `/sui lock` when done. Everything is combat-safe: operations that
can't run in a fight queue up and finish when you leave combat.

## 🌐 Localization

Interface language follows the game client: **English** and **German** are
fully supported. Strings are keyed in English; translations live in each
module's `Locales/deDE.lua`.

## 📄 License

All rights reserved — source-available, not open source. See `LICENSE`:
you may view and use the code, but not copy, modify or redistribute it.

---

*xRL-Dev.de — made for the Forever client.*
