# SentiUI Bags

One clean, Sentinel-styled bag window — plus a matching bank window —
that replaces the Blizzard bag and bank frames entirely.

## Features

- **Bag slots strip** — equipped bags sit in a row above the grid (bags
  1–4 + reagent bag; bank bags in the bank window): drag a bag onto a
  slot to equip it, click an equipped one to pick it up, quality-tinted
  border and item tooltip
- **Unified grid** — all carried bags in one window, no per-bag frames
- **Bank window** — bank container, bank bags and reagent bank in a
  second window that opens with the game's bank
- **Categories** — items group under headers (New, Quest, Equipment,
  Consumables, Trade goods, Miscellaneous, Junk, Empty); can be
  switched off for one flat grid
- **New items section** — fresh loot lands on top first; the section
  clears when you close the window
- **Quality borders** — slot border takes the item's quality color
- **Overlays** — stack counts, item level on gear, junk mark on grey items
- **Search** — live filter box that dims non-matching slots
- **Sort** — toolbar button runs the client's bag / bank sort
- **Sell junk** — sells every grey item (toolbar button, or automatically
  when a vendor opens)
- **Auto repair** — repairs gear at repair-capable vendors, paid from
  your own gold by default; "Guild repair first" tries guild funds and
  falls back to your gold when not allowed
- **Footer** — free slots, backpack-tracked currencies and your money
  at a glance
- **Clicks** — left picks the item up, right uses it, shift links
  it, ctrl tries it on. Right-click item use *inside a fight* is a
  protected call the client only grants to its own bag buttons — a
  limitation every addon bag shares.
- **Movers** — both windows are movable; `/sui` → Bags for settings

## Settings

Everything is switchable under SentiUI → Bags:

- **View options** — search box, categories, new-items section,
  currency strip
- **Bags window / Bank window** — separate grids: slot size, spacing,
  columns, empty slots, quality border, item level, junk mark
- **Merchant** — auto-sell grey items, auto repair, guild funds first

## Notes

- Blizzard's container frames and `BankFrame` are hidden;
  `ToggleBag`/`OpenAllBags` and the game's bank events drive the
  SentiUI windows instead.
- Item usage goes through a hidden `SecureActionButton`, the same path
  the game's own buttons take.
- The "New" section uses the client's `C_NewItems` flags — items that
  are already marked as seen by the game just sort into their category.
