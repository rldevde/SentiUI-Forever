# SentiUI Chat

Sentinel-styled chat for SentiUI, built the way the Sentinel chat module
was: no boxed panels, a shade behind the chat that fades towards the top,
accent-colored tab underlines and a borderless edit box.

## Features

- **Panels** - a movable shade behind the left chat dock and an optional
  right panel for an undocked Loot tab. Width, height, top fade and which
  panels show are configurable.
- **Loot chat** - a chat window named *Loot* is created automatically and
  docked in the right panel, stripped down to loot, money and gain
  messages only. Toggle it under *Chat > Panels > Loot chat window*.
- **Tabs** - Blizzard tab textures stripped, accent underline under the
  active tab, accent text on the selected frame.
- **Edit box** - borderless, sits above or below the chat panel and
  borrows the color of the channel you type in.
- **Message filter** - short channel names (`[1. General]` → `[1]`,
  `[Party]` → `[P]`), clickable URLs with a copy popup, keyword
  highlighting (`%MYNAME%` works) with an alert sound, timestamps.
- **Names** - class-colored player names everywhere, plus `[52 Name]`
  levels for players known from guild, group and friends.
- **Extras** - spam throttle, link hover tooltips, a
  copy-chat button and window per frame, scroll-to-bottom arrow, optional
  chat history that survives a reload.
- **Emotes** - typed smileys (`:)`, `;)`, `xD`, `<3`, `o.O`, `:3`, `;P`
  …) and Discord-style `:name:` codes render as inline icons; a `:)`
  chip in the tab strip opens a 60-icon picker. Codes only convert with
  real boundaries, so timestamps like `04:39` and names never tear.

## Moving

The panels are registered movers: unlock move mode in the SentiUI
settings and drag them; right-click a handle to reset. The docked chat
follows the left panel.

## Settings

Open the SentiUI settings (minimap button or `/sui`) → **Chat**. All
options apply live except the module and copy/scroll buttons, which ask
for a reload.
