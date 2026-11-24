# Changelog

## 0.1.3 - 2026-11-23

- Fix the profession tabs, the Stop button and the Professions key still doing nothing: the secure `spell` attribute only fires when it carries the spell NAME on this client, never the ID (same lesson SentiUI_Pally learned). Tab overlays and the K-keybind button now resolve their spell ID to a name before the attribute is set, falling back to the tab's OpenTradeSkill click if the name can't be resolved.

## 0.1.2 - 2026-11-23

- Fix dead profession tabs and the craft Stop button: their secure overlays set spell attributes inside an insecure PreClick handler, which taints the click dispatch so the cast dies silently. The overlays now carry their `type`/`spell`/`macrotext` attributes statically (refreshed when the tabs rebuild, never in combat), register both click phases and honor `useOnKeyDown=false` - the same proven shape as the secure reload overlay. The open profession's tab casts nothing, so clicking it can never toggle the window shut.
- Fix the close X and the Unlearn link not clicking: the full-width drag strip across the title bar won hit-testing over them on this client (same bug the messenger had). The window now registers for drag itself and only starts moving when the title band is grabbed - no clickable-eating overlay frame at all.

## 0.1.1 - 2026-11-23

- Fix dead clicks: the parked game window was only invisible - alpha 0 keeps every child button hit-testing, so the hidden Blizzard list ate the clicks over our window. The game's frame is now parked off screen (still shown, still running) and re-parked if anything moves it back.

## 0.1.0 - 2026-11-23

- New professions window in SentiUI style: recipe list (search, Skill-ups / Have materials / Slot filters, collapsible categories, favorites and tracking via right-click) on the left, the picked recipe with materials and owned counts on the right, and a create footer with amount stepper, Create all and a progress bar. Profession tabs under the title switch by casting the profession's spell; the Professions key (K) opens the last used one and closes the window again. The game's own window stays parked underneath for NPC and guild lists.
