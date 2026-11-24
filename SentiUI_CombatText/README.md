# SentiUI Combat Text

A scrolling floating-combat-text feed for the SentiUI suite.

## What it does

- Incoming damage, healing, misses (dodge/parry/block/resist) and resource
  gains (energize, leech, absorb) stack from the bottom of a movable feed,
  hold for a moment, then fly off to a screen edge or fade in place.
- Critical hits render bigger and gold.
- Every event family (damage / heals / misses / gains) can be toggled.
- The feed is a `S.Movers` mover - drag it anywhere.

## Why incoming only

The combat log (`COMBAT_LOG_EVENT_UNFILTERED`) is a protected registration
on this client, so outgoing damage has no Lua-visible source. The feed
drives off `COMBAT_TEXT_UPDATE` - the same unprotected event the unit-frame
combat text uses - which reports what lands on the player.

## Options (`/sui` -> Combat Text)

Font size, hold time, exit direction (right/left/fade), crit emphasis,
per-family toggles.
