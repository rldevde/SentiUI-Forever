-- Stops the game's quest tracker before it starts so ours (or Questie's)
-- is the only one - the same mechanism DaylightUI uses. The game sets up
-- its tracker once, after PLAYER_ENTERING_WORLD / VARIABLES_LOADED through
-- three functions nothing else calls: AddContainer, AssignModulesOrder and
-- SetModuleContainer. Emptied while this addon loads, no container is ever
-- registered, so the game's tracker never draws.
--
-- This runs at file load, before the module system is up, so the saved
-- choice is read straight from SentiUIDB. Choice "blizzard" keeps the
-- game's tracker alive (it returns on the next load with this module off).
-- Never Hide() the frame: it is a managed frame and its OnHide would
-- re-lay out the right-side frames from addon code. What is left goes to
-- alpha 0 and stops taking the mouse.
local _, ns = ...
local S = SentiUI

local B = {}
ns.Blizzard = B

local function noop() end
local EMPTIED = { "AddContainer", "AssignModulesOrder", "SetModuleContainer" }

local function savedTracker()
	local m = _G.SentiUIDB and _G.SentiUIDB.modules and _G.SentiUIDB.modules.Quests
	return type(m) == "table" and m.tracker or "sentiui"
end

function B.Starve()
	if B.starved then return true end
	if savedTracker() == "blizzard" then return false end
	local m = _G.ObjectiveTrackerManager
	if type(m) ~= "table" then return false end
	for _, name in ipairs(EMPTIED) do m[name] = noop end
	B.starved = true
	return true
end

local muted = setmetatable({}, { __mode = "k" })
local function mute(f)
	if type(f) ~= "table" or type(f.EnableMouse) ~= "function" or muted[f] then return end
	muted[f] = true
	pcall(f.EnableMouse, f, false)
end

-- the empty frame left behind: transparent and click-through. Runs even
-- when the manager was not there to starve (it may load on demand): then
-- the tracker still drew, and hiding it visually is the fallback.
function B.Mute()
	if savedTracker() == "blizzard" then return end
	local f = _G.ObjectiveTrackerFrame
	if type(f) ~= "table" then return end
	pcall(f.SetAlpha, f, 0)
	if type(f.NineSlice) == "table" and f.NineSlice.SetAlpha then
		pcall(f.NineSlice.SetAlpha, f.NineSlice, 0)
	end
	mute(f)
	if type(f.Header) == "table" then
		mute(f.Header)
		mute(f.Header.MinimizeButton)
	end
	mute(_G.QuestTimerFrame)
end

B.Starve()
S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
	B.Starve() -- in case the manager only exists by now
	B.Mute()
end)
