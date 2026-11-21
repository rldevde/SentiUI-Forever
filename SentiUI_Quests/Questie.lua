-- Questie's own settings step aside while the SentiUI tracker is in charge,
-- the same mechanism DaylightUI uses: Questie.db.profile.trackerEnabled = false
-- stops its tracker, and hideUntrackedQuestsMapIcons = true keeps quests we
-- do not watch off the maps (Questie reads "tracked" from the game's quest
-- watches, which is what our tracker lists). Everything we flip is
-- remembered in the module db and put back when the player picks Questie's
-- tracker (Questie's tracker rebuilds after a reload, so switching asks).
local _, ns = ...
local S = SentiUI

local QA = {}
ns.Questie = QA

local db -- module db, set from Tracker.Enable

function QA.SetDb(d) db = d end

function QA.Loaded()
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
	if type(loaded) ~= "function" or loaded("Questie") ~= true then return false end
	return type(_G.Questie) == "table"
end

local function profile()
	local q = _G.Questie
	local p = type(q) == "table" and type(q.db) == "table" and q.db.profile
	return type(p) == "table" and p or nil
end

local NONE = "none" -- stands in for a setting the player never set (nil)

-- ours = SentiUI tracker in charge
function QA.Run(ours)
	local prof = profile()
	if not prof or not db then return false end
	db.questieOff = db.questieOff or {}
	local off = db.questieOff
	if ours then
		for _, key in ipairs({ "trackerEnabled", "hideUntrackedQuestsMapIcons" }) do
			if off[key] == nil then
				off[key] = prof[key] == nil and NONE or prof[key]
			end
			prof[key] = (key == "trackerEnabled") and false or true
		end
	else
		for key, was in pairs(off) do
			prof[key] = (was == NONE) and nil or was
			off[key] = nil
		end
		if next(off) == nil then db.questieOff = nil end
	end
	return true
end

-- Questie's AceDB settings can land after our login; retry a few times.
QA.RETRY, QA.TRIES = 0.5, 20
function QA.Retry(ours, left)
	if left <= 0 or not QA.Loaded() then return end
	C_Timer.After(QA.RETRY, function()
		local done
		S.SafeCall("questie", function() done = QA.Run(ours) end)
		if not done then QA.Retry(ours, left - 1) end
	end)
end
