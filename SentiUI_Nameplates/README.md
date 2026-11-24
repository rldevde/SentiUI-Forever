# SentiUI Nameplates

Custom nameplates for the SentiUI suite - flat Sentinel-styled plates
that replace the game's nameplate art: health bar, name, level, cast
bar, debuffs, threat colors, target highlight.

## How it works

The game's nameplate driver still positions every plate on screen. For
each unit the driver shows (`NAME_PLATE_UNIT_ADDED`), a custom plate
frame is anchored to the driver frame while the game's own unit frame
is parked under a hidden parent (its events quieted, its widget
container and soft-target icon moved onto the driver so quest progress
and soft target still work). `UpdateHitTestArea` keeps unit clicks
alive - our plate never takes the mouse.

- **Health bar** - flat fill, dark inset, 1px border; fills ease to
  the new value instead of snapping (`smoothBars` setting). Fill color:
  tap-denied grey (tagged by another group) > threat (attackable, in
  combat) > class color (players) > reaction. Tapped mobs also dim
  their name text so no-credit targets are obvious at a glance.
  Optional % text.
- **Threat colors** - `UnitThreatSituation` + a 0.25s ticker (the
  events are unreliable on this client). Tank: holding = teal,
  slipping = orange, lost = red. DPS: on you = red, warning = orange,
  safe = teal. Role is auto-detected (assigned role, then spec) and
  can be forced in the settings.
- **Class colors** - resolved via the numeric classID path
  (`C_CreatureInfo.GetClassInfo`) with `RAID_CLASS_COLORS` and a plain
  fallback table - the class file token reads secret on this client.
- **Cast bar** - spell icon + name; a gold fill driven by
  `UnitCastingInfo`/`UnitChannelInfo`, darker grey for
  non-interruptible casts. Secret timestamps degrade to a static fill
  instead of breaking.
- **Debuffs** - up to `maxDebuffs` harmful auras (`C_UnitAuras`),
  optionally only your own.
- **Friendly units** - plate can collapse to a class-colored name only.
- **Extras** - gold accent border on your target, raid target icon,
  elite/rare/boss marker, enemy/friendly CVar toggles.

## Settings

SentiUI > Nameplates. Every feature is individually toggleable:
enable, sizes, scale, friendly handling, class colors, level, health
text, threat colors + tank mode, cast bar + icon, debuffs (+count,
mine-only), target highlight, raid icon, elite marker.

`/reload` after enabling. Disabling restores the game's unit frames
best-effort; a `/reload` is the clean path back.

## Notes for this client (WoW Forever / Camelot)

- Secret values are never compared or formatted - raw values go
  straight into frame setters inside `pcall`.
- The game's unit frames are never deleted, only parked; widgets that
  the game keeps drawing (quest progress) stay visible.
- Disable `DaylightUI_Nameplates`, `Plater`, `Platynator` and similar
  when using this module - two nameplate replacements always fight.
