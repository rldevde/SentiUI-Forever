# Changelog

## 0.3.40 - 2026-11-23

- Mover snap-back fix: dragged frames returned to their default position because rect reads (GetCenter/GetSize) answer secret inside the drag/keyboard hardware handlers on this client, so the save silently skipped. Saves now run one tick later where reads are plain, fall back to storing the raw UIParent anchor when the rect is still unreadable, and M.Save (window title drags) defers the same way.
- Protected frames can be moved now: when a frame refuses StartMoving (born under combat lockdown) the drag handle moves instead and the frame is parked on its drop spot.

## 0.3.39 - 2026-11-22

- Design system overhaul: `S.Template` now gives `raised`/`gold` panels a soft Sentinel gold border tint. `PillReady` re-enabled — when `make_edges.py` has been run all panels get smooth rounded corners via edgeFile backdrop (no pixelated raster arcs). `S.SetBorderLit` restores the saved border colour on hover-off. `S.TabChip` shows a gold border when selected.

## 0.3.38 - 2026-11-22

- Short-frame chevron fix: `S.EdgeArc` now clamps its radius to half the host height at build time — a radius taller than the frame made the top and bottom quarter arcs overlap into pointed brackets instead of a smooth pill end.

## 0.3.37 - 2026-11-22

- Media pipeline disabled on request: `S.Tex()` returns nil and the pill-edge probe reports false, so every consumer falls back to its code-drawn look — panels and tooltips get the programmatic rounded-9slice raster again, the gold window edge is strips+arcs, bars/glyphs/widgets use blank fills and native art. No generated texture is loaded anywhere; the `Media\Textures` files stay on disk but unused.

## 0.3.36 - 2026-11-22

- Regenerated the edge-file media in-house (`make_edges.py`): the AI-delivered TGAs put a squashed full ring in slice 0, left the right/top/bottom edge slices empty and drew diagonal brackets in the corner slices — which is exactly why edges rendered as a fat band on one side plus corner stubs. The new `PillEdge`, `SquareEdge`, `TooltipEdge`, `GoldEdge`, `TargetRing`, `ThreatGlow` and `GlowEdge` follow the real 8-slice spec (L,R,T,B + TL,TR,BL,BR corners), supersampled for true anti-aliased lines — every panel, tooltip, threat ring and target ring now gets a proper closed border.

## 0.3.35 - 2026-11-22

- Own widgets ride the generated media: checkboxes use the `CheckEmpty`/`CheckOn` widget art (dark box, gold check) instead of an inset template + accent square, dropdowns show the `DropdownArrow` glyph instead of a text 'v', and slider thumbs carry the `SliderThumb` grip glyph.

## 0.3.34 - 2026-11-22

- Media wiring: new `S.Tex(name)` registry probes each shipped texture once via `GetFileIDFromPath` and returns the path only when the client resolves it — every consumer keeps a programmatic fallback. Tooltips now ride the `TooltipEdge.tga` edgeFile for a real border instead of the 1px flat edge.

## 0.3.33 - 2026-11-22

- Full texture suite: `make_media.py` now generates all 88 SentiUI interface textures into `Media/Textures/` — window/tooltip/glow/target edge files (8-slice 128x16, seamless rounded and square corners), panel/raised/inset fills, status-bar fills (flat, gloss, striped, segmented), control glyphs (checkbox, radio, slider, arrows, gear, lock), icon/button frames and masks, unit-frame overlays (absorb, incoming heal, threat glow, range fade), role/dispel/status icons, and suite furniture (minimap border, action-bar plates, chat tabs, toast card, logo mark). Every asset ships as uncompressed 32bpp BGRA TGA plus a PNG preview; tintable art is white+alpha so it recolors cleanly to the gold accent. A `_ContactSheet.png` in the same folder shows the whole set for review.

## 0.3.32 - 2026-11-22

- Rounded-edge media pipeline: `make_media.py` generates `Media/Textures/PillEdge.tga` — an 8-slice edgeFile with an anti-aliased quarter ring, a ~1px border and a dark inner band that doubles as a subtle inner shadow. Once generated, `S.Template` switches every panel, button, chip and skinned window from the programmed 1px-column raster to real texture borders with bilinear-smooth corners.

## 0.3.31 - 2026-11-22

- `S.CornerCut` gains a `subLevel` parameter: corner caps can now sit at OVERLAY sublevel 7, above regions created after the caps. Fixes a pixel artifact where the bar gloss overlay (created after the caps on unit frames) drew over them and poked a faint white tip into every rounded bar corner.

## 0.3.30 - 2026-11-22

- Edge arc pixel fix: `S.EdgeArc` covered each column as [arc top minus local rise, arc top], which left a gap in the ring's lower half on steep columns and overfilled elsewhere — visible pixel errors on the gold window edge and the unit-frame edge glow. Columns now cover the true band between the inner circle (radius minus stroke width) and the outer arc, keeping a constant ring thickness.

## 0.3.29 - 2026-11-22

- New core helper `S.EdgeArc` rasterizes a quarter-circle border segment (1px columns, any stroke thickness) — edge borders built from four straight strips (the gold window edge, the unit-frame edge glow) ended 7px before each corner and read as open stubs. The arcs close the outline into one continuous rounded frame.

## 0.3.28 - 2026-11-22

- WatchShown fix: a frame discovered already shown silently initialized its state instead of firing the transition, so the onShow callback never ran for the first-ever open — load-on-demand windows (auction house, collections, most modern panels) only got their skins from the second open on. The first observed shown-state now fires the callback; skins are idempotent so the extra run is safe.

## 0.3.27 - 2026-11-22

- Anti-aliased rounded corners: every S.Roundize corner column now carries a 1px sliver at the arc boundary whose alpha is the fractional coverage — the hard 1px staircase becomes a smooth, evenly rasterized curve. Panels, buttons, chips and every skinned Blizzard window get visibly softer corners, still fully programmed with no media files.
- New S.CornerCut helper: raster caps in the color of the surface behind a region cover the corner notch outside a quarter disc — the Roundize arc math inverted, with the same AA slivers. Makes any bar or icon read as a rounded rect; used for status bars and icon rounding.
- S.IconRound now delegates to S.CornerCut: icon corner caps get the anti-aliased edges too (portrait tiles, aura icons, action slots, roll cards).

## 0.3.26 - 2026-11-22

- TabChip label fix: removed the RIGHT anchor from the label FontString. The RIGHT anchor clamped GetStringWidth() to the button's current width (0 on a new chip), so every chip got sized to 22px and rendered as a featureless dark square without text. All chip-based tabs (Character, BugSack, Training, Journal, Blacklist, AccountInfo) now size correctly.
- S.Roundize rewritten: corner arcs are now rasterized in pure code as 1px columns (h(i) = sqrt(r² - (r-i-.5)²)) from WHITE8X8 — no external mask file can turn the rounded corners into dark boxes. The five straight pieces are unchanged; tinting runs through one flat f.roundPieces list.
- Corner strip anchor fix: WoW y-offsets run UP, not DOWN — the arc strips were parked outside the frame, drawing a floating dark nub at every corner of every panel and button (the 'four corner points' bug). They now sit inside the corner tile hugging the arc.
- Edge decorations inset: the installer top accent edge and the move-mode edit bar edge line now end on the straight edge (7px inset) instead of poking past the rounded corners.
- S.IconRound rewritten AGAIN — the MaskTexture rendered its oversized white circle as a visible blob at every icon corner on this client (the 'white corners' bug). Icon rounding now uses tiny raster caps in the slot's background color covering only the outer corner notch (the Roundize arc math inverted) — no mask, no file, worst case the icon stays square.
- S.IconRound relayout hook fixed: OnSizeChanged is not a supported script type on Texture objects (HookScript threw for every action slot, bag slot, cast bar and unit frame icon). The relayout now hooks the icon's host frame inside pcall.
- S.IconRound secret-dimension guard: aura-container icons report secret width/height — comparing them threw inside Blizzard's frame-creation dispatch. Secret dimensions now leave the icon square instead of comparing.
- Tooltip skin: GameTooltip, ItemRefTooltip, ShoppingTooltip1/2 and comparison tooltips now use the Sentinel look (dark background, 1px border, gold accent line at the top). Applied once at PLAYER_LOGIN via S.StyleTooltips().

## 0.3.25 - 2026-11-22

- New S.IconRound helper: covers an icon's square corners with background-colored arc pieces so the displayed icon appears softly rounded. Uses CircleMask.tga with inverse UV mapping relative to S.Roundize — the opaque circle center maps to the outer tile corner (covering the icon) and the transparent circle exterior maps to the inner tile corner (showing the icon body). Zero external media required.

## 0.3.24 - 2026-11-22

- S.Roundize UV fix: the previous UV coordinates mapped corner tiles to the transparent outer region of the circle mask, making every rounded chip visually identical to a flat box. Coordinates are now geometrically correct — each outer corner maps to UV (1,1)/(0,1)/(1,0)/(0,0) which are outside the circle, and each inner corner maps to the circle center UV (0.5,0.5), producing a proper quarter-circle arc of radius equal to the tile size.
- S.Template now uses the programmatic 9-slice (Roundize) as the default path when PillEdge media is absent — every frame, button, input, chip and panel gets rounded corners immediately on /reload without any external files. The PillEdge backdrop path is preserved for when the media is generated.
- S.SetBorderLit updated for Roundize-based frames: on hover the corner arcs glow to the accent color and the fill brightens; on leave they restore to the base fill. Backdrop-border frames continue to use the existing SetBackdropBorderColor path.
- Settings cards now carry a subtle 1px gold accent line along their top edge, giving each section a clear visual anchor without a heavy border.

## 0.3.23 - 2026-11-22

- Installer finish did not reload: the secure /reload overlay was built once at frame creation - if the installer first opened during combat, SecureReload returned nil forever, leaving a dead finish button. The overlay is now built lazily when the finish step shows.
- SecureReload is now completely script-free: the PostClick handler set via SetScript could taint the click dispatch the same way the old OnClick override did. Side effects moved out of the button (installer marks done when the finish step shows; the reload dialog stays visible until the reload fires).
- Installer game UI scale now persists: the client does not write the uiScale CVar to config-cache.wtf, so a plain SetCVar was gone after relog. The chosen scale is stored in SentiUIDB.general.gameScale and re-applied on every login.
- Settings resetting every login: the client loads SavedVariables too late unless told otherwise - modules enabled at PLAYER_LOGIN got fresh default tables and every options write went into them. All TOCs with SavedVariables now declare LoadSavedVariablesFirst: 1 so the stored data is present before any code runs (SentiUI, Panel, Training, Journal, Nameplates; BugSack and AccountInfo already had it).
- Escape-close windows no longer throw ADDON_ACTION_FORBIDDEN in combat: SetPropagateKeyboardInput is restricted during a fight on this client, so S.EscClosable and the mover arrow keys now guard the call (bail in combat, pcall otherwise). The keyboard only goes live once propagation actually took - a window opened mid-fight can no longer swallow the game's keys, and propagation resets on key-up/hide.
- The installer now persists the UI scale even when the slider is never touched: the current scale is stored at the scale step, so any completed run keeps the choice across relogs (the slider alone only fired on real changes).
- The finish page has a real visible secure button now: the old invisible overlay laid over Next ate the pointer (no hover feedback, dead-looking button) and a combat-time build failure left a silent no-reload finish. The secure button carries textures and a label (no scripts), Next is swapped for it on the last step, and the combat fallback keeps working.
- Modules can add installer steps: new SentiUI.Installer.AddModuleStep places them before the finish page.
- The finish button never fired its /reload: without the useOnKeyDown=false attribute the secure dispatch follows the key-down CVar and ignores the Up click. The button now registers both click phases, carries the attribute and is built the proven DaylightUI way - parented to UIParent, laid over Next one level up on show. Installer step build errors are printed to chat instead of showing as a mysteriously empty step.
- The installer pages are interactive now, ElvUI-style: the Modules step is a scrollable checklist that enables/disables every loaded module (applied with the finish reload), and the controls step carries buttons for move mode and the settings window.
- Module installer steps no longer cache a failed build: a step whose module was not ready yet showed up empty forever. Nil builds are retried on the next visit and the reason is printed to chat; the chat and minimap steps drop their enabled-guard entirely (controls that write settings a disabled module picks up later beat an empty page).
- The game UI scale is now a real setting: new "Game UI scale" slider under SentiUI > Interface, sharing S.ApplyGameScale with the installer's scale step (CVar + general.gameScale, re-applied on every login). Before, the game scale existed only inside the installer.
- Installer buttons no longer overlap: Back is anchored to Next's left edge instead of a fixed offset, and Next/Finish are wide enough for the localized "Finish & reload" label.
- New shared design language for small tabs and filter chips: S.TabChip builds a dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active tab. Adopted by the character window tabs, the BugSack view tabs and the filter chips of Training, Journal and the blacklist window - one system instead of scattered boxes.
- Soft rounded corners for every tab and filter chip - fully programmed, zero setup: S.Roundize assembles the chip body from nine texture pieces (four quarter-disc corners cut from the circle mask the minimap module ships, five straight WHITE8X8 pieces) instead of a backdrop fill - an overlay disc can never cut a square fill away, so the fill IS the nine pieces now. Chips round immediately on /reload; panels keep the flat look until the PillEdge media exists (`Media erzeugen (doppelklicken).bat` in SentinelUI-Tools).
- The script's target folder is created on the fly (it crashed on the missing Media\Textures directory before) and the media path points at the _forever_ SentiUI tree now.

## 0.3.22 - 2026-11-22

- Secure button clicks were still tainted: SecureReload and the panel/minimap secure rows replaced the template's OnClick via SetScript, which makes the whole click dispatch insecure - RunMacroText then gets flagged ADDON_ACTION_FORBIDDEN. The template's own handler now runs untouched everywhere (reload overlay, options button, confirm dialog, minimap submenu, panel plugin overlays, talent pill).

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
