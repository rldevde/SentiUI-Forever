# Changelog

## 0.1.12 - 2026-11-22

- Close button replaced with the shared S.Widgets.Close — consistent Sentinel look instead of the raw hand-built "x" text button.

## 0.1.11 - 2026-11-22

- Filter chips use the shared Sentinel tab chip now: dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active chip - one design language across the whole suite instead of scattered boxes.

## 0.1.10 - 2026-11-22

- Window now closes on Escape via the shared S.EscClosable helper instead of a UISpecialFrames entry - addon-written entries in that game table taint the Escape dispatch, which made protected calls (spell stop, reload) fail and get blamed on the addon.

## 0.1.9 - 2026-11-22

- The dungeon map no longer registers GLOBAL_MOUSE_UP - the event fires inside the input dispatch that then delivers the click to a button, so any addon Lua there taints it and kills the protected call behind it (Reload in the addon list, SpellStopCasting on Escape). Drag release is detected by polling the button state in OnUpdate.

## 0.1.8

- Compile fix: a slot-parser loop assigned to its loop variable (LuaJIT const-assign error) - Page.lua failed to load. Uses a local instead.

## 0.1.7

- Journal window joins the combat deferral: opening it mid-combat queues for after the fight with a chat note, and an open window hides on combat start and returns after (core S:CombatDeferWindow).

## 0.1.6

- Interface-dispatch audit: the map fallback no longer calls ToggleWorldMap via pcall - it goes through the same guarded call path as the protected waypoint APIs.


## 0.1.5

- Escape-forbidden-call fix: search box `OnEscapePressed`/`OnEditFocusLost` and the dungeon map `OnHide` hook ran inside the Escape dispatch - hint syncs via `OnTextChanged`, stale drag state resets on show instead.


## 0.1.4

- Localized remaining English bits: profession tags (Blacksmithing/Mining), faction name fallbacks, localized item names for quest start items.

## 0.1.3

- Fixed protected SetPassThroughButtons errors: Blizzard button templates replaced by Sentinel-styled homegrown buttons (map zoom/floor buttons, window close).

## 0.1.2

- Waypoint buttons work again (direct guarded call when securecall is missing).
- Quest chains show done/pending steps with green/gold numbering.
- Journal and Trainers windows are mutually exclusive.

## 0.1.1

- Boss loot rows now show the item icon in a dark socket next to the quality-colored name.

## 0.1.0

- New module: the My-Social dungeon compendium as a standalone SentiUI addon.
- Dungeon list with search and aliases, Sentinel-styled detail view with art banner.
- Bosses tab with portraits, levels and quality-colored loot rows.
- Quests tab with faction filter, quest book page, chains, waypoints and rewards.
- Map tab with floor maps, boss/entrance/quest pins, zoom and drag panning.
- Panel plugin in the lower bar opens the window; /suij toggles it.
