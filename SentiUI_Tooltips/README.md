# SentiUI Tooltips

Sentinel-styled tooltips for SentiUI: the game's tooltips keep running
(everything is post-hooks, nothing secure is replaced), they just get the
Sentinel look and useful extras.

## Features

- **Skin** - flat dark backdrop with a 1px border and the Sentinel font on
  every tooltip the game (and most addons) create: `GameTooltip`, item-ref
  tips, shopping tips, embedded item tooltip, buff tooltip. A reflow pass
  measures the real width of every line after styling and widens the frame
  when our font or rewritten lines outgrow the client's computed size, so
  text never draws over the border.
- **Units** - player name in class color, NPC name in reaction color, border
  and top accent edge tinted by class/reaction, faction + AFK/DND + realm
  tags on the name line, level number in difficulty color, class name in
  class color, guild line with recolored name (faction-colored by default -
  Horde red / Alliance blue, configurable fallback, own guild in accent
  gold), a colored rank tag and an optional "My Guild" text tag (off by
  default - the accent color alone marks it), elite/rare/boss
  badge, group role, specialization (live or via inspect),
  target-of-target in that unit's color, and a
  slim restyled health bar with optional `cur / max · %` text.
- **Items** - border and top accent edge in item quality color (uncommon
  and up), item level line (only when the game didn't already write one),
  optional max-stack line and item/spell IDs.
- **Line discipline** - everything the module adds is idempotent: label
  lines update in place, one-shot lines are deduplicated, so the repeated
  tooltip post-calls never stack the same line twice.
- **Placement** - fixed movable anchor (SentiUI mover) or at-cursor with
  X/Y offsets, scale slider, optional hide-in-combat (hold Shift to peek).

## Settings

SentiUI > **Tooltips**: anchor mode (fixed/cursor), cursor offsets, scale,
hide in combat, class colors, class/reaction border, health bar + height,
guild rank + guild name/rank colors, target of target, quality border,
item level, IDs, stack size -
every extra is individually switchable.
