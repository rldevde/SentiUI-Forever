# Changelog

## 0.1.2 - 2026-11-24

- Fix hundreds of ADDON_ACTION_BLOCKED during combat: SPELLS_CHANGED
  repainted the RF/aura/seal chips directly, and the chips are
  protected (they contain secure buttons) - every aura tick hit a
  forbidden Show(). The chip paints now defer the whole repaint
  through RunOutOfCombat, so icon and cast attributes stay in sync
  with what a click would fire.

## 0.1.1 - 2026-11-24

- Fix casts doing nothing: the secure spell attribute needs the spell
  NAME on this client, not the id - every cast button (RF/aura/seal
  chips, greater/single blessing rows) resolves ids to names now.
- Fix grid changes not reaching the buff bar: the local name key used
  GetUnitName's realm-suffixed form while the wire tables are keyed by
  the short name - assignments written in the grid never matched the
  row the bar reads. All name keys normalize through Ambiguate short.
- Aura cell cycling in the grid skips auras the paladin does not know.

## 0.1.0 - 2026-11-23

- New blessings window for paladins, fully wire-compatible with PallyPower: the PLPWR addon channel carries REQ/SELF/ASELF, ASSIGN/PASSIGN/MASSIGN, NASSIGN, AASSIGN, CLEAR and FREEASSIGN with symbol counts and cooldowns, so assignments sync with every real PallyPower in the group.
- One row per class in the group: class icon, buffed/total count, one blessing cell per known paladin (click cycles when you may control it) and a secure cast button for your assigned blessing on the first member missing it. Rows expand to member lists with per-player overrides.
- Personal strip: aura and seal chips (wheel cycles, icon click casts) plus Righteous Fury - script-free secure buttons with static attributes and both click phases.
- Footer: auto-assign, clear, report, free-assignment checkbox, refresh. Symbol of Kings count in the title bar; /sp toggles the window.
