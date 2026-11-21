# SentiUI Unit Frames
## 0.2.17

- Dispatcher rollback: PLAYER_TARGET_CHANGED/PLAYER_FOCUS_CHANGED/RAID_TARGET_UPDATE events are back; the poll is the plain targettarget poll again.



## 0.2.16

- ESC fix: target/focus/raid-mark events replaced by GUID + mark-signature polling in the existing 0.5s poll - same refreshes, no forbidden calls.

## 0.2.15

- Group members no longer show as Offline while they are online:
  `UnitIsConnected` can return a secret boolean on this client, which
  read as nil and flipped every check to "offline". Only a plainly-false
  result now marks a unit offline.

## 0.2.14

- Cast bar fill is now driven per frame off the engine duration object
  (`UnitCastingDuration`) instead of relying on `SetTimerDuration`
  alone - the raw (possibly secret) getter values go straight into the
  status bar, so the fill animates even where the engine call accepts
  the duration but never repaints.

## 0.2.13

- No countdown numbers on buff/debuff icons - the sweep still runs, just without the digit clutter.

## 0.2.12

- Buff/debuff icons breathe: size 18px with a minimum 6px gap instead of cramped 16px/4px, so the rows read as icons instead of a squashed strip.

## 0.2.11

- Cast bars rebuilt the client-proven way: the bar lives on UIParent now (children of the secure unit buttons inherit combat lockdown, so their Show/SetPoint could be refused exactly when you cast). Fill runs on the engine duration when offered, else per-frame timestamp math, else a static full bar with the spell name - something always shows while you cast.

## 0.2.10

- Cast bars are back: the aura container's creation could fail in combat or restricted zones and its throw aborted Refresh before CastBar.Update ran. Container creation is now fully pcall-wrapped, lazily retried on the next update, and the cast bar clears the debuff icon row by its row height instead of anchoring to the container.

## 0.2.9

- Level text uses real difficulty colors via `S.LevelColor` instead of
  staying light gray.

## 0.2.8

- Buff/debuff icon rows now run on engine AuraContainers (the buff
  bars' path): the engine assigns and renders auras itself, so icons
  show even while aura data is secret - curses/dots finally appear on
  the target in combat. Icons carry the cooldown widget's own
  countdown, stack counts and dispel-colored edges on harmful rows;
  the group dispel border keeps its readable scan.

## 0.2.7

- Cast bars now show and animate on unit frames: driven by
  SetTimerDuration + UnitCastingDuration/UnitChannelDuration (engine
  animated, secret-safe) instead of GetTime() math on timestamps that
  can be secret; the spell name/icon pass through pcall so a secret
  name no longer hides the bar, and the remaining-time text uses the
  duration object's GetRemainingDuration.

## 0.2.6

- Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.

## 0.2.5

- Boss and arena frame settings are live: width, height and the power
  bar were defined in the defaults but ignored - the frames always
  rendered at 160x26 with a power bar. All three are now configurable
  per stack on the Extras page.

## 0.2.4

- Range fade finally works: `UnitInRange`'s secret boolean read as
  "always in range" (`Plain()` nil is not false) — secret results now
  go to `SetAlphaFromBoolean` so the engine evaluates them, the same
  path SentiHeal uses. Disabled range-fade toggles are honoured too
  (they always faded before).
- Incoming-heal/absorb bands anchor at the health fill's right edge
  (fill-texture anchor) instead of stretching from the bar's left
  edge, and re-read on `UNIT_HEALTH`/`UNIT_MAXHEALTH` — the
  `UNIT_HEAL_PREDICTION` event may never fire on this client.

## 0.1.10

- Aura icon spacing raised from 2px to 4px so icons no longer touch.

## 0.1.9

- Aura rows no longer sit inside the bars: buffs 3px above, debuffs 3px
  below the frame, duration text moved inside each icon's top edge.
- Castbar anchors below the debuff row while it is visible so nothing
  overlaps.
- Role icons shifted left along the top edge so they can't collide with
  raid-target icons on the corner.

## 0.1.8

- Role icons moved onto the top-right corner edge, clear of name and
  health texts.
- New Health text option: percent, raw values, or both (default: both) —
  values are abbreviated (4.8m / 12.3k).
- Smooth bar animation: health/power fills ease out via the client's
  status-bar interpolation (toggleable), plus the gloss overlays from
  0.1.7 keep the SentiUI look.

## 0.1.7

- Role marks now use the real Blizzard role icons (tank/healer/damager
  portrait-role texture) instead of colored letters.
- Style pass: health/power bars get a top-fade gloss like the other
  SentiUI bars, texts anchor to their bars and clear the class-colored
  edge, role icons sit inside the frame corners.

## 0.1.6

- Fix: party frames showed as an empty box — UF.Configure was never
  called for party buttons, so bars and texts had no anchors. The layout
  pass now configures every button.

## 0.1.5

- Fix: hidden class colors — when the client keeps a unit's class secret,
  C_ClassColor.GetClassColor accepts the secret token from UnitClassBase
  and returns secret rgb values that feed straight into the bar/text
  color setters (the DaylightUI approach, reimplemented). Name coloring
  moved to SetTextColor so secrets never hit string formatting.

## 0.1.4

- Fix: class colors still fell back to reaction yellow — UnitIsPlayer is
  unreliable on this client, so player detection is now GUID-based
  ("Player-" prefix) and the class token falls back to
  GetPlayerInfoByGUID when UnitClass returns a secret.

## 0.1.3

- Fix: class colors on health bars — the class-color fallback table was
  read with `.r/.g/.b` fields while storing array values, and a
  secret/failed UnitIsPlayer silently fell through to reaction green.
  RAID_CLASS_COLORS indexing is now guarded and the player unit is
  recognized directly.

## 0.1.2

- Fix: health/power values arrive as secret values on this client —
  bars now feed them to the StatusBar widgets directly (percent text
  via UnitHealthPercent/UnitPowerPercent) instead of clamping to 0.
- Fix: power bar now sits inside the frame instead of hanging below it.
- Fix: aura duration text normalized (foreign time scales no longer
  print raw mega numbers like "4843600"), stack counts via
  GetAuraApplicationDisplayCount.

## 0.1.1

- Fix: `UNIT_HEALTH_FREQUENT`/`UNIT_POWER_FREQUENT` do not exist on this
  client — event registration now skips unknown events instead of
  throwing, which also unblocked frame setup for every unit.

## 0.1.0

- Initial release: player, target, target-of-target, pet and focus
  frames on secure unit buttons, a five-button party block
  (joins/leaves mid-combat handled by unit watch) and a secure raid
  grid header.
- Health bars in class/reaction/static colors with percent + absolute
  text, power bars in power-type colors, names with level, raid icons,
  leader/role marks, threat border, dead/ghost/offline/AFK status text.
- Castbars for player and target with icon, name, time and
  uninterruptible shield. Auras above (buffs) and below (debuffs) the
  frame with stack counts, timers and dispel-type borders;
  dispellable debuffs tint the frame border on party/raid.
- Out-of-range fading for party/raid, ready-check marks,
  hide-Blizzard toggles, SentiUI movers for every block, and a full
  settings section.

## 0.2.0

- New: heal prediction overlay (incoming heals) and absorb shield overlay on every frame's health bar.
- New: class power pips above the player frame (combo points, holy power, chi, soul shards, arcane charges, essence).
- New: combat text on the player frame - damage, healing, misses and absorbs rise out of the bar.
- New: boss1-5 and arena1-5 frame stacks (secure unit buttons, own movers, shown only while the units exist); Blizzard boss/arena frames are parked with the other chrome.
- New: focus castbar, threat percent on the target frame, phase/resurrect/summon icons, offline dimming, party pet bars.
- New options page "Extras" plus per-frame toggles (party pets, party/raid auras, target threat, focus castbar).

## 0.2.1

- Fixed: the absorb overlay compared a secret number and errored on every frame refresh; secret absorb amounts are fed to the widget raw now.

## 0.2.2

- Fixed: combat text never fired - the event bus passes the event name as first argument and the wrapper shifted every argument.
- Fixed: secret-safe extras - heal prediction, threat percent and phase/resurrect/summon icons now feed secret values to widgets raw instead of comparing them; before, everything stayed silently hidden.

## 0.2.3

- Fixed: combat text errored on its first number - FontStrings cannot take OnUpdate scripts; the pool is now animated from its holder frame.
