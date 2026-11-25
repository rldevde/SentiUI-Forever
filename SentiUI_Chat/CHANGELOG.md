# SentiUI Chat

## 0.2.40 - 2026-11-25

- Level-up chat jump fixed at the source: ChatFrame1 now gets the real `ignoreFramePositionManager` frame field instead of the ineffective secure attribute, its legacy managed-position entries are removed, and any already-registered managed-container membership is cleared. Blizzard's level-up/banner layout pass should no longer move the chat out of the panel even for one frame.
- When the fallback snap-back does correct a displaced ChatFrame1, it now also saves that corrected rectangle to the chat cache so a later FCF restore cannot reapply the stale pre-panel position.
- Chat message/label guards now check secret values before type or truthiness tests, so protected chat text cannot throw inside the filter, throttle, loot-window detection or player-level rewrite paths.

## 0.2.39 - 2026-11-23

- Chat tabs keep their Sentinel skin permanently: the tab style only ran once per frame (the styled-flag early-return sat before the tab pass), but the engine re-paints the tab's Selected/Highlight art on every dock/hover/select and the gray Blizzard bevels crept back. StyleTab now re-runs on every watchdog tick (it is fully idempotent) and also kills a NineSlice on newer tab templates.

## 0.2.38 - 2026-11-23

- Input bar only appears while typing now: this client never hides its editbox (IsShown is always true), so the bar tracks HasFocus instead - shows when the box gains focus, hides when focus leaves.

## 0.2.37 - 2026-11-23

- Input bar is now slightly transparent to match the chat panel (55% fill when the panel runs transparent, 80% otherwise). The client never hides its editbox so the bar is a permanent fixture - it has to blend in, not sit as an opaque slab over the world.

## 0.2.36 - 2026-11-23

- Input bar now actually appears: the show/hide fast path read f.editBox directly, but that field is not populated on every chat window on this client - anyEbShown stayed false forever and the bar never showed. It now uses FindEditBox with the global fallback like the rest of the module.

## 0.2.35 - 2026-11-23

- Input bar no longer permanently visible: the bar shows only when an edit box is open, hidden otherwise - same rhythm as the Blizzard default.
- Input bar restyled with the same panel template as the chat panels so it looks like a continuation of them, not a foreign element.

## 0.2.34 - 2026-11-23

- Edit bar completely rebuilt: previous versions rendered behind the panel (LOW strata invisible) or stacked conflicting layers. New bar lives at DIALOG strata level 5, slightly lighter dark fill (bgRaised), 1px border, gold hairline at top, 3px channel-coloured left strip. Fixed 26px height so the text, gold line and border all have room.

## 0.2.33 - 2026-11-23

- Edit bar now carries the gold top hairline the data bars use (inset past the corner arc), so the input strip reads as the same band family as the XP/rep bar above the panels.

## 0.2.32 - 2026-11-23

- Edit bar height now follows the Data Bars height setting (default 14px): the gold input strip, the XP bar and the rep bar all read as one uniform band. Gloss is anchored to the bar's center so it scales with the height.

## 0.2.31 - 2026-11-23

- Edit bar template switched from raised to inset: the thin gold wireframe on black read as a hollow rectangle. Now a dark recessed field - gold stays on the left accent strip and the corner ticks.

## 0.2.30 - 2026-11-23

- Edit bar restyled to the full Sentinel panel recipe: inner fade gradient (same as the chat panels), top-half gloss, left gold accent strip, corner ticks at the bottom, 26px tall and docked flush (1px gap) under the chat panel instead of floating loose.

## 0.2.29 - 2026-11-23

- The chat input is now a real styled bar: templating the Blizzard edit box directly rendered through its NineSlice as a thin black sliver. A dedicated SentiUIChatEditBar (dark raised fill, gold border, accent strip, 24px tall) sits behind the box; the box itself is transparent and fills it. Click the bar to focus, channel color now tints the bar's border.

## 0.2.28 - 2026-11-23

- Chat no longer jumps out of the panel on level up: the client re-anchors chat windows several seconds apart (banner, spec/spell toasts, floating text each trigger their own pass) and the old 1.5s burst only caught the first shove. The snap-back burst now runs 5s with full dock passes at 0.6s / 1.6s / 3s / 5s.

## 0.2.27 - 2026-11-23

- Scrollbars and scroll buttons no longer jump: Blizzard re-shows the chat ScrollBar, ScrollToBottomButton and the button-frame up/down arrows on scroll events, so they flickered back until the next 0.25s restyle tick. Each one now gets an OnShow -> Hide guard on top of alpha 0 - hidden for good.
- Edit box no longer jumps on open: Blizzard's header/resize passes re-anchor the edit box for a frame or two before the anchor watchdog caught it. A per-frame fast path re-anchors a shown edit box the same frame.
- Edit box polish: 6px text insets so the caret no longer hugs the border, plus the Sentinel gold accent strip on the left edge.

## 0.2.26 - 2026-11-22

- Chat tabs ride the generated `ChatTab`/`ChatTabActive` plates instead of a tinted blank fill — the active tab swaps to its own plate art, inactive tabs dim the same texture.

## 0.2.25 - 2026-11-22

- The loot window's floating channel tab is now hidden and taken off the mouse while the window lives inside the right chat panel - it poked out over the panel's top edge and clicking it toggled the whole chat frame off. Restored automatically if the window re-docks into a Blizzard dock.
- Loot window detection hardened: the frame itself is remembered and matched, plus the German "Plündern" label - a loot window whose tab label did not match was never docked into the right panel and floated loose with its tab sticking out.

## 0.2.24 - 2026-11-22

- Chat tabs now have a dark inset background chip (80% opacity active, 55% inactive) so the tab label reads clearly against the game world.
- Gold hairline at the tab bottom edge is now only visible on the active tab.
- Chat copy frame close button replaced with the shared W.Close.
- Bottom corner ticks fixed: the right tick hung 4px outside the panel edge; both are now mirrored and inset past the rounded corner arc.
- The panel fade layer is inset 7px so it no longer shows a dark square wedge behind each rounded corner.

## 0.2.23 - 2026-11-22

- Chat sizes scale for real now: neither frame:SetFont nor the Font object path reach a ScrollingMessageFrame on this client - the game's own wrapper FCF_SetChatWindowFontSize(nil, frame, size) is the path that works, and every size change (settings, installer, watchdog) goes through it now. The outline still applies via the Font object path when it differs.
- The watchdog re-pushes a drifted size only when the observed size actually moved, so a font API that never reflects the push cannot rebuild the chat lines every quarter second.
- The installer chat step no longer bails on an unready module - an empty step was cached forever; the controls now always render and write settings the module picks up when it runs.

## 0.2.22 - 2026-11-22

- Chat font sizes now actually apply: frame.SetFont silently does nothing on this client, so every size change (settings, installer, watchdog) went into the database while the visible size stayed whatever the game had cached. Fonts go through a real Font object via SetFontObject now, verified with GetFont, plain SetFont as fallback - the same reliable path the rest of the suite uses. Tab texts included.
- The watchdog no longer adopts a size that was never applied: a silent font failure used to be read back as a 'menu change' and overwrote the saved choice.
- The loot chat window reopens when it was closed by hand: EnsureLootChat shows the found window again and the dock pass re-anchors it into the right panel.

## 0.2.21 - 2026-11-22

- New installer step 'Chat': font size and tab font size sliders, the loot chat window toggle and the panel backdrop dropdown. Everything applies live through the module's setting path - every chat window (general, loot, whispers ...) takes the size immediately and the loot window is created and docked on the spot.

## 0.2.20 - 2026-11-22

- Default chat background came back after every reload: the frame styling ran once per frame and Blizzard's chat init finished after it, repainting the default background and buttons over the styled frame. The chrome kill is idempotent now and re-runs in the watchdog for every frame, plus a NineSlice/backdrop kill for backgrounds that are not plain regions.
- Font size arbitration after login: a mismatch seen in the first 15 seconds is Blizzard's chat-cache restore clobbering our application and gets put back to the saved size; a later mismatch is a live tab-menu change and is adopted into the settings. Before, the sync read the wrong GetFont return and never fired at all.
- The own-timestamp switch now uses C_CVar.SetCVar - the legacy SetCVar global is not guaranteed on this client.

## 0.2.19 - 2026-11-22

- Chat font size now persists no matter where it is changed: a size set through Blizzard's tab menu is written back into the module settings (0.25s watchdog, no Blizzard hooks), so the next login applies your choice instead of resetting to the default 12.

## 0.2.18 - 2026-11-22

- Loot lines now stay in the Loot window: every other chat window loses the loot, money and gain message groups - before, the same lines showed in the general chat and the Loot window at once.

## 0.2.17 - 2026-11-22

- New 'Loot chat window' option (on by default): a chat window named Loot is created automatically, stripped to loot, money and gain message groups only, and docked in the right panel - before, nothing ever created that window, so the right panel stayed empty.

## 0.2.16 - 2026-11-22

- Chat panels and the docked chat now re-run their sizing pass on DISPLAY_SIZE_CHANGED and UI_SCALE_CHANGED - before, a resolution or UI-scale change left the chat at its stale size until a manual resize.

## 0.2.15 - 2026-11-22

- Smiley pass fixes: codes now need real boundaries, so ':3' inside a '04:39' timestamp and 'xD'/'o.O' inside names no longer tear into icons - while a smiley glued to a word ('moment;)') still converts. New codes: xD, XD, D:, ;D, ;P, :o, :3, :|, :/, :*, >:(, :'(, :').
- URL fix: links created by the url pass were unmasked when the smiley pass ran - a smiley code inside a linkified url tore the |H markup. Fresh |Hurl links are masked before smileys now.

## 0.2.14 - 2026-11-22

- URL copy dialog, chat copy window and emote picker now use the own dialog/Escape handling instead of StaticPopupDialogs and UISpecialFrames.
- Removed the 'sticky channels' option: it wrote into ChatTypeInfo, and every addon-written value there taints the Enter dispatch that later calls the protected SendChatMessage. Channel stickiness now follows the client's own defaults.

## 0.2.13 - 2026-11-22

- Fix the edit box losing its style: NineSlice was alpha'd before SetBackdrop - the backdrop draws through NineSlice, so the raised fill/border never rendered (transparent bar with gold focus brackets). The watchdog now also retries styling for late-created edit boxes and re-hides the header chrome every tick.

## 0.2.12 - 2026-11-22

- All post-hooks on Blizzard layout and chat functions are gone (UIParent_ManageFramePositions, FCF_*, ChatEdit_UpdateHeader, tab clicks): they ran inside input/panel dispatches and tainted them - the probable source of blocked SendChatMessage and secret-compare errors when windows opened. One 0.25s watchdog now re-docks the chat, restyles new frames, re-colors tabs and edit box borders and re-anchors the edit box.

## 0.2.11

- Compile fix: UpdateKeywords assigned to the for-loop variable, which LuaJIT rejects as a const assign - the whole Chat.lua failed to load. Loop variable is now shadowed by a local.

## 0.2.10

- Chat copy window: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.

## 0.2.9

- Escape-forbidden-call fix: `OnEscapePressed` handlers on the URL popup and copy-chat window ran inside the Escape dispatch - both close natively via `hideOnEscape`/`UISpecialFrames` now.


## 0.2.8

- Fixed the `attempt to index global 't'` error on level ups: the
  snap-back ticker captured its handle before the local existed (Lua
  scope starts after the `local` statement), so the 15th tick indexed
  a nil global. The ticker variable is now declared before the
  `NewTicker` call.

## 0.2.7

- Fixed repeated errors on messages with secret sender values: the
  player-level filter guarded the message text but passed the raw sender
  into `ShortName`, which called `:gsub` on it - on this client the
  sender can be a secret value, so every such message threw. The filter
  now skips secret senders and `ShortName` returns nil for non-plain
  strings.

## 0.2.6

- Player links like `|Hplayer:Prinz Nexo:..|[Prinz Nexo]` no longer
  tear: the mask only matched `|H..|h label |h` pairs, but some link
  payloads are separated by a single pipe on this client, so `:P`
  inside `player:Prinz` stayed reachable for the smiley pass. A second
  mask pass covers leftover `|H..|h` payloads.

## 0.2.5

- Copy-chat window is now a real mover: move-mode entry + Movers.Save
  persistence, reopens where you left it.

## 0.2.4

- The chat frame no longer visibly jumps on level up: ChatFrame1's
  anchor is now re-asserted inside the same Lua pass via hooksecurefunc
  post-calls on the client's chat/dock positioning functions
  (FCF_SetWindowPosition, FCF_RestorePositionAndDimensions, FCF_DockUpdate,
  FloatingChatFrame_Update, UIParent_ManageFramePositions), a short burst
  check after PLAYER_LEVEL_UP, and the ignoreFramePositionManager
  attribute - instead of a delayed re-position 0.5s later.

## 0.2.3

- Fixed broken player links in chat (raw `|Hplayer` text and icon
  garbage in names): the hyperlink mask only matched links whose
  label contains a bracket, so player links like
  `|Hplayer:...|hName|h` stayed unmasked and the smiley pass cut
  ":P" out of names like "Priemelchen", tearing the whole link
  markup apart. All hyperlink labels now mask before the url/smiley
  passes.

## 0.2.2

- Fixed the chat frame jumping out of its panel after a level up: the
  client re-anchors chat windows on level ups and dock passes (the tabs
  stayed because they hang on the dock manager, the frame itself was
  moved mid-screen). `ChatFrame1` now re-docks whenever its anchor no
  longer points at the chat panel — checked once per second, skipped
  in combat — and `PLAYER_LEVEL_UP` triggers a delayed re-position
  after Blizzard's own pass settles.

## 0.2.1

- Quest references typed as plain text - `[19] Name (questID)` -
  are wrapped into real `|Hquest` hyperlinks so they can be clicked
  like normal links. Toggle: "Clickable quest links".

## 0.2.0

- Proper emoji palette: the old 7-icon row became a real grid -
  60 emotes in an 8-column panel with title bar, inset cells, hover
  accent and `:name:` tooltips. Classic smiley codes like `:)`
  or `<3` still render, now mapped onto the same icon set, and
  Discord-style `:name:` codes work too: type `:joy:`, `:fire:`,
  `:thumbsup:` and they render as icons.

## 0.1.9

- Rebuilt the channel, voice and chat-menu buttons as a proper
  strip: instead of sitting on Blizzard's default anchors half
  outside the panel, they are now 16px inset chips lined up in the
  tab row right in front of the emoji chip - dimmed until hovered,
  accent border on hover, re-anchored after dock updates so the game
  cannot pull them back.

## 0.1.8

- Fixed the regression from the scroll-chip rebuild: `HookScript`
  threw on script names this client does not know
  (`OnMessageScrollChanged`, possibly `OnHyperlinkEnter`/`Leave`) -
  that aborted `StyleChatFrame` mid-way so everything after the
  scroll chip (tabs, edit box, copy button, hyperlink tooltips)
  never ran. All `HookScript` calls on chat frames now go through
  `pcall`.

## 0.1.7

- Isolated every module enable step (panels, buttons, emoji, filters,
  scans, positioning) so a failure in one can no longer abort the
  rest - each now reports with its own `chat:*` tag so the failing
  piece is identifiable instead of leaving the whole chat unstyled.

## 0.1.6

- Hardened the whole style + position pass: every block now runs
  guarded so one bad frame can no longer skip the rest - which is
  what left the chat bar unstyled and unanchored. The edit box also
  resolves Blizzard's shared `ChatFrameEditBox` fallback, re-asserts
  its anchor on show and after `ChatEdit_SetLastActiveWindow` / dock
  updates, and secret-value reads in `GetRegions`/`GetFont`/
  `GetMaxLines` are `pcall`'d.

## 0.1.5

- Fixed the chat never docking into the panel: `PositionChat` died
  during enable - `FCF_SavePositionAndDimensions` was not wrapped and
  unnamed temporary chat frames could break the name lookups. Every
  frame now styles on its own, the dock manager and tab colors are
  guarded, so one bad frame can no longer take the whole layout down.

## 0.1.4

- The edit box now sits below the chat by default; existing profiles
  are migrated once. The position stays switchable in the options.

## 0.1.3

- Fixed the scroll-to-bottom chip doing nothing: Blizzard's own button
  was reparented, which broke its click handler. It is a proper SentiUI
  chip now that scrolls the frame itself and only shows while you are
  scrolled up.

## 0.1.2

- Fixed the copy chip: its text now fills the button and centers
  properly instead of spilling out.
- Emoticons: `:) ;-) :D :( :P <3 o.O ^^` render as the Sentinel pixel
  icons in chat, and a `:)` chip in the tab strip opens a picker that
  inserts codes into the edit box.
- Channel, voice and chat menu buttons are no longer hidden - they sit
  next to the chat dimmed until hovered, toggleable in the options.

## 0.1.1

- Panels now match the SentiUI look: the bordered dark panel every
  window uses, an accent hairline under the tab row and accent corner
  ticks at the bottom edge. "Fade at top" still switches to the plain
  transparent shade.
- The copy button became a proper readable chip (inset style, accent
  text, lit border on hover); the copy window got the accent title line.
- The scroll-to-bottom button is a dark chip with an accent arrow now.

## 0.1.0

- First release: Sentinel-styled chat for SentiUI - shade panels behind
  the dock (movable), restyled tabs with an accent underline, a
  borderless edit box above or below the chat that borrows the channel
  color.
- Message filter: short channel names, clickable links with a copy
  popup, keyword highlighting with an alert sound, timestamps in the
  panel color.
- Class-colored player names, player levels for known players, spam
  throttle, sticky channels, hyperlink hover tooltips, per-frame copy
  button and window, scroll-to-bottom arrow, optional chat history
  across reloads.
