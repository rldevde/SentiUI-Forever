-- ActionBars module defaults. Merged into SentiUIDB.modules.ActionBars at enable.
local _, ns = ...

local function bar(perRow, enabled, hideEmpty)
	return {
		enabled = enabled ~= false,
		size = 34,
		spacing = 3,
		numButtons = 12,
		perRow = perRow,
		visibility = "ALWAYS",      -- "ALWAYS" | "COMBAT" | "TARGET"
		vertical = false,           -- fill columns instead of rows
		mouseoverFade = false,
		fadeAlpha = 0.3,
		hideEmpty = hideEmpty,      -- vanish while every slot is empty
	}
end

ns.DEFAULTS = {
	enabled = true,
	hotkeys = true,               -- key bind text on buttons
	counts = true,                -- item/charge count
	macroNames = true,            -- macro name under the icon
	rangeColor = true,            -- red tint when the target is out of range
	cooldownDim = true,           -- desaturate the icon while its cooldown runs
	readyPulse = true,            -- gold flash on the icon when a cooldown ends
	bar1 = bar(12, true, false),  -- paged main bar (forms, stances, vehicles)
	bar2 = bar(12, true, true),   -- static page 4 (slots 37-48)
	bar3 = bar(12, false, true),  -- static page 5
	bar4 = bar(1, false, true),   -- static page 6, vertical side bar
	petBar = {                    -- pet action bar, only with a pet
		enabled = true,
		size = 26,
		spacing = 3,
		vertical = false,
	},
	stanceBar = {                 -- forms/stances: druid forms, warrior stances,
		enabled = true,           -- rogue stealth, priest shadowform, ...
		size = 26,
		spacing = 3,
		vertical = false,
	},
	totemBar = {                  -- shaman totem slots, only for shamans
		enabled = true,
		size = 30,
		spacing = 3,
		vertical = false,
	},
	extras = {                    -- extra action, zone ability, vehicle/taxi exit
		enabled = true,
	},
	cooldownViewers = false,      -- opt-in: Cooldown Manager viewers un-parked + skinned
}
