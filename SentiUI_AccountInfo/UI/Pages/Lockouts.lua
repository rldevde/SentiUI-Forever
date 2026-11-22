-- luacheck: read globals GetServerTime
local _, ns = ...

-- Dungeons & raids page: saved-instance lockouts of every known
-- character — instance name, difficulty, boss progress with per-boss
-- killed markers and time until reset. Lockouts are only collected on
-- the character itself, so foreign characters show their last snapshot.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

local PAD = 12
local CHAR_H = 24
local LOCK_H = 20
local BOSS_H = 16

local CHECK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
local CROSS = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:0|t"

local function TimeAgo(ts)
	if not ts then
		return L.NEVER
	end
	return L.TIME_AGO:format(W.Duration(GetServerTime() - ts))
end

local function ResetText(lockout)
	if not lockout.resetAt then
		return nil
	end
	local left = lockout.resetAt - GetServerTime()
	if left <= 0 then
		return L.LOCK_RESET_SOON
	end
	return L.LOCK_RESET_IN:format(W.Duration(left))
end

local function Build(content)
	local page = {}

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	local header = W.Text(panel, "GameFontNormal", W.GOLD)
	header:SetPoint("TOPLEFT", PAD, -PAD)
	header:SetText(L.LOCK_TITLE)

	local hint = W.Text(panel, "GameFontDisableSmall", W.MUTED)
	hint:SetPoint("LEFT", header, "RIGHT", 10, 0)
	hint:SetPoint("RIGHT", -PAD, 0)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.LOCK_HINT)

	local scroll, holder = W.ScrollArea(panel)
	scroll:SetPoint("TOPLEFT", 1, -34)
	scroll:SetPoint("BOTTOMRIGHT", -9, 1)

	local empty = W.Text(panel, "GameFontDisable")
	empty:SetPoint("CENTER")
	empty:SetWidth(440)
	empty:SetJustifyH("CENTER")
	empty:SetText(L.LOCK_EMPTY)

	local pool = {}
	local used = 0
	local function Line(height)
		used = used + 1
		local f = pool[used]
		if not f then
			f = CreateFrame("Frame", nil, holder)
			f.text = W.Text(f, "GameFontHighlightSmall", W.TEXT)
			f.text:SetPoint("TOPLEFT", 0, 0)
			f.text:SetPoint("TOPRIGHT", 0, 0)
			f.text:SetJustifyH("LEFT")
			f.text:SetWordWrap(false)
			pool[used] = f
		end
		f:SetHeight(height)
		f:Show()
		return f
	end

	function page:Refresh()
		used = 0
		for _, f in ipairs(pool) do
			f:Hide()
		end
		local y = -4
		local any = false
		local width = math.max(100, scroll:GetWidth() - 4)

		for _, key in ipairs(Store.CharKeys()) do
			local char = ns.db.chars[key]
			local locks = char.lockouts
			if type(locks) == "table" and #locks > 0 then
				any = true
				-- Character header.
				local h = Line(CHAR_H)
				h:SetPoint("TOPLEFT", 0, y)
				h:SetWidth(width)
				local color = char.class and W.ClassColorHex(char.class) or "ffffffff"
				h.text:SetText(("|c%s%s|r   |cff8c919f%s|r"):format(color,
					char.name or ns.ShortName(key), TimeAgo(char.lockoutsAt)))
				y = y - CHAR_H

				for _, lockout in ipairs(locks) do
					local l = Line(LOCK_H)
					l:SetPoint("TOPLEFT", 0, y)
					l:SetWidth(width)
					local bits = { lockout.name }
					if lockout.difficulty then
						bits[#bits + 1] = "(" .. tostring(lockout.difficulty)
							.. (lockout.maxPlayers and (" · " .. lockout.maxPlayers .. "p") or "")
							.. ")"
					elseif lockout.maxPlayers then
						bits[#bits + 1] = "(" .. lockout.maxPlayers .. "p)"
					end
					if lockout.worldBoss then
						bits[#bits + 1] = "|cffebad33" .. L.LOCK_WORLD_BOSS .. "|r"
					elseif lockout.max and lockout.max > 0 then
						local done = lockout.progress or 0
						local cc = done >= lockout.max and "ff4dd25d" or "ffebad33"
						bits[#bits + 1] = ("|c%s%d/%d|r"):format(cc, done, lockout.max)
					end
					local reset = ResetText(lockout)
					if reset then
						bits[#bits + 1] = "|cff8c919f" .. reset .. "|r"
					end
					l.text:SetText("  " .. table.concat(bits, "  "))
					y = y - LOCK_H

					if lockout.encounters then
						for _, boss in ipairs(lockout.encounters) do
							local b = Line(BOSS_H)
							b:SetPoint("TOPLEFT", 0, y)
							b:SetWidth(width)
							b.text:SetText(("      %s %s"):format(
								boss.killed and CHECK or CROSS, boss.name))
							y = y - BOSS_H
						end
					end
				end
				y = y - 10
			end
		end
		-- Weekly checklist: every instance anyone is locked to, and who
		-- still has it free (never scanned chars are marked stale).
		local insts = Store.InstanceChecklist()
		if #insts > 0 then
			local h = Line(CHAR_H)
			h:SetPoint("TOPLEFT", 0, y)
			h:SetWidth(width)
			h.text:SetText("|cffebad33" .. L.LOCK_CHECKLIST .. "|r")
			y = y - CHAR_H
			for _, inst in ipairs(insts) do
				local l = Line(LOCK_H)
				l:SetPoint("TOPLEFT", 0, y)
				l:SetWidth(width)
				local title = inst.name
					.. (inst.diff and ("  |cff8c919f(" .. inst.diff .. ")|r") or "")
				local savedN, savedParts, freeParts, unscanned = 0, {}, {}, 0
				for _, key in ipairs(Store.CharKeys()) do
					local char = ns.db.chars[key]
					local color = char.class and W.ClassColorHex(char.class) or "ffffffff"
					local name = ("|c%s%s|r"):format(color, ns.ShortName(key))
					if inst.saved[key] then
						savedN = savedN + 1
						savedParts[#savedParts + 1] = name
					elseif char.lockoutsAt then
						freeParts[#freeParts + 1] = name
					else
						unscanned = unscanned + 1
					end
				end
				l.text:SetText(("  %s   |cff8c919f%s:|r %s   |cff4dd25d%s:|r %s%s"):format(
					title, L.LOCK_SAVED, table.concat(savedParts, " "),
					L.LOCK_FREE, table.concat(freeParts, " "),
					unscanned > 0 and ("   |cff8c919f(+%d %s)|r"):format(
						unscanned, L.LOCK_UNSCANNED) or ""))
				y = y - LOCK_H
			end
			y = y - 10
		end
		empty:SetShown(not any)
		holder:SetHeight(math.max(1, -y + 10))
	end

	return page
end

UI.RegisterPage(5, L.TAB_LOCKOUTS, Build)
