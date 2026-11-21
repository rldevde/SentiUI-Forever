# SentiUI module API

How a `SentiUI_*` addon docks into the settings window. The module addon is a
normal addon folder with `## Dependencies: SentiUI` in its TOC, so it loads
after the core. No libraries are required.

## Registering

At file load (any file works; convention is `Module.lua` last):

```lua
local addonName, ns = ...

SentiUI:RegisterModule("ActionBars", {
    label   = "Action Bars",      -- section name in the window
    order   = 100,                -- section order (lower = earlier)
    defaults = ns.DEFAULTS,       -- defaults merged into SentiUIDB.modules.ActionBars
    options = ns.OPTIONS,         -- { pages = { ... } }, see below
    changelog = ns.CHANGELOG,     -- release history, shown on SentiUI > Changelog
    -- optional:
    section = "layout",           -- file pages under another section id
    OnEnable         = function(mod, db) end,
    OnSettingChanged = function(mod, path, value) end,  -- path is dotted
})
```

`mod.db` is the module's live settings table (defaults already merged).
Registering after login enables the module immediately.

## Settings access

```lua
SentiUI:Get("ActionBars", "bars.1.size")   -- dotted path, scope = module name
SentiUI:Set("ActionBars", "bars.1.size", 12)
SentiUI:Get("general", "gridSnap")         -- core settings live in "general"
```

`Set` fires `OnSettingChanged` on the module and the global
`SentiUI.On("SettingChanged", fn)` callback.

## Option pages

```lua
ns.OPTIONS = {
    pages = {
        {
            id    = "bars",                 -- page id (unique inside the module)
            label = "Bars",
            desc  = "One line under the title.",      -- optional
            groups = {                        -- cards on the page
                {
                    label = "Main bar",
                    items = {
                        { type = "toggle",   key = "enabled",  label = "Enable" },
                        { type = "slider",   key = "size",     label = "Button size",
                          min = 24, max = 64, step = 1, unit = "px" },
                        { type = "dropdown", key = "style",    label = "Style",
                          values = { flat = "Flat", ring = "Ring" } },
                        { type = "color",    key = "tint",     label = "Tint", alpha = true },
                        { type = "button",   label = "Reset",  func = function() end },
                        { type = "text",     label = "A note." },
                        { type = "custom",   label = "Mine",
                          build = function(row) end, height = 40 },
                    },
                },
            },
        },
    },
}
```

`key` is a dotted path into the module's defaults. Any value item may instead
use `get()`/`set(v)` plus `default()`. Extra per-item fields:

- `desc`            hover tooltip
- `disabled(get)`   grey out; `get(key)` reads another setting in the scope
- `hidden(get)`     hide the row
- `invert = true`   show a toggle flipped
- `reload = true`   ask for a UI reload after a change
- `noSearch = true` keep the row out of the search

## Movers

```lua
SentiUI.Movers.Register(frame, "actionbars.main", "Main Bar",
    { x = 0, y = -300 },            -- default: CENTER offset from UIParent
    { scale = true })               -- wheel on the handle scales the frame
```

Positions are saved in `SentiUIDB.positions[key]` as CENTER offsets.
`SentiUI.Movers.SetUnlocked(true)` opens move mode; `/sui unlock` toggles it.

## Changelog

Pass `changelog = ns.CHANGELOG` in the module def and the release history
shows on **SentiUI > Changelog**, in the client's language. Each entry:

```lua
ns.CHANGELOG = {
    { version = "0.2.0", date = "2025-01-15",   -- date optional
      changes   = { "English line", ... },
      changesDE = { "German line", ... } },     -- optional, falls back to changes
}
```

`SentiUI.Changelog.Register(addonName, entries)` registers more entries or a
non-module addon directly. Keep `CHANGELOG.md` in sync with the Lua entries;
keep `README.md` (English) up to date with features and options.
