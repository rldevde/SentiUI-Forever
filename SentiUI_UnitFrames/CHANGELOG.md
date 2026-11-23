# SentiUI Unit Frames

## 0.2.37 - 2026-11-23

- Members no longer stick on "offline" while online: `UnitIsConnected` can return plainly-false for visible units on this client, so the check now double-checks via `UnitIsVisible` (a unit we can see is online by definition), holds the flag for 3s to survive zoning flicker, and the name text is restored when the member reads connected again.

## 0.2.36 - 2026-11-23

- Castbar visual pass (player/target — also covers interact casts like opening chests): raised panel with the same 0.70-alpha gold border as the frames above, darker unfilled area + top-fade glass sheen, spell icon now sits in its own inset tile, and the uninterruptible shield moved onto the icon corner (Blizzard-style badge).
- Empower cast events (UNIT_SPELLCAST_EMPOWER_START/UPDATE/STOP) added to the frame event map so empower spells drive the castbar too.

## 0.2.35 - 2026-11-23

- Layout fix: health/power bars were 1–3 px inside the PillEdge backdrop's 3 px insets, causing bars to bleed into the gold border region and look misaligned. All four sides now inset by 4 px so bars sit cleanly inside the fill area. Power bar bottom raised from y=1 to y=4; health top from y=-1 to y=-4; health bottom adjusted accordingly.
- Removed AccentLine and BottomLine textures from player/target frames — the interior gold strips conflicted visually with the outer backdrop border and created the "icky gold thing inside" effect. The backdrop border itself now carries the visual weight.
- Player/target backdrop border alpha raised from 0.45 to 0.70 so the gold frame is clearly visible without interior decorations.
- healthTextMode migration: BOTH (the old system default) is automatically updated to VALUE on first load, so existing users get absolute HP numbers without needing to reset settings.

## 0.2.34 - 2026-11-23

- Visual overhaul — player/unit/party/raid frames:
  - HP text: absolute value instead of percentage (healthTextMode "VALUE").
  - Power/mana bar height 8 px for player and target (was 6) for better number readability.
  - Bar backgrounds opaque from 0.55 → 0.65 alpha for stronger dark base.
  - Class colour dimmed 12 % on health bars — eliminates the washed-out look on bright classes (e.g. Paladin pink).
  - Health-bar glass sheen gradient brightened (0.14 → 0.20 top alpha).
  - Power-bar sheen raised to 0.16.
  - `S.CornerCut` applied to health bar (radius 3) and power bar (radius 2) — bars now have programmatic pill-shaped rounded ends that blend into the dark panel.
  - Player/target top gold accent line alpha raised to 0.90.
  - New 1 px bottom closure gold line on player/target frames (35 % alpha).
  - Portrait separator: 1 px dark vertical divider between class icon and bar area.

## 0.2.33 - 2026-11-23

- Aggro/threat/dispel border strips still partially hidden: the EdgeGlow container `g` was at `f:GetFrameLevel() + 6`, below the text-holder frame `th` at `f:GetFrameLevel() + 8`. Because `th` has `SetAllPoints()` and sits higher in the Z-order it was covering the strips. Increased EdgeGlow frame level to `f:GetFrameLevel() + 10` so the border renders above all internal unit-frame layers (portrait +2, bars +1, text-holder +8).

## 0.2.32 - 2026-11-23

- Aggro/threat border incomplete: `ns.EdgeGlow` used `g.strips[p1] = t` (first anchor point as key). Both the top horizontal strip (`"TOPLEFT"→"TOPRIGHT"`) and the left vertical strip (`"TOPLEFT"→"BOTTOMLEFT"`) share `"TOPLEFT"` as `p1`, so the left strip silently overwrote the top one. `SetEdgeColor` iterated only the 3 surviving entries — left/bottom/right got the threat colour while the top strip remained white/invisible. Fixed by using array indices (`#g.strips + 1`) so all four strips are always stored and coloured.

## 0.2.31 - 2026-11-23

- Player and target frames now use the `raised` panel style: Sentinel gold border tint and the lifted `bgRaised` background give them visual prominence over secondary frames (pet, focus, tot, party, raid) which stay on `panel`.
- 2 px gold top accent line added to player and target frames: a horizontal blade just inside the top edge reinforces the "primary character bar" identity, complementing the existing left-edge health-colour strip.

## 0.2.30 - 2026-11-22

- `ns.EdgeGlow` (threat/dispel ring) replaced with a simple square 4-strip border — no arc geometry, no `OnSizeChanged` complexity, immune to the chevron bug on short bars. `CastBar` corner-cut removed to match the flat bar style.

## 0.2.29 - 2026-11-22

- Threat/dispel edge ring on short frames: `ns.EdgeGlow` now clamps the corner inset to half the frame height and (re)builds strips+arcs via `OnSizeChanged` once the frame has a real size — previously radius-7 arcs overlapped on ~12px bars and rendered as pointed pink chevrons at the bar ends while the side strips collapsed.

## 0.2.28 - 2026-11-22

- Generated icons wired in: role icons use the `RoleTank`/`RoleHeal`/`RoleDps` glyph files instead of the Blizzard atlas texcoords, the leader crown uses `LeaderIcon.tga`, resting/combat use `RestingIcon`/`CombatIcon.tga`, and every aura tile gets the thin `IconBorder` ring. Fix: `AbsorbBar.tga` was dark-based and muddied the shield overlay — reverted to the pale band; `IncomingHeal.tga` is already green so it tints white now instead of double-darkening.

## 0.2.27 - 2026-11-22

- Generated media wired in: threat/dispel rings use the `ThreatGlow.tga` edgeFile — one anti-aliased border texture replaces the strip+arc raster, bilinear-smooth at every size. The cast bar spark uses `BarSpark.tga` (soft glow instead of a hard 2px line), the uninterruptible shield uses `CastShield.tga`, and heal-prediction/absorb overlays ride `IncomingHeal`/`AbsorbBar`. Every asset is probed and falls back to the rastered look when missing.

## 0.2.26 - 2026-11-22

- Bar corner caps moved to OVERLAY sublevel 7: the sheen overlay created after the bars drew over the caps and poked a faint white tip into every rounded corner — visible pixel errors on player, target, target-of-target, pet, focus, party and raid bars. The cast bar caps get the same pin.

## 0.2.25 - 2026-11-22

- Edge glow corners: the threat highlight and dispel-type border were four strips ending 7px short of every corner — rasterized quarter arcs (new core `S.EdgeArc`) now close the outline, and `SetEdgeColor` recolors strips and arcs together so threat states and dispel types keep one continuous ring.

## 0.2.24 - 2026-11-22

- Rounded bars: health and power bars now read as rounded rects — anti-aliased caps in the panel color cover the corner notches (new core `S.CornerCut`). Applies to every frame sharing the bar plumbing: player, target, target-of-target, pet, focus, party and raid.
- Cast bar fill ends rounded the same way with inset-colored caps; the alternate power bar picks up the look automatically.

## 0.2.23 - 2026-11-22

- Portrait tile now sits centered in the left edge (2px inset, clear of the corner arcs), and both bars share one flush left edge right of it — the power bar no longer runs underneath. Both bars also end 4px before the right edge: the square power bar otherwise poked past the panel's rounded bottom-right corner and looked longer than the health bar.

## 0.2.22 - 2026-11-22

- Portrait tile for party and raid frames (Unit Frames > Party / Raid): the shared portrait machinery now extends to the group cells — a square tile on the left edge showing the class icon for players or the engine's 3D portrait for everything else (model mode covers all units). Party defaults to the class icon; raid stays off by default (small cells). The health bar shifts right to make room; applies live without a reload.
- Fix: portrait tiles rendered as empty dark squares — the icon was only painted during a full Refresh, but Configure builds the tile lazily after the first Refresh and unit events never call `UpdatePortrait`. The icon is now painted inside Configure and re-painted on `UNIT_PORTRAIT_UPDATE`. Class icon atlas switched to `Interface\WorldStateFrame\Icons-Classes` (the sheet that actually ships on this client).

## 0.2.21 - 2026-11-22

- New raid tools tray (Unit Frames > Raid): a slim tab docked to the top screen edge unfolds a tray with target markers, world markers, ready check and a 10s pull timer — visible only while grouped. Click the tab to fold the tray away (works in combat); the fold state is remembered. Marker buttons run through the client's own /tm and /wm slash commands in the secure macro path.
- Alternate power bar replaces the parked `PlayerPowerBarAlt`: watches the encounter power index via `UnitPower`/`UnitPowerMax` (secret-safe) and shows name + percent while active. Own mover.
- External defensive indicators on party/raid cells: small corner icons fed by an engine AuraContainer filtered to `HELPFUL|EXTERNAL_DEFENSIVE` — secret-safe.

## 0.2.20 - 2026-11-22

- Fixed the dark blob hanging below the unit frame: the aura tile's dark fill was registered with the engine's dispel-type texture system with `showWithoutDispelType = true` — the engine may scale managed dispel textures past the button bounds, so overlapping always-on dark textures rendered as a lumpy dark mass under every debuff row. The tile fill is now an unmanaged texture; the engine-managed dispel overlay only appears with a real dispel type (tinted by type).
- Heal prediction and absorb bars showed far too small: the band anchors at the health fill's right edge so it only spans the missing-health region, but its scale used `UnitHealthMax` — the fill came out `(max-cur)/max` times too small. The scale now uses `UnitHealthMissing` (secret-safe, `UnitHealthMax` fallback).

## 0.2.19 - 2026-11-22

- New portrait option per single frame (Off / Class icon / 3D portrait): a rounded tile inside the left edge, sized to the health bar; the health bar shifts right while power keeps full width. Class icon shows the class emblem for players and falls back to the engine's 3D portrait for creatures; player and target default to it. Applies live without a reload.

## 0.2.18 - 2026-11-22

- Threat highlight redesigned: the square backdrop ring is gone — a new ns.EdgeGlow draws four strips that follow the rounded panel silhouette (inset past the corner arc), red/orange by threat state. The group-frame dispel border uses the same edge glow.
- Ambient bar tints: health and power backdrops pick up a whisper of the bar color instead of flat black (secret-safe).
- Aura icons clip to soft rounded corners via S.IconRound, the dispel background shares the same mask; cast bar icon clipped the same way; cast bar fill rides a warm spark at its leading edge; the health blade is inset past the corner arc.

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
