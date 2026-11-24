-- The professions window. The game still runs the trade skill: casting a
-- profession spell opens it (TRADE_SKILL_SHOW), Forever's ProfessionsFrame
-- shows, and its OnHide closes the trade skill. That frame is held aside
-- (alpha 0 + moved off screen: it stays "shown" so its scripts keep
-- running, and its invisible children can't steal clicks) while this
-- window stands in for it. Guild lists, NPC crafting and linked
-- professions are lent back to the game's window.
--
-- Tabs switch professions by casting the profession's spell from a secure
-- button laid over the tab, as the game's own tabs do; OpenTradeSkill is
-- only the fallback because it needs a hardware event.
local _, ns = ...
local S = SentiUI
local L = ns.L
local C = S.colors
local W = S.Widgets
local D = ns.Data

local Core = {}
ns.Core = Core

local db
Core.WIN_W, Core.WIN_H = 720, 560
local EDGE = 10
local LIST_W = 300
local ROW_H = 36
local HEAD_H = 22

local win                    -- the window frame
local parked = false         -- game's frame held aside
local data                   -- last Data.Read() result
local picked                 -- selected recipe id (per profession, session)
local pickedByProf = {}
local rowPool, headPool = {}, {}
local listSF, listRows, listHeads
local searchBox, chipSkill, chipMats, chipSlot, slotChipText
local filterText, chipOn = nil, { skill = false, mats = false }
local slotIndex, inSlot, slots
local shownProf

-- ---------------------------------------------------------------------------
-- small helpers
-- ---------------------------------------------------------------------------

local function game()
	local g = _G.ProfessionsFrame
	return type(g) == "table" and g or nil
end

-- alpha alone keeps the game frame "shown" but its children still hit-test:
-- an invisible Blizzard list would eat every click over our window. So the
-- frame is parked OFF SCREEN - shown, alive, but nowhere near the pointer.
local parkTicker
local function parkGame(g)
	if not g then return end
	parked = true
	g:SetAlpha(0)
	if g.EnableMouse then g:EnableMouse(false) end
	pcall(function()
		g:ClearAllPoints()
		g:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", 0, 0)
	end)
	-- the game (or another addon) can re-anchor it; keep it parked
	if not parkTicker then
		parkTicker = C_Timer.NewTicker(0.5, function()
			if not parked then return end
			local gg = game()
			if gg and gg:IsShown() then
				local l = gg:GetLeft()
				if l and l < (UIParent:GetRight() or 0) - 10 then
					pcall(function()
						gg:ClearAllPoints()
						gg:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", 0, 0)
					end)
				end
			end
		end)
	end
end

local function unparkGame(g)
	g = g or game()
	if not (parked and g) then return end
	parked = false
	if parkTicker then parkTicker:Cancel() parkTicker = nil end
	g:SetAlpha(1)
	if g.EnableMouse then g:EnableMouse(true) end
	-- back to the game's own left-panel spot
	pcall(function()
		g:ClearAllPoints()
		g:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116)
	end)
end

-- ---------------------------------------------------------------------------
-- context menu (same pattern as the messenger's row menu)
-- ---------------------------------------------------------------------------

local menu, menuCatch
local function CloseMenu()
	if menu then menu:Hide() end
	if menuCatch then menuCatch:Hide() end
end

local function ShowMenu(items, anchor)
	if not menu then
		menuCatch = CreateFrame("Button", nil, UIParent)
		menuCatch:SetAllPoints(UIParent)
		menuCatch:SetFrameStrata("TOOLTIP")
		menuCatch:SetFrameLevel(1)
		menuCatch:RegisterForClicks("AnyUp", "AnyDown")
		menuCatch:SetScript("OnClick", CloseMenu)
		menuCatch:Hide()
		menu = CreateFrame("Frame", "SentiUICraftMenu", UIParent, "BackdropTemplate")
		menu:SetFrameStrata("TOOLTIP")
		menu:SetFrameLevel(10)
		menu:SetToplevel(true)
		menu:EnableMouse(true)
		S.Template(menu, "panel")
		S.EscClosable(menu)
		menu.items = {}
	end
	for _, b in ipairs(menu.items) do b:Hide() end
	local y = 4
	local widest = 90
	for i, it in ipairs(items) do
		local b = menu.items[i]
		if not b then
			b = CreateFrame("Button", nil, menu, "BackdropTemplate")
			S.Template(b, "inset")
			b.label = S.Font(b, 11, C.text)
			b.label:SetPoint("LEFT", 8, 0)
			b.label:SetJustifyH("LEFT")
			b:SetScript("OnEnter", function(s) S.SetBorderLit(s, true) end)
			b:SetScript("OnLeave", function(s) S.SetBorderLit(s, false) end)
			menu.items[i] = b
		end
		b:SetPoint("TOPLEFT", 4, -y)
		b:SetHeight(20)
		b.label:SetText(it.text)
		b.label:SetTextColor(it.title and C.accent.r or C.text.r,
			it.title and C.accent.g or C.text.g, it.title and C.accent.b or C.text.b)
		b:EnableMouse(not it.title)
		b:SetScript("OnClick", function()
			CloseMenu()
			if it.fn then it.fn() end
		end)
		widest = math.max(widest, (b.label:GetStringWidth() or 0) + 20)
		y = y + 21
	end
	menu:SetSize(widest, y + 4)
	for _, b in ipairs(menu.items) do if b:IsShown() then b:SetWidth(widest - 8) end end
	menu:ClearAllPoints()
	menu:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 0, 0)
	menu:Show()
	menuCatch:Show()
end

-- ---------------------------------------------------------------------------
-- list filtering
-- ---------------------------------------------------------------------------

local function keep(r)
	if chipOn.skill and not D.SkillsUp(r) then return false end
	if chipOn.mats and r.count <= 0 then return false end
	if inSlot and not inSlot[r.id] then return false end
	if filterText and not string.find(string.lower(r.name), filterText, 1, true) then
		return false
	end
	return true
end

local function folds() return db.collapsed end
local function foldKey(sec)
	return (data and data.prof and data.prof.name or "") .. ":" .. (sec.name or "")
end

-- ---------------------------------------------------------------------------
-- list rows
-- ---------------------------------------------------------------------------

local function rowAt(i)
	local r = rowPool[i]
	if r then return r end
	local child = listSF:GetScrollChild()
	r = CreateFrame("Button", nil, child, "BackdropTemplate")
	r:SetHeight(ROW_H)
	r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	S.Template(r, "inset")
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetSize(26, 26)
	r.icon:SetPoint("LEFT", 6, 0)
	r.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	r.name = S.Font(r, 11)
	r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -2)
	r.name:SetPoint("RIGHT", r, "RIGHT", -34, 0)
	r.name:SetJustifyH("LEFT")
	r.name:SetWordWrap(false)
	r.sub = S.Font(r, 9, C.textDim)
	r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -1)
	r.sub:SetPoint("RIGHT", r, "RIGHT", -34, 0)
	r.sub:SetJustifyH("LEFT")
	r.sub:SetWordWrap(false)
	r.count = S.Font(r, 11, C.accent)
	r.count:SetPoint("RIGHT", -8, 0)
	r:SetScript("OnEnter", function(self)
		if not self.picked then S.SetBorderLit(self, true) end
		local rr = self.recipe
		if rr and GameTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if type(GameTooltip.SetRecipeResultItem) == "function" then
				GameTooltip:SetRecipeResultItem(rr.id)
			elseif rr.link and type(GameTooltip.SetHyperlink) == "function" then
				GameTooltip:SetHyperlink(rr.link)
			end
			GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", function(self)
		if not self.picked then S.SetBorderLit(self, false) end
		if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)
	r:SetScript("OnClick", function(self, btn)
		local rr = self.recipe
		if not rr then return end
		if btn == "RightButton" then
			local items = { { text = rr.name, title = true } }
			if D.CanFavorite() then
				items[#items + 1] = {
					text = rr.favorite and (BATTLE_PET_UNFAVORITE or L["Remove Favorite"])
						or (BATTLE_PET_FAVORITE or L["Set Favorite"]),
					fn = function()
						D.SetFavorite(rr.id, not rr.favorite)
						Core.Soon()
					end }
			end
			if D.CanTrack(rr) then
				items[#items + 1] = {
					text = D.IsTracked(rr.id) and (PROFESSIONS_UNTRACK_RECIPE or L["Untrack"])
						or (PROFESSIONS_TRACK_RECIPE or L["Track Recipe"]),
					fn = function() D.SetTracked(rr.id, not D.IsTracked(rr.id)) end }
			end
			if #items > 1 then ShowMenu(items, self) end
			return
		end
		if IsModifiedClick and IsModifiedClick("CHATLINK") then
			local link = D.RecipeLink(rr)
			local insert = ChatFrameUtil and ChatFrameUtil.InsertLink or ChatEdit_InsertLink
			if link and type(insert) == "function" then insert(link) end
			return
		end
		Core.Pick(rr.id)
	end)
	rowPool[i] = r
	return r
end

local function headAt(i)
	local h = headPool[i]
	if h then return h end
	local child = listSF:GetScrollChild()
	h = CreateFrame("Button", nil, child)
	h:SetHeight(HEAD_H)
	h:RegisterForClicks("LeftButtonUp")
	h.label = S.Font(h, 10, C.accent)
	h.label:SetPoint("LEFT", 4, 0)
	h.line = h:CreateTexture(nil, "ARTWORK")
	h.line:SetTexture(S.media.blank)
	h.line:SetHeight(1)
	h.line:SetPoint("BOTTOMLEFT", h, "BOTTOMLEFT", 4, 3)
	h.line:SetPoint("BOTTOMRIGHT", h, "BOTTOMRIGHT", -4, 3)
	h.line:SetVertexColor(C.border.r, C.border.g, C.border.b, 1)
	h:SetScript("OnClick", function(self)
		if self.section then
			local k = foldKey(self.section)
			folds()[k] = not folds()[k] or nil
			Core.RenderList(true)
		end
	end)
	headPool[i] = h
	return h
end

function Core.RenderList(keepScroll)
	if not listSF then return end
	local child = listSF:GetScrollChild()
	local w = math.max(child:GetWidth(), LIST_W - 30)
	local y = 0
	local ri, hi = 0, 0
	listRows = {}
	for _, sec in ipairs(data and data.sections or {}) do
		local shown = {}
		for _, r in ipairs(sec.recipes) do
			if keep(r) then shown[#shown + 1] = r end
		end
		if #shown > 0 then
			hi = hi + 1
			local h = headAt(hi)
			h.section = sec
			local folded = not filterText and folds()[foldKey(sec)]
			h.label:SetText((folded and "+ " or "") .. string.upper(sec.name or ""))
			h:ClearAllPoints()
			h:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
			h:SetWidth(w)
			h:Show()
			y = y + HEAD_H
			if not folded then
				for _, r in ipairs(shown) do
					ri = ri + 1
					local b = rowAt(ri)
					b.recipe = r
					b.picked = r.id == picked
					b.icon:SetTexture(r.icon)
					local col
					if db.rarityNames then
						local q = D.OutputQuality(r.id)
						if q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] then
							local qc = ITEM_QUALITY_COLORS[q]
							col = { qc.r, qc.g, qc.b }
						end
					end
					col = col or D.Color(r.difficulty)
					b.name:SetText(r.name)
					b.name:SetTextColor(col[1], col[2], col[3])
					b.sub:SetText(r.sub)
					b.count:SetText(r.count > 0 and tostring(r.count) or "")
					S.SetBorderLit(b, b.picked)
					b:ClearAllPoints()
					b:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
					b:SetWidth(w)
					b:Show()
					listRows[r.id] = b
					y = y + ROW_H
				end
			end
		end
	end
	for i = ri + 1, #rowPool do rowPool[i]:Hide() end
	for i = hi + 1, #headPool do headPool[i]:Hide() end
	child:SetHeight(math.max(y, 1))
	if listNote then
		local empty = y == 0
		listNote:SetShown(empty)
		if empty then
			local filtered = filterText or chipOn.skill or chipOn.mats or slotIndex
			listNote:SetText(data and data.prof
				and (filtered and L["No recipes match."] or L["No recipes yet."])
				or L["Pick a profession above."])
		end
	end
	if not keepScroll and listSF.Scroll then listSF:Scroll(0) end
end

-- ---------------------------------------------------------------------------
-- recipe side (right pane)
-- ---------------------------------------------------------------------------

local rIcon, rName, rDiff, rCD, rOut, matRows = nil, nil, nil, nil, nil, {}
local footCreate, footAll, numBox, progRow, progBar, progText
local listNote

local function matRowAt(i)
	local r = matRows[i]
	if r then return r end
	r = CreateFrame("Frame", nil, rOut:GetParent())
	r:SetHeight(20)
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetSize(16, 16)
	r.icon:SetPoint("LEFT", 0, 0)
	r.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	r.name = S.Font(r, 10)
	r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
	r.name:SetJustifyH("LEFT")
	r.have = S.Font(r, 10, C.textDim)
	r.have:SetPoint("RIGHT", 0, 0)
	matRows[i] = r
	return r
end

local crafting          -- { id, total, done, from, to }
local amount = 1

local function paintFooter(r)
	if not footCreate then return end
	local many = r and not r.enchant
	local canMake = r and r.count > 0 and not D.Waiting(r.id)
	footCreate:SetShown(r ~= nil and not crafting)
	footAll:SetShown(many and not crafting)
	numBox:SetShown(many and not crafting)
	if r then
		local verb = r.enchant and (CREATE_PROFESSION_ENCHANT or L["Enchant"])
			or r.verb or (CREATE_PROFESSION or L["Create"])
		footCreate:SetText(verb)
		local allWord = r.enchant and PROFESSIONS_ENCHANT_ALL or PROFESSIONS_CREATE_ALL
		footAll:SetText((PROFESSIONS_CREATE_ALL_FORMAT or "%s [%d]"):format(allWord or L["Create all"], r.count))
		footCreate:SetAlpha(canMake and 1 or 0.45)
		footAll:SetAlpha((many and r.count > 1 and not D.Waiting(r.id)) and 1 or 0.45)
	end
end

local function progress(on)
	if not progRow then return end
	progRow:SetShown(on)
	footCreate:SetShown(not on)
	footAll:SetShown(not on)
	numBox:SetShown(not on)
	if on and crafting then
		progText:SetText(string.format(L["Making %d of %d"],
			math.min(crafting.done + 1, crafting.total), crafting.total))
	end
end

local function craftEnd()
	crafting = nil
	progress(false)
	local r = data and data.byID and picked and data.byID[picked]
	paintFooter(r)
end

local function craftStart(r, n)
	if not r or n < 1 or crafting then return end
	crafting = { id = r.id, total = n, done = 0 }
	if r.enchant and D.Has("CraftEnchant") then
		D.Call("CraftEnchant", r.id, n)
	else
		D.Call("CraftRecipe", r.id, n)
	end
	progress(true)
end

local function onCast(event, unit, _, spellID)
	if unit ~= "player" or (S.IsSecret and S.IsSecret(spellID)) then return end
	local s = crafting
	if not s or spellID ~= s.id then return end
	if event == "UNIT_SPELLCAST_START" then
		local _, _, _, from, to = UnitCastingInfo("player")
		if type(from) == "number" and type(to) == "number" and to > from
			and not (S.IsSecret and (S.IsSecret(from) or S.IsSecret(to))) then
			s.from, s.to = from, to
			progBar:SetMinMaxValues(from, to)
		end
		progText:SetText(string.format(L["Making %d of %d"],
			math.min(s.done + 1, s.total), s.total))
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		s.done = s.done + 1
		if s.done >= s.total then return craftEnd() end
		progText:SetText(string.format(L["Making %d of %d"],
			math.min(s.done + 1, s.total), s.total))
	else
		craftEnd()
	end
end

local function fillRecipe(r)
	if not rName then return end
	if not r then
		rIcon:Hide()
		rName:SetText("")
		rDiff:SetText("")
		rCD:SetText("")
		rOut:Hide()
		for _, m in ipairs(matRows) do m:Hide() end
		paintFooter(nil)
		return
	end
	rIcon:Show()
	rIcon:SetTexture(r.icon)
	rName:SetText(r.name)
	local col = D.Color(r.difficulty)
	rName:SetTextColor(col[1], col[2], col[3])
	rDiff:SetText(D.SkillWords(r.difficulty))
	rDiff:SetTextColor(col[1], col[2], col[3])
	local left = D.Cooldown(r.id)
	rCD:SetText(left and string.format("|cffff5555%s|r", SecondsToTime and SecondsToTime(left) or (left .. "s")) or "")
	-- output item
	local itemID = D.OutputItem(r.id)
	if itemID and C_Item and C_Item.GetItemNameByID then
		local nm = C_Item.GetItemNameByID(itemID)
		if nm then
			rOut:Show()
			rOut.itemID = itemID
			rOut.icon:SetTexture(C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID) or r.icon)
			rOut.label:SetText(nm)
			local q = D.OutputQuality(r.id)
			if q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q] then
				local qc = ITEM_QUALITY_COLORS[q]
				rOut.label:SetTextColor(qc.r, qc.g, qc.b)
			else
				rOut.label:SetTextColor(C.text.r, C.text.g, C.text.b)
			end
		else
			rOut:Hide()
		end
	else
		rOut:Hide()
	end
	-- materials, each under the last
	local above = rOut:IsShown() and rOut or rDiff
	for i, m in ipairs(r.mats) do
		local row = matRowAt(i)
		row.icon:SetTexture(m.icon)
		row.name:SetText(m.name or ("item:" .. m.itemID))
		local short = m.have < m.need
		row.have:SetText(m.have .. "/" .. m.need)
		row.have:SetTextColor(short and C.red.r or C.textDim.r,
			short and C.red.g or C.textDim.g, short and C.red.b or C.textDim.b)
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, i == 1 and -10 or -2)
		row:SetPoint("TOPRIGHT", above, "BOTTOMRIGHT", 0, i == 1 and -10 or -2)
		row:Show()
		above = row
	end
	for i = #r.mats + 1, #matRows do matRows[i]:Hide() end
	amount = 1
	paintFooter(r)
end

function Core.Pick(id)
	picked = id
	if data and data.prof then pickedByProf[data.prof.id] = id end
	for rid, b in pairs(listRows or {}) do
		if b:IsShown() then
			b.picked = rid == id
			S.SetBorderLit(b, b.picked)
		end
	end
	fillRecipe(data and data.byID and data.byID[id])
end

-- ---------------------------------------------------------------------------
-- header: profession icon/name, skill bar, unlearn, tabs
-- ---------------------------------------------------------------------------

local titleIcon, titleName, titleSub, skillBar, unlearnBtn, tabsRow
local tabs = {}

local function tabFor(prof)
	for _, t in ipairs(tabs) do
		if prof and t.skillLine == prof.id then return t end
	end
	return nil
end

local function confirmUnlearn()
	local tab = tabFor(data and data.prof)
	if not (tab and tab.primary) then return end
	local abandon = C_SkillInfo and C_SkillInfo.AbandonSkill or _G.AbandonSkill
	if type(abandon) ~= "function" then return end
	if not StaticPopupDialogs["SENTIUI_UNLEARN_PROFESSION"] then
		StaticPopupDialogs["SENTIUI_UNLEARN_PROFESSION"] = {
			text = UNLEARN_SKILL or L["Do you really want to unlearn %s?"],
			button1 = YES or "Yes", button2 = NO or "No",
			OnAccept = function(_, skillLine) abandon(skillLine) end,
			timeout = 0, whileDead = 1, hideOnEscape = 1,
		}
	end
	StaticPopup_Show("SENTIUI_UNLEARN_PROFESSION", tab.name, nil, tab.skillLine)
end

local function paintHeader()
	local prof = data and data.prof
	if not prof then
		titleIcon:Hide()
		titleName:SetText(TRADE_SKILLS or L["Professions"])
		titleName:SetTextColor(C.text.r, C.text.g, C.text.b)
		titleSub:SetText("")
		skillBar:Hide()
		unlearnBtn:Hide()
		return
	end
	titleIcon:Show()
	titleIcon:SetTexture(D.Icon(prof.id))
	titleName:SetText(prof.name)
	titleName:SetTextColor(C.accent.r, C.accent.g, C.accent.b)
	titleSub:SetText(string.format(L["Skill %d / %d"], prof.skill + prof.bonus, prof.max))
	skillBar:Show()
	skillBar:SetMinMaxValues(0, math.max(1, prof.max))
	skillBar:SetValue(math.min(prof.skill + prof.bonus, prof.max))
	local tab = tabFor(prof)
	unlearnBtn:SetShown(tab ~= nil and tab.primary == true)
end

-- A tab chip carries a secure spell-cast button (created out of combat) that
-- opens the profession the same way the game's tabs do. In combat the chip's
-- own click calls OpenTradeSkill - a click is a hardware event.
local function makeTab(i)
	local t = tabs[i]
	if t then return t end
	t = S.TabChip(tabsRow, 20)
	t.autoWidth = true
	-- fallback when the secure overlay is missing: a click is the
	-- hardware event OpenTradeSkill needs, out of combat and in a fight
	t:SetScript("OnClick", function(self)
		if self.skillLine then D.Call("OpenTradeSkill", self.skillLine) end
	end)
	if not InCombatLockdown() then
		local b = CreateFrame("Button", "SentiUICraftTab" .. i, t, "SecureActionButtonTemplate")
		b:SetAllPoints(t)
		-- both phases: whether the client honors useOnKeyDown or follows the
		-- key-down CVar, the spell fires on press or on release
		b:RegisterForClicks("AnyDown", "AnyUp")
		pcall(b.SetAttribute, b, "useOnKeyDown", false)
		b:SetFrameLevel(t:GetFrameLevel() + 2)
		-- attributes only, set at build - NO SetScript on a secure button:
		-- an insecurely stored handler taints the click dispatch and the
		-- cast is flagged FORBIDDEN (same lesson as S.SecureReload)
		t.secure = b
	end
	tabs[i] = t
	return t
end

local function buildTabs()
	local profTabs = D.Tabs()
	for _, t in ipairs(tabs) do t:Hide() end
	local x = 0
	for i, tt in ipairs(profTabs) do
		local b = makeTab(i)
		b.skillLine, b.spellID = tt.skillLine, tt.spellID
		b:SetLabel(tt.name)
		local open = data and data.prof
		local isOpen = open ~= nil and open.id == tt.skillLine
		b:SetSelected(isOpen)
		if b.secure and not InCombatLockdown() then
			-- every tab casts its profession spell; the open one's does
			-- nothing, so a click there can never toggle the window shut
			-- the secure spell attribute needs the spell NAME on this
			-- client, not the ID (same fix as SentiUI_Pally's cast chips)
			local cast = (not isOpen) and D.SpellName(tt.spellID) or nil
			pcall(b.secure.SetAttribute, b.secure, "type", cast and "spell" or nil)
			pcall(b.secure.SetAttribute, b.secure, "type1", cast and "spell" or nil)
			pcall(b.secure.SetAttribute, b.secure, "spell", cast)
		end
		b:ClearAllPoints()
		b:SetPoint("LEFT", tabsRow, "LEFT", x, 0)
		b:Show()
		x = x + b:GetWidth() + 4
	end
end

-- ---------------------------------------------------------------------------
-- the window
-- ---------------------------------------------------------------------------

local function buildWindow()
	if win then return win end
	local f = CreateFrame("Frame", "SentiUICraftWindow", UIParent, "BackdropTemplate")
	f:SetSize(Core.WIN_W, Core.WIN_H)
	f:SetPoint("CENTER", 60, 40)
	f:SetFrameStrata("DIALOG")
	f:SetToplevel(true)
	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:Hide()
	S.Template(f, "panel")
	S.EscClosable(f)

	-- drag by the title band - on the window itself, like the options
	-- panel: a full-width EnableMouse strip would win hit-testing and
	-- sit on the close X and the unlearn link (proven in the messenger)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		local y = select(2, GetCursorPosition()) / self:GetEffectiveScale()
		if y > self:GetTop() - 40 then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		S.Movers.Save("professions.window")
	end)

	titleIcon = f:CreateTexture(nil, "ARTWORK")
	titleIcon:SetSize(24, 24)
	titleIcon:SetPoint("TOPLEFT", 12, -8)
	titleIcon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	titleIcon:Hide()
	titleName = S.Font(f, 13, C.accent)
	titleName:SetPoint("LEFT", titleIcon, "RIGHT", 8, 6)
	titleSub = S.Font(f, 10, C.textDim)
	titleSub:SetPoint("TOPLEFT", titleName, "BOTTOMLEFT", 0, -1)

	skillBar = CreateFrame("StatusBar", nil, f)
	skillBar:SetSize(96, 8)
	skillBar:SetStatusBarTexture(S.media.blank)
	skillBar:SetStatusBarColor(C.accent.r, C.accent.g, C.accent.b)
	skillBar:SetPoint("LEFT", titleSub, "RIGHT", 10, 0)
	local sbBg = skillBar:CreateTexture(nil, "BACKGROUND")
	sbBg:SetAllPoints(skillBar)
	sbBg:SetTexture(S.media.blank)
	sbBg:SetVertexColor(C.border.r, C.border.g, C.border.b, 0.5)

	unlearnBtn = W.Button(f, L["Unlearn"], 60, 18)
	unlearnBtn:SetPoint("LEFT", skillBar, "RIGHT", 8, 0)
	unlearnBtn.label:SetTextColor(C.red.r, C.red.g, C.red.b)
	unlearnBtn:SetScript("OnClick", confirmUnlearn)
	unlearnBtn:Hide()

	W.Close(f, function() Core.Close() end):SetPoint("TOPRIGHT", -8, -7)

	local hairline = S.Line(f, C.accent)
	hairline:SetPoint("TOPLEFT", 10, -34)
	hairline:SetPoint("TOPRIGHT", -10, -34)

	-- profession tabs under the title line
	tabsRow = CreateFrame("Frame", nil, f)
	tabsRow:SetPoint("TOPLEFT", 12, -42)
	tabsRow:SetPoint("TOPRIGHT", -12, -42)
	tabsRow:SetHeight(22)

	-- left: search + chips + list
	searchBox = W.EditBox(f, LIST_W - 2 * EDGE, 24)
	searchBox.placeholder:SetText(L["Search..."])
	searchBox.holder:SetPoint("TOPLEFT", EDGE, -72)
	searchBox.onChanged = function(t)
		filterText = (type(t) == "string" and t ~= "") and string.lower(t) or nil
		Core.RenderList(true)
	end

	local function chip(label, x, onClick)
		local b = S.TabChip(f, 18)
		b.autoWidth = true
		b:SetLabel(label)
		b:SetPoint("TOPLEFT", x, -102)
		b:SetScript("OnClick", onClick)
		return b
	end
	chipSkill = chip(L["Skill-ups"], EDGE, function(self)
		chipOn.skill = not chipOn.skill
		self:SetSelected(chipOn.skill)
		Core.RenderList(true)
	end)
	chipMats = chip(L["Have materials"], EDGE + chipSkill:GetWidth() + 6, function(self)
		chipOn.mats = not chipOn.mats
		self:SetSelected(chipOn.mats)
		Core.RenderList(true)
	end)
	chipSlot = chip(L["Slot"], EDGE + chipSkill:GetWidth() + chipMats:GetWidth() + 12, function(self)
		local items = { { text = L["All slots"], fn = function() Core.PickSlot(nil) end } }
		for _, s in ipairs(slots or {}) do
			items[#items + 1] = { text = s.name, fn = function() Core.PickSlot(s.index) end }
		end
		ShowMenu(items, self)
	end)

	local lp = CreateFrame("Frame", nil, f, "BackdropTemplate")
	lp:SetPoint("TOPLEFT", EDGE, -126)
	lp:SetPoint("BOTTOMLEFT", EDGE, EDGE)
	lp:SetWidth(LIST_W - 2 * EDGE)
	S.Template(lp, "inset")
	listSF = W.Scroll(lp)
	listSF:SetPoint("TOPLEFT", 4, -4)
	listSF:SetPoint("BOTTOMRIGHT", -4, 4)
	listSF:GetScrollChild():SetWidth(LIST_W - 2 * EDGE - 8)
	listNote = S.Font(lp, 11, C.textDim)
	listNote:SetPoint("CENTER", lp, "CENTER", 0, 0)
	listNote:Hide()

	-- right: recipe page
	local rp = CreateFrame("Frame", nil, f, "BackdropTemplate")
	rp:SetPoint("TOPLEFT", lp, "TOPRIGHT", 8, 0)
	rp:SetPoint("BOTTOMRIGHT", -EDGE, EDGE + 44)
	S.Template(rp, "inset")

	rIcon = rp:CreateTexture(nil, "ARTWORK")
	rIcon:SetSize(32, 32)
	rIcon:SetPoint("TOPLEFT", 12, -12)
	rIcon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	rName = S.Font(rp, 13)
	rName:SetPoint("LEFT", rIcon, "RIGHT", 10, 8)
	rDiff = S.Font(rp, 10, C.textDim)
	rDiff:SetPoint("TOPLEFT", rName, "BOTTOMLEFT", 0, -2)
	rCD = S.Font(rp, 10)
	rCD:SetPoint("TOPRIGHT", -12, -14)

	-- the output item, clickable for its tooltip
	rOut = CreateFrame("Button", nil, rp, "BackdropTemplate")
	rOut:SetPoint("TOPLEFT", rDiff, "BOTTOMLEFT", 0, -10)
	rOut:SetPoint("TOPRIGHT", rp, "TOPRIGHT", -12, -10)
	rOut:SetHeight(24)
	S.Template(rOut, "raised")
	rOut.icon = rOut:CreateTexture(nil, "ARTWORK")
	rOut.icon:SetSize(18, 18)
	rOut.icon:SetPoint("LEFT", 4, 0)
	rOut.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	rOut.label = S.Font(rOut, 11)
	rOut.label:SetPoint("LEFT", rOut.icon, "RIGHT", 6, 0)
	rOut.label:SetJustifyH("LEFT")
	rOut:SetScript("OnEnter", function(self)
		if self.itemID and GameTooltip then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetItemByID(self.itemID)
			GameTooltip:Show()
		end
	end)
	rOut:SetScript("OnLeave", function(self)
		if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)
	rOut:Hide()

	-- footer: create / amount / create all / progress
	local foot = CreateFrame("Frame", nil, f)
	foot:SetPoint("BOTTOMLEFT", lp, "BOTTOMRIGHT", 8, 0)
	foot:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
	foot:SetHeight(36)

	footCreate = W.Button(foot, CREATE_PROFESSION or L["Create"], 120, 26)
	footCreate:SetPoint("LEFT", 0, 0)
	footCreate:SetScript("OnClick", function()
		local r = data and data.byID and picked and data.byID[picked]
		if r and r.count > 0 and not D.Waiting(r.id) then
			craftStart(r, r.enchant and 1 or amount)
		end
	end)

	numBox = CreateFrame("Frame", nil, foot)
	numBox:SetSize(88, 26)
	numBox:SetPoint("LEFT", footCreate, "RIGHT", 8, 0)
	numBox:EnableMouseWheel(true)
	local function step(d)
		local r = data and data.byID and picked and data.byID[picked]
		local most = r and math.max(1, r.count) or 1
		amount = math.max(1, math.min(most, (amount or 1) + d))
		numBox.num:SetText(tostring(amount))
	end
	numBox.less = W.Button(numBox, "-", 22, 24)
	numBox.less:SetPoint("LEFT")
	numBox.less:SetScript("OnClick", function() step(-1) end)
	numBox.num = S.Font(numBox, 12)
	numBox.num:SetPoint("CENTER")
	numBox.num:SetText("1")
	numBox.more = W.Button(numBox, "+", 22, 24)
	numBox.more:SetPoint("RIGHT")
	numBox.more:SetScript("OnClick", function() step(1) end)
	numBox:SetScript("OnMouseWheel", function(_, d) step(d > 0 and 1 or -1) end)

	footAll = W.Button(foot, L["Create all"], 110, 26)
	footAll:SetPoint("RIGHT", 0, 0)
	footAll:SetScript("OnClick", function()
		local r = data and data.byID and picked and data.byID[picked]
		if r and not r.enchant and r.count > 1 and not D.Waiting(r.id) then
			craftStart(r, r.count)
		end
	end)

	-- progress row while crafting (same spot as the buttons)
	progRow = CreateFrame("Frame", nil, foot)
	progRow:SetAllPoints(foot)
	progRow:Hide()
	progText = S.Font(progRow, 11)
	progText:SetPoint("LEFT", 0, 0)
	progBar = CreateFrame("StatusBar", nil, progRow)
	progBar:SetPoint("LEFT", 130, 0)
	progBar:SetPoint("RIGHT", -70, 0)
	progBar:SetHeight(10)
	progBar:SetStatusBarTexture(S.media.blank)
	progBar:SetStatusBarColor(C.accent.r, C.accent.g, C.accent.b)
	local pbBg = progBar:CreateTexture(nil, "BACKGROUND")
	pbBg:SetAllPoints(progBar)
	pbBg:SetTexture(S.media.blank)
	pbBg:SetVertexColor(C.border.r, C.border.g, C.border.b, 0.5)
	progRow:SetScript("OnUpdate", function()
		local s = crafting
		if not (s and s.from and s.to) then return end
		progBar:SetValue(math.max(s.from, math.min(s.to, GetTime() * 1000)))
	end)
	-- Stop needs a secure button: /stopcasting is protected, so a secure
	-- macro button laid over the label button (built out of combat).
	local stopLabel = W.Button(progRow, STOP or L["Stop"], 60, 22)
	stopLabel:SetPoint("RIGHT", 0, 0)
	if not InCombatLockdown() then
		local sb = CreateFrame("Button", "SentiUICraftStop", stopLabel, "SecureActionButtonTemplate")
		sb:SetAllPoints(stopLabel)
		sb:SetFrameLevel(stopLabel:GetFrameLevel() + 2)
		sb:RegisterForClicks("AnyDown", "AnyUp")
		pcall(sb.SetAttribute, sb, "useOnKeyDown", false)
		pcall(sb.SetAttribute, sb, "type", "macro")
		pcall(sb.SetAttribute, sb, "type1", "macro")
		pcall(sb.SetAttribute, sb, "macrotext", "/stopcasting")
		pcall(sb.SetAttribute, sb, "macrotext1", "/stopcasting")
	end

	-- cast events for the player's own crafts
	local casts = CreateFrame("Frame")
	for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
		"UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED" }) do
		casts:RegisterUnitEvent(e, "player")
	end
	casts:SetScript("OnEvent", function(_, event, ...) onCast(event, ...) end)

	-- hiding ours (X, Escape, mover) closes the trade skill too: the game
	-- frame's own OnHide runs C_TradeSkillUI.CloseTradeSkill
	f:HookScript("OnHide", function()
		local g = game()
		if g and g:IsShown() and parked then
			if InCombatLockdown() then
				if C_TradeSkillUI and C_TradeSkillUI.CloseTradeSkill then
					C_TradeSkillUI.CloseTradeSkill()
				end
			elseif type(HideUIPanel) == "function" then
				HideUIPanel(g)
			end
		end
	end)

	S.Movers.Register(f, "professions.window", L["Professions"])
	win = f
	return f
end

-- ---------------------------------------------------------------------------
-- fill / refill
-- ---------------------------------------------------------------------------

function Core.PickSlot(index)
	slotIndex = index
	D.SetSlot(index)
	inSlot = index and D.Filtered() or nil
	if chipSlot then
		local nm
		for _, s in ipairs(slots or {}) do
			if s.index == index then nm = s.name end
		end
		chipSlot:SetLabel(nm or L["Slot"])
		chipSlot:SetSelected(index ~= nil)
	end
	Core.RenderList(true)
end

local function refill()
	if not (win and win:IsShown()) then return end
	data = D.Read()
	local prof = data.prof
	if prof and prof.id ~= shownProf then
		shownProf = prof.id
		slotIndex, inSlot = nil, nil
		slots = D.Slots()
		chipSlot:SetShown(#slots > 0)
		chipSlot:SetLabel(L["Slot"])
		chipSlot:SetSelected(false)
	end
	buildTabs()
	paintHeader()
	picked = pickedByProf[prof and prof.id or 0]
	if not (picked and data.byID[picked]) then
		picked = nil
		for _, sec in ipairs(data.sections) do
			for _, r in ipairs(sec.recipes) do
				if keep(r) then picked = r.id break end
			end
			if picked then break end
		end
	end
	Core.RenderList()
	fillRecipe(picked and data.byID[picked])
end

-- Burst refresh: bag/craft events arrive in groups; re-read once settled.
local pending
function Core.Soon(wait)
	if pending then return end
	pending = true
	C_Timer.After(wait or 0.15, function()
		pending = nil
		if win and win:IsShown() and not D.Changing() then refill() end
	end)
end

-- ---------------------------------------------------------------------------
-- open / close / parking the game's frame
-- ---------------------------------------------------------------------------

function Core.Open()
	if not db.enabled then return end
	local f = buildWindow()
	-- own recipes or the all-professions overview; the rest (guild list,
	-- NPC window, linked professions) stays with the game
	local g = game()
	if not g then return end
	parkGame(g)
	f:Show()
	refill()
end

-- Hiding is enough: the window's OnHide un-shows the parked game frame,
-- whose own OnHide closes the trade skill.
function Core.Close()
	if win then win:Hide() end
end

function Core.IsOpen() return win ~= nil and win:IsShown() end

-- lend: give the game's frame back (guild list, NPC, linked view)
local function lend(g)
	unparkGame(g)
	if win and win:IsShown() then win:Hide() end
end

local function onGameShown(g, tries)
	if not db or not db.enabled then return end
	tries = (tries or 0) + 1
	if D.Changing() then
		-- the list isn't in yet; a link can read as the old profession
		if tries < 20 then
			C_Timer.After(0.2, function() onGameShown(g, tries) end)
		end
		return
	end
	if D.Viewing() ~= nil or D.Call("IsTradeSkillGuild") == true
		or D.Call("IsNPCCrafting") == true then
		return lend(g)
	end
	Core.Open()
end

local hooked
local function hookGame(g)
	if hooked or not g or not g.HookScript then return end
	hooked = true
	g:HookScript("OnShow", function()
		C_Timer.After(0, function() onGameShown(g) end)
	end)
	g:HookScript("OnHide", function()
		if parked then unparkGame(g) end
		if win and win:IsShown() then win:Hide() end
	end)
end

-- ---------------------------------------------------------------------------
-- the Professions key (K): cast the last used profession through an override
-- binding on a hidden secure button, closing our window when it's open.
-- ---------------------------------------------------------------------------

local keyBtn, keyOwner, keyBound
local KEY_BINDING = "TOGGLEPROFESSIONBOOK"

local function keySpell()
	local tabs = D.Tabs()
	if #tabs == 0 then return nil end
	local want = db.lastProf
	for _, t in ipairs(tabs) do
		if t.skillLine == want then return t.spellID end
	end
	return tabs[1].spellID
end

local function applyKey()
	if InCombatLockdown() or not db then return end
	if not keyBtn then
		local b = CreateFrame("Button", "SentiUICraftKey", UIParent, "SecureActionButtonTemplate")
		b:RegisterForClicks("AnyDown")
		b:SetAttribute("useOnKeyDown", true)
		b:Hide()
		b:SetScript("PreClick", function(self)
			if InCombatLockdown() then return end
			if Core.IsOpen() then
				self:SetAttribute("type", nil)
				Core.Close()
			else
				self:SetAttribute("type", self.spell and "spell" or nil)
			end
		end)
		b:SetScript("PostClick", function(self)
			if not InCombatLockdown() then
				self:SetAttribute("type", self.spell and "spell" or nil)
			end
		end)
		keyBtn = b
		keyOwner = CreateFrame("Frame")
	end
	local spell = keySpell()
	keyBtn.spell = spell
	-- secure spell attribute wants the name, not the ID
	local name = spell and D.SpellName(spell) or nil
	keyBtn:SetAttribute("type", name and "spell" or nil)
	keyBtn:SetAttribute("spell", name)
	local keys = {}
	if type(GetBindingKey) == "function" then
		for _, k in ipairs({ GetBindingKey(KEY_BINDING) }) do
			if type(k) == "string" and k ~= "" then keys[#keys + 1] = k end
		end
	end
	local sig = tostring(spell) .. "|" .. table.concat(keys, " ")
	if keyBound == sig then return end
	keyBound = sig
	ClearOverrideBindings(keyOwner)
	if not spell then return end
	for _, k in ipairs(keys) do
		SetOverrideBindingClick(keyOwner, false, k, "SentiUICraftKey", "LeftButton")
	end
end

-- ---------------------------------------------------------------------------
-- enable
-- ---------------------------------------------------------------------------

function Core.SettingChanged(mod, path)
	if not Core.enabled then return end
	db = mod.db
	if win and win:IsShown() then Core.RenderList(true) end
end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db
	if type(db.collapsed) ~= "table" then db.collapsed = {} end

	-- game frame hooks: the frame exists once a trade skill has been shown
	S.RegisterEvent("TRADE_SKILL_SHOW", function()
		C_Timer.After(0, function()
			local g = game()
			if not g then return end
			hookGame(g)
			if g:IsShown() and not Core.IsOpen() then onGameShown(g) end
			if Core.IsOpen() then
				-- a profession switch while open
				local prof = D.Profession()
				if prof then db.lastProf = prof.id applyKey() end
				refill()
			end
		end)
	end)
	S.RegisterEvent("TRADE_SKILL_LIST_UPDATE", function()
		C_Timer.After(0, function()
			if win and win:IsShown() then refill() end
		end)
	end)
	S.RegisterEvent("SKILL_LINES_CHANGED", function()
		applyKey()
		if win and win:IsShown() then
			buildTabs()
			local prof = D.Profession()
			if data and data.prof and prof and prof.id == data.prof.id then
				data.prof = prof
			end
			paintHeader()
		end
	end)
	for _, e in ipairs({ "BAG_UPDATE_DELAYED", "TRADE_SKILL_FAVORITES_CHANGED",
		"TRACKED_RECIPE_UPDATE", "NEW_RECIPE_LEARNED", "GET_ITEM_INFO_RECEIVED" }) do
		S.RegisterEvent(e, function() Core.Soon(e == "GET_ITEM_INFO_RECEIVED" and 0.3 or nil) end)
	end
	S.RegisterEvent("TRADE_SKILL_CLOSE", craftEnd)
	S.RegisterEvent("UPDATE_TRADESKILL_CAST_STOPPED", craftEnd)

	-- the K key
	S.RegisterEvent("UPDATE_BINDINGS", applyKey)
	S.RegisterEvent("PLAYER_ENTERING_WORLD", applyKey)
	applyKey()
end
