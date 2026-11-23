# SentiUI Panel

Titan-Panel-style info bars for SentiUI: a thin full-width bar on the
top and/or bottom screen edge holding small plugin buttons (clock,
coords, gold, bags, performance and many more), plus kill statistics,
a quest book and notification toasts. Standalone module - requires the
SentiUI core.

## Bars

- Top and bottom bar, each with LEFT / CENTER / RIGHT zones
- Per bar: enabled, height, opacity, margin, auto-hide (fades out until
  the mouse nears the edge), hide in combat, border, gloss,
  class-colored border and Adjust-UI
- Adjust-UI shrinks UIParent via the secure restricted environment so
  Blizzard frames stay clear of the bars (same mechanism Titan uses)
- Right-click on empty bar space: bar menu incl. hidden-plugin list
- Right-click on a plugin: options menu (label/icon, move, zone, bar,
  hide, plugin-specific actions)
- Shift+drag a plugin: reorder inside a zone or move between bars
- Installer step "Bottom bar plugins": a scrollable checklist that picks
  which plugins show on the bottom bar (live, editable later under
  SentiUI > Panel > Plugins)

## Plugins (32)

Clock · Location/coords · Performance (fps/ms + addon memory) ·
Played · Session (kills/gold/xp per hour) · Speed · Volume ·
Calendar events (Darkmoon + holidays) · Tracking · Vitals · XP ·
Reputation (with watch-faction menu) · Spec · Item level ·
Durability (merchant click = repair/sell junk) · Ammo · Soul shards ·
Pet happiness · Timed buffs · PvP rank · Hearthstone · Gold
(per-character totals) · Bags · Mail · Friends · Guild · Quests ·
Saved raids · Auctions · Profession cooldowns · Professions
(click = menu with every learned profession + skill level, clicking
one opens the profession window) · Kills · Layer
(creature-GUID shard read, SentiLayer letters, click = open / swap) ·
SentiUI brand

## Kill statistics

Tracks creature kills (XP message + corpse polling, no combat log),
spawn points per mob, looted drops, rares (toast + sound, gold pins on
the world map), NPC roles learned from interactions and a quest book
keeping texts/objectives/status. The window offers sidebar sections
(all/creatures/NPCs/rares/drops/quests/statistics), filters, detail
popups, waypoints (TomTom or native user waypoint), per-mob notes and
CSV export.

## Blacklist (ForeverBlackListed)

Integrated shared blacklist: players and guilds with notes, per-author
note history, votes, groups, good list, removal requests and tooltip
warnings. Shares the FBLDB data model with the standalone
ForeverBlackListed addon and delegates writes/sync to it when loaded.

- Wire sync on the FBLsync channel: chunked JSON export, auto-accept
  with trust modes (everyone / guild / friends), live share of local
  changes, version pings, pull requests and last-write-wins merge
- Channel transport is probed like the standalone: if SendAddonMessage
  does not reach the custom channel on this client, sends fall back to
  SendChatMessage, which only drains inside real input events (clicks)
- 'Sync log' page in the list window (for everyone): live status
  (channel, own/peer revision, live share, auto-accept, trust, last
  sender, live member count) plus a persisted log of all sync
  traffic in and out, and a peers strip listing known FBL clients
  on the channel with version, revision, their entry count vs ours
  (FBLstat announce) and last-seen time
- Admin page: admin roster, auto-accept/trust switches, import/export,
  pending removal requests, 'Sync all'

## Usage

- `/suipanel` (or `/spnl`) - open the SentiUI settings
- `/suipanel top|bottom` - toggle a bar
- `/suipanel reset` - default plugin layout
- `/suipanel kills [name]` - kill statistics window (optional search)
- `/suipanel wp <name>` - waypoint to a stored creature/NPC
