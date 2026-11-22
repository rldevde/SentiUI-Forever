-- The SentiUI quest tracker: a slim Sentinel list of watched quests, built
-- from the quest log. Zone headers, [level] titles, objective progress,
-- gold completion. Left-click opens the quest log, shift-click untracks.
-- Read-only data access: every quest log call is pcall-guarded and secret
-- values are never compared.
local _, ns = ...
local S = SentiUI
local L = ns.L

local format, ipairs, math = string.format, ipairs, math
local CreateFrame, InCombatLockdown = CreateFrame, InCombatLockdown

local function SC(n)
	local g = S.DB.General()
	return n * ((g and g.uiScale) or 1)
end
local function SetFont(fs, size, flags)
	if not fs then return end
	-- the FontStrings are created with the GameFontNormal object so a font
	-- is always set; SetFont only restyles it. The client rejects float
	-- sizes (SetFont silently failed), so round first.
	size = math.floor((size or 12) + 0.5)
	for _, f in ipairs({ S.media.font, STANDARD_TEXT_FONT, "Fonts\\FRIZQT__.TTF" }) do
		if f and not S.IsSecret(f) and pcall(fs.SetFont, fs, f, size, flags or "") then break end
	end
	pcall(fs.SetShadowColor, fs, 0, 0, 0, 0)
end

ns.Core = ns.Core or {}
local Core = ns.Core

local db
local frame, headerFS, zoneBtn, allBtn, emptyFS
local view, content, bar, thumb
local scroll, contentH = 0, 0
local pool = {}        -- pooled row frames (headers and quests)
local used = 0
-- frames created during combat lockdown are born protected - every
-- Show/SetPoint on them then fires ADDON_ACTION_FORBIDDEN. The pool is
-- warmed up front and never grows mid-fight.
local POOL_WARM = 45

-- quest log reads ---------------------------------------------------------------
local function QuestInfo(index)
	if C_QuestLog and C_QuestLog.GetInfo then
		local ok, info = pcall(C_QuestLog.GetInfo, index)
		if ok and type(info) == "table" then return info end
		return nil
	end
	-- fallback: classic tuple API
	local ok, title, level, _, isHeader, _, isComplete, _, questID =
		pcall(GetQuestLogTitle, index)
	if ok and title then
		return { title = title, level = level, isHeader = isHeader,
			questID = questID, isComplete = isComplete }
	end
	return nil
end

local function NumEntries()
	if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
		local ok, n = pcall(C_QuestLog.GetNumQuestLogEntries)
		if ok and type(n) == "number" then return n end
	elseif GetNumQuestLogEntries then
		local ok, n = pcall(GetNumQuestLogEntries)
		if ok and type(n) == "number" then return n end
	end
	return 0
end

local watchedSet -- questID -> true, built once per refresh
local function IsWatched(questID)
	if watchedSet then return watchedSet[questID] == true end
	if C_QuestLog and C_QuestLog.GetQuestWatchType then
		local ok, w = pcall(C_QuestLog.GetQuestWatchType, questID)
		-- secrets throw on any comparison, ~= nil included
		return ok and not S.IsSecret(w) and w ~= nil
	end
	return false
end

local function BuildWatchSet()
	watchedSet = nil
	-- the client's own way: watch index -> questID
	if C_QuestLog and C_QuestLog.GetNumQuestWatches and C_QuestLog.GetQuestIDForQuestWatchIndex then
		local ok, n = pcall(C_QuestLog.GetNumQuestWatches)
		if ok and type(n) == "number" and not S.IsSecret(n) then
			watchedSet = {}
			for i = 1, n do
				local okI, id = pcall(C_QuestLog.GetQuestIDForQuestWatchIndex, i)
				if okI and id and not S.IsSecret(id) then watchedSet[id] = true end
			end
			return
		end
	end
	-- older global API
	if GetNumQuestWatches and GetQuestIndexForWatch then
		local ok, n = pcall(GetNumQuestWatches)
		if ok and type(n) == "number" then
			watchedSet = {}
			for i = 1, n do
				local okI, idx = pcall(GetQuestIndexForWatch, i)
				if okI and idx then
					local info = QuestInfo(idx)
					if info and not S.IsSecretTable(info) and info.questID
						and not S.IsSecret(info.questID) then
						watchedSet[info.questID] = true
					end
				end
			end
			return
		end
	end
	-- no list API: IsWatched falls back to per-quest GetQuestWatchType
end

local function IsComplete(questID)
	if C_QuestLog and C_QuestLog.IsComplete then
		local ok, c = pcall(C_QuestLog.IsComplete, questID)
		if ok then return not S.IsSecret(c) and c == true end
	end
	return false
end

local function Objectives(questID)
	local list = {}
	-- modern table API first
	if C_QuestLog and C_QuestLog.GetQuestObjectives then
		local ok, objs = pcall(C_QuestLog.GetQuestObjectives, questID)
		if ok and type(objs) == "table" and not S.IsSecretTable(objs) then
			for _, o in ipairs(objs) do
				if type(o) == "table" and not S.IsSecretTable(o)
					and type(o.text) == "string" then
					list[#list + 1] = {
						text = o.text,
						finished = o.finished == true,
						numF = type(o.numFulfilled) == "number" and o.numFulfilled or nil,
						numR = type(o.numRequired) == "number" and o.numRequired or nil,
					}
				end
			end
			return list
		end
	end
	if not GetQuestObjectiveInfo then return list end
	local j = 1
	while true do
		local ok, text, _, finished, numF, numR = pcall(GetQuestObjectiveInfo, questID, j, false)
		if not ok or not text or S.IsSecret(text) then break end
		list[#list + 1] = {
			text = text,
			finished = (not S.IsSecret(finished)) and finished == true,
			numF = (type(numF) == "number" and not S.IsSecret(numF)) and numF or nil,
			numR = (type(numR) == "number" and not S.IsSecret(numR)) and numR or nil,
		}
		j = j + 1
		if j > 30 then break end
	end
	return list
end

-- opening a quest shows the world map on its map and pings it - the old
-- QuestLogFrame is an empty leftover window on this client. Track() also
-- makes the quest the super-tracked target, so the way marker points at it
-- difficulty color of a quest level, exactly like the game colors the
-- log: gray (trivial), green, yellow, orange, red. GetQuestDifficultyColor
-- is the native source; the fallback bands against the player level use
-- the classic thresholds
local function DiffColor(level)
	if type(level) ~= "number" or level <= 0 or S.IsSecret(level) then return nil end
	if GetQuestDifficultyColor then
		local ok, c = pcall(GetQuestDifficultyColor, level)
		if ok and type(c) == "table" and type(c.r) == "number" then
			return format("|cff%02x%02x%02x",
				math.floor(c.r * 255 + 0.5),
				math.floor(c.g * 255 + 0.5),
				math.floor(c.b * 255 + 0.5))
		end
	end
	local pl = UnitLevel and UnitLevel("player") or 0
	if pl <= 0 then return nil end
	local d = level - pl
	local r, g, b
	if d <= -6 then r, g, b = 0.50, 0.50, 0.50
	elseif d <= -3 then r, g, b = 0.25, 0.75, 0.25
	elseif d <= 1 then r, g, b = 0.90, 0.80, 0.25
	elseif d <= 3 then r, g, b = 1.00, 0.50, 0.25
	else r, g, b = 1.00, 0.15, 0.15 end
	return format("|cff%02x%02x%02x",
		math.floor(r * 255 + 0.5),
		math.floor(g * 255 + 0.5),
		math.floor(b * 255 + 0.5))
end

local function Track(questID)
	local ST = C_SuperTrack
	if not ST then return end
	if ST.SetSuperTrackedQuestID then
		pcall(ST.SetSuperTrackedQuestID, questID)
	elseif ST.SetSuperTrackedQuest then
		pcall(ST.SetSuperTrackedQuest, questID)
	end
end

-- waypoint spot: GetNextWaypoint first (the game's own navigation point),
-- else the quest's pin position on the player's current map
local function QuestSpot(questID)
	if C_QuestLog and C_QuestLog.GetNextWaypoint then
		local ok, m, x, y = pcall(C_QuestLog.GetNextWaypoint, questID)
		if ok and type(m) == "number"
			and type(x) == "number" and type(y) == "number" then
			return m, x, y
		end
	end
	if C_Map and C_Map.GetBestMapForUnit and C_QuestLog
		and C_QuestLog.GetQuestsOnMap then
		local okM, m = pcall(C_Map.GetBestMapForUnit, "player")
		if okM and type(m) == "number" then
			local okQ, list = pcall(C_QuestLog.GetQuestsOnMap, m)
			if okQ and type(list) == "table" and not S.IsSecretTable(list) then
				for _, q in ipairs(list) do
					if type(q) == "table" and q.questID == questID
						and type(q.x) == "number" and type(q.y) == "number" then
						return m, q.x, q.y
					end
				end
			end
		end
	end
end

local function SetWaypoint(m, x, y)
	if not (C_Map and C_Map.SetUserWaypoint) then return end
	if UiMapPoint and UiMapPoint.CreateFromCoordinates then
		local ok, pt = pcall(UiMapPoint.CreateFromCoordinates, m, x, y)
		if ok and pt and pcall(C_Map.SetUserWaypoint, pt) then return end
	end
	pcall(C_Map.SetUserWaypoint, m, x, y) -- some clients take plain coords
end

-- declared before PinQuest: the pin calls it, so the local has to be in
-- scope already (a later local declaration would resolve as nil global)
local function OpenOnMap(questID)
	if InCombatLockdown() then return end
	if C_QuestLog and C_QuestLog.SetSelectedQuest then
		pcall(C_QuestLog.SetSelectedQuest, questID)
	end
	local mapID = type(GetQuestUiMapID) == "function"
		and GetQuestUiMapID(questID, true)
	if C_Map and C_Map.OpenWorldMap then
		pcall(C_Map.OpenWorldMap,
			(type(mapID) == "number" and mapID > 0) and mapID or nil)
	end
	if EventRegistry and EventRegistry.TriggerEvent then
		pcall(EventRegistry.TriggerEvent, EventRegistry,
			"MapCanvas.PingQuestID", questID)
	end
end

-- pin a quest: super-track it AND drop the client's own waypoint on its
-- spot - the waypoint is what draws the route line on the map and the
-- edge marker on the minimap
local function PinQuest(questID)
	Track(questID)
	local m, x, y = QuestSpot(questID)
	if m then SetWaypoint(m, x, y) end
	OpenOnMap(questID)
end

-- right-click on a pin clears our waypoint and the tracking again
local function UnpinQuest()
	if C_Map and C_Map.ClearUserWaypoint then
		pcall(C_Map.ClearUserWaypoint)
	end
	if C_SuperTrack and C_SuperTrack.ClearAllSuperTracked then
		pcall(C_SuperTrack.ClearAllSuperTracked)
	elseif C_SuperTrack and C_SuperTrack.ClearSuperTrackedQuestID then
		pcall(C_SuperTrack.ClearSuperTrackedQuestID)
	end
end

-- rows ---------------------------------------------------------------------------
local function GetRow(i)
	local r = pool[i]
	if not r then
		-- creating frames in combat would produce protected frames; keep
		-- rendering what the warm pool has instead
		if InCombatLockdown() then return nil end
		r = CreateFrame("Button", nil, content)
		r.title = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		r.title:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
		r.title:SetPoint("RIGHT", r, "RIGHT", 0, 0)
		r.title:SetJustifyH("LEFT")
		r.title:SetWordWrap(true)
		r.objs = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		r.objs:SetPoint("TOPLEFT", r.title, "BOTTOMLEFT", SC(8), -SC(1))
		r.objs:SetPoint("RIGHT", r, "RIGHT", 0, 0)
		r.objs:SetJustifyH("LEFT")
		r.objs:SetWordWrap(true)
		r.hl = r:CreateTexture(nil, "BACKGROUND")
		r.hl:SetAllPoints()
		r.hl:SetColorTexture(0.92, 0.68, 0.20, 0.06)
		r.hl:Hide()
		r:RegisterForClicks("LeftButtonUp")
		-- map pin (plain button) + usable quest item (secure button) on the
		-- right edge; the item's macro only changes out of combat
		r.pin = CreateFrame("Button", nil, r)
		r.pin:SetSize(SC(16), SC(16))
		r.pin:SetPoint("TOPRIGHT", r, "TOPRIGHT", -2, -1)
		r.pin.icon = r.pin:CreateTexture(nil, "ARTWORK")
		r.pin.icon:SetAllPoints()
		-- if the media file does not resolve on this client, fall back to a
		-- gold diamond so the button is still visible and clickable
		if not r.pin.icon:SetTexture(
			"Interface\\AddOns\\SentiUI_Quests\\Media\\Pin") then
			r.pin.icon:SetTexture("Interface\\Buttons\\WHITE8X8")
			r.pin.icon:SetRotation(math.pi / 4)
			r.pin.icon:SetVertexColor(0.92, 0.68, 0.20)
			r.pin.icon:SetPoint("CENTER", r.pin, "CENTER")
			r.pin.icon:SetSize(SC(9), SC(9))
		end
		r.pin:SetScript("OnEnter", function()
			GameTooltip:SetOwner(r.pin, "ANCHOR_LEFT")
			GameTooltip:AddLine(L["Pin"], 0.92, 0.93, 0.96)
			GameTooltip:AddLine(L["Left-click: mark the way, right-click: clear."], 0.55, 0.57, 0.64)
			GameTooltip:Show()
		end)
		r.pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
		r.pin:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		r.pin:SetScript("OnClick", function(self, btn)
			if btn == "RightButton" then
				UnpinQuest()
				return
			end
			local q = self:GetParent().questID
			if q then PinQuest(q) end
		end)
		r.pin:Hide()
		r.item = CreateFrame("Button", nil, r, "SecureActionButtonTemplate")
		r.item:SetSize(SC(16), SC(16))
		r.item:SetPoint("TOPRIGHT", r.pin, "TOPLEFT", -2, 0)
		r.item:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
		r.item:SetAttribute("type", "item")
		r.item.icon = r.item:CreateTexture(nil, "ARTWORK")
		r.item.icon:SetAllPoints()
		r.item:SetScript("OnEnter", function(self)
			if self.link then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				-- untainted: the tooltip fill reads secret item data
				if type(securecall) == "function" then
					securecall(GameTooltip.SetHyperlink, GameTooltip, self.link)
				else
					pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
				end
				GameTooltip:Show()
			end
		end)
		r.item:SetScript("OnLeave", function() GameTooltip:Hide() end)
		r.item:SetAlpha(0)
		r:SetScript("OnEnter", function(self)
			self.hl:Show()
			if self.questID then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				GameTooltip:AddLine(self.fullTitle or "", 0.92, 0.93, 0.96)
				GameTooltip:AddLine(L["Click: show on the map, pin: mark the way, shift-click: link into open chat (else stop tracking)."], 0.55, 0.57, 0.64)
				GameTooltip:Show()
			end
		end)
		r:SetScript("OnLeave", function(self) self.hl:Hide() GameTooltip:Hide() end)
		r:SetScript("OnClick", function(self)
			if self.zoneName then
				db.collapsed = db.collapsed or {}
				db.collapsed[self.zoneName] = not db.collapsed[self.zoneName] or nil
				Core.Refresh()
				return
			end
			if not self.questID then return end
			if IsShiftKeyDown() then
				-- chat box open: paste the quest link into it (share the
				-- quest in a channel); no open box falls back to untrack
				local okL, link = pcall(function()
					if C_QuestLog and C_QuestLog.GetQuestLink then
						return C_QuestLog.GetQuestLink(self.questID)
					end
					if type(GetQuestLink) == "function" then
						return GetQuestLink(self.questID)
					end
				end)
				local insert = (ChatFrameUtil and ChatFrameUtil.InsertLink)
					or ChatEdit_InsertLink
				if okL and type(link) == "string"
					and type(insert) == "function" then
					local okI, did = pcall(insert, link)
					if okI and did ~= false then return end
				end
				if C_QuestLog and C_QuestLog.RemoveQuestWatch then
					pcall(C_QuestLog.RemoveQuestWatch, self.questID)
				end
				return
			end
			PinQuest(self.questID)
		end)
		pool[i] = r
	end
	return r
end

local dirty -- a render was requested during combat; done on regen
local SetScroll -- forward: Refresh clamps the offset, defined below

local function Refresh()
	if not frame or not db or db.tracker ~= "sentiui" then
		if frame and not InCombatLockdown() then frame:Hide() end
		return
	end
	local C = S.colors
	local fs = SC(db.fontSize or 12)
	local gap = SC(db.spacing or 2)
	local width = db.width or 260

	BuildWatchSet()
	-- filter modes: "watched" = the game's quest watch list (default),
	-- "zone" = every quest under the current zone's log header,
	-- "all" = the whole log. zoneName reads localized like the headers.
	local mode = db.filter or "watched"
	local zoneName
	if mode == "zone" then
		local okz, zn = pcall(GetRealZoneText)
		zoneName = okz and not S.IsSecret(zn) and zn or nil
		if type(zoneName) ~= "string" or zoneName == "" then
			local okz2, zn2 = pcall(GetZoneText)
			zoneName = okz2 and not S.IsSecret(zn2) and zn2 or nil
		end
	end
	local showAll = mode == "all"
	local zoneOnly = mode == "zone" and type(zoneName) == "string" and zoneName ~= ""
	local items = {}
	local count = 0
	local curHeader
	for i = 1, NumEntries() do
		local info = QuestInfo(i)
		if info and not S.IsSecretTable(info) and not S.IsSecret(info.title) then
			if info.isHeader then
				curHeader = info.title
				items[#items + 1] = { header = info.title }
			elseif info.questID and not S.IsSecret(info.questID)
				and not info.isHidden
				and (showAll or (zoneOnly and curHeader == zoneName)
					or (not showAll and not zoneOnly and IsWatched(info.questID))) then
				local complete = ((not S.IsSecret(info.isComplete)) and info.isComplete == true)
					or IsComplete(info.questID)
				local title = info.title or "?"
				if db.questLevels and type(info.level) == "number"
					and not S.IsSecret(info.level) and info.level > 0 then
					title = format("[%d] %s", info.level, title)
				end
				local it = {
					quest = true, id = info.questID, logIndex = i,
					title = title, rawTitle = info.title,
					complete = complete,
					color = DiffColor(info.level),
					objs = complete and {} or Objectives(info.questID),
				}
				-- usable quest item next to the row (click = /use item:id)
				if GetQuestLogSpecialItemInfo then
					local okQ, itemID, r2, r3 = pcall(GetQuestLogSpecialItemInfo, i)
					if okQ and itemID and not S.IsSecret(itemID) then
						it.itemID = itemID
						-- return layout varies between builds
						-- ((id, texture), (id, texture, usable) or
						-- (id, link, texture)) - pick the value that is
						-- actually a texture: fileIDs are large numbers,
						-- paths contain backslashes; links start |H and
						-- flags are tiny numbers
						local function asIcon(v)
							if S.IsSecret(v) then return nil end
							if type(v) == "number" then
								if v > 100 then return v end
								return nil
							end
							if type(v) == "string"
								and v:find("\\") then
								return v
							end
						end
						it.itemIcon = asIcon(r2) or asIcon(r3)
						if not it.itemIcon
							and C_Item and C_Item.GetItemIconByID then
							local okI, ic = pcall(C_Item.GetItemIconByID, itemID)
							if okI and ic and not S.IsSecret(ic) then
								it.itemIcon = ic
							end
						end
						-- link either arrived as second return or comes
						-- from the item API
						if type(r2) == "string" and r2:find("|H") then
							it.itemLink = r2
						elseif C_Item and C_Item.GetItemLink then
							local okL, link = pcall(C_Item.GetItemLink, itemID)
							if okL and link and not S.IsSecret(link) then
								it.itemLink = link
							end
						end
					end
				end
				items[#items + 1] = it
				count = count + 1
			end
		end
	end

	-- drop zone headers that have no watched quests under them
	local clean = {}
	for i, it in ipairs(items) do
		if it.header then
			local nxt = items[i + 1]
			if nxt and nxt.quest then clean[#clean + 1] = it end
		else
			clean[#clean + 1] = it
		end
	end
	-- and a trailing header
	if clean[#clean] and clean[#clean].header then clean[#clean] = nil end

	headerFS:SetText(count > 0 and format("%s  |cff555c70(%d)|r", L["Quests"], count) or L["Quests"])
	for _, b in ipairs({ zoneBtn, allBtn }) do
		if b then
			local c = (db.filter == b.mode) and S.colors.accent or S.colors.textDim
			b.fs:SetTextColor(c.r, c.g, c.b)
		end
	end

	-- combat lockdown: NO calls on Button widgets at all - a protected row
	-- (or one under a protected parent) makes every Show/SetPoint/EnableMouse
	-- fire ADDON_ACTION_FORBIDDEN. Regions (FontStrings/Textures) and plain
	-- table fields are always allowed, so text keeps updating live; the
	-- structural pass runs on PLAYER_REGEN_ENABLED via `dirty`.
	local combat = InCombatLockdown()
	used = 0
	local y = SC(2) -- content-local: the view scrolls the rows inside it
	local folded = false
	for _, it in ipairs(clean) do
		if it.header then
			folded = db.collapsed and db.collapsed[it.header] == true
		end
		if it.header or not folded then
			used = used + 1
			local r = combat and pool[used] or GetRow(used)
			if not r then break end -- pool exhausted; fills after combat
			local lines -- quest objective lines; lives in the iteration
			-- scope because the structural pass below still needs it
			-- fields + regions: always allowed
			r.questID = nil
			r.zoneName = nil
			r.fullTitle = nil
			r.item.link = nil
			if it.header then
				SetFont(r.title, fs - 1, "OUTLINE")
				if not combat then
					r.title:SetPoint("RIGHT", r, "RIGHT", -SC(4), 0)
				end
				local mark = folded
					and "|TInterface\\Buttons\\UI-PlusButton-Up:11|t"
					or "|TInterface\\Buttons\\UI-MinusButton-Up:11|t"
				r.title:SetText(mark .. " |cff8a8040" .. it.header .. "|r")
				r.objs:SetText("")
				r.zoneName = it.header
			else
				SetFont(r.title, fs, "OUTLINE")
				if not combat then
					r.title:SetPoint("RIGHT", r, "RIGHT", -SC(40), 0)
				end
				r.title:SetText(it.complete
					and format("|cff%s%s |TInterface\\RaidFrame\\ReadyCheck-Ready:11|t|r",
						S.Hex(C.green), it.title)
					or (it.color and (it.color .. it.title .. "|r") or it.title))
				SetFont(r.objs, fs - 1, "")
				lines = {}
				for _, o in ipairs(it.objs) do
					local t = o.text or ""
					if o.numF and o.numR and o.numR > 1 then
						t = format("%s  |cff8a8040(%d/%d)|r", t, o.numF, o.numR)
					end
					lines[#lines + 1] = o.finished
						and format("|cff%s- %s|r", S.Hex(C.green), t)
						or format("|cff%s- %s|r", S.Hex(C.textDim), t)
				end
				r.objs:SetText(#lines > 0 and table.concat(lines, "\n") or "")
				r.questID = it.id
				r.fullTitle = it.rawTitle
				if it.itemID then
					r.item.icon:SetTexture(it.itemIcon) -- region: allowed
					r.item.link = it.itemLink
				end
			end
			if not combat then
				-- structure: out of combat only
				r:ClearAllPoints()
				r:SetPoint("TOPLEFT", content, "TOPLEFT", SC(4), -y)
				r:SetWidth(width - SC(16))
				r.pin:Hide()
				r.item:SetAlpha(0)
				r.item:SetAttribute("item", "")
				if it.header then
					r:SetHeight(r.title:GetHeight() + gap)
				else
					local h = r.title:GetHeight()
						+ (lines and #lines > 0 and (r.objs:GetHeight() + SC(1)) or 0)
					r:SetHeight(h + gap)
					r.pin:Show()
					if it.itemID then
						r.item:SetAlpha(1)
						r.item:SetAttribute("item", it.itemID)
					end
				end
				r:EnableMouse(true)
				r:Show()
				y = y + r:GetHeight() + gap
			end
		end
	end

	if combat then
		dirty = true
		-- stale leftover rows keep their spot but lose their content
		for i = used + 1, #pool do
			local r = pool[i]
			if r and r.title then
				r.title:SetText("")
				r.objs:SetText("")
				r.questID, r.zoneName, r.fullTitle = nil, nil, nil
			end
		end
		return
	end
	dirty = nil

	for i = used + 1, #pool do pool[i]:Hide() end

	-- the wheel scrolls inside a clipped view instead of the tracker
	-- growing the whole screen tall; fixedHeight keeps the box at
	-- maxHeight even for a short list
	contentH = math.max(y + SC(2), 1)
	content:SetSize(width - SC(8), contentH)
	local maxH = math.max(SC(db.maxHeight or 420), 40)
	local viewH = (db.fixedHeight ~= false) and maxH
		or math.min(contentH, maxH)
	view:ClearAllPoints()
	view:SetPoint("TOPLEFT", frame, "TOPLEFT", SC(4),
		-(headerFS:GetHeight() + SC(8)))
	view:SetSize(width - SC(8), viewH)
	frame:SetSize(width, headerFS:GetHeight() + SC(10) + viewH + SC(6))
	-- an active filter keeps the frame (and its buttons) alive even with
	-- zero matches - only the default watched view hides when empty
	local filterOn = db.filter == "zone" or db.filter == "all"
	frame:SetShown(count > 0 or filterOn)
	if count == 0 and filterOn then
		emptyFS:SetText(db.filter == "zone"
			and L["No quests in this zone"] or L["No quests"])
		emptyFS:Show()
	else
		emptyFS:Hide()
	end
	SetScroll(scroll) -- clamp + re-anchor
end
Core.Refresh = Refresh

-- scroll: the content child slides inside the clipped view; offset>0
-- pushes its top above the view's top edge (see lower rows)
local function UpdateThumb()
	if not bar or not view then return end
	local vh = view:GetHeight()
	if not vh or vh <= 0 or contentH <= vh then
		bar:Hide()
		thumb:Hide()
		return
	end
	bar:ClearAllPoints()
	bar:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, 0)
	bar:SetPoint("BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0)
	bar:SetWidth(3)
	bar:Show()
	local th = math.max(14, vh * vh / contentH)
	local span = math.max(contentH - vh, 1)
	local frac = math.max(0, math.min(scroll / span, 1))
	thumb:ClearAllPoints()
	thumb:SetPoint("TOPRIGHT", view, "TOPRIGHT", 0, -frac * (vh - th))
	thumb:SetSize(3, th)
	thumb:Show()
end

function SetScroll(v)
	-- wheel scrolls re-anchor content/thumb - protected calls under
	-- lockdown; the next Refresh clamps the offset instead
	if InCombatLockdown() then return end
	local vh = view and view:GetHeight() or 0
	local span = math.max(contentH - vh, 0)
	scroll = math.max(0, math.min(v or 0, span))
	if content then
		content:ClearAllPoints()
		content:SetPoint("TOPLEFT", view, "TOPLEFT", 0, scroll)
	end
	UpdateThumb()
end

local pending
local function Schedule()
	if pending then return end
	pending = true
	C_Timer.After(0.3, function()
		pending = false
		S.SafeCall("quests:refresh", Core.Refresh)
	end)
end

-- frame ---------------------------------------------------------------------------
local function BuildFrame()
	if frame then return end
	frame = CreateFrame("Frame", "SentiUIQuestTracker", UIParent)
	S.Template(frame, "panel")
	frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -SC(6), -SC(240))
	frame:SetFrameStrata("LOW")
	frame:SetClampedToScreen(true)
	headerFS = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerFS:SetPoint("TOPLEFT", frame, "TOPLEFT", SC(8), -SC(4))
	headerFS:SetPoint("RIGHT", frame, "RIGHT", -SC(8), 0)
	headerFS:SetJustifyH("LEFT")
	SetFont(headerFS, SC((db.fontSize or 12) + 1), "OUTLINE")
	headerFS:SetText(L["Quests"])
	headerFS:SetTextColor(S.colors.accent.r, S.colors.accent.g, S.colors.accent.b)

	-- filter buttons top right: the active one wears the accent color,
	-- clicking it again returns to the watched list. Built with the frame
	-- so they exist before combat.
	local function mkFilter(label, mode, xoff)
		local b = CreateFrame("Button", nil, frame)
		b:SetSize(44, 14)
		b:SetPoint("TOPRIGHT", frame, "TOPRIGHT", xoff, -SC(4))
		b.fs = S.Font(b, 10)
		b.fs:SetPoint("CENTER")
		b.fs:SetText(label)
		b.mode = mode
		b:RegisterForClicks("LeftButtonUp")
		b:SetScript("OnClick", function()
			db.filter = (db.filter == mode) and "watched" or mode
			Core.Refresh()
		end)
		b:SetScript("OnEnter", function(self)
			if db.filter ~= mode then
				local c = S.colors.text
				self.fs:SetTextColor(c.r, c.g, c.b)
			end
		end)
		b:SetScript("OnLeave", function(self)
			local c = (db.filter == mode) and S.colors.accent or S.colors.textDim
			self.fs:SetTextColor(c.r, c.g, c.b)
		end)
		return b
	end
	allBtn = mkFilter(L["All"], "all", -SC(6))
	zoneBtn = mkFilter(L["Zone"], "zone", -SC(52))

	-- clipped view + content child: rows live in `content`, the wheel
	-- slides it inside `view` and a slim bar shows the position
	view = CreateFrame("Frame", nil, frame)
	-- empty-state note: keeps the frame useful while a filter matches
	-- nothing (the header's buttons stay reachable to switch back)
	emptyFS = view:CreateFontString(nil, "OVERLAY")
	emptyFS:SetPoint("TOPLEFT", view, "TOPLEFT", SC(6), -SC(4))
	SetFont(emptyFS, SC(db.fontSize or 12), "")
	emptyFS:SetTextColor(S.colors.textDim.r, S.colors.textDim.g, S.colors.textDim.b)
	emptyFS:Hide()
	pcall(view.SetClipsChildren, view, true)
	content = CreateFrame("Frame", nil, view)
	content:SetPoint("TOPLEFT", view, "TOPLEFT", 0, 0)
	view:EnableMouseWheel(true)
	view:SetScript("OnMouseWheel", function(_, delta)
		SetScroll(scroll - delta * 40)
	end)
	bar = frame:CreateTexture(nil, "OVERLAY")
	bar:SetColorTexture(0.13, 0.16, 0.22, 0.9)
	thumb = frame:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(0.92, 0.68, 0.20, 0.95)
	bar:Hide()
	thumb:Hide()

	S.Movers.Register(frame, "questtracker", L["Quest tracker"])
end

-- choice ---------------------------------------------------------------------------
local function AskTrackerChoice()
	S.Dialog({
		text = L["Questie is on"] .. "\n\n" .. L["Which quest tracker?"] .. "\n"
			.. L["You can change it later on the Quests options page."],
		okText = L["SentiUI tracker (works with Questie)"],
		cancelText = L["Questie's tracker"],
		onAccept = function() Core.SetMode("sentiui") end,
		-- the cancel button is the Questie pick, not a dismissal
		onCancel = function() Core.SetMode("questie") end,
	})
end

local function MaybeAsk()
	if db.questieAsked or not ns.Questie.Loaded() then return end
	if InCombatLockdown() then
		S.RunOutOfCombat(MaybeAsk)
		return
	end
	db.questieAsked = true
	AskTrackerChoice()
end

-- mode ---------------------------------------------------------------------------
function Core.SetMode(mode)
	if not db then return end
	db.tracker = mode
	if mode == "sentiui" then
		S.SafeCall("questie", function() ns.Questie.Run(true) end)
		Core.Refresh()
	elseif mode == "questie" then
		S.SafeCall("questie", function() ns.Questie.Run(false) end)
		if frame and not InCombatLockdown() then frame:Hide() end
		S.Options.AskReload()
	elseif mode == "blizzard" then
		S.SafeCall("questie", function() ns.Questie.Run(false) end)
		if frame and not InCombatLockdown() then frame:Hide() end
		S.Options.AskReload()
	end
end

function Core.Enable(mod)
	db = mod.db
	Core.db = db
	db.collapsed = db.collapsed or {}
	ns.Questie.SetDb(db)
	ns.Nav.SetDb(db)
	ns.Nav.Apply()
	ns.Progress.SetDb(db)
	ns.Progress.Apply()
	ns.AutoQuest.SetDb(db)
	ns.AutoQuest.Apply()
	S.RegisterEvent("UI_INFO_MESSAGE", ns.Progress.OnInfo)
	S.RegisterEvent("QUEST_ACCEPTED", ns.Progress.OnAccepted)
	S.RegisterEvent("QUEST_TURNED_IN", ns.Progress.OnTurnedIn)
	-- saved-vars safety for the choice flag name
	if db.questieAsked == nil and db.tracker ~= "sentiui" then db.questieAsked = true end

	-- the tracker frame and the row pool are built out of combat: frames
	-- created during lockdown are born protected and every Show/SetPoint
	-- on them fires ADDON_ACTION_FORBIDDEN
	local function BuildAndWarm()
		BuildFrame()
		for i = 1, POOL_WARM do GetRow(i) end
		Core.Refresh()
	end
	if InCombatLockdown() then S.RunOutOfCombat(BuildAndWarm) else BuildAndWarm() end

	-- quest events are not protected on this client; a slow ticker covers
	-- anything the events miss
	for _, ev in ipairs({ "QUEST_WATCH_LIST_CHANGED", "QUEST_LOG_UPDATE",
		"QUEST_ACCEPTED", "QUEST_REMOVED", "ZONE_CHANGED_NEW_AREA",
		"PLAYER_ENTERING_WORLD" }) do
		S.RegisterEvent(ev, Schedule)
	end
	S.RegisterEvent("PLAYER_REGEN_DISABLED", function()
		if db.hideInCombat and frame then frame:SetAlpha(0) end
	end)
	S.RegisterEvent("PLAYER_REGEN_ENABLED", function()
		if frame then frame:SetAlpha(1) end
		if dirty then dirty = nil Core.Refresh() end
	end)
	C_Timer.NewTicker(2, Schedule)

	-- Questie's db loads with AceDB, maybe after us
	S.SafeCall("questie", function()
		if not ns.Questie.Run(db.tracker == "sentiui") then
			ns.Questie.Retry(db.tracker == "sentiui", ns.Questie.TRIES)
		end
	end)

	C_Timer.After(3, function() S.SafeCall("questie choice", MaybeAsk) end)
	Core.Refresh()
end

function Core.SettingChanged(mod, path)
	if not db then return end
	if path == "tracker" then
		Core.SetMode(db.tracker)
	elseif path == "width" or path == "fontSize" or path == "spacing"
		or path == "questLevels" or path == "hideInCombat"
		or path == "filter" or path == "maxHeight" or path == "fixedHeight" then
		Core.Refresh()
	elseif path == "nav" then
		ns.Nav.Apply()
	elseif path == "progress" or path == "shareProgress" then
		ns.Progress.Apply()
	end
end
