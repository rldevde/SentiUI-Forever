# Changelog — SentiUI Outfitter

## 1.1.0 - 2026-11-25

- SentiOutfitter is now a SentiUI module (SentiUI_Outfitter): it registers with the core, stores settings in `SentiUIDB.modules.Outfitter` and gets a page in `/sui`. Settings, saved sets and the bar position migrate from the standalone addon's saved variables on first load - nothing is lost.
- New `/sui` page: bar toggles (scale, combat alpha, names, vertical, lock), tooltip mode, sell protection, bag markers and the minimap button - all live-editable without `/so`.
- New `/so options` command opens the settings panel.
- Everything else stays: the quick-swap bar, the sets window, sell buyback protection, bag outfit badges, the minimap button and `/so`.
- Fixed: minimap button angle math used `math.atan2`, which does not exist on this client (`math.atan(y, x)` now).

## 1.0.2

- Reworked: the outfit window is now an Outfitter-style sidebar — it
  docks to the RIGHT of the character window at the same top edge and
  height, each row has a worn-checkbox, outfit icon, name and a menu
  arrow (right-click still works), plus a thin scrollbar.
- New: Outfitter-style "Outfits" toggle button pinned to the top of the
  character window (shown while "Open with character window" is on).
- Fixed: the worn marker no longer depends on who equipped the set —
  it uses the client's `isEquipped` flag, with a live item-location
  check as fallback. Outfits equipped via the game's own UI (or worn
  before a relog) are now shown as worn correctly.
- Fixed: icon picker was empty — the preset list contained plain icon
  names, not valid textures. The picker now collects real icon fileIDs
  from the outfit's items, equipped gear and bag contents (paged grid,
  mouse wheel to page). Icons can be changed again.
- Fixed: item states were wrong whenever the location-data helpers
  failed — all `EquipmentManager_GetLocationData` calls are now
  pcall-guarded with an `EquipmentManager_UnpackLocation` fallback.
- New: the list refreshes on `PLAYER_EQUIPMENT_CHANGED` and
  `EQUIPMENT_SETS_CHANGED`, so worn/missing state stays current.
- Fixed: missing-item "!" marker uses the `numMissing` return when the
  client provides it; row hover highlight added; context menu no longer
  opens off-screen on the right edge.
- Fixed: window title overlapped the drag hint; context-menu text no
  longer spills outside the box (menu width now fits the longest entry,
  gold accent line on top); Settings button widened so its label fits.
- Fixed: dropdown menus and dialogs never closed — they stayed on
  screen after the outfit window was hidden. All popups (menu, prompt,
  confirm, icon picker, slot picker) now close on ESC, on click
  anywhere outside, and when the outfit window closes.
- Fixed: settings panel was too short for its rows — "Reset position"
  overlapped the last option. Panel height now fits the row count and
  the reset button sits below the last row.
- New: full localization for every WoW client language — deDE, frFR,
  esES, esMX, itIT, ptBR, ruRU, koKR, zhCN and zhTW tables are loaded
  per client locale (enUS/enGB fall back to the English keys), and
  common buttons (OK/Cancel/Settings/...) use the client's own Blizzard
  strings. German text no longer leaks onto non-German clients.

## 1.0.0

- Initial release: outfit manager built on the native `C_EquipmentSet` API
  (per-character, compatible with Blizzard's Equipment Manager).
- Save current gear as named outfits, optional per-slot selection
  (partial outfits like weapon/trinket sets are supported).
- Rename, delete, custom icon per outfit.
- Outfit bar: draggable, horizontal/vertical, secure `equipmentset`
  buttons — weapon swaps also work in combat natively.
- Item tooltips show which outfits contain the item
  (bags, merchant, loot, inbox, quest, trade tooltips covered).
- Main window + settings panel in the Sentinel look (gold `ebad33`).
- Commands: `/so` or `/sentioutfitter` (open UI / wear outfit by name / `bar`).
- Fixed: tooltip init error when `GameTooltip.SetContainerItem` is
  unavailable — tooltip hooks are now installed only for existing methods.
- New: outfit window opens automatically next to the character window —
  detects Blizzard, DaylightUI, ElvUI or custom character UIs.
  Toggle in Settings ("Open with character window").
- Fixed: character-window watcher threw an error every tick
  (`IsShown` called without self), so the outfit window never opened.
- Reworked: the outfit window is now an Outfitter-style list that docks
  to the left of the character window — outfit rows expand to show the
  stored items with quality colors and per-slot state (equipped/bags/
  bank/missing), click wears the outfit, right-click opens the menu
  (Wear, Update with slot pick, Rename, Icon, Delete).
- Reworked: outfit bar got the Sentinel look (dark panel, 1px borders,
  gold manage button and gold edge on the worn set) and now docks to
  the right screen edge by default; fixed the double-scale bug that
  mis-sized the bar.
- Reworked: character-window detection now hooks OnShow/OnHide directly
  on known frames (DaylightUICharacter, PaperDollFrame, CharacterFrame,
  ElvUI) instead of relying only on polling; `/so scan` prints the
  detected character frames and their visibility for debugging.
- Fixed: `EnumerateFrames` is step-based on this client
  (`EnumerateFrames(prev)` returns the next frame), not an iterator —
  the `for` loop crashed the whole watcher, which is why nothing ever
  opened next to the character window.
- Fixed: the watcher hooked every enumerated character sub-frame
  (~100 slots/tabs/buttons); any child `OnHide` instantly re-hid the
  outfit window. Only window-level frames (width > 200) are hooked now,
  and visibility checks use `IsVisible` so hidden parents don't count.
- Fixed: `GetItemInfo`/`GetItemInfoInstant` don't exist as globals on
  this client — routed through `C_Item` with fallbacks. This crashed
  `GetSetItems`, so the outfit list rendered empty and New/Update/
  Rename/Icon/Delete appeared broken.
- Fixed: frame enumeration could hit frames whose `GetName` returns a
  non-string — type-guarded the name check.
- Fixed: bar buttons did nothing — the secure `type="equipmentset"`
  action isn't handled on this client, so clicks now also call
  `C_EquipmentSet.UseEquipmentSet` directly (idempotent if both fire).
- New: right-click on a bar button opens the outfit menu
  (Wear / Update / Rename / Icon / Delete) — same as the list.
- Fixed: `GetName`/`IsVisible`/`GetWidth` raise taint errors on
  protected frames (e.g. action-bar cooldowns) during the frame scan —
  all of these calls are pcall-guarded now.
- Fixed: all mutating `C_EquipmentSet` calls (save, update, rename,
  delete, icon) now go through a guarded wrapper that reports failures
  in chat (`C_EquipmentSet.X -> error`) instead of silently doing
  nothing; read calls (`GetItemLocations`, `GetIgnoredSlots`,
  `GetNumEquipmentSets`) are pcall-guarded too.
- Fixed: the manage "S" button was covered by a full-size gold overlay
  (looked like a solid tan square); it now has a clean dark face with
  a thin gold border. All bar buttons use crisp 1px borders, and the
  worn set keeps the gold edge.
- New: addon logo (`Media/Logo.tga`) is now used for the addon-list
  icon (`IconTexture`), the minimap button, the manage button on the
  outfit bar and the window/settings headers.
- New: minimap button (draggable around the edge, left-click opens the
  outfit window, right-click opens settings; toggleable in settings).
- Fixed: bar clicks hit other addons' buttons — the bar sat in the LOW
  frame strata, below action buttons (MEDIUM), which swallowed the
  clicks. The bar is now in the HIGH strata above action bars.
- New: sell protection — items that belong to an outfit can't be sold
  for good. Selling can't be blocked without tainting the secure bag
  code, so a sold protected item is bought back from the vendor's
  buyback list right away (same price) and a chat line tells you.
  Items are free to sell again once no outfit uses them. Copies beyond
  what an outfit needs (e.g. a spare of the same item) stay sellable.
  Tooltips show "Protected from selling"; toggle in settings.
- New: outfit marker on bag items — items that belong to an outfit show
  a small logo in the corner of their bag slot (Blizzard bags, ElvUI and
  DaylightUI; bank slots too). Updates on bag/equipment/outfit changes;
  toggle in settings ("Mark outfit items in bags").
- Fixed: item IDs were never resolved (`ItemIDFromLink` lost the second
  return value of `pcall`), so sell protection never knew which items to
  keep and nothing was bought back.
- New: `/so bags` prints how many outfit slots, bag buttons and markers
  were found plus the protected items, for debugging.
