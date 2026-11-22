-- Page registry plus the secondary pages: Pet, Reputation, Skills, PvP,
-- Currency and Statistics. Each page decides via Available() whether this
-- client exposes the APIs it needs; unavailable pages keep the tab hidden
-- so ToggleCharacter can fall through to the Blizzard window.
local _, ns = ...
local S = SentiUI
local C = S.colors
local L = ns.L

ns.Pages = {}
local P = ns.Pages

P.order = {}
P.defs = {}

function P.Register(id, def)
	P.defs[id] = def
	P.order[#P.order + 1] = id
end

-- Generic scrolling list ------------------------------------------------
-- A scroll child filled with pooled rows (label left, value/bar right).

local function MakeList(parent)
	local sf, child = S.Widgets.Scroll(parent)
	sf:SetPoint("TOPLEFT", 4, -4)
	sf:SetPoint("BOTTOMRIGHT", -10, 4)
	sf.child = child
	sf.rows = {}
	-- refresh the thin bar whenever the list content height changes
	local rawSetHeight = child.SetHeight
	child.SetHeight = function(s, h)
		rawSetHeight(s, h)
		if sf.UpdateBar then sf.UpdateBar() end
	end
	return sf
end

local function Row(sf, i)
	local r = sf.rows[i]
	if r then return r end
	r = CreateFrame("Frame", nil, sf.child)
	r:SetHeight(18)
	r.label = S.Font(r, 10)
	r.label:SetPoint("LEFT", 6, 0)
	r.label:SetWidth(180)
	r.label:SetJustifyH("LEFT")
	r.label:SetWordWrap(false)
	r.value = S.Font(r, 10, C.textDim)
	r.value:SetPoint("RIGHT", -6, 0)
	r.bar = r:CreateTexture(nil, "BACKGROUND")
	r.bar:SetPoint("LEFT", r.label, "RIGHT", 4, 0)
	r.bar:SetPoint("RIGHT", -110, 0)
	r.bar:SetHeight(10)
	r.fill = r:CreateTexture(nil, "ARTWORK")
	r.fill:SetPoint("TOPLEFT", r.bar, "TOPLEFT", 1, -1)
	r.fill:SetPoint("BOTTOMLEFT", r.bar, "BOTTOMLEFT", 1, 1)
	r.fill:SetHeight(8)
	r.bar:Hide()
	sf.rows[i] = r
	return r
end

local function ClearRows(sf, from)
	for i = from, #sf.rows do sf.rows[i]:Hide() end
end

local function NoAPI(parent)
	if not parent.noapi then
		parent.noapi = S.Font(parent, 11, C.textDim)
		parent.noapi:SetPoint("CENTER")
		parent.noapi:SetText(L["Not available on this client."])
	end
	parent.noapi:Show()
end

-- Pet -------------------------------------------------------------------

P.Register("pet", {
	label = L["Pet"],
	Available = function() return HasPetUI and HasPetUI() end,
	Build = function(f)
		f.model = CreateFrame("PlayerModel", nil, f)
		f.model:SetPoint("TOP", 0, -10)
		f.model:SetSize(240, 280)
		f.info = S.Font(f, 11, C.textDim)
		f.info:SetPoint("TOP", f.model, "BOTTOM", 0, -6)
	end,
	Refresh = function(f)
		if not UnitExists("pet") then
			f.model:Hide()
			f.info:SetText(L["No pet summoned."])
			return
		end
		f.model:Show()
		f.model:SetUnit("pet")
		local name = ns.PlainStr(UnitName("pet")) or ""
		local hp = ns.Plain(UnitHealth("pet"))
		local hpmax = ns.Plain(UnitHealthMax("pet"))
		local xp, xpmax
		if GetPetExperience then
			xp, xpmax = ns.Plain(GetPetExperience())
		end
		local happy
		if GetPetHappiness then
			local h = ns.Plain(GetPetHappiness())
			local names = { [1] = L["Unhappy"], [2] = L["Content"], [3] = L["Happy"] }
			happy = h and names[h]
		end
		local parts = { name }
		if hp and hpmax then
			parts[#parts + 1] = string.format("%d / %d HP", hp, hpmax)
		end
		if xp and xpmax and xpmax > 0 then
			parts[#parts + 1] = string.format(L["XP: %d / %d"], xp, xpmax)
		end
		if happy then parts[#parts + 1] = happy end
		f.info:SetText(table.concat(parts, "   "))
	end,
})

-- Reputation --------------------------------------------------------------

P.Register("reputation", {
	label = L["Reputation"],
	Available = function() return GetNumFactions ~= nil end,
	Build = function(f) f.list = MakeList(f) end,
	Refresh = function(f)
		local sf = f.list
		local n = ns.Plain(GetNumFactions()) or 0
		local ri, y = 0, 0
		if ExpandAllFactionHeaders then ExpandAllFactionHeaders() end
		for i = 1, n do
			local name, _, standingID, barMin, barMax, barValue, _, _, isHeader, isCollapsed, hasRep =
				GetFactionInfo(i)
			name = ns.PlainStr(name)
			standingID = ns.Plain(standingID)
			barMin, barMax, barValue = ns.Plain(barMin), ns.Plain(barMax), ns.Plain(barValue)
			if name then
				ri = ri + 1
				local r = Row(sf, ri)
				r:SetPoint("TOPLEFT", 0, -y)
				r:SetPoint("RIGHT", sf.child, "RIGHT", 0, 0)
				if isHeader then
					r.label:SetText(name)
					r.label:SetTextColor(C.accent.r, C.accent.g, C.accent.b)
					r.value:SetText("")
					r.bar:Hide()
				else
					r.label:SetText("   " .. name)
					r.label:SetTextColor(1, 1, 1)
					if hasRep and barMin and barMax and barValue then
						local span = barMax - barMin
						local pct = span > 0 and (barValue - barMin) / span or 0
						local sc = FACTION_BAR_COLORS and FACTION_BAR_COLORS[standingID or 1]
						r.bar:Show()
						r.bar:SetColorTexture(1, 1, 1, 0.08)
						r.fill:SetWidth(math.max(1, (r.bar:GetWidth() or 100) * pct))
						r.fill:SetColorTexture(sc and sc.r or 0.4, sc and sc.g or 0.4, sc and sc.b or 0.4)
						local st = standingID and GetText
							and ns.PlainStr(GetText("FACTION_STANDING_LABEL" .. standingID,
								UnitSex("player")))
						r.value:SetText(st or "")
					else
						r.bar:Hide()
						r.value:SetText("")
					end
				end
				r:Show()
				y = y + 18
			end
		end
		ClearRows(sf, ri + 1)
		sf.child:SetHeight(math.max(1, y))
	end,
})

-- Skills -------------------------------------------------------------------

P.Register("skills", {
	label = L["Skills"],
	Available = function() return GetNumSkillLines ~= nil end,
	Build = function(f) f.list = MakeList(f) end,
	Refresh = function(f)
		local sf = f.list
		local n = ns.Plain(GetNumSkillLines()) or 0
		local ri, y = 0, 0
		if ExpandSkillHeader then ExpandSkillHeader(0) end
		for i = 1, n do
			local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
			name = ns.PlainStr(name)
			rank, maxRank = ns.Plain(rank), ns.Plain(maxRank)
			if name then
				ri = ri + 1
				local r = Row(sf, ri)
				r:SetPoint("TOPLEFT", 0, -y)
				r:SetPoint("RIGHT", sf.child, "RIGHT", 0, 0)
				if isHeader then
					r.label:SetText(name)
					r.label:SetTextColor(C.accent.r, C.accent.g, C.accent.b)
					r.value:SetText("")
					r.bar:Hide()
				else
					r.label:SetText("   " .. name)
					r.label:SetTextColor(1, 1, 1)
					if rank and maxRank and maxRank > 0 then
						r.bar:Show()
						r.bar:SetColorTexture(1, 1, 1, 0.08)
						r.fill:SetWidth(math.max(1, (r.bar:GetWidth() or 100) * rank / maxRank))
						r.fill:SetColorTexture(C.accent2.r, C.accent2.g, C.accent2.b)
						r.value:SetText(rank .. " / " .. maxRank)
					else
						r.bar:Hide()
						r.value:SetText("")
					end
				end
				r:Show()
				y = y + 18
			end
		end
		ClearRows(sf, ri + 1)
		sf.child:SetHeight(math.max(1, y))
	end,
})

-- PvP ----------------------------------------------------------------------

P.Register("pvp", {
	label = L["PvP"],
	Available = function() return GetPVPLifetimeStats ~= nil or GetPVPSessionStats ~= nil end,
	Build = function(f) f.list = MakeList(f) end,
	Refresh = function(f)
		local sf = f.list
		local ri, y = 0, 0
		local function Add(label, value)
			ri = ri + 1
			local r = Row(sf, ri)
			r:SetPoint("TOPLEFT", 0, -y)
			r:SetPoint("RIGHT", sf.child, "RIGHT", 0, 0)
			r.label:SetText(label)
			r.label:SetTextColor(1, 1, 1)
			r.value:SetText(value or "-")
			r.bar:Hide()
			r:Show()
			y = y + 18
		end
		if GetPVPSessionStats then
			local hk, dk = ns.Plain(select(1, GetPVPSessionStats())), ns.Plain(select(2, GetPVPSessionStats()))
			Add(L["Honorable kills today"], hk and tostring(hk))
		end
		if GetPVPLifetimeStats then
			local hk, _, rank = GetPVPLifetimeStats()
			hk = ns.Plain(hk)
			Add(L["Lifetime honorable kills"], hk and tostring(hk))
			local rname = rank and GetPVPRankInfo and select(1, GetPVPRankInfo(rank))
			if rname then Add(L["Highest rank"], ns.PlainStr(rname)) end
		end
		ClearRows(sf, ri + 1)
		sf.child:SetHeight(math.max(1, y))
	end,
})

-- Currency -------------------------------------------------------------------

P.Register("currency", {
	label = L["Currency"],
	Available = function() return C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize ~= nil end,
	Build = function(f) f.list = MakeList(f) end,
	Refresh = function(f)
		local sf = f.list
		local n = ns.Plain(C_CurrencyInfo.GetCurrencyListSize()) or 0
		local ri, y = 0, 0
		for i = 1, n do
			local ok, info = pcall(C_CurrencyInfo.GetCurrencyListInfo, i)
			if ok and type(info) == "table" then
				local name = ns.PlainStr(info.name)
				if name and name ~= "" then
					ri = ri + 1
					local r = Row(sf, ri)
					r:SetPoint("TOPLEFT", 0, -y)
					r:SetPoint("RIGHT", sf.child, "RIGHT", 0, 0)
					if info.isHeader then
						r.label:SetText(name)
						r.label:SetTextColor(C.accent.r, C.accent.g, C.accent.b)
						r.value:SetText("")
					else
						local qty = ns.Plain(info.quantity)
						local mx = ns.Plain(info.maxQuantity)
						r.label:SetText("   " .. name)
						r.label:SetTextColor(1, 1, 1)
						r.value:SetText(mx and mx > 0 and (qty or 0) .. " / " .. mx or tostring(qty or 0))
					end
					r.bar:Hide()
					r:Show()
					y = y + 18
				end
			end
		end
		ClearRows(sf, ri + 1)
		sf.child:SetHeight(math.max(1, y))
	end,
})

-- Statistics -----------------------------------------------------------------

P.Register("statistics", {
	label = L["Statistics"],
	Available = function() return GetCategoryList ~= nil and GetStatistic ~= nil end,
	Build = function(f) f.list = MakeList(f) end,
	Refresh = function(f)
		local sf = f.list
		local cats = GetCategoryList()
		if type(cats) ~= "table" then return end
		local ri, y = 0, 0
		for _, catId in ipairs(cats) do
			local ok, catName, num = pcall(function()
				local name, parent = GetCategoryInfo(catId)
				return name, GetCategoryNumAchievements(catId)
			end)
			catName = ok and catName or nil
			num = ok and num or 0
			if catName and num and num > 0 then
				ri = ri + 1
				local r = Row(sf, ri)
				r:SetPoint("TOPLEFT", 0, -y)
				r:SetPoint("RIGHT", sf.child, "RIGHT", 0, 0)
				r.label:SetText(ns.PlainStr(catName) or "?")
				r.label:SetTextColor(C.accent.r, C.accent.g, C.accent.b)
				r.value:SetText("")
				r.bar:Hide()
				r:Show()
				y = y + 18
				for a = 1, num do
					local ok2, id, sname = pcall(function()
						local id, name = GetAchievementInfo(catId, a)
						return id, name
					end)
					if ok2 and sname and sname ~= -1 then
						local val = sname
						if val == "" then val = nil end
						if val or true then
							ri = ri + 1
							local r2 = Row(sf, ri)
							r2:SetPoint("TOPLEFT", 0, -y)
							r2:SetPoint("RIGHT", sf.child, "RIGHT", 0, 0)
							local ok3, entry = pcall(GetStatistic, id or -1)
							r2.label:SetText("   " .. tostring(ns.PlainStr(sname) or ""))
							r2.label:SetTextColor(1, 1, 1)
							r2.value:SetText(ok3 and ns.PlainStr(entry) or "")
							r2.bar:Hide()
							r2:Show()
							y = y + 18
						end
					end
				end
			end
		end
		ClearRows(sf, ri + 1)
		sf.child:SetHeight(math.max(1, y))
	end,
})
