# SentiUI Panel

## 0.5.42 - 2026-11-24

- FBL sync speed: a full list now travels in seconds instead of half a minute. Chunks grew to 236 bytes (still under the 255-byte message cap), the addon drain sends 3 chunks per 0.15s tick (~20 msg/s, was 1 per 0.3s), and every broadcast additionally pushes one guild copy - reaching guildmates who never joined the sync channel.
- Pull answers go direct: when a peer asks for a newer list, we now whisper them a full copy via addon message first (not channel- or hardware-gated) before the jittered channel broadcast. Pull cooldown 600s -> 300s, answer jitter 5-40s -> 3-10s.
- Chat fallback flood cap: channel sends inside an input event are now limited to 12 lines per event so the client spam throttle stops silently eating chunks (a missing chunk corrupts the whole list at the receiver).

## 0.5.41 - 2026-11-24

- FBL sync: the receive notice now names the sender's client - 'Blacklist received from X via SentiUI' vs 'via ForeverBlackListed', learned from each peer's FBLver ping (SentiUI announces SentiUI_Panel-x.y, the standalone a bare version).

## 0.5.40 - 2026-11-24

- FBL sync: receiving a blacklist is now visible in chat, not just sending. A complete incoming list prints 'Blacklist received from <name> (n chunks)' in gold before the trust/accept step - previously only the merge result printed, and only when entries actually changed, so unchanged or echoed lists arrived silently.

## 0.5.39 - 2026-11-24

- FBL sync channel: 'invalid channel name' spam gone. JoinSync retried the 18-char preferred name every cycle (up to 30 times per session), printing the system error each pass. Names that miss their join check twice are now remembered in db.sync.badNames and skipped on all later attempts, converging on the FBLsync fallback like the standalone; if every name ever turns bad the marks reset and retry (transient failures).

## 0.5.38 - 2026-11-24

- FBL send crash + false rejections: the channel drain could run before anything was queued (sendQueue nil, 'attempt to index upvalue'), and an over-strict SendAddonMessage result check treated a delivered send as failed, dropping whole payloads ('106 blocks rejected'). The queue now normalizes before drain and the send counts as sent on pcall success, matching the standalone.

## 0.5.37 - 2026-11-23

- FBL sync transport fix: SentiUI's blacklist never reached ForeverBlackListed users. The module sent every channel message via SendAddonMessage 'CHANNEL' - a path this client does not route to custom channels, and the wrapper hid the failure, so 'Blacklist sent' printed while nothing went out. The panel now mirrors the standalone's model: a self-echo probe detects whether addon traffic reaches the channel; when it does not, sends fall back to SendChatMessage, which is hardware-gated and therefore drains inside the real input events (Sync buttons, removal request). Version pings and pull requests park in pending slots until a transport exists, ADDON_ACTION_BLOCKED during a chat send disables the chat path for the session, and F.Debug now reports the probed transport state.

## 0.5.36 - 2026-11-23

- Guild plugin combat fix: hovering the guild tile mid-fight fired ADDON_ACTION_BLOCKED - the tooltip called GetGuildRosterMOTD/GetGuildRosterInfo live and the roster API is protected under lockdown (a pcall does not stop the flag). MOTD and the member list are now cached inside the combat-guarded GuildRefresh and the tooltip only reads the cache; a dirty flag flushes one refresh on PLAYER_REGEN_ENABLED.

## 0.5.35 - 2026-11-23

- FBL realm fix: entries added from a unit lost the target's server - GetUnitFullName called GetUnitName without the realm flag and CleanName stripped any "-Realm" suffix, so AddEntry silently stored our own realm. A ported GetUnitNameRealm (name + realm returns) now feeds AddUnit, the window's Target button (name field carries "First Last-Realm") and the tooltip auto-add, matching the standalone ForeverBlackListed.

## 0.5.34 - 2026-11-22

- Layer channel parking fix: the join/leave timers in the world plugin ran unguarded seconds later, tripping 'forbidden call: UNKNOWN()' when combat started in between. Each timer step now bails under InCombatLockdown.

## 0.5.33 - 2026-11-22

- Accent edge lines (top/bottom bars, plugins menu, toasts) are now inset 7px past the corner arc so they end on the straight edge instead of poking past the rounded frame silhouette.

## 0.5.32 - 2026-11-22

- The blacklist window's filter chips use the shared Sentinel tab chip now: dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active chip - one design language across the whole suite.

## 0.5.31 - 2026-11-22

- New installer step 'Bottom bar plugins': a scrollable checklist of every registered plugin - tick what should show on the bottom bar, untick what should not. Changes apply live and stay editable under SentiUI > Panel > Plugins.

## 0.5.30 - 2026-11-22

- The performance plugin defaults to hidden: the same readout now lives as a gear icon on the minimap (SentiUI_Minimap 0.3.14). The bar entry stays available under Panel > Plugins; existing configs keep their choice.

## 0.5.29 - 2026-11-22

- Overlapping plugin texts fixed: GetStringWidth can return 0 (not nil) before a string has rendered on this client - the width fallback never kicked in, so a freshly updated plugin collapsed to icon width and its neighbor drew over it.

## 0.5.28 - 2026-11-22

- Plugin secure overlays (item/macro targets) no longer replace the template OnClick - clicks run through the client's secure dispatch.

## 0.5.27 - 2026-11-22

- The bottom bar starts much leaner now: only brand, gold, bags, clock, mail, layer, friends, guild, performance, professions and account info are visible on a fresh profile. Location, spec, item level, XP, durability, trainers, compendium and blacklist default to hidden - each is one toggle away under SentiUI > Panel > Plugins. Existing configs keep their choices.

## 0.5.26 - 2026-11-22

- New bottom-bar plugin "AccountInfo": shows total account gold and character count from the SentiUI_AccountInfo module; click opens its window, the menu lists the richest characters and offers a rescan.

## 0.5.25 - 2026-11-22

- New 'Professions' plugin (bottom bar): shows the first learned profession with icon, name and rank; a click opens the professions menu listing every learned profession with its skill level (rank/max) - clicking one opens the game's profession window via C_TradeSkillUI.OpenTradeSkill (works from a click, even in combat). Hides itself while no profession is learned.

## 0.5.24 - 2026-11-22

- Embedded ForeverBlackListed dialogs (note edit, removal request, sync accept) converted to the shared own dialog instead of StaticPopupDialogs entries; all panel windows now close on Escape via S.EscClosable. Both changes remove addon-written entries from game tables that the Escape dispatch reads in Lua - the source of the 'ADDON_ACTION_FORBIDDEN SpellStopCasting' blame.

## 0.5.23 - 2026-11-22

- Player right-click menus now carry the same ForeverBlackListed entries the standalone adds: blacklist, good list, guild entries and a group picker - on Menu.ModifyMenu, classic UnitPopup and a docked fallback, so they show whichever backend draws the menu. Skipped when the standalone addon is installed (it registers them itself).

## 0.5.22

- UNIT vital events join the poll: UNIT_HEALTH/POWER/AURA/HAPPINESS/PET handlers shared the unit-frame update dispatch with Blizzard's secret health-bar compares ('execution tainted by SentiUI_Panel' in HealthBar/UnitFrame) - the vitals/buffs/pet plugins now refresh on the 1.5s ticker with a synthesized 'player' unit arg so their filters still pass. Also fixed: extdb() (the standalone FBL db when ForeverBlackListed is loaded) never ran through our defaults guarantee - callers indexing db.sync crashed again; it now guarantees .sync the same way DB() does.

## 0.5.21

- Event-bus de-taint: the client fires window-data events (durability, equipment/ilvl, spells/talents, friends/guild, quests, tradeskill/AH, mail, bags, money/xp/honor, tracking) INSIDE the window-open or input dispatch - a handler running there taints the dispatch and the client's secret status-bar compare right after fails with 'execution tainted by SentiUI_Panel' (the 16x TextStatusBar error on pressing C). Those events are now polled on a 1.5s ticker; arg-carrying events (UNIT_*, TIME_PLAYED_MSG, layer protocol) stay event-driven.

## 0.5.20

- Blacklist window joins the combat deferral: opening it mid-combat queues for after the fight with a chat note, and an open window hides on combat start and returns after (core S:CombatDeferWindow).

## 0.5.19

- Blacklist peers strip now shows whether someone's list is complete: a lightweight FBLstat message (rev + entry count, ignored by older clients and the standalone) rides alongside the version ping, so each peer row displays 'rev N  theirs/ours' - green when the peer is caught up, red when behind. Our own stats re-announce shortly after merges and manual imports.


## 0.5.18

- Blacklist sync log: fixed the search box overlapping the new chip (window is wider now) and added a peers strip on the sync page - known FBL clients on the channel with addon version, list revision and last-seen time, plus a live channel member count when the roster API resolves.


## 0.5.17

- Blacklist: new 'Sync log' page in the list window (for every user, not just admins) - live status (channel, own/peer revision, live share, auto-accept, trust, last sender) plus a persisted ring buffer of all sync traffic: list sends/receives, chunk counts, pull requests, version pings, peers, removal requests, imports and delegations to the standalone addon. 'Request update' and 'Clear log' buttons included.


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
