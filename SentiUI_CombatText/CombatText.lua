-- SentiUI combat text: a scrolling feed of incoming combat events -
-- damage taken, healing received, misses and resource gains. Driven by
-- COMBAT_TEXT_UPDATE, the same unprotected event the unit-frame combat
-- text reads: the combat log itself is a protected registration on this
-- client, so OUTGOING damage has no Lua-visible source and the feed only
-- covers what lands on the player.
--
-- Rows are pooled FontStrings on a movable frame: newest at the bottom,
-- they hold, then fly off toward a screen edge (or fade in place) like
-- the loot feed rows. All animation is region ops (alpha + SetPoint on
-- pooled strings) - created out of combat, legal mid-fight.
local _, ns = ...
local S = SentiUI
local L = ns.L
local IsSecret = S.IsSecret

local GetTime = GetTime
local tremove, tinsert = table.remove, table.insert

local Core = {}
ns.Core = Core
local db

local ROW_H = 18
local POOL = 8

local feed, rows, entries

-- type routing: arg1 of COMBAT_TEXT_UPDATE -> (style key, color, flags)
-- amounts read arg2 except energize/leech families which read arg3 (same
-- read the unit-frame combat text does)
local STYLES = {
	DAMAGE            = { flag = "damage", col = { 1, 0.35, 0.35 } },
	DAMAGE_CRIT       = { flag = "damage", col = { 1, 0.45, 0.25 }, crit = true },
	SPELL_DAMAGE      = { flag = "damage", col = { 1, 0.35, 0.35 } },
	SPELL_DAMAGE_CRIT = { flag = "damage", col = { 1, 0.45, 0.25 }, crit = true },
	PERIODIC_DAMAGE   = { flag = "damage", col = { 0.85, 0.4, 0.4 } },
	DAMAGE_SHIELD     = { flag = "damage", col = { 1, 0.35, 0.35 } },
	HEAL              = { flag = "heals", col = { 0.35, 0.9, 0.45 } },
	HEAL_CRIT         = { flag = "heals", col = { 0.45, 1, 0.5 }, crit = true },
	SPELL_HEAL        = { flag = "heals", col = { 0.35, 0.9, 0.45 } },
	SPELL_HEAL_CRIT   = { flag = "heals", col = { 0.45, 1, 0.5 }, crit = true },
	PERIODIC_HEAL     = { flag = "heals", col = { 0.35, 0.8, 0.5 } },
	MISS              = { flag = "misses", col = { 0.75, 0.75, 0.75 }, label = "Miss" },
	DODGE             = { flag = "misses", col = { 0.75, 0.75, 0.75 }, label = "Dodge" },
	PARRY             = { flag = "misses", col = { 0.75, 0.75, 0.75 }, label = "Parry" },
	BLOCK             = { flag = "misses", col = { 0.75, 0.75, 0.75 }, label = "Block" },
	RESIST            = { flag = "misses", col = { 0.75, 0.75, 0.75 }, label = "Resist" },
	IMMUNE            = { flag = "misses", col = { 0.75, 0.75, 0.75 }, label = "Resist" },
	ENERGIZE          = { flag = "gains", col = { 0.4, 0.6, 1 }, use3 = true },
	PERIODIC_ENERGIZE = { flag = "gains", col = { 0.4, 0.6, 1 }, use3 = true },
	SPELL_ENERGIZE    = { flag = "gains", col = { 0.4, 0.6, 1 }, use3 = true },
	SPELL_LEECH       = { flag = "gains", col = { 0.4, 0.75, 1 }, use3 = true },
	ABSORB            = { flag = "gains", col = { 0.9, 0.9, 1 }, label = "Absorb" },
	ABSORB_ADDED      = { flag = "gains", col = { 0.9, 0.9, 1 }, label = "Absorb" },
}

local UpdateFeed -- layout + animation pass, assigned in BuildFeed

-- feed ----------------------------------------------------------------------
local function BuildFeed()
	if feed then return end
	feed = CreateFrame("Frame", "SentiUICombatTextFeed", UIParent)
	feed:SetSize(260, ROW_H)
	-- default: right of the screen center, classic SCT spot; mover moves it
	feed:SetPoint("CENTER", UIParent, "CENTER", 260, -120)
	feed:SetFrameStrata("MEDIUM")
	feed:EnableMouse(false)
	S.Movers.Register(feed, "combattext.feed", L["Combat text feed"])

	rows = {}
	for i = 1, POOL do
		local fs = S.Font(feed, db.fontSize or 14, nil, "OUTLINE")
		fs:SetJustifyH("CENTER")
		fs:Hide()
		rows[i] = fs
	end
	entries = {}

	function UpdateFeed(_, dt)
		dt = dt or 0.016
		local now, hold = GetTime(), db.hold or 2.2
		for i = #entries, 1, -1 do
			local e = entries[i]
			if e.fading then
				e.alpha = e.alpha - dt * 2
				if e.alpha <= 0 then
					tremove(entries, i)
				elseif e.exitDir and e.exitDist then
					-- fly to the screen edge, eased like the loot feed
					local f = 1 - e.alpha
					e.slide = e.exitDir * (f * f) * e.exitDist
				end
			elseif now - e.t > hold then
				e.fading = true
				local dir = db.feedExit == "left" and -1
					or db.feedExit == "right" and 1 or 0
				if dir ~= 0 then
					local x = feed:GetCenter()
					if x then
						local edge = dir > 0 and UIParent:GetRight()
							or UIParent:GetLeft()
						if edge then
							e.exitDir = dir
							e.exitDist = math.abs(edge - x) + 40
						end
					end
				end
			end
		end
		-- layout: newest at the bottom, older stack upward; styling is
		-- re-stamped every pass since pooled rows recycle mid-flight
		for i = 1, POOL do rows[i]:Hide() end
		local idx = 0
		local base = db.fontSize or 14
		for i = #entries, math.max(1, #entries - POOL + 1), -1 do
			local e = entries[i]
			local row = rows[idx + 1]
			idx = idx + 1
			e.row = row
			if row then
				pcall(row.SetText, row, e.text)
				row:SetTextColor(e.r, e.g, e.b)
				row:SetFont(S.media.font,
					(e.crit and db.crits ~= false) and base + 6 or base,
					"OUTLINE")
				row:ClearAllPoints()
				row:SetPoint("BOTTOM", feed, "BOTTOM", e.slide or 0,
					(idx - 1) * ROW_H)
				row:SetAlpha(e.fading and e.alpha or 1)
				row:Show()
			end
		end
		if #entries == 0 then
			feed:SetScript("OnUpdate", nil)
		end
	end
end

local function Push(text, r, g, b, crit)
	if not feed then return end
	tinsert(entries, {
		text = text, r = r, g = g, b = b, crit = crit,
		t = GetTime(), alpha = 1,
	})
	if #entries > 40 then tremove(entries, 1) end
	feed:SetScript("OnUpdate", UpdateFeed)
end

-- event ---------------------------------------------------------------------
local function OnCombatText(_, arg1, arg2, arg3)
	if IsSecret(arg1) then return end
	local st = arg1 and STYLES[arg1]
	if not st then return end
	if db[st.flag] == false then return end
	local crit = st.crit == true or arg3 == 1 or arg3 == true
	local text
	if st.label then
		text = L[st.label]
	else
		local v = st.use3 and arg3 or arg2
		if IsSecret(v) then
			text = v -- FontString renders secret numbers raw
		elseif type(v) == "number" then
			local prefix = st.flag ~= "damage" and "+" or "-"
			text = prefix .. tostring(v)
		elseif type(v) == "string" then
			text = v
		else
			return
		end
	end
	Push(text, st.col[1], st.col[2], st.col[3], crit)
end

function Core.SettingChanged(mod, path)
	if not feed then return end
	-- re-stamp pooled rows at the new font size
	local base = db.fontSize or 14
	for _, row in ipairs(rows) do
		row:SetFont(S.media.font, base, "OUTLINE")
	end
end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db
	BuildFeed()
	S.RegisterEvent("COMBAT_TEXT_UPDATE", function(ev, a, b, c)
		S.SafeCall("ct:feed", OnCombatText, ev, a, b, c)
	end)
end
