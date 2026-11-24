# SentiUI Data Bars

Experience and reputation bars for SentiUI.

- **Experience bar**: rested XP as a lighter segment ahead of the
  fill, pending XP from completed quests as a green segment, a
  `LEVEL UP!` marker when banked turn-ins would ding, and XP/hour
  plus time-to-level in the tooltip.
- **Reputation bar**: shows the watched faction in its standing
  color; friendship, renown and paragon factions are handled.
  Click the bar to open the reputation frame.
- Both bars dock onto the chat panels by default (they follow the
  chat movers) and are registered as their own movers so they can
  be detached and placed anywhere.
- The fill glides to new values (Smooth bars) and `+N` gain numbers
  pop off the fill's leading edge and rise while they fade (Gain
  flytext) — both on by default.
- Settings live under **SentiUI → Data Bars** (`/sui`): size,
  orientation (horizontal/vertical), text mode, mouseover fade,
  smooth fill, gain flytext, hide at max level and more.
