-- luacheck: read globals C_Container C_Item C_Timer GetServerTime GetMoney
-- luacheck: read globals UnitClass UnitFactionGroup UnitLevel UnitRace GetGuildInfo
-- luacheck: read globals GetInventoryItemID GetInventoryItemLink GetContainerNumSlots
-- luacheck: read globals GetContainerItemInfo GetContainerNumFreeSlots GetItemInfo
-- luacheck: read globals Enum BANK_CONTAINER REAGENTBANK_CONTAINER NUM_BAG_SLOTS
-- luacheck: read globals NUM_BANKBAGSLOTS issecretvalue ipairs pairs type tostring
-- luacheck: read globals tonumber select unpack math table
-- luacheck: read globals UnitXP UnitXPMax GetXPExhaustion GetRestState GetMaxPlayerLevel
-- luacheck: read globals GetRealZoneText GetZoneText GetSubZoneText GetBindLocation
-- luacheck: read globals GetAverageItemLevel GetTotalAchievementPoints
-- luacheck: read globals GetNumCompletedAchievements GetNumTitles IsTitleKnown
-- luacheck: read globals GetCategoryList GetCategoryNumAchievements PlayerHasToy
-- luacheck: read globals GetProfessions
-- luacheck: read globals GetProfessionInfo GetNumSavedInstances GetSavedInstanceInfo
-- luacheck: read globals GetSavedInstanceEncounterInfo GetNumSavedWorldBosses
-- luacheck: read globals GetSavedWorldbossInfo RequestRaidInfo RequestTimePlayed
-- luacheck: read globals C_MountJournal C_PetJournal C_ToyBox
-- luacheck: read globals EJ_GetInstanceByIndex EJ_SelectInstance
-- luacheck: read globals EJ_GetEncounterInfoByIndex EJ_GetNumTiers EJ_SelectTier
-- luacheck: read globals C_CurrencyInfo C_Reputation C_TradeSkillUI C_EquipmentSet
-- luacheck: read globals GetCurrencyListSize GetCurrencyListInfo ExpandCurrencyList
-- luacheck: read globals GetNumFactions GetFactionInfo ExpandAllFactionHeaders
-- luacheck: read globals GetSpecialization GetSpecializationInfo
-- luacheck: read globals GetInboxNumItems GetInboxHeaderInfo GetInboxItemLink GetInboxItem
-- luacheck: read globals GetAchievementInfo
-- luacheck: read globals GetNumQuestLogEntries GetQuestLogTitle GetInventoryItemDurability
-- luacheck: read globals GetPVPLifetimeStats GetNumTradeSkills GetTradeSkillInfo
-- luacheck: read globals GetTradeSkillCooldown GetFriendshipReputation
local _, ns = ...

-- Snapshot scanner: keeps the own character's record in ns.db.chars
-- current. Money and bags update live; the bank snapshot only refreshes
-- while the bank frame is open (the client reports nothing otherwise);
-- worn gear updates on equipment changes.
local Scanner = {}
ns.Scanner = Scanner

local Store = ns.Store

local BAG_DEBOUNCE = 0.4
local FIRE_DEBOUNCE = 0.5

local bankOpen = false
local bagsQueued = false
local bankQueued = false
local gearQueued = false
local fireQueued = false

local function IsSecret(v)
	return issecretvalue ~= nil and issecretvalue(v)
end

local function Plain(v)
	if IsSecret(v) then
		return nil
	end
	return v
end

-- Coalesced SAI_CHAR_CHANGED so a burst of bag events repaints once.
local function Changed()
	if fireQueued then
		return
	end
	fireQueued = true
	C_Timer.After(FIRE_DEBOUNCE, function()
		fireQueued = false
		ns:Fire("SAI_CHAR_CHANGED")
		ns:Fire("SAI_CHARS_CHANGED")
	end)
end

local function Stamp(char, field)
	char[field] = GetServerTime()
	char.updated = char[field]
end

--------------------------------------------------------------------------------
-- Container helpers
--------------------------------------------------------------------------------

local function NumSlots(bag)
	local f = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
	if not f then
		return 0
	end
	local ok, n = pcall(f, bag)
	return (ok and type(n) == "number" and n > 0) and n or 0
end

local function SlotItem(bag, slot)
	if C_Container and C_Container.GetContainerItemInfo then
		local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
		if ok and type(info) == "table" and not IsSecret(info.itemID) then
			local id = tonumber(info.itemID)
			local count = tonumber(info.stackCount) or 1
			if id then
				return id, count
			end
		end
	elseif GetContainerItemInfo then
		local ok, _, count, _, _, _, link = pcall(GetContainerItemInfo, bag, slot)
		if ok and link and not IsSecret(link) then
			local id = tonumber(tostring(link):match("item:(%d+)"))
			return id, (tonumber(count) or 1)
		end
	end
end

-- Count table { [itemID] = total } over a container id list.
local function ScanContainers(containers)
	local out = {}
	for _, bag in ipairs(containers) do
		for slot = 1, NumSlots(bag) do
			local id, count = SlotItem(bag, slot)
			if id then
				out[id] = (out[id] or 0) + count
			end
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- Carried bags (0-4 plus the reagent bag 5 on this client)
--------------------------------------------------------------------------------

local carried = {}

local function CarriedContainers()
	for i = #carried, 1, -1 do
		carried[i] = nil
	end
	for bag = 0, 5 do
		if NumSlots(bag) > 0 then
			carried[#carried + 1] = bag
		end
	end
	return carried
end

local function ScanBags()
	bagsQueued = false
	local char = Store.OwnChar()
	if not char then
		return
	end
	local newBags = ScanContainers(CarriedContainers())
	-- Activity log: item deltas vs the previous snapshot (max 15 entries,
	-- powers "recently gained/lost" on the character page).
	local old = char.bags
	if type(old) == "table" and char.bagsAt then
		local delta, seen
		for id, n in pairs(newBags) do
			seen = seen or {}
			seen[id] = true
			local d = n - (old[id] or 0)
			if d ~= 0 then
				delta = delta or {}
				delta[id] = d
			end
		end
		for id, n in pairs(old or {}) do
			if not (seen and seen[id]) and n > 0 then
				delta = delta or {}
				delta[id] = -n
			end
		end
		if delta then
			local act = char.activity or {}
			act[#act + 1] = { t = GetServerTime(), items = delta }
			if #act > 15 then
				table.remove(act, 1)
			end
			char.activity = act
		end
	end
	char.bags = newBags
	Stamp(char, "bagsAt")
	Changed()
end

local function QueueBags()
	if bagsQueued then
		return
	end
	bagsQueued = true
	C_Timer.After(BAG_DEBOUNCE, ScanBags)
end

--------------------------------------------------------------------------------
-- Bank (only readable while the bank frame is open)
--------------------------------------------------------------------------------

local bankContainers = {}

local function BankContainers()
	for i = #bankContainers, 1, -1 do
		bankContainers[i] = nil
	end
	local seen = {}
	local function Add(bag)
		if type(bag) == "number" and not seen[bag] then
			seen[bag] = true
			bankContainers[#bankContainers + 1] = bag
		end
	end
	Add(BANK_CONTAINER or -1)
	local reag = REAGENTBANK_CONTAINER
		or (Enum and Enum.BagIndex and Enum.BagIndex.Reagentbank)
	Add(reag)
	local bagCount = NUM_BAG_SLOTS
		or (Enum and Enum.BagIndex and Enum.BagIndex.BankBag_1
			and (Enum.BagIndex.BankBag_1 - 1))
		or 5
	for b = bagCount + 1, bagCount + (NUM_BANKBAGSLOTS or 7) do
		Add(b)
	end
	-- Character bank tabs (Camelot/retail enum values).
	if Enum and Enum.BagIndex then
		local tabs = {}
		for k, v in pairs(Enum.BagIndex) do
			if type(k) == "string" and k:lower():find("^characterbanktab") then
				tabs[#tabs + 1] = v
			end
		end
		table.sort(tabs)
		for _, v in ipairs(tabs) do
			Add(v)
		end
	end
	return bankContainers
end

local function ScanBank()
	bankQueued = false
	if not bankOpen then
		return
	end
	local char = Store.OwnChar()
	if not char then
		return
	end
	char.bank = ScanContainers(BankContainers())
	Stamp(char, "bankAt")
	Changed()
end

local function QueueBank()
	if not bankOpen or bankQueued then
		return
	end
	bankQueued = true
	-- Container events fire per slot during a move burst: one scan when
	-- the burst settles, not one per event.
	C_Timer.After(BAG_DEBOUNCE, ScanBank)
end

--------------------------------------------------------------------------------
-- Worn gear
--------------------------------------------------------------------------------

local function ScanGear()
	gearQueued = false
	local char = Store.OwnChar()
	if not char then
		return
	end
	local gear = {}
	for slot = 1, 19 do
		local ok, id = pcall(GetInventoryItemID, "player", slot)
		id = ok and Plain(id) or nil
		if type(id) == "number" then
			gear[slot] = id
		end
	end
	char.gear = gear
	Stamp(char, "gearAt")
	Changed()
end

local function QueueGear()
	if gearQueued then
		return
	end
	gearQueued = true
	C_Timer.After(BAG_DEBOUNCE, ScanGear)
end

--------------------------------------------------------------------------------
-- Money + character metadata
--------------------------------------------------------------------------------

local function ScanMoney()
	local char = Store.OwnChar()
	if not char then
		return
	end
	local ok, money = pcall(GetMoney)
	money = ok and Plain(money) or nil
	if type(money) == "number" then
		local prev = char.money
		char.money = money
		-- Gold history: one point per ~6h (or on any money change after
		-- that gap), capped so the table stays small. Powers the weekly
		-- trend on the dashboard.
		local hist = char.goldHist or {}
		local now = GetServerTime()
		local last = hist[#hist]
		if not last or (now - (last.t or 0)) >= 21600 or last.g ~= money then
			hist[#hist + 1] = { t = now, g = money }
			if #hist > 90 then
				table.remove(hist, 1)
			end
			char.goldHist = hist
		end
			-- Activity log: gold deltas, same ring buffer the bag-diff
		-- entries use.
		if type(prev) == "number" and prev ~= money then
			local act = char.activity or {}
			act[#act + 1] = { t = GetServerTime(), gold = money - prev }
			if #act > 15 then
				table.remove(act, 1)
			end
			char.activity = act
		end
		Stamp(char, "moneyAt")
		Changed()
	end
end

local function ScanMeta()
	local char, key = Store.OwnChar()
	if not char then
		return
	end
	char.name = ns:GetPlayerName() or ns.ShortName(key)
	char.realm = ns.OwnRealm()
	local ok, _, classFile = pcall(UnitClass, "player")
	if ok and type(classFile) == "string" then
		char.class = classFile
	end
	local okF, faction = pcall(UnitFactionGroup, "player")
	if okF and type(faction) == "string" then
		char.faction = faction
	end
	local okR, race = pcall(UnitRace, "player")
	if okR and type(race) == "string" then
		char.race = race
	end
	local okL, level = pcall(UnitLevel, "player")
	if okL and type(level) == "number" then
		char.level = level
	end
	local okG, guild = pcall(GetGuildInfo, "player")
	if okG and type(guild) == "string" and guild ~= "" then
		char.guild = guild
	else
		char.guild = nil
	end
	Stamp(char, "updated")
end

--------------------------------------------------------------------------------
-- Character statistics (XP, location, professions, collections, ...)
--------------------------------------------------------------------------------
-- Every call is optional: an API that the client's flavour does not ship
-- simply leaves its field nil — the UI shows "-" for it. This keeps the
-- addon loading unchanged across Forever, retail and classic flavours.

local function PlainCall(func, ...)
	if type(func) ~= "function" then
		return nil
	end
	local ok, v = pcall(func, ...)
	if not ok then
		return nil
	end
	return Plain(v)
end

local function AvgItemLevel()
	local v = PlainCall(GetAverageItemLevel)
	if type(v) == "number" and v > 0 then
		return math.floor(v * 10 + 0.5) / 10
	end
	-- Fallback: average over the visible gear slots (1-3, 5-17).
	local total, n = 0, 0
	for _, slot in ipairs({ 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }) do
		local link = PlainCall(GetInventoryItemLink, "player", slot)
		if link then
			local ok, _, _, _, ilvl = pcall(GetItemInfo, link)
			ilvl = ok and Plain(ilvl) or nil
			if type(ilvl) == "number" then
				total = total + ilvl
				n = n + 1
			end
		end
	end
	if n > 0 then
		return math.floor(total / n * 10 + 0.5) / 10
	end
end

local function ScanProfessions()
	local out = {}
	if GetProfessions and GetProfessionInfo then
		local ok, p1, p2, p3, p4, p5 = pcall(GetProfessions)
		if ok then
			for _, index in ipairs({ p1, p2, p3, p4, p5 }) do
				if index then
					local r = { pcall(GetProfessionInfo, index) }
					local name = r[1] and Plain(r[2]) or nil
					if type(name) == "string" then
						out[#out + 1] = {
							name = name,
							icon = Plain(r[3]),
							cur = tonumber(Plain(r[4])) or 0,
							max = tonumber(Plain(r[5])) or 0,
						}
					end
				end
			end
		end
	end
	return out
end

-- GetCategoryNumAchievements returns (numAchievements, numCompleted,
-- pointsEarned) per category on flavours that support it. Summed over
-- GetCategoryList these are the real achievement totals. If a client
-- only returns the count, fall back to per-achievement GetAchievementInfo
-- (id, name, points, completed, ... - completed is the 4th return).
-- Cached per session; GetNumCompletedAchievements/GetTotalAchievementPoints
-- remain the last resort. Returns points, done or nil.
local achvCache
local function CountAchievements()
	if achvCache then
		return achvCache.points, achvCache.done
	end
	if not (GetCategoryList and GetCategoryNumAchievements) then
		return nil
	end
	local ok, cats = pcall(GetCategoryList)
	if not ok or not ns.CanAccessTable(cats) then
		return nil
	end
	local done, points, usable = 0, 0, false
	for _, cat in ipairs(cats) do
		local r = { pcall(GetCategoryNumAchievements, cat) }
		if r[1] then
			local c, p = tonumber(Plain(r[3])), tonumber(Plain(r[4]))
			if c or p then
				usable = true
			end
			done = done + (c or 0)
			points = points + (p or 0)
		end
	end
	if not usable and GetAchievementInfo then
		for _, cat in ipairs(cats) do
			local num = tonumber(PlainCall(GetCategoryNumAchievements, cat)) or 0
			for i = 1, num do
				local r = { pcall(GetAchievementInfo, cat, i) }
				if r[1] and r[2] then
					usable = true
					if Plain(r[5]) == true or Plain(r[14]) == true then
						done = done + 1
						points = points + (tonumber(Plain(r[4])) or 0)
					end
				end
			end
		end
	end
	if usable then
		achvCache = { points = points, done = done }
		return points, done
	end
end

local function ScanStats()
	local char = Store.OwnChar()
	if not char then
		return
	end
	local s = char.stats or {}
	char.stats = s

	s.xp = PlainCall(UnitXP, "player")
	s.xpMax = PlainCall(UnitXPMax, "player")
	s.rested = PlainCall(GetXPExhaustion)
	s.restState = PlainCall(GetRestState)
	local maxLevel = PlainCall(GetMaxPlayerLevel)
	s.maxLevel = (type(maxLevel) == "number" and type(char.level) == "number"
		and char.level >= maxLevel) or nil

	-- Daily progress: fold the delta since the previous scan into today's
	-- bucket (xp, level-ups, played seconds). Level-ups wrap the bar -
	-- the rest of the previous bar counts first, then whatever the new
	-- bar already holds. Kept per character in char.daily["YYYY-MM-DD"];
	-- dailyState carries the last absolute sample (xp alone is useless
	-- for deltas because the bar resets on level-up).
	if type(char.level) == "number" then
		local day = date("%Y-%m-%d")
		local st = char.dailyState
		local gained, lvls = 0, 0
		if st and type(st.level) == "number" then
			if char.level > st.level then
				lvls = char.level - st.level
				if type(st.xp) == "number" and type(st.xpMax) == "number"
					and st.xpMax > st.xp then
					gained = st.xpMax - st.xp
				end
				if type(s.xp) == "number" then
					gained = gained + s.xp
				end
			elseif char.level == st.level and type(st.xp) == "number"
				and type(s.xp) == "number" and s.xp > st.xp then
				gained = s.xp - st.xp
			end
		end
		local play
		if st and type(st.played) == "number" and char.played
			and type(char.played.total) == "number"
			and char.played.total > st.played then
			play = char.played.total - st.played
		end
		if gained > 0 or lvls > 0 or (play and play > 0) then
			char.daily = char.daily or {}
			local today = char.daily[day]
			if not today then
				today = { xp = 0, lvl = 0, played = 0 }
				char.daily[day] = today
			end
			today.xp = (today.xp or 0) + gained
			today.lvl = (today.lvl or 0) + lvls
			if play then
				today.played = (today.played or 0) + play
			end
			-- bound the history to the newest 14 day keys
			local keys = {}
			for k in pairs(char.daily) do
				keys[#keys + 1] = k
			end
			table.sort(keys)
			for i = 1, #keys - 14 do
				char.daily[keys[i]] = nil
			end
		end
		char.dailyState = {
			level = char.level, xp = s.xp, xpMax = s.xpMax,
			played = (char.played and char.played.total)
				or (st and st.played),
		}
	end

	s.zone = PlainCall(GetRealZoneText) or PlainCall(GetZoneText)
	local sub = PlainCall(GetSubZoneText)
	s.subzone = (type(sub) == "string" and sub ~= "") and sub or nil
	s.bind = PlainCall(GetBindLocation)
	s.itemLevel = AvgItemLevel()

	-- Achievements: GetTotalAchievementPoints reports 0 on this server.
	-- GetCategoryNumAchievements returns per-category completed counts
	-- and earned points, so the real numbers are summed by hand.
	local points, done = CountAchievements()
	s.achievementPoints = (points ~= nil) and points
		or PlainCall(GetTotalAchievementPoints)
	s.achievements = (done ~= nil) and done
		or PlainCall(GetNumCompletedAchievements)

	-- Titles: GetNumTitles counts every title in the game data, not the
	-- earned ones - count IsTitleKnown instead.
	if GetNumTitles and IsTitleKnown then
		local total = tonumber(PlainCall(GetNumTitles)) or 0
		local known = 0
		for i = 1, total do
			local r = { pcall(IsTitleKnown, i) }
			if r[1] and Plain(r[2]) == true then
				known = known + 1
			end
		end
		s.titles = known
	else
		s.titles = nil
	end

	-- Mounts: GetNumMounts counts all journal entries incl. uncollected
	-- ones - count the isCollected flag (11th return of GetMountInfoByID).
	s.mounts = nil
	if C_MountJournal and C_MountJournal.GetMountIDs and C_MountJournal.GetMountInfoByID then
		local ok, ids = pcall(C_MountJournal.GetMountIDs)
		if ok and ns.CanAccessTable(ids) then
			local n = 0
			for _, id in ipairs(ids) do
				local r = { pcall(C_MountJournal.GetMountInfoByID, id) }
				if r[1] and Plain(r[12]) == true then
					n = n + 1
				end
			end
			s.mounts = n
		end
	elseif C_MountJournal and C_MountJournal.GetNumDisplayedMounts
		and C_MountJournal.GetDisplayedMountInfo then
		local total = tonumber(PlainCall(C_MountJournal.GetNumDisplayedMounts)) or 0
		local n = 0
		for i = 1, total do
			local r = { pcall(C_MountJournal.GetDisplayedMountInfo, i) }
			if r[1] and Plain(r[12]) == true then
				n = n + 1
			end
		end
		s.mounts = n
	end

	-- Pets: count the isOwned flag (3rd return of GetPetInfoByIndex)
	-- rather than trusting GetNumPets' second return, whose meaning
	-- varies between clients.
	s.pets = nil
	if C_PetJournal and C_PetJournal.GetNumPets and C_PetJournal.GetPetInfoByIndex then
		local total = tonumber(PlainCall(C_PetJournal.GetNumPets)) or 0
		local n = 0
		for i = 1, total do
			local r = { pcall(C_PetJournal.GetPetInfoByIndex, i) }
			if r[1] and Plain(r[4]) == true then
				n = n + 1
			end
		end
		s.pets = n
	end

	-- Toys: learned count when the API offers it, else iterate the toy
	-- box and test PlayerHasToy per entry.
	s.toys = nil
	if C_ToyBox and C_ToyBox.GetNumLearnedDisplayedToys then
		s.toys = tonumber(PlainCall(C_ToyBox.GetNumLearnedDisplayedToys))
	elseif C_ToyBox and C_ToyBox.GetNumToys and C_ToyBox.GetToyFromIndex and PlayerHasToy then
		local total = tonumber(PlainCall(C_ToyBox.GetNumToys)) or 0
		local n = 0
		for i = 1, total do
			local itemID = PlainCall(C_ToyBox.GetToyFromIndex, i)
			if itemID and PlayerHasToy(itemID) then
				n = n + 1
			end
		end
		s.toys = n
	end

	local free, total = 0, 0
	local numFree = C_Container and C_Container.GetContainerNumFreeSlots
		or GetContainerNumFreeSlots
	for bag = 0, 5 do
		local n = NumSlots(bag)
		total = total + n
		if n > 0 and numFree then
			free = free + (tonumber(PlainCall(numFree, bag)) or 0)
		end
	end
	s.bagSlots = total
	s.freeBagSlots = free

	s.professions = ScanProfessions()

	-- Active spec: GetSpecializationInfo returns (id, name, description,
	-- icon, role, ...) - name and role are the useful parts.
	s.spec = nil
	if GetSpecialization and GetSpecializationInfo then
		local idx = tonumber(PlainCall(GetSpecialization))
		if idx then
			local r = { pcall(GetSpecializationInfo, idx) }
			if r[1] and type(Plain(r[3])) == "string" then
				s.spec = {
					name = Plain(r[3]),
					icon = Plain(r[5]),
					role = Plain(r[6]),
				}
			end
		end
	end

	-- Equipment sets: GetEquipmentSetInfo returns (name, icon, setID,
	-- isEquipped, numItems, ...) per C_EquipmentSet.GetEquipmentSetIDs id.
	s.equipSets = nil
	if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs
		and C_EquipmentSet.GetEquipmentSetInfo then
		local ok, ids = pcall(C_EquipmentSet.GetEquipmentSetIDs)
		if ok and ns.CanAccessTable(ids) then
			local sets = {}
			for _, id in ipairs(ids) do
				local r = { pcall(C_EquipmentSet.GetEquipmentSetInfo, id) }
				if r[1] and type(Plain(r[2])) == "string" then
					sets[#sets + 1] = {
						name = Plain(r[2]),
						icon = Plain(r[3]),
						items = tonumber(Plain(r[6])) or 0,
					}
				end
			end
			table.sort(sets, function(a, b)
				return (a.name or "") < (b.name or "")
			end)
			s.equipSets = sets
		end
	end

	-- Durability: worst percentage across the gear slots that can wear.
	s.durability = nil
	if GetInventoryItemDurability then
		local worst
		for _, slot in ipairs({ 1, 3, 5, 6, 7, 8, 9, 10, 16, 17 }) do
			local r = { pcall(GetInventoryItemDurability, slot) }
			local cur = r[1] and tonumber(Plain(r[2])) or nil
			local max = r[1] and tonumber(Plain(r[3])) or nil
			if cur and max and max > 0 then
				local pct = math.floor(cur / max * 100 + 0.5)
				if not worst or pct < worst then
					worst = pct
				end
			end
		end
		s.durability = worst
	end

	-- PvP: lifetime honorable kills (first return), rank name if any.
	if GetPVPLifetimeStats then
		local r = { pcall(GetPVPLifetimeStats) }
		if r[1] then
			s.pvpHK = tonumber(Plain(r[2]))
			local rn = Plain(r[5])
			s.pvpRank = type(rn) == "string" and rn or nil
		end
	end

	-- Achievement watchlist: user-picked IDs from settings; store the
	-- per-char earned flag (wasEarnedByMe, 13th return of
	-- GetAchievementInfo) so foreign chars keep their own results.
	s.watch = nil
	local wl = ns.db.settings and ns.db.settings.watchlist
	if type(wl) == "table" and #wl > 0 and GetAchievementInfo then
		local w = {}
		for _, id in ipairs(wl) do
			id = tonumber(id)
			if id then
				local r = { pcall(GetAchievementInfo, id) }
				if r[1] then
					w[id] = Plain(r[14]) == true or nil
				end
			end
		end
		s.watch = w
	end

	char.statsAt = GetServerTime()
	char.updated = char.statsAt
	Changed()
end

--------------------------------------------------------------------------------
-- Playtime (RequestTimePlayed -> TIME_PLAYED_MSG, async)
--------------------------------------------------------------------------------

local function RequestPlaytime()
	if RequestTimePlayed then
		pcall(RequestTimePlayed)
	end
end

ns:RegisterEvent("TIME_PLAYED_MSG", function(_, totalPlayed, levelPlayed)
	local char = Store.OwnChar()
	if not char then
		return
	end
	totalPlayed = Plain(totalPlayed)
	levelPlayed = Plain(levelPlayed)
	if type(totalPlayed) ~= "number" then
		return
	end
	char.played = char.played or {}
	char.played.total = totalPlayed
	char.played.level = type(levelPlayed) == "number" and levelPlayed or nil
	char.playedAt = GetServerTime()
	Changed()
end)

--------------------------------------------------------------------------------
-- Saved instances: dungeon/raid lockouts with per-boss kills
--------------------------------------------------------------------------------
-- Boss names come from the encounter journal (EJ_* exists on this
-- client): built lazily once, mapped by instance name. Kill order in
-- the journal normally matches the lockout's encounter order, so the
-- first `progress` entries are marked killed. When the client's
-- GetSavedInstanceEncounterInfo exists it wins - real kill flags.

local journalCache

local function BuildJournalCache()
	journalCache = {}
	if type(EJ_GetInstanceByIndex) ~= "function"
		or type(EJ_SelectInstance) ~= "function"
		or type(EJ_GetEncounterInfoByIndex) ~= "function" then
		return
	end
	local tiers = tonumber(PlainCall(EJ_GetNumTiers)) or 1
	for tier = 1, tiers do
		if type(EJ_SelectTier) == "function" then
			pcall(EJ_SelectTier, tier)
		end
		for _, isRaid in ipairs({ true, false }) do
			for index = 1, 60 do
				local r = { pcall(EJ_GetInstanceByIndex, index, isRaid) }
				local instanceID, name = Plain(r[2]), Plain(r[3])
				if type(instanceID) ~= "number" then
					break
				end
				pcall(EJ_SelectInstance, instanceID)
				local bosses = {}
				for e = 1, 40 do
					local er = { pcall(EJ_GetEncounterInfoByIndex, e, instanceID) }
					local bname = Plain(er[2])
					if not bname then
						er = { pcall(EJ_GetEncounterInfoByIndex, e) }
						bname = Plain(er[2])
					end
					if type(bname) ~= "string" then
						break
					end
					bosses[#bosses + 1] = bname
				end
				if type(name) == "string" and #bosses > 0 then
					journalCache[name:lower()] = bosses
				end
			end
		end
	end
end

local function JournalBosses(instanceName)
	if type(instanceName) ~= "string" then
		return nil
	end
	if not journalCache then
		BuildJournalCache()
	end
	return journalCache[instanceName:lower()]
end

local function ScanLockouts()
	local char = Store.OwnChar()
	if not char then
		return
	end
	local out = {}
	if GetNumSavedInstances and GetSavedInstanceInfo then
		local num = tonumber(PlainCall(GetNumSavedInstances)) or 0
		for i = 1, num do
			local r = { pcall(GetSavedInstanceInfo, i) }
			if r[1] and type(Plain(r[2])) == "string" then
				-- name, id, reset, difficulty, locked, extended, idMS,
				-- isRaid, maxPlayers, diffName, numEncounters, progress
				local numEnc = tonumber(Plain(r[12])) or 0
				local entry = {
					name = Plain(r[2]),
					isRaid = Plain(r[9]) and true or false,
					maxPlayers = tonumber(Plain(r[10])) or nil,
					difficulty = Plain(r[11]) or Plain(r[5]),
					progress = tonumber(Plain(r[13])) or 0,
					max = numEnc,
				}
				local reset = tonumber(Plain(r[4]))
				if reset and reset > 0 then
					entry.resetAt = GetServerTime() + reset
				end
				if GetSavedInstanceEncounterInfo and numEnc > 0 then
					entry.encounters = {}
					for e = 1, numEnc do
						local er = { pcall(GetSavedInstanceEncounterInfo, i, e) }
						-- bossName, fileDataID, killed
						if er[1] and type(Plain(er[2])) == "string" then
							entry.encounters[#entry.encounters + 1] = {
								name = Plain(er[2]),
								killed = Plain(er[4]) and true or false,
							}
						end
					end
				end
				if not entry.encounters or #entry.encounters == 0 then
					-- Encounter-journal fallback: journal order is the
					-- kill order, so the first `progress` bosses count
					-- as done.
					local bosses = JournalBosses(entry.name)
					if bosses then
						entry.encounters = {}
						for b, bname in ipairs(bosses) do
							entry.encounters[b] = {
								name = bname,
								killed = b <= entry.progress,
							}
						end
						if entry.max == 0 then
							entry.max = #bosses
						end
					end
				end
				out[#out + 1] = entry
			end
		end
	end
	-- World boss lockouts (retail-only API).
	if GetNumSavedWorldBosses and GetSavedWorldbossInfo then
		local num = tonumber(PlainCall(GetNumSavedWorldBosses)) or 0
		for i = 1, num do
			local r = { pcall(GetSavedWorldbossInfo, i) }
			-- name, worldBossID, reset
			if r[1] and type(Plain(r[2])) == "string" then
				local entry = { name = Plain(r[2]), worldBoss = true }
				local reset = tonumber(Plain(r[4]))
				if reset and reset > 0 then
					entry.resetAt = GetServerTime() + reset
				end
				out[#out + 1] = entry
			end
		end
	end
	char.lockouts = out
	char.lockoutsAt = GetServerTime()
	char.updated = char.lockoutsAt
	Changed()
end

local lockoutsQueued = false
local function QueueLockouts()
	if lockoutsQueued then
		return
	end
	lockoutsQueued = true
	C_Timer.After(BAG_DEBOUNCE, function()
		lockoutsQueued = false
		ScanLockouts()
	end)
end

--------------------------------------------------------------------------------
-- Currencies (C_CurrencyInfo on retail-like flavours, globals on classic)
--------------------------------------------------------------------------------
-- GetCurrencyListInfo returns a table { name, isHeader, isHeaderExpanded,
-- quantity, iconFileID, currencyID, maxQuantity } on modern clients and a
-- multi-return (name, isHeader, isHeaderExpanded, isUnused, isWatched,
-- quantity, iconFileID, maxQuantity, ...) on older ones.
-- Re-entrancy guards: expanding a faction/currency header fires
-- UPDATE_FACTION / CURRENCY_DISPLAY_UPDATE on this client, which would
-- call the scan again while it is still running -> C stack overflow.
local currenciesScanning = false
local repScanning = false

local function ScanCurrencies(allowExpand, rescanned)
	if currenciesScanning then
		return
	end
	local char = Store.OwnChar()
	if not char then
		return
	end
	local C = C_CurrencyInfo
	local listSize = (C and C.GetCurrencyListSize) or GetCurrencyListSize
	local listInfo = (C and C.GetCurrencyListInfo) or GetCurrencyListInfo
	if not (listSize and listInfo) then
		return
	end
	local expand = allowExpand
		and ((C and C.ExpandCurrencyList) or ExpandCurrencyList)
	local out = {}
	local expanded = false
	local n = tonumber(PlainCall(listSize)) or 0
	currenciesScanning = true
	for i = 1, n do
		local r = { pcall(listInfo, i) }
		local info = r[2]
		if r[1] and type(info) == "table" then
			if Plain(info.isHeader) and not Plain(info.isHeaderExpanded) and expand then
				pcall(expand, i, true)
				expanded = true
			elseif not Plain(info.isHeader) and type(Plain(info.name)) == "string" then
				out[#out + 1] = {
					id = tonumber(Plain(info.currencyID)),
					name = Plain(info.name),
					icon = Plain(info.iconFileID),
					qty = tonumber(Plain(info.quantity)) or 0,
					max = tonumber(Plain(info.maxQuantity)) or 0,
				}
			end
		elseif r[1] and type(Plain(r[2])) == "string" then
			if Plain(r[3]) and not Plain(r[4]) and expand then
				pcall(expand, i, true)
				expanded = true
			elseif not Plain(r[3]) then
				out[#out + 1] = {
					name = Plain(r[2]),
					icon = Plain(r[8]),
					qty = tonumber(Plain(r[7])) or 0,
					max = tonumber(Plain(r[9])) or 0,
				}
			end
		end
	end
	currenciesScanning = false
	-- Expanding a header inserts its children into the list: re-run once
	-- so the first scan already sees every currency.
	if expanded and not rescanned then
		return ScanCurrencies(allowExpand, true)
	end
	char.currencies = out
	Stamp(char, "currenciesAt")
	Changed()
end

local currenciesQueued = false
local function QueueCurrencies()
	if currenciesQueued then
		return
	end
	currenciesQueued = true
	C_Timer.After(BAG_DEBOUNCE, function()
		currenciesQueued = false
		ScanCurrencies(false)
	end)
end

--------------------------------------------------------------------------------
-- Reputation (C_Reputation tables or the classic GetFactionInfo returns)
--------------------------------------------------------------------------------
local function ScanReputation(allowExpand)
	if repScanning then
		return
	end
	local char = Store.OwnChar()
	if not char then
		return
	end
	local numFactions = C_Reputation and C_Reputation.GetNumFactions or GetNumFactions
	if not numFactions then
		return
	end
	local expandAll = allowExpand
		and (C_Reputation and C_Reputation.ExpandAllFactionHeaders
			or ExpandAllFactionHeaders)
	repScanning = true
	if expandAll then
		pcall(expandAll)
	end
	local byIndex = C_Reputation and C_Reputation.GetFactionDataByIndex
	local out = {}
	local n = tonumber(PlainCall(numFactions)) or 0
	for i = 1, n do
		if byIndex then
			local r = { pcall(byIndex, i) }
			local d = r[1] and r[2] or nil
			if type(d) == "table" and type(Plain(d.name)) == "string"
				and (not Plain(d.isHeader) or Plain(d.isHeaderWithRep)) then
				out[#out + 1] = {
					id = tonumber(Plain(d.factionID)),
					name = Plain(d.name),
					reaction = tonumber(Plain(d.reaction)) or 4,
					min = tonumber(Plain(d.currentReactionThreshold)) or 0,
					max = tonumber(Plain(d.nextReactionThreshold)) or 0,
					value = tonumber(Plain(d.currentStanding)) or 0,
					atWar = Plain(d.atWarWith) == true or nil,
				}
			end
		elseif GetFactionInfo then
			local r = { pcall(GetFactionInfo, i) }
			-- name, description, standingID, barMin, barMax, barValue,
			-- atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, ...
			if r[1] and type(Plain(r[2])) == "string"
				and (Plain(r[10]) ~= true or Plain(r[12]) == true) then
				out[#out + 1] = {
					id = tonumber(Plain(r[15])),
					name = Plain(r[2]),
					reaction = tonumber(Plain(r[4])) or 4,
					min = tonumber(Plain(r[5])) or 0,
					max = tonumber(Plain(r[6])) or 0,
					value = tonumber(Plain(r[7])) or 0,
					atWar = Plain(r[8]) == true or nil,
				}
			end
		else
			break
		end
	end
	repScanning = false
	-- Friendship factions (Chromie-style personal standings): the API
	-- returns a table whose .reaction holds the current level label.
	if GetFriendshipReputation then
		for _, entry in ipairs(out) do
			if entry.id then
				local r = { pcall(GetFriendshipReputation, entry.id) }
				local d = r[1] and r[2]
				if type(d) == "table" and type(Plain(d.reaction)) == "string" then
					entry.friend = Plain(d.reaction)
				end
			end
		end
	end
	char.reputations = out
	Stamp(char, "repAt")
	Changed()
end

local repQueued = false
local function QueueReputation()
	if repQueued then
		return
	end
	repQueued = true
	C_Timer.After(BAG_DEBOUNCE, function()
		repQueued = false
		ScanReputation(false)
	end)
end

--------------------------------------------------------------------------------
-- Recipes: GetAllRecipeIDs only covers the tradeskill window that is open
-- right now, so this harvests whenever a profession panel updates - the
-- bank model again. Stored per skill line: char.recipes[line] = { name,
-- list = { [recipeID] = { n, i } } }.
--------------------------------------------------------------------------------
local function ScanRecipes()
	local char = Store.OwnChar()
	if not char then
		return
	end
	local ts = C_TradeSkillUI
	if type(ts) ~= "table" or type(ts.GetAllRecipeIDs) ~= "function"
		or type(ts.GetRecipeInfo) ~= "function" then
		return
	end
	local profName, line
	if type(ts.GetTradeSkillLine) == "function" then
		local r = { pcall(ts.GetTradeSkillLine) }
		if r[1] then
			if type(Plain(r[2])) == "string" then
				-- (name, rank, max, lineID)
				profName = Plain(r[2])
				line = tonumber(Plain(r[5]))
			else
				-- (lineID, name, ...)
				line = tonumber(Plain(r[2]))
				profName = Plain(r[3])
			end
		end
	end
	local ok, ids = pcall(ts.GetAllRecipeIDs)
	if not ok or not ns.CanAccessTable(ids) then
		return
	end
	local list = {}
	for _, id in ipairs(ids) do
		if type(id) == "number" then
			local r = { pcall(ts.GetRecipeInfo, id) }
			local info = r[1] and r[2] or nil
			if type(info) == "table" and Plain(info.learned) == true
				and Plain(info.isDummyRecipe) ~= true
				and type(Plain(info.name)) == "string" then
				local entry = { n = Plain(info.name), i = Plain(info.icon) }
				-- Chat link/tooltip: the recipe info carries a hyperlink
				-- on modern clients; enchant recipes have none, so
				-- GetRecipeLink is the fallback.
				entry.l = Plain(info.hyperlink)
				if not entry.l and type(ts.GetRecipeLink) == "function" then
					entry.l = PlainCall(ts.GetRecipeLink, id)
				end
				-- Materials: required reagent slots with quantities from
				-- the schematic (optional/hidden slots are skipped).
				if type(ts.GetRecipeSchematic) == "function" then
					local ok, sch = pcall(ts.GetRecipeSchematic, id, false)
					if ok and ns.CanAccessTable(sch)
						and type(sch.reagentSlotSchematics) == "table" then
						local mats = {}
						for _, slot in ipairs(sch.reagentSlotSchematics) do
							local first = type(slot.reagents) == "table"
								and slot.reagents[1]
							local itemID = type(first) == "table"
								and tonumber(Plain(first.itemID))
							if itemID and Plain(slot.hiddenInCraftingForm) ~= true
								and Plain(slot.required) ~= false then
								mats[#mats + 1] = {
									i = itemID,
									n = tonumber(Plain(slot.quantityRequired)) or 1,
								}
							end
						end
						if #mats > 0 then
							entry.m = mats
						end
					end
				end
				list[id] = entry
			end
		end
	end
	local key = line or profName or "?"
	char.recipes = char.recipes or {}
	-- Profession cooldowns: the legacy index API (same one
	-- SentinelPanel's ProfCDs uses) only reports while a trade skill
	-- window is open - exactly the context of this scan.
	local cds
	if GetNumTradeSkills and GetTradeSkillInfo and GetTradeSkillCooldown then
		local ok, n = pcall(GetNumTradeSkills)
		for i = 1, (ok and tonumber(n)) or 0 do
			local okC, cd = pcall(GetTradeSkillCooldown, i)
			cd = (okC and tonumber(cd)) or 0
			if cd > 0 then
				local okN, rname = pcall(GetTradeSkillInfo, i)
				if okN and type(rname) == "string" then
					cds = cds or {}
					cds[#cds + 1] = { n = rname, x = GetServerTime() + cd }
				end
			end
		end
	end
	char.recipes[key] = { name = profName or tostring(key), list = list, cds = cds }
	Stamp(char, "recipesAt")
	Changed()
end

--------------------------------------------------------------------------------
-- Mailbox (readable whenever - the headers describe current inbox state;
-- a snapshot is only as fresh as the last MAIL_INBOX_UPDATE)
--------------------------------------------------------------------------------
local mailQueued = false
local function ScanMail()
	mailQueued = false
	local char = Store.OwnChar()
	if not char or not GetInboxNumItems then
		return
	end
	local num = tonumber(PlainCall(GetInboxNumItems)) or 0
	local items, money = {}, 0
	local minDays
	for i = 1, math.min(num, 100) do
		if GetInboxHeaderInfo then
			local r = { pcall(GetInboxHeaderInfo, i) }
			-- packageIcon, stationeryIcon, sender, subject, money,
			-- CODAmount, daysLeft, hasItem, wasRead, ...
			if r[1] then
				money = money + (tonumber(Plain(r[6])) or 0)
				local dl = tonumber(Plain(r[8]))
				if dl and (not minDays or dl < minDays) then
					minDays = dl
				end
				for a = 1, math.min(tonumber(Plain(r[9])) or 0, 12) do
					local link = GetInboxItemLink and PlainCall(GetInboxItemLink, i, a)
					local id = link and tonumber(tostring(link):match("item:(%d+)"))
					if id then
						local count = 1
						if GetInboxItem then
							local ir = { pcall(GetInboxItem, i, a) }
							count = (ir[1] and tonumber(Plain(ir[5]))) or 1
						end
						items[id] = (items[id] or 0) + count
					end
				end
			end
		end
	end
	char.mail = { count = num, money = money, items = items,
		expireDays = minDays }
	Stamp(char, "mailAt")
	Changed()
end

local function QueueMail()
	if mailQueued then
		return
	end
	mailQueued = true
	C_Timer.After(BAG_DEBOUNCE, ScanMail)
end

--------------------------------------------------------------------------------
-- Full rescan (settings button + first login pass)
--------------------------------------------------------------------------------
-- Quest log snapshot: count + titles (headers skipped), capped so the
-- record stays small. GetQuestLogTitle returns (title, level,
-- suggestedGroup, isHeader, isCollapsed, ...).
--------------------------------------------------------------------------------

local function ScanQuests()
	local char = Store.OwnChar()
	if not char or not GetNumQuestLogEntries then
		return
	end
	local n = tonumber(PlainCall(GetNumQuestLogEntries)) or 0
	local list
	if GetQuestLogTitle then
		list = {}
		for i = 1, math.min(n, 50) do
			local r = { pcall(GetQuestLogTitle, i) }
			if r[1] and Plain(r[5]) ~= true and type(Plain(r[2])) == "string" then
				list[#list + 1] = Plain(r[2])
			end
		end
	end
	char.quests = { count = n, list = list }
	Stamp(char, "questsAt")
	Changed()
end

--------------------------------------------------------------------------------

function Scanner.Rescan()
	ScanMeta()
	ScanMoney()
	ScanGear()
	ScanBags()
	ScanStats()
	ScanLockouts()
	ScanCurrencies(true)
	ScanReputation(true)
	ScanQuests()
	QueueMail()
	RequestPlaytime()
	if bankOpen then
		ScanBank()
	end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

local function InitialScan()
	ScanMeta()
	ScanMoney()
	-- Bag contents arrive shortly after entering the world; scan once now
	-- and once more a little later so late-arriving items are caught.
	QueueBags()
	QueueGear()
	ScanStats()
	QueueLockouts()
	ScanCurrencies(true)
	ScanReputation(true)
	ScanQuests()
	QueueMail()
	RequestPlaytime()
	if RequestRaidInfo then
		pcall(RequestRaidInfo)
	end
	C_Timer.After(3, function()
		QueueBags()
		QueueGear()
		ScanMoney()
	end)
end

-- Everything below activates on SAI_BOOT (fired once by the module glue
-- when the SentiUI module is enabled); until then nothing runs.
ns.RegisterCallback(Scanner, "SAI_BOOT", function()

-- Playtime answer is async; ask again periodically so the stored value
-- stays fresh within a session.
ns:Every(600, RequestPlaytime)

-- PLAYER_ENTERING_WORLD may already have fired by the time the module
-- enables on PLAYER_LOGIN (event order is not guaranteed on this client),
-- so scan right away too - a beat later so the first bag data has
-- arrived. The realm name can still be unknown very early; retry until
-- OwnKey resolves, otherwise every Scan* call would bail on a nil char.
local bootTries = 0
local function BootScan()
	bootTries = bootTries + 1
	local ok, key = pcall(Store.OwnKey)
	if ok and key then
		pcall(InitialScan)
	elseif bootTries < 15 then
		ns:After(1, BootScan)
	else
		ns:Print("could not resolve the character key (name/realm unavailable) - /sai scan for details")
	end
end
ns:After(1, BootScan)
ns:RegisterEvent("PLAYER_ENTERING_WORLD", InitialScan)
ns:RegisterEvent("PLAYER_LEVEL_UP", function()
	ScanMeta()
	ScanStats()
end)
ns:RegisterEvent("ZONE_CHANGED", ScanStats)
ns:RegisterEvent("ZONE_CHANGED_INDOORS", ScanStats)
ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", ScanStats)
ns:RegisterEvent("PLAYER_XP_UPDATE", ScanStats)
ns:RegisterEvent("PLAYER_MONEY", ScanMoney)
ns:RegisterEvent("BAG_UPDATE", function()
	QueueBags()
	if bankOpen then
		QueueBank()
	end
end)
ns:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", QueueGear)

ns:RegisterEvent("BANKFRAME_OPENED", function()
	bankOpen = true
	QueueBank()
end)
ns:RegisterEvent("BANKFRAME_CLOSED", function()
	bankOpen = false
end)

for _, entry in ipairs({
	{ "PLAYERBANKSLOTS_CHANGED", QueueBank },
	{ "PLAYERBANKBAGSLOTS_CHANGED", QueueBank },
	{ "PLAYERREAGENTBANKSLOTS_CHANGED", QueueBank },
	{ "BAG_UPDATE_DELAYED", QueueBags },
	{ "GUILD_ROSTER_UPDATE", ScanMeta },
	{ "UPDATE_INSTANCE_INFO", QueueLockouts },
	{ "ACHIEVEMENT_EARNED", function()
		achvCache = nil
		ScanStats()
	end },
	{ "CURRENCY_DISPLAY_UPDATE", QueueCurrencies },
	{ "UPDATE_FACTION", QueueReputation },
	{ "PLAYER_SPECIALIZATION_CHANGED", ScanStats },
	{ "EQUIPMENT_SETS_CHANGED", ScanStats },
	{ "MAIL_SHOW", QueueMail },
	{ "MAIL_INBOX_UPDATE", QueueMail },
	{ "QUEST_LOG_UPDATE", ScanQuests },
	{ "QUEST_ACCEPTED", ScanQuests },
	{ "QUEST_REMOVED", ScanQuests },
	{ "TRADE_SKILL_SHOW", function()
		-- the list still refills after SHOW; LIST_UPDATE catches it too
		C_Timer.After(0.5, ScanRecipes)
	end },
	{ "TRADE_SKILL_LIST_UPDATE", ScanRecipes },
	{ "NEW_RECIPE_LEARNED", ScanRecipes },
}) do
	-- Client-dependent events: an unknown one must not kill the rest.
	ns.SafeCall("RegisterEvent " .. entry[1], ns.RegisterEvent, ns, entry[1], entry[2])
end

end) -- SAI_BOOT
