# Changelog — SentiUI BugSack

## 0.2.3 - 2026-11-22

- Close button replaced: the Blizzard UIPanelCloseButton template (which carried its own styling and chrome) is replaced with the shared S.Widgets.Close — consistent with every other window in the suite.

## 0.2.2 - 2026-11-22

- The Current session / Archive view tabs use the shared Sentinel tab chip now: a 2px accent blade on the left edge marks the active view - one design language across the whole suite.

## 0.2.1 - 2026-11-22

- Wipe and archive-wipe confirms now use the shared own dialog instead of StaticPopupDialogs entries; the window closes on Escape via S.EscClosable. Removes addon-written entries from game tables the Escape dispatch reads.

## 0.2.0 - 2026-11-22

- Reworked: the list now shows only the CURRENT session by default - older sessions live in the Archive view as collapsible session groups (session -> addon -> error) instead of cluttering the side list.
- The archive keeps the last 25 sessions; older ones are pruned at load. A new Clear archive button empties it without touching the current session.
- Capture fix: every distinct addon+function blocked call is its own entry now - previously only the FIRST blocked call per addon per session was recorded.
- Guard against recursive capture so an error inside the grabber can no longer lock up the store.
- Export overlay covers the whole content area and exports what the current view shows; detail pane now carries a session/timestamp meta line.

## 0.1.6

- BugSack window: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.

## 0.1.5

- Blocked/forbidden action events are no longer stored as 'simple' entries: the grabber captures the full stack trace now, so the BugSack window shows which file and line triggered the blocked call.


## 0.1.4

- Escape-forbidden-call fix: the three `OnEscapePressed` handlers ran inside the Escape dispatch and tainted the engine's protected spell-stop calls - the window is in `UISpecialFrames`, so Escape closes it natively.


## 0.1.3

- Fixed the empty error list: the list scroll frame anchored its left
  edge twice (`TOPLEFT` + `BOTTOMLEFT`), collapsing it to zero width -
  every row was clipped invisible while the counter still showed the
  errors. The right edge is anchored properly now, so the grouped error
  rows and the detail pane render.

## 0.1.2

- Fixed the window never opening: the filter/nav buttons and the list rows
  were plain Frames (`S.Panel`), and this client rejects `OnClick` on a
  Frame ("script type not supported by this object"), so the whole build
  died on the first click handler. Buttons and rows are real Buttons now
  with the same panel styling, so the error list and detail view appear.

## 0.1.1

- Fixed an error flood: if window construction failed after the frame was
  created, every new captured error re-ran the half-built list renderer
  and threw again, feeding an endless capture loop until the flood
  throttle kicked in. The refresh path now hard-guards on a missing list,
  window build failures surface the real error once instead of staying
  silent, and the error-notify callback is pcall-wrapped so window bugs
  can never feed the grabber loop.
- Scroll frames degrade gracefully: `FauxScrollFrameTemplate` and
  `UIPanelScrollFrameTemplate` creations fall back to plain ScrollFrames
  if the templates are missing on this client.

## 0.1.0

- Initial release: a fully internal BugGrabber + BugSack for the SentiUI
  suite — no external error addons needed.
- The grabber installs the client's error handler (BugGrabber style:
  `seterrorhandler` is stubbed so nothing can replace it), listens for
  `LUA_WARNING` and `ADDON_ACTION_BLOCKED/FORBIDDEN`, deduplicates repeats
  into a counter, caps the store at 500 errors and tracks session numbers.
- BugSack-style window: All/Current/Previous session filters plus search,
  error list grouped and collapsible by addon, a copyable plain-text
  detail pane, prev/next navigation and wipe with confirmation.
- Export view selects the whole report in one box (Ctrl+A, Ctrl+C) so it
  pastes cleanly into the bug tracker at
  https://dev.xrl-dev.de/bugtracker — the hint sits in the window and the
  export pane.
- Slash commands: `/sbs` or `/bugsack` toggles the window, `/sbs wipe`
  clears, `/sbs export` and `/sbs export all` open the export,
  `/sbs <n>` prints error n.
- New errors can print a clickable chat line, play a sound and auto-open
  the window (never in combat) — all three are options under
  SentiUI > BugSack.
- The window is a real mover: drag it anywhere and it reopens where you
  left it.
