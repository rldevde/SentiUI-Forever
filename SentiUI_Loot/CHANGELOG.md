# SentiUI Loot

## 0.2.19 - 2026-11-24

- Loot feed exit animation: expired rows now fly off to the screen edge while fading - direction is a setting (Row exit: right / left / fade in place). The flight distance is measured once from the row to the chosen edge and eased in, so the row accelerates off-screen exactly as its alpha dies. Merge resets and right-click dismisses use the same run.


## 0.2.18 - 2026-11-23

- Blizzard loot window gone for good: the alpha/mouse kill could still lose to a Show() path that re-alpha'd the frame. LootFrame now gets its loot events unregistered (LOOT_OPENED/LOOT_READY/LOOT_SLOT_*) so it never learns about loot at all - every loot-replacement UI kills it this way. LOOT_BIND_CONFIRM stays registered so BoP pickups still auto-confirm; turning our window off re-registers the events and restores the frame.

## 0.2.17 - 2026-11-23

- Blizzard loot frame no longer flashes visible: the alpha/mouse kill only ran a frame after the game showed it (deferred via C_Timer + the shown watch). It now fires synchronously inside every loot event dispatch and via hooksecurefunc on LootFrame_Show/LootFrame_Update, so the frame is neutralised inside the same pass it is shown in.

## 0.2.16 - 2026-11-22

- Fixed the double loot window: the alpha/mouse kill on the game's LootFrame only ran inside a shown-state watch registered at enable time — a lazily created LootFrame (load-on-demand on this client) never got a watcher, so both windows stayed open. The kill now runs on every own-window update and the watch uses the resolver form that catches late-created frames.
- Roll panel finishing: the scroll frame's scrollbar is actually anchored now (the UIPanelScrollFrame template leaves it unpositioned on this client) - it sits in the right gutter the frame reserves.
- Mouse wheel on a roll card forwards to the panel scroll; roll glyph buttons show Need/Greed/Disenchant/Pass tooltips.
- LOOT_ROLLS_COMPLETE clears all pending rolls at once instead of waiting for each card's timeout check.

## 0.2.15 - 2026-11-22

- Roll cards now show the item tooltip on hover: the card frame never enabled mouse input and the icon is a plain texture that cannot take scripts, so hovering a party/raid roll showed nothing. The card takes the hover itself and paints the item tooltip from the cached roll link; hovering also lights the card's border edge.

## 0.2.14 - 2026-11-22

- Fixed the recurring question-mark icons while looting: item data arrives async on this client, so the first draw often found nothing cached. A new RetryIcon helper (Item:CreateFromItemLink + ContinueOnItemLoad) re-resolves the icon once the item lands in the cache — applied to loot window rows, roll cards and the loot feed, with a suiIconLink guard against stale callbacks on recycled rows.
- Loot window close button replaced with the shared W.Close — consistent Sentinel look.

## 0.2.13 - 2026-11-22

- Roll card icons now clip to soft rounded corners via the rewritten core S.IconRound MaskTexture — the icon itself is cut instead of being covered by overlay tiles.

## 0.2.12 - 2026-11-22

- Loot history close and clear buttons replaced with shared W.Close / W.Button — consistent Sentinel look.
- Roll card icons have soft rounded corners via S.IconRound (4px radius).

## 0.2.11 - 2026-11-22

- Loot icons finally show: the quality border was created on the OVERLAY layer and painted as a solid square on top of the icon - every item looked like a plain quality-colored box (roll cards, loot rows, feed rows, Blizzard button styling). The ring now sits on the BORDER layer so only the 1px frame peeks out.
- Roll button glyphs: a missing glyph texture (the disenchant sheet on this client) rendered as a grey box because SetTexture keeps dead paths. Glyph paths are now probed via GetFileIDFromPath when available, with fallback candidates and the letter fallback if nothing resolves.

## 0.2.10 - 2026-11-22

- The own loot window no longer dies instantly: hiding the game's LootFrame triggered its OnHide -> CloseLoot(), ending the loot session the moment it opened. The frame now gets alpha 0 and its mouse killed instead of hidden - the session stays alive, invisible.
- Icons actually verify now: SetTexture silently drops secret/bad values on this client, so every icon (loot rows, roll cards, feed) is checked with GetTexture after setting and walks fallbacks - slot data, the game button's own icon, C_Item.GetItemIconByID, GetItemInfo, then a question mark.
- The normal-loot modifier works again: IsModifiedClick can answer falsely on this client, so the held check reads the configured AUTOLOOTTOGGLE key via GetModifiedClick and tests the raw key state instead.
- The group roll panel is a real Sentinel card now: the client's roll frames are hidden and click-dead while our cards show icon + quality border, quality-colored name, an accent countdown bar and the dice/coin/disenchant/pass glyphs - clicks go through RollOnLoot, rolls vanish when resolved.

## 0.2.9 - 2026-11-22

- Loot window stayed closed with leftovers: LOOT_CLOSED hid it blindly. A full bag ends the session with items still inside - the window now re-checks a frame later and stays open while anything remains.
- Loot window icons could vanish: a secret icon return made SetTexture fail silently. Secret values are skipped and the icon falls back to C_Item.GetItemIconByID.
- Fast and normal loot side by side: 'Always fast loot' now yields to your autoloot modifier - hold it to loot by hand, and the window gets a 'Loot all' button for manual sessions.

## 0.2.8 - 2026-11-22

- The loot window now registers its mover at module enable, not on the first loot - before, it had no handle in move mode until you had looted once. The handle also only shows while the own loot window is enabled.

## 0.2.7 - 2026-11-22

- Window now closes on Escape via the shared S.EscClosable helper instead of a UISpecialFrames entry - addon-written entries in that game table taint the Escape dispatch, which made protected calls (spell stop, reload) fail and get blamed on the addon.

## 0.2.6

- Interface-dispatch audit: hiding the Blizzard loot frame and refreshing the custom window no longer run inside LOOT_* events or the frame's OnShow - a visibility watcher and deferred calls do the work one frame outside the dispatch. Auto-loot slot pickup is deferred the same way.

## 0.2.5

- Dispatcher rollback: LOOT_READY/LOOT_OPENED/LOOT_SLOT_*/LOOT_CLOSED events and the OnShow hook that re-hides the Blizzard loot frame are back - the GetNumLootItems/visibility polling is removed.


## 0.2.4

- LOOT_* events and the Blizzard LootFrame hooks were replaced by GetNumLootItems/visibility polling - running addon code inside the client's loot dispatch tainted follow-up protected calls.


## 0.2.3

- Roll panel: active rolls are re-homed into a Sentinel panel docked
  directly beside the loot window (the items) - or the game's loot
  frame, falling back to the roll mover's position. One deterministic
  column, oldest roll on top, scrolls past 3 cards via scrollbar or
  mouse wheel over the panel and the cards.

## 0.2.1

- Title-drag saving now goes through Movers.Save (nearest-anchor
  format + MoversChanged) instead of a manual center offset that mixed
  frame-space and UIParent-space coordinates.

## 0.2.0

- Own loot window: a Sentinel panel replaces the game's loot frame —
  every slot as a row with a quality border and colored name, a click
  loots it, hover shows the tooltip. It's a mover; the game's window
  hides while the option is on.
- Loot feed: your recent loot as small fading rows (items stack by
  count, money pools on one row, hover shows the tooltip, right-click
  dismisses). Self-loot is matched through the game's own format
  strings, so it works in every language. Mover, plus row-count and
  hold-time settings.

## 0.1.0

- First release: fast loot takes every slot the moment the loot window
  opens, respecting the autoloot modifier unless "always" is set.
- Chat filter hides loot spam: item messages below a chosen quality and,
  optionally, coin lines.
- Loot log window (`/slootlog`): every loot line with an item is kept
  across sessions, item links stay clickable, scrollable, with a clear
  button.
- Sentinel skins: dark panel and quality-colored icon borders on the
  loot window; quality border plus tinted need/greed/pass/disenchant
  buttons on the group roll frames.
