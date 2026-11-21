-- Auto quest accept / turn-in. Walks the NPC dialogs on its own:
-- QUEST_DETAIL accepts, QUEST_PROGRESS completes when finishable,
-- QUEST_COMPLETE turns in when there is at most one reward to pick
-- (a real choice is never auto-picked), GOSSIP_SHOW / QUEST_GREETING
-- take the first offered or completable quest. Holding SHIFT skips the
-- automation for that one interaction so the dialog can be read.
local _, ns = ...
local S = SentiUI
local L = ns.L

local AutoQuest = {}
ns.AutoQuest = AutoQuest

local db

local function On()
	return db and db.autoQuest and not IsShiftKeyDown()
end

-- trivial ("gray") quests are skipped by auto-accept unless the option
-- is off - manual accepting is unaffected. Detection order: the native
-- trivial flag, the gossip entry's isTrivial field, then a gray
-- difficulty band vs player level via GetQuestDifficultyColor
local function TrivialQuest(questID, level, isTrivial)
	if db and db.autoQuestSkipTrivial == false then return false end
	if isTrivial == true then return true end
	if questID and C_QuestLog and C_QuestLog.IsQuestTrivial then
		local ok, t = pcall(C_QuestLog.IsQuestTrivial, questID)
		if ok and not S.IsSecret(t) then return t == true end
	end
	if type(level) == "number" and not S.IsSecret(level)
		and GetQuestDifficultyColor then
		local ok, c = pcall(GetQuestDifficultyColor, level)
		if ok and type(c) == "table" and type(c.r) == "number" then
			-- the trivial color is a flat mid-gray in every locale
			return math.abs(c.r - c.g) < 0.02 and math.abs(c.g - c.b) < 0.02
				and c.r < 0.65
		end
	end
	return false
end

-- dialog events ---------------------------------------------------------------
local function Detail()
	if not On() or not AcceptQuest then return end
	local id = GetQuestID and GetQuestID() or nil
	if TrivialQuest(id) then return end
	pcall(AcceptQuest)
end

local function ProgressStep()
	if not On() then return end
	if IsQuestCompletable and IsQuestCompletable() and CompleteQuest then
		pcall(CompleteQuest)
	end
end

local function Complete()
	if not On() then return end
	local n = 0
	if GetNumQuestChoices then
		local ok, c = pcall(GetNumQuestChoices)
		if ok and type(c) == "number" then n = c end
	end
	if n <= 1 and GetQuestReward then pcall(GetQuestReward, 1) end
end

-- gossip: completable active quests first, then the first offered quest
local function Gossip()
	if not On() or not C_GossipInfo then return end
	if C_GossipInfo.GetActiveQuests and C_GossipInfo.SelectActiveQuest then
		local ok, list = pcall(C_GossipInfo.GetActiveQuests)
		if ok and type(list) == "table" and not S.IsSecretTable(list) then
			for i, q in ipairs(list) do
				if type(q) == "table" and q.isComplete ~= false then
					pcall(C_GossipInfo.SelectActiveQuest, i)
					return
				end
			end
		end
	end
	if C_GossipInfo.GetAvailableQuests and C_GossipInfo.SelectAvailableQuest then
		local ok, list = pcall(C_GossipInfo.GetAvailableQuests)
		if ok and type(list) == "table" and not S.IsSecretTable(list) then
			for i, q in ipairs(list) do
				if type(q) == "table" then
					if not TrivialQuest(q.questID, q.level,
						(q.isTrivial or q.isLowLevel) == true) then
						pcall(C_GossipInfo.SelectAvailableQuest, i)
						return
					end
				end
			end
		end
	end
end

-- older greeting flow for multi-quest NPCs: completable actives first
local function Greeting()
	if not On() then return end
	if type(GetNumActiveQuests) == "function"
		and type(SelectActiveQuest) == "function" then
		local ok, n = pcall(GetNumActiveQuests)
		if ok and type(n) == "number" and n > 0 then
			pcall(SelectActiveQuest, 1)
			return
		end
	end
	if type(GetNumAvailableQuests) == "function"
		and type(SelectAvailableQuest) == "function" then
		local ok, n = pcall(GetNumAvailableQuests)
		if ok and type(n) == "number" and n > 0 then
			for i = 1, n do
				local trivial
				if type(IsAvailableQuestTrivial) == "function" then
					local okT, t = pcall(IsAvailableQuestTrivial, i)
					trivial = okT and t == true or nil
				end
				local level
				if type(GetAvailableLevel) == "function" then
					local okL, lv = pcall(GetAvailableLevel, i)
					if okL then level = lv end
				end
				if not TrivialQuest(nil, level, trivial) then
					pcall(SelectAvailableQuest, i)
					return
				end
			end
		end
	end
end

-- escort/multi-turn quests ask for an explicit accept confirm
local function Confirm()
	if On() and ConfirmAcceptQuest then pcall(ConfirmAcceptQuest) end
end

function AutoQuest.SetDb(d) db = d end

-- Dialog step -> handler. QUEST_*/GOSSIP_* events fire inside the
-- NPC-interact dispatch, where running Lua taints the client's
-- secret-safe dialog updates. Instead a 0.15s poll watches which
-- dialog sub-panel is visible and runs the matching handler once per
-- step change - same behavior, different dispatch.
local STEPS = {
	{ name = "QUEST_DETAIL", fn = Detail,
		frames = { "QuestDetailScrollFrame", "QuestFrameDetailPanel" } },
	{ name = "QUEST_PROGRESS", fn = ProgressStep,
		frames = { "QuestProgressScrollFrame", "QuestFrameProgressPanel" } },
	{ name = "QUEST_COMPLETE", fn = Complete,
		frames = { "QuestRewardScrollFrame", "QuestFrameRewardPanel" } },
	{ name = "QUEST_GREETING", fn = Greeting,
		frames = { "QuestGreetingScrollFrame", "QuestFrameGreetingPanel" } },
	{ name = "GOSSIP_SHOW", fn = Gossip,
		frames = { "GossipGreetingScrollFrame", "GossipFrameGreetingPanel" } },
}

local function DialogOpen()
	local qf = _G.QuestFrame
	local gf = _G.GossipFrame
	return (qf and qf:IsShown()) or (gf and gf:IsShown()) or false
end

local stepSeen = {}
function AutoQuest.Apply()
	local confirmSeen = false
	C_Timer.NewTicker(0.15, function()
		local open = DialogOpen()
		for _, st in ipairs(STEPS) do
			local on = false
			if open then
				for _, n in ipairs(st.frames) do
					local p = _G[n]
					if p and p:IsShown() then on = true break end
				end
			end
			if on and not stepSeen[st.name] then
				S.SafeCall("autoQuest:" .. st.name, st.fn)
			end
			stepSeen[st.name] = on
		end
		if not open then wipe(stepSeen) end
		local confirm = type(StaticPopup_Visible) == "function"
			and StaticPopup_Visible("QUEST_ACCEPT_CONFIRM") and true or false
		if confirm and not confirmSeen then
			S.SafeCall("autoQuest:QUEST_ACCEPT_CONFIRM", Confirm)
		end
		confirmSeen = confirm
	end)
end

-- /sqauto: which pieces are live - option state + poll coverage
SLASH_SENTIUIQUESTAUTO1 = "/sqauto"
SlashCmdList.SENTIUIQUESTAUTO = function()
	print("|cffebad33sqauto:|r enabled=" .. tostring(db and db.autoQuest == true)
		.. "  (dialog poll: 0.15s)")
end
