# Changelog — SentiUI_Character

## 0.2.10

- Exposed the module API (Open/Close/Toggle per page) on the registered module so sibling addons can open exact window pages without calling the game's Toggle* bookkeeping functions.

## 0.2.9

- Removed the ShowUIPanel post-hook: it ran our window code inside every managed-panel open dispatch (spellbook, talents, map, friends...), tainting the client's follow-up panel management - other windows opened broken. The CharacterFrame visibility watcher now covers every open path (key, micro menu, API) and toggles our window instead.

## 0.2.8

- The parked Blizzard character frame now hides via S.WatchShown polling instead of an OnShow hook - the frame is shown inside the ShowUIPanel dispatch, where addon Lua taints the client's follow-up protected calls.


## 0.2.7

- Escape-forbidden-call fix: the `HideUIPanel` post-hook ran insecure code inside the Escape dispatch when panels closed - removed; our window is in `UISpecialFrames` and C toggles through `ShowUIPanel`, so nothing is lost.


## 0.2.6

- Stat panel moved: instead of a wide strip under the gear it is a
  tall column right next to the character model now (gear – model –
  stats – gear), full page height with scrolling. The window is a
  bit wider to fit it.

## 0.2.5

- Stat groups scrolled out under the window edge — the stat panel is a
  real `ScrollFrame` now, so long group lists scroll inside the panel
  instead of painting past the footer.

## 0.2.4

- Same color crash one line down: the item-name `SetTextColor` also
  failed when the quality color came back as a table or secret —
  channels are extracted first, defaults applied, and the call is
  `pcall`'d.

## 0.2.3

- Gear window no longer errors on the quality ring: this client's
  `SetVertexColor` takes a color object (`r,g,b` failed), quality colors
  may come back as a table or secret — the slot code now plain-checks
  every channel and tries both vertex-color forms.

## 0.2.2

- Pressing `C` opened the Blizzard window: the earlier load error aborted
  the module before its hooks were installed. The swap now hooks
  `ShowUIPanel`/`HideUIPanel` too, so any path that opens the character
  frame routes to our window.

## 0.2.1

- Fixed a load-time error when a stat API is missing on this client
  (e.g. `UnitDefense`) — all stat lookups now check the function exists
  before calling it.

## 0.2.0

- Tabs: the window now routes every character-sheet tab — Pet, Reputation,
  Skills, PvP, Currency and Statistics render inside our window when the
  client exposes the API; tabs without an available API keep the Blizzard
  window.
- Equipment sets: a "Sets" picker in the footer lists your
  equipment-manager sets and equips them (deferred out of combat).
- Slot clicks: left picks the item up, shift links it into the chat edit
  box, ctrl opens the dressing room, right/alt opens a small menu
  (pick up / link / dressing room).
- Enchant and gem markers: enchanted items show a green marker in the info
  line, filled gem sockets show blue diamonds.

## 0.1.0

- New module: the SentiUI character window takes over the character sheet
  when you press `C` (or the micro menu) — the Blizzard frame stays parked
  while ours is open.
- Gear columns in the classic layout: eight slots left (head…wrist), eight
  right (hands…trinkets), weapons along the bottom. Icons carry a quality
  ring, item name, item-level line and a red ring when durability runs low.
- Rotatable 3D character model in the middle; collapsible stat groups on
  the right (Attributes, Melee, Defense, Resistances); footer with total
  item level and overall durability.
- ESC closes the window via `UISpecialFrames`; combat-sensitive work is
  deferred; secret values are guarded throughout.
- Options under SentiUI › Character: item names, item level (line or icon
  corner), repair threshold, zebra rows, colored footer, stat groups.
