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
  dispel-type borders). Each frame can show a **portrait tile** on its
  left edge: a class icon for players (3D fallback for creatures) or the
  engine's 3D portrait for every unit.
- **Party** - a fixed five-button block (`player` + `party1-4`) driven
  by an engine-side `[@unit,exists]` visibility state driver, so joins
  and leaves mid-combat update visibility without touching protected
  attributes (RegisterUnitWatch only ran after combat on this client).
  Role marks,
  leader icons, ready-check marks, range fading, growth direction.
- **Raid** - `SecureGroupHeaderTemplate` grid (up to 8x5) on an
  unprotected holder; the visibility state driver lives on the holder
  so combat never triggers the protected header layout. Group by
  group/class/role, range fading, dispel-type border, ready check.
- Blizzard's own unit frames are parked on a hidden container
  (toggleable per group).
- **External defensive indicators** - small corner icons on party/raid
  cells fed by an engine `AuraContainer` filtered to
  `HELPFUL|EXTERNAL_DEFENSIVE` (secret-safe; toggleable per group).
- **Raid tools** - a slim tab docked to the top screen edge (own mover)
  that unfolds a tray with target markers, world markers, ready check
  and a 10s pull timer, shown only while grouped; click the tab to fold
  the tray away (works in combat, state persists). Markers run through
  the client's `/tm` and `/wm` slash commands in the secure macro path.
- **Alt power bar** - replaces the parked `PlayerPowerBarAlt`: watches
  the encounter power index via `UnitPower`/`UnitPowerMax`
  (secret-safe), shows name and percent while active. Own mover.
- **Class power** - pips above the player frame: combo points, holy
  power, chi, soul shards, arcane charges, essence. Death knights get
  six rune pips whose fill climbs per-rune while they recharge
  instead.
- **Cooldown tracker** - small icons under each party cell when a
  member casts an interrupt or signature defensive (kick, counterspell,
  ice block, divine shield, ...), driven by `UNIT_SPELLCAST_SUCCEEDED`
  per cell so any group member shows, no addon channel needed. On by
  default for party, opt-in on raid cells.
- **Screen effects** - a red vignette pulses at the screen edges while
  your health drops below the chosen threshold (Low health pulse), a
  gold flash marks level ups (Level-up flash), and optional
  screenshots fire on level ups and earned achievements.

## Usage

- `/sui` opens the SentiUI settings - the module has four pages
  (Unit Frames, Player & Target, Party, Raid).
- `/sui unlock` enables the movers to drag every block.
- Click a frame to target the unit; right-click opens the unit menu.
