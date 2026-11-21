# Changelog

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
