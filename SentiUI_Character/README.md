# SentiUI_Character

The Sentinel character window for SentiUI — gear, stats and the 3D model in
one dark, gold-accented panel. It replaces the Blizzard character sheet when
you press `C` or use the micro menu; the Blizzard frame stays hidden while
ours is open and returns when the module is disabled (reload required).

## Features

- **Gear columns** — classic layout: head…wrist on the left, hands…trinkets
  on the right, main hand / off hand / ranged / ammo along the bottom.
- **Per-slot info** — item icon in a flat box whose border shows the item quality color, item name in
  quality color, item level under the name or as a corner badge on the icon,
  and a durability percentage.
- **Repair warning** — slots at or below the configured durability
  threshold get a red border.
- **3D model** — your character in the middle; drag with the left mouse
  button to rotate.
- **Stat groups** — Attributes, Melee, Defense and Resistances as
  collapsible groups with optional zebra rows.
- **Footer** — average item level and total durability (green → red).
- **Native tooltips** — hovering a slot shows the game's own item tooltip.

## Tabs

The window takes over every character-sheet tab whose API exists on the
client: **Character** (gear + stats + model), **Pet**, **Reputation**,
**Skills**, **PvP**, **Currency** and **Statistics**. Tabs without a usable
API stay with the Blizzard window, as do `ToggleCharacter` calls for frames
the module doesn't cover.

## Slot interactions

| Input | Action |
| --- | --- |
| Left click | Pick the item up (native behavior) |
| Shift + click | Insert the item link into the chat edit box |
| Ctrl + click | Open the item in the dressing room |
| Right click / Alt + click | Menu: pick up / link / dressing room |

A **Sets** picker in the footer lists equipment-manager sets and equips the
chosen one (deferred out of combat). Enchanted items show a green marker
and filled gem sockets show blue diamonds in the item info line.

## Options

SentiUI › Character:

| Option | Effect |
| --- | --- |
| Enable character module | Master switch; off returns the Blizzard window after a reload. |
| Character model | Show/hide the 3D model. |
| Item names | Item name next to each gear icon. |
| Item level | Item-level text under the name. |
| Item level in icon | Item level as a corner badge instead of the text line. |
| Repair warning at | Durability fraction that triggers the red ring. |
| Zebra rows | Alternate stat rows on a faint stripe. |
| Stat groups open | Start with all groups or only the main ones expanded. |
| Colored footer | Durability colors green → red in the footer. |

## Notes

- ESC closes the window (registered in `UISpecialFrames`).
- The module hooks `ToggleCharacter`; tabs it doesn't cover fall through
  to the Blizzard window untouched.
- Secret values are guarded; combat-sensitive frame work is deferred
  through `S.RunOutOfCombat`.
