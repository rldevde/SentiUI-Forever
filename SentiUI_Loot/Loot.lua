-- SentiUI loot: instant fast loot, chat loot-spam filter, a persistent
-- loot log window and Sentinel skins for the loot window and the group
-- roll frames.
local _, ns = ...
local S = SentiUI
local L = ns.L
local W = S.Widgets
local IsSecret = S.IsSecret

local _G = _G
local ipairs, pairs, pcall, type = ipairs, pairs, pcall, type
local format, date, time = string.format, date, time
local tinsert, tremove = table.insert, table.remove

local ACCENT = S.colors.accent

local Core = {}
ns.Core = Core
local db

-- fast loot ----------------------------------------------------------------------
-- every slot the instant LOOT_READY fires, before the window renders;
-- respects the autoloot modifier/cvar unless "always" is set
-- IsModifiedClick lies on this client (documented in ActionBars):
-- AUTOLOOTTOGGLE can answer truthy with nothing held or never at all.
-- Ask the mapping (GetModifiedClick) which key the game wants, then check
-- the raw key state; unknown mapping = any modifier means hands-on.
local function ManualLootHeld()
	local mod = GetModifiedClick and GetModifiedClick("AUTOLOOTTOGGLE")
	if mod == "SHIFT" then return IsShiftKeyDown and IsShiftKeyDown() end
	if mod == "CTRL" then return IsControlKeyDown and IsControlKeyDown() end
	if mod == "ALT" then return IsAltKeyDown and IsAltKeyDown() end
	return (IsShiftKeyDown and IsShiftKeyDown())
		or (IsControlKeyDown and IsControlKeyDown())
		or (IsAltKeyDown and IsAltKeyDown())
end

local function OnLootReady(_, autoloot)
	if not db.fastLoot then return end
	local loot = db.fastLootAlways or autoloot
		or (GetCVarBool and GetCVarBool("autoLootDefault"))
	if not loot then return end
	-- a held autoloot modifier drops back to the normal window, even in
	-- "always" mode - the user picks the slots himself then
	if ManualLootHeld() then return end
	for i = (GetNumLootItems and GetNumLootItems() or 0), 1, -1 do
		S.SafeCall("loot:slot", LootSlot, i)
	end
end

-- chat filter ----------------------------------------------------------------------
-- hides poor-quality drops and solo coin messages via the message filter
local function LootFilter(_, _, msg)
	if not db.filter then return false end
	if type(msg) ~= "string" or IsSecret(msg) then return false end
	local link = msg:match("|Hitem:.-|h%[.-%]|h")
	if not link then
		-- no item link: coin and loot system text
		return db.hideCoin or false
	end
	local q = GetItemInfo and select(3, GetItemInfo(link))
	if not q then
		-- item not cached: fall back to the link's quality color
		local hex = link:match("|c(%x%x%x%x%x%x%x%x)")
		if not hex then return false end
		hex = hex:upper()
		for i = 0, 7 do
			local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[i]
			local h = c and c.hex and (c.hex:gsub("^|[cC]", "")):upper()
			if h and h == hex then q = i break end
		end
	end
	if q then return q < (db.filterQuality or 0) end
	return false
end

-- loot log ----------------------------------------------------------------------
local MAX_ROWS, ROW_H = 14, 18
local frame, rows

local function Entries()
	SentiUIDB.lootHistory = SentiUIDB.lootHistory or {}
	return SentiUIDB.lootHistory
end

local function BuildFrame()
	if frame then return end
	frame = CreateFrame("Frame", "SentiUILootHistory", UIParent, "BackdropTemplate")
	S.EscClosable(frame)
	frame:SetSize(460, 310)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	S.Template(frame, "panel")
	local title = S.Font(frame, 13, ACCENT, "OUTLINE")
	title:SetPoint("TOP", 0, -10)
	title:SetText(L["Loot History"])
	local line = S.Line(frame, ACCENT)
	line:SetPoint("TOPLEFT", 10, -26)
	line:SetPoint("TOPRIGHT", -10, -26)
	local close = W.Close(frame, function() frame:Hide() end)
	close:SetPoint("TOPRIGHT", -6, -6)
	local clear = W.Button(frame, L["Clear"])
	clear:SetPoint("BOTTOMRIGHT", -10, 8)
	clear:SetScript("OnClick", function()
		wipe(Entries())
		frame.offset = 0
		Core.FillHistory()
	end)
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(self, delta)
		local max = math.max(0, #Entries() - MAX_ROWS)
		self.offset = math.max(0, math.min(max, (self.offset or 0) - delta))
		Core.FillHistory()
	end)
	rows = {}
	for i = 1, MAX_ROWS do
		local r = CreateFrame("Button", nil, frame)
		r:SetSize(430, ROW_H)
		r:SetPoint("TOPLEFT", 12, -34 - (i - 1) * ROW_H)
		r.text = S.Font(r, 10)
		r.text:SetPoint("LEFT", 4, 0)
		r.text:SetWidth(420)
		r.hl = r:CreateTexture(nil, "HIGHLIGHT")
		r.hl:SetAllPoints()
		r.hl:SetColorTexture(0.3, 0.3, 0.4, 0.4)
		r:SetScript("OnEnter", function(self)
			local link = self.link
			if link then
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				pcall(GameTooltip.SetHyperlink, GameTooltip, link)
				GameTooltip:Show()
			end
		end)
		r:SetScript("OnLeave", function() GameTooltip:Hide() end)
		rows[i] = r
	end
	frame:Hide()
end

function Core.FillHistory()
	if not frame then return end
	local e = Entries()
	local off = frame.offset or 0
	for i, row in ipairs(rows) do
		local d = e[i + off]
		if d then
			row.text:SetText(format("|cff888888%s|r %s",
				date("%H:%M", d.t or 0), d.msg or ""))
			row.link = d.link
			row:Show()
		else
			row:Hide()
		end
	end
end

function Core.AddHistory(msg)
	local e = Entries()
	-- keep the first item hyperlink so rows show its tooltip on hover
	local link = msg:match("(|Hitem:.-|h%[.-%]|h)")
	tinsert(e, 1, { t = time(), msg = msg, link = link })
	local max = db.historySize or 200
	while #e > max do tremove(e) end
	if frame and frame:IsShown() then Core.FillHistory() end
end

function Core.ToggleHistory()
	BuildFrame()
	if frame:IsShown() then frame:Hide() else Core.FillHistory() frame:Show() end
end

local function OnLootMsg(_, msg)
	if not db.history then return end
	if type(msg) ~= "string" or IsSecret(msg) or not msg:find("Hitem") then return end
	Core.AddHistory(msg)
end

-- roll frames ----------------------------------------------------------------------
-- the client's roll frames stay alive (they own rollID and the countdown)
-- but get fully hidden and click-dead; the visible card is ours: item
-- icon with a quality border, name, an accent countdown line and the
-- classic dice/coin/disenchant/pass glyphs - a real Sentinel look
local ROLL_W, ROLL_H, ROLL_GAP, ROLL_VISIBLE = 264, 56, 6, 3
local ROLL_BTN = 20
local ROLL_ORDER = { "need", "greed", "de", "pass" }
local ROLL_ID = { need = 1, greed = 2, de = 3, pass = 0 }
local ROLL_TEX = {
	need = "Interface\\Buttons\\UI-GroupLoot-Dice-Up",
	greed = "Interface\\Buttons\\UI-GroupLoot-Coin-Up",
	de = { "Interface\\Buttons\\UI-GroupLoot-DE-Up",
		"Interface\\Icons\\INV_Enchant_Disenchant" },
	pass = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
}

-- some group-loot glyph sheets are missing on this client and SetTexture
-- happily accepts the dead path (renders a grey box). Probe the file data
-- when possible so a missing glyph falls back to the letter instead
local function ResolveGlyph(v)
	local candidates = type(v) == "table" and v or { v }
	for _, path in ipairs(candidates) do
		if type(path) == "string" then
			if not GetFileIDFromPath then return path end
			local ok, id = pcall(GetFileIDFromPath, path)
			if ok and id and id ~= 0 then return path end
		end
	end
end

local function QualityColor(quality)
	local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
	if c then return c.r, c.g, c.b end
	return 1, 1, 1
end

-- Where the roll frames actually live: classic GroupLootFrameN globals
-- plus, on this client, the frames managed by GroupLootContainer. The
-- container list is the reason the skin missed the visible frame.
local function EachRollFrame(fn)
	for i = 1, (NUM_GROUP_LOOT_FRAMES or 8) do
		local f = _G["GroupLootFrame" .. i]
		if f then fn(f) end
	end
	local c = _G.GroupLootContainer
	if type(c) ~= "table" then return end
	if type(c.rollFrames) == "table" then
		for _, f in pairs(c.rollFrames) do
			if type(f) == "table" then fn(f) end
		end
	end
	for _, f in ipairs({ c:GetChildren() }) do
		-- roll frames carry the roll buttons/icon frame; skip other children
		if type(f) == "table" and (f.IconFrame or f.LootButtonContainer or f.Timer) then
			fn(f)
		end
	end
end

-- invisible and click-dead: alpha 0 plus mouse killed recursively so the
-- game frame's own buttons can't eat a click through our cards. Hide()
-- is deliberately avoided - the engine may treat it as a dismissed roll.
local function KillRollFrame(f)
	f:SetAlpha(0)
	local function kill(fr)
		if fr.EnableMouse then pcall(fr.EnableMouse, fr, false) end
		if fr.EnableMouseWheel then pcall(fr.EnableMouseWheel, fr, false) end
		for _, c in ipairs({ fr:GetChildren() }) do
			if type(c) == "table" then kill(c) end
		end
	end
	kill(f)
end

local function RollIDOf(f)
	local ok, id = pcall(function() return f.rollID end)
	if ok and id ~= nil and not IsSecret(id) then return id end
end

-- roll panel + cards -----------------------------------------------------------
local rollPanel, rollScroll, rollChild
local rollCards = {}

local function MakeRollCard()
	local r = CreateFrame("Frame", nil, rollChild)
	r:SetSize(ROLL_W, ROLL_H)
	S.Template(r, "inset")
	-- the icon is a plain texture and cannot take input: the card frame
	-- takes the hover instead and shows the item tooltip that
	-- UpdateRollCard caches on the icon as suiIconLink
	r:EnableMouse(true)
	r:SetScript("OnEnter", function(self)
		S.SetBorderLit(self, true)
		local link = self.icon and self.icon.suiIconLink
		if link and not IsSecret(link) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			pcall(GameTooltip.SetHyperlink, GameTooltip, link)
			GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", function(self)
		S.SetBorderLit(self, false)
		GameTooltip:Hide()
	end)
	-- wheel straight to the panel scroll even with the cursor on a card
	r:EnableMouseWheel(true)
	r:SetScript("OnMouseWheel", function(_, delta)
		local w = rollPanel and rollPanel:GetScript("OnMouseWheel")
		if w then w(rollPanel, delta) end
	end)
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetPoint("TOPLEFT", 6, -7)
	r.icon:SetSize(30, 30)
	r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	-- subtle 2px corner clip keeps the icon's square silhouette
	S.IconRound(r, 2)
	-- quality ring sits one layer under the icon: OVERLAY would paint
	-- the solid square over it and the icon disappears
	r.border = r:CreateTexture(nil, "BORDER")
	r.border:SetPoint("TOPLEFT", r.icon, -1, 1)
	r.border:SetPoint("BOTTOMRIGHT", r.icon, 1, -1)
	r.name = S.Font(r, 11)
	r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -2)
	r.name:SetWidth(ROLL_W - 32 - 14 - (2 * ROLL_BTN + 10))
	r.name:SetJustifyH("LEFT")
	r.name:SetWordWrap(false)
	-- accent countdown line along the bottom edge
	r.timer = CreateFrame("StatusBar", nil, r)
	r.timer:SetPoint("BOTTOMLEFT", 6, 5)
	r.timer:SetPoint("BOTTOMRIGHT", -6, 5)
	r.timer:SetHeight(3)
	r.timer:SetMinMaxValues(0, 1)
	r.timer:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	r.timer:SetStatusBarColor(ACCENT.r, ACCENT.g, ACCENT.b, 0.9)
	r.timerbg = r.timer:CreateTexture(nil, "BACKGROUND")
	r.timerbg:SetAllPoints()
	r.timerbg:SetTexture("Interface\\Buttons\\WHITE8X8")
	r.timerbg:SetVertexColor(1, 1, 1, 0.08)
	-- 2x2 glyph grid on the right: need greed / disenchant pass
	r.btns = {}
	for i, key in ipairs(ROLL_ORDER) do
		local b = CreateFrame("Button", nil, r)
		b:SetSize(ROLL_BTN, ROLL_BTN)
		local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
		b:SetPoint("TOPRIGHT", -6 - col * (ROLL_BTN + 3),
			-7 - row * (ROLL_BTN + 3))
		b.tex = b:CreateTexture(nil, "ARTWORK")
		b.tex:SetAllPoints()
		local glyph = ResolveGlyph(ROLL_TEX[key])
		if glyph then b.tex:SetTexture(glyph) end
		if not glyph or not b.tex:GetTexture() then
			-- the classic glyph sheets are missing on this client:
			-- fall back to a letter so the button still reads
			b.tex:Hide()
			local fs = S.Font(b, 12, ACCENT)
			fs:SetPoint("CENTER")
			fs:SetText(({ need = "N", greed = "G", de = "D", pass = "P" })[key])
		end
		b.rollType = ROLL_ID[key]
		b:SetScript("OnClick", function(self)
			local card = self:GetParent()
			if card.rollID ~= nil then
				S.SafeCall("loot:roll", RollOnLoot, card.rollID, self.rollType)
			end
		end)
		b:SetScript("OnEnter", function(self)
			self.tex:SetVertexColor(ACCENT.r, ACCENT.g, ACCENT.b)
			local label = ({ need = NEED or "Need", greed = GREED or "Greed",
				de = ROLL_DISENCHANT or DISENCHANT or "Disenchant",
				pass = PASS or "Pass" })[key]
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(label)
		end)
		b:SetScript("OnLeave", function(self)
			self.tex:SetVertexColor(1, 1, 1)
			GameTooltip:Hide()
		end)
		r.btns[key] = b
	end
	return r
end

-- SetTexture can silently drop a bad or secret value; verify the texture
-- actually stuck and walk the fallbacks until something draws
local function IconSticks(tex, v)
	if v == nil or IsSecret(v) then return false end
	tex:SetTexture(v)
	return tex:GetTexture() ~= nil
end

-- Item data arrives async on this client: the first loot often finds
-- nothing cached and every icon source comes back empty, leaving the
-- question-mark fallback. ContinueOnItemLoad re-runs the lookup the
-- moment the item lands in the cache. tex.suiIconLink guards against
-- recycled rows: if the row was reused for another item while the load
-- was pending, the stale callback does nothing.
local function RetryIcon(tex, link)
	tex.suiIconLink = link
	if not (link and Item and Item.CreateFromItemLink) then return end
	local ok, item = pcall(Item.CreateFromItemLink, Item, link)
	if not (ok and item and item.ContinueOnItemLoad) then return end
	item:ContinueOnItemLoad(function()
		if tex.suiIconLink ~= link then return end
		if C_Item and C_Item.GetItemIconByID then
			local ok2, v = pcall(C_Item.GetItemIconByID, link)
			if ok2 and IconSticks(tex, v) then return end
		end
		if item.GetItemIcon then
			local ok2, v = pcall(item.GetItemIcon, item)
			if ok2 then IconSticks(tex, v) end
		end
	end)
end

local function RollInfo(rollID)
	-- texture, name, count, quality, bindOnPickup, canNeed, canGreed,
	-- canDisenchant, reason*, deSkillRequired, canTransmog
	local ok, tex, name, count, quality, _, canNeed, canGreed, canDE =
		pcall(GetLootRollItemInfo, rollID)
	if not ok then return end
	if IsSecret(name) then name = nil end
	if IsSecret(tex) then tex = nil end
	return tex, name, count, quality, canNeed, canGreed, canDE
end

local function UpdateRollCard(r, rollID)
	r.rollID = rollID
	local tex, name, count, quality, canNeed, canGreed, canDE = RollInfo(rollID)
	local link = GetLootRollItemLink and GetLootRollItemLink(rollID)
	if link and GetItemInfo then
		quality = select(3, GetItemInfo(link)) or quality
		if not name then name = select(1, GetItemInfo(link)) end
	end
	if not tex and link and C_Item and C_Item.GetItemIconByID then
		local ok, v = pcall(C_Item.GetItemIconByID, link)
		if ok and not IsSecret(v) then tex = v end
	end
	r.icon.suiIconLink = link
	if not IconSticks(r.icon, tex) then
		IconSticks(r.icon, "Interface\\Icons\\INV_Misc_QuestionMark")
		RetryIcon(r.icon, link)
	end
	local cr, cg, cb = QualityColor(quality or 1)
	r.border:SetColorTexture(cr, cg, cb)
	r.name:SetText(name or (link and link:match("%[(.-)%]")) or "?")
	r.name:SetTextColor(cr, cg, cb)
	if type(count) == "number" and count > 1 then
		r.name:SetText(r.name:GetText() .. " x" .. count)
	end
	-- roll buttons exist only for what the item allows; a secret flag
	-- keeps the fallback (need/greed shown, disenchant hidden)
	local function Allowed(v, fallback)
		if v == nil or IsSecret(v) then return fallback end
		return v == true
	end
	if r.btns.need then r.btns.need:SetShown(Allowed(canNeed, true)) end
	if r.btns.greed then r.btns.greed:SetShown(Allowed(canGreed, true)) end
	if r.btns.de then r.btns.de:SetShown(Allowed(canDE, false)) end
	-- countdown: remember the longest time seen, the bar drains to zero
	local left = GetLootRollTimeLeft and GetLootRollTimeLeft(rollID)
	if type(left) == "number" and not IsSecret(left) then
		local total = r.total and math.max(r.total, left) or left
		r.total = total
		r.timer:SetMinMaxValues(0, math.max(1, total))
		r.timer:SetValue(math.max(0, left))
	end
end

local function BuildRollPanel()
	if rollPanel then return end
	rollPanel = CreateFrame("Frame", "SentiUIRollPanel", UIParent,
		"BackdropTemplate")
	rollPanel:SetFrameStrata("HIGH")
	rollPanel:SetClampedToScreen(true)
	rollPanel:EnableMouse(true)
	S.Template(rollPanel, "panel")
	rollScroll = CreateFrame("ScrollFrame", nil, rollPanel,
		"UIPanelScrollFrameTemplate")
	rollScroll:SetPoint("TOPLEFT", 3, -3)
	rollScroll:SetPoint("BOTTOMRIGHT", -18, 3)
	rollChild = CreateFrame("Frame", nil, rollScroll)
	rollChild:SetSize(1, 1)
	rollScroll:SetScrollChild(rollChild)
	-- the template scrollbar comes unanchored on this client: park it in
	-- the right gutter the scroll frame leaves (-18) with room for the
	-- up/down buttons
	local sb = rollScroll.ScrollBar
	if sb then
		sb:ClearAllPoints()
		sb:SetPoint("TOPRIGHT", rollScroll, "TOPRIGHT", 0, -16)
		sb:SetPoint("BOTTOMRIGHT", rollScroll, "BOTTOMRIGHT", 0, 16)
	end
	rollPanel:EnableMouseWheel(true)
	rollPanel:SetScript("OnMouseWheel", function(_, delta)
		local cur = rollScroll:GetVerticalScroll() or 0
		local max = math.max(0, (rollChild:GetHeight() or 0)
			- (rollScroll:GetHeight() or 0))
		rollScroll:SetVerticalScroll(
			math.max(0, math.min(max, cur - delta * 60)))
	end)
	rollPanel:Hide()
end

-- live rolls: rollID -> seen-at least once from a client frame (the
-- countdown source) or from START_LOOT_ROLL itself
local liveRolls = {}
local pendingRolls = {}
local rollIDList = {}

local function CollectRolls()
	wipe(liveRolls)
	EachRollFrame(function(f)
		if f.IsForbidden and f:IsForbidden() then return end
		if f.IsShown and f:IsShown() then
			-- the client's frame keeps ticking but stays invisible
			KillRollFrame(f)
			local id = RollIDOf(f)
			if id ~= nil then liveRolls[id] = true end
		end
	end)
	for id in pairs(pendingRolls) do
		liveRolls[id] = true
	end
	wipe(rollIDList)
	for id in pairs(liveRolls) do
		rollIDList[#rollIDList + 1] = id
	end
	table.sort(rollIDList)
	return rollIDList
end

local function LayoutRollPanel()
	if not db.rollSkin then
		if rollPanel then rollPanel:Hide() end
		return
	end
	BuildRollPanel()
	local ids = CollectRolls()
	local n = 0
	for i, id in ipairs(ids) do
		local r = rollCards[i] or MakeRollCard()
		rollCards[i] = r
		UpdateRollCard(r, id)
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", rollChild, "TOPLEFT",
			0, -(i - 1) * (ROLL_H + ROLL_GAP))
		r:Show()
		n = i
	end
	for i = n + 1, #rollCards do
		rollCards[i].rollID = nil
		rollCards[i].total = nil
		rollCards[i]:Hide()
	end
	if n == 0 then
		rollPanel:Hide()
		return
	end
	rollChild:SetSize(ROLL_W, n * (ROLL_H + ROLL_GAP))
	local rows = math.min(n, ROLL_VISIBLE)
	rollPanel:SetSize(ROLL_W + 24, rows * (ROLL_H + ROLL_GAP) - ROLL_GAP + 8)
	-- dock beside the items first (our loot window, else the game's);
	-- with no loot window up the roll mover's position is the fallback
	rollPanel:ClearAllPoints()
	local lw = _G.SentiUILootWindow
	if lw and lw:IsShown() then
		rollPanel:SetPoint("TOPLEFT", lw, "TOPRIGHT", 4, 0)
	elseif _G.LootFrame and _G.LootFrame:IsShown() then
		rollPanel:SetPoint("TOPLEFT", _G.LootFrame, "TOPRIGHT", 4, 0)
	elseif _G.GroupLootContainer then
		rollPanel:SetPoint("TOPLEFT", _G.GroupLootContainer, "TOPLEFT", 0, 0)
	else
		rollPanel:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 14, 320)
	end
	rollPanel:Show()
end

-- smooth countdown between the coarse polls
local function RollTick(dt)
	if not (rollPanel and rollPanel:IsShown()) then return end
	local dirty = false
	for _, r in ipairs(rollCards) do
		if r:IsShown() and r.rollID ~= nil then
			local left = GetLootRollTimeLeft
				and GetLootRollTimeLeft(r.rollID)
			if type(left) == "number" and not IsSecret(left) and left > 0 then
				if not r.total or left > r.total then r.total = left end
				r.timer:SetValue(math.max(0, left))
			else
				-- gone when the timer is up or the roll no longer exists
				local dead = type(left) == "number" and not IsSecret(left)
					and left <= 0
				if not dead and GetLootRollItemLink then
					local ok, l = pcall(GetLootRollItemLink, r.rollID)
					dead = ok and (l == nil or l == "")
				end
				if dead then
					pendingRolls[r.rollID] = nil
					r.rollID = nil
					dirty = true
				end
			end
		end
	end
	if dirty then LayoutRollPanel() end
end

local function UpdateRollFrames()
	LayoutRollPanel()
end

-- loot window ----------------------------------------------------------------------
local function StyleLootButton(btn)
	if not btn or btn.suiStyled then return end
	btn.suiStyled = true
	local icon = btn.Icon or _G[(btn.GetName and btn:GetName() or "") .. "IconTexture"]
	if icon and not icon.suiBorder then
		-- icon can be a plain texture (no CreateTexture); host the ring
		-- on the button then, always anchored to the icon
		local host = (type(icon.CreateTexture) == "function") and icon or btn
		local border = host:CreateTexture(nil, "BORDER")
		border:SetPoint("TOPLEFT", icon, -1, 1)
		border:SetPoint("BOTTOMRIGHT", icon, 1, -1)
		border:SetColorTexture(1, 1, 1, 0.9)
		icon.suiBorder = border
	end
end

local function StyleLootFrame()
	local lf = _G.LootFrame
	if not lf or lf.suiStyled then return end
	lf.suiStyled = true
	for _, region in ipairs({ lf:GetRegions() }) do
		if region:IsObjectType("Texture") and region:GetDrawLayer() == "BACKGROUND" then
			region:SetTexture(nil)
		end
	end
	if not lf.SetBackdrop and BackdropTemplateMixin then Mixin(lf, BackdropTemplateMixin) end
	S.Template(lf, "panel")
	for i = 1, 8 do StyleLootButton(_G["LootButton" .. i]) end
end

local function UpdateLootFrame()
	if not db.lootSkin then return end
	StyleLootFrame()
	for i = 1, (LOOT_FRAME_NUM_BUTTONS or 4) do
		local btn = _G["LootButton" .. i]
		if btn and btn:IsShown() then
			local icon = btn.Icon or _G["LootButton" .. i .. "IconTexture"]
			local link = GetLootSlotLink and GetLootSlotLink(i)
			local quality = link and GetItemInfo and select(3, GetItemInfo(link))
			if not quality and GetLootSlotInfo then
				local _, _, _, q = GetLootSlotInfo(i)
				quality = q
			end
			if icon and icon.suiBorder then
				icon.suiBorder:SetColorTexture(QualityColor(quality or 1))
				icon.suiBorder:Show()
			end
		end
	end
end

-- own loot window -------------------------------------------------------------------
-- a Sentinel panel replacing the game's loot frame: icon with a quality
-- border, quality-colored name, count on the right, click to loot
local lootWin, lootRows = nil, {}
local LOOT_ROW_H, LOOT_ROWS_MAX = 22, 10

local function SlotData(i)
	-- GetLootSlotInfo's middle return is quality on item slots and a
	-- currency id on currency slots; the link's real quality wins anyway
	local icon, name, qty, quality, quest
	if GetLootSlotInfo then
		local ok, a, b, c, d, _, _, g = pcall(GetLootSlotInfo, i)
		if ok then
			-- any return can be secret on this client; a secret icon would
			-- make SetTexture fail silently and the row shows nothing
			if not IsSecret(a) then icon = a end
			if not IsSecret(b) then name = b end
			qty = c
			if type(d) == "number" then quality = d end
			quest = g
		end
	end
	local link = GetLootSlotLink and GetLootSlotLink(i)
	if link and GetItemInfo then
		local q = select(3, GetItemInfo(link))
		if type(q) == "number" then quality = q end
	end
	return icon, name, qty, quality, quest, link
end

local function SlotIcon(tex, i, icon, link)
	tex.suiIconLink = link
	if IconSticks(tex, icon) then return end
	-- the game's own (hidden) loot button already got the icon engine-side
	local btn = _G["LootButton" .. i]
	local bi = (type(btn) == "table" and (btn.Icon or btn.IconTexture))
		or _G["LootButton" .. i .. "IconTexture"]
	if bi and bi.GetTexture then
		local ok, v = pcall(bi.GetTexture, bi)
		if ok and IconSticks(tex, v) then return end
	end
	if link and C_Item and C_Item.GetItemIconByID then
		local ok, v = pcall(C_Item.GetItemIconByID, link)
		if ok and IconSticks(tex, v) then return end
	end
	if link and GetItemInfo then
		local ok, v = pcall(function()
			return select(10, GetItemInfo(link))
		end)
		if ok and IconSticks(tex, v) then return end
	end
	IconSticks(tex, "Interface\\Icons\\INV_Misc_QuestionMark")
	RetryIcon(tex, link)
end

local function LootRow(i)
	local r = lootRows[i]
	if r then return r end
	r = CreateFrame("Button", nil, lootWin)
	r:SetHeight(LOOT_ROW_H)
	S.Template(r, "inset")
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetPoint("LEFT", 4, 0)
	r.icon:SetSize(16, 16)
	r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	r.border = r:CreateTexture(nil, "BORDER")
	r.border:SetPoint("TOPLEFT", r.icon, -1, 1)
	r.border:SetPoint("BOTTOMRIGHT", r.icon, 1, -1)
	r.border:SetColorTexture(1, 1, 1, 0.9)
	r.name = S.Font(r, 11)
	r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
	r.name:SetJustifyH("LEFT")
	r.name:SetWidth(140)
	r.name:SetWordWrap(false)
	r.qty = S.Font(r, 10, S.colors.textDim)
	r.qty:SetPoint("RIGHT", -6, 0)
	r:SetScript("OnClick", function(self, btn)
		if self.slot and btn == "LeftButton" then
			pcall(LootSlot, self.slot)
		end
	end)
	r:SetScript("OnEnter", function(self)
		S.SetBorderLit(self, true)
		if self.slot then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local ok = pcall(GameTooltip.SetLootItem, GameTooltip, self.slot)
			if not ok and self.link then
				pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
			end
			GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", function(self)
		S.SetBorderLit(self, false)
		GameTooltip:Hide()
	end)
	lootRows[i] = r
	return r
end

local function BuildLootWindow()
	if lootWin then return end
	lootWin = CreateFrame("Frame", "SentiUILootWindow", UIParent, "BackdropTemplate")
	lootWin:SetSize(240, 60)
	lootWin:SetPoint("CENTER", 0, -40)
	lootWin:SetFrameStrata("HIGH")
	lootWin:SetToplevel(true)
	S.EscClosable(lootWin)
	lootWin:EnableMouse(true)
	lootWin:SetMovable(true)
	lootWin:RegisterForDrag("LeftButton")
	lootWin:SetScript("OnDragStart", lootWin.StartMoving)
	lootWin:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		-- same store as the mover: nearest-anchor format + MoversChanged
		S.Movers.Save("loot.window")
	end)
	lootWin:Hide()
	S.Template(lootWin, "panel")
	local title = S.Font(lootWin, 12, ACCENT)
	title:SetPoint("TOP", 0, -8)
	title:SetText(LOOT or "Loot")
	local hairline = S.Line(lootWin, ACCENT)
	hairline:SetPoint("TOPLEFT", 10, -24)
	hairline:SetPoint("TOPRIGHT", -10, -24)
	local close = W.Close(lootWin, function()
		pcall(CloseLoot)
		lootWin:Hide()
	end)
	close:SetPoint("TOPRIGHT", -4, -4)
	-- manual counterpart to fast loot: one click empties the window
	local all = W.Button(lootWin, L["Loot all"], 76, 18)
	all:SetPoint("BOTTOMRIGHT", -8, 6)
	all:SetScript("OnClick", function()
		for i = (GetNumLootItems and GetNumLootItems() or 0), 1, -1 do
			S.SafeCall("loot:slot", LootSlot, i)
		end
	end)
	lootWin.lootAll = all
	-- the mover registers at build time so move mode knows the window even
	-- before the first loot; the handle itself only shows while the own
	-- loot window is enabled
	S.Movers.Register(lootWin, "loot.window", L["Loot window"], nil, {
		active = function() return db and db.lootWindow end,
	})
end

-- the game's loot frame must stay out of the way while ours is enabled
-- - but NEVER Hide() it: on this client LootFrame's OnHide calls
-- CloseLoot(), so hiding it ends the loot session instantly (the window
-- flashes open and dies). Alpha + mouse-kill instead. Called on every
-- window update: the show watcher alone misses a frame that was created
-- (and shown) before the watch registered
local LOOT_FRAME_EVENTS = {
	"LOOT_OPENED", "LOOT_READY", "LOOT_SLOT_CHANGED", "LOOT_SLOT_CLEARED",
}

-- the real kill: the frame only opens when it hears the loot events, so
-- take its ears. LOOT_BIND_CONFIRM stays registered on purpose - it is
-- what auto-confirms BoP pickups on this client
local function SilenceBlizzardLoot(on)
	local lf = _G.LootFrame
	if type(lf) ~= "table" or not lf.UnregisterEvent then return end
	for _, ev in ipairs(LOOT_FRAME_EVENTS) do
		if on then pcall(lf.UnregisterEvent, lf, ev)
		else pcall(lf.RegisterEvent, lf, ev) end
	end
end

local function KillBlizzardLoot()
	local lf = _G.LootFrame
	if type(lf) ~= "table" or not (db and db.lootWindow) then return end
	SilenceBlizzardLoot(true)
	lf:SetAlpha(0)
	lf:EnableMouse(false)
end

local function UpdateLootWindow()
	if not db.lootWindow then
		if lootWin then lootWin:Hide() end
		return
	end
	BuildLootWindow()
	local n = GetNumLootItems and GetNumLootItems() or 0
	if n == 0 then
		lootWin:Hide()
		return
	end
	KillBlizzardLoot()
	lootWin:SetHeight(34 + math.min(n, LOOT_ROWS_MAX) * LOOT_ROW_H + 8
		+ (lootWin.lootAll and 26 or 0))
	lootWin:Show()
	for i = 1, math.min(n, LOOT_ROWS_MAX) do
		local r = LootRow(i)
		r.slot = i
		r:ClearAllPoints()
		r:SetPoint("TOPLEFT", 6, -30 - (i - 1) * LOOT_ROW_H)
		r:SetPoint("TOPRIGHT", -6, -30 - (i - 1) * LOOT_ROW_H)
		local icon, name, qty, quality, quest, link = SlotData(i)
		r.link = link
		SlotIcon(r.icon, i, icon, link)
		local r2, g2, b2 = QualityColor(quest and 1 or quality)
		r.border:SetColorTexture(r2, g2, b2)
		if name and not IsSecret(name) then
			r.name:SetText(name)
			if quest then
				r.name:SetTextColor(1, 0.82, 0)
			else
				r.name:SetTextColor(r2, g2, b2)
			end
		elseif link and not IsSecret(link) then
			r.name:SetText(link)
			r.name:SetTextColor(r2, g2, b2)
		end
		r.qty:SetText(type(qty) == "number" and qty > 1 and ("x" .. qty) or "")
		r:Show()
	end
	for i = n + 1, #lootRows do lootRows[i]:Hide() end
end

-- the game's loot frame is re-hidden via an OnShow hook in Core.Enable

-- loot feed -------------------------------------------------------------------------
-- recent own loot as small fading rows: the same item stacks, money pools
-- on one row, hover for the tooltip, right-click dismisses early. Self-loot
-- is matched through the game's own format strings so every language works.
local feed, feedRows, feedEntries = nil, {}, {}
local FEED_ROW_H, FEED_ICON = 20, 16

local function fmtPattern(fmt)
	if type(fmt) ~= "string" or IsSecret(fmt) then return nil end
	local p = fmt:gsub("%%", "\001")
	p = p:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	p = p:gsub("\001s", "(.-)"):gsub("\001d", "(%%d+)")
	return "^" .. p .. "$"
end

local itemPats, moneyPats
local function BuildFeedPatterns()
	itemPats = {}
	for _, g in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF",
		"LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF",
		"LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF" }) do
		local p = fmtPattern(_G[g])
		if p then itemPats[#itemPats + 1] = p end
	end
	moneyPats = {}
	for _, g in ipairs({ "YOU_LOOT_MONEY", "LOOT_MONEY_SPLIT" }) do
		local p = fmtPattern(_G[g])
		if p then moneyPats[#moneyPats + 1] = p end
	end
end

local function MoneyToCopper(text)
	-- "3 Gold, 45 Silver" -> copper, in any locale: the currency words are
	-- the GOLD/SILVER/COPPER globals
	local total, mul = 0, { [GOLD or "Gold"] = 10000, [SILVER or "Silver"] = 100, [COPPER or "Copper"] = 1 }
	for amt, cur in text:gmatch("(%d+)%s*([%aäöüÄÖÜ]+)") do
		if mul[cur] then total = total + tonumber(amt) * mul[cur] end
	end
	return total > 0 and total or nil
end

local function CopperText(copper)
	if GetCoinTextureString then
		local ok, s = pcall(GetCoinTextureString, copper)
		if ok and s then return s end
	end
	if GetMoneyString then
		local ok, s = pcall(GetMoneyString, copper, true)
		if ok and s then return s end
	end
	return nil
end

local StartExit -- defined below FeedLayout; the row click forwards here

local function FeedRow(i)
	local r = feedRows[i]
	if r then return r end
	r = CreateFrame("Button", nil, feed)
	r:SetSize(240, FEED_ROW_H)
	S.Template(r, "inset")
	r.icon = r:CreateTexture(nil, "ARTWORK")
	r.icon:SetPoint("LEFT", 3, 0)
	r.icon:SetSize(FEED_ICON, FEED_ICON)
	r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	r.border = r:CreateTexture(nil, "BORDER")
	r.border:SetPoint("TOPLEFT", r.icon, -1, 1)
	r.border:SetPoint("BOTTOMRIGHT", r.icon, 1, -1)
	r.border:SetColorTexture(1, 1, 1, 0.9)
	r.text = S.Font(r, 11)
	r.text:SetPoint("LEFT", r.icon, "RIGHT", 7, 0)
	r.text:SetWidth(165)
	r.text:SetJustifyH("LEFT")
	r.text:SetWordWrap(false)
	r.qty = S.Font(r, 10, ACCENT)
	r.qty:SetPoint("RIGHT", -5, 0)
	r:RegisterForClicks("RightButtonUp")
	r:SetScript("OnClick", function(self)
		local e = feedEntries[self.i]
		if e then
			e.fading, e.alpha = true, math.min(e.alpha or 1, 0.4)
			StartExit(e, self)
		end
	end)
	r:SetScript("OnEnter", function(self)
		local e = feedEntries[self.i]
		if e and e.link then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			pcall(GameTooltip.SetHyperlink, GameTooltip, e.link)
			GameTooltip:Show()
		end
	end)
	r:SetScript("OnLeave", function() GameTooltip:Hide() end)
	feedRows[i] = r
	return r
end

local function FeedLayout()
	local shown = 0
	for i, e in ipairs(feedEntries) do
		local r = FeedRow(i)
		r.i = i
		r:ClearAllPoints()
		-- e.slide: the exit animation's horizontal offset, computed in the
		-- feed's OnUpdate from the fade progress
		r:SetPoint("TOPLEFT", feed, "TOPLEFT", e.slide or 0,
			-(i - 1) * (FEED_ROW_H + 3))
		if e.money then
			r.icon.suiIconLink = nil
			r.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
			r.border:SetColorTexture(0.95, 0.80, 0.30)
			r.text:SetText(e.text or "")
			r.text:SetTextColor(0.95, 0.80, 0.30)
			r.qty:SetText("")
		else
			r.icon.suiIconLink = e.link
			if not IconSticks(r.icon, e.icon) then
				IconSticks(r.icon, "Interface\\Icons\\INV_Misc_QuestionMark")
				RetryIcon(r.icon, e.link)
			end
			local r2, g2, b2 = QualityColor(e.quality)
			r.border:SetColorTexture(r2, g2, b2)
			r.text:SetText(e.name or "")
			r.text:SetTextColor(r2, g2, b2)
			r.qty:SetText(e.count > 1 and ("x" .. e.count) or "")
		end
		r:SetAlpha(e.alpha or 1)
		r:Show()
		shown = i
	end
	for i = shown + 1, #feedRows do feedRows[i]:Hide() end
	feed:SetHeight(math.max(1, shown * (FEED_ROW_H + 3)))
end

-- the exit run's direction + travel distance, measured once from the
-- row's position to the chosen screen edge (feedExit = "left"|"right")
function StartExit(e, row)
	e.slide = nil
	local dir = db.feedExit == "left" and -1
		or db.feedExit == "right" and 1 or 0
	e.exitDir, e.exitDist = nil, nil
	if not (row and dir ~= 0) then return end
	e.exitDir = dir
	local l, rr = row:GetLeft(), row:GetRight()
	local sw = UIParent:GetWidth() or 1920
	if dir > 0 and l then e.exitDist = math.max(0, sw - l + 20)
	elseif dir < 0 and rr then e.exitDist = rr + 20 end
end

local function FeedPush(e)
	-- merge: same item stacks, money pools onto a single row
	for _, x in ipairs(feedEntries) do
		if (e.money and x.money) or (e.link and x.link == e.link) then
			if e.money then
				x.copper = (x.copper or 0) + (e.copper or 0)
				x.text = CopperText(x.copper) or e.text
			else
				x.count = x.count + e.count
			end
			x.t = GetTime()
			x.fading, x.alpha = false, 1
			x.slide, x.exitDir, x.exitDist = nil, nil, nil
			FeedLayout()
			return
		end
	end
	tinsert(feedEntries, 1, e)
	while #feedEntries > (db.feedMax or 6) do tremove(feedEntries) end
	FeedLayout()
end

local function OnFeedLootMsg(_, msg)
	if not db.feed or not feed then return end
	if type(msg) ~= "string" or IsSecret(msg) then return end
	if not itemPats then BuildFeedPatterns() end
	for _, p in ipairs(itemPats) do
		if msg:match(p) then
			local link = msg:match("(|Hitem:.-|h%[.-%]|h)")
			if not link then return end
			local name = link:match("%[(.-)%]") or link
			local count = tonumber(msg:match("x(%d+)")) or 1
			local quality, icon
			if GetItemInfo then
				quality = select(3, GetItemInfo(link))
				icon = select(10, GetItemInfo(link))
			end
			FeedPush({ link = link, name = name, count = count,
				quality = quality, icon = icon, t = GetTime() })
			return
		end
	end
end

local function OnFeedMoneyMsg(_, msg)
	if not db.feed or not feed then return end
	if type(msg) ~= "string" or IsSecret(msg) then return end
	if not moneyPats then BuildFeedPatterns() end
	for _, p in ipairs(moneyPats) do
		local coins = msg:match(p)
		if coins then
			FeedPush({ money = true, copper = MoneyToCopper(coins),
				text = coins, t = GetTime() })
			return
		end
	end
end

local function BuildFeed()
	if feed then return end
	feed = CreateFrame("Frame", "SentiUILootFeed", UIParent)
	feed:SetSize(240, FEED_ROW_H)
	-- default: above the right chat panel; the mover takes it anywhere
	local rp = _G.SentiUIRightChatPanel
	if rp then
		feed:SetPoint("BOTTOMLEFT", rp, "TOPLEFT", 2, 30)
	else
		feed:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -40, 320)
	end
	feed:SetFrameStrata("MEDIUM")
	feed:EnableMouse(false) -- rows take the clicks
	S.Movers.Register(feed, "loot.feed", L["Loot feed"])
	feed:SetScript("OnUpdate", function(_, dt)
		local now, hold = GetTime(), db.feedHold or 4
		local dirty = false
		for i = #feedEntries, 1, -1 do
			local e = feedEntries[i]
			local row = feedRows[i]
			if e.fading then
				e.alpha = (e.alpha or 1) - (dt or 0.016) * 2
				if e.alpha <= 0 then
					tremove(feedEntries, i)
					dirty = true
				elseif e.exitDir and e.exitDist then
					-- fly to the screen edge: progress 0..1 eased in so the
					-- row accelerates, reaching the edge as the alpha dies
					local f = 1 - e.alpha
					e.slide = e.exitDir * (f * f) * e.exitDist
					dirty = true
				elseif row then
					row:SetAlpha(e.alpha)
				end
			elseif now - e.t > hold then
				-- rows under the mouse hold their fade so the tooltip stays
				if not (row and row:IsMouseOver()) then
					e.fading = true
					StartExit(e, row)
				end
			end
		end
		if dirty then FeedLayout() end
	end)
	feed:SetShown(db.feed)
end

-- enable / settings ------------------------------------------------------------------
function Core.SettingChanged(mod, path)
	if not Core.enabled then return end
	if path == "lootSkin" then UpdateLootFrame() end
	if path == "rollSkin" then UpdateRollFrames() end
	if path == "lootWindow" then
		UpdateLootWindow()
		if db.lootWindow then
			KillBlizzardLoot()
		else
			-- give the game's frame back when our window turns off
			SilenceBlizzardLoot(false)
			local lf = _G.LootFrame
			if lf then
				lf:SetAlpha(1)
				lf:EnableMouse(true)
			end
		end
		-- the mover handle's active gate changed with the setting
		if S.Movers.unlocked then S.Movers.Recheck() end
	end
	if path == "feed" then
		BuildFeed()
		if feed then feed:SetShown(db.feed) end
	end
	if path == "feedMax" then
		while #feedEntries > (db.feedMax or 6) do tremove(feedEntries) end
		FeedLayout()
	end
end

function Core.Enable(mod)
	if Core.enabled then return end
	Core.enabled = true
	db = mod.db

	-- LOOT_* fires inside the client's loot-window dispatch; running our
	-- window update there taints the client's follow-up work in that same
	-- dispatch. Flag it and apply a frame later instead.
	local lootDirty
	local function QueueLootUpdate()
		if lootDirty then return end
		lootDirty = true
		C_Timer.After(0, function()
			lootDirty = nil
			S.SafeCall("loot:update", UpdateLootWindow)
		end)
	end
	S.RegisterEvent("LOOT_READY", function(_, autoloot)
		-- LootSlot inside the loot dispatch writes game state tainted;
		-- run the fast-loot pass on the next frame like the window update
		local arg = autoloot
		C_Timer.After(0, function()
			S.SafeCall("loot:ready", OnLootReady, nil, arg)
		end)
		QueueLootUpdate()
	end)
	for _, ev in ipairs({ "LOOT_OPENED", "LOOT_SLOT_CHANGED", "LOOT_SLOT_CLEARED" }) do
		S.RegisterEvent(ev, function(...)
			-- kill the Blizzard frame in the SAME dispatch, not a frame
			-- later: QueueLootUpdate defers via C_Timer and the alpha kill
			-- landed after the window had already rendered once - the
			-- occasional visible Blizzard loot flash the user reported
			KillBlizzardLoot()
			QueueLootUpdate()
		end)
	end
	-- belt on top of the event path: Blizzard's own show/update routines
	-- re-show and re-lay-out the frame - alpha + mouse go back to 0
	-- right inside their call, before the next render pass. Guarded:
	-- hooksecurefunc is a FrameXML util, not guaranteed on this client.
	if type(hooksecurefunc) == "function" then
		if type(_G.LootFrame_Show) == "function" then
			hooksecurefunc("LootFrame_Show", KillBlizzardLoot)
		end
		if type(_G.LootFrame_Update) == "function" then
			hooksecurefunc("LootFrame_Update", KillBlizzardLoot)
		end
	end
	S.RegisterEvent("LOOT_CLOSED", function()
		-- a full bag closes the loot session with items still in it; the
		-- count is only settled a frame later. Re-run the window update:
		-- leftovers keep it open, an empty corpse lets it close
		C_Timer.After(0, function()
			if db then S.SafeCall("loot:closed", UpdateLootWindow) end
		end)
	end)

	-- the game's loot frame must stay out of the way while ours is
	-- enabled - but NEVER Hide() it: on this client LootFrame's OnHide
	-- calls CloseLoot(), so hiding it ends the loot session instantly
	-- (the window flashes open and dies). Alpha + mouse-kill instead.
	-- WatchShown, not OnShow: an insecure script on a client frame runs
	-- inside its show dispatch and taints the client's follow-up calls.
	-- The resolver form matters: LootFrame can be load-on-demand on this
	-- client, so a watch on a nil frame would never register.
	S.WatchShown(function() return _G.LootFrame end, function(f)
		UpdateLootFrame()
		KillBlizzardLoot()
	end)

	-- build the window right away (it stays hidden until loot): the mover
	-- otherwise only registers on the first loot and the window is missing
	-- from move mode until then
	BuildLootWindow()

	-- loot feed: own item + money lines become fading rows
	BuildFeed()
	S.RegisterEvent("CHAT_MSG_LOOT", OnFeedLootMsg)
	S.RegisterEvent("CHAT_MSG_MONEY", OnFeedMoneyMsg)

	-- chat filter
	if ChatFrame_AddMessageEventFilter then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_LOOT", LootFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_MONEY", LootFilter)
	end

	-- loot log
	S.RegisterEvent("CHAT_MSG_LOOT", OnLootMsg)
	SLASH_SENTILOOTLOG1 = "/slootlog"
	SLASH_SENTILOOTLOG2 = "/sll"
	SlashCmdList.SENTILOOTLOG = function() Core.ToggleHistory() end

	-- skins: restyle behind the game's own layout calls
	S.RegisterEvent("START_LOOT_ROLL", function(_, rollID)
		if rollID ~= nil and not IsSecret(rollID) then
			pendingRolls[rollID] = true
		end
		C_Timer.After(0.1, UpdateRollFrames)
	end)
	S.RegisterEvent("CANCEL_LOOT_ROLL", function(_, rollID)
		if rollID ~= nil then pendingRolls[rollID] = nil end
		UpdateRollFrames()
	end)
	-- every pending roll resolved at once: drop them all instead of
	-- waiting for the per-card timeout cleanup
	S.RegisterEvent("LOOT_ROLLS_COMPLETE", function()
		wipe(pendingRolls)
		UpdateRollFrames()
	end)
	-- the container owns the visible frames on this client; its own
	-- add/update calls are the moment to skin them
	for _, fnName in ipairs({ "GroupLootContainer_AddFrame", "GroupLootContainer_Update" }) do
		if type(_G[fnName]) == "function" then
			hooksecurefunc(fnName, function() UpdateRollFrames() end)
		end
	end
	-- polling fallback while a roll frame is up (buttons appear per
	-- frame); it also keeps the panel docked and hides it when the
	-- last roll resolves; RollTick drives the countdown lines smoothly
	local poll = CreateFrame("Frame")
	poll.elapsed = 0
	poll:SetScript("OnUpdate", function(self, dt)
		RollTick(dt)
		self.elapsed = self.elapsed + (dt or 0)
		if self.elapsed < 0.5 then return end
		self.elapsed = 0
		local any = false
		EachRollFrame(function(f)
			if f.IsShown and f:IsShown() then any = true end
		end)
		if any or next(pendingRolls) or (rollPanel and rollPanel:IsShown()) then
			UpdateRollFrames()
		end
	end)
end
