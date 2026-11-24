# SentiUI Blessings (SentiUI_Pally)

A PallyPower-compatible blessing window in SentiUI style, for paladins only.
It speaks PallyPower's own addon protocol (`PLPWR`), so it sees the same
paladins and the same assignments as every real PallyPower client in the
group - and they see you.

## Window

- **Personal strip** - aura and seal chips (mouse wheel cycles through what
  you know, the icon casts), plus a Righteous Fury button that lights while
  the buff is missing.
- **Class rows** - one row per class in the group: class icon, buffed/total
  counter (red / gold / green), one blessing cell per known paladin and a
  cast button that puts *your* assigned blessing on the first member
  missing it. Click a row to expand its member list for per-player blessing
  overrides (normal blessings).
- **Assignment cells** - left-click cycles a paladin's blessing forward,
  right-click cycles back. You can change your own row, every row when you
  lead or assist, and any paladin who enabled Free Assignment.
- **Auras row** - the same cells carrying aura assignments (AASSIGN).
- **Footer** - Auto-Assign (class priorities over the known paladins),
  Clear, Report to group chat, Free Assignment checkbox, Refresh (re-sends
  SELF and asks everyone for REQ).
- **Title bar** - Symbol of Kings count. Drag the window by the title band,
  Esc closes, position is saved via the movers (`/sui` unlock).

## Protocol compatibility

Wire-compatible with PallyPower (AznamirWoW/PallyPower, Forever flavor):

- `REQ`, `SELF`, `ASELF`, `ASSIGN`, `PASSIGN`, `NASSIGN`, `MASSIGN`,
  `AASSIGN`, `CLEAR`, `FREEASSIGN .. | SYMCOUNT .. | COOLDOWNS..`
- full names with spaces travel over the wire with `_` in place of the
  space, exactly like PallyPower on Forever
- leader/assistant gating identical: only leaders may change other
  paladins, unless they enabled Free Assignment

`/sp` toggles the window. Options under **SentiUI > Blessings**.
