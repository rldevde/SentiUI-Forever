# SentiUI Professions

A professions window in the SentiUI look: the game's trade skill keeps
running underneath (its `ProfessionsFrame` stays parked, alpha 0, so its
`OnHide` still closes the trade skill) while this window stands in for it.

## Features

- **Recipe list** on the left: search, `Skill-ups` / `Have materials`
  filter chips, the profession's own inventory-slot filter for gear
  professions, collapsible categories (folds are saved), favorites in
  their own section on top. Rows show the icon, the name in its
  difficulty color (or the crafted item's rarity), the materials
  underneath, and how many can be made.
- **Right-click a recipe** to favorite/unfavorite it or track it —
  the game's own functions. With Auctionator loaded the menu also
  offers **Search reagents (AH)**.
- **Recipe page** on the right: icon and name, the skill-up chance
  line, the crafted item (hover for its tooltip), every reagent with
  owned/needed counts (red when short), and the cooldown when there is
  one.
- **Linking** like the game's window: hovering a reagent row shows
  the item tooltip; shift-click on a reagent, the output item or a
  list row pastes the link into the chat box. Recipe links are built
  by hand (`enchant:<id>` + real name) — the client's `GetRecipeLink`
  renders the generic craft spell name.
- **AH search** (needs Auctionator): a button on the recipe page
  searches the auction house for every material of the shown recipe
  via Auctionator's `MultiSearch` API — the addon's own button can't
  appear since it hooks the parked Blizzard frame.
- **Stable scroll**: the list keeps its scroll position across
  refreshes (crafting, bag updates, learned recipes); it only resets
  on a profession switch.
- **Create footer**: Create, an amount stepper (`-` `n` `+`, mouse
  wheel), Create all — and while casting, a progress bar with
  "Making x of n" and Stop.
- **Profession tabs** under the title switch professions by casting
  the profession's spell through a secure button, like the game's own
  tabs. In combat they call `OpenTradeSkill` from the click instead.
- **Unlearn** sits beside the skill bar for primary professions, with
  the game's confirm popup.
- **The Professions key (K)** opens the last used profession in this
  window via an override binding that casts its spell; pressing it
  again closes the window.
- **Lent back**: the guild list, NPC crafting and linked professions
  keep the game's own window.

## Notes

- Draggable by the title area; the position is saved as the
  `professions.window` mover (`/sui unlock` to move it that way too).
- Options live under **SentiUI > Professions**; the window can be
  disabled to get the game's window back.
