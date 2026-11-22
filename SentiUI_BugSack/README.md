# SentiUI BugSack

A fully internal error grabber and BugSack-style viewer for the SentiUI
suite. No external `!BugGrabber` / BugSack addons needed — everything runs
inside the suite, styled in Sentinel colors and wired into the SentiUI
settings.

## What it captures

- **Lua errors** — the module installs the client's error handler the
  BugGrabber way (`seterrorhandler` is stubbed afterwards so nothing else
  can replace it). Messages, stacks and locals are kept.
- **`LUA_WARNING`**
- **`ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN`** — with the addon
  name and the forbidden call; floods are throttled (max 10/s). Every
  distinct addon+function pair gets its own entry, repeats only bump the
  counter.

Repeated messages collapse into one entry with an occurrence counter. The
store keeps at most 500 errors and tracks a session number so the window
can separate new errors from old ones across reloads.

## The window

`/sbs` or `/bugsack` toggles it (also: SentiUI settings → BugSack →
*Open BugSack*). It is a real SentiUI mover — drag it where you want it.

- **Views:** *Current session* is the default — only fresh errors. Older
  sessions live in the **Archive** view as collapsible session groups
  (session → addon → error), keeping the last 25 sessions. A search box
  scans message, stack and locals across everything.
- **List:** errors grouped per addon, collapsible, sorted by count; the
  archive nests a session header above each addon group.
- **Detail pane:** the selected error as plain text with a session and
  timestamp meta line — click in, Ctrl+A, Ctrl+C to copy a single report.
- **Export:** *Export* dumps the current view, *Export all* dumps the
  whole store — a select-all box covering the whole content area,
  formatted for the bug tracker.
- **Wipe all errors** clears the store, **Clear archive** drops only the
  archived sessions (both ask for confirmation).
- Prev/next buttons walk the list; Escape closes.

## Reporting bugs

Please post exported reports at
**https://dev.xrl-dev.de/bugtracker** — the reminder sits in the window
footer and the export pane. Include the whole export block if you can;
stacks and locals make fixes much faster.

## Options (SentiUI → BugSack)

- **Grab errors** — master switch (a change needs a reload to fully
  attach/detach the handler).
- **Chat notice on new errors** — clickable chat line that opens the error.
- **Sound on new errors** — warning sound (3 s cooldown).
- **Auto-open on new errors** — pops the window (never in combat).

## Slash commands

| Command | Action |
| --- | --- |
| `/sbs`, `/bugsack` | toggle the window |
| `/sbs wipe` | clear all stored errors |
| `/sbs export` | export current session |
| `/sbs export all` | export everything |
| `/sbs <n>` | print error *n* to chat |

## Notes

- If the old standalone `!SentinelBugFolder` (or any other error grabber)
  is installed too, keep only one — two grabbers compete for the same
  error handler.
- Errors from BugSack itself are printed to chat directly so the grabber
  can never swallow its own failures.
