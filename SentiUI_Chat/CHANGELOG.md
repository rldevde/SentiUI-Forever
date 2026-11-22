# SentiUI Chat

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
