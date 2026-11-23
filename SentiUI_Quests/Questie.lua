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

-- the profile flag only gates Questie's STARTUP - an already-built
-- tracker frame stays visible until reload. Suppress the frame itself
-- so the switch applies live: OnShow re-hide guard while our tracker is
-- in charge, released when the player picks Questie's tracker back.
local suppressWatch
local function SuppressTracker(suppress)
	local bf = _G.Questie_BaseFrame
	if type(bf) == "table" and bf.Hide then
		if suppress then
			if not bf._sentiSuppressed then
				bf._sentiSuppressed = true
				bf:HookScript("OnShow", function(self)
					if not self._sentiReleased then self:Hide() end
				end)
			end
			bf._sentiReleased = nil
			bf:Hide()
		else
			bf._sentiReleased = true
		end
	end
	-- the base frame can still be unborn: Questie builds its tracker in a
	-- startup coroutine, possibly after our first run. Poll until it shows
	-- up (or the mode gets released) so the guard always lands.
	if suppress and not suppressWatch then
		local left = 30
		suppressWatch = C_Timer.NewTicker(0.5, function()
			left = left - 1
			-- bail if the mode flipped back while the watch was running
			if db and db.tracker ~= "sentiui" then
				suppressWatch:Cancel()
				suppressWatch = nil
				return
			end
			local b = _G.Questie_BaseFrame
			local found = type(b) == "table" and b.Hide
			if found then
				b._sentiReleased = nil
				if not b._sentiSuppressed then
					b._sentiSuppressed = true
					b:HookScript("OnShow", function(self)
						if not self._sentiReleased then self:Hide() end
					end)
				end
				b:Hide()
			end
			if found or left <= 0 then
				suppressWatch:Cancel()
				suppressWatch = nil
			end
		end)
	end
end

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
	SuppressTracker(ours)
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
