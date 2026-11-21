# SentiUI Data Bars

## 0.1.4

- Fixed broken bar fills: the orientation helper was declared below
  the fill function, so it resolved to a nil global and errored on
  every update - bars rendered uncolored (white).

## 0.1.3

- Bar orientation setting is live: the `HORIZONTAL`/`VERTICAL` default
  existed but was never read - vertical bars now fill bottom to top,
  keep Height as thickness, use Width as length and park at the screen
  edge instead of docking under the chat panels.

## 0.1.2

- Fill colors retuned to the Sentinel palette: XP bar now fills in
  the amber-gold family instead of the bright UI blue, rested XP is
  violet and pending quest XP a muted green. Fill gradient softened
  so the bars no longer look muddy.

## 0.1.1

- Visual pass so the bars match the interface: they now dock flush
  onto the chat panel's top edge with width following the panel,
  carry the SentiUI accent hairline, a spark at the leading edge
  of the fill and a subtle gradient on all fill colors.

## 0.1.0

- Initial release: experience bar with rested and pending-quest-XP
  segments, a LEVEL UP marker when banked turn-ins would ding,
  XP/hour and time-to-level in the tooltip, plus a reputation bar
  for the watched faction colored by standing (friendship, renown
  and paragon aware, click to open the reputation frame). Both bars
  are SentiUI-styled, dock onto the chat panels by default and are
  their own movers.
