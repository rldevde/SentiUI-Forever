-- SentiUI data bars: an experience bar (rested + pending quest XP segments,
-- LEVEL UP marker, XP/hour tooltip) and a watched-faction reputation bar in
-- standing color. Both dock onto the chat panels by default and are movers.
local _, ns = ...
local S = SentiUI
local L = ns.L
local IsSecret = S.IsSecret

local _G = _G
local format, floor, min, max = string.format, math.floor, math.min, math.max
local ceil = math.ceil

local BLANK = "Interface\\Buttons\\WHITE8X8"
local ACCENT = S.colors.accent
-- palette follows the gold accent family, not the bright UI blue -
-- the saturated blue/teal/green fills clashed with the dark + gold look
local XP_COLOR = { r = 0.92, g = 0.62, b = 0.18 }
local RESTED_COLOR = { r = 0.45, g = 0.35, b = 0.90, a = 0.45 }
local QUEST_COLOR = { r = 0.40, g = 0.80, b = 0.35, a = 0.50 }

local Core = {}
ns.Core = Core
local db
Core.bars = {}

local function IsVert()
	return db and db.orientation == "VERTICAL"
end

-- eased fill like the nameplate health bars; snapped when smoothBars is off
local INTERP = Enum and Enum.StatusBarInterpolation
	and Enum.StatusBarInterpolation.ExponentialEaseOut or nil
local function SetSmooth(sb, cur, mx)
	if INTERP and db.smoothBars ~= false then
		local ok = pcall(sb.SetMinMaxValues, sb, 0, mx, INTERP)
		if ok and pcall(sb.SetValue, sb, cur, INTERP) then return end
	end
	sb:SetMinMaxValues(0, mx)
	sb:SetValue(cur)
end

-- "+N" gain numbers pop off the leading edge of the fill and rise while
-- they fade; rapid gains pool into one sum instead of a string spam
local function Gain(bar, amount, color)
	if not (bar.fly and amount and amount > 0) then return end
	bar.flySum = (bar.flySum or 0) + amount
	bar.flyT = 0
	bar.flyColor = color or XP_COLOR
	bar.fly:SetText("+" .. Abbrev(bar.flySum))
	bar.fly:SetTextColor(bar.flyColor.r, bar.flyColor.g, bar.flyColor.b)
	bar.fly:SetAlpha(1)
	bar.fly:Show()
end

local function MaxLevel()
	return (GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion())
		or (GetMaxPlayerLevel and GetMaxPlayerLevel()) or MAX_PLAYER_LEVEL or 60
end

local function Abbrev(n)
	if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
	if n >= 1e6 then return format("%.1fM", n / 1e6) end
	if n >= 1e3 then return format("%.1fk", n / 1e3) end
	return tostring(floor(n))
end

local function FormatText(mode, cur, mx, extra)
	if mode == "NONE" or mx <= 0 then return "" end
	local pct = cur / mx * 100
	if mode == "PERCENT" then return format("%.1f%%", pct) .. (extra or "")
	elseif mode == "CURMAX" then return Abbrev(cur) .. " / " .. Abbrev(mx) .. (extra or "")
	elseif mode == "CURPERC" then return format("%s - %.1f%%", Abbrev(cur), pct) .. (extra or "")
	elseif mode == "REMAINING" then return Abbrev(mx - cur) .. (extra or "")
	elseif mode == "CURVALUE" then return Abbrev(cur) .. (extra or "") end
	return format("%.1f%%", pct) .. (extra or "")
end

-- pending quest XP: XP waiting in quests that are complete but not turned in
local questScan
local function PendingQuestXP()
	if questScan then return 0, 0 end
	questScan = true
	local total, count = 0, 0
	local n = (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries())
		or (GetNumQuestLogEntries and GetNumQuestLogEntries()) or 0
	for i = 1, n do
		local qid = C_QuestLog and C_QuestLog.GetQuestIDForLogIndex and C_QuestLog.GetQuestIDForLogIndex(i)
		if qid then
			local ok, done = pcall(function()
				return (C_QuestLog.IsComplete and C_QuestLog.IsComplete(qid))
					or (IsQuestComplete and IsQuestComplete(qid))
			end)
			if ok and (done == true or done == 1) then
				local xp = (C_QuestLog.GetQuestLogRewardXP and C_QuestLog.GetQuestLogRewardXP(qid))
					or (C_QuestInfo and C_QuestInfo.GetQuestRewardXP and C_QuestInfo.GetQuestRewardXP(qid))
				if xp and not IsSecret(xp) and type(xp) == "number" and xp > 0 then
					total = total + xp
					count = count + 1
				end
			end
		end
	end
	questScan = false
	return total, count
end

-- rolling XP rate (last 10 minutes) for the XP/hour + time-to-level tooltip
local xpLog, lastXP = {}, nil
local WINDOW = 600
local function XpPerHour()
	local now = GetTime()
	local xp, firstT = 0, nil
	for i = #xpLog, 1, -1 do
		local e = xpLog[i]
		if e.t < now - WINDOW then break end
		xp, firstT = xp + e.a, e.t
	end
	if xp <= 0 or not firstT then return end
	local span = max(60, now - firstT)
	return floor(xp / span * 3600 + 0.5)
end

-- the fill gets a subtle left-to-right gradient; SetStatusBarColor is the
-- fallback on clients without texture gradients
local function Fill(bar, r, g, b, a)
	bar:SetStatusBarColor(r, g, b, a or 1)
	local tex = bar:GetStatusBarTexture()
	if tex and tex.SetGradient and CreateColor then
		pcall(tex.SetGradient, tex, IsVert() and "VERTICAL" or "HORIZONTAL",
			CreateColor(r * 0.72, g * 0.72, b * 0.72, a or 1), CreateColor(r, g, b, a or 1))
	end
end

-- bars -----------------------------------------------------------------------
local function DefaultAnchor(key, bar)
	bar:ClearAllPoints()
	if IsVert() then
		-- vertical bars can't stretch across the chat panels; park them side
		-- by side at the screen edge (movers relocate them anyway)
		if key ~= "xp" and Core.bars.xp then
			bar:SetPoint("BOTTOMLEFT", Core.bars.xp, "BOTTOMRIGHT", 4, 0)
		else
			bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 6, 250)
		end
		return
	end
	if key == "xp" then
		local p = _G.SentiUILeftChatPanel
		if p then
			-- flush on the panel's top edge, width follows the panel
			bar:SetPoint("BOTTOMLEFT", p, "TOPLEFT", 0, 0)
			bar:SetPoint("BOTTOMRIGHT", p, "TOPRIGHT", 0, 0)
		else
			bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 6, 250)
			bar:SetWidth(db.width)
		end
	else
		local rp = _G.SentiUIRightChatPanel
		if rp and rp:IsShown() then
			bar:SetPoint("BOTTOMLEFT", rp, "TOPLEFT", 0, 0)
			bar:SetPoint("BOTTOMRIGHT", rp, "TOPRIGHT", 0, 0)
		else
			local xp = Core.bars.xp
			if xp then bar:SetPoint("BOTTOMLEFT", xp, "TOPLEFT", 0, 2)
			else
				bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 6, 250)
				bar:SetWidth(db.width)
			end
		end
	end
end

local function MakeBar(key, label)
	local vert = IsVert()
	local f = CreateFrame("Frame", "SentiUI" .. key .. "Bar", UIParent, "BackdropTemplate")
	-- "height" stays the bar's thickness in both orientations
	f:SetSize(vert and db.height or db.width, vert and db.width or db.height)
	f:SetFrameStrata("LOW")
	f:EnableMouse(true)
	S.Template(f, "inset")

	-- draw order: quest (back) -> rested -> main fill (front)
	local orient = vert and "VERTICAL" or "HORIZONTAL"
	local quest = CreateFrame("StatusBar", nil, f)
	quest:SetPoint("TOPLEFT", 1, -1)
	quest:SetPoint("BOTTOMRIGHT", -1, 1)
	quest:SetStatusBarTexture(BLANK)
	quest:SetFrameLevel(f:GetFrameLevel() + 1)
	pcall(quest.SetOrientation, quest, orient)

	local rested = CreateFrame("StatusBar", nil, f)
	rested:SetPoint("TOPLEFT", 1, -1)
	rested:SetPoint("BOTTOMRIGHT", -1, 1)
	rested:SetStatusBarTexture(BLANK)
	rested:SetFrameLevel(f:GetFrameLevel() + 2)
	pcall(rested.SetOrientation, rested, orient)

	local main = CreateFrame("StatusBar", nil, f)
	main:SetPoint("TOPLEFT", 1, -1)
	main:SetPoint("BOTTOMRIGHT", -1, 1)
	main:SetStatusBarTexture(BLANK)
	main:SetFrameLevel(f:GetFrameLevel() + 3)
	main:SetMinMaxValues(0, 1)
	pcall(main.SetOrientation, main, orient)

	-- the text sits on the topmost bar so the fill cannot cover it
	local text = S.Font(main, max(8, min(12, db.height - 2)), nil, "OUTLINE")
	text:SetPoint("CENTER", f, "CENTER")

	-- the gain flytext rides the fill's leading edge while it rises and
	-- fades; anchored per tick, so it tracks an easing fill too
	local fly = S.Font(main, max(8, min(12, db.height)), nil, "OUTLINE")
	fly:Hide()
	f.fly = fly
	f:SetScript("OnUpdate", function(_, dt)
		if not f.flyT then return end
		f.flyT = f.flyT + (dt or 0.016)
		local t, dur = f.flyT, 1.3
		if t >= dur then
			fly:Hide()
			f.flyT, f.flySum = nil, 0
			return
		end
		fly:SetAlpha(t < 0.7 and 1 or max(0, (dur - t) / 0.6))
		fly:ClearAllPoints()
		local tex = main:GetStatusBarTexture()
		if IsVert() then
			fly:SetPoint("BOTTOM", tex, "TOP", 0, 4 + t * 16)
		else
			fly:SetPoint("BOTTOMLEFT", tex, "TOPRIGHT", 4, 4 + t * 16)
		end
	end)

	-- SentiUI signature: accent hairline across the top edge + a spark at the
	-- leading edge of the fill
	local line = S.Line(f, ACCENT)
	-- flush full width: the gold edge IS the bar's top edge, not a shorter
	-- strip inside it - the 5px inset read as a shrunken golden section
	line:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	line:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
	local spark = main:CreateTexture(nil, "OVERLAY")
	spark:SetTexture(BLANK)
	spark:SetVertexColor(1, 1, 1, 0.85)
	if vert then
		spark:SetHeight(1)
		spark:SetPoint("LEFT", main:GetStatusBarTexture(), "TOPLEFT")
		spark:SetPoint("RIGHT", main:GetStatusBarTexture(), "TOPRIGHT")
	else
		spark:SetWidth(1)
		spark:SetPoint("TOP", main:GetStatusBarTexture(), "TOPRIGHT")
		spark:SetPoint("BOTTOM", main:GetStatusBarTexture(), "BOTTOMRIGHT")
	end

	-- dark-glass gloss across the fill area, matching the unit frame /
	-- castbar look: a soft top highlight inset past the border
	local gloss = f:CreateTexture(nil, "ARTWORK")
	gloss:SetPoint("TOPLEFT", 1, -1)
	gloss:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -1, -math.max(3, db.height * 0.45))
	gloss:SetColorTexture(1, 1, 1, 0.10)

	f.main, f.rested, f.quest, f.text, f.spark = main, rested, quest, text, spark
	f.key = key

	f:SetScript("OnEnter", function(b)
		if db.mouseover then b:SetAlpha(1) end
		if Core["Tooltip_" .. key] then S.SafeCall("databars:tip", Core["Tooltip_" .. key], b) end
	end)
	f:SetScript("OnLeave", function(b)
		if db.mouseover then b:SetAlpha(0) end
		GameTooltip:Hide()
	end)

	DefaultAnchor(key, f)
	S.Movers.Register(f, "databar." .. key, label)
	Core.bars[key] = f
	return f
end

-- experience -----------------------------------------------------------------
function Core.UpdateXP()
	local bar = Core.bars.xp
	if not bar then return end
	local atMax = (UnitLevel("player") or 0) >= MaxLevel() or (IsXPUserDisabled and IsXPUserDisabled())
	if not db.xp.enable or (db.xp.hideAtMaxLevel and atMax) then bar:Hide() return end
	bar:Show()
	local cur, mx = (UnitXP("player") or 0), max(1, UnitXPMax("player") or 1)
	if IsSecret(cur) or IsSecret(mx) then return end
	local rested = (GetXPExhaustion and GetXPExhaustion()) or 0
	if IsSecret(rested) then rested = 0 end
	SetSmooth(bar.main, cur, mx)
	Fill(bar.main, XP_COLOR.r, XP_COLOR.g, XP_COLOR.b)
	bar.spark:SetShown(cur > 0)
	-- "+N XP" pop where the fill lands; skipped on level-up (mx changes)
	local last = bar.lastXP
	if last and last.mx == mx and cur > last.cur and db.gainText ~= false then
		Gain(bar, cur - last.cur, XP_COLOR)
	end
	bar.lastXP = { cur = cur, mx = mx }
	if db.xp.showRested and rested > 0 then
		bar.rested:SetMinMaxValues(0, mx)
		bar.rested:SetValue(min(mx, cur + rested))
		Fill(bar.rested, RESTED_COLOR.r, RESTED_COLOR.g, RESTED_COLOR.b, RESTED_COLOR.a)
		bar.rested:Show()
	else
		bar.rested:Hide()
	end
	local qxp = db.xp.showQuestXP and PendingQuestXP() or 0
	if qxp > 0 then
		bar.quest:SetMinMaxValues(0, mx)
		bar.quest:SetValue(min(mx, cur + rested + qxp))
		Fill(bar.quest, QUEST_COLOR.r, QUEST_COLOR.g, QUEST_COLOR.b, QUEST_COLOR.a)
		bar.quest:Show()
	else
		bar.quest:Hide()
	end
	local suffix = format(" - |cffdddddd%s|r %s", Abbrev(mx - cur), L["left"])
	if rested > 0 then suffix = suffix .. format(" |cff9ecbff(R %.0f%%)|r", rested / mx * 100) end
	if qxp > 0 then
		suffix = suffix .. format(" |cff8aff80(+%s %s)|r", Abbrev(qxp), L["quest XP"])
		if cur + rested + qxp >= mx then
			suffix = suffix .. " |cffffd100» " .. L["LEVEL UP!"] .. "|r"
		end
	end
	bar.text:SetText(FormatText(db.textMode, cur, mx, suffix))
end

function Core.Tooltip_xp(bar)
	local cur, mx = (UnitXP("player") or 0), max(1, UnitXPMax("player") or 1)
	if IsSecret(cur) or IsSecret(mx) then return end
	local rested = (GetXPExhaustion and GetXPExhaustion()) or 0
	if IsSecret(rested) then rested = 0 end
	GameTooltip:SetOwner(bar, "ANCHOR_TOP", 0, 4)
	GameTooltip:AddLine(L["Experience"], ACCENT.r, ACCENT.g, ACCENT.b)
	GameTooltip:AddDoubleLine(LEVEL, UnitLevel("player"), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(L["XP"], format("%s / %s (%.1f%%)", Abbrev(cur), Abbrev(mx), cur / mx * 100), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(L["Remaining"], format("%s (%.1f%%)", Abbrev(mx - cur), (mx - cur) / mx * 100), 1, 1, 1, 1, 1, 1)
	if rested > 0 then
		GameTooltip:AddDoubleLine(L["Rested"], format("%s (%.1f%%)", Abbrev(rested), rested / mx * 100), 0.6, 0.8, 1, 1, 1, 1)
	end
	if db.xp.trackRate then
		local xph = XpPerHour()
		if xph and xph > 0 then
			GameTooltip:AddDoubleLine(L["XP per hour"], Abbrev(xph) .. "/h", 0.6, 0.85, 1, 1, 1, 1)
			local hrs = (mx - cur) / xph
			local t = hrs >= 1 and format("%.1fh", hrs) or format("%dm", floor(hrs * 60 + 0.5))
			GameTooltip:AddDoubleLine(L["Time to level"], t, 0.6, 0.85, 1, 1, 1, 1)
		end
	end
	local qxp, qcount = PendingQuestXP()
	if qxp > 0 then
		GameTooltip:AddDoubleLine(L["Pending quest XP"], format("%s (%d %s)", Abbrev(qxp), qcount, L["quests"]), 0.4, 0.9, 0.4, 1, 1, 1)
		if cur + qxp >= mx then
			GameTooltip:AddDoubleLine(L["Turn-in result"], "|cff8aff80" .. L["LEVEL UP!"] .. "|r", 0.4, 0.9, 0.4)
		end
	end
	GameTooltip:Show()
end

-- reputation -----------------------------------------------------------------
local function GetWatched()
	if C_Reputation and C_Reputation.GetWatchedFactionData then
		local data = C_Reputation.GetWatchedFactionData()
		if not data or not data.name then return end
		local name, standing = data.name, data.reaction
		local minV, maxV, value = data.currentReactionThreshold, data.nextReactionThreshold, data.currentStanding
		local factionID = data.factionID
		local label = _G["FACTION_STANDING_LABEL" .. (standing or 1)]
		if factionID and C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
			local friend = C_GossipInfo.GetFriendshipReputation(factionID)
			if friend and friend.friendshipFactionID and friend.friendshipFactionID > 0 then
				label = friend.reaction
				minV = friend.reactionThreshold or 0
				maxV = friend.nextThreshold or friend.standing or 1
				value = friend.standing or 0
			end
		end
		if factionID and C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(factionID)
			and C_MajorFactions and C_MajorFactions.GetMajorFactionData then
			local info = C_MajorFactions.GetMajorFactionData(factionID)
			if info then
				minV, maxV, value = 0, info.renownLevelThreshold or 1, info.renownReputationEarned or 0
				label = (RENOWN_LEVEL_LABEL or "Renown %d"):format(info.renownLevel or 0)
				standing = 10
			end
		end
		if factionID and C_Reputation.IsFactionParagon and C_Reputation.IsFactionParagon(factionID)
			and C_Reputation.GetFactionParagonInfo then
			local cur, threshold = C_Reputation.GetFactionParagonInfo(factionID)
			if cur and threshold then
				minV, maxV, value = 0, threshold, cur % threshold
				label = L["Paragon"]
				standing = 9
			end
		end
		return name, standing, minV, maxV, value, label
	end
	if not GetWatchedFactionInfo then return end
	local name, standing, minV, maxV, value = GetWatchedFactionInfo()
	if not name then return end
	return name, standing, minV, maxV, value, _G["FACTION_STANDING_LABEL" .. standing]
end

function Core.UpdateRep()
	local bar = Core.bars.rep
	if not bar then return end
	local name, standing, minV, maxV, value, label = GetWatched()
	if not db.rep.enable or not name then bar:Hide() return end
	bar:Show()
	local cur, mx = (value or 0) - (minV or 0), max(1, (maxV or 1) - (minV or 0))
	SetSmooth(bar.main, cur, mx)
	local c = (standing == 9 and { r = 0, g = 0.5, b = 0.9 })
		or (standing == 10 and { r = 0, g = 0.75, b = 0.95 })
		or (FACTION_BAR_COLORS and FACTION_BAR_COLORS[standing])
		or { r = 0, g = 0.6, b = 0.1 }
	Fill(bar.main, c.r, c.g, c.b)
	bar.spark:SetShown(cur > 0)
	local last = bar.lastRep
	if last and last.mx == mx and cur > last.cur and db.gainText ~= false then
		Gain(bar, cur - last.cur, c)
	end
	bar.lastRep = { cur = cur, mx = mx }
	bar.quest:Hide()
	bar.rested:Hide()
	bar.text:SetText(name .. ": " .. FormatText(db.textMode, cur, mx) .. " [" .. (label or "") .. "]")
end

function Core.Tooltip_rep(bar)
	local name, standing, minV, maxV, value, label = GetWatched()
	if not name then return end
	GameTooltip:SetOwner(bar, "ANCHOR_TOP", 0, 4)
	GameTooltip:AddLine(name, ACCENT.r, ACCENT.g, ACCENT.b)
	GameTooltip:AddDoubleLine(L["Standing"], label or "", 1, 1, 1, 1, 1, 1)
	GameTooltip:AddDoubleLine(REPUTATION, format("%s / %s", Abbrev((value or 0) - (minV or 0)), Abbrev((maxV or 1) - (minV or 0))), 1, 1, 1, 1, 1, 1)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(L["Click: open reputation"], 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

-- enable / settings ------------------------------------------------------------
function Core.Update()
	for _, bar in pairs(Core.bars) do
		bar:SetHeight(db.height)
		bar:SetAlpha(db.mouseover and 0 or 1)
		bar.text:SetShown(db.textMode ~= "NONE" and db.height >= 10)
	end
	Core.UpdateXP()
	Core.UpdateRep()
end

function Core.SettingChanged(mod, path)
	if not Core.enabled then return end
	Core.Update()
end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db

	MakeBar("xp", L["Experience Bar"])
	MakeBar("rep", L["Reputation Bar"])
	Core.bars.rep:SetScript("OnMouseUp", function()
		if ToggleCharacter then pcall(ToggleCharacter, "ReputationFrame") end
	end)
	Core.Update()

	-- re-dock once the chat panels exist (module load order is alphabetical,
	-- so they should already be there - this is a belt-and-braces retry)
	local function Redock()
		local positions = S.DB.Positions()
		for key, bar in pairs(Core.bars) do
			if not positions["databar." .. key] then
				S.SafeCall("databars:redock", DefaultAnchor, key, bar)
			end
		end
	end
	C_Timer.After(1, Redock)
	S.RegisterEvent("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(0.5, Redock)
		Core.Update()
	end)

	for _, e in ipairs({ "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION",
		"DISABLE_XP_GAIN", "ENABLE_XP_GAIN", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN" }) do
		S.RegisterEvent(e, Core.UpdateXP)
	end
	S.RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN", function()
		local now = GetTime()
		local cur = UnitXP("player")
		if lastXP and not IsSecret(cur) and cur > lastXP then
			xpLog[#xpLog + 1] = { t = now, a = cur - lastXP }
		end
		lastXP = cur
	end)
	for _, e in ipairs({ "UPDATE_FACTION", "COMBAT_TEXT_UPDATE", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" }) do
		S.RegisterEvent(e, Core.UpdateRep)
	end
end
