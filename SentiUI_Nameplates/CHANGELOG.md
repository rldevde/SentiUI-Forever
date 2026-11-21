# SentiUI Nameplates
## 0.1.15

- Dispatcher rollback: PLAYER_TARGET_CHANGED and RAID_TARGET_UPDATE are registered again and the raid icon moved back out of the volatile color pass.



## 0.1.14

- ESC fix: dropped PLAYER_TARGET_CHANGED/RAID_TARGET_UPDATE (they fire inside the protected input dispatch); the ticker now repaints the raid icon too, so target highlight and marks stay live.

## 0.1.13

- Enemy cast bars on plates now actually animate: the fill is driven
  per frame off the engine duration object (`UnitCastingDuration`),
  reading its getters raw - which keeps working when the cast
  timestamps are secret values, and even where `SetTimerDuration`
  accepts the duration but never repaints the bar. `/snptest` now
  reports the duration object and cast-info values for debugging.

## 0.1.12

- Tap detection: mobs tagged by a player outside your group now paint
  grey - health fill and name both dim like the game's own plates, so
  you see at a glance the kill gives no credit. Grey wins over threat,
  class and reaction colors; a **Grey tapped targets** toggle controls
  it.

## 0.1.11

- No countdown numbers on plate debuff icons - the sweep still runs.

## 0.1.10

- Debuff icons on plates get more room: 16px with a minimum 4px gap instead of 15px/2px, so the row no longer looks squashed.

## 0.1.9

- Cast bars rebuilt the client-proven way: engine duration fill when offered, else per-frame timestamp math, else a static full bar with the spell name - something always shows while the unit casts.

## 0.1.8

- Cast bars are back: the aura container's creation could fail in combat or restricted zones and its throw aborted the plate update before the cast refresh ran. Container creation and SetUnit are now fully pcall-wrapped and retried on the next update; the plate update itself can no longer take the cast bar down.

## 0.1.7

- Debuffs show who applied them: own = gold edge, group = blue edge,
  outsiders = desaturated dark edge.
- Level text uses real difficulty colors instead of staying gray at
  equal level.

## 0.1.6

- Debuffs on enemy nameplates now actually show: the manual
  C_UnitAuras scan is replaced by an engine AuraContainer (same path
  the buff bars use) that renders secret aura data itself - your
  curses/dots appear in combat with icon, cooldown sweep, stack count
  and dispel-colored edge. "Only my debuffs" filters the container to
  HARMFUL|PLAYER.

## 0.1.5

- Fixed the "attempt to compare secret number" error spam: threat
  percentages (and potentially levels/health) arrive as secret numbers
  that type() reports as "number" and issecretvalue does not flag -
  only the comparison throws. Threat.State now pcall's its whole
  decision, and the level text plus health-percent fallback got the
  same treatment.
- Style pass: health and cast bars now carry the SentiUI bar look -
  darker unfilled background plus the vertical white gloss fade the
  unit frames use, texts parented onto the bars above the gloss layer.

## 0.1.4

- Cast bar hardening: cast-info reads are pcall-guarded so a throwing
  secret return can no longer abort Refresh and hide the bar; the spell
  name goes straight into SetText instead of an 'or' fallback evaluated
  on a possibly-secret value.

## 0.1.3

- Long unit names are truncated with ... instead of running through
  the level text (font strings never clip at their anchors).
- New /snptest debug command dumps the live state of the target's
  plate so broken layers report themselves.
- Secret-value fix in the health percent path (nil-compare on a
  secret result could kill the refresh pass).


## 0.1.2

- Cast bar animates smoothly again: driven by SetTimerDuration fed by
  UnitCastingDuration/UnitChannelDuration (engine-animated, secret-safe)
  instead of GetTime() math that froze at the static 50% fallback.
- The plate name is clipped against the level field - no more overlap.
- Health values and percent refresh on the 0.25s plate ticker too.
- Manager.forbidden() pcalls the IsForbidden comparison; a secret
  boolean there could previously kill the attach entirely.
- Threat colors no longer skipped when UnitCanAttack is secret.


## 0.1.1

- Health and cast bars now use the proven unit-frame pattern: every
  StatusBar setter is pcall'd individually so one rejected secret value
  can no longer freeze the bar; cast progress runs on normalized
  0..1 fractions in seconds; the health percent text uses
  UnitHealthPercent (accepts secret values) before falling back to
  plain math.


## 0.1.0

- First release: fully custom nameplates in the Sentinel style - flat
  health bars with a 1px border, name and level above, cast bar below.
- Threat colors on the health fill: holding it (tank) / safe (dps)
  teal, slipping orange, lost or on you red - tank mode auto-detects
  role/spec, overridable.
- Class-colored bars for players, reaction colors for NPCs, level,
  elite/rare/boss marker, raid target icon, gold accent border on your
  current target.
- Cast bar with spell icon and spell name; non-interruptible casts
  show darker so you don't waste the kick.
- Debuff row above the name (optionally only your own debuffs),
  friendly nameplates can collapse to name-only.
- Enemy/friendly plate CVar toggles, width/height/scale sliders -
  everything under SentiUI > Nameplates.
