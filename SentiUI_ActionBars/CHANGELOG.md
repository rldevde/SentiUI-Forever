# SentiUI Action Bars

## 0.3.9

- Fixed the action-button press point covering only the slot's center: ActionBarButtonTemplate ships an inset hit rect (the artwork ring is not clickable), while our slot look fills the whole button - the hit rect is reset to the full frame now.


## 0.3.8

- Interface-dispatch audit: micro-button alert frames are hidden via visibility watchers instead of OnShow hooks (insecure scripts in the alert dispatch taint the client's follow-up). The talent pill forwards a real secure click to the micro button instead of calling ToggleTalentFrame; watcher installation is deduplicated.

## 0.3.7

- Dispatcher rollback: the event-removal/poll rework broke the bars - the full native event set is back (slot/state/autorepeat/combat/mount/cooldown/usable/range/charges/target/shapeshift/page/vehicle), the 0.2s state poll and button signatures are gone.


## 0.3.5

- Cooldown/usable/range/charge events moved into the 0.2s bar state poll as a per-button signature - those events fire inside the protected cast and target-swap dispatches and tainted Blizzard's CooldownFrame_Set on secret times.


## 0.3.4

- ESC fix: page/stance/vehicle/target events replaced by a 0.2s state poll issuing the same queued repaints.

## 0.3.3

- Escape-forbidden-call fix: the EditMode manager's `OnHide` hook ran inside the Escape dispatch when leaving Edit Mode - it watches the hidden transition via `S.WatchHide` now.


## 0.3.2

- Status tracking bars are no longer reparented into the park frame —
  layout passes call their manager methods, which expect the real parent
  (caused `blizzard: TextStatusBar` errors). They now stay put with
  events off and alpha 0.
- Extra-button attach: when another addon's holder frame claims the same
  Blizzard frame, we yield instead of fighting it — two holder hooks
  ping-ponged `ExtraAbilityContainer` into a C stack overflow when both
  UI suites were loaded.

## 0.3.1

- Stopped the `StatusTrackingBarManager`'s events under the park frame —
  its Blizzard `TextStatusBar` updates kept running while hidden and
  errored on the client's secret XP/reputation values (error source
  `blizzard: TextStatusBar`).

## 0.3.0

- Unspent-talent-points hint redone in SentiUI style: the game's
  micro-button alert anchored to the parked micro bar and floated
  mid-screen - all `*MicroButtonAlert` frames are now re-hidden, and a
  small gold-lit pill above the bottom bars shows
  `Unspent talent points: N` instead (count via `UnitCharacterPoints`
  / `C_ClassTalents` where available, otherwise it still follows the
  game's own alert). Click opens the talent frame.

## 0.2.9

- Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.

## 0.2.8

- Every bar now fires through the game's own twin button (type=click on
  ActionButton1-12 / MultiBar*ButtonN): the twin knows its real action
  slot AND handles the Shift pickup modifier natively, so casting and
  pickup behave exactly like the client's own buttons. Bar 1's twins get
  their page pushed by the existing state snippet.
- Click registration is AnyDown+AnyUp again: this client ignores
  useOnKeyDown=false and fires on the down half, so AnyUp alone made all
  bars dead. Drag-out pickup stays gated on Shift / unlocked bars.
- Removed the custom OnMouseDown pickup hack - the twin's own modified
  click logic covers press-to-pickup.

## 0.2.7

- Bars 2-4 now actually cast: instead of type=action + a guessed slot,
  each button clicks through to the game's own twin button
  (type=click + clickbutton on MultiBarBottomLeftButtonN etc.) - the twin
  holds the client's real action mapping, so the spell it shows is the
  spell that fires. The slot attribute still feeds painting and pickup.

## 0.2.6

- Fixed bars 2-4 doing nothing: their buttons pointed at main-bar page
  slots (61-72, 49-60, 25-36) instead of the multi-bar ranges. Buttons
  now read their action slot from the game's own twin button
  (MultiBarBottomLeft = 85-96 etc. on this client's 132-slot map), so the
  mapping is correct whatever the client uses; the old page math stays as
  fallback only.

## 0.2.5

- Fixed dead action bars: `IsModifiedClick("PICKUPACTION")` can return
  truthy on this client without the key being held, so every button press
  picked the spell up instead of casting it. Pickup now requires Shift
  held (the game's default modifier) or unlocked action bars.

## 0.2.4

- Dragging an action off a bar no longer triggers it: pickup now needs the
  pick-up modifier (Shift by default, remappable via the PICKUPACTION
  binding) or unlocked action bars, matching normal WoW behavior.
- Buttons fire on release only (AnyUp) — the AnyDown registration let a
  plain press cast before a drag could start.

## 0.2.3

- The Counts toggle is honored now: the count painter ignored the
  setting and always drew item and charge counts.

## 0.2.2

- Fixed the park pass dying mid-list: `BagsBar` and
  `MicroButtonAndBagsBar` are plain controller tables on this client,
  not frames - a nil `GetParent` call aborted the loop and left
  everything after them (status tracking bar, micro menu, totem bar,
  cooldown viewers) visible.
- Fixed clicks on the action bars: the un-parked
  `MultiCastActionBarFrame` sat on top of the buttons and ate them.
- Buttons now also register for `AnyDown` so press-and-hold casting
  works.

## 0.2.1

- Fixed cooldowns never sweeping: without a DurationObject the sweep fell
  through to `Clear()` on every paint - now it uses raw times while they
  are readable, and leaves an active sweep alone instead of clearing it.
- Fixed parked game frames coming back: the game re-parents its bars on
  its own layout passes, so the park now rechecks behind
  `UpdateMicroButtons`, the micro menu fullscreen hand-offs, talent/spec
  updates, Edit Mode changes and the vehicle/override events.
- Each post-build enable step runs in its own safe call now - one
  failure can no longer take the extras (pet/stance/totem bars) down.

## 0.2.0

Full engine rework onto the proven native architecture:

- **Root cause of the `UNKNOWN()` spam removed**: `ActionBarButtonTemplate`'s
  `OnLoad` registers every created button into the game's dispatch lists
  (`ActionBarButtonEventsFrame`, `ActionBarActionEventsFrame`,
  `ActionBarButtonUpdateFrame`). The game then ran *its own* protected
  writes on our buttons under addon taint - every one became a blocked
  call blamed on us. Buttons are now unlisted/unwatched right after
  creation and the template methods that would re-register them are
  silenced.
- **Event-driven painting** instead of the 0.15s poll: per-painter updates
  on the real game events, batched into one flush per frame. The range
  watch only ticks while a target exists.
- **Native keybinds**: keys press the game's hidden twin buttons; the
  secure page driver copies bar 1's page onto them via `actionpage`, so a
  key casts exactly what the SentiUI button shows - cast-on-key-down
  included. No override bindings except flyout slots.
- **Parked game bars**: reparented under a hidden frame once, never
  shown/hidden/alpha'd from addon code. Twins unlisted and parked too;
  `ActionBarActionEventsFrame` silenced.
- **Stance/pet bars adopt the game's own buttons** - updates, keybinds and
  tooltips stay the game's.
- Slot mapping now uses the client's real bar pages (bar2=6, bar3=5,
  bar4=3). Cooldowns stay on the secret-safe DurationObject path.

## 0.1.22

- Fixed the action bars not loading at all (Blizzard bars visible again):
  the labelled `Call()` helper was declared *below* `DriverHide`, so the
  Blizzard suppression called a nil global and `Enable` aborted before a
  single bar was created - and `Core.enabled` was already `true`, so no
  retry ever ran. `Call`/`Sec` are now declared at the top of the file.
- Fixed the duration-object reads: `Call()` returns its `ok` flag first,
  so `GetActionCooldownDuration`'s object never reached the cooldown
  widget.

## 0.1.21

- Fixed the 100x cooldown spam (`Cooldown.lua: attempt to compare local
  'start' (a secret number value)`): `CooldownFrame_Set` was fed raw secret
  `start`/`duration` values and the client's cooldown code compares `start`
  in Lua - which throws under addon taint. `securecall` does NOT untaint on
  this client (verified). The cooldown now uses a `DurationObject`
  (`GetActionCooldownDuration`, built via `C_DurationUtil.CreateDuration`
  when the API is absent) passed to `SetCooldownFromDurationObject` - the
  widget handles secrets natively in C++, no Lua compare. Raw
  `CooldownFrame_Set` only runs when every value is actually readable.
- Remaining unlabelled engine calls (`GetAttribute` in drag/hover,
  `btn:SetChecked` on drag stop, `RegisterStateDriver`) now go through the
  `ns.Call` correlation wrapper too.

## 0.1.20

- `ns.Sec`: calls whose internals touch secret values (`CooldownFrame_Set`,
  `SetCooldownFromDurationObject`, `cooldown:Clear`, `CooldownFrame_Clear`,
  `GameTooltip:SetAction`, `GameTooltip:SetTotem`) now run through
  `securecall` - untainted execution so the client's own code may compare
  secret `start`/action values. Fixes `Cooldown.lua:8: attempt to compare
  local 'start' (a secret number value)` and the resulting
  `ADDON_ACTION_*` spam.

## 0.1.19

- Call-site correlation for the forbidden/blocked radar: every engine call
  in `ActionBars.lua` and `Extras.lua` (action info reads, binding queries,
  override bindings, tooltips, cooldowns, pet/stance/totem/taxi/vehicle
  APIs, frame methods, `SetAttribute`) runs through `ns.Call`, which marks
  the current call site. Since `ADDON_ACTION_FORBIDDEN` fires
  synchronously during the blocked call, the chat now names the exact call
  (`forbidden during X`) instead of `UNKNOWN()`.

## 0.1.18

- The `blocked api` diagnostic also prints the bug tracker hint
  (https://dev.xrl-dev.de/bugtracker) once per session.

## 0.1.17

- `Core.Enable` defers the whole bar construction when it runs during
  combat (e.g. `/reload` mid-fight) - frames created during lockdown are
  born protected and every layout call would fire `ADDON_ACTION_FORBIDDEN`.

## 0.1.16

- Fixed the `ADDON_ACTION_FORBIDDEN` spam: `GetBindingKey`/`GetBindingText`
  were called ~320x/sec in the 0.15s refresh tick - binding queries from
  insecure code are restricted on this client. Hotkey text is now read once
  per `UPDATE_BINDINGS`/login/combat-end and cached per button.
- Every client API read in the button update now goes through a labelled
  wrapper - if another protected call ever fires, the message names the
  exact API instead of `UNKNOWN()`.

## 0.1.15

- SetFont rounds sizes first - the client rejects float font sizes and
  silently leaves the FontString without a font ("Font not set").


- The combat checked-state path no longer calls GetCheckedTexture on the
  protected button - the texture is captured at button creation, removing
  the last possible restricted getter call in combat.


- Stopped the repeating "forbidden call" reports: the 0.15s button tick no
  longer calls restricted methods on protected buttons in combat -
  SetChecked only fires on change (drives the checked texture in combat),
  the hotkey text is cached, and bar layouts defer to after combat.
- More secret-value guards in the pet/stance/totem updates - comparisons
  now check IsSecret first (order matters, secrets throw on any compare).


- The vehicle exit and taxi landing buttons show proper icons now
  (Sentinel gold, Media/Exit.tga + Media/Land.tga) instead of red text.


- Internal error reports use `S.Stack` now - the real traceback prints
  instead of "error in error handling".

## 0.1.10

- Release history is now filed for the in-game changelog
  (SentiUI > Changelog, English + German).

## 0.1.9

- Stance bar: the slots are now capped at the real form/stance count
  from GetNumShapeshiftForms - the bar no longer shows phantom buttons
  for a character without any forms, and it still grows automatically
  as stances/forms are learned.

## 0.1.8

- Removed the micro menu bar: the minimap menu already covers the game
  menu and the client does not expose usable per-button icons for it.

## 0.1.7

- Micro bar rebuilt: reparenting the real Blizzard buttons left them
  invisible on this client, so the bar now creates its own Sentinel
  buttons that forward clicks to the hidden originals via /click macros
  (same mechanism as the stance bar), with the original icon or a short
  label, plus a button size option.

## 0.1.6

- Fixed "hide when empty": HasAction can return secret values on this
  client, which always counted as occupied - the check now looks for an
  action texture instead, so empty extra bars actually vanish.

## 0.1.5

- New "Vertical" option on every bar: action bars fill columns instead
  of rows, pet/stance/totem/micro bars stack downward.
- New micro bar: the real Blizzard menu buttons (character, spellbook,
  talents, finder, collections, menu) are reparented into a movable
  Sentinel bar instead of being hidden with the chrome.

## 0.1.4

- Internal error reports (page driver, secure headers) now include a
  Lua traceback so the failing file and line are shown in chat.

## 0.1.3

- Button updates now use the client's native C_ActionBar.* API (with
  global fallbacks): cooldowns are driven by the info table plus
  DurationObject via SetCooldownFromDurationObject, counts come from
  GetActionDisplayCount, and active states (auto-attack, toggled
  abilities) set the button's checked glow again.

## 0.1.2

- New per-bar option "Hide when empty" (default on for bars 2-4): extra
  bars no longer show a row of dark empty slots at low levels. Bar 1
  always stays visible.

## 0.1.1

- The client's Cooldown Manager viewers (Essential/Utility/BuffIcon/BuffBar)
  are now suppressed as well — they load on demand with
  `Blizzard_CooldownViewer`, so the suppression re-runs after every addon
  load and on entering the world.

## 0.1.0

- First release: action bar module for SentiUI, ported from the proven
  SentinelForeverCore implementation.
- Bar 1 is the paged main bar: a secure state driver follows druid forms,
  warrior stances, rogue stealth, priest shadowform, monk/evoker bonus
  states, vehicles, override and possess bars, plus manual paging (bar:2/3).
- Bars 2-4 are static extra bars on the free pages 4-6 (this client's form
  pages share the side-bar slots); bars 3 and 4 hide while empty, bar 4 is
  the vertical side bar.
- Secure buttons (ActionButtonTemplate + SecureHandlerStateTemplate headers)
  with drag & drop, key binds via override bindings, hotkey/count/macro
  name text, range and usability coloring, cooldown sweeps and tooltips.
- Per-bar settings: enable, button size/spacing/count, buttons per row,
  visibility (always / combat / target), mouseover fade.
- Pet bar (secure pet buttons with auto-attack marker), stance bar (forwards
  to the client's own StanceButtons via /click macro) and shaman totem bar
  (cooldown sweep, right-click destroys the totem).
- Extra buttons: movable holders for the quest extra action button, the
  zone ability button, vehicle seats, talking head, loot rolls, alerts,
  mirror timers and loss of control, plus a secure vehicle exit button and
  a taxi "land at the next stop" button.
- All bars and holders are registered SentiUI movers; the client's own
  action bar chrome is suppressed (protected frames via a secure visibility
  driver, plain chrome faded out).
