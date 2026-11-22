# Changelog

## 0.3.21 - 2026-11-22

- Reload fix everywhere: C_UI.Reload/ReloadUI is a protected call on this client (ADDON_ACTION_BLOCKED: Reload()). New S.SecureReload helper lays an invisible SecureActionButton running the secure /reload macro over the real button - used by the installer's Finish step, the options 'Reload the interface' button, the options reload-confirm dialog (secureAccept) and the minimap menu's Reload entry.

## 0.3.20 - 2026-11-22

- Installer rework: the wizard has an interactive step area now. New 'Interface scale' step with a live slider and a Recommended button that picks the scale matching your resolution; the last step's Finish button reloads the UI (C_UI.Reload) so every setting takes effect cleanly.

## 0.3.19 - 2026-11-22

- New shared helpers: S.EscClosable (Escape-close without a UISpecialFrames entry) and S.Dialog (own confirm/prompt dialog). All core windows (settings, installer, movers) converted - addon-written entries in UISpecialFrames/StaticPopupDialogs taint the game's Escape dispatch, which is what made protected calls fail and get blamed on the addon.
- The 'reload required?' confirm and the options reset confirm now use the own dialog (the reload still goes through C_UI.Reload).

## 0.3.18 - 2026-11-22

- Reworked the combat deferral: the core no longer wraps ShowUIPanel/HideUIPanel/ToggleFrame or the Toggle* keybind functions - every wrapped call ran addon code inside the caller's dispatch and tainted it, which is what blocked Reload() in the addon list, SpellStopCasting() on Escape and secret comparisons when panels opened.
- Blocked window opens are now recognized inside the dead dispatch's stack (binding chunk, Toggle* name or panel file) and queued for after combat - same feature, zero taint.

## 0.3.17 - 2026-11-22

- Forbidden-call reports now name the event the blocked call really ran inside; the dispatcher used to overwrite it with the blocked event itself.
- A blocked call raised while reporting another one stays silent in chat; BugSack still records it.
- When every stack frame is core machinery, the report names the real call line instead of the dispatcher line.

## 0.3.16

- Compile fix: the combat-deferral entry used '...' inside a non-vararg function - LuaJIT rejects the whole file at load, so the entire core (and with it every module) failed to initialize. LuaJIT now compiles the suite clean; a full compile sweep also caught the same class of bug in Journal, Chat, SentiLayer and My-Social.

## 0.3.15

- Combat deferral, full coverage: ShowUIPanel, HideUIPanel and ToggleFrame join the queued path, so micro-menu buttons and every other open path defer in combat too (deduped per frame - a double ToggleFrame would undo itself). Every suite window is now flagged for combat deferral: BugSack, Character, Messenger hub/card/copy, bags+bank and the chat copy window join settings, blacklist, training and journal - they defer their open, hide on combat start and return after.

## 0.3.14

- Combat window deferral: opening a managed window mid-combat dies to ADDON_ACTION_FORBIDDEN on the client's protected FrameShow, so Blizzard key toggles (character C, spellbook K, talents N, quests L, map, friends, guild, pvp, calendar, help, group finder...) now queue the open for after combat with a chat note - and fire only when the window is still closed. Flagged own windows behave the same via S:CombatDeferWindow: Show() in combat defers with a note, an open window hides on combat start and returns after. Flagged so far: settings, panel blacklist, training, journal.

## 0.3.13

- Forbidden-action reports dig one frame deeper and name the dispatching event: core machinery frames (OnEvent dispatcher, SafeCall/S.Call wrappers) are skipped so the site points at the real module file.lua:line, and the report now includes "during EVENT_NAME" when a client event was being dispatched inside the blocked call.

## 0.3.12

- Forbidden-action site reporting fixed: the handler's own frame was the first Lua frame on the debug stack, so reports always pointed at Core.lua:257 instead of the real culprit. The topmost frame is now skipped and the next SentiUI frame below the event dispatch is named - the next ADDON_ACTION_FORBIDDEN report shows the actual file.lua:line that ran inside the protected dispatch.

## 0.3.11

- Central call-site reporting: S.Call (labelled pcall) and S.SecureAPI (securecall lane) live in the core now - every current and future module gets 'file.lua:line' reporting for failed or blocked engine calls for free. Module wrappers delegate to it.


## 0.3.10

- Forbidden-action reports now name the call site: ADDON_ACTION_BLOCKED/FORBIDDEN fires synchronously inside the blocked call, so the handler reads debugstack and prints the first SentiUI frame (file.lua:line) next to the blamed addon - an UNKNOWN() blame is no longer anonymous.

## 0.3.9

- WatchPump treats a non-boolean IsShown answer (error or secret) as unknown, not hidden - it could otherwise fake a shown->hidden transition that never happened.

## 0.3.8

- WatchPump hardened: a frame resolver or IsShown call that errors no longer kills the whole visibility watcher loop - every watched window after it stayed dead (bank, merchant, loot re-hide).

## 0.3.7

- Added S.WatchShown: central ticker-based visibility-transition watcher (shown and hidden callbacks) for Blizzard windows that may open/close inside a protected dispatch.


## 0.3.6

- Escape-forbidden-call hardening, suite-wide: the shared edit box lost its `OnEscapePressed`/`OnEditFocusLost` handlers (they ran insecure Lua inside the Escape dispatch and tainted the engine's protected SpellStopCasting/SpellStopTargeting calls), the lit border now resets from a focus-poll timer, and new `S.WatchHide` replaces `OnHide` scripts on Escape-closed windows - movers bar included.


## 0.3.5

- Changelog page gets module categories: a filter dropdown on top lists
  every addon that filed entries (All modules, SentiUI, each `SentiUI_*`
  module) and narrows the cards to the picked module.

## 0.3.4

- Changelog/settings page fixed: text rows stayed at a fixed 26px height
  while long changelog lines wrapped onto two or three lines - entries
  drew over each other. Text rows now measure the wrapped label height
  (explicit width + word wrap) and grow to fit, control rows stay
  single-line.

## 0.3.3

- New shared `S.LevelColor(unit)` helper: maps the unit's server-side
  content difficulty through `GetDifficultyColor` - real difficulty
  colors for level text, secret-safe.

## 0.3.2

- Mover hardening: a throwing snap pass could kill the drag-stop
  handler before the save ran - moved frames looked placed but snapped
  back on the next apply/reload. Snap is now pcall'd, UIParent
  rect/size reads are secret-guarded, and NearestAnchor returns nil
  instead of a fake {BOTTOMLEFT,0,0} so unreadable rects skip the save
  rather than parking the frame in the corner. M.Apply on an unknown
  key no longer indexes nil; proxy movers would save the handle's rect.

## 0.3.1

- New SentiUI artwork: `Media/Logo.tga` (Alliance/Horde emblem,
  1024x1024) replaces the previous logo so the minimap button,
  installer and settings title band pick it up automatically;
  `Media/LongLogo.tga` (1024x512, letterboxed) is exposed as
  `S.media.longLogo` + `S.media.longLogoBand` and shown as a hero
  banner on the settings Home page.

## 0.3.0

- Settings search upgraded: result clicks now scroll to and flash the
  matching option (Panel.Reveal), page titles are searchable, the
  results header shows the hit count, Enter jumps to the first result,
  and the search field gets a gold accent edge.
- `strtrim` fallback guards the search filter on clients where the
  FrameXML util is missing.

## 0.2.9

- New `S.Movers.Save(key)`: persists a directly-dragged frame position
  through the mover DB so `Apply`/`Reset` stay authoritative (used by
  the bag windows' title-bar drag).
- The 0.2.8 font-object change (`S.ApplyFont`/`S.FontObject`) is now
  also listed in the in-game changelog.

## 0.2.8

- `S.ApplyFont` / `S.FontObject`: text now gets a real Font object via
  `CreateFontFamily` + `SetFontObject`, verified through `GetFont` -
  plain `SetFont` can silently do nothing on this client, which left
  FontStrings fontless and invisible. `S.Font` routes through it, so
  every module's text benefits.

## 0.2.7

- Widget buttons no longer throw on non-string captions: `Button:SetText`
  ignores secret values and coerces anything that is not a string or number
  to empty. Fixes `bad argument #1 to 'SetText'` in the first-run installer.

## 0.2.6

- Error output now prints a one-time-per-session hint to report problems at
  https://dev.xrl-dev.de/bugtracker - shown after Lua errors (`S.SafeCall`)
  and `ADDON_ACTION_FORBIDDEN`/`ADDON_ACTION_BLOCKED` reports. Localized
  (en/deDE); modules get it for free via the shared core handler.

## 0.2.5

- Buttons and installer steps tolerate nil text now - no more
  "bad argument to SetText" when a step or label resolves empty.

## 0.2.4

- Error radar fully hardened: error messages that are themselves secret
  values no longer break the xpcall handler ("error in error handling"),
  and the forbidden-call report labels addon vs. function correctly.

## 0.2.3

- Fixed the error radar itself: `debug.traceback` does not exist on this
  client - `S.Stack` now uses `debugstack` (pcall-guarded with a
  `debug.traceback` fallback), so real errors print their traceback instead
  of "error in error handling".
- New `S.IsSecretTable` helper (`canaccesstable`/`issecrettable`): indexing
  a secret table throws before `IsSecret` can see a field.

## 0.2.2

- New in-game changelog: SentiUI > Changelog lists the release history of
  the core and every module, in the client's language (English + German).
  Modules file entries via `changelog = ns.CHANGELOG` in RegisterModule;
  `S.Changelog.Register(name, entries)` for anything else.

## 0.2.1

- Error radar: SafeCall failures now print the Lua traceback with
  Interface/AddOns/<file>:<line>, and ADDON_ACTION_FORBIDDEN /
  ADDON_ACTION_BLOCKED are reported in chat with the blocked function
  name and the addon the client blames.

## 0.2.0

- Mover rewrite on the proven SentinelForeverCore approach: real frames
  move via SetMovable/StartMoving, positions save as nearest screen
  anchor, handles are UIParent overlays, hidden frames stay grabbable,
  selection + arrow-key nudge.

## 0.1.0

- First release: settings shell for the SentiUI suite.
- Minimap button (left click: settings, right click: move mode, drag: reposition).
- Options window with section/page navigation, search, and card groups.
- Option item types: toggle, slider, dropdown, color, button, text, custom.
- Module registry: `SentiUI_*` addons dock their own option pages in via
  `SentiUI:RegisterModule(...)` (see API.md).
- Mover system: `SentiUI.Movers.Register`, move mode with labeled handles,
  grid + edge snapping, mouse-wheel scaling, per-frame reset.
- `/sui` (or `/sentiui`) opens the settings, `/sui unlock` toggles move mode.
- First-run installer wizard (`/sui install`, re-runnable from SentiUI > Home);
  modules can append steps via `SentiUI.Installer.AddStep`.
- Test frame for move mode (SentiUI > General > "Show test frame") plus a
  mover counter in the move-mode bar.
- Move mode reworked: screen dim + readable grid, a larger bottom edit bar
  (mover count, hints, Lock button), ESC leaves the mode, the settings
  window reopens on lock if it was open, and an unlock failure can no longer
  leave a half-on state.
- Buttons now grow to fit their label; long localized text no longer
  overflows the button borders.
- Native API pass: reload uses `C_UI.Reload()` (plain `ReloadUI` is
  protected on this client), `table.unpack`, `C_CVar` for module cvars,
  `math.atan` for the minimap button drag.

## 0.2.0

- Mover system rebuilt on the proven SentinelForeverCore mechanics for this
  client: the real frame is moved with `SetMovable` + `StartMoving`, handles
  live on UIParent (TOOLTIP strata, minimum grab size, so hidden and tiny
  frames stay placeable), and positions are stored as the nearest screen
  anchor (`point` + offsets in UIParent space) with effective-scale
  conversion on restore.
- Every `GetSize`/`GetCenter`/`GetPoint` read is secret-guarded (`IsSecret`)
  before it hits arithmetic - protected widgets return secret values here.
- Reset now restores the frame's original anchor live (captured with
  `frame:GetPoint(1)` at registration) - no reload needed.
- New mover extras: selected handle highlight, arrow-key nudging
  (Shift = 10px), and handles stay available for hidden frames.
