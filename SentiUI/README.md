# SentiUI

Settings core for the SentiUI interface suite (WoW Forever client).

- Minimap button: left-click opens the settings, right-click toggles move
  mode, drag repositions the button.
- `/sui` or `/sentiui` opens the window; `/sui unlock`, `/sui lock`,
  `/sui reset`, `/sui minimap`.
- The window has section/page navigation with search on the left and card
  groups on the right.
- Move mode draws a labeled handle over every frame a module registered:
  drag to move, mouse wheel to scale, right-click to reset. Grid and
  edge/center snapping are configurable under SentiUI > General.
- `SentiUI_*` module addons dock their own sections and pages into the
  window — see `API.md` for the contract.
- First run shows a short installer (`/sui install` any time): a live
  UI-scale slider with a per-resolution *Recommended* button, then
  *Finish & reload* applies everything cleanly.

Disable other full UI replacements when running this suite.
