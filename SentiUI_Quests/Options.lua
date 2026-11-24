-- The module's options, filed under its own "Quests" section.
local _, ns = ...
local L = ns.L

local function trackerValues()
	local v = { sentiui = L["SentiUI tracker"] }
	local order = { "sentiui" }
	if ns.Questie.Loaded() then
		v.questie = L["Questie's tracker"]
		order[#order + 1] = "questie"
	end
	v.blizzard = L["Blizzard tracker"]
	order[#order + 1] = "blizzard"
	return v, order
end

-- choices is re-evaluated on every render, so a Questie that loads late
-- still shows up in the dropdown.

ns.OPTIONS = {
	pages = {
		{
			id = "quests",
			label = L["Quests"],
			desc = L["The SentiUI quest tracker, or Questie's tracker when you have it installed."],
			groups = {
				{
					label = L["Quest tracker"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable quests module"], reload = true,
							desc = L["The Blizzard tracker returns after a reload with this module off."] },
						{ type = "dropdown", key = "tracker", label = L["Quest tracker"],
							desc = L["Which quest tracker is shown."],
							choices = trackerValues },
					},
				},
				{
					label = L["Quest tracker"],
					items = {
						{ type = "slider", key = "width", label = L["Width"], min = 180, max = 400, step = 5, unit = "px" },
						{ type = "slider", key = "maxHeight", label = L["Tracker height"], min = 150, max = 900, step = 10, unit = "px",
							desc = L["The list scrolls inside this height with the mouse wheel."] },
						{ type = "toggle", key = "fixedHeight", label = L["Fixed size"],
							desc = L["The tracker keeps the configured height whether the list is short or long - off shrinks it to the content."] },
						{ type = "slider", key = "fontSize", label = L["Font size"], min = 10, max = 18, step = 1 },
						{ type = "dropdown", key = "filter", label = L["List filter"],
							desc = L["What the tracker lists - the header buttons switch it on the fly."],
							values = { watched = L["Watched quests"], zone = L["This zone's quests"], all = L["All quests"] },
							order = { "watched", "zone", "all" } },
						{ type = "slider", key = "spacing", label = L["Row spacing"], min = 0, max = 8, step = 1, unit = "px" },
						{ type = "toggle", key = "questLevels", label = L["Quest levels"],
							desc = L["Show the level in front of each quest title."] },
						{ type = "toggle", key = "hideInCombat", label = L["Hide in combat"] },
						{ type = "toggle", key = "nav", label = L["Way marker"],
							desc = L["In-world marker on the tracked quest: a gold diamond with distance on the spot; an arrow at the screen edge points the way when it's off-screen."] },
						{ type = "toggle", key = "progress", label = L["Progress lines"],
							desc = L["Sentinel-styled quest progress lines mid-screen (count in accent, thin bar, gold on quest complete) instead of the game's yellow text. It's a mover."] },
						{ type = "dropdown", key = "feedExit", label = L["Row exit"],
							desc = L["Expired rows fly off to the chosen screen edge while they fade."],
							values = { right = L["Fly off right"], left = L["Fly off left"], fade = L["Fade in place"] },
							order = { "right", "left", "fade" },
							disabled = function(get) return get("progress") == false end },
						{ type = "toggle", key = "completeToast", label = L["Completion toast"],
							desc = L["A big card pops mid-screen when a quest is finished."] },
						{ type = "toggle", key = "objectiveToast", label = L["Objective toast"],
							desc = L["A card pops mid-screen when a single objective finishes."] },
						{ type = "toggle", key = "shareProgress", label = L["Share progress in group"],
							desc = L["Posts objective progress and quest completion to the party chat."] },
						{ type = "toggle", key = "autoQuest", label = L["Auto accept / turn in"],
							desc = L["Walks through NPC quest dialogs on its own: accepts, progresses and turns in. A choice of rewards is never picked for you. Hold SHIFT to talk to an NPC manually."] },
						{ type = "toggle", key = "autoQuestSkipTrivial", label = L["Skip gray quests"],
							desc = L["Auto-accept ignores trivial (gray) quests - they can still be taken by hand or with SHIFT held."] },
					},
				},
				{
					label = L["Position"],
					items = {
						{ type = "text", label = L["The tracker is a registered mover: unlock move mode and drag it. Right-click its handle to reset."] },
						{ type = "button", label = L["Move frames"], text = L["Unlock"],
							func = function() SentiUI.Movers.SetUnlocked(true) end },
						{ type = "button", label = L["Reset position"], text = L["Reset"],
							func = function() SentiUI.Movers.Reset("questtracker") end },
					},
				},
			},
		},
	},
}
