-- Blessings module defaults. Merged into SentiUIDB.modules.Blessings
-- at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	showSolo = true,        -- show the window without a group
	showParty = true,       -- show in a party/raid
	freeassign = false,     -- let anyone change my assignment (PallyPower term)
	reportChannel = "auto", -- auto | party | raid | say | guild

	aura = 0,               -- remembered aura pick (index)
	seal = 0,               -- remembered seal pick (index)
	rfbuff = true,          -- remind me about Righteous Fury

	-- own assignments, remembered between reloads (broadcast via SELF)
	assign = {},            -- class id -> blessing id (my class blessings)
	auraAssign = 0,         -- aura id I'm assigned to run
	normals = {},           -- class id -> { player name -> blessing id }

	-- window spot saved by the mover (mover key "blessings.window")
}
