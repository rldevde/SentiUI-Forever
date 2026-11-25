# SentiUI Outfitter

Outfit / gear-set manager module for **SentiUI** (WoW Forever client).
Outfits are stored natively via `C_EquipmentSet`, so they sync with
Blizzard's Equipment Manager and appear in the character sheet.

Registers with the SentiUI core (`SentiUI:RegisterModule`) — settings
live in `SentiUIDB.modules.Outfitter`, the options page sits under
`/sui`, and the changelog shows on the SentiUI changelog page.
Standalone SentiOutfitter saved variables are imported once on first
load; nothing is lost.

## Usage

- `/so` or `/sentioutfitter` — open the outfit window
- `/so <name>` — wear an outfit by name
- `/so bar` — toggle the outfit bar
- `/so options` — open the settings panel
- `/sui` → Outfitter — module settings page
- The small **S** button on the bar opens the window; drag the bar to
  move it (lock it in settings).

## Features

- Save current gear as an outfit, with optional slot selection
  (e.g. only weapons + trinkets).
- Outfit bar with one button per outfit — left click wears it.
  Buttons are secure (`type="equipmentset"`), so weapon swaps work
  natively, including in combat.
- Sets window that docks to the character sheet (toggleable).
- Item tooltips list the outfits that contain the item.
- Rename / delete / custom icon per outfit.
- Sell protection — outfit items sold by accident are bought back
  instantly.
- Bag markers — outfit items get a small badge on their bag slot.
- Minimap button (left-click opens the window, right-click settings,
  draggable; collected by SentiUI_Minimap's button bar).

## Options (`/sui` → Outfitter)

Bar: enable, scale, combat alpha, set names, vertical layout, lock.
Behavior: tooltip mode (always / out of combat / never), sell
protection, bag markers, open-with-character-panel, minimap button.

## Notes

- Outfits are stored per character by the game itself
  (`C_EquipmentSet`), shared with the default Equipment Manager.
- Armor cannot be swapped in combat — that is a Blizzard restriction.
  Weapon swaps through the bar work in combat.
- Requires SentiUI on the Forever client (`Interface: 16001`).
