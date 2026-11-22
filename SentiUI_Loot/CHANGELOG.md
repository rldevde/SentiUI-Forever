# SentiUI Loot

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
