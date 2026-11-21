# SentiUI Chat

Sentinel-styled chat for SentiUI, built the way the Sentinel chat module
was: no boxed panels, a shade behind the chat that fades towards the top,
accent-colored tab underlines and a borderless edit box.

## Features

- **Panels** - a movable shade behind the left chat dock and an optional
  right panel for an undocked Loot tab. Width, height, top fade and which
  panels show are configurable.
- **Tabs** - Blizzard tab textures stripped, accent underline under the
  active tab, accent text on the selected frame.
- **Edit box** - borderless, sits above or below the chat panel and
  borrows the color of the channel you type in.
- **Message filter** - short channel names (`[1. General]` → `[1]`,
  `[Party]` → `[P]`), clickable URLs with a copy popup, keyword
  highlighting (`%MYNAME%` works) with an alert sound, timestamps.
- **Names** - class-colored player names everywhere, plus `[52 Name]`
  levels for players known from guild, group and friends.
- **Extras** - spam throttle, sticky channels, link hover tooltips, a
  copy-chat button and window per frame, scroll-to-bottom arrow, optional
  chat history that survives a reload.

## Moving

The panels are registered movers: unlock move mode in the SentiUI
settings and drag them; right-click a handle to reset. The docked chat
follows the left panel.

## Settings

Open the SentiUI settings (minimap button or `/sui`) → **Chat**. All
options apply live except the module and copy/scroll buttons, which ask
for a reload.
