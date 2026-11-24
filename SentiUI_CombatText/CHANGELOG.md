# Changelog

## 0.1.0 - 2026-11-25

- First release: a scrolling incoming-combat feed driven by COMBAT_TEXT_UPDATE. Damage taken, heals, misses and resource gains stack from the bottom, hold, then fly off to a screen edge (right/left/fade) with crit emphasis. Movable via the mover system; every event family toggles separately. Outgoing damage has no unprotected source on this client, so the feed covers incoming events only.
