-- World/social plugins: gold, bags, mail, friends, guild, quests,
-- raid lockouts, auctions, profession cooldowns, and the brand chip.
local _, ns = ...
local S = SentiUI
local L = ns.L
local P = ns.Plugins
local Plain = ns.Plain
local TipHead, TipKV, TipSub = ns.TipHead, ns.TipKV, ns.TipSub
local SecureAPI = ns.SecureAPI
local format, floor, min, abs = string.format, math.floor, math.min, math.abs
local sort, tinsert = table.sort, table.insert

local AH = "|cff" .. ns.accentHex
local DH = "|cff" .. ns.dimHex

-- Gold ---------------------------------------------------------------------------------
local function FormatMoney(money)
	money = Plain(money) or 0
	local gold = floor(abs(money) / 10000)
	local silver = floor((abs(money) % 10000) / 100)
	local copper = abs(money) % 100
	local sign = money < 0 and "-" or ""
	return format("%s%s|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", sign,
		BreakUpLargeNumbers and BreakUpLargeNumbers(gold) or gold, silver, copper)
end

local function CharKey()
	local ok, n = pcall(GetUnitName, "player", false)
	n = ok and Plain(n) or "?"
	local okR, r = pcall(GetRealmName)
	return tostring(n) .. " @ " .. (okR and Plain(r) or "?")
end

ns.RegisterPlugin({
	id = "gold",
	label = L["Gold"],
	icon = "Interface\\MoneyFrame\\UI-GoldIcon",
	bar = "bottom", zone = "LEFT", order = 20,
	events = { "PLAYER_MONEY", "PLAYER_ENTERING_WORLD" },
	update = function(def)
		local money = Plain(GetMoney()) or 0
		def.start = def.start or money
		ns.db.chars[CharKey()] = money
		local gold = floor(money / 10000)
		local silver = floor((money % 10000) / 100)
		return format("%s|cffffd700g|r %d|cffc7c7cfs|r",
			BreakUpLargeNumbers and BreakUpLargeNumbers(gold) or gold, silver)
	end,
	tooltip = function(tip)
		TipHead(tip, L["Gold"])
		tip:AddLine(FormatMoney(GetMoney()), 1, 1, 1)
		local d = P.byId.gold
		if d and d.start then
			local diff = (Plain(GetMoney()) or 0) - d.start
			if diff ~= 0 then
				TipKV(tip, L["Session"], FormatMoney(diff))
			end
		end
		-- per-character totals across the account
		local me = CharKey()
		local list, total = {}, 0
		for name, money in pairs(ns.db.chars) do
			list[#list + 1] = { name = name, money = Plain(money) or 0 }
			total = total + (Plain(money) or 0)
		end
		if #list > 0 then
			sort(list, function(a, b) return a.name < b.name end)
			TipSub(tip, L["All characters"])
			for i = 1, min(#list, 15) do
				local c = list[i]
				local name = c.name == me and AH .. c.name .. "|r" or c.name
				tip:AddDoubleLine("  " .. name, FormatMoney(c.money), 1, 1, 1, 0.8, 0.8, 0.8)
			end
			if #list > 15 then
				tip:AddLine(format("  %s... %s|r", DH, format(L["%d more"], #list - 15)), 1, 1, 1)
			end
			TipKV(tip, L["Total"], FormatMoney(total))
		end
	end,
})

-- Bags ----------------------------------------------------------------------------------
local function BagSlots()
	local free, total = 0, 0
	for bag = 0, 5 do
		local okN, num = pcall(C_Container.GetContainerNumSlots, bag)
		local okF, fr = pcall(C_Container.GetContainerNumFreeSlots, bag)
		num, fr = okN and Plain(num), okF and Plain(fr)
		if num and fr then
			total = total + num
			free = free + fr
		end
	end
	return free, total
end

ns.RegisterPlugin({
	id = "bags",
	label = L["Bags"],
	icon = "Interface\\Icons\\INV_Misc_Bag_08",
	bar = "bottom", zone = "LEFT", order = 30,
	events = { "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD" },
	update = function()
		local free, total = BagSlots()
		return format("%s%d|r/%d", AH, free, total)
	end,
	tooltip = function(tip)
		local free, total = BagSlots()
		TipHead(tip, L["Bags"])
		TipKV(tip, L["Free slots"], format("%d / %d", free, total))
		TipSub(tip, L["Per bag"])
		for bag = 0, 5 do
			local okN, num = pcall(C_Container.GetContainerNumSlots, bag)
			local okF, fr = pcall(C_Container.GetContainerNumFreeSlots, bag)
			num, fr = okN and Plain(num), okF and Plain(fr)
			if num and num > 0 then
				local name = "#" .. bag
				if C_Container.GetBagName then
					local okB, bn = pcall(C_Container.GetBagName, bag)
					if okB and Plain(bn) and bn ~= "" then name = bn end
				end
				if bag == 0 then name = L["Backpack"] end
				tip:AddDoubleLine("  " .. name, format("%d / %d", fr or 0, num), 1, 1, 1, 0.7, 0.7, 0.7)
			end
		end
		-- bank container (values refresh once the bank has been seen)
		local okN, num = pcall(C_Container.GetContainerNumSlots, -1)
		local okF, fr = pcall(C_Container.GetContainerNumFreeSlots, -1)
		num, fr = okN and Plain(num), okF and Plain(fr)
		if num and num > 0 then
			tip:AddDoubleLine("  " .. L["Bank"], format("%d / %d", fr or 0, num), 1, 1, 1, 0.7, 0.7, 0.7)
		end
	end,
	secureClick = { "MainMenuBarBackpackButton" },
	click = function() SecureAPI(ToggleAllBags) end,
})

-- Mail ------------------------------------------------------------------------------------
ns.RegisterPlugin({
	id = "mail",
	label = L["Mail"],
	icon = "Interface\\Icons\\INV_Letter_15",
	bar = "bottom", zone = "RIGHT", order = 50,
	events = { "UPDATE_PENDING_MAIL", "PLAYER_ENTERING_WORLD" },
	update = function()
		if ns.MailWaiting() then return "|cff55ff55" .. L["New mail"] .. "|r" end
		return ""
	end,
	tooltip = function(tip)
		TipHead(tip, L["Mail"])
		tip:AddLine(L["You have unread mail"], 1, 1, 1)
		tip:AddLine(L["Check your mailbox"], 0.6, 0.6, 0.6)
	end,
})

-- Friends -----------------------------------------------------------------------------------
local MAX_FRIENDS = 20

local function FriendCounts()
	local wow, bnet = 0, 0
	if C_FriendList and C_FriendList.GetNumOnlineFriends then
		wow = Plain(C_FriendList.GetNumOnlineFriends()) or 0
	end
	if BNGetNumFriends then
		local ok, total, online = pcall(BNGetNumFriends)
		if ok then bnet = Plain(online) or 0 end
	end
	return wow, bnet
end

local function OnlineWowFriends()
	local out = {}
	if not (C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex) then
		return out
	end
	local ok, n = pcall(C_FriendList.GetNumFriends)
	n = ok and Plain(n) or 0
	for i = 1, n do
		local okI, info = pcall(C_FriendList.GetFriendInfoByIndex, i)
		if okI and ns.CanAccess(info) and Plain(info.connected) then
			local tag
			if Plain(info.afk) or Plain(info.status) == "AFK" then tag = " <AFK>"
			elseif Plain(info.dnd) or Plain(info.status) == "DND" then tag = " <DND>" end
			local name = Plain(info.name) or "?"
			tinsert(out, {
				name = ns.ClassColor(name, Plain(info.className)) .. (tag or ""),
				level = Plain(info.level) or 0,
				area = Plain(info.area) or "",
			})
		end
	end
	sort(out, function(a, b) return a.name < b.name end)
	return out
end

local function OnlineBnetFriends()
	local out = {}
	if not (BNGetNumFriends and BNGetFriendInfo) then return out end
	local ok, total = pcall(BNGetNumFriends)
	total = ok and Plain(total) or 0
	for i = 1, total do
		local okI, _, presenceName, _, _, _, _, isOnline = pcall(BNGetFriendInfo, i)
		if okI and Plain(isOnline) then
			tinsert(out, Plain(presenceName) or "?")
		end
	end
	sort(out)
	return out
end

ns.RegisterPlugin({
	id = "friends",
	label = L["Friends"],
	icon = "Interface\\Icons\\INV_Misc_GroupNeedMore",
	bar = "bottom", zone = "RIGHT", order = 60,
	events = { "FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED", "PLAYER_ENTERING_WORLD" },
	update = function()
		local wow, bnet = FriendCounts()
		return format("%s%d|r", AH, wow + bnet)
	end,
	tooltip = function(tip)
		if C_FriendList then SecureAPI(C_FriendList.ShowFriends) end
		TipHead(tip, L["Friends"])
		local wow, bnet = FriendCounts()
		TipKV(tip, "WoW", wow)
		TipKV(tip, "Battle.net", bnet)

		local friends = OnlineWowFriends()
		if #friends > 0 then
			TipSub(tip, format("WoW (%d)", #friends))
			local shown = min(#friends, MAX_FRIENDS)
			for i = 1, shown do
				local f = friends[i]
				tip:AddDoubleLine("  " .. f.name, format("%d  %s", f.level, f.area), 1, 1, 1, 0.7, 0.7, 0.7)
			end
			if #friends > shown then
				tip:AddLine(format("  %s... %s|r", DH, format(L["%d more"], #friends - shown)), 1, 1, 1)
			end
		end

		local bn = OnlineBnetFriends()
		if #bn > 0 then
			TipSub(tip, format("Battle.net (%d)", #bn))
			local shown = min(#bn, MAX_FRIENDS)
			for i = 1, shown do
				tip:AddLine("  " .. bn[i], 1, 1, 1)
			end
			if #bn > shown then
				tip:AddLine(format("  %s... %s|r", DH, format(L["%d more"], #bn - shown)), 1, 1, 1)
			end
		end
	end,
	secureClick = { "SocialsMicroButton" },
	click = function() SecureAPI(ToggleFriendsFrame, 1) end,
})

-- Guild ----------------------------------------------------------------------------------------
local guildCache = { online = nil, total = 0, name = nil }
local MAX_GUILD = 30

local function GuildRefresh()
	-- modern club API first - the classic roster calls are the ones
	-- that get flagged forbidden on this client. Online count comes from
	-- the member list: presence 0/3 = unknown/offline, the rest counts
	if C_Club and C_Club.GetGuildClubId and C_Club.GetClubMembers and C_Club.GetMemberInfo then
		local ok, clubId = pcall(C_Club.GetGuildClubId)
		clubId = ok and Plain(clubId)
		if clubId then
			local okM, members = pcall(C_Club.GetClubMembers, clubId)
			if okM and ns.CanAccess(members) then
				local online, total, sawPresence = 0, 0, false
				for _, memberId in ipairs(members) do
					total = total + 1
					local okI, info = pcall(C_Club.GetMemberInfo, clubId, memberId)
					if okI and ns.CanAccess(info) then
						local p = Plain(info.presence)
						if p ~= nil then
							sawPresence = true
							if p ~= 0 and p ~= 3 then online = online + 1 end
						end
					end
				end
				if sawPresence then
					guildCache.online, guildCache.total = online, total
					if C_Club.GetClubInfo then
						local okN, info = pcall(C_Club.GetClubInfo, clubId)
						if okN and ns.CanAccess(info) then
							guildCache.name = Plain(info.name) or guildCache.name
						end
					end
					return
				end
				guildCache.total = total -- member list works, presence does not
			end
		end
	end
	if not IsInGuild then guildCache.online, guildCache.name = nil, nil return end
	local okG, inGuild = pcall(IsInGuild)
	if not (okG and Plain(inGuild)) then guildCache.online, guildCache.name = nil, nil return end
	local ok, total, online = pcall(GetNumGuildMembers)
	if ok then guildCache.online, guildCache.total = Plain(online) or 0, Plain(total) or 0 end
	if GetGuildInfo then
		local okN, name = pcall(GetGuildInfo, "player")
		if okN then guildCache.name = Plain(name) or guildCache.name end
	end
end

local function OnlineMembers()
	local out = {}
	local ok, total = pcall(GetNumGuildMembers)
	total = ok and Plain(total) or 0
	if not GetGuildRosterInfo then return out end
	for i = 1, total do
		local okR, name, rankName, _, level, _, zone, _, _, online, status, class =
			pcall(GetGuildRosterInfo, i)
		if okR and Plain(online) and Plain(name) then
			local tag
			local st = Plain(status)
			if st == 1 then tag = " <AFK>"
			elseif st == 2 then tag = " <DND>" end
			local short = name
			if Ambiguate then
				local okA, s = pcall(Ambiguate, name, "guild")
				if okA then short = Plain(s) or short end
			end
			tinsert(out, {
				name = ns.ClassColor(short, Plain(class)) .. (tag or ""),
				level = Plain(level) or 0,
				zone = Plain(zone) or "",
			})
		end
	end
	sort(out, function(a, b) return a.name < b.name end)
	return out
end

ns.RegisterPlugin({
	id = "guild",
	label = L["Guild"],
	icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
	bar = "bottom", zone = "RIGHT", order = 70,
	events = { "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "PLAYER_ENTERING_WORLD" },
	onevent = function() GuildRefresh() end,
	update = function()
		local online = guildCache.online
		if not online then return DH .. L["No guild"] .. "|r" end
		return format("%s%d|r", AH, online)
	end,
	tooltip = function(tip)
		-- on-demand refresh while hovering is fine, it is not a tick
		GuildRefresh()
		if C_GuildInfo then SecureAPI(C_GuildInfo.GuildRoster) end
		TipHead(tip, guildCache.name or L["Guild"])
		if GetGuildRosterMOTD then
			local okM, motd = pcall(GetGuildRosterMOTD)
			motd = okM and Plain(motd)
			if motd and motd ~= "" then tip:AddLine(DH .. motd .. "|r") end
		end
		local online, total = guildCache.online, guildCache.total
		if online then TipKV(tip, L["Online"], format("%d / %d", online, total)) end
		local members = OnlineMembers()
		if #members > 0 then
			TipSub(tip, format("%s (%d)", L["Online now"], #members))
			local shown = min(#members, MAX_GUILD)
			for i = 1, shown do
				local m = members[i]
				tip:AddDoubleLine("  " .. m.name, format("%d  %s", m.level, m.zone), 1, 1, 1, 0.7, 0.7, 0.7)
			end
			if #members > shown then
				tip:AddLine(format("  %s... %s|r", DH, format(L["%d more"], #members - shown)), 1, 1, 1)
			end
		end
	end,
	secureClick = { "GuildMicroButton", "CommunitiesMicroButton" },
	click = function() SecureAPI(ToggleGuildFrame) end,
})

-- Quests ---------------------------------------------------------------------------------------
local MAX_QUESTS = 40
local MAX_QUEST_LIST = 15

local function QuestCounts()
	local num = (C_QuestLog and C_QuestLog.GetNumQuestLogEntries) or GetNumQuestLogEntries
	if not num then return 0, 0 end
	local ok, entries, quests = pcall(num)
	if not ok then return 0, 0 end
	return Plain(entries) or 0, Plain(quests) or Plain(entries) or 0
end

local function QuestList()
	local out = {}
	local entries = QuestCounts()
	if C_QuestLog and C_QuestLog.GetInfo then
		for i = 1, entries do
			local ok, info = pcall(C_QuestLog.GetInfo, i)
			if ok and ns.CanAccess(info) and not Plain(info.isHeader) then
				tinsert(out, { level = Plain(info.level) or 0, title = Plain(info.title) or "?" })
			end
		end
	elseif GetQuestLogTitle then
		for i = 1, entries do
			local ok, title, level, _, isHeader = pcall(GetQuestLogTitle, i)
			if ok and Plain(title) and not Plain(isHeader) then
				tinsert(out, { level = Plain(level) or 0, title = title })
			end
		end
	end
	return out
end

ns.RegisterPlugin({
	id = "quests",
	label = L["Quests"],
	icon = "Interface\\Icons\\INV_Misc_Book_09",
	bar = "top", zone = "CENTER", order = 20,
	events = { "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "PLAYER_ENTERING_WORLD" },
	update = function()
		local _, quests = QuestCounts()
		return format("%s%d|r/%d", AH, quests, MAX_QUESTS)
	end,
	tooltip = function(tip)
		TipHead(tip, L["Quest log"])
		local _, quests = QuestCounts()
		TipKV(tip, L["Quests"], format("%d / %d", quests, MAX_QUESTS))
		local list = QuestList()
		if #list > 0 then
			TipSub(tip, format("%s (%d)", L["Quests"], #list))
			for i = 1, min(#list, MAX_QUEST_LIST) do
				local q = list[i]
				tip:AddLine(format("  %s%d|r  %s", AH, q.level, q.title), 1, 1, 1)
			end
			if #list > MAX_QUEST_LIST then
				tip:AddLine(format("  %s... %s|r", DH, format(L["%d more"], #list - MAX_QUEST_LIST)), 1, 1, 1)
			end
		end
	end,
})

-- Raid info -------------------------------------------------------------------------------------
local function SavedRaids()
	local out = {}
	if not (GetNumSavedInstances and GetSavedInstanceInfo) then return out end
	local ok, n = pcall(GetNumSavedInstances)
	n = ok and Plain(n) or 0
	for i = 1, n do
		local okI, name, _, reset, _, _, _, _, _, diffName, maxEnc, prog = pcall(GetSavedInstanceInfo, i)
		if okI and Plain(name) then
			out[#out + 1] = {
				name = name,
				diff = Plain(diffName) or "",
				prog = Plain(prog) or 0,
				max = Plain(maxEnc) or 0,
				reset = Plain(reset) or 0,
			}
		end
	end
	return out
end

local function FmtReset(sec)
	sec = Plain(sec) or 0
	local d = floor(sec / 86400)
	local h = floor((sec % 86400) / 3600)
	local m = floor((sec % 3600) / 60)
	if d > 0 then return format("%dd %dh", d, h) end
	if h > 0 then return format("%dh %dm", h, m) end
	return format("%dm", m)
end

ns.RegisterPlugin({
	id = "raidinfo",
	label = L["Raids"],
	icon = "Interface\\Icons\\Achievement_Boss_Ragnaros",
	bar = "top", zone = "RIGHT", order = 30,
	events = { "UPDATE_INSTANCE_INFO", "PLAYER_ENTERING_WORLD" },
	update = function()
		return format("%s%d|r", AH, #SavedRaids())
	end,
	tooltip = function(tip)
		if RequestRaidInfo then pcall(RequestRaidInfo) end
		TipHead(tip, L["Saved instances"])
		local list = SavedRaids()
		if #list == 0 then
			tip:AddLine(L["No saved instances"], 0.7, 0.7, 0.7)
			return
		end
		for _, s in ipairs(list) do
			local label = s.name
			if s.diff ~= "" then label = format("%s (%s)", label, s.diff) end
			local right = format("%d/%d", s.prog, s.max)
			if s.max == 0 then right = FmtReset(s.reset) end
			tip:AddDoubleLine("  " .. label, right, 1, 1, 1, 0.7, 0.7, 0.7)
			if s.max > 0 then
				tip:AddDoubleLine("  " .. DH .. L["Resets in"] .. "|r", FmtReset(s.reset), 1, 1, 1, 0.7, 0.7, 0.7)
			end
		end
	end,
})

-- Auctions ---------------------------------------------------------------------------------------
local aucCache = { n = 0, items = {} }
local aucQueried = false

local function AuctionShown()
	return (AuctionHouseFrame and AuctionHouseFrame:IsShown())
		or (AuctionFrame and AuctionFrame:IsShown())
end

local function AucItemName(itemID)
	if not itemID then return "?" end
	if C_Item and C_Item.GetItemNameByID then
		local ok, name = pcall(C_Item.GetItemNameByID, itemID)
		name = ok and Plain(name)
		if name then return name end
	end
	return format("Item %s", tostring(itemID))
end

local function ScanAuctionsRetail()
	if not (C_AuctionHouse and C_AuctionHouse.GetNumOwnedAuctions) then return false end
	if not aucQueried then
		aucQueried = true
		if C_AuctionHouse.QueryOwnedAuctions then
			pcall(C_AuctionHouse.QueryOwnedAuctions, 0)
		end
		if C_AuctionHouse.QueryOwnedCommodities then
			pcall(C_AuctionHouse.QueryOwnedCommodities)
		end
	end
	if C_AuctionHouse.HasFullOwnedAuctionResults
		and not C_AuctionHouse.HasFullOwnedAuctionResults() then
		return true -- results still loading, keep polling
	end
	local total = 0
	wipe(aucCache.items)
	if C_AuctionHouse.GetOwnedAuctionInfo then
		local ok, n = pcall(C_AuctionHouse.GetNumOwnedAuctions)
		n = ok and Plain(n) or 0
		for i = 1, n do
			local okI, info = pcall(C_AuctionHouse.GetOwnedAuctionInfo, i)
			if okI and type(info) == "table" then
				local itemKey = Plain(info.itemKey)
				aucCache.items[#aucCache.items + 1] = {
					name = AucItemName(itemKey and Plain(itemKey.itemID)),
					count = Plain(info.quantity) or 1,
					buyout = Plain(info.buyoutAmount) or Plain(info.bidAmount) or 0,
					sold = Plain(info.status) == 1,
				}
			end
		end
		total = n
	end
	if C_AuctionHouse.GetNumCommoditiesOwned and C_AuctionHouse.GetCommodityOwnedInfo then
		local ok, n = pcall(C_AuctionHouse.GetNumCommoditiesOwned)
		n = ok and Plain(n) or 0
		for i = 1, n do
			local okI, info = pcall(C_AuctionHouse.GetCommodityOwnedInfo, i)
			if okI and type(info) == "table" then
				local itemKey = Plain(info.itemKey)
				local qty = Plain(info.quantity) or 1
				local unit = Plain(info.unitPrice)
				aucCache.items[#aucCache.items + 1] = {
					name = AucItemName(itemKey and Plain(itemKey.itemID)),
					count = qty,
					buyout = unit and unit * qty or 0,
					sold = Plain(info.status) == 1,
				}
			end
		end
		total = total + n
	end
	aucCache.n = total
	return true
end

local function ScanAuctionsClassic()
	if not (GetNumAuctionItems and GetAuctionItemInfo) then return false end
	local ok, batch, total = pcall(GetNumAuctionItems, "owner")
	if not ok then return false end
	total = Plain(total) or Plain(batch) or 0
	wipe(aucCache.items)
	for i = 1, total do
		local okI, name, _, count, _, _, _, _, buyout, _, _, _, status = pcall(GetAuctionItemInfo, "owner", i)
		if okI then
			aucCache.items[#aucCache.items + 1] = {
				name = Plain(name) or "?",
				count = Plain(count) or 1,
				buyout = Plain(buyout) or 0,
				sold = Plain(status) == 1,
			}
		end
	end
	aucCache.n = total
	return true
end

local function ScanAuctions()
	if not ScanAuctionsRetail() then ScanAuctionsClassic() end
end

local function AucSupported()
	return (C_AuctionHouse and C_AuctionHouse.GetNumOwnedAuctions)
		or (GetNumAuctionItems and GetAuctionItemInfo)
end

local function AucMoney(c)
	c = Plain(c) or 0
	return format("%d|cffffd700g|r %d|cffc7c7cfs|r", floor(c / 10000), floor(c % 10000 / 100))
end

ns.RegisterPlugin({
	id = "auctions",
	label = L["Auctions"],
	icon = "Interface\\Icons\\INV_Misc_Coin_01",
	bar = "top", zone = "RIGHT", order = 85,
	events = { "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "PLAYER_ENTERING_WORLD" },
	onevent = function(_, event)
		if event == "AUCTION_HOUSE_CLOSED" then
			aucQueried = false
		elseif AuctionShown() then
			aucQueried = false
			ScanAuctions()
		end
	end,
	update = function()
		if not AucSupported() then return "" end
		if AuctionShown() then ScanAuctions() end
		if aucCache.n <= 0 then return DH .. "0|r" end
		return format("%s%d|r", AH, aucCache.n)
	end,
	tooltip = function(tip)
		TipHead(tip, L["Auctions"])
		if aucCache.n <= 0 then
			tip:AddLine(L["No running auctions"], 0.7, 0.7, 0.7)
			TipSub(tip, L["Open the auction house to refresh"])
			return
		end
		TipKV(tip, L["Running"], aucCache.n)
		for _, it in ipairs(aucCache.items) do
			local tag = it.sold and "|cff55ff55+|r " or ""
			local name = it.count > 1 and format("%s x%d", it.name, it.count) or it.name
			tip:AddDoubleLine("  " .. tag .. name, AucMoney(it.buyout), 1, 1, 1, 0.8, 0.8, 0.8)
		end
	end,
})

-- Profession cooldowns -----------------------------------------------------------------------------
local profList = {}

local function ScanProfCDs()
	wipe(profList)
	if not (GetTradeSkillLine and GetNumTradeSkills and GetTradeSkillInfo and GetTradeSkillCooldown) then
		return false
	end
	local ok, n = pcall(GetNumTradeSkills)
	if not ok then return false end
	n = Plain(n) or 0
	for i = 1, n do
		local okN, name, stype = pcall(GetTradeSkillInfo, i)
		if okN and name and stype ~= "header" then
			local okC, cd = pcall(GetTradeSkillCooldown, i)
			cd = okC and Plain(cd) or 0
			if cd and cd > 0 then
				profList[#profList + 1] = { name = name, cd = cd }
			end
		end
	end
	return true
end

ns.RegisterPlugin({
	id = "profcds",
	label = L["Cooldowns"],
	icon = "Interface\\Icons\\Spell_Nature_ElementalAbsorption",
	bar = "top", zone = "RIGHT", order = 90,
	events = { "TRADE_SKILL_SHOW", "TRADE_SKILL_CLOSE", "NEW_RECIPE_LEARNED", "PLAYER_ENTERING_WORLD" },
	onevent = function() ScanProfCDs() end,
	update = function()
		if not ScanProfCDs() then return "" end
		if #profList == 0 then return "" end
		return format("%s%d|r", AH, #profList)
	end,
	tooltip = function(tip)
		TipHead(tip, L["Profession cooldowns"])
		if #profList == 0 then
			tip:AddLine(L["Nothing on cooldown"], 0.7, 0.7, 0.7)
			return
		end
		for _, it in ipairs(profList) do
			tip:AddDoubleLine("  " .. it.name, SecondsToTime and SecondsToTime(it.cd) or it.cd .. "s",
				1, 1, 1, 0.9, 0.7, 0.3)
		end
	end,
})


-- Training ------------------------------------------------------------------------
-- Opens the SentiUI_Training compendium (class spells, weapon skills,
-- professions). Empty when the module is not installed, so the plugin
-- stays out of the layout instead of showing a dead button.
ns.RegisterPlugin({
	id = "training",
	noLabel = true,
	showLabel = false,
	label = L["Trainers"],
	icon = "Interface\\Icons\\INV_Misc_Book_09",
	bar = "bottom", zone = "LEFT", order = 61,
	events = { "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "PLAYER_LEVEL_UP" },
	update = function()
		if not SentiUITraining then return "" end
		return AH .. L["Trainers"] .. "|r"
	end,
	tooltip = function(tip)
		TipHead(tip, L["Trainers"])
		TipSub(tip, L["Click: open the trainer compendium"])
	end,
	click = function()
		if SentiUITraining and SentiUITraining.Toggle then
			SentiUITraining.Toggle()
		end
	end,
})

-- Journal -------------------------------------------------------------------------
-- Opens the SentiUI_Journal dungeon compendium. Hidden when the module
-- is not installed so the layout stays clean.
ns.RegisterPlugin({
	id = "journal",
	noLabel = true,
	showLabel = false,
	label = L["Compendium"],
	icon = "Interface\\Icons\\INV_Misc_Book_11",
	bar = "bottom", zone = "LEFT", order = 62,
	events = { "PLAYER_ENTERING_WORLD" },
	update = function()
		if not SentiUIJournal then return "" end
		return AH .. L["Compendium"] .. "|r"
	end,
	tooltip = function(tip)
		TipHead(tip, L["Compendium"])
		TipSub(tip, L["Click: open the dungeon journal"])
	end,
	click = function()
		if SentiUIJournal and SentiUIJournal.Toggle then
			SentiUIJournal.Toggle()
		end
	end,
})

-- Blacklist -----------------------------------------------------------------------
-- ForeverBlackListed integration: shared FBLDB store. With the real
-- addon loaded its window and sync take over; without it the panel
-- runs a compatible local list plus warnings and tooltip lines.
ns.RegisterPlugin({
	id = "blacklist",
	noLabel = true,
	label = L["Blacklist"],
	icon = "Interface\\Icons\\Ability_Creature_Cursed_04",
	bar = "bottom", zone = "LEFT", order = 63,
	events = { "PLAYER_ENTERING_WORLD" },
	update = function()
		if not ns.FBL then return "" end
		local n = ns.FBL.EntryCount()
		return n > 0 and ("|cffff5555" .. n .. "|r") or (AH .. L["Blacklist"] .. "|r")
	end,
	tooltip = function(tip)
		TipHead(tip, L["Blacklist"])
		TipKV(tip, L["Entries"], ns.FBL.EntryCount())
		local recent, shown = {}, 0
		for _, e in ipairs(ns.FBL.SortedEntries()) do
			if e.list ~= "good" then
				shown = shown + 1
				if shown <= 6 then
					recent[#recent + 1] = "|cffff5555" .. e.name .. "|r  |cff8c919f- "
						.. (ns.FBL.AnyNote(e) or "?") .. "|r"
				end
			end
		end
		for _, line in ipairs(recent) do tip:AddLine(line) end
		if shown > 6 then tip:AddLine("|cff8c919f... +" .. (shown - 6) .. "|r") end
		TipSub(tip, L["Click: open list  |  Right-click: menu"])
	end,
	click = function()
		ns.FBL.ToggleWindow()
	end,
	menu = function(def, items)
		items[#items + 1] = { text = L["Blacklist target"], onClick = function()
			ns.FBL.AddUnit("target") end }
		items[#items + 1] = { text = L["Blacklist mouseover"], onClick = function()
			ns.FBL.AddUnit("mouseover") end }
		items[#items + 1] = { text = L["Remove target"], onClick = function()
			ns.FBL.RemoveUnit("target") end }
		local te = UnitExists and UnitExists("target")
			and ns.FBL.GetUnitFullName("target")
		local tentry = te and ns.FBL.FindEntry("player", te)
		if tentry and not ns.FBL.IsAdmin() then
			items[#items + 1] = { text = L["Request removal"], onClick = function()
				ns.FBL.RequestRemoval(tentry, "") end }
		end
		items[#items + 1] = { text = L["Open list"], onClick = function()
			ns.FBL.ToggleWindow() end }
	end,
})

-- Brand --------------------------------------------------------------------------------------------
ns.RegisterPlugin({
	id = "brand",
	label = L["SentiUI"],
	showLabel = false,
	icon = "Interface\\AddOns\\SentiUI\\Media\\Logo.tga",
	bar = "bottom", zone = "LEFT", order = -100,
	events = { "PLAYER_ENTERING_WORLD" },
	update = function()
		return AH .. "SentiUI|r"
	end,
	tooltip = function(tip)
		TipHead(tip, "SentiUI Panel")
		TipKV(tip, L["Version"], ns.version)
		TipSub(tip, L["Left-click: options  |  Right-click: menu"])
	end,
	click = function()
		if S.OptionsPanel and S.OptionsPanel.Toggle then S.OptionsPanel.Toggle() end
	end,
})
-- Layer -----------------------------------------------------------------------------------
-- Self-contained SentiLayer replacement: the same creature-GUID layer
-- read, the same "sentilayer" channel protocol ("inv layer <SL zone not
-- id>" line + hidden SentiLayer addon notes), asker side AND host side.
-- SentiLayer users answer our asks and we answer theirs - the
-- standalone addon is no longer needed for display, swap or hosting.
local LAYER_CHANNEL = "sentilayer"
local NOTE_PREFIX = "SentiLayer"
local ZONE_MAP = (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3
local PARTY_MAX = 5
local VOTE_KEEP, STALE_FOR = 10, 10
local ASK_COOLDOWN, ASK_TTL = 10, 60
local INVITE_COOLDOWN, INVITE_SPACING = 60, 1

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
	pcall(C_ChatInfo.RegisterAddonMessagePrefix, NOTE_PREFIX)
end

local layVotes, laySeen = {}, {}
local layStale, layStaleUntil = nil, 0
local layCurrent
local layCandKey, layCandSince -- candidate layer waiting for its hold time
local ask              -- { at, want, joined } running swap request
local hostInvited = {} -- name -> GetTime() we invited (host side)
local lastInviteAt = 0

local function LayerKey(id)
	return type(id) == "string" and id:match("^(%d+)%-") or id
end

local function LaySame(a, b)
	return a ~= nil and b ~= nil and LayerKey(a) == LayerKey(b)
end

local function LayObserve(unit)
	local okG, g = pcall(UnitGUID, unit)
	g = okG and g
	if S.IsSecret(g) or type(g) ~= "string" or laySeen[g] then return end
	local kind, _, server, _, zoneUID = strsplit("-", g)
	if (kind ~= "Creature" and kind ~= "Vehicle")
		or type(server) ~= "string" or type(zoneUID) ~= "string" then
		return
	end
	-- player-controlled summons carry their maker's home, not this layer
	local okP, pc = pcall(UnitPlayerControlled, unit)
	if okP and pc == true and not S.IsSecret(pc) then return end
	if layStale and GetTime() < layStaleUntil and layStale[g] then return end
	laySeen[g] = true
	local id = server .. "-" .. zoneUID
	layVotes[#layVotes + 1] = id
	if #layVotes > VOTE_KEEP then table.remove(layVotes, 1) end
	local counts, best, bn = {}, nil, 0
	for _, v in ipairs(layVotes) do
		local k = LayerKey(v)
		counts[k] = (counts[k] or 0) + 1
	end
	for i = #layVotes, 1, -1 do
		local n = counts[LayerKey(layVotes[i])]
		if n >= bn then best, bn = layVotes[i], n end
	end
	-- a challenger must hold the vote for a few seconds before the
	-- display flips: overlapping layers leave mixed GUIDs in view and a
	-- flicker used to mint a fresh registry letter every time
	if not best then return end
	local newKey = LayerKey(best)
	if not layCurrent then
		layCurrent = best -- first read ever: adopt at once
	elseif newKey == LayerKey(layCurrent) then
		layCandKey, layCandSince = nil, 0 -- challenger died off
	elseif newKey == layCandKey then
		if GetTime() - layCandSince >= 2.5 then
			layCurrent = best
			layCandKey, layCandSince = nil, 0
			-- a real move while we hold a host's group: the swap
			-- worked - leave once the game settles us there
			if ask and ask.joined then
				C_Timer.After(5, function()
					if IsInGroup() then
						local leave = (C_PartyInfo
							and C_PartyInfo.LeaveParty) or LeaveParty
						ns.HardAPI("LeaveParty", leave)
					end
					ask = nil
				end)
			end
		end
	else
		layCandKey, layCandSince = newKey, GetTime()
	end
end

local function LayScan()
	for i = 1, 40 do LayObserve("nameplate" .. i) end
	LayObserve("target")
	LayObserve("mouseover")
	LayObserve("focus")
end

-- creatures in view right now are the old layer's - freeze them out for
-- STALE_FOR seconds, then let fresh sightings vote again
local function LayMarkStale()
	local guids = {}
	for i = 1, 40 do
		local okG, g = pcall(UnitGUID, "nameplate" .. i)
		g = okG and g
		if type(g) == "string" and not S.IsSecret(g) then guids[g] = true end
	end
	for _, u in ipairs({ "target", "mouseover", "focus" }) do
		local okG, g = pcall(UnitGUID, u)
		g = okG and g
		if type(g) == "string" and not S.IsSecret(g) then guids[g] = true end
	end
	layStale = guids
	layStaleUntil = GetTime() + STALE_FOR
	wipe(layVotes)
	laySeen = {}
end

-- the zone map id the route carries (C_Map walk to the zone level)
local function LayZoneId()
	if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then
		return nil
	end
	local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
	if not ok or type(id) ~= "number" or id <= 0 then return nil end
	local zone = id
	for _ = 1, 6 do
		local okI, info = pcall(C_Map.GetMapInfo, zone)
		if not okI or type(info) ~= "table"
			or type(info.mapType) ~= "number" then break end
		if info.mapType == ZONE_MAP then return zone end
		local up = info.parentMapID
		if info.mapType < ZONE_MAP or type(up) ~= "number" or up <= 0 then
			break
		end
		zone = up
	end
	return id
end

-- the zone name the layer registry files layers under
local function LayZoneText()
	local zone
	if type(GetRealZoneText) == "function" then
		local okZ, z = pcall(GetRealZoneText)
		zone = okZ and z or nil
	end
	if type(zone) ~= "string" or zone == "" then
		local okZ, z = pcall(GetZoneText)
		zone = okZ and z or nil
	end
	return (type(zone) == "string" and zone ~= "") and zone or "?"
end

-- 1 -> A, 2 -> B ... 26 -> Z, 27 -> AA (SentiLayer's letter scheme)
local function LayLetter(n)
	local s = ""
	while n > 0 do
		local r = (n - 1) % 26
		s = string.char(65 + r) .. s
		n = math.floor((n - 1) / 26)
	end
	return s
end

-- The friendly name for a layer. SentiLayer's letters win while that
-- addon is loaded (its SavedVariables keep the registry); without it the
-- plugin keeps its own per-zone registry in the plugin opts - first-seen
-- order, persisted across reloads, so "Layer A" stays "Layer A" instead
-- of showing the raw GUID key as if it were a name.
local function LayLabel(def, id)
	if not id then return nil end
	local key = LayerKey(id)
	local zone = LayZoneText()
	local db = type(SentiLayerDB) == "table" and SentiLayerDB.layers
	if type(db) == "table" then
		for _, l in pairs(db) do
			if type(l) == "table" and l.letter and l.zone == zone
				and LayerKey(l.id) == key then
				return "Layer " .. l.letter
			end
		end
	end
	if not def then return "Layer " .. tostring(key) end
	-- while sightings are still frozen (zone/layer change) or the zone
	-- name is unreadable, naming a layer would mint a wrong letter -
	-- the raw key is honest until the window passes
	if GetTime() < layStaleUntil or zone == "?" then
		return "Layer " .. tostring(key)
	end
	local reg = P.Opt(def, "reg")
	if type(reg) ~= "table" then
		reg = {}
		P.SetOpt(def, "reg", reg)
	end
	local list = reg[zone]
	if type(list) ~= "table" then
		list = {}
		reg[zone] = list
	end
	-- a zone can never hold more layers than letters: early builds minted
	-- one per vote flicker, so any list past Z is pollution to rebuild
	if #list > 26 then wipe(list) end
	for i, k in ipairs(list) do
		if k == key then return "Layer " .. LayLetter(i) end
	end
	list[#list + 1] = key
	return "Layer " .. LayLetter(#list)
end

-- channel plumbing -------------------------------------------------------------
local function LayChanId()
	local ok, n = pcall(GetChannelName, LAYER_CHANNEL)
	n = ok and n
	if type(n) == "number" and n > 0 then return n end
end

-- the layer channel belongs BEHIND the standard channels: if it sat
-- on a default slot (joined before they existed), a filler channel
-- parks the low slot while ours rejoins above it - same trick the FBL
-- sync uses
local function LayParkHigh()
	local n = LayChanId()
	if not n or n > 6 then return end
	if InCombatLockdown and InCombatLockdown() then return end
	local leave = (C_ChatInfo and C_ChatInfo.LeaveChannelByName)
		or LeaveChannelByName
	local join = (C_ChatInfo and C_ChatInfo.JoinChannelByName)
		or JoinChannelByName
	if not (leave and join) then return end
	local PARK = "sentipark"
	ns.HardAPI("LeaveChannelByName", leave, LAYER_CHANNEL)
	C_Timer.After(2, function()
		ns.HardAPI("JoinChannelByName", join, PARK)
		C_Timer.After(2, function()
			ns.HardAPI("JoinChannelByName", join, LAYER_CHANNEL)
			C_Timer.After(4, function()
				ns.HardAPI("LeaveChannelByName", leave, PARK)
			end)
		end)
	end)
end

local function LayJoinChan()
	if LayChanId() then
		LayParkHigh() -- already joined: still fix a low slot
		return true
	end
	local join = (C_ChatInfo and C_ChatInfo.JoinChannelByName)
		or JoinChannelByName
	if type(join) == "function" then
		ns.HardAPI("JoinChannelByName", join, LAYER_CHANNEL)
	end
	if LayChanId() then C_Timer.After(2, LayParkHigh) end
	return LayChanId() ~= nil
end

local function LayNote(text, chid)
	if not (chid and C_ChatInfo and C_ChatInfo.SendAddonMessage) then
		return
	end
	ns.HardAPI("SendAddonMessage(channel)", C_ChatInfo.SendAddonMessage,
		NOTE_PREFIX, text, "CHANNEL", chid)
end

-- "inv layer <SL <zoneId> not <id>>" + hidden notes: SentiLayer hosts
-- read the visible route even when addon notes are slow or refused
-- hardwareOnly: SendChatMessage on a channel needs a real input event on
-- this client, so timer/retried asks skip the visible route and ride the
-- addon-note path instead (standalone hosts read notes as well)
local function LaySendAsk(hardwareOnly)
	local chid = LayChanId()
	if not chid then
		LayJoinChan()
		C_Timer.After(1.5, function()
			if LayChanId() then LaySendAsk(false) end
		end)
		return
	end
	local zone = LayZoneId()
	if hardwareOnly then
		local route = "<SL" .. (zone and (" " .. zone) or "")
			.. " not " .. layCurrent .. ">"
		local send = (C_ChatInfo and C_ChatInfo.SendChatMessage)
			or SendChatMessage
		ns.HardAPI("SendChatMessage(channel)", send,
			"inv layer " .. route, "CHANNEL", nil, chid)
	end
	if zone then LayNote("zone " .. zone, chid) end
	LayNote("not " .. layCurrent, chid)
end

local function LayAsk()
	if not layCurrent then
		LayScan()
		if not layCurrent then
			S.Print(L["Reading your layer first - target or mouse over an NPC, then ask again."])
			return
		end
	end
	if IsInGroup() and not (ask and ask.joined) then
		S.Print(L["You are in a group - leave it to swap layers."])
		return
	end
	if ask and GetTime() - ask.at < ASK_COOLDOWN then return end
	ask = { at = GetTime(), want = nil }
	LaySendAsk(true)
end

-- host side ------------------------------------------------------------------
local function LayHosting(def)
	return P.Opt(def, "host") ~= false -- on like SentiLayer
end

-- alone, or leading a party we are filling - raids never host
local function LayCanInvite()
	if IsInRaid() then return false end
	if not IsInGroup() then return true end
	local ok, lead = pcall(UnitIsGroupLeader, "player")
	return ok and lead == true
end

-- "<SL zone want id | not id [not id...] x,y>" from the visible line -
-- hosts read it even when the hidden notes never arrive
local function LayRoute(msg)
	if type(msg) ~= "string" then return nil end
	local body = msg:match("<SL([^<>]*)>")
	if not body then return nil end
	local avoids = {}
	for id in body:gmatch("not%s+(%d+%-%d+)") do
		avoids[#avoids + 1] = id
	end
	return {
		zone = body:match("^%s*(%d+)%s") or body:match("^%s*(%d+)%s*$"),
		want = body:match("want%s+(%d+%-%d+)"),
		avoids = avoids,
	}
end

local function LayInvite(name)
	local now = GetTime()
	if hostInvited[name] and now - hostInvited[name] < INVITE_COOLDOWN then
		return
	end
	if now - lastInviteAt < INVITE_SPACING then
		C_Timer.After(INVITE_SPACING, function() LayInvite(name) end)
		return
	end
	if not LayCanInvite() then return end
	lastInviteAt = now
	hostInvited[name] = now
	local call = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
	ns.HardAPI("InviteUnit", call, name)
end

local function LayOnChannelMsg(def, text, sender, channelName)
	if not LayHosting(def) or not layCurrent then return end
	if type(text) ~= "string" or not text:find("^inv layer") then return end
	if type(channelName) ~= "string"
		or channelName:lower() ~= LAYER_CHANNEL then return end
	if type(sender) ~= "string" then return end
	-- our own ask echoes back on the channel - never invite ourselves
	local ok, me = pcall(UnitName, "player")
	if ok and me and sender:find(me, 1, true) then return end
	local route = LayRoute(text)
	if route then
		-- this ask names its layer: only a host NOT on it answers
		if route.want and LaySame(route.want, layCurrent) then return end
		for _, id in ipairs(route.avoids) do
			if LaySame(id, layCurrent) then return end
		end
		-- Forever asks stay inside their zone map
		local ours = LayZoneId()
		if route.zone and ours and tostring(ours) ~= tostring(route.zone) then
			return
		end
	end
	LayInvite(sender)
end

-- guests we invited joined the party: they moved the moment they joined,
-- so the host clears the seat for the next asker
local function LayKickGuests()
	if not LayCanInvite() or type(hostInvited) ~= "table" then return end
	local un = (C_PartyInfo and C_PartyInfo.UninviteUnit) or UninviteUnit
	for i = 1, PARTY_MAX - 1 do
		local unit = "party" .. i
		if UnitExists(unit) then
			local ok, name = pcall(UnitName, unit)
			name = ok and name
			if type(name) == "string" and hostInvited[name]
				and not hostInvited[name .. ":in"] then
				hostInvited[name .. ":in"] = true
				C_Timer.After(8, function()
					if LayCanInvite() then ns.HardAPI("UninviteUnit", un, name) end
					hostInvited[name .. ":in"] = nil
				end)
			end
		end
	end
end

ns.RegisterPlugin({
	id = "layer",
	label = L["Layer"],
	icon = "Interface\\Icons\\Spell_Frost_Stun",
	bar = "bottom", zone = "RIGHT", order = 55,
	events = { "NAME_PLATE_UNIT_ADDED", "PLAYER_TARGET_CHANGED",
		"UPDATE_MOUSEOVER_UNIT", "PLAYER_ENTERING_WORLD",
		"ZONE_CHANGED_NEW_AREA", "GROUP_JOINED", "GROUP_LEFT",
		"GROUP_ROSTER_UPDATE", "SHARD_TRANSFER", "CHAT_MSG_CHANNEL" },
	onevent = function(def, event, unit, a2, a3, a4)
		if event == "NAME_PLATE_UNIT_ADDED" and type(unit) == "string" then
			LayObserve(unit)
		elseif event == "PLAYER_TARGET_CHANGED" then
			LayObserve("target")
		elseif event == "UPDATE_MOUSEOVER_UNIT" then
			LayObserve("mouseover")
		elseif event == "PLAYER_ENTERING_WORLD"
			or event == "ZONE_CHANGED_NEW_AREA" then
			LayMarkStale()
			LayScan()
			if LayHosting(def) then
				LayJoinChan()
			elseif event == "PLAYER_ENTERING_WORLD" and LayChanId() then
				-- still joined from a previous session: keep the slot
				-- behind the standard channels
				C_Timer.After(15, LayParkHigh)
			end
		elseif event == "GROUP_JOINED" then
			LayMarkStale()
			if ask then
				ask.joined = true
				-- no confirmed move within the ask's life: leave anyway
				C_Timer.After(ASK_TTL, function()
					if ask and ask.joined and IsInGroup() then
						local leave = (C_PartyInfo
							and C_PartyInfo.LeaveParty) or LeaveParty
						ns.HardAPI("LeaveParty", leave)
					end
					ask = nil
				end)
			end
		elseif event == "GROUP_LEFT" then
			LayMarkStale()
			ask = nil
		elseif event == "GROUP_ROSTER_UPDATE" then
			LayKickGuests()
		elseif event == "SHARD_TRANSFER" then
			LayMarkStale()
		elseif event == "CHAT_MSG_CHANNEL" then
			LayOnChannelMsg(def, unit, a2, a4)
		end
	end,
	update = function(def)
		-- the last reading holds until the votes move to another layer -
		-- and across /reload via the plugin opts, so the bar does not
		-- drop to "?" while the client still stands on the same shard
		if not layCurrent then
			layCurrent = P.Opt(def, "last")
			if not layCurrent then LayScan() end
			if not layCurrent then
				return "|cff555c70" .. L["Layer"] .. ": ?|r"
			end
		end
		if P.Opt(def, "last") ~= layCurrent then
			P.SetOpt(def, "last", layCurrent)
		end
		local t = "|cff" .. S.Hex(S.colors.accent2)
			.. LayLabel(def, layCurrent) .. "|r"
		if ask and not ask.joined then
			t = t .. " |cff8a8f98…|r"
		end
		return t
	end,
	tooltip = function(tip)
		local def = P.byId["layer"]
		TipHead(tip, L["Layer"])
		TipKV(tip, L["Layer"], layCurrent
			and (LayLabel(def, layCurrent) .. "  (" .. layCurrent .. ")")
			or L["Unknown"])
		TipKV(tip, L["Host swaps"],
			def and LayHosting(def) and L["On"] or L["Off"])
		if ask then
			TipKV(tip, L["Swap"],
				ask.joined and L["moved - leaving host group"]
					or L["asking for invites…"])
		end
		TipSub(tip, L["Left-click: ask for a layer swap  |  Right-click: options"])
	end,
	click = function() LayAsk() end,
	menu = function(def, items)
		items[#items + 1] = {
			text = L["Ask for a layer swap"],
			onClick = function() LayAsk() end,
		}
		items[#items + 1] = {
			text = L["Host swaps"],
			checked = LayHosting(def),
			noClose = true,
			onClick = function()
				P.SetOpt(def, "host", not LayHosting(def))
				if LayHosting(def) then LayJoinChan() end
				def.last = nil
				P.UpdateOne(def)
			end,
		}
		if ask then
			items[#items + 1] = {
				text = L["Stop asking"],
				onClick = function() ask = nil end,
			}
		end
	end,
})
