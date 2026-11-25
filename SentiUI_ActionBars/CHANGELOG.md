# SentiUI Action Bars

## 0.3.70 - 2026-11-25

- `/suibars` no longer depends on the optional FrameXML `strtrim` global; the command keeps working on clients where that utility is absent.
- The parked-button mouse sweep now treats a secret `_sentiTwin` field read safely instead of letting the truthiness test abort the sweep, and action-count fallback reads check secrecy before type inspection.

## 0.3.69 - 2026-11-25

- Removed the addon's own "Open all" mail button: the client ships a native inbox "Open all" button, so ours was a duplicate.

## 0.3.68 - 2026-11-25

- Communities/Guild window unskinned: the dialog skin fought DaylightUI's social pack over the same frame; the member card and invite pane ended up floating off the window edge. Both frames keep their own look.

## 0.3.67 - 2026-11-25

- "Open all" button on the mail window: drains the inbox one letter per tick until empty.

## 0.3.65 - 2026-11-24

- Cooldown dim: action icons desaturate while their cooldown sweeps and get the color back the moment the spell is usable again (option: Cooldown dim, on by default). Cooldown end fires no event on this client, so a small watcher re-checks dimmed buttons every 0.1s until the widget stops sweeping; charge abilities keep their color while a charge recharges.


## 0.3.64 - 2026-11-24

- Level-up during combat no longer flashes the Blizzard talent window in: the client auto-opens the talent panel for the new point and it stayed visible until regen. A talent panel surfacing within 2.5s of `PLAYER_LEVEL_UP` is now recognized as that auto-open and re-hidden immediately; the unspent-points pill carries the hint instead.

## 0.3.63 - 2026-11-23

- Loss-of-control banner follow-up: the game re-alphas its red art and re-anchors icon+text on every display tick, undoing the one-shot skin - the style now re-applies every 0.15s while the banner is visible, so the icon stays docked left, the red lines stay dead and the fonts keep the SentiUI look.

## 0.3.62 - 2026-11-23

- Button skin fix, round 2: some button templates keep their themed face on named fields (ButtonTexture, ArtOverlay, Background, ButtonArt) or on chrome child frames instead of plain texture regions - the professions' red "Create"/"Create All" buttons painted over our fill and border. Text buttons now alpha named chrome fields and every child frame plus its textures before our template goes on.

## 0.3.61 - 2026-11-23

- Button skin fix: NineSlice sub-widgets and widget-level state textures (normal/pushed/disabled/highlight) survived the texture fade on some button templates and rendered Blizzard's border/face over ours - the "half-broken" button look (e.g. trainer buttons). Both are alpha-killed before our template is applied.

## 0.3.60 - 2026-11-23

- Loss-of-control banner (stun/root/silence) gets a dedicated skin: Blizzard blackBg and red line art removed outright, icon docked to the left edge at bar height (was overlapping the ability text), SentiUI panel + gold edge, restyled fonts.

## 0.3.59 - 2026-11-23

- Fixed Lua ordering error: SKINS.MirrorTimerContainer called the local SweepStart function before its definition line, so it resolved nil and errored on load - the mirror timer skin never ran. The proxy + skin are now defined after SweepStart.

## 0.3.58 - 2026-11-23

- Mirror timer bars (breath, fatigue, feign death) now get the SentiUI skin properly: the StatusBar fill widget is found inside the MirrorTimerN container (it lives on a child on this client, not the container itself), gets a flat gold fill, and the wooden border texture is killed outright instead of dimmed to 15%.

## 0.3.57 - 2026-11-23

- Breath/fatigue bars (MirrorTimer) stay unskinned no longer: they spawn lazily on first use on this client, so the one-time `MirrorTimer1..3` loop found nothing. The container is now wired into the lazy sweep with a proxy that merges container children and `MirrorTimer1..10` globals — every new bar gets the flat fill, dark panel + gold edge and SentiUI font as it appears.

## 0.3.56 - 2026-11-23

- Cooldowns surviving a reload: `PLAYER_ENTERING_WORLD` repaints all buttons, but action data is often unreadable at that moment and already-running cooldowns fire no events afterwards — long cooldowns stayed unpainted until a new cast. PEW now also schedules delayed cooldown-only sweeps at +0.5s/+1.5s/+3s so restored cooldowns get their swipe and countdown numbers back.

## 0.3.55 - 2026-11-23

- Cooldown number readability: the countdown font was `GameFontHighlightSmall` (plain white, no outline) — unreadable over bright spell icons. Now `SystemFont_Outline_Small`, which carries a dark outline for contrast (same look as Blizzard's cooldown digits).

## 0.3.54 - 2026-11-23

- NPC/quest/gossip dialog text: parchment-dark strings stay near-black now (like the originals) instead of being lifted to the bright text color — readability on the dark panel comes from a tiny 1px white shadow offset bottom-right (alpha 0.85), a hairline rim that doesn't glare. Applies to every dialog RestyleFonts touches.

## 0.3.53 - 2026-11-23

- Cooldown numbers on action buttons: the `ActionBarButtonTemplate` cooldown hides its countdown digits on this client, so only the swipe showed. `MakeButton` now calls `SetHideCountdownNumbers(false)` / `SetShowCountdownNumbers(true)` and hands the widget `GameFontHighlightSmall` via `SetCountdownFont` (each call guarded for older builds). Also picks up the template's `ChargeCooldown`/`LossOfControlCooldown` children — they were never assigned, so charge-recharge and loss-of-control swipes never painted; they are anchored to the icon in `StyleButton` like the main cooldown.

## 0.3.52 - 2026-11-23

- Action bar frame: replaced the 4 thin gold edge strips with `S.Template(holder, "panel")` — the holder now gets a proper dark panel backdrop with an accent-tinted border that sits flush behind the button grid (3px pad) instead of floating as a thin disconnected line at the outer edge.

## 0.3.51 - 2026-11-23

- Mail compose window: `SkinMail` finds the body ScrollFrame (`MailBody`, `MailScroll*`, or any ScrollFrame containing an EditBox) and applies the dark `inset` fill to the whole message area instead of just the thin EditBox inside it. The parchment texture is faded — no more black bar floating on orange paper.
- `SkinQuestDialog` moved after `SkinDialog` in the file — Lua local functions must be declared before use; the original order caused `attempt to call a nil value` on QuestFrame and GossipFrame.

## 0.3.50 - 2026-11-23

- Quest/NPC dialog font fix: removed the `OUTLINE` flag from `RestyleFonts` — the thick black stroke produced a heavy black border around all white text on the dark panel. Quest and gossip fonts carry their own subtle shadow and read cleanly without the extra outline.
- Quest/Gossip frame structure: `SkinQuestDialog` adds a subtle gold divider (28% alpha, 1px) at y=-55 below the NPC greeting/portrait area, giving the frame a titled section structure instead of floating text on a blank dark panel.
- Action bar gold border: four 1px gold accent strips on the bar holder's BORDER layer (below button art) frame every bar in Sentinel gold at 55% alpha.
- Action bar bottom offset raised from 10px to 16px for better clearance from the screen edge.
- Action bar button icon inset increased from 1px to 3px — the icon was bleeding into the PillEdge backdrop's corner arc and appearing visually cut off at the edges.

## 0.3.49 - 2026-11-23

- Cooldown fix: complete rewrite of `PaintCooldown` / `sweep` to never inspect secret/tainted values in Lua.
  - **Root cause**: `startTime`, `duration` and `isActive` are secret/tainted values on this client. Any Lua comparison on them (`== true`, `S.IsSecret(...)`) throws under addon taint, aborting the painter. Even wrapping `isActive == true` in `pcall` and treating a throw as "not active" was wrong — it caused `sweep` to explicitly `Clear()` all running cooldowns.
  - **Fix**: `isActive` is never read. The raw `info` table is passed directly to `CooldownFrame_Set` (Blizzard C++ function that handles secrets internally). The C++ layer itself decides show/hide based on `duration`. Fallback chain: `SetCooldownFromDurationObject` → `CooldownFrame_Set` → `cd:SetCooldown` (direct frame method, for clients where the FrameXML global is absent).

## 0.3.48 - 2026-11-23

- Dark text in quest/gossip/book dialogs: raised the luminance threshold for the dark-text lift from `0.35` to `0.52`. This catches the parchment mid-tones WoW's `QuestFont`/`GossipFont` objects use (~0.40–0.50 luminance) which previously slipped through and stayed black on the dark panel.

## 0.3.47 - 2026-11-22

- `SkinPanelish` windows: dark fill via `raised` template (gold border tint), four clean corner-to-corner gold strips — no arc offsets, no `EdgeArc` gaps. Action buttons get a 1px gold ring overlay on hover and while a spell is toggled active.

## 0.3.46 - 2026-11-22

- The golden window edge uses the `GoldEdge` edgeFile again — now backed by the regenerated, spec-correct texture (continuous side lines + rounded corners), it replaces the strip+arc raster as intended.

## 0.3.45 - 2026-11-22

- Reverted the `GoldEdge.tga` window edge: the generated file renders a fat band on one side and open corners instead of a closed thin ring — the gold contrast edge is back to the strip+arc raster.
- Black dialog text: gossip/quest/book bodies are re-painted by the game after the show pass, so the dark-text lift now re-runs on the content events (`GOSSIP_SHOW`, `QUEST_*`, `ITEM_TEXT_*`) and also catches strings whose font object carries the dark color while the vertex color reads white.

## 0.3.44 - 2026-11-22

- Action-button states ride the media: the pushed state uses the `ButtonPushed` soft-light overlay instead of a white blank tint, and the checked state uses the `ButtonChecked` gold outline ring instead of an accent fill — pressed and toggled buttons now read as designed states, not color washes.

## 0.3.43 - 2026-11-22

- Generated media in the window skin: the golden contrast edge uses the `GoldEdge.tga` edgeFile — one anti-aliased accent ring replaces the strip+arc raster on every skinned window. Scrollbar thumbs ride the real `SliderThumb.tga` glyph (accent-tinted) instead of a solid strip, and checkboxes use the `CheckOn`/`CheckEmpty` widget art — dark box, gold check — instead of a tinted Blizzard check.

## 0.3.42 - 2026-11-22

- Forbidden-object hardening, second pass: TradeFrame's own `GetRegions` passes but a child inside it is forbidden — `RestyleFonts` walked in and threw "Attempt to access forbidden object". The probe now checks both `GetRegions` and `GetChildren`, and every walk entry point carries the cached check.

## 0.3.41 - 2026-11-22

- The gold window edge was missing its corners: the four accent strips ended 7px short of every corner, leaving the border open on all skinned Blizzard windows. Rasterized quarter arcs (new core S.EdgeArc) now close the frame - center and radius land exactly on the strip ends and follow the panel's rounded corner.

## 0.3.40 - 2026-11-22

- Fix: forbidden objects (TradeFrame, StoreFrame) threw "Attempt to access forbidden object" on login and every open - GetRegions/GetName is refused there. The skin probes a frame once, caches the verdict and leaves forbidden objects completely alone. Child-level probes (object type, name) are silent pcalls now, so protected children skip quietly instead of printing "blocked api" warnings.

## 0.3.39 - 2026-11-22

- Golden contrast edge: every skinned Blizzard window now carries the 1px accent frame around its panel - strong on top, softer on the other three sides, inset past the corner arcs like every own SentiUI window.
- Fix: styled windows flipped back to the old Blizzard look mid-session. The game rebuilds its chrome on every open (NineSlice children, region alphas, backdrops) - the chrome kill now re-runs on every show, and scrollbars, checkboxes and status bars re-apply their skin every walk instead of once. A deferred re-walk catches content populated a tick after OnShow (AH result rows).

## 0.3.38 - 2026-11-22

- Skinned dialog buttons light their border on hover - the same border-lit feedback every own SentiUI widget has. Icon/art buttons stay untouched.

## 0.3.37 - 2026-11-22

- Close buttons keep their X glyph but tint accent gold; window titles (TitleText, TitleContainer) read in accent gold.

## 0.3.36 - 2026-11-22

- Scrollbar up/down arrow buttons get tinted accent gold - the glyph stays but the wooden button look dies.

## 0.3.35 - 2026-11-22

- Widget sweep now also covers UIWidgetCenterDisplayFrame; pet battle queue ready popup and old browse/raid browser frame names join the dialog list.

## 0.3.34 - 2026-11-22

- Closed the leftover gaps inside styled windows (visible at the auction house): the chrome pass now runs at every depth of the child walk, so nested panels lose their own NineSlice/Border fields and named inset children. The window's own backdrop edge is cleared (BackdropTemplateMixin borders are not texture regions and survived the fade). Modern MenuUtil DropdownButton objects (AH filter dropdowns) get the raised style, and ornate border art on the ARTWORK layer fades when the region name reads border/background-ish.

## 0.3.33 - 2026-11-22

- Fixed erased icons in the group finder (LFG role/activity tiles): the deep walk faded buttons whose names did not read icon-ish. The guard now keeps a button's art when any texture region sits on the ARTWORK layer or when the button has textures but no label text. Added alternate finder frame names (GroupFinderFrame, PremadeGroupsFrame, LFGFrame).

## 0.3.32 - 2026-11-22

- Chat popup menus (chat menu, emotes, language, voice macros) and the chat autocomplete dropdown get panel + fonts. Pet battle frame and dungeon difficulty banner get fonts only - their buttons are content art and a generic skin would break more than it fixes.

## 0.3.31 - 2026-11-22

- World map gets its own skin (panel + top-level chrome + fonts, no child walk - map pins are plain buttons without icon-ish names and would have been faded invisible). The per-show deep re-walk now only runs for real dialogs, so panel-only skins keep their button art.
- More stragglers: barber shop, audio options, transmogrify frame, raid parent, contribution collection, torghast level picker; battleground always-up score gets the font pass.

## 0.3.30 - 2026-11-22

- The deep child walk re-runs on every window show, not just once: widgets the game builds lazily (tab pages on first click, scroll rows on populate, late-spawned buttons) get styled as soon as the window reopens. Marker flags keep already-skinned children cheap.

## 0.3.29 - 2026-11-22

- Backdrop chrome dies too: modern inset frames carry their border through the backdrop mixin rather than texture regions - the chrome pass now clears SetBackdrop on NineSlice/Border/Inset/Bg/TopTileStreaks children and fades one child level deeper, so the frame edge can no longer survive the texture fade.
- Last named stragglers: battle tag invite, recruit-a-friend dialogs, quest sync dialogs, edit mode system settings, generic popup, loss-of-control splash (panel+fonts).

## 0.3.28 - 2026-11-22

- Fourth wave of window skins: auction house (both frame names), black market, read-mail window, stable master, arena registrar, movie frame, store, script errors, bonus roll, party pose screens, keystone frame, macro icon picker, community ticket manager, quest log popup detail, recruit-a-friend, scrapper, azerite frames, reputation detail and token popups, all calendar sub-windows, tutorial frame - plus panel+fonts on the compact raid manager pullout.

## 0.3.27 - 2026-11-22

- Third wave of window skins: modern SettingsPanel, click bindings, edit mode manager, group-finder popups (ready/invite/role check), PvP match results/scoreboard, player choice, warboard, archaeology, item interaction, obliterum, islands, chromie time, guild control/invite/text edit, model preview, splash, death recap, report, generic traits, delves pickers, crafting orders and the garrison/order hall/covenant/soulbind/runeforge/anima system windows.
- Chrome in named child frames (NineSlice, Border, Inset, Bg, TopTileStreaks) now fades along with field-based chrome; status bars inside windows swap the wood fill for the flat blank texture and keep their status color.

## 0.3.26 - 2026-11-22

- The window skin now walks the full child tree: nested page buttons, scroll children and tab-page widgets get the raised/inset look instead of staying wooden. Text tabs (merchant, spellbook, friends, character) become raised chips; dropdown fields lose their pill chrome and sit in a dark inset (label and arrow stay).
- The icon guard got sharper: buttons whose name, icon field or texture regions read icon/item/slot/spell/glyph/portrait keep their art - spellbook and glyph icons can not be erased by the deep walk.

## 0.3.25 - 2026-11-22

- Second wave of window skins: collections, encounter journal, achievements, calendar, guild/communities, PvE finder, challenges, talents, professions/tradeskill, wardrobe/transmog, void storage, item upgrade/socketing, weekly rewards, perks, landing pages, flight map, loot history, BG scoreboard, quest log detail, raid info, guild registrar, color picker and opacity frames all get the Sentinel dialog skin (load-on-demand frames resolve through the show watcher).
- Scrollbars and checkboxes inside the skinned windows get a deep styling pass: scrollbar tracks fade, thumbs become solid accent bars (arrow art stays), checkbox checks tint accent gold.

## 0.3.24 - 2026-11-22

- Dark text on the dark panel is readable now: Blizzard dialog fonts are painted black for parchment, so a luminance check in the font pass lifts only strings that still read dark onto the normal text color - quality/link/header colors keep their role color. The font pass also re-runs on every show, since the game repaints text colors per open (quest pages, merchant tabs).

## 0.3.23 - 2026-11-22

- The dialog skin now covers the big everyday windows too: quest giver/log, gossip, merchant, mail, spellbook, trade, inspect, taxi, dressing room, tabard, petition, friends, macro, trainer/craft, battlefield/PvP/honor/LFG, bank/guild bank/auction, quest timer, time manager, help, interface options/keybindings and the addon list. Missing names are skipped; load-on-demand windows are styled on first show via the visibility watcher.
- Item slot buttons inside those windows keep their icons: the child-button skin faded every texture region, which would have erased merchant slots, quest reward icons and mail attachments - item/icon/slot/tab/attachment buttons now only get the font pass.

## 0.3.22 - 2026-11-22

- Cooldown Manager viewers opt-in (Extra buttons page): the parked Essential/Utility/Buff viewers come back with a SentiUI skin and movable positions — off by default.
- Mover-framed Blizzard UI gets the SentiUI look: TalkingHead, mirror timers and the vehicle seat indicator lose their chrome and gain the dark panel; large screen texts (zone/subzone, raid warnings, boss emotes, UI errors) use the SentiUI font with accent colors.
- Remaining Blizzard leftovers skinned: ESC game menu, StaticPopup dialogs, ready check, item text, chat config, stack split and cinematic close dialogs get the dark panel with SentiUI buttons/fonts; dropdown menus, Battle.net toasts, queue and ticket status, durability doll and ghost button get the panel look; boss/level-up banners switch font; alert toasts, UI widgets (top-center/below-minimap) and battleground timer bars are styled on spawn via a slow sweep.

## 0.3.21 - 2026-11-22

- Fixed a cooldown error: the button template's own handlers call `SetCooldown(start, duration, modRate)` with values that are secret on this client — `SetCooldown` refuses secrets under addon taint. Our buttons now swallow that throw on their own cooldown widget; the visible cooldown still paints via `SetCooldownFromDurationObject` and the game's untainted cooldown events.

## 0.3.20 - 2026-11-22

- Empty action slots dim their button body to 18% opacity instead of showing a full dark square — the bar grid stays readable without prominent black boxes.
- Icon rounding now uses the rewritten core S.IconRound: the icon is clipped by a real MaskTexture (rounded-square silhouette).

## 0.3.19 - 2026-11-22

- Action button icons now have soft rounded corners via S.IconRound — background-colored arc pieces cover each icon's square corner (6px radius, matching the button body rounding).

## 0.3.18 - 2026-11-22

- Talent alert pill: same secure-click fix - the /click forward keeps the template's own OnClick handler so the macro runs untainted.

## 0.3.17 - 2026-11-22

- Fix the 'forbidden call' spam in combat: the 2s mouse-unblock sweep touched protected children inside parked Blizzard bars (EnableMouse is forbidden mid-fight) and got blamed on SentiUI. The sweep and KillMouseDeep now skip while in combat; the next tick after REGEN catches up.

## 0.3.16 - 2026-11-22

- Fix 'hide when empty' bars blinking on fresh characters: the bare SetShown fought the visibility state driver, which re-asserted 'show' and made the bar flicker every check tick. Empty bars now hide by unregistering the visibility driver and re-registering it when a slot gains an action; they also reappear while dragging a spell (ACTIONBAR_SHOWGRID) so they can receive drops.

## 0.3.15 - 2026-11-22

- Real click blocker found via /suibars foci: parked Blizzard bars keep CHILD frames at their old rects with mouse enabled (an unnamed MultiBarBottomLeft child at MEDIUM/level 1001 sat over the extra bar). Parked subtrees and the status-tracking containers now lose their mouse recursively; secure twin buttons keep theirs (click targets). Unnamed fullscreen ModelScenes lose the mouse in the sweep.

## 0.3.14 - 2026-11-22

- TextOverlayContainer can be created lazily after the button - its mouse now gets disabled in the 2s sweep too, not only at button creation.

## 0.3.13 - 2026-11-22

- Follow-up click fix: the widget CONTAINER frames themselves (UIWidgetBelowMinimap/TopCenter/PowerBar, ObjectiveTrackerUIWidget, ContainerFrame) also lose their mouse - they are pure layout frames; children keep their own hit flags. New /suibars foci prints the mouse-enabled frames under the cursor so any remaining click blocker names itself.

## 0.3.12 - 2026-11-22

- Fix extension bar slots only clicking on a thin lower rim: the template's TextOverlayContainer rides at frame level 500 with its mouse enabled and covered the whole button, and the client's global FX/widget model scenes at high strata swallowed clicks where they overlap the bars. The container's mouse is dropped per button; the FX/widget model scenes lose theirs on a 2s sweep (they respawn late).

## 0.3.11 - 2026-11-22

- Holder attach keeps ExtraAbilityContainer and friends in place by a 0.5s drift poll instead of SetParent/SetPoint post-hooks - the hooks ran inside the client's layout dispatch and tainted whatever protected work followed.

## 0.3.10

- The labelled Call/Sec wrappers now delegate to the shared core wrapper (S.Call): blocked engine calls print the api name AND the call site (file.lua:line) once.


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
