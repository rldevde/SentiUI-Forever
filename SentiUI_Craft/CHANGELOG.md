# Changelog

## 0.1.1 - 2026-11-23

- Fix dead clicks: the parked game window was only invisible - alpha 0 keeps every child button hit-testing, so the hidden Blizzard list ate the clicks over our window. The game's frame is now parked off screen (still shown, still running) and re-parked if anything moves it back.

## 0.1.0 - 2026-11-23

- New professions window in SentiUI style: recipe list (search, Skill-ups / Have materials / Slot filters, collapsible categories, favorites and tracking via right-click) on the left, the picked recipe with materials and owned counts on the right, and a create footer with amount stepper, Create all and a progress bar. Profession tabs under the title switch by casting the profession's spell; the Professions key (K) opens the last used one and closes the window again. The game's own window stays parked underneath for NPC and guild lists.
