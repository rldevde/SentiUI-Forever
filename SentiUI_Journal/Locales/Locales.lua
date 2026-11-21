local _, ns = ...

local L = setmetatable({}, {
	__index = function(t, k)
		rawset(t, k, k)
		return k
	end,
})
ns.L = L

-- Named compendium keys (shared data tables reference these)
L.DJ_BOSSES = "Bosses"
L.DJ_QUESTS = "Quests"
L.DJ_MAP = "Map"
L.DJ_NO_MAP = "No map for this dungeon."
L.DJ_UNPLACED = "Boss locations not on the map"
L.DJ_CHAIN = "Quest chain"
L.DJ_CHOOSE = "Choose one"
L.DJ_EMPTY = "Pick a dungeon on the left - bosses, quests and the map show up here."
L.DJ_IN_DUNGEON = "Inside the dungeon"
L.DJ_LEVEL = "Level"
L.DJ_NEXT_QUEST = "Follow-up: %s"
L.DJ_NOTES = "Notes"
L.DJ_NO_DATA = "Compendium data did not load - restart the game client."
L.DJ_NO_QUESTS = "No quests recorded for this dungeon."
L.DJ_NO_WAYPOINT = "This client cannot set map waypoints."
L.DJ_OBJECTIVE = "Objective"
L.DJ_ONLY_MINE = "My faction"
L.DJ_OPTIONAL = "optional"
L.DJ_PICKUP = "Pickup"
L.DJ_PICK_QUEST = "Pick a quest on the left."
L.DJ_RECEIVE = "You receive"
L.DJ_REPEATABLE = "repeatable"
L.DJ_REQUIRES = "Requires level"
L.DJ_REQUIRES_CHAIN = "Requires a quest chain first"
L.DJ_REWARDS = "Rewards"
L.DJ_SHOW_MAP = "Show on map"
L.DJ_STARTS = "Starts with:"
L.DJ_TURNIN = "Turn-in"
L.DJ_UNAVAILABLE = "unavailable"
L.DJ_WARNING = "Warning"
L.DJ_DONE = "done"
L.DJ_WAYPOINT = "Waypoint"
L.HIST_SEARCH = "Search..."
L.NAV_DUNGEON = "Compendium"
