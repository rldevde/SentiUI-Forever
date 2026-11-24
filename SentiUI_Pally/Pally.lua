-- Two windows, like PallyPower (and our SentinelBlessings):
--  * the buff bar - a slim always-on tracker: personal RF/aura/seal icons
--    and one row per class in the group. The row IS the cast button:
--    left-click puts the greater blessing on the class, right-click puts
--    the single blessing on the first member missing it.
--  * the assignment grid (/sp or the "Grid" button) - class columns on top,
--    one row per known paladin, cells cycle that paladin's blessing for the
--    class; the last column cycles the aura assignment.
-- Secure cast buttons carry attributes only, no scripts - a script on a
-- secure frame taints the click dispatch on this client and the cast dies
-- FORBIDDEN.
local _, ns = ...
local S = SentiUI
local L = ns.L
local D = ns.Data
local C = S.colors
local W = S.Widgets
local Comm = ns.Comm

local Core = {}
ns.Core = Core
local UI = {}
ns.UI = UI

local EDGE = 8
local BAR_W = 168
local ROW_H = 18
local CELL = 24          -- grid cell pitch
local GRID_LEFT = 120    -- name column width in the grid

local db
local playerName
local bar, grid
local barRows = {}       -- classId -> secure row
local rfChip, auraChip, sealChip
local gridCells, gridNames, gridAuras = {}, {}, {}
local hdrIcons, hdrAura
local footRow, freeChk, minW = nil, nil, 340
local manualHideBar, gridShown

-- blessing name cache (wire only carries ids)
local bname, bnames = {}, false
local function blessingName(b)
	if not bnames then
		bnames = true
		for i = 1, D.BLESSING_IDS do
			local info = D.Blessings[i]
			bname[i] = info and D.SpellName(info.ranks[#info.ranks]) or ("#" .. i)
		end
	end
	return bname[b] or "?"
end
local classNames = LOCALIZED_CLASS_NAMES_MALE or {}
local function className(c) return classNames[c] or c end
local function ShortName(n) return n and Ambiguate and Ambiguate(n, "short") or n end
local function me() return playerName end

-- ---------------------------------------------------------------------------
-- secure helpers
-- ---------------------------------------------------------------------------

local function secureBtn(parent, name)
	local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
	b:RegisterForClicks("AnyDown", "AnyUp")
	pcall(b.SetAttribute, b, "useOnKeyDown", false)
	return b
end

-- mouse = 1 left / 2 right button attributes
local function setCast(b, mouse, spell, unit)
	if InCombatLockdown() then return end
	-- the secure "spell" attribute resolves by NAME on this client - a bare
	-- id silently casts nothing (SentinelForeverBlessings does the same)
	pcall(b.SetAttribute, b, "type" .. mouse, spell and "spell" or nil)
	pcall(b.SetAttribute, b, "spell" .. mouse,
		spell and D.SpellName(spell) or nil)
	pcall(b.SetAttribute, b, "unit" .. mouse, unit or nil)
end

-- ---------------------------------------------------------------------------
-- state helpers
-- ---------------------------------------------------------------------------

local function pallyOrder()
	local mine = me()
	local out = {}
	for name in pairs(Comm.pallies) do out[#out + 1] = name end
	table.sort(out, function(a, b)
		if a == mine then return true end
		if b == mine then return false end
		return a < b
	end)
	return out
end

local function auraHas(id)
	if not id then return false end
	return D.AuraSet("player")[id] == true
end

local function myClass(cid) return (Comm.ga[me()] or {})[cid] or 0 end
local function myAura() return Comm.aa[me()] or 0 end
local function myNormal(cid, who)
	local m = Comm.na[me()]
	return (m and m[cid] and m[cid][who]) or 0
end

-- effective blessing a member should get from me (override or class assign)
local function effBless(cid, who)
	local over = myNormal(cid, who)
	if over ~= 0 then return over end
	return myClass(cid)
end

local roster
local function membersOf(cid) return (roster and roster.classes[cid]) or {} end

-- per-member missing check against that member's effective blessing
local function memberMiss(m, cid)
	local set = m.auras or D.AuraSet(m.unit)
	m.auras = set
	local b = effBless(cid, m.name)
	if b ~= 0 then return not D.HasBlessing(set, b) end
	return not D.HasAnyBlessing(set)
end

-- ---------------------------------------------------------------------------
-- small icon chips (RF / aura / seal) on the bar
-- ---------------------------------------------------------------------------

-- icon chip: secure cast on the icon, plain ">" button owns cycling + tooltip
local function chip(parent, cyclable)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetSize(28, 18)
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetSize(16, 16)
	f.icon:SetPoint("LEFT", 1, 0)
	f.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	f.cast = secureBtn(f)
	f.cast:SetPoint("LEFT", f, "LEFT", 1, 0)
	f.cast:SetSize(16, 16)
	local c = CreateFrame("Button", nil, f)
	-- protected children may only anchor to frames, never to the texture
	c:SetPoint("LEFT", f, "LEFT", 17, 0)
	c:SetSize(10, 16)
	c.label = S.Font(c, 9, C.textDim)
	c.label:SetPoint("CENTER")
	c.label:SetText(">")
	c:EnableMouseWheel(true)
	f.cycle = c
	-- non-cyclable chips keep the strip as a tooltip hover zone
	if not cyclable then c.label:SetText("") end
	return f
end

local function chipTip(owner, tip)
	owner.tip = tip
end
local function chipEnter(owner)
	owner.cycle:SetScript("OnEnter", function()
		if GameTooltip and owner.tip then
			GameTooltip:SetOwner(owner.cycle, "ANCHOR_RIGHT")
			GameTooltip:SetText(owner.tip)
			GameTooltip:Show()
		end
	end)
	owner.cycle:SetScript("OnLeave", function()
		if GameTooltip then GameTooltip:Hide() end
	end)
end

local function paintAuraChip()
	if not auraChip then return end
	-- the chips contain secure buttons = protected frames: Show/Hide in
	-- combat is FORBIDDEN. Park the whole repaint so icon and attributes
	-- stay consistent with what the button would cast
	if InCombatLockdown() then S.RunOutOfCombat(paintAuraChip) return end
	-- the grid assignment drives the button (PallyPower behavior); the pick
	-- is NOT skill-gated - SentinelForeverBlessings shows whatever is
	-- assigned and lets a failed cast speak for itself
	local a = Comm.aa[me()] or 0
	if a < 1 or a > #D.Auras or not D.Auras[a] then a = 0 end
	auraChip:Show()
	local info = D.Auras[a > 0 and a or 1]
	auraChip.icon:SetTexture(info.icon)
	auraChip.icon:SetDesaturated(a == 0)
	setCast(auraChip.cast, 1, a > 0 and info.id or nil, "player")
	chipTip(auraChip, (D.SpellName(info.id) or "?") .. "\n" ..
		L["Left: cast - right on > or wheel: next aura"])
end

local function paintSealChip()
	if not sealChip then return end
	if InCombatLockdown() then S.RunOutOfCombat(paintSealChip) return end
	sealChip:Show()
	-- db.seal indexes D.Seals directly (the pick is not skill-gated,
	-- like the reference) - rank-1 ids miss higher learned ranks anyway
	local pick = db.seal or 0
	if pick < 1 or pick > #D.Seals then pick = 1 db.seal = 1 end
	local id = D.Seals[pick]
	sealChip.icon:SetTexture(D.SpellIcon(id) or D.Blessings[1].icon)
	sealChip.icon:SetDesaturated(false)
	setCast(sealChip.cast, 1, id, "player")
	chipTip(sealChip, (D.SpellName(id) or "?") .. "\n" ..
		L["Left: cast - right on > or wheel: next seal"])
end

local function paintRFChip()
	if not rfChip then return end
	if InCombatLockdown() then S.RunOutOfCombat(paintRFChip) return end
	if not D.IsKnown(D.RFID) then rfChip:Hide() return end
	rfChip:Show()
	rfChip.icon:SetTexture(D.SpellIcon(D.RFID) or D.Blessings[2].icon)
	setCast(rfChip.cast, 1, D.RFID, "player")
	local has = auraHas(D.RFID)
	-- reminder: dim when missing (option rfbuff), solid when active
	rfChip.icon:SetDesaturated(not has)
	rfChip.icon:SetAlpha((has or not (db and db.rfbuff)) and 1 or 0.45)
	chipTip(rfChip, L["Righteous Fury"])
end

local function cycle(list, key, paint, step)
	if #list == 0 then return end
	db[key] = ((db[key] - 1 + step) % #list) + 1
	S.RunOutOfCombat(paint)
end

-- ---------------------------------------------------------------------------
-- buff bar
-- ---------------------------------------------------------------------------

local function barRow(cid)
	local r = barRows[cid]
	if r then return r end
	r = secureBtn(bar)
	r:SetHeight(ROW_H)
	r:SetPoint("LEFT", 3, 0)
	r:SetPoint("RIGHT", -3, 0)
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetSize(14, 14)
	r.icon:SetPoint("LEFT", 2, 0)
	r.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	r.cls = r:CreateTexture(nil, "ARTWORK")
	r.cls:SetSize(12, 12)
	r.cls:SetPoint("LEFT", r.icon, "RIGHT", 4, 0)
	r.cls:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	r.name = S.Font(r, 10, C.text)
	r.name:SetPoint("LEFT", r.cls, "RIGHT", 5, 0)
	r.name:SetJustifyH("LEFT")
	r.count = S.Font(r, 9)
	r.count:SetPoint("RIGHT", -2, 0)
	r.count:SetJustifyH("RIGHT")
	r.cid = cid
	-- tooltip on a plain child at the row's right edge: the secure row
	-- itself may carry NO scripts (taints the click dispatch here)
	local info = CreateFrame("Button", nil, r)
	info:SetPoint("RIGHT", r, "RIGHT", -1, 0)
	info:SetSize(30, ROW_H)
	info:SetScript("OnEnter", function(self)
		if not GameTooltip then return end
		local row = self:GetParent()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(className(D.ClassID[row.cid]))
		local b = myClass(row.cid)
		GameTooltip:AddLine(string.format("%s: %s", L["Assigned"],
			b > 0 and blessingName(b) or L["none"]), 0.8, 0.8, 0.8)
		local miss = row.miss or 0
		local tot = row.tot or 0
		GameTooltip:AddLine(string.format("%s: %d/%d", L["Blessed"], tot - miss, tot),
			0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["Left: greater on class - right: single on missing"],
			0.55, 0.55, 0.55)
		GameTooltip:Show()
	end)
	info:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
	barRows[cid] = r
	return r
end

local function paintBarRows()
	local y = 42
	local shown = 0
	for cid = 1, D.MAXCLASSES do
		local members = membersOf(cid)
		if #members > 0 then
			local r = barRow(cid)
			local bless = myClass(cid)
			local miss, first = 0, nil
			for _, m in ipairs(members) do
				if memberMiss(m, cid) then
					miss = miss + 1
					if not first then first = m end
				end
			end
			-- left: greater on the class; right: single rank on first missing
			-- (rank scaled to that member's level, like PallyPower does)
			if bless > 0 then
				local tgt = first or members[1]
				local lvl = tgt.unit and UnitLevel and UnitLevel(tgt.unit) or 0
				local gid = D.BestGreaterSpell(bless)
				local nid = D.BlessingForLevel(bless, lvl)
				setCast(r, 1, gid, members[1].unit)
				setCast(r, 2, nid, tgt.unit)
				r.icon:SetTexture(D.Blessings[bless].icon)
				r.icon:SetDesaturated(false)
				r.icon:SetAlpha(1)
			else
				setCast(r, 1, nil); setCast(r, 2, nil)
				r.icon:SetTexture(D.Blessings[1].icon)
				r.icon:SetDesaturated(true)
				r.icon:SetAlpha(0.35)
			end
			r.miss, r.tot = miss, #members
			r.cls:SetTexture(D.ClassIcons[cid])
			r.name:SetText(className(D.ClassID[cid]))
			if miss > 0 then
				r.count:SetText("|cfff0525c" .. miss .. "/" .. #members .. "|r")
			else
				r.count:SetText("|cff4dd878" .. #members .. "/" .. #members .. "|r")
			end
			r:ClearAllPoints()
			r:SetPoint("TOPLEFT", 3, -(y + shown * (ROW_H + 1)))
			r:SetPoint("RIGHT", -3, 0)
			r:Show()
			shown = shown + 1
		end
	end
	for cid = 1, D.MAXCLASSES do
		if #membersOf(cid) == 0 and barRows[cid] then barRows[cid]:Hide() end
	end
	return shown
end

local function buildBar()
	if bar then return bar end
	local f = CreateFrame("Frame", "SentiUIPallyBar", UIParent, "BackdropTemplate")
	bar = f
	f:SetSize(BAR_W, 60)
	f:SetPoint("CENTER", -380, 120)
	f:SetFrameStrata("MEDIUM")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:Hide()
	S.Template(f, "panel")
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		local y = select(2, GetCursorPosition()) / self:GetEffectiveScale()
		if y > self:GetTop() - 20 and not InCombatLockdown() then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		S.RunOutOfCombat(function()
			self:StopMovingOrSizing()
			S.Movers.Save("blessings.bar")
		end)
	end)

	f.title = S.Font(f, 10, C.accent)
	f.title:SetPoint("TOPLEFT", 6, -4)
	f.title:SetText(L["Blessings"])
	f.sym = S.Font(f, 9, C.textDim)
	f.sym:SetPoint("LEFT", f.title, "RIGHT", 6, 0)

	-- grid toggle + close on the title line
	f.gridBtn = CreateFrame("Button", nil, f)
	f.gridBtn:SetSize(26, 12)
	f.gridBtn:SetPoint("TOPRIGHT", -20, -5)
	f.gridBtn.label = S.Font(f.gridBtn, 9, C.accent2)
	f.gridBtn.label:SetPoint("CENTER")
	f.gridBtn.label:SetText(L["Grid"])
	f.gridBtn:SetScript("OnClick", function() UI.ToggleGrid() end)
	f.gridBtn:SetScript("OnEnter", function(self) self.label:SetTextColor(C.text.r, C.text.g, C.text.b) end)
	f.gridBtn:SetScript("OnLeave", function(self) self.label:SetTextColor(C.accent2.r, C.accent2.g, C.accent2.b) end)
	f.x = CreateFrame("Button", nil, f)
	f.x:SetSize(14, 12)
	f.x:SetPoint("TOPRIGHT", -5, -5)
	f.x.label = S.Font(f.x, 9, C.textDim)
	f.x.label:SetPoint("CENTER")
	f.x.label:SetText("x")
	f.x:SetScript("OnClick", function()
		manualHideBar = true
		S.RunOutOfCombat(function() f:Hide() end)
	end)
	f.x:SetScript("OnEnter", function(self) self.label:SetTextColor(C.red.r, C.red.g, C.red.b) end)
	f.x:SetScript("OnLeave", function(self) self.label:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b) end)

	-- personal icons: RF, aura, seal
	rfChip = chip(f, false)
	rfChip:SetPoint("TOPLEFT", 5, -20)
	auraChip = chip(f, true)
	auraChip:SetPoint("LEFT", rfChip, "RIGHT", 4, 0)
	sealChip = chip(f, true)
	sealChip:SetPoint("LEFT", auraChip, "RIGHT", 4, 0)
	chipEnter(rfChip); chipEnter(auraChip); chipEnter(sealChip)
	-- cycling the bar aura IS an aura assignment (PallyPower parity):
	-- it lands in Comm.aa and goes out on the wire as AASSIGN. Blind
	-- 1..8 like the reference - the pick is a preference, not a cast check
	local function cycleAuraAssign(step)
		local cur = Comm.aa[me()] or 0
		cur = step > 0 and (cur % 8 + 1) or (cur - 1)
		if cur < 1 then cur = 8 end
		Comm.SetAura(me(), cur)
	end
	auraChip.cycle:SetScript("OnClick", function() cycleAuraAssign(1) end)
	auraChip.cycle:SetScript("OnMouseWheel", function(_, d) cycleAuraAssign(d > 0 and 1 or -1) end)
	sealChip.cycle:SetScript("OnClick", function()
		cycle(D.Seals, "seal", paintSealChip, 1)
	end)
	sealChip.cycle:SetScript("OnMouseWheel", function(_, d)
		cycle(D.Seals, "seal", paintSealChip, d > 0 and 1 or -1)
	end)

	S.Movers.Register(f, "blessings.bar", L["Blessings"])
	return f
end

-- ---------------------------------------------------------------------------
-- assignment grid
-- ---------------------------------------------------------------------------

local function gridCell(parent, r, c)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(CELL - 4, CELL - 4)
	b:SetPoint("TOPLEFT", GRID_LEFT + (c - 1) * CELL, -54 - (r - 1) * CELL)
	S.Template(b, "inset")
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	b.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	return b
end

local function cycleBless(pname, cid, back)
	if not Comm.CanControl(pname) then return end
	local cur = (Comm.ga[pname] or {})[cid] or 0
	local info = Comm.pallies[pname]
	local nxt = cur
	for _ = 0, 7 do
		nxt = back and (nxt - 1) or (nxt + 1)
		if nxt < 0 then nxt = 6 elseif nxt > 6 then nxt = 0 end
		if nxt == 0 or pname == me() or (info and info[nxt] and (info[nxt].rank or 0) > 0) then break end
		if nxt == cur then break end
	end
	Comm.SetClass(pname, cid, nxt)
end

local function cycleAuraCell(pname, back)
	if not Comm.CanControl(pname) then return end
	local info = Comm.pallies[pname]
	local cur = Comm.aa[pname] or 0
	for _ = 1, 8 do
		cur = back and (cur - 1) or (cur + 1)
		if cur < 0 then cur = 8 elseif cur > 8 then cur = 0 end
		-- own row cycles freely; other paladins only through auras they
		-- reported knowing in their ASELF block
		local ai = info and info.AuraInfo and info.AuraInfo[cur]
		if cur == 0 or pname == me()
			or (ai and (ai.rank or 0) > 0) then break end
	end
	Comm.SetAura(pname, cur)
end

local function paintGrid()
	if not grid then return end
	local f = grid
	local list = pallyOrder()
	for r, pname in ipairs(list) do
		local nameFs = gridNames[r]
		if not nameFs then
			nameFs = S.Font(f, 10, C.text)
			nameFs:SetPoint("TOPLEFT", 12, -58 - (r - 1) * CELL)
			nameFs:SetWidth(GRID_LEFT - 16)
			nameFs:SetJustifyH("LEFT")
			gridNames[r] = nameFs
		end
		local nc = pname == me() and C.accent or C.text
		nameFs:SetText(pname)
		nameFs:SetTextColor(nc.r, nc.g, nc.b)
		nameFs:Show()
		local can = Comm.CanControl(pname)
		for cid = 1, D.MAXCLASSES do
			local idx = r * 100 + cid
			local cell = gridCells[idx]
			if not cell then cell = gridCell(f, r, cid) gridCells[idx] = cell end
			local b = (Comm.ga[pname] or {})[cid] or 0
			if b > 0 and D.Blessings[b] then
				cell.icon:SetTexture(D.Blessings[b].icon)
				cell.icon:SetDesaturated(false)
				cell.icon:SetAlpha(1)
			else
				cell.icon:SetTexture(D.Blessings[1].icon)
				cell.icon:SetDesaturated(true)
				cell.icon:SetAlpha(0.15)
			end
			cell:SetAlpha(can and 1 or 0.7)
			cell:SetScript("OnClick", function(_, btn)
				cycleBless(pname, cid, btn == "RightButton")
			end)
			cell:SetScript("OnEnter", function(self)
				if not GameTooltip then return end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(pname .. " - " .. className(D.ClassID[cid]))
				GameTooltip:AddLine(b > 0 and blessingName(b) or L["none"], 0.8, 0.8, 0.8)
				if can then
					GameTooltip:AddLine(L["Left: next - right: previous"], 0.55, 0.55, 0.55)
				end
				GameTooltip:Show()
			end)
			cell:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
			cell:Show()
		end
		local ab = gridAuras[r]
		if not ab then ab = gridCell(f, r, D.MAXCLASSES + 1) gridAuras[r] = ab end
		local a = Comm.aa[pname] or 0
		if a > 0 and D.Auras[a] then
			ab.icon:SetTexture(D.Auras[a].icon)
			ab.icon:SetDesaturated(false)
			ab.icon:SetAlpha(1)
		else
			ab.icon:SetTexture(D.Auras[1].icon)
			ab.icon:SetDesaturated(true)
			ab.icon:SetAlpha(0.15)
		end
		ab:SetAlpha(can and 1 or 0.7)
		ab:SetScript("OnClick", function(_, btn)
			cycleAuraCell(pname, btn == "RightButton")
		end)
		ab:SetScript("OnEnter", function(self)
			if not GameTooltip then return end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(pname .. " - " .. L["Aura"])
			GameTooltip:AddLine(a > 0 and D.Auras[a]
				and D.SpellName(D.Auras[a].id) or L["none"], 0.8, 0.8, 0.8)
			if can then
				GameTooltip:AddLine(L["Left: next - right: previous"], 0.55, 0.55, 0.55)
			end
			GameTooltip:Show()
		end)
		ab:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
		ab:Show()
	end
	for r = #list + 1, #gridNames do
		gridNames[r]:Hide()
		for cid = 1, D.MAXCLASSES do
			local c = gridCells[r * 100 + cid]
			if c then c:Hide() end
		end
		if gridAuras[r] then gridAuras[r]:Hide() end
	end
	f:SetHeight(92 + math.max(#list, 1) * CELL)
	f.symTxt:SetText("|cffebad33" .. D.ItemCount(D.SYMBOL_ITEM) .. "|r")
	freeChk:SetChecked(db.freeassign == true)
end

local CLASS_PRIO = {
	WARRIOR = { 2, 4, 5, 3, 1 }, ROGUE = { 2, 4, 3, 1, 5 },
	PRIEST = { 1, 4, 3, 5, 2 }, DRUID = { 1, 4, 3, 5, 2 },
	PALADIN = { 3, 4, 1, 2, 5 }, HUNTER = { 2, 4, 3, 1, 5 },
	MAGE = { 1, 4, 3, 5, 2 }, WARLOCK = { 1, 4, 3, 5, 2 },
	SHAMAN = { 1, 2, 4, 3, 5 },
}

local function autoAssign()
	local pallies = pallyOrder()
	if #pallies == 0 then return end
	for cid = 1, D.MAXCLASSES do
		local prio = CLASS_PRIO[D.ClassID[cid]]
		for j, pname in ipairs(pallies) do
			if Comm.CanControl(pname) then
				local skills = Comm.pallies[pname] or {}
				local pick = 0
				local want = prio and prio[j]
				if want and skills[want] then pick = want end
				Comm.SetClass(pname, cid, pick)
			end
		end
	end
end

local blessShort = { "Wis", "Mgt", "Kgs", "Slv", "Lgt", "Sct" }
local classShort = { "WAR", "ROG", "PRI", "DRU", "PAL", "HUN", "MAG", "WLK", "SHA" }

local function report()
	if not SendChatMessage then return end
	local chan = db.reportChannel ~= "auto" and string.upper(db.reportChannel)
		or (IsInRaid() and "RAID" or "PARTY")
	pcall(SendChatMessage, "SentiUI Blessings:", chan)
	for _, name in ipairs(pallyOrder()) do
		local bits = {}
		for cid = 1, D.MAXCLASSES do
			local b = (Comm.ga[name] or {})[cid]
			if b and b > 0 and b <= 6 then
				bits[#bits + 1] = classShort[cid] .. ":" .. blessShort[b]
			end
		end
		local a = Comm.aa[name]
		if a and a > 0 and D.Auras[a] then
			bits[#bits + 1] = "A:" .. (D.SpellName(D.Auras[a].id) or a)
		end
		if #bits > 0 then
			pcall(SendChatMessage, name .. ": " .. table.concat(bits, " "), chan)
		end
	end
end

local function buildGrid()
	if grid then return grid end
	local f = CreateFrame("Frame", "SentiUIPallyGrid", UIParent, "BackdropTemplate")
	grid = f
	f:SetSize(GRID_LEFT + (D.MAXCLASSES + 1) * CELL + 8, 200)
	f:SetPoint("CENTER", -420, 60)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:Hide()
	S.Template(f, "panel")
	S.EscClosable(f)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		local y = select(2, GetCursorPosition()) / self:GetEffectiveScale()
		if y > self:GetTop() - 40 and not InCombatLockdown() then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		S.RunOutOfCombat(function()
			self:StopMovingOrSizing()
			S.Movers.Save("blessings.grid")
		end)
	end)

	local t = S.Font(f, 12, C.accent)
	t:SetPoint("TOPLEFT", 10, -8)
	t:SetText(L["Assignments"])
	f.symTxt = S.Font(f, 10, C.textDim)
	f.symTxt:SetPoint("RIGHT", f, "TOPRIGHT", -32, -11)

	W.Close(f, function()
		gridShown = false
		S.RunOutOfCombat(function() f:Hide() end)
	end):SetPoint("TOPRIGHT", -8, -7)

	local hairline = S.Line(f, C.accent)
	hairline:SetPoint("TOPLEFT", 10, -30)
	hairline:SetPoint("TOPRIGHT", -10, -30)

	-- column headers: class icons + an aura header
	hdrIcons = {}
	for cid = 1, D.MAXCLASSES do
		local tex = f:CreateTexture(nil, "ARTWORK")
		tex:SetSize(16, 16)
		tex:SetPoint("TOPLEFT", GRID_LEFT + (cid - 1) * CELL + 2, -36)
		tex:SetTexture(D.ClassIcons[cid])
		tex:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		hdrIcons[cid] = tex
	end
	hdrAura = f:CreateTexture(nil, "ARTWORK")
	hdrAura:SetSize(16, 16)
	hdrAura:SetPoint("TOPLEFT", GRID_LEFT + D.MAXCLASSES * CELL + 2, -36)
	hdrAura:SetTexture(D.Auras[1].icon)
	hdrAura:SetTexCoord(0.06, 0.94, 0.06, 0.94)

	-- footer, measured so nothing overlaps
	footRow = CreateFrame("Frame", nil, f)
	footRow:SetPoint("BOTTOMLEFT", EDGE, EDGE)
	footRow:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
	footRow:SetHeight(22)
	local measure = S.Font(footRow, 10)
	local function textW(s)
		measure:SetText(s or "")
		return math.ceil(measure:GetStringWidth())
	end
	local fx = 0
	local function fbtn(label, fn)
		-- W.Button auto-grows to its caption (FitWidth) - advance by the
		-- REAL width or the next button overlaps
		local b = W.Button(footRow, label, 40, 20)
		b:SetPoint("LEFT", fx, 0)
		b:SetScript("OnClick", fn)
		fx = fx + b:GetWidth() + 6
		return b
	end
	fbtn(L["Auto-Assign"], autoAssign)
	fbtn(L["Clear"], function() Comm.Clear() end)
	fbtn(L["Report"], report)
	freeChk = W.Check(footRow)
	freeChk:SetPoint("LEFT", fx, 2)
	freeChk.onChanged = function(on)
		db.freeassign = on and true or false
		Comm.ScanSelf()
		Comm.SendSelf()
	end
	local fl = S.Font(footRow, 10, C.textDim)
	fl:SetPoint("LEFT", freeChk, "RIGHT", 4, 0)
	fl:SetJustifyH("LEFT")
	fl:SetText(L["Free assignment"])
	fx = fx + 16 + 4 + textW(L["Free assignment"]) + 6
	local refresh = W.Button(footRow, L["Refresh"], 40, 20)
	refresh:SetPoint("RIGHT", 0, 0)
	refresh:SetScript("OnClick", function()
		Comm.ScanSelf()
		Comm.SendSelf()
		Comm.Send("REQ")
		UI.Refresh()
	end)
	minW = fx + refresh:GetWidth() + EDGE * 2

	S.Movers.Register(f, "blessings.grid", L["Assignments"])
	return f
end

-- ---------------------------------------------------------------------------
-- refresh / visibility
-- ---------------------------------------------------------------------------

local function wantsBar()
	if not (db and db.enabled and Comm.isPaladin()) then return false end
	if (GetNumGroupMembers and GetNumGroupMembers() or 0) > 0 then return db.showParty end
	return db.showSolo
end

local refreshing
function UI.Refresh()
	if refreshing then return end
	-- every layout op below touches protected frames (the bar and its rows
	-- contain secure buttons): in combat the clicks still work off the last
	-- set attributes, but repainting must wait for PLAYER_REGEN_ENABLED
	if InCombatLockdown() then S.RunOutOfCombat(UI.Refresh) return end
	refreshing = true
	pcall(function()
		playerName = ShortName(D.UnitName("player") or UnitName("player"))
		roster = Comm.roster or D.Roster()
		Comm.roster = roster
		Comm.leaders = roster.leaders
		if Comm.ga[playerName] then db.assign = Comm.ga[playerName] end
		if Comm.na[playerName] then db.normals = Comm.na[playerName] end
		if Comm.aa[playerName] then db.auraAssign = Comm.aa[playerName] end

		if not wantsBar() or manualHideBar then
			if bar then bar:Hide() end
		else
			local f = buildBar()
			paintAuraChip(); paintSealChip(); paintRFChip()
			f.sym:SetText("|cffebad33" .. D.ItemCount(D.SYMBOL_ITEM) .. "|r")
			local shown = paintBarRows()
			f:SetHeight(46 + math.max(shown, 1) * (ROW_H + 1))
			f:SetShown(shown > 0)
		end

		if gridShown then
			buildGrid()
			local w = math.max(minW, GRID_LEFT + (D.MAXCLASSES + 1) * CELL + 16)
			grid:SetWidth(w)
			paintGrid()
			grid:Show()
		end
	end)
	refreshing = nil
end

function UI.ToggleGrid()
	gridShown = not gridShown
	if not gridShown and grid then
		S.RunOutOfCombat(function() grid:Hide() end)
	end
	UI.Refresh()
end

function UI.Toggle()
	manualHideBar = not manualHideBar
	if manualHideBar and bar then
		S.RunOutOfCombat(function() bar:Hide() end)
		return
	end
	UI.Refresh()
end

-- ---------------------------------------------------------------------------
-- enable
-- ---------------------------------------------------------------------------

function Core.Enable(mod)
	db = mod.db
	if not Comm.isPaladin() then return end
	Comm.Enable(mod)

	local pending
	local function soon()
		if pending then return end
		pending = true
		C_Timer.After(0.3, function()
			pending = nil
			if roster then
				for _, list in pairs(roster.classes) do
					for _, m in ipairs(list) do m.auras = nil end
				end
			end
			UI.Refresh()
		end)
	end
	S.RegisterEvent("UNIT_AURA", function(_, unit)
		if unit and (unit == "player" or unit:sub(1, 4) == "raid" or unit:sub(1, 5) == "party") then
			soon()
		end
	end)
	S.RegisterEvent("GROUP_ROSTER_UPDATE", soon)
	S.RegisterEvent("SPELLS_CHANGED", function()
		paintAuraChip(); paintSealChip(); paintRFChip(); soon()
	end)
	S.RegisterEvent("BAG_UPDATE", soon)
	S.RegisterEvent("PLAYER_ENTERING_WORLD", soon)
	S.RegisterEvent("PLAYER_REGEN_ENABLED", UI.Refresh)

	SLASH_SENTIPALLY1 = "/sp"
	SlashCmdList["SENTIPALLY"] = function(msg)
		if (msg or ""):lower() == "bar" then UI.Toggle()
		else UI.ToggleGrid() end
	end

	C_Timer.After(1.5, UI.Refresh)
end

function Core.SettingChanged()
	UI.Refresh()
end
