# SentiUI Bags

## 0.4.16 - 2026-11-23

- Bags window opening then immediately closing at merchant: `MERCHANT_SHOW` fires `Core.Sync()` (via the `Bags.lua` event handler) AND `ns.Core.Open()` (via `Merchant.lua`). `Sync` calls `IsAnyBagOpen()` which reads the game's own bag frames — not our custom window — and returns `false`, causing `ApplyGameState(false)` to close the window a frame after it opened. Fix: `Core.forceOpen` flag set on `MERCHANT_SHOW` and cleared on `MERCHANT_CLOSED`; `Core.Sync` returns `ApplyGameState(true)` early when the flag is set.

## 0.4.15 - 2026-11-23

- Bags open at merchant: `MERCHANT_SHOW` now calls `ns.Core.Open()` unconditionally — the bags window opens alongside the merchant frame like the game's own behaviour (previously only opened when autoRepair or sellJunk was enabled).
- Auto-repair fix: `RepairAllItems` is now called via `securecall` (protected function on this client — plain `pcall` fails silently). `GetRepairAllCost` returning a secret value no longer silently aborts the repair; the call proceeds and the cost shows as "?" in the message.
- Repair toolbar button: hidden when `autoRepair` is enabled — manual repair is redundant when the auto path handles it. Toggling `autoRepair` in settings updates the button without a reload.
- Bag slot tooltip: hovering a bag slot now shows the bag's contents (up to 8 items, then "…") plus the assigned category label when a bag preference is set.
- Bag preferences: new "Bag preferences" settings group under SentiUI > Bags. Four dropdowns (Bag 1–4) assign a category to each bag — "Everything" (default) keeps the bag unrestricted. Preference is shown in the bag slot tooltip as "Holds: <category>".

## 0.4.14 - 2026-11-23

- Removed the own bank window entirely: `Bank.Enable` no longer calls `ns.Core.MakeWindow("bank", ...)`. The Blizzard `BankFrame` is no longer parked under the hidden holder in `Blizzard.Apply` — it stays visible and shows the client's native slot purchase UI ("Taschenplätze: … Kaufen"). The carried-bags window still opens alongside the bank via the `BANKFRAME_OPENED` event (same as the game's behaviour). `Bank.Open`/`Bank.Close` are safe no-ops when `Core.windows.bank` is nil.

## 0.4.13 - 2026-11-23

- Bank slot purchase: `securecall` applied to every candidate API before `pcall` — protected functions on this client refuse plain addon-context calls. Added `BuyBankSlot`, `C_Bank.PurchaseNextBankSlot`, `C_Bank.BuyNextBankSlot` to the API list. Fallback now scans `BankFrame` for its own `PurchaseButton`/`BuyButton`/`BankFramePurchaseButton` and programmatically clicks it, so the game's own purchase handler runs in the correct context.
- Removed `StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")` fallback — the dialog's `OnAccept` calls a nil function on this build.

## 0.4.12 - 2026-11-23

- Bank slot purchase crash: removed `StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")` from the fallback chain — the client's own `OnAccept` handler for that dialog calls a nil function on this build (`GameDialogDefs.lua:698`), so clicking "Buy" on the game's own confirm popup crashes. Now shows the hidden Blizzard `BankFrame` as the last-resort fallback; it carries its own working purchase UI.

## 0.4.11 - 2026-11-23

- Buy bank slots: new "Buy slot" toolbar button in the bank window. `Slots.BuySlot()` walks the full API fallback chain — `PurchaseSlot` → `BankFramePurchaseSlot` → `PurchaseBankSlot` → `C_Bank.PurchaseSlot` — and falls back to `StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")` or showing the hidden Blizzard `BankFrame` when no direct function exists. The bag-strip buyable slot highlight is unchanged; this adds a reliable explicit purchase path that works even when `GetNumBankSlots`/`PurchaseSlot` return secret or are absent.

## 0.4.10 - 2026-11-22

- Fix: using items straight from the bag window was blocked with `ADDON_ACTION_FORBIDDEN` (`UseContainerItem`). The item buttons were real game template buttons, but our own scripts were planted on them — custom `OnEnter`/`OnLeave` tooltip, an `OnDragStart` fallback hook, and the `S.IconRound` size hook. On this client an addon script on the button marks its whole dispatch addon-owned, so the protected use-call inside the game's own click handler was blamed on SentiUI_Bags. The buttons are now completely script-free; the template's native click/drag/tooltip paths do everything. Corner rounding on slot icons is dropped with it.

## 0.4.9 - 2026-11-22

- Bag slot icons now clip to soft rounded corners via the rewritten core S.IconRound MaskTexture — the icon itself is cut, so a failing overlay can never paint a dark box over it.

## 0.4.8 - 2026-11-22

- Bag slot icons now have soft rounded corners via S.IconRound — 4px background-colored arc pieces cover each icon's square corner.

## 0.4.7

- Bank slots are purchasable now: the bag strip in the bank window shows the next buyable slot with an accent border and its price in the tooltip; clicking it asks for confirmation and calls PurchaseSlot. Locked slots beyond the next stay hidden.

## 0.4.6

- Bag and bank windows: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.

## 0.4.5

- Removed the leftover bag diagnostics (trace buffer, /sbagtrace) now that the mirror is stable. Bank and merchant open/close work (window swap, auto-repair, auto-sell) now runs a frame outside the client dispatch - those dispatches carry secret values and item APIs called inside them can fail.

## 0.4.4

- Bag window mirror is hook-driven only now: the 0.15s state poll raced the client's multi-frame open sequence - IsAnyBagOpen can read false mid-transition, which flashed the window open and shut on some key presses. Every real open/close path already goes through the hooked bag functions, so the deferred mirror after them is the only driver.

## 0.4.3

- Followed the bag model proven elsewhere on this client: addon code never calls CloseAllBags/ToggleAllBags (their bookkeeping writes run tainted and break follow-up calls) - the game's containers are hidden directly like their own close buttons do. Window stays out of UISpecialFrames; hooks flag a batched mirror and the state poll keeps watching IsAnyBagOpen.

## 0.4.2

- Root cause of the instant close found via trace: the client's own UISpecialFrames walk hid the window a tick after it showed (it closes members it did not open), our WatchHide then called CloseAllBags and the state looped. The window is no longer a special frame - ESC still works because it hides the game's container frames, which the state poll mirrors. Containers are reparented again (the alpha ghost made the client flap the bag state).

## 0.4.1

- Fixed the bag window closing instantly on B: the reparented-under-hidden container frames were IsVisible=false, so the client treated them as closed, flipped its bag state back and hid our window in the close pass. They are ghosted instead now (SetAlpha 0 + mouse off, staying IsVisible and truthful to IsAnyBagOpen) plus a state poll - BAG_OPEN/CLOSED never fire on this client. /sbagtrace toggles a diagnostic trace.

## 0.4.1

- Dispatcher rollback: BAG_OPEN/BAG_CLOSED/MERCHANT_* events restored (the 0.15s poll is gone) and GameBagOpen is back to IsAnyBagOpen/IsBagOpen - the parked containers' IsShown read as always-hidden under the holder, so the bag window could never report open.


## 0.4.0

- Bag state is read from the parked container frames' own IsShown flags instead of IsAnyBagOpen/IsBagOpen: those can return secret or plain wrong values on this client, which dropped Sync to a blind toggle - each hooked call in the B-key chain toggled again and the window closed right after opening.

## 0.3.9

- Fixed the bag state poll never mirroring: the transition check tested an undeclared variable and could never pass, so the window only followed the bag-function hooks. Polling now tracks bagSeen correctly.

## 0.3.8

- Bag function post-hooks (ToggleBag, OpenBag, ...) now only set a flag - running our sync inside the client's keypress dispatch tainted the follow-up protected calls. The mirror runs from a 0.05s ticker.

## 0.3.7

- Bag, bank and merchant windows no longer use BAG_OPEN/BAG_CLOSED/BANKFRAME_*/MERCHANT_* events - those fire inside the client's protected window dispatch. Open/close state is now detected via GameBagOpen plus S.WatchShown visibility polling.


## 0.3.6

- Escape-forbidden-call fix: the bag window's `OnHide` hook ran inside the Escape dispatch (it is in `UISpecialFrames`) - the new-item cleanup now runs via `S.WatchHide` polling instead.


## 0.3.5

- Fixed dragging items out of the bags: the modern item-button mixin
  reads `BagID`/`SlotID` off the button itself, not the parent holder's
  `GetID`, so drag-pickup ran on a nil bag and nothing lifted. The
  fields are set now plus a fallback `OnDragStart` that calls
  `C_Container.PickupContainerItem` if the template did not - items can
  be dragged between slots and thrown out into the world again.

## 0.3.4

- Equipped-bag slots are back: both windows now show a strip of bag
  slots above the item grid (bags 1-4 + reagent bag; bank bags in the
  bank window). Drag a bag onto a slot to equip it, click an equipped
  bag to pick it back up - swap goes through the game's own
  PutItemInBag/PickupBagFromSlot so the client rules (non-empty bags,
  soulbound) apply natively.
- Slots paint the equipped bag's icon, tint the border by its quality,
  dim the empty-slot placeholder and show the bag's tooltip (or a hint
  on empty slots). BAG_SLOT_FLAGS_UPDATED refreshes them live.

## 0.3.3

- Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.

## 0.3.2

- Auto repair clarified and hardened: it pays from your own gold by
  default (enable "Guild repair first" only if you want guild funds
  tried first - it falls back to your gold when the guild bank doesn't
  allow it). The repair report now prints the full cost in
  gold/silver/copper, and guild funds are only attempted when you're in
  a guild and actually allowed to withdraw for repairs.

## 0.3.1

- Fixed the window creeping upward on every item click or bag update:
  the pixel-snap re-anchored the frame from measured screen coordinates
  (`GetLeft`/`GetTop`) on every layout, which drifts on this client. It
  now rounds the stored anchor offsets (`GetPoint`) instead - it
  converges after one half-unit nudge and can never accumulate.
- Fixed leftover ghost slots: buttons freed by a layout were never
  hidden because their parent is now the per-bag holder frame, not the
  grid.

## 0.3.0

- The last piece of the click puzzle: slots are now created as
  `ItemButton` frames, not plain `Button`s with the same template.
  On this client the mixin's click logic (pickup, use, sell, split,
  link/dressup) lives on the `ItemButton` class - a `Button` only got
  the look, which is why right click and splitting stayed dead and
  left click behaved oddly.

## 0.2.9

- Item clicks completely rebuilt: slots are now real
  `ContainerFrameItemButtonTemplate` buttons, so the game's own
  trusted click handler does everything natively - pickup, use,
  equip, sell at vendors, bank transfers, stack split, link/dressup.
  Custom handlers and the secure overlay are gone; that path could
  never work because protected actions only run inside game code.
  Bag id comes from the slot's holder frame, slot from its own ID -
  the proven recipe on this client.
- Bonus: the template's cooldown wheel is now driven (item cooldowns
  show on slots).

## 0.2.8

- Right-click sell for real this time: a transparent
  `SecureActionButton` now parks on top of the hovered slot, so your
  genuine right click lands on it (the way bag addons do it). It
  registers BOTH the down and the up click because the
  `ActionButtonUseKeyDown` cvar decides which one counts - registering
  only "up" is why the previous fix still did nothing. Overlay skips
  combat, modifiers and a busy cursor, and hides when the window
  closes.

## 0.2.7

- Right click works again - use items, equip, sell at vendors, move
  to/from the bank. Slots are now real `SecureActionButton`s
  (`type2="item"`): the previous hidden helper button was clicked
  programmatically, and the engine only runs protected actions on
  genuine hardware clicks. Left click pickup stays in `OnMouseDown`,
  which does not need protection.

## 0.2.6

- Fixed the strange "15:15" style numbers on slots: this client
  reports fractional item levels (15.15) whose decimal point looks
  like a colon at slot font size - the display is now rounded to
  whole numbers.
- Item level no longer appears on trade goods and consumables: the
  gear check now uses `GetItemInfoInstant`'s classID (weapon/armour)
  instead of an unreliable `GetItemInfo` return position.

## 0.2.5

- Quality borders now start at Uncommon (green) instead of Common -
  white is the Common quality colour, which drew a plain white box
  around most of the inventory.
- Fixed slot borders losing their top (or another) edge: the window
  now snaps its origin to whole pixels on every layout so 1px borders
  land on real pixels again.

## 0.2.4

- Fixed some item icons rendering blank or partial: the icon field is
  no longer filtered to numbers (texture paths were dropped) and the
  whole icon read+apply runs inside one pcall so secret values can't
  leave a half-painted slot.

## 0.2.3

- Bag and bank windows can now be dragged directly by their title
  bar; the position is persisted through the mover DB
  (`Movers.Save`) so unlock-mode moves and resets stay consistent.

## 0.2.2

- Fixed the bag key needing two presses and the window refusing to
  close: hooks no longer toggle blindly, they mirror the game's real
  bag state (`IsAnyBagOpen`) after each call.
- New close button in the title bar and ESC support; hiding the window
  also settles the game's bag state so the next key press behaves.
- Fixed the toolbar layout: proper title row, buttons size to their
  captions and the window never gets narrower than the search bar and
  buttons.

## 0.2.1

- Fixed the bag key doing nothing: the game's container frames are
  now parked under a hidden parent instead of hidden outright, so the
  client's bag open/close state stays truthful and toggles keep
  working.
- New `/sbags` command toggles the bag window directly; the window
  also follows the game's `BAG_OPEN`/`BAG_CLOSED` events when present.
- Hardened slot painting and junk selling against secret values
  (`isLocked`, `hasNoValue`, `quality`) so one unreadable field can no
  longer break the whole grid or the merchant button.

## 0.2.0

- **Bank window** — the game's bank opens a second Sentinel window
  (bank container + bank bags + reagent bank) with its own mover,
  sort button and search. The Blizzard `BankFrame` is hidden.
- **Categories** — items group under headers: New, Quest, Equipment,
  Consumables, Trade goods, Miscellaneous, Junk, Empty. Switchable for
  one flat grid.
- **New items section** — fresh loot lands on top first and clears when
  you close the window (client new-item flags via `C_NewItems`).
- **Currency strip** — backpack-tracked currencies show as icon +
  amount in the bags footer.
- **Per-view settings** — slot size, spacing, columns, empty slots,
  quality border, item level and junk mark are configured separately
  for the bags and the bank window (`bags.*` / `bank.*`).

## 0.1.0

- First release: one clean Sentinel-styled bag window replacing the
  Blizzard bag frames. Unified grid over all carried bags with
  quality-colored borders, stack counts, item level on gear and a
  junk mark on grey items.
- Search box dims non-matching slots live; toolbar buttons sort bags,
  sell every grey item at an open vendor and repair. Optional
  automations: auto-sell grey items and auto repair (guild funds
  first, then own gold) when a merchant opens.
- Right-click uses items through a hidden `SecureActionButton`,
  left-click picks them onto the cursor; shift-click links,
  ctrl-click dresses up. The window is a mover.
