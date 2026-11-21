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
  name and the forbidden call; floods are throttled (max 10/s) and repeat
  offenders are only recorded once per session.

Repeated messages collapse into one entry with an occurrence counter. The
store keeps at most 500 errors and tracks a session number so "current
session" and "previous session" stay meaningful across reloads.

## The window

`/sbs` or `/bugsack` toggles it (also: SentiUI settings → BugSack →
*Open BugSack*). It is a real SentiUI mover — drag it where you want it.

- **Filters:** All / Current session / Previous session, plus a search
  box that scans message, stack and locals.
- **List:** errors grouped per addon, collapsible, sorted by count.
- **Detail pane:** the selected error as plain text — click in,
  Ctrl+A, Ctrl+C to copy a single report.
- **Export:** *Export session* / *Export all* opens a select-all box with
  the whole report formatted for the bug tracker.
- **Wipe** clears the store (asks for confirmation).
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
