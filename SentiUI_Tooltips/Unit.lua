-- Unit tooltip: class-colored player name, reaction-colored NPC name, a
-- border and top edge in the same color, the slim restyled health bar,
-- difficulty-colored level, class-colored class name, guild rank and a
-- "my guild" mark right on the guild line, faction + status + realm tags
-- on the name line, elite/rare/boss badge, group role, specialization,
-- target-of-target and a TipTac-style item level (live for yourself,
-- throttled inspect + gear-scan fallback for other players).
--
-- Every line we add goes through UpsertLine/AddLineOnce: the unit post-call
-- fires more than once per tooltip show and plain AddLine stacked the same
-- line over and over (that's how "Guild member" ended up twice).
local _, ns = ...
local S = SentiUI
local L = ns.L

local Unit = {}
ns.Unit = Unit

local BLANK = S.media.blank

local function plain(v)
	if S.IsSecret(v) then return nil end
	return v
end

local function have(v)
	return (issecretvalue and issecretvalue(v)) or v ~= nil
end

local function hexOf(c, fallback)
	if type(c) == "table" and type(c.r) == "number" then
		return S.Hex(c)
	end
	return fallback
end

local function escPat(s)
	return (s:gsub("(%W)", "%%%1"))
end

-- tooltip line helpers ----------------------------------------------------
local function Line(tip, i)
	local name = tip.GetName and tip:GetName()
	if type(name) ~= "string" then return nil end
	return _G[name .. "TextLeft" .. i]
end

local function LineText(fs)
	if type(fs) ~= "table" or not fs.GetText then return nil end
	local t = fs:GetText()
	if type(t) ~= "string" or S.IsSecret(t) then return nil end
	return t
end

-- find a line that already carries our label ("Item Level:") and update it
-- in place; add it at the bottom when missing. Idempotent across the
-- repeated post-calls one tooltip show triggers.
local function UpsertLine(tip, label, text, r, g, b)
	for i = 1, tip:NumLines() or 0 do
		local f = Line(tip, i)
		local t = LineText(f)
		if t and t:sub(1, #label) == label then
			if t ~= text then pcall(f.SetText, f, text) end
			return f
		end
	end
	tip:AddLine(text, r, g, b)
end

-- add a line only when that exact text isn't already there
local function AddLineOnce(tip, text, r, g, b)
	for i = 1, tip:NumLines() or 0 do
		if LineText(Line(tip, i)) == text then return end
	end
	tip:AddLine(text, r, g, b)
end

-- colors ---------------------------------------------------------------------
local CLASS_FALLBACK = {
	WARRIOR = { 0.78, 0.61, 0.43 }, PALADIN = { 0.96, 0.55, 0.73 },
	HUNTER = { 0.67, 0.83, 0.45 }, ROGUE = { 1.00, 0.96, 0.41 },
	PRIEST = { 1.00, 1.00, 1.00 }, DEATHKNIGHT = { 0.77, 0.12, 0.23 },
	SHAMAN = { 0.00, 0.44, 0.87 }, MAGE = { 0.25, 0.78, 0.92 },
	WARLOCK = { 0.53, 0.53, 0.93 }, MONK = { 0.00, 1.00, 0.59 },
	DRUID = { 1.00, 0.49, 0.04 }, DEMONHUNTER = { 0.64, 0.19, 0.79 },
	EVOKER = { 0.20, 0.58, 0.50 },
}
local REACTION_FALLBACK = {
	[1] = { 0.79, 0.15, 0.12 }, [2] = { 0.79, 0.15, 0.12 },
	[3] = { 0.85, 0.30, 0.12 }, [4] = { 0.78, 0.65, 0.12 },
	[5] = { 0.30, 0.85, 0.28 }, [6] = { 0.30, 0.85, 0.28 },
	[7] = { 0.30, 0.85, 0.28 }, [8] = { 0.30, 0.85, 0.28 },
}
local FACTION_FALLBACK = {
	Alliance = { 0.29, 0.33, 0.91 },
	Horde = { 0.90, 0.05, 0.07 },
}

-- class token: the classFile return of UnitClass can read secret on
-- this client while the numeric classID (3rd return) stays plain -
-- C_CreatureInfo.GetClassInfo(classID).classFile turns it back into
-- the token. GetPlayerInfoByGUID is the secret-proof path for hidden
-- classes.
local function ClassToken(unit)
	local ok, _, cls, classID = pcall(UnitClass, unit)
	cls = ok and plain(cls)
	if type(cls) == "string" then return cls end
	classID = ok and plain(classID)
	if type(classID) == "number" and C_CreatureInfo and C_CreatureInfo.GetClassInfo then
		local okC, info = pcall(C_CreatureInfo.GetClassInfo, classID)
		info = okC and plain(info)
		local okF, file = pcall(function() return info and info.classFile end)
		file = okF and plain(file)
		if type(file) == "string" then return file end
	end
	local okG, guid = pcall(UnitGUID, unit)
	guid = okG and plain(guid)
	if type(guid) ~= "string" or guid:sub(1, 7) ~= "Player-" then return nil end
	local okI, _, ecls = pcall(GetPlayerInfoByGUID, guid)
	ecls = okI and plain(ecls)
	return type(ecls) == "string" and ecls or nil
end

local function TokenColor(cls)
	local c
	local ok, live = pcall(function()
		return (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS or {})[cls]
	end)
	if ok and type(live) == "table" and not S.IsSecretTable(live) then
		c = live
	end
	c = c or CLASS_FALLBACK[cls]
	if type(c) == "table" then
		if c.r then return c.r, c.g, c.b end
		return c[1], c[2], c[3]
	end
end

function Unit.ClassColor(unit)
	local cls = ClassToken(unit)
	if not cls then return nil end
	return TokenColor(cls)
end

-- localized class name -> token map (the tooltip's own level line tells
-- the class even when every unit function reads secret)
local CLASS_NAMES
local function EnsureClassNames()
	if CLASS_NAMES then return end
	CLASS_NAMES = {}
	for _, t in ipairs({ LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE }) do
		if type(t) == "table" and not S.IsSecretTable(t) then
			for tok, n in pairs(t) do
				if type(n) == "string" and not S.IsSecret(n) then
					CLASS_NAMES[n] = tok
				end
			end
		end
	end
end

local function ClassFromTip(tip)
	EnsureClassNames()
	for i = 2, math.min(6, tip:NumLines() or 0) do
		local t = LineText(Line(tip, i))
		if t then
			for name, tok in pairs(CLASS_NAMES) do
				if t:find(name, 1, true) then return tok end
			end
		end
	end
end

-- when the client hides the class behind a secret, the engine still
-- resolves it: C_ClassColor.GetClassColor accepts the secret token and
-- returns secret rgb numbers that color setters take natively - callers
-- must never boolean-test or format them
function Unit.SecretColor(unit)
	if not (C_ClassColor and C_ClassColor.GetClassColor and UnitClassBase) then return nil end
	local ok, name, file, id = pcall(UnitClassBase, unit)
	if not ok then return nil end
	for i = 1, 3 do
		local tok = select(i, file, id, name)
		local got, c = pcall(C_ClassColor.GetClassColor, tok)
		if got and type(c) == "table" then
			local okC, r, g, b = pcall(function() return c.r, c.g, c.b end)
			if okC and ((issecretvalue and issecretvalue(r)) or r ~= nil) then
				return r, g, b
			end
		end
	end
end

-- player-ness survives secret booleans: UnitIsPlayer can read secret on
-- this client, the GUID prefix is the fallback truth. nil = can't tell
local function IsPlayerUnit(unit)
	local ok, isP = pcall(UnitIsPlayer, unit)
	isP = ok and plain(isP)
	if isP == nil then
		local okg, guid = pcall(UnitGUID, unit)
		guid = okg and plain(guid)
		if type(guid) == "string" then isP = guid:sub(1, 7) == "Player-" end
	end
	return isP
end

local function FactionColor(eng)
	local g = eng == "Horde" and _G.PLAYER_FACTION_COLOR_HORDE
		or eng == "Alliance" and _G.PLAYER_FACTION_COLOR_ALLIANCE
	if type(g) == "table" and not S.IsSecretTable(g) then
		local ok, fr, fg, fb = pcall(function() return g.r, g.g, g.b end)
		if ok and type(fr) == "number" then return fr, fg, fb end
	end
	local c = FACTION_FALLBACK[eng]
	if c then return c[1], c[2], c[3] end
end

-- "Horde"/"Alliance" or nil. UnitFactionGroup is unreliable on this client
-- (single return, sometimes localized only), so every return value is
-- tested against the english tag and the localized globals, with the
-- race's faction group as the last fallback.
local function UnitFaction(unit)
	if type(UnitFactionGroup) == "function" then
		local ok, a, b = pcall(UnitFactionGroup, unit)
		a, b = ok and plain(a), ok and plain(b)
		for _, v in ipairs({ a, b }) do
			if v == "Horde" or v == "Alliance" then return v end
		end
		for _, v in ipairs({ a, b }) do
			if type(v) == "string" then
				if v == FACTION_HORDE or v == "Horde" then return "Horde" end
				if v == FACTION_ALLIANCE or v == "Alliance"
					or v == "Allianz" then
					return "Alliance"
				end
			end
		end
	end
	local ok, _, _, raceID = pcall(UnitRace, unit)
	raceID = ok and plain(raceID)
	if type(raceID) == "number" and C_CreatureInfo
		and C_CreatureInfo.GetFactionInfo then
		local ok2, info = pcall(C_CreatureInfo.GetFactionInfo, raceID)
		info = ok2 and plain(info)
		if type(info) == "table" then
			local tag = plain(info.groupTag)
			if tag == "Horde" or tag == "Alliance" then return tag end
		end
	end
end

function Unit.ReactionColor(unit)
	local ok, r = pcall(UnitReaction, unit, "player")
	r = ok and plain(r)
	local c = type(r) == "number" and REACTION_FALLBACK[math.floor(r)]
		or REACTION_FALLBACK[5]
	return c[1], c[2], c[3]
end

-- returns r,g,b; the values MAY be secret numbers (engine class color) -
-- they only ever go into pcall'd color setters
local function UnitColor(tip, unit)
	local isP = IsPlayerUnit(unit)
	if isP == true then
		local r, g, b = Unit.ClassColor(unit)
		if r then return r, g, b end
	end
	if isP ~= false then
		local cls = ClassFromTip(tip)
		if cls then
			local r, g, b = TokenColor(cls)
			if r then return r, g, b end
		end
		local sr, sg, sb = Unit.SecretColor(unit)
		if (issecretvalue and issecretvalue(sr)) or sr ~= nil then
			return sr, sg, sb
		end
	end
	return Unit.ReactionColor(unit)
end

-- TipTac-style item level -----------------------------------------------------
-- self: GetAverageItemLevel (equipped) + GetItemLevelColor for the tint.
-- others: C_PaperDollInfo.GetInspectItemLevel once INSPECT_READY data is
-- there; when that stays empty the gear is scanned slot by slot and the
-- item levels averaged over 16 slots - the Item mixin resolves upgraded
-- levels, GetDetailedItemLevelInfo is the fallback. The number is tinted
-- by the average item quality, like TipTac does.
local QCOLOR = {
	[0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 },
	[2] = { 0.12, 1.00, 0.00 }, [3] = { 0.00, 0.44, 0.87 },
	[4] = { 0.64, 0.21, 0.93 }, [5] = { 1.00, 0.50, 0.00 },
	[6] = { 0.90, 0.80, 0.50 }, [7] = { 0.90, 0.80, 0.50 },
	[8] = { 0.00, 0.80, 1.00 },
}
local function QualityRGB(q)
	local c = (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]) or QCOLOR[q]
	if type(c) == "table" and not S.IsSecretTable(c) then
		return c.r or c[1], c.g or c[2], c.b or c[3]
	end
end

local SKIP_SLOTS = {}
for _, i in ipairs({ INVSLOT_BODY, INVSLOT_TABARD, INVSLOT_RANGED, 4, 19 }) do
	if type(i) == "number" then SKIP_SLOTS[i] = true end
end

-- average equipped item level + average quality over a unit's gear
local function ScanGear(unit)
	local total, count, qsum, qn = 0, 0, 0, 0
	local first = type(INVSLOT_FIRST_EQUIPPED) == "number" and INVSLOT_FIRST_EQUIPPED or 1
	local last = type(INVSLOT_LAST_EQUIPPED) == "number" and INVSLOT_LAST_EQUIPPED or 18
	for i = first, last do
		if not SKIP_SLOTS[i] then
			local ok, link = pcall(GetInventoryItemLink, unit, i)
			link = ok and plain(link)
			if type(link) == "string" and link ~= "" then
				local ilvl, q
				-- the Item mixin knows upgraded levels that the raw link hides
				if Item and Item.CreateFromItemLink then
					local oki, it = pcall(Item.CreateFromItemLink, Item, link)
					it = oki and it
					if type(it) == "table" then
						local oke, v = pcall(function()
							if it.GetCurrentItemLevel then return it:GetCurrentItemLevel() end
						end)
						ilvl = oke and plain(v)
						local okq, qq = pcall(function()
							if it.GetItemQuality then return it:GetItemQuality() end
						end)
						q = okq and plain(qq)
					end
				end
				if type(ilvl) ~= "number" and C_Item and C_Item.GetDetailedItemLevelInfo then
					local oke, v = pcall(C_Item.GetDetailedItemLevelInfo, link)
					ilvl = oke and plain(v)
				end
				if type(q) ~= "number" and C_Item and C_Item.GetItemInfo then
					local okq, qq = pcall(function()
						return select(3, C_Item.GetItemInfo(link))
					end)
					q = okq and plain(qq)
				end
				if type(ilvl) == "number" and ilvl > 1 then
					total = total + ilvl
					count = count + 1
				end
				if type(q) == "number" then qsum, qn = qsum + q, qn + 1 end
			end
		end
	end
	if count == 0 then return nil end
	return math.floor(total / 16 + 0.5), qn > 0 and qsum / qn or nil
end

-- one call fills ilvl + spec for a unit; `deep` = inspect data may exist
local function PlayerData(unit, deep)
	local info = {}
	local okS, self_ = pcall(UnitIsUnit, unit, "player")
	self_ = okS and plain(self_)
	if self_ == true then
		if type(_G.GetAverageItemLevel) == "function" then
			local okI, overall, equipped = pcall(GetAverageItemLevel)
			if okI then info.ilvl = plain(equipped) or plain(overall) end
			if type(info.ilvl) == "number" then info.ilvl = math.floor(info.ilvl) end
		end
		if type(_G.GetItemLevelColor) == "function" then
			local okC, r, g, b = pcall(GetItemLevelColor)
			if okC and type(plain(r)) == "number" then
				info.qr, info.qg, info.qb = plain(r), plain(g), plain(b)
			end
		end
		-- own spec reads live
		if type(GetSpecialization) == "function" and type(GetSpecializationInfo) == "function" then
			local okP, idx = pcall(GetSpecialization)
			idx = okP and plain(idx)
			if type(idx) == "number" then
				local okN, _, name = pcall(GetSpecializationInfo, idx)
				name = okN and plain(name)
				if type(name) == "string" and name ~= "" then info.spec = name end
			end
		end
		if not info.ilvl then info.ilvl, info.avgq = ScanGear(unit) end
		return info
	end
	-- other players: paper-doll value first, gear scan as the tiptac fallback
	if deep and C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
		local okI, v = pcall(C_PaperDollInfo.GetInspectItemLevel, unit)
		v = okI and plain(v)
		if type(v) == "number" and v > 0 then info.ilvl = math.floor(v + 0.5) end
	end
	if deep and not info.ilvl then
		info.ilvl, info.avgq = ScanGear(unit)
	end
	-- spec via inspect (deep only - GetInspectSpecialization needs the data)
	if deep then
		local fn = (C_SpecializationInfo and C_SpecializationInfo.GetInspectSpecialization)
			or (type(_G.GetInspectSpecialization) == "function" and _G.GetInspectSpecialization)
		if fn then
			local okP, sid = pcall(fn, unit)
			sid = okP and plain(sid)
			if type(sid) == "number" and sid > 0 then
				local fni = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfoByID)
					or (type(_G.GetSpecializationInfoByID) == "function" and _G.GetSpecializationInfoByID)
				if fni then
					local okN, _, name, _, _, role = pcall(fni, sid)
					name = okN and plain(name)
					role = okN and plain(role)
					if type(name) == "string" and name ~= "" then
						info.spec = name
						info.specRole = type(role) == "string" and role or nil
					end
				end
			end
		end
	end
	return info
end

-- inspect queue (tiptac mechanics): one inspect in flight, ~2s api
-- spacing, per-guid cache with negative results, never while the game's
-- own inspect frame is open
local INSPECT_GAP, INSPECT_TTL, INSPECT_FAIL = 2, 45, 1
local iQueue, iQueued, iCache = {}, {}, {}
local iPending -- { guid =, sent = }
local iLast = 0
local iTicker

local function UnitForGUID(guid)
	if not UnitTokenFromGUID then return nil end
	local oku, u = pcall(UnitTokenFromGUID, guid)
	u = oku and plain(u)
	return type(u) == "string" and u or nil
end

local function InspectDone(guid, unit)
	local info = unit and PlayerData(unit, true) or nil
	-- empty answers only stick briefly - a player walking into inspect
	-- range should get a second try instead of waiting out the full TTL
	iCache[guid] = { info = info or {}, when = GetTime(),
		neg = not (info and next(info)) }
	pcall(ClearInspectPlayer)
	-- refresh the live tooltip when it still shows this unit; Apply is
	-- idempotent so a full rerun just fills the new lines
	local okd, data = pcall(GameTooltip.GetPrimaryTooltipData, GameTooltip)
	data = okd and plain(data)
	local okg, g = pcall(function() return data and data.guid end)
	g = okg and plain(g)
	if g == guid and GameTooltip:IsShown() then
		S.SafeCall("tips:apply", Unit.Apply, GameTooltip)
		pcall(GameTooltip.Show, GameTooltip) -- reflow for the new lines
	end
end

local function InspectDrain()
	if iPending then
		if GetTime() - iPending.sent > INSPECT_FAIL then
			-- INSPECT_READY never came: read whatever the client has anyway
			-- (the gear-scan fallback may still get an answer), else the
			-- empty info table lands in the cache as a negative result
			local g = iPending.guid
			local unit = UnitForGUID(g)
			iPending = nil
			if unit then
				InspectDone(g, unit)
			else
				iCache[g] = { info = {}, when = GetTime(), neg = true }
				pcall(ClearInspectPlayer)
			end
			InspectDrain()
		end
		return
	end
	if #iQueue == 0 or GetTime() - iLast < INSPECT_GAP then return end
	if type(NotifyInspect) ~= "function" then
		iQueue, iQueued = {}, {}
		return
	end
	if InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() then
		return
	end
	local guid = table.remove(iQueue, 1)
	iQueued[guid] = nil
	local unit = UnitForGUID(guid)
	if type(unit) ~= "string" then return InspectDrain() end
	-- gate on inspect RANGE, not CanInspect: CanInspect lies for plain
	-- hovering on this client, while a dead NotifyInspect just falls into
	-- the 1s fail path and caches negative anyway
	if type(CheckInteractDistance) == "function" then
		local okd, near = pcall(CheckInteractDistance, unit, 1)
		near = okd and plain(near)
		if near == false then return InspectDrain() end
	end
	iLast = GetTime()
	iPending = { guid = guid, sent = iLast }
	pcall(NotifyInspect, unit)
end

S.RegisterEvent("INSPECT_READY", function(_, guid)
	guid = plain(guid)
	if iPending and guid == iPending.guid then
		local unit = UnitForGUID(guid)
		iPending = nil
		InspectDone(guid, unit)
	end
	InspectDrain()
end)

-- cached player data for the tooltip, or nil + a queued inspect
local function RequestPlayerData(unit)
	local okg, guid = pcall(UnitGUID, unit)
	guid = okg and plain(guid)
	if type(guid) ~= "string" or guid:sub(1, 7) ~= "Player-" then return nil end
	local c = iCache[guid]
	if c and GetTime() - c.when < (c.neg and 8 or INSPECT_TTL) then
		return c.info
	end
	-- data another addon already pulled is free - cheap probe first, the
	-- full gear scan only runs when inspect data actually exists
	if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
		local okI, v = pcall(C_PaperDollInfo.GetInspectItemLevel, unit)
		v = okI and plain(v)
		if type(v) == "number" and v > 0 then
			local quick = PlayerData(unit, true)
			iCache[guid] = { info = quick, when = GetTime() }
			return quick
		end
	end
	-- under level 10 the game shows no ilvl anyway
	local okl, lvl = pcall(UnitLevel, unit)
	lvl = okl and plain(lvl)
	if type(lvl) == "number" and lvl > 0 and lvl < 10 then return nil end
	if type(NotifyInspect) ~= "function" then return nil end
	if not iQueued[guid] then
		iQueue[#iQueue + 1] = guid
		iQueued[guid] = true
	end
	if not iTicker then iTicker = C_Timer.NewTicker(0.4, InspectDrain) end
	return nil
end

-- health bar -----------------------------------------------------------------
local styled
function Unit.StyleBar()
	local bar = GameTooltipStatusBar
	if type(bar) ~= "table" or not bar.SetStatusBarTexture or styled then return end
	styled = true
	pcall(bar.SetStatusBarTexture, bar, BLANK)
	if bar.SetStatusBarColor then
		pcall(bar.SetStatusBarColor, bar, 0.30, 0.85, 0.28, 1)
	end
	-- dark shell behind the bar so it reads like the rest of the UI
	local sh = CreateFrame("Frame", nil, bar:GetParent(), "BackdropTemplate")
	sh:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
	sh:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
	local lvl = bar.GetFrameLevel and bar:GetFrameLevel() or 1
	sh:SetFrameLevel(math.max(0, lvl - 1))
	sh:SetBackdrop({ bgFile = BLANK, edgeFile = BLANK, edgeSize = 1 })
	sh:SetBackdropColor(0.03, 0.04, 0.06, 0.92)
	sh:SetBackdropBorderColor(0.16, 0.18, 0.25, 0.9)
	bar.__sentiShell = sh
	-- WatchShown, not OnShow/OnHide hooks: insecure scripts on the client's
	-- status bar run inside its show/hide dispatch and taint what the
	-- client does next in that pass
	S.WatchShown(bar, function() sh:Show() end, function() sh:Hide() end)
	if bar:IsShown() then sh:Show() else sh:Hide() end
end

local function Short(n)
	if type(n) ~= "number" then return "?" end
	if n >= 1000 then return string.format("%.1fk", n / 1000) end
	return math.floor(n)
end

function Unit.Bar(tip, unit)
	local bar = GameTooltipStatusBar
	if type(bar) ~= "table" then return end
	if not ns.Cfg().healthBar then
		bar:SetAlpha(0)
		if bar.__sentiShell then bar.__sentiShell:Hide() end
		return
	end
	bar:SetAlpha(1)
	pcall(bar.SetHeight, bar, ns.Cfg().barHeight or 6)
	local r, g, b = UnitColor(tip, unit)
	if have(r) then pcall(bar.SetStatusBarColor, bar, r, g, b) end
	if ns.Cfg().healthText then
		if not bar.__sentiText then
			bar.__sentiText = S.Font(bar, 9, nil, "OUTLINE")
			bar.__sentiText:SetPoint("CENTER")
		end
		local okh, cur = pcall(UnitHealth, unit)
		local okm, max = pcall(UnitHealthMax, unit)
		cur, max = okh and plain(cur), okm and plain(max)
		if type(cur) == "number" and type(max) == "number" and max > 0 then
			bar.__sentiText:SetFormattedText("%s / %s |cff8a8f98· %d%%|r",
				Short(cur), Short(max), math.floor(cur / max * 100 + 0.5))
			bar.__sentiText:Show()
		else
			bar.__sentiText:Hide()
		end
	elseif bar.__sentiText then
		bar.__sentiText:Hide()
	end
end

-- name-line tag helper: appends "|cffhex tag|r" once and remembers it on
-- the fontstring, so the name-color rebuild can re-colour the base name
-- without destroying the tag colors (fs.__sentiTags keeps them in order)
local function TagOnce(fs, tag, r, g, b)
	if not fs or not fs.SetText then return end
	local t = LineText(fs)
	if not t or t:find(tag, 1, true) then return end
	fs.__sentiTags = fs.__sentiTags or {}
	fs.__sentiTags[#fs.__sentiTags + 1] = { tag = tag, r = r, g = g, b = b }
	local hex = S.Hex({ r = r, g = g, b = b })
	pcall(fs.SetText, fs, t .. " |cff" .. hex .. tag .. "|r")
end

-- per-tooltip pass -------------------------------------------------------------
local muted = setmetatable({}, { __mode = "k" })

function Unit.Muted(tip) return muted[tip] end

function Unit.Apply(tip)
	local db = ns.Cfg()

	if db.hideInCombat and tip == GameTooltip and InCombatLockdown()
		and not (IsShiftKeyDown and IsShiftKeyDown()) then
		muted[tip] = true
		tip:SetAlpha(0)
		return
	end
	muted[tip] = nil
	tip:SetAlpha(1)

	-- unit token: GetUnit() can hand back a dead/secret token; the
	-- tooltip's data guid -> UnitTokenFromGUID is the reliable path
	local unit
	local okd, data = pcall(tip.GetPrimaryTooltipData, tip)
	data = okd and plain(data)
	local okg, guid = pcall(function() return data and data.guid end)
	guid = okg and plain(guid)
	if type(guid) == "string" and UnitTokenFromGUID then
		unit = UnitForGUID(guid)
	end
	if not unit then
		local ok, _, u = pcall(tip.GetUnit, tip)
		u = ok and plain(u)
		if type(u) == "string" then unit = u end
	end
	if not unit then return end

	local isP = IsPlayerUnit(unit)
	local r, g, b = UnitColor(tip, unit)
	local nameFS = Line(tip, 1)

	-- name line: the client's own text can embed color codes that beat
	-- SetTextColor, so the line is rebuilt - tracked tags peeled off the
	-- tail, base name wrapped in the unit color, tags re-appended with
	-- their original colors. Runs before the tag blocks below.
	if db.classColors and nameFS then
		local hex
		if type(r) == "number" then
			hex = S.Hex({ r = r, g = g, b = b })
		end
		local t = LineText(nameFS)
		if t then
			local stripped = t:gsub("|c%x+", ""):gsub("|r", "")
			local tags = nameFS.__sentiTags or {}
			local base, kept = stripped, {}
			for i = #tags, 1, -1 do
				local pat = "%s*" .. tags[i].tag:gsub("(%W)", "%%%1") .. "%s*$"
				if base:find(pat) then
					base = base:gsub(pat, "")
					kept[#kept + 1] = tags[i]
				else
					break -- a line reset ends the suffix chain
				end
			end
			-- kept came tail-first: flip back to append order and forget
			-- tags whose text disappeared (new unit on the same tip)
			local ordered = {}
			for i = #kept, 1, -1 do ordered[#ordered + 1] = kept[i] end
			nameFS.__sentiTags = ordered
			local new = base
			if hex then new = "|cff" .. hex .. base .. "|r" end
			for _, tg in ipairs(ordered) do
				new = new .. " |cff" .. S.Hex({ r = tg.r, g = tg.g, b = tg.b })
					.. tg.tag .. "|r"
			end
			if new ~= t then pcall(nameFS.SetText, nameFS, new) end
		end
		if not hex and have(r) and nameFS.SetTextColor then
			-- secret rgb from the engine color path can still go into the
			-- native setter - it just can't be formatted into text
			pcall(nameFS.SetTextColor, nameFS, r, g, b)
		end
	end
	if nameFS then
		if db.factionColors then
			local fac = UnitFaction(unit)
			if fac then
				local fr, fg, fb = FactionColor(fac)
				local disp = fac == "Horde" and (FACTION_HORDE or fac)
					or (FACTION_ALLIANCE or fac)
				if fr then TagOnce(nameFS, "[" .. disp .. "]", fr, fg, fb) end
			end
		end
		if db.showRealm then
			local okr, firstName, realm = pcall(UnitName, unit)
			firstName, realm = okr and plain(firstName), okr and plain(realm)
			if type(realm) == "string" and realm ~= "" then
				-- this client's second UnitName value is the surname, not
				-- a realm ("Raziel Lucas" + "-Lucas") - only tag it when
				-- the full name doesn't already end with it
				local okf, full = pcall(GetUnitName, unit)
				full = okf and plain(full)
				local surname = type(full) == "string"
					and full:match("(%S+)%s*$")
				if type(full) == "string" and surname ~= realm
					and realm ~= firstName then
					TagOnce(nameFS, "-" .. realm, 0.55, 0.57, 0.62)
				end
			end
		end
		if db.unitStatus then
			local ok8, afk = pcall(UnitIsAFK, unit)
			afk = ok8 and plain(afk)
			local ok9, dnd = pcall(UnitIsDND, unit)
			dnd = ok9 and plain(dnd)
			local tag = afk == true and "<AFK>" or dnd == true and "<DND>" or nil
			if tag then TagOnce(nameFS, tag, 0.55, 0.57, 0.62) end
		end
	end

	-- border + top edge tint
	if db.classBorder and have(r) then
		ns.Skin.SetBorder(tip, r, g, b)
		if db.coloredEdge then ns.Skin.SetAccent(tip, r, g, b) end
	end

	Unit.Bar(tip, unit)

	-- guild line: the name itself is recolored (own guild in accent), rank
	-- appended in its own color, "My Guild" mark in accent - everything is
	-- rebuilt from a stripped copy so repeat post-calls stay idempotent
	local guild
	do
		local ok2, g, rank = pcall(GetGuildInfo, unit)
		g, rank = ok2 and plain(g), ok2 and plain(rank)
		guild = g
		if type(g) == "string" then
			local mine
			if db.myGuild then
				local ok7, m = pcall(GetGuildInfo, "player")
				mine = ok7 and plain(m)
			end
			local acHex = S.Hex(S.colors.accent)
			local isMine = db.myGuild and type(mine) == "string" and mine == g
			local nameHex = isMine and acHex or nil
			if not nameHex and db.guildFactionColors then
				local ef = UnitFaction(unit)
				if ef then
					local fr, fg, fb = FactionColor(ef)
					if type(fr) == "number" then
						nameHex = string.format("%02x%02x%02x",
							fr * 255, fg * 255, fb * 255)
					end
				end
			end
			nameHex = nameHex or hexOf(db.guildColor, "339eff")
			local rankHex = hexOf(db.guildRankColor, "8a8f98")
			for i = 2, math.min(6, tip:NumLines() or 0) do
				local f = Line(tip, i)
				local t = LineText(f)
				if t then
					local stripped = t:gsub("|c%x+", ""):gsub("|r", "")
					-- drop our own previously appended "  · rank/mark" tails,
					-- they are rebuilt right after
					local cut = stripped:find("  ·", 1, true)
					if cut then stripped = stripped:sub(1, cut - 1) end
					if stripped:find(g, 1, true) then
						local new = stripped:gsub(escPat(g),
							"|cff" .. nameHex .. g .. "|r", 1)
						if db.guildRank and type(rank) == "string" and rank ~= "" then
							new = new .. "  |cff" .. rankHex .. "· " .. rank .. "|r"
						end
						if isMine and db.myGuildText then
							new = new .. "  |cff" .. acHex
								.. "· " .. L["My Guild"] .. "|r"
						end
						if new ~= t then pcall(f.SetText, f, new) end
						break
					end
				end
			end
		end
	end

	-- level line: class name in class color + level in difficulty color
	if db.classText or db.levelDiffColor then
		local cname, ctok
		if db.classText then
			local ok4, cn = pcall(UnitClass, unit)
			cname = ok4 and plain(cn)
			-- the classFile return of UnitClass reads secret here - the
			-- ClassToken chain (classID, GUID) and the tooltip's own text
			-- are the reliable sources
			ctok = ClassToken(unit) or ClassFromTip(tip)
			if ctok and type(cname) ~= "string" then
				EnsureClassNames()
				-- class name secret too: pick the localized name right
				-- off the level line, token-matched
				for i = 2, math.min(6, tip:NumLines() or 0) do
					local lt = LineText(Line(tip, i))
					if lt then
						for n, ntok in pairs(CLASS_NAMES) do
							if ntok == ctok and lt:find(n, 1, true) then
								cname = n
								break
							end
						end
					end
					if cname then break end
				end
			end
		end
		local cr, cg, cb = ctok and TokenColor(ctok)
		local chex = (type(cr) == "number" and type(cg) == "number"
			and type(cb) == "number") and string.format("%02x%02x%02x",
			cr * 255, cg * 255, cb * 255) or nil
		local lvl, dhex
		if db.levelDiffColor then
			local okl, lv = pcall(UnitLevel, unit)
			lvl = okl and plain(lv)
			if type(lvl) == "number" and lvl > 0 then
				local okc, dc = pcall(GetQuestDifficultyColor, lvl)
				dc = okc and plain(dc)
				if type(dc) ~= "table" then dc = nil end
				if dc and type(dc.r) == "number" then
					dhex = string.format("%02x%02x%02x",
						dc.r * 255, dc.g * 255, dc.b * 255)
				end
			end
		end
		for i = 2, math.min(6, tip:NumLines() or 0) do
			local f = Line(tip, i)
			local t = LineText(f)
			if t then
				local new = t
				if chex and type(cname) == "string" and cname ~= ""
					and new:find(cname, 1, true) and not new:find(chex, 1, true) then
					new = (new:gsub(escPat(cname), "|cff" .. chex .. cname .. "|r", 1))
				end
				if dhex and lvl then
					local ls = tostring(lvl)
					if new:find(ls) and not new:find(dhex, 1, true) then
						new = (new:gsub(ls, "|cff" .. dhex .. ls .. "|r", 1))
					end
				end
				if new ~= t then pcall(f.SetText, f, new) break end
			end
		end
	end

	-- classification badge
	if db.classification then
		local ok5, cls = pcall(UnitClassification, unit)
		cls = ok5 and plain(cls)
		local label, cr, cg, cb = nil, 0.92, 0.68, 0.20
		if cls == "worldboss" then label, cr, cg, cb = L["Boss"], 0.95, 0.30, 0.25
		elseif cls == "rareelite" then label, cr, cg, cb = L["Rare elite"], 0.85, 0.55, 0.10
		elseif cls == "rare" then label, cr, cg, cb = L["Rare"], 0.85, 0.55, 0.10
		elseif cls == "elite" then label, cr, cg, cb = L["Elite"], 0.85, 0.55, 0.10
		end
		if label then
			AddLineOnce(tip, "|cff"
				.. string.format("%02x%02x%02x", cr * 255, cg * 255, cb * 255)
				.. "◆ " .. label .. "|r")
		end
	end

	-- group role
	if db.roleText then
		local ok6, role = pcall(UnitGroupRolesAssigned, unit)
		role = ok6 and plain(role)
		local label = role == "TANK" and L["Tank"]
			or role == "HEALER" and L["Healer"]
			or (role == "DAMAGER" or role == "DPS") and L["Damage"] or nil
		if label then
			UpsertLine(tip, L["Role"] .. ":", L["Role"] .. ": |cff"
				.. S.Hex(S.colors.accent) .. label .. "|r", 0.55, 0.57, 0.62)
		end
	end

	-- specialization (tiptac mechanics)
	if db.showSpec and isP ~= false then
		local info = (isP == true and PlayerData(unit, false))
			or RequestPlayerData(unit)
		if info and info.spec then
			local line = L["Specialization"] .. ": |cffffffff" .. info.spec .. "|r"
			if info.specRole then
				local rl = info.specRole == "TANK" and L["Tank"]
					or info.specRole == "HEALER" and L["Healer"]
					or info.specRole == "DAMAGER" and L["Damage"] or nil
				if rl then
					line = line .. " |cff8a8f98· " .. rl .. "|r"
				end
			end
			UpsertLine(tip, L["Specialization"] .. ":", line, 0.55, 0.57, 0.62)
		end
	end

	-- target of target, colored like the target itself
	if db.showTarget then
		local ok3, tname = pcall(UnitName, unit .. "target")
		tname = ok3 and plain(tname)
		if type(tname) == "string" and tname ~= "" then
			local hex = "ffffff"
			local tr, tg, tb = UnitColor(tip, unit .. "target")
			if type(plain(tr)) == "number" then
				hex = string.format("%02x%02x%02x", tr * 255, tg * 255, tb * 255)
			end
			UpsertLine(tip, L["Target"] .. ":", L["Target"] .. ": |cff"
				.. hex .. tname .. "|r", 0.55, 0.57, 0.62)
		end
	end

	-- rewritten/added lines can outgrow the frame the game already sized:
	-- widen it so text never draws over the border
	ns.Skin.Reflow(tip)
end
