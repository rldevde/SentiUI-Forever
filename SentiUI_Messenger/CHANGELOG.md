# SentiUI Messenger

## 0.3.12 - 2026-11-23

- Whisper chips: slightly taller pills, and the close X moved inside the chip's right edge - on hover it fades in over the unread count's spot, always inside the parent with a hit box big enough to press. Chips reserve right-side space for it so names can't run under it.

## 0.3.11 - 2026-11-22

- Whisper tiles redesigned: the square letter boxes are now pill chips showing the contact's first name in class color, with the pin star in gold and the unread count on the right. Chips auto-size to the name; the close X sits on the chip's top edge and still fades in on hover.

## 0.3.10 - 2026-11-22

- ForeverBlackListed integration: right-click a conversation row for the context menu - add the contact to the blacklist or good list (with FBL's note prompt), or remove a listed contact. Listed names are tinted: blacklist = red, good list = green. No list actions for Battle.net chats (no character name).

## 0.3.9 - 2026-11-22

- Fix the close X (hub) and the card header buttons not clicking: the full-width drag strip covered them and won hit-testing. The strips now stop short of the button row.

## 0.3.8 - 2026-11-22

- Fix sent messages appearing twice: sendTo echoes the line right away and the CHAT_MSG_WHISPER_INFORM event then added it a second time - INFORM lines that repeat the just-echoed text are now skipped.

## 0.3.7 - 2026-11-22

- Conversation windows now close on Escape via the shared S.EscClosable helper instead of UISpecialFrames entries - addon-written entries in that game table taint the Escape dispatch.

## 0.3.6

- Messenger windows: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.

## 0.3.5

- Escape-forbidden-call fix: the copy window's `OnEscapePressed` ran inside the Escape dispatch - the window is in `UISpecialFrames`, so Escape closes it natively.


## 0.3.4

- Conversation window is now a real mover: move-mode entry +
  Movers.Save persistence replace the custom saveSpot/restoreSpot
  pair.

## 0.3.3

- Hub title-drag saving now goes through Movers.Save (nearest-anchor
  format + MoversChanged) instead of a manual center offset that mixed
  frame-space and UIParent-space coordinates.

## 0.3.2

- Tile strip default anchor now docks above whichever left-side strip
  is highest — chat tab row, XP bar or a rep bar stacked above it —
  so tiles no longer sit inside a data bar.
- Tiles got a small `x` on the top-right corner (fades in on hover):
  clicking it deletes that conversation, the same as the hub's
  delete — an open card for it closes too.

## 0.3.1

- Fixed the header level: the German client abbreviates level as
  "St." with no number placeholder, so "St. Paladin" lost the actual
  level — it now prints the number directly ("19 · Paladin").
- Moved the tile strip's default: it now anchors above the chat's tab
  row (`GeneralDockManager`) instead of the chat panel's top edge,
  which a data bar can occupy — no more tiles hiding inside the XP
  bar.

## 0.3.0

- **Header info line**: card (and hub thread) show level, localized
  class name and guild under the sender's name — learned from the
  sender's GUID, guild probed by name.
- **Header actions on the card**: `I` group invite, `B` ignore,
  `C` copy history, `>` open in hub, `x` close (hover shows meaning).
- **Copy history window**: the whole conversation as selectable plain
  text with a `dd.mm hh:mm` timestamp per line, for copying the log
  out of the game. The store already keeps every line's timestamp
  persistently.

## 0.2.2

- Moved the default tile strip: it now sits above the chat panel's
  TOP-LEFT edge and grows rightward like a tab row (was: top-right
  corner growing left). The preview toast follows to the left edge.
  `/sui reset` or right-click the mover handle once for the new
  default.

## 0.2.1

- The conversation window opens on its own for a new incoming whisper
  (option "Open window on whisper", on by default).
- The reply key (r) opens the last whisperer's conversation window
  instead of the plain chat input; falls back to the game's reply box
  if nothing was recorded yet (option "Reply key opens window").
- Tile strip renders on the MEDIUM strata so unit frames/panels can no
  longer cover it.

## 0.2.0

- **Whisper tiles**: a row of small squares above the left chat
  panel — one per recent conversation, the sender's initial in their
  class color plus unread count and pin marker. Left-click opens that
  chat's own window, right-click opens it in the hub, hovering shows
  the name and last line. The strip is a mover (`/sui unlock`).
- **Conversation card**: each chat gets its own window — class-colored
  title, scrollable thread with clickable links, reply box and a
  button that expands into the hub. Draggable, position persists,
  Escape closes.
- **New whisper preview**: a small toast above the tiles flashes the
  sender and first line for a few seconds; clicking opens the card.

## 0.1.0

- First release: a whisper hub in the Sentinel look. One window for
  every conversation — search and list on the left (pinned first, last
  line and unread count), the picked chat's thread on the right with
  its own reply box. Open with `/smsg` or `/sm`, from the settings
  page, or move the window via `/sui unlock`.
- Conversations persist per account (80 lines each, oldest unpinned
  trimmed past 40 chats); Battle.net whispers last for the session.
  Class-colored names, clickable item/spell links, optional
  timestamps, unread badge on the minimap button and a throttled
  whisper sound.
- Optional away auto-reply: answers an incoming whisper once per
  person every 15 minutes while you are flagged away.
