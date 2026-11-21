# SentiUI_Buffs

Buff and debuff bars for SentiUI built on the client's own
**`AuraContainer`** — the engine path ElvUI uses on modern clients
(`SecureAuraHeaderTemplate` does not exist on this build). The engine
assigns auras to its own buttons inside the restricted environment, so
slots appear and disappear correctly even in combat and secret aura
data never reaches addon Lua.

## Features

- **Buff bar** — your buffs as square icons with cooldown swipe and the
  engine's own countdown text (`19m`, `2h`) plus stack count.
- **Debuff bar** — your debuffs with the border ring tinted by dispel
  type (Magic blue, Curse purple, Poison green, Disease brown,
  Bleed red) via `AddDispelTypeTexture`.
- **Weapon enchants** — temporary enchantments ride ahead of the buffs
  via the container's `AddItemEnchantment` slots.
- **Right-click cancels** — `SetCancelAuraButtons` hooks the secure
  cancel path, so buffs can be dismissed even in combat.
- **Movers** — both bars move with `/sui unlock`: *Buff bar*,
  *Debuff bar*. Defaults dock left of the minimap.
- **Layout** — icon size, spacing, icons per row, grow direction, scale.
- **Hide Blizzard** — the stock `BuffFrame`/`DebuffFrame`/
  `TemporaryEnchantFrame` are parked while the module is on.

## How it works

Each bar is `CreateFrame('AuraContainer', ..., UIParent,
'CustomAuraContainerTemplate, DisableUntrustedLayoutScriptsTemplate')`,
built deferred on a clean timer tick (the provider refuses to wire its
buttons when created inside a restricted caller). `AddAuraGroup`
registers one group per bar whose `initializeFrame` wires our widgets
into every spawned `AuraButton`: `SetIcon`, `SetDurationCooldown`,
`SetApplicationCount`, `SetCancelAuraButtons`,
`AddDispelTypeTexture`. The container then owns icon, duration, count,
visibility and flow layout — including all combat-time add/remove.

## Settings

SentiUI → Buffs. `enabled` and `hideBlizzard` need a reload; everything
else applies live.

## Secret-value notes

Aura values stay inside the engine: icons, durations and counts are fed
straight to the widgets by the container, never touched or compared by
Lua — the whole approach is secret-safe by construction.
