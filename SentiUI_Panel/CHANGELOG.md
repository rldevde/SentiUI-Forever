# SentiUI Panel

## 0.5.16

- Hardened the FBL channel handler further: DB() now guarantees .sync is a table on every resolved store (pcall'd merge + a secret-safe table check), and the FBLver handler self-heals a missing sync field instead of indexing nil.


## 0.5.15

- Fixed 'attempt to index field sync (a nil value)' on incoming FBL channel messages: a saved-variables file of another FBLDB declarer can hand us a global that never saw the defaults merge - DB() now guarantees merged defaults on every table it resolves, so .sync and friends always exist.


## 0.5.14

- The shared blacklist now actually reaches other players: the importer routes through the sync owner's store (the standalone's ImportJSON when it is loaded, our live FBLDB otherwise) and runs non-quiet, so the list revision bumps and live-share rebroadcasts the fresh entries on the FBL channel. The probe now checks the sync store too, not just the saved global.


## 0.5.13

- Fixed the shared-blacklist import re-running (and reporting) every login: FBLDB is declared by several addons and the last saved-variables file to load replaces the global - the cached F.db pointed at an orphaned table, so the once-flag and imported entries never reached disk. All FBL reads now resolve the live global, the importer probes for present entries before running and stays silent either way.


## 0.5.12

- SecureAPI now delegates to the shared core wrapper: blocked or failed engine calls print their call site (file.lua:line) once, the same reporting every module gets.


## 0.5.11

- Interface-dispatch audit: plugin buttons got a secure-click overlay - bags, friends, guild, character, talents and calendar now forward a real click to the Blizzard micro buttons instead of calling Toggle* functions from addon code (securecall does not untaint on this client; the calls wrote window bookkeeping tainted). Reputation/itemlevel land on the matching Character-module page; durability uses the module API when it is loaded.

## 0.5.10

- Dispatcher rollback: the world plugin listens to PLAYER_TARGET_CHANGED/UPDATE_MOUSEOVER_UNIT again (GUID-poll ticker removed), TRADE_SKILL_*/AUCTION_HOUSE_* events and BAG_UPDATE_COOLDOWN on the hearthstone plugin are back.


## 0.5.9

- Removed TRADE_SKILL_* and AUCTION_HOUSE_* window events from the world plugins - they fire inside the window's open dispatch and tainted Blizzard's CooldownFrame_Set on secret cooldown values (professions book error). Status refresh runs via the regular update path.


## 0.5.8

- ESC fix, round 5: BAG_UPDATE_COOLDOWN dropped from the hearthstone plugin (fires inside the secure item click dispatch); the 1s refresh covers it.

## 0.5.7

- Escape-forbidden-call fix, round 4 — the real last source: the layer
  plugin listened to `PLAYER_TARGET_CHANGED` and
  `UPDATE_MOUSEOVER_UNIT`. Both fire inside the protected ESC/click
  dispatch, so merely receiving them tainted the client's
  `SpellStopCasting`/`SpellStopTargeting` calls right after. Target and
  mouseover sightings now poll on a 0.4s ticker instead; nameplate
  sightings stay event-driven (render path, not input path).

## 0.5.6

- Escape-forbidden-call fix, round 3: the last insecure code left in
  the Escape dispatch was the removal-request popup's `OnHide`
  callback plus two `OnEditFocusLost` handlers (even a deferred
  `C_Timer` call inside the handler marks the dispatch tainted, so
  `SpellStopCasting` right after got `ADDON_ACTION_FORBIDDEN`). The
  popup now tracks visibility via `StaticPopup_Visible`, the admin
  box saves on each keystroke, and the helper's focus-loss handler
  is gone entirely.

## 0.5.5

- Escape errors gone for real: the remaining `OnEscapePressed` and
  `OnEditFocusLost` handlers on panel/FBL windows ran insecure code
  inside the Escape dispatch, which tainted the engine's
  `SpellStopCasting`/`SpellStopTargeting` calls right after it
  (`ADDON_ACTION_FORBIDDEN` on window close). Both windows are in
  `UISpecialFrames` so Escape closes them natively — the handlers were
  removed, focus-loss work defers a frame.

## 0.5.4

- Removed the `GameTooltip` `OnTooltipSetUnit` `HookScript` fallback —
  an insecure handler on a Blizzard frame taints its whole dispatch,
  and the game then blamed SentiUI_Panel when its own unit-health code
  crashed on secret values (the `blizzard: GameTooltip` /
  `TextStatusBar` reports). Blacklist tooltip lines now only draw
  through `TooltipDataProcessor`; without it they stay off.

## 0.5.3

- Removed the `SendChatMessage` fallbacks from FBL sync — channel chat
  text is hardware-gated on this client, so every timer-driven retry
  raised a blocked call (the anonymous `UNKNOWN()` errors). Addon
  messages carry the same protocol and need no input event.
- Layer asks behave the same way now: the visible chat route is only
  attempted on a real click; retried/timer asks use the addon-note path.

## 0.5.2

- Routed every remaining FBL sync send and channel join through the
  named blocked-call diagnostic — if a call is still refused, the chat
  now prints which function and line instead of a bare `UNKNOWN()`.

## 0.5.1

- The `sentilayer` channel no longer grabs a default slot: when it
  sits on slot 1-6 a filler channel (`sentipark`) takes the low slot,
  the layer channel rejoins above it and the filler leaves - the same
  parking the FBL sync uses. Checked on join, when already joined and
  once after entering the world.

## 0.5.0

- KillStats removed entirely: the kill-tracking window, map pins,
  `/suipanel kills`/`wp` commands, the kills and map-search plugins and
  the options button are gone. The feature kept tripping the client's
  taint radar around the world map (`UNKNOWN()` on map open/close) and
  the tracking it offered is not worth the recurring blame.

## 0.4.8

- Kill-map pins no longer reparent into `WorldMapFrame`'s canvas: our
  insecure child frames were inside the map's protected frame tree, so
  closing the map with ESC ran the teardown through addon code and
  blamed the panel (`forbidden call: UNKNOWN()`). Pins are UIParent
  children anchored *relative* to the canvas now - same dots, zero
  taint.

## 0.4.7

- `ns.HardAPI`: a named wrapper for hardware/protected calls we cannot
  predict (party invites/leaves/kicks, channel joins, channel sends).
  When the client rejects one, the panel prints
  `blocked call: <name> @ file.lua:line` once - turning anonymous
  `UNKNOWN()` blame into an exact call site.

## 0.4.6

- Volume plugin: the legacy `SetCVar` global is protected on this
  client - pcall caught the Lua error but the blocked-action event
  still fired (`UNKNOWN()`). The sound toggle and volume steps use
  `C_CVar.SetCVar` now.
- FBL channel sends respect combat lockdown: the chunk drain, pull
  requests and version pings pause mid-fight and resume after combat
  instead of piling up blocked channel sends.

## 0.4.5

- Removed the insecure script hooks from Blizzard frames: the kill-map
  rare pins no longer `HookScript` `WorldMapFrame` OnShow/OnUpdate -
  they poll from an own ticker while the map is open. Closing the
  world map with ESC ran the client's protected teardown through the
  hooked frame and blamed the panel (`forbidden call: UNKNOWN()`).
  The minimap mail indicator polls `IsShown` on demand now instead of
  hooking OnShow/OnHide.

## 0.4.4

- More `UNKNOWN()` sources closed: plugin updates fire on every bus
  event (gold, coords, bags - mid-combat included) and ran
  `SetParent`/`SetPoint`/`SetShown` on buttons holding the secure
  overlay; sizing + relayout now defer through `S.RunOutOfCombat`. The
  FBL channel join (`JoinChannelByName` is combat-protected) also
  waits for combat to end instead of being blocked by the retry
  timer.

## 0.4.3

- Taint hardening: the bars now hide during combat via a secure
  `RegisterStateDriver` visibility driver instead of insecure
  `SetShown` calls on frames holding secure children (the 0.4.2
  hearthstone overlay made that path blockable -> `UNKNOWN()`).
  Anchoring and layout work defers through `S.RunOutOfCombat`.
- The plugin menu's screen-wide click catcher propagates mouse clicks
  to the world now, so right-click cancels (`SpellStopTargeting`) and
  Escape cancels (`SpellStopCasting`) are no longer eaten and blamed
  on the panel.

## 0.4.2

- Forbidden `UNKNOWN()` calls now identify themselves: when a
  SecureAPI-wrapped function is rejected, the panel prints the actual
  call site (`file.lua:line`) once instead of leaving the blame
  anonymous.
- The hearthstone plugin is a real secure button now (`item`
  attribute) - item-use APIs are protected on this client, so the old
  `UseItemByName` click could only fail. Left-click uses the
  hearthstone natively, right-click still opens the plugin menu.

## 0.4.1

- Kill-stats note popup: its Escape handler now defers `Hide()` out of
  the key dispatch like the other panel fields, closing the last
  synchronous Escape->hide path that could feed the protected Escape
  binding (ADDON_ACTION_BLOCKED/FORBIDDEN spam).

## 0.4.0

- Fixed the FBL module dying at load: the 30-minute version-ping ticker
  captured `SendVersionPing` before its assignment, so the file aborted
  mid-load and every FBL entry point (window toggle, menu, tooltips)
  stayed nil - the blacklist button threw "attempt to call a nil
  value". The ticker now calls through a closure.

## 0.3.9

- FBL sync performs the standalone's full convergence handshake:
  version pings carry our list revision (`FBLver;ver;rev`), a peer
  advertising a newer revision triggers a rate-limited `FBLpull`,
  joining the channel pushes our list when it changed since the last
  broadcast, and a 2-minute watchdog rejoins a lost channel. Paired
  with ForeverBlackListed 1.3.6 pulling on join, both implementations
  converge to the same list in both directions.

## 0.3.8

- Fixed a Lua scoping error on channel join: the pull-request callback was declared below its use, so the timer got nil and threw - the sync-channel pull now fires correctly.

## 0.3.7

- Blacklist sync receives FBL pull/version traffic now: after joining the channel we broadcast 'FBLpull;rev' asking peers for the newest list (an online ForeverBlackListed client answers with a full push), and we answer pull requests ourselves when our revision is ahead - jittered like the standalone. '/suipanel fbl' prints a sync debug line (channel, prefix, entries, last sender).

## 0.3.6

- Blacklist sync no longer spams: your own broadcast echo is ignored (channel addon messages bounce back to the sender) and merges only print when entries were actually added or updated - silent merges stay silent.

## 0.3.5

- Blacklist add-form: chips row is no longer clipped (taller form, fixed widths on Player/Guild/Good list). Sync send hardened: join waits for default channels and retries both channel names via all join APIs, the addon prefix registers at login, send falls back to channel chat when addon messages fail, progress and rejected chunks are reported.

## 0.3.4

- Fixed ADDON_ACTION_FORBIDDEN (SpellStopCasting) blamed on the panel: Escape handlers in the blacklist fields, the text popup and the map search now defer focus loss/hide out of the key handler, so Escape no longer falls through to the protected binding.

## 0.3.3

- Two builtin list admins now: Xenshi Lucas and Raziel Lucas - both can delete entries, moderate notes, answer removal requests and use Sync all. The standalone ForeverBlackListed honors the same pair.

## 0.3.2

- Blacklist reached feature parity with the standalone: right-click context menu on entries (vote +/-, move between blacklist/good list, edit note, move to any group, remove), votes show your own mark; the admin page gained auto-accept + trust mode chips and JSON import/export popups. Ships a one-time importer that merges the shared ForeverBlackListed list into FBLDB.

## 0.3.1

- Blacklist: full wire sync ported - 'Sync all' on the admin page pushes the whole list as chunked JSON on the FBLsync channel, incoming chunks are reassembled and merged last-write-wins (entries, notes, votes, tombstones) with the same trust/auto-accept rules and dedupe as the standalone; local changes rebroadcast via live-share. The add form now uses a real Player/Guild radio pair.

## 0.3.0

- Blacklist admin page: an 'Admin' filter chip appears only for list admins and swaps the list for status, effective admins, the extra-admin field (shared sync.admin key) and pending removal requests with accept/decline.

## 0.2.9

- Blacklist window rebuilt: filter chips, live search, group headers with counts, kind icons, guild/realm/votes columns, rich tooltips, add form (name/note/kind/good), Target fill, proper empty states.

## 0.2.8

- Fixed a load error: the removal-request locale key contained a real line break inside a quoted string.

## 0.2.7

- FBL admin support: EffectiveAdmins + IsAdmin, admin note deletion with tombstone stamps, FBLreq removal requests over the ForeverBlackListed/FBLsync channel in both directions (accept popup for admins, request option in the plugin menu), admin marker in the list window.

## 0.2.6

- ForeverBlackListed integrated: Blacklist plugin (count + list + add/remove via menu), shared FBLDB store compatible with the standalone addon (delegates to its window/sync when loaded), tooltip lines with auto-add rules, whisper/invite warnings with auto-decline, compact list window fallback.

## 0.2.5

- New noLabel plugin flag: suppresses the Label: prefix even when the saved label option is on - fixes "Trainers: Trainers" persisting from an older config.

## 0.2.4

- Trainers and Compendium plugins no longer print their label twice (icon plus name once).

## 0.2.3

- New Compendium plugin (bottom bar): opens the SentiUI_Journal dungeon compendium when the module is installed.

## 0.2.2

- New **Trainers** plugin (bottom bar, book icon): opens the
  SentiUI_Training window - the trainer compendium with class
  spells, weapon skills and profession recipes. The plugin hides
  itself when the module is not installed.

## 0.2.1

- Layer letters no longer balloon (`Layer AA` and friends): the vote
  winner was adopted instantly on every sighting, so layers
  overlapping in view flickered the display and each flicker minted a
  registry letter. A challenger now has to hold the majority for
  ~2.5s before the display flips; the first read still adopts at
  once. Registry writes are skipped during the stale window and on
  unreadable zones, and any per-zone list past Z rebuilds itself.

## 0.2.0

- Mail indicator rebuilt on the native signal: `HasNewMail()` is the
  verdict again (the call the engine's minimap envelope and
  SentinelForeverCore's info bar use). The minimap mail frame is only
  a fallback for a missing API, resolved as the icon child - never the
  always-shown `IndicatorFrame` container, which was the actual
  stuck-true bug - and tracked via `OnShow`/`OnHide` hooks like
  DaylightUI's mail dot. `/suipanel mail` now prints every candidate
  frame's state separately.

## 0.1.9

- World-map kill pins are now **opt-in**: nothing is drawn until you
  search for a mob. New **Map search** plugin on the bottom bar
  (spyglass icon) - left-click opens a search box, matching kills
  light up their recorded spawn points on the world map, clearing the
  search hides every pin again. Right-click menu: search, clear,
  open statistics.

## 0.1.8

- **Layer** plugin: friendly layer names no longer require the
  standalone SentiLayer. The plugin now keeps its own per-zone layer
  registry in its saved options - layers get letters in first-seen
  order (Layer A, B, ...), persisted across reloads. SentiLayer's
  letters still win while that addon is loaded, so the naming stays
  consistent for anyone migrating.

## 0.1.7

- The **Layer** plugin is now a self-contained SentiLayer replacement -
  the standalone addon is no longer needed. Left-click asks for a swap
  on the `sentilayer` channel using the same protocol ("inv layer
  `<SL zone not id>`" plus hidden SentiLayer addon notes), so
  SentiLayer users still invite you; accept the invite, the votes
  confirm the move, and the host group is left automatically. A
  **Host swaps** menu toggle (on by default) makes you a host too:
  asks on the channel are filtered by zone and wanted/avoided layers,
  answered invites are kicked after the guest moved. Known gaps vs.
  SentiLayer: no whisper-search fallback on restricted realms, no
  per-player notes log, no panel UI - this is the compact protocol
  surface.

## 0.1.6

- Layer plugin: the detected layer now persists across `/reload` - the
  last reading is kept in the plugin settings until the creature votes
  actually move to another layer (zone change, group join, Blizzard
  shard transfer), so the bar never flashes "?" on a relog while you
  still stand on the same shard.

## 0.1.5

- New **Layer** plugin (bottom bar, right side): reads your shard layer
  from the creature GUIDs in view, SentiLayer-style - server+zone of
  the GUID is the layer, the creatures present at a zone change or
  group join are frozen out for 10 seconds as leftovers of the old
  layer, and a majority vote over the last sightings decides. Shows the
  same per-zone letters (Layer A/B/C) when the standalone SentiLayer
  addon is loaded; left-click opens its panel, right-click asks for a
  layer swap.

## 0.1.4

- Mail detection reworked again after reports the indicator still
  stuck: the lookup now also covers `MinimapCluster.MailFrame`, falls
  back to the unread-sender list (`GetLatestThreeSenders`) when no mail
  frame exists, and only then to `HasNewMail`. New `/suipanel mail`
  command prints all three signal states plus the verdict so a stuck
  indicator can be traced to the layer that lies.

## 0.1.3

- Fixed the mail indicator sticking on "New mail": `HasNewMail()` stays
  true on this client after the mail was read, so the bottom bar never
  cleared. The plugin and the new-mail toast now trust the engine's
  minimap mail frame (shown = mail waiting) and only fall back to
  `HasNewMail` when the frame does not exist.

## 0.1.2

- Kill statistics window and the details/export text popup are now
  real movers: move-mode handle, Movers.Save persistence, kept across
  reloads.

## 0.1.1

- Minimum plugin spacing: plugins inside a zone now always keep at
  least 8 px between each other, so a spacing of 0 can no longer glue
  them together. Plugin spacing slider starts at 8.

## 0.1.0

- Initial release: Titan-style info bars at the top and bottom screen
  edge with LEFT / CENTER / RIGHT zones, right-click bar and plugin
  menus, shift+drag to move plugins between bars and zones, auto-hide,
  class-colored border, gloss and the secure Adjust-UI viewport.
- 30 builtin plugins: clock, location/coords, performance, played,
  session, speed, volume, calendar events, tracking, vitals, XP,
  reputation, spec, item level, durability (vendor actions), ammo,
  soul shards, pet happiness, timed buffs, PvP rank, hearthstone,
  gold, bags, mail, friends, guild, quests, saved raids, auctions,
  profession cooldowns and kills - each with a proper tooltip and
  click/right-click actions.
- Kill statistics window: creature and NPC tracking with spawn
  points, drops, rare detection with toast+sound, NPC roles, quest
  book with texts and objectives, sidebar sections,
  name/zone/level/role filters, waypoints (TomTom or native), CSV
  export, notes and rare pins on the world map.
- Notification toasts for new mail, low durability, full bags and
  spotted rares. Slash: `/suipanel` (`top`|`bottom`|`reset`|
  `kills [name]`|`wp <name>`).
