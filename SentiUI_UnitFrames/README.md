# SentiUI Unit Frames

Unit frames for SentiUI: player, target, target-of-target, pet, focus,
party and raid in the SentiUI look (dark panels, accent edge,
class-colored health). Standalone module - requires the SentiUI core.

## Frames

- **Player / Target / ToT / Pet / Focus** - secure unit buttons
  (`SecureUnitButtonTemplate`, left-click targets, right-click menu)
  with health + power bars, name/level, status text, threat border,
  raid icons and optional castbars (icon, name, time, uninterruptible
  shield) and auras (buffs above, debuffs below, stack counts, timers,
  dispel-type borders).
- **Party** - a fixed five-button block (`player` + `party1-4`) driven
  by `RegisterUnitWatch`, so joins and leaves mid-combat update
  visibility without touching protected attributes. Role marks,
  leader icons, ready-check marks, range fading, growth direction.
- **Raid** - `SecureGroupHeaderTemplate` grid (up to 8x5) on an
  unprotected holder; the visibility state driver lives on the holder
  so combat never triggers the protected header layout. Group by
  group/class/role, range fading, dispel-type border, ready check.
- Blizzard's own unit frames are parked on a hidden container
  (toggleable per group).

## Usage

- `/sui` opens the SentiUI settings - the module has four pages
  (Unit Frames, Player & Target, Party, Raid).
- `/sui unlock` enables the movers to drag every block.
- Click a frame to target the unit; right-click opens the unit menu.
