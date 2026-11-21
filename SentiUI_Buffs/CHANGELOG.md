# Changelog

## 0.6.9

- Aura timers sit under the icons now: the cooldown keeps its swipe but
  its on-icon countdown numbers are hidden; the duration goes to a small
  outlined fontstring below each icon via SetDurationText, in a compact
  45s/10m/2h/3d format - the jumbled "10m1h10m" look is gone. Rows get a
  wider gap so the text has room.

## 0.6.8

- Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.

## 0.6.7

- The "Sentinel border" and "Dispel-colored debuffs" settings actually
  work now: both were in the options but never read - icons always
  drew the ring and the engine always tinted debuffs. Border off now
  hides the ring, dispel colors off keeps every border Sentinel gold.

## 0.6.6

- Fixed a Lua error on login: the anchor watch was assigned as an
  `OnUpdate` script ON the AuraContainer, but that handler is forbidden
  on this frame type ("cannot replace a forbidden script handler") —
  the watch now runs on a helper frame. This also restores the re-pin
  fix from 0.6.5, which silently never ran because of it.

## 0.6.5

- Fixed bars resetting to their default spot after reload/login: the
  client re-anchors the container on its own layout passes — the
  container now re-pins to the mover holder automatically whenever its
  anchor no longer points at the holder (checked every 0.5 s, skipped
  in combat).

## 0.6.0

- Reworked onto the client's own `AuraContainer` — the engine path ElvUI
  uses on modern clients (`SecureAuraHeaderTemplate` does not exist
  here). The engine assigns auras to its own buttons, so buffs and
  debuffs appear and disappear correctly even in combat and secret aura
  data never reaches Lua.
- Each button is wired through `initializeFrame` with our widgets: icon
  texture, dispel-tinted border ring (the engine colors debuffs by type
  via `AddDispelTypeTexture`), cooldown swipe with the engine's own
  `19m` countdown text (`SetDurationCooldown`), stack count
  (`SetApplicationCount`) and secure right-click buff cancel
  (`SetCancelAuraButtons`).
- Weapon enchants show ahead of the buffs via `AddItemEnchantment`.

## 0.5.0

- Reworked onto `SecureAuraHeaderTemplate` — the same engine path ElvUI
  uses: the client assigns auras to buttons inside the restricted
  environment, so buffs and debuffs appear and disappear correctly even
  in combat.
- Durations render through `C_UnitAuras.GetAuraDuration` as a duration
  object on the cooldown widget — the engine draws the `19m` countdown
  itself, secret-proof. Stack counts and dispel colors use the dedicated
  client APIs (`GetAuraApplicationDisplayCount`,
  `GetAuraDispelTypeColor`).
- Right-click cancels a buff again (secure `cancelaura` button template);
  weapon enchants show on the buff bar via the header's tempEnchant
  slots.

## 0.1.0

- New module: buff and debuff bars built on the client's native
  AuraContainer - the engine owns the aura buttons, so secret aura data
  never crosses addon code.
- Two movable bars (SentiUI movers `/sui unlock`), icon size, spacing,
  icons-per-row wrap, grow direction and scale options.
- Temporary weapon enchants shown ahead of the buffs; right-click cancels
  a buff; the stock Blizzard buff/debuff frames are parked.
- The debuff bar can narrow to dispellable-only.

## 0.1.1

- Fixed invisible bars: the aura container must hang off UIParent (the
  container's parent becomes protected for button spawns - a 1x1 holder
  could starve it). The mover holder is now a real one-row handle.

## 0.1.2

- Fixed bars never spawning buttons: the aura container starts disabled
  on this client - SetEnabled(true) plus Show() is required. Default
  position moved up beside the minimap.

## 0.6.7

- Added AddAuraSlot fallback when AddAuraGroup is unavailable, plus a
  one-shot status print after load showing whether containers/groups
  registered.

## 0.1.4
- Bars were registered but hidden behind the minimap's LOW-strata panel -
  containers and holders now live on MEDIUM strata, container gets a real size.

## 0.1.5
- Buttons stayed blank: the aura template ships its Icon/Count/Duration
  regions unwired - initializeFrame now hands each region back to the button.

## 0.1.6
- No icons spawned: an AuraContainer built inside the module's xpcall/event
  context hands its button provider the caller's accessRestrictions, so the
  engine could not wire the AuraButtons' onshow. Container setup now runs in
  a clean C_Timer.After context (same fix the working dispel container uses).

## 0.2.0
- Reworked around the client's own buff/debuff/weapon-enchant frames: the
  native frames keep doing all aura work (icons, durations, stacks, cancel,
  dispel borders) and are re-anchored onto SentiUI movers.
- Every aura button gets the Sentinel look: square icons and a 1px border.
- Settings slimmed to what the native frames allow: enable, scale, square
  icons, Sentinel border.

## 0.2.1
- Fixed borders drawn on empty pool buttons and the collapse arrow: the
  border now only shows while the button actually carries an aura icon.

## 0.2.2
- Icons were hidden behind the border frame: the template's dark fill
  covered the button - the backdrop now draws its edge only, transparent fill.

## 0.2.3
- Aura timers restyled: duration centered on the icon in the SentiUI font
  with thick outline + hard shadow; stack counts to the top-right corner.

## 0.2.4
- Ghost borders gone: buttons come from the provider's active/auraFrames
  list, which only holds live auras - the engine's empty pool slots (and
  the collapse arrow) are no longer styled.

## 0.2.5
- Timer text no longer spills over the icon: smaller thick-outlined font,
  centered on the icon.
- Ghost borders on empty slots: the border also follows the icon's shown
  state and a readable aura-slot id when the client exposes one.

## 0.2.6
- Empty-slot borders gone: buttons are counted against the player's real
  aura count (C_UnitAuras) - pool slots past the last actual aura never
  get a border.
- Duration text compacted ("60 min" -> "60m") and sized down, so timers
  stay inside the icon.

## 0.2.7
- Added "/suibuffs debug": dumps the native frames' children with
  shown/alpha/icon/texture state.

## 0.2.8
- "/suibuffs" now works: registered at file scope, dumps on any call - no
  longer silently does nothing when invoked without "debug".

## 0.2.9
- Timer text actually compacts: all FontString regions on the buttons are
  found (field names differ between clients) and SetText is hooked, so
  every engine refresh is shortened to "51m"/"2h" immediately.

## 0.3.0
- Empty boxes were the engine's own unused pool slots: buttons with a
  hidden/textureless icon (or past the real aura count) are now hidden
  outright and re-shown the moment they carry an aura.

## 0.3.1
- Fixed resurrected pool slots: only buttons this module hid are ever
  shown again; the pool's red "?" placeholder icons count as empty now.
- Aura counting hardened against stub tables.

## 0.3.2
- Ghost borders, final logic: a border now needs positive proof of an
  aura (readable slot id or real icon texture) - unreadable pool buttons
  hide instead of drawing ghosts.
- "/suibuffs" also reports each button's FontString count and whether the
  text is readable or secret.

## 0.3.3
- Complete pass over the styling core: empty pool buttons are hidden with
  the secure state driver (plain Hide loses on this client) and woken when
  their icon gains a real texture.
- Timer texts found via named globals (BuffButton1Duration...) instead of
  field access, so "51m" compaction and icon-centered font reach the
  strings this client actually uses.

## 0.3.4
- Fixed UNIT_AURA error: the engine's duration is a secret string - all
  text handling now sits inside pcall.
- Own timer string per icon: remaining time computed from expirationTime
  and rendered as "19m"/"2h"/"45s", engine text faded out. Falls back to
  the engine text when the aura is unreadable.

## 0.4.0
- Reworked into fully custom aura icons: auras enumerated via C_UnitAuras,
  every icon is a SentiUI widget (icon, border, compact "19m"/"2h" timer,
  stacks, cooldown swipe, dispel-colored debuff edges).
- Layout options are back: icon size, spacing, icons per row, grow
  direction, scale. Tooltips on hover; Blizzard frames parked.

## 0.4.1
- Bar defaults dock next to the real minimap (computed from its position,
  icons grow left) instead of a fixed center offset - saved positions win,
  so reset movers once for the new spots.

## 0.4.2
- Bars no longer empty in combat: when aura data turns secret the API
  either throws (bar freezes, refreshes after the fight) or hands back
  secret tables (slots keep their icons) - the pool is never wiped.
