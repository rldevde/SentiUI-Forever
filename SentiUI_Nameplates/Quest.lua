-- Quest-mob marker: a gold "!" beside a plate whose unit name appears in
-- an unfinished quest objective line. Objective texts rescan on quest log
-- events; matching is a plain substring check, so it works in every
-- locale without parsing "0/8" counts. A secret unit name or objective
-- text just never marks.
local _, ns = ...
local S = SentiUI

local Quest = {}
ns.Quest = Quest

local texts = {}
local dirty = true

local function CollectObjective(questID)
	if C_QuestLog and C_QuestLog.GetQuestObjectives then
		local okO, objs = pcall(C_QuestLog.GetQuestObjectives, questID)
		if okO and type(objs) == "table" then
			for _, o in ipairs(objs) do
				local okF, add = pcall(function()
					return o.finished == false and type(o.text) == "string"
						and o.text ~= ""
				end)
				if okF and add then texts[#texts + 1] = o.text end
			end
			return
		end
	end
	if GetQuestLogLeaderBoard then
		for j = 1, 20 do
			local okL, text, _, fin = pcall(GetQuestLogLeaderBoard, j, questID)
			if not okL or type(text) ~= "string" then break end
			if fin == false then texts[#texts + 1] = text end
		end
	end
end

local function Rescan()
	dirty = false
	wipe(texts)
	local n = 0
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		local ok, a, b = pcall(C_QuestLog.GetNumQuestLogEntries)
		if ok then n = tonumber(b or a) or 0 end
	elseif GetNumQuestLogEntries then
		local ok, a, b = pcall(GetNumQuestLogEntries)
		if ok then n = tonumber(b or a) or 0 end
	end
	for i = 1, n do
		local id, isHeader
		if C_QuestLog and C_QuestLog.GetInfo then
			local okI, info = pcall(C_QuestLog.GetInfo, i)
			if okI and type(info) == "table" then
				id, isHeader = info.questID, info.isHeader
			end
		elseif GetQuestLogTitle then
			local okI, _, _, _, hdr, _, _, _, qid =
				pcall(GetQuestLogTitle, i)
			if okI then id, isHeader = qid, hdr end
		end
		if id and isHeader ~= true then CollectObjective(id) end
	end
end

function Quest.Dirty() dirty = true end

function Quest.IsQuestMob(unit)
	if dirty then Rescan() end
	if #texts == 0 then return false end
	local ok, name = pcall(UnitName, unit)
	if not ok or type(name) ~= "string" or name == "" then return false end
	for _, t in ipairs(texts) do
		local okF, hit = pcall(string.find, t, name, 1, true)
		if okF and hit then return true end
	end
	return false
end

function Quest.Register()
	for _, ev in ipairs({ "QUEST_LOG_UPDATE", "QUEST_WATCH_UPDATE",
		"QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN",
		"UNIT_QUEST_LOG_CHANGED", "PLAYER_ENTERING_WORLD" }) do
		S.RegisterEvent(ev, function(_, unit)
			if unit and unit ~= "player" then return end
			Quest.Dirty()
			local M = ns.Manager
			if M and M.byUnit then
				for _, p in pairs(M.byUnit) do
					S.SafeCall("plates:quest", function()
						if ns.Plate and ns.Plate.Update then
							ns.Plate.Update(p)
						end
					end)
				end
			end
		end)
	end
end
