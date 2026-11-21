# SentiUI Tooltips

## 0.2.9

- Interface-dispatch audit: tooltip re-anchoring and the unit status-bar shell no longer run from OnShow/OnHide scripts on GameTooltip and its status bar - secure visibility watchers apply the work outside the client dispatch, which can carry secret unit values.


## 0.2.8

- Removed the player item level line from unit tooltips (per request) -
  the option, the line and its toggle are gone; Specialization keeps
  the inspect machinery. The item-level line on item tooltips stays
  available.

## 0.2.7

- Class name in the level line colors again: the `classFile` return of
  `UnitClass` reads secret on this client, so the color lookup came back
  empty and the class name stayed white. The token now comes from the
  `ClassToken` fallback chain (classID, GUID) plus the tooltip's own
  text, and a secret localized class name is picked straight off the
  level line.
- New option **"My Guild" text tag** (default off): the accent color
  alone marks your own guild - the literal `· My Guild` suffix only
  shows when enabled. *Guild member highlight* still controls the color.

## 0.2.6

- Cut-off tooltips / "missing" right border fixed: the client sizes the
  frame before our post-call lines and font swap land, so rewritten or
  added lines (and the wider SentiUI font) could outgrow the frame and
  draw over the edge. A new reflow pass measures the real width of every
  line after styling and grows the frame to fit - border and top accent
  edge stay visible and no text clips over them.

## 0.2.5

- Class-colored names actually paint now: the client's own name line
  can embed its own color codes, which silently win over SetTextColor -
  the line is rebuilt instead (base name wrapped in the unit color)
  while our appended tags ([Allianz], -Realm, <AFK>) are tracked per
  fontstring and re-applied with their original colors, so repeat
  tooltip passes stay idempotent and a new unit never inherits stale
  tags.

## 0.2.4

- Name line no longer doubles the surname: this client's second
  UnitName return is the character's last name, not a realm, so
  "Raziel Lucas" gained a "-Lucas" tag. The realm tag now only shows
  when the value differs from the surname in the full name - real
  realms still get their "-Realm".

## 0.2.3

- Faction detection fixed: UnitFactionGroup only returns a single
  (sometimes localized) value on this client - the english-faction
  check we relied on always came back nil, so neither the [Allianz] tag
  on the name line nor the faction-colored guild name ever painted.
  Detection now tests every return, matches the localized FACTION_*
  globals and falls back to the race's faction group.
- Hover item level for non-group players: the queue gated on
  CanInspect, which answers "no" for plain hovering here and silently
  dropped every request. It now gates on inspect range
  (CheckInteractDistance) and lets a dead NotifyInspect expire into the
  fail path instead. Negative cache entries also only stick for 8s now,
  so someone walking into range gets a retry quickly.

## 0.2.2

- Guild names can now wear the faction color: new toggle "Guild name in
  faction colors" (default on) paints Horde guilds red and Alliance
  guilds blue, using the client's own faction palette. It overrides the
  guild name color; your own guild still keeps the accent gold.

## 0.2.1

- Guild colors: the guild name on unit tooltips is now recolored -
  foreign guilds in a configurable color (default Sentinel blue), your
  own guild in the accent gold. The rank tag on the same line gets its
  own configurable color (default gold) instead of the grey it used to
  borrow.
- Two new pickers under SentiUI > Tooltips: "Guild name color" and
  "Guild rank color".

## 0.2.0

- Full rework. Fixed duplicated lines (Guild member and every other
  added line stacked once per post-call): all tooltip lines are now
  idempotent - label lines update in place, one-shot lines are deduped.
- Player item level now works the TipTac way: own ilvl live via
  `GetAverageItemLevel` + `GetItemLevelColor`; others via throttled
  `NotifyInspect` -> `INSPECT_READY` -> `GetInspectItemLevel`, and when
  that stays empty the equipped gear is scanned slot by slot
  (upgrade-aware `Item` mixin) and averaged over 16 slots. The number is
  tinted by average item quality.
- New: specialization line for players (live for you, via inspect for
  others, incl. role), difficulty-colored level number, faction /
  status / realm tags on the name line, the guild line itself carries
  the rank + a "My Guild" mark instead of a separate line, elite / rare /
  boss badge in its own color, target-of-target name colored by that
  unit's color, top accent edge tinted by class/quality color, dark
  shell + optional `cur / max · %` text on the health bar.

## 0.1.8

- Other players' item levels now really show: a throttled inspect
  queue calls `NotifyInspect` (max one in flight, ~2s spacing,
  `CanInspect` + InspectFrame guards, level-10 minimum), waits for
  `INSPECT_READY`, then reads `C_PaperDollInfo.GetInspectItemLevel`.
  Results cache per guid for 30s and the line is appended live if the
  tip still shows that player.

## 0.1.7

- Faction tag: Horde/Alliance units get a line in their faction color
  (horde red / alliance blue, localized name).
- Player item level: your own average ilvl always shows, other players
  once the game holds their inspect data. Both toggleable under Units.

## 0.1.6

- Class colors, root cause found: `GameTooltip:GetUnit()` returns a
  dead token on this client, so every unit lookup silently failed.
  The tooltip now resolves its unit from its own tooltip data guid
  via `UnitTokenFromGUID`, and class resolution additionally uses
  the numeric classID (3rd `UnitClass` return) through
  `C_CreatureInfo.GetClassInfo` - both paths proven on this client.

## 0.1.5

- Class colors for real this time: `UnitIsPlayer` itself reads secret
  on this client, which skipped the whole class lookup before it
  started. The player check now falls back to the GUID prefix, and an
  unreadable answer still gets the text-based class read (the
  localized class name inside the tooltip's own lines) plus the
  engine's secret class color.

## 0.1.4

- Fixed class colors never applying: a secret `UnitIsPlayer` threw
  inside the color lookup and aborted the whole unit pass. Classes
  hidden behind secrets are now resolved through the engine's
  `C_ClassColor` path and their secret rgb goes straight into the
  color setters.

## 0.1.3

- New unit info, all individually switchable: class name in class
  color inside the level line, health numbers on the bar,
  elite/rare/boss badge, group role for party members and an AFK/DND
  tag on the name.
- Guild extras: the guild line already carries the rank; new is the
  "Guild member" highlight when the target is in your own guild.

## 0.1.2

- The fixed point now really is fixed: every tooltip show is checked,
  so world and unit tooltips that skip the default-anchor call are
  pulled to the anchor too. Tooltips anchored to a specific owner
  (bag slots, action buttons, links) keep their spot.

## 0.1.1

- Tooltips now carry the Sentinel gold edge line across the top,
  matching every other panel.
- Fixed the default anchor sitting mid-screen: the fixed spot is now
  the classic bottom-right tooltip corner and resets there too.

## 0.1.0

- New module: Sentinel-styled tooltips (flat dark backdrop, Sentinel
  font) for all the game's tooltips.
- Units: class-colored player name, reaction-colored NPC name, border
  in class/reaction color, slim restyled health bar, guild rank on the
  guild line and a target-of-target line.
- Items: border in item quality color (uncommon and up), item level
  line (only when the game didn't write one), optional max stack and
  item/spell IDs.
- Placement: fixed movable anchor or at-cursor with X/Y offsets, scale
  slider, optional hide-in-combat (Shift bypasses).
