# SentiUI Action Bars

Action bar module for the SentiUI suite (WoW Forever client). Requires
`SentiUI`. Disable other full UI replacements while it runs.

## Bars

- **Bar 1** — paged main bar. A secure state driver follows druid forms,
  warrior stances, rogue stealth, priest shadowform, monk/evoker bonus
  states, vehicles, override and possess bars, plus manual paging
  (`bar:2/3`). Works in combat; no taint.
- **Bars 2–4** — static extra bars on the free pages 4–6 (this client's form
  pages share the side-bar slots). Bars 2–4 hide while empty by default;
  bar 4 is the vertical side bar.
- **Pet bar** — secure `type="pet"` buttons plus the auto-attack marker.
- **Stance bar** — forms/stances read from the client's own `StanceButton*`
  and clicked through via `/click`. The slot count is capped at
  `GetNumShapeshiftForms()`, so it appears only once real forms/stances are
  learned and grows automatically.
- **Totem bar** — four `GetTotemInfo` slots with cooldown sweep;
  right-click destroys a totem (shaman only).
- **Extra buttons** — movable holders for the quest extra action button,
  zone ability, vehicle seats, talking head, loot rolls, alerts, mirror
  timers and loss of control; plus a secure vehicle exit button
  (`/leavevehicle` with a `[canexitvehicle]` driver) and a taxi
  "land at the next stop" button — both show Sentinel icon textures.
- **Mover-frame skins** — TalkingHead, mirror timers and the vehicle
  seat indicator lose their Blizzard chrome and gain the dark SentiUI
  panel; large screen texts (zone/subzone announcements, raid warnings,
  boss emotes, UI errors) use the SentiUI font with accent coloring.
- **Blizzard leftover skins** — the ESC game menu, StaticPopup confirm
  dialogs, ready check, item text reader, chat config, stack split and
  cinematic close dialogs get the dark panel with SentiUI buttons and
  fonts; dropdown menus, Battle.net toasts, queue/ticket status, the
  durability doll and the ghost button get the panel look; boss and
  level-up banners switch to the SentiUI font; alert toasts, UI widgets
  and battleground timer bars are styled on spawn via a slow sweep.
- **Cooldown viewers** — opt-in: the parked Cooldown Manager viewers
  (Essential/Utility/Buff) come back with the SentiUI skin and movable
  positions (`cooldownViewers` setting, off by default).

## Buttons

`ActionBarButtonTemplate` + `SecureActionButtonTemplate` (secure last, so
the plain secure click handler wins) under `SecureHandlerStateTemplate`
holders. Each button is detached from the game's dispatch lists right
after creation (`ActionBarButtonEventsFrame` and friends would run the
game's own protected writes on it under addon taint — that was the
`UNKNOWN()` spam) and painted from our own event frame instead of a
ticker. The native `C_ActionBar.*` API drives textures, cooldown sweeps
(`GetActionCooldown` + `DurationObject`, secret-safe), display counts,
usable/range coloring, the checked glow, equipped edges and proc alerts —
all secret-guarded. Icons also desaturate while their cooldown runs and
get the color back the moment the spell is usable (`cooldownDim`
setting). Drag & drop and tooltips included.

Keybinds keep pressing the game's hidden twin buttons (`ActionButton1..`,
`MultiBar*Button*`); the secure page driver copies bar 1's page onto the
twins through `actionpage`, so a key casts exactly what the SentiUI button
shows — cast-on-key-down included, no override bindings. Only flyout
slots are re-pointed at our buttons.

Bar visibility runs through a secure state driver (`[petbattle] hide;`
style rules), paging through a macro-condition state driver in the
client's own clause order (override, vehicle, possess, shapeshift,
manual pages, bonus bars, class forms).

## Options

Own "Action Bars" section: global hotkey/count/macro/range toggles, and per
bar: enable, button size, spacing, button count, buttons per row,
**vertical layout**, visibility (always / combat / target), mouseover fade
and "hide when empty" (empty bars reappear while dragging a spell so
they can receive drops). All bars and holders are SentiUI movers
(`/sui unlock`).

## Blizzard chrome

The game's bars are **parked**: reparented under a hidden frame
(`SentiUIParkedBars`) once — never shown, hidden or alpha-faded from addon
code, so no shared dispatch ever taints them. Their buttons (the twins
keybinds press) are unlisted from the game's event frame and parked too;
`ActionBarActionEventsFrame` is silenced since nothing it fed is left.
The micro menu, bag bar, status tracking and Cooldown Manager viewers go
to the same hidden frame. Stance and pet bars adopt the game's own
buttons (`StanceButton*`, `PetActionButton*`) into SentiUI holders — their
updates and keybinds stay the game's.
