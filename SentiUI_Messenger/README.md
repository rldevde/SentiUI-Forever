# SentiUI Messenger

A whisper hub for SentiUI — every conversation in one window, in the
Sentinel look. Inspired by conversation-style messengers, implemented
independently.

## Features

- **Whisper tiles**: a row of small squares above the left chat panel —
  one per recent conversation, the sender's initial in their class
  color plus unread count and pin marker. Left-click opens that chat's
  own **conversation card** (a small window with the thread and a reply
  box, draggable, position saved), right-click opens it in the hub.
  A new whisper flashes a short **preview toast** above the tiles;
  clicking it opens the card. The strip is a mover — `/sui unlock` to
  drag it anywhere.
- **One window for all whispers** (`/smsg`, `/sm`, or the button on the
  SentiUI > Messenger settings page): search field and conversation
  list on the left (pinned chats first, then recent, each with the
  last line and an unread count), the picked conversation's thread on
  the right with its own reply box.
- **Per-person conversations** for character whispers and Battle.net
  whispers. Names render in class colors (learned from the sender's
  GUID), links stay clickable with tooltips.
- **History**: character conversations persist per account — 80 lines
  each by default, and the oldest unpinned chats are trimmed once more
  than 40 conversations exist. Battle.net chats last for the session
  because their sender names can be protected.
- **Notifications**: throttled whisper sound and an unread counter on
  the SentiUI minimap button.
- **Pin & prune**: hover a conversation for its pin (keeps it on top
  and out of the trim) and delete buttons; a *Clear all* button empties
  the whole list.
- **Away auto-reply** (optional): answers an incoming whisper once per
  person every 15 minutes while you are flagged away.
- **Secret-value safe**: whispers whose sender or text the client
  protects are not stored — they still reach the normal chat.
- The window is draggable by its title bar and registered as a mover,
  so `/sui unlock` and login placement stay in sync.

## Options

SentiUI > Messenger: enable/disable, whisper sound, minimap badge,
lines per conversation, conversations kept, timestamps, away
auto-reply.

## Slash commands

| Command | Effect |
| --- | --- |
| `/smsg`, `/sm` | toggle the hub window |
| `/smsg Name` | open (or start) the conversation with `Name` |
