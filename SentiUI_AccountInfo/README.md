# SentiUI AccountInfo

Account-wide overview of every character, integrated into the SentiUI
suite: the former standalone SentiAccountInfo addon as a SentiUI module.
Its data still lives in `SentiAccountInfoDB`, so existing records carry
over unchanged.

## Features

- **Dashboard** - totals at a glance: characters, gold, recent scans.
- **Characters** - every known character with level, class, guild, money
  and last scan time.
- **Search** - fulltext item search across bags, bank, mail and worn
  gear of every character and imported account.
- **Character view** - one character in detail: gear, bags, bank, mail,
  quests, professions and recipes.
- **Statistics** - XP, rested, playtime, achievements, mounts, pets and
  more per character.
- **Lockouts** - raid and dungeon saves across the account, including a
  "who is NOT saved" checklist.
- **Currency & reputation** - currencies and faction standings per
  character.
- **Recipes** - known recipes per profession window visit, with
  craftability based on stored inventory.
- **Sync** - export/import strings merge characters between WoW
  accounts (LibDeflate compressed); the own record is never overwritten.
- **Item tooltips** - "who owns this" lines (bags/bank/mail/worn) on
  every item tooltip, toggleable in the window's settings page.
- **Item watchlist** - settings page accepts a list of item IDs tracked
  on the dashboard.

## Panel bar

The SentiUI_Panel plugin *AccountInfo* shows character count and total
account gold on the bottom bar; click opens the window, the menu offers
open/rescan and the richest characters.

## Commands

- `/sai` - toggle the window (`/sai help` for subcommands)
- `/sai delete <name>` - remove a stored character record
- `/sai sync` - open the sync page

## Settings

SentiUI > AccountInfo has the enable switch and an open button; the
window's own settings page covers tooltip lines and the watchlist.
