-- luacheck: read globals CreateFrame GameTooltip C_Map GetCursorPosition SetCursor ResetCursor GetTime
local _, ns = ...

-- Dungeon map page for the compendium. The map art is always shown in a
-- 3:2 field (no stretching), centred in the panel; the mouse wheel zooms
-- around the cursor and the left button drags the zoomed map. Pins:
-- boss portraits, entrance icons, ladders between floors, numbered
-- markers/statues and quest symbols.
local L = ns.L
local W = ns.Widgets
local BP = ns.BossPortrait

local M = {}
ns.DungeonMap = M

local MEDIA = "Interface\\AddOns\\SentiUI_Journal\\Media\\Compendium\\"
local ALIAS = { esMX = "esES", ptPT = "ptBR", enGB = "enUS" }
local STATUE = { texture = MEDIA .. "Statue", bottom = 198 / 256, aspect = 128 / 198, headX = 0.33 }

local function Txt(key, ...)
	local all = ns.MapText or {}
	local lang = GetLocale and GetLocale() or "enUS"
	lang = ALIAS[lang] or lang
	local s = (all[lang] and all[lang][key]) or (all.enUS and all.enUS[key]) or key
	if select("#", ...) > 0 then
		local ok, r = pcall(string.format, s, ...)
		return ok and r or s
	end
	return s
end
M.Text = Txt

local function Font(large)
	if large then
		return _G.SystemFont_Shadow_Large_Outline and "SystemFont_Shadow_Large_Outline" or "GameFontNormalLarge"
	end
	return _G.SystemFont_Outline and "SystemFont_Outline" or "GameFontNormal"
end

local function Tip(self)
	local o = self.owner or self
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(o.title or "", 1, 0.82, 0)
	if o.body then
		GameTooltip:AddLine(o.body, 1, 1, 1, true)
	end
	GameTooltip:Show()
end
local function TipOff()
	GameTooltip:Hide()
end

local function BossScale()
	local v = ns.db and tonumber(ns.db.mapBossScale)
	return math.max(0, math.min(1, v or 0.9))
end

local function Norm(s)
	if type(s) ~= "string" then
		return nil
	end
	return (s:lower():gsub("[^%w\128-\255]", ""))
end

local found = {}
-- maps of the client whose name matches one of the candidates and that have art
local function FindFloors(dungeon, names)
	if found[dungeon] then
		return found[dungeon]
	end
	local wanted = {}
	for _, n in ipairs(names) do
		local k = Norm(n)
		if k and k ~= "" then
			wanted[k] = true
		end
	end
	local out = {}
	if C_Map and C_Map.GetMapInfo and C_Map.GetMapArtLayers and C_Map.GetMapArtLayerTextures then
		for id = 1, 3000 do
			local ok, info = pcall(C_Map.GetMapInfo, id)
			if ok and type(info) == "table" and wanted[Norm(info.name) or ""] then
				local okL, layers = pcall(C_Map.GetMapArtLayers, id)
				local okT, tex = pcall(C_Map.GetMapArtLayerTextures, id, 1)
				if okL and type(layers) == "table" and layers[1] and okT and type(tex) == "table" and #tex > 0 then
					out[#out + 1] = { uiMapID = id, label = info.name }
				end
			end
		end
	end
	found[dungeon] = out
	return out
end

-- opts: onBoss(index), locBoss(name), locQuest(id, field), dungeons() -> ns.DB
function M.Create(parent, opts)
	local self = { zoom = 1, panX = 0, panY = 0, floor = 1 }

	local panel = CreateFrame("Frame", nil, parent)
	panel:SetClipsChildren(true)
	panel:EnableMouse(true)
	panel:EnableMouseWheel(true)
	local bg = panel:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)
	self.panel = panel

	local holder = CreateFrame("Frame", nil, panel)
	holder:SetClipsChildren(true)
	self.holder = holder

	local tiles, markers, entrances, ladders, numbers, quests, turnins, floorBtns =
		{}, {}, {}, {}, {}, {}, {}, {}

	local noMap = W.Text(panel, "GameFontDisable", W.MUTED)
	noMap:SetPoint("CENTER")
	noMap:SetText(L.DJ_NO_MAP)
	noMap:Hide()

	---------------------------------------------------------
	-- zoom / pan
	---------------------------------------------------------
	local function Position()
		local hw, hh = holder:GetWidth() or 0, holder:GetHeight() or 0
		local maxX, maxY = 0, 0
		if self.zoom > 1.001 then
			maxX, maxY = hw / 2, hh / 2
		end
		self.panX = math.max(-maxX, math.min(maxX, self.panX))
		self.panY = math.max(-maxY, math.min(maxY, self.panY))
		holder:ClearAllPoints()
		holder:SetPoint("CENTER", panel, "CENTER", self.panX, self.panY)
	end

	function self:ResetView()
		self.zoom, self.panX, self.panY = 1, 0, 0
	end

	panel:SetScript("OnMouseWheel", function(frame, delta)
		if not self.data then
			return
		end
		local old = self.zoom
		local new = math.max(1, math.min(4, old * (delta > 0 and 1.25 or 0.8)))
		if math.abs(new - old) < 0.001 then
			return
		end
		local scale = frame:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		local mx = cx / scale - (frame:GetLeft() or 0) - (frame:GetWidth() or 0) / 2
		local my = cy / scale - (frame:GetBottom() or 0) - (frame:GetHeight() or 0) / 2
		local k = new / old
		self.panX = mx - (mx - self.panX) * k
		self.panY = my - (my - self.panY) * k
		if new <= 1.001 then
			self.panX, self.panY = 0, 0
		end
		self.zoom = new
		self:Render()
	end)

	local function StopDrag(frame)
		if not frame.drag then
			return
		end
		frame.drag = nil
		if ResetCursor then
			pcall(ResetCursor)
		end
	end
	panel:SetScript("OnMouseDown", function(frame, button)
		if button ~= "LeftButton" or self.zoom <= 1.001 then
			return
		end
		local scale = frame:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		frame.drag = { x = cx / scale, y = cy / scale, px = self.panX, py = self.panY }
		if SetCursor then
			pcall(SetCursor, "Interface\\CURSOR\\UI-Cursor-Move")
		end
	end)
	panel:HookScript("OnMouseUp", function(frame, button)
		if button == "LeftButton" then
			StopDrag(frame)
		end
	end)
	-- no OnHide hook: the journal window is in UISpecialFrames, so
	-- OnHide runs inside the Escape dispatch and taints the engine's
	-- protected spell-stop calls. A stale drag state is cleared when
	-- the map shows again instead.
	panel:HookScript("OnShow", function(frame) frame.drag = nil end)
	-- no GLOBAL_MOUSE_UP: the event fires inside the input dispatch that
	-- delivers the click to a button - insecure Lua there taints the whole
	-- dispatch and kills the protected call after it (Reload in the addon
	-- list, SpellStopCasting on Escape, secret compares on panel opens).
	-- The button state polls fine in OnUpdate instead.
	panel:SetScript("OnUpdate", function(frame)
		local d = frame.drag
		if not d then
			return
		end
		local down = (IsMouseButtonDown and IsMouseButtonDown("LeftButton"))
			or (IsLeftButtonDown and IsLeftButtonDown())
		if down == false then
			StopDrag(frame)
			return
		end
		local scale = frame:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		self.panX = d.px + (cx / scale - d.x)
		self.panY = d.py + (cy / scale - d.y)
		Position()
	end)
	panel:SetScript("OnSizeChanged", function(_, w, h)
		if w > 10 and h > 10 and self.data and panel:IsVisible() then
			self:Render()
		end
	end)

	---------------------------------------------------------
	-- boss icon size control (bottom left)
	---------------------------------------------------------
	local sizer = CreateFrame("Frame", nil, panel, "BackdropTemplate")
	sizer:SetSize(100, 46)
	sizer:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	sizer:SetBackdropColor(0, 0, 0, 0.75)
	sizer:SetBackdropBorderColor(0.45, 0.38, 0.25, 1)
	sizer:SetPoint("BOTTOMLEFT", 8, 8)
	sizer:SetFrameLevel(holder:GetFrameLevel() + 30)
	sizer.label = sizer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sizer.label:SetPoint("TOP", 0, -6)
	sizer.label:SetText(Txt("MAP_BOSS_ICONS"))
	sizer.value = sizer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sizer.value:SetWidth(36)
	sizer.value:SetPoint("BOTTOM", 0, 9)
	local function SizerBtn(text, delta, anchor, rel)
		local b = W.Button(sizer, 22, 20, text)
		b:SetPoint(anchor, sizer.value, rel, 0, 0)
		b:SetScript("OnClick", function()
			if ns.db then
				ns.db.mapBossScale = math.floor(math.max(0, math.min(1, BossScale() + delta)) * 10 + 0.5) / 10
			end
			self:Render()
		end)
		return b
	end
	sizer.minus = SizerBtn("-", -0.1, "RIGHT", "LEFT")
	sizer.plus = SizerBtn("+", 0.1, "LEFT", "RIGHT")
	sizer:SetWidth(math.max(100, (sizer.label:GetStringWidth() or 60) + 14))

	---------------------------------------------------------
	-- pools
	---------------------------------------------------------
	local function Pool(list, i, make)
		local f = list[i]
		if not f then
			f = make()
			list[i] = f
		end
		if f:GetParent() ~= holder then
			f:SetParent(holder)
		end
		return f
	end
	local function HideFrom(list, from)
		for i = from, #list do
			list[i]:Hide()
		end
	end

	local function MakeMarker()
		local m = CreateFrame("Button", nil, holder)
		m.portrait = m:CreateTexture(nil, "ARTWORK")
		m.portrait:SetAllPoints()
		m.border = m:CreateTexture(nil, "OVERLAY")
		m.border:SetPoint("CENTER")
		m.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
		m.border:SetTexCoord(0, 0.6, 0, 0.6)
		m:SetScript("OnEnter", function(frame)
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(frame.bossName or "")
			if frame.questTitle then
				GameTooltip:AddLine(frame.questTitle, 1, 0.82, 0)
				GameTooltip:AddLine(Txt("MAP_QUEST_TARGET"), 0.92, 0.92, 0.92)
			end
			GameTooltip:Show()
		end)
		m:SetScript("OnLeave", TipOff)
		return m
	end

	local function MakeEntrance()
		local e = CreateFrame("Frame", nil, holder)
		e.icon = e:CreateTexture(nil, "OVERLAY")
		e.icon:SetAllPoints()
		local ok = e.icon.SetAtlas and pcall(e.icon.SetAtlas, e.icon, "Dungeon", false)
		if not ok then
			e.icon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
			e.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		end
		e.label = e:CreateFontString(nil, "OVERLAY", Font(true))
		e.label:SetShadowColor(0, 0, 0, 1)
		e.label:SetShadowOffset(1, -1)
		return e
	end

	local function MakeLadder()
		local t = CreateFrame("Button", nil, holder)
		t.arrow = t:CreateTexture(nil, "OVERLAY")
		t.arrow:SetTexture(MEDIA .. "Ladder")
		t.arrow:SetAllPoints()
		t.label = t:CreateFontString(nil, "OVERLAY", Font(false))
		t.label:SetShadowColor(0, 0, 0, 1)
		t.label:SetShadowOffset(1, -1)
		t.label:SetTextColor(0.35, 1, 0.35)
		t.label:SetPoint("BOTTOM", t, "TOP", 0, 1)
		t:SetScript("OnClick", function(frame)
			if frame.toFloor then
				self.floor = frame.toFloor
				self:Render()
			end
		end)
		t:SetScript("OnEnter", function(frame)
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
			GameTooltip:SetText(frame.toFloor and Txt("MAP_FLOOR", frame.toFloor) or frame.noteText or "", 0.35, 1, 0.35)
			GameTooltip:Show()
		end)
		t:SetScript("OnLeave", TipOff)
		return t
	end

	local function MakeNumber()
		local m = CreateFrame("Frame", nil, holder)
		m:EnableMouse(true)
		m.statue = m:CreateTexture(nil, "ARTWORK")
		m.statue:SetAllPoints()
		m.statue:Hide()
		m.badge = CreateFrame("Frame", nil, m)
		m.badge:EnableMouse(true)
		m.badge.owner = m
		m.rim = m.badge:CreateTexture(nil, "ARTWORK", nil, 1)
		m.rim:SetAllPoints()
		m.rim:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
		m.rim:SetVertexColor(0.95, 0.74, 0.25, 1)
		m.disc = m.badge:CreateTexture(nil, "ARTWORK", nil, 2)
		m.disc:SetPoint("TOPLEFT", 2, -2)
		m.disc:SetPoint("BOTTOMRIGHT", -2, 2)
		m.disc:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
		m.disc:SetVertexColor(0.10, 0.07, 0.04, 0.95)
		m.text = m.badge:CreateFontString(nil, "OVERLAY", Font(false))
		m.text:SetPoint("CENTER")
		m.text:SetTextColor(1, 0.84, 0.3)
		m:SetScript("OnEnter", Tip)
		m:SetScript("OnLeave", TipOff)
		m.badge:SetScript("OnEnter", Tip)
		m.badge:SetScript("OnLeave", TipOff)
		return m
	end

	local function MakeIcon(texture)
		return function()
			local q = CreateFrame("Frame", nil, holder)
			q:EnableMouse(true)
			q.icon = q:CreateTexture(nil, "OVERLAY")
			q.icon:SetAllPoints()
			q.icon:SetTexture(texture)
			q:SetScript("OnEnter", Tip)
			q:SetScript("OnLeave", TipOff)
			return q
		end
	end

	---------------------------------------------------------
	-- bosses without a position on the map: a clickable list
	---------------------------------------------------------
	local list = CreateFrame("Frame", nil, panel, "BackdropTemplate")
	list:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	list:SetBackdropColor(0, 0, 0, 0.75)
	list:SetBackdropBorderColor(0.45, 0.38, 0.25, 1)
	list:SetPoint("BOTTOMRIGHT", -8, 8)
	list:SetFrameLevel(holder:GetFrameLevel() + 30)
	list.title = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	list.title:SetPoint("TOPLEFT", 10, -8)
	list.title:SetText(L.DJ_UNPLACED)
	list.rows = {}
	list:Hide()

	function self:ListUnplaced()
		local data, rec = self.data, opts.dungeons and opts.dungeons()[self.dungeon]
		for _, r in ipairs(list.rows) do
			r:Hide()
		end
		local placed = {}
		for _, b in ipairs(data and data.bosses or {}) do
			placed[b.name] = true
		end
		local n, width = 0, list.title:GetStringWidth() or 100
		for idx, b in ipairs(rec and rec.bosses or {}) do
			if not placed[b.name] and not b.trash and not b.recipeTab and not b.lootChest and not b.children then
				n = n + 1
				local r = list.rows[n]
				if not r then
					r = CreateFrame("Button", nil, list)
					r:SetHeight(16)
					r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
					r.text:SetPoint("LEFT")
					r:SetScript("OnEnter", function(frame)
						frame.text:SetTextColor(0.92, 0.68, 0.20)
					end)
					r:SetScript("OnLeave", function(frame)
						frame.text:SetTextColor(1, 1, 1)
					end)
					list.rows[n] = r
				end
				r.text:SetText(opts.locBoss and opts.locBoss(b.name) or b.name)
				r.idx = idx
				r:SetScript("OnClick", function(frame)
					if opts.onBoss then
						opts.onBoss(frame.idx)
					end
				end)
				r:ClearAllPoints()
				r:SetPoint("TOPLEFT", 10, -24 - (n - 1) * 16)
				r:SetWidth(math.max(60, r.text:GetStringWidth() + 4))
				width = math.max(width, r.text:GetStringWidth())
				r:Show()
			end
		end
		list:SetShown(n > 0)
		list:SetSize(width + 24, 32 + n * 16)
	end

	---------------------------------------------------------
	-- render
	---------------------------------------------------------
	function self:Show(dungeon, data, floor)
		if data and data.find and not data.resolved then
			local names = {}
			for _, n in ipairs(data.find) do
				names[#names + 1] = n
			end
			local loc = opts.locDungeon and opts.locDungeon(dungeon)
			if loc then
				names[#names + 1] = loc
			end
			data.floors = FindFloors(dungeon, names)
			data.resolved = true
		end
		self.dungeon, self.data = dungeon, data
		local saved = ns.db and ns.db.mapFloors and ns.db.mapFloors[dungeon]
		if data and type(saved) == "number" and saved >= 1 and saved <= #(data.floors or {}) then
			floor = floor or saved
		end
		self.floor = floor or (data and data.defaultFloor) or (data and data.entrance and data.entrance.floor) or 1
		self:ResetView()
		self:Render()
	end

	function self:Render()
		for _, t in ipairs(tiles) do
			t:Hide()
		end
		local data = self.data
		local usable = data ~= nil and #(data.floors or {}) > 0
		noMap:SetShown(not usable)
		holder:SetShown(usable)
		sizer:SetShown(usable)
		if not usable then
			HideFrom(floorBtns, 1)
			self:ListUnplaced()
			return
		end
		local pw, ph = panel:GetWidth() or 0, panel:GetHeight() or 0
		if pw < 40 or ph < 40 then
			return
		end

		local floors = data.floors or {}
		local floorIndex = math.max(1, math.min(#floors, self.floor or 1))
		self.floor = floorIndex
		if ns.db and self.dungeon then
			ns.db.mapFloors = ns.db.mapFloors or {}
			ns.db.mapFloors[self.dungeon] = floorIndex
		end
		local fl = floors[floorIndex]
		if not fl then
			return
		end
		local dungeonRec = opts.dungeons and opts.dungeons()[self.dungeon]

		-- fit the 3:2 art into the page, then apply zoom and pan
		local availW, availH = math.max(200, pw - 16), math.max(140, ph - 16)
		local baseW, baseH = availW, availW / 1.5
		if baseH > availH then
			baseH, baseW = availH, availH * 1.5
		end
		baseW, baseH = math.floor(baseW), math.floor(baseH)
		local artW, artH = math.floor(baseW * self.zoom), math.floor(baseH * self.zoom)
		holder:SetSize(artW, artH)
		Position()

		local function Tile(i)
			local t = tiles[i]
			if not t then
				t = holder:CreateTexture(nil, "ARTWORK")
				tiles[i] = t
			end
			t:ClearAllPoints()
			return t
		end

		if fl.texture then
			local t = Tile(1)
			t:SetAllPoints(holder)
			t:SetTexture(fl.texture)
			t:SetTexCoord(0, fl.texRight or 1, 0, fl.texBottom or 1)
			t:SetDrawLayer("ARTWORK", 0)
			t:Show()
		else
			-- no packaged picture: the client's own map tiles
			local textures, layer
			if fl.uiMapID and C_Map and C_Map.GetMapArtLayers and C_Map.GetMapArtLayerTextures then
				local okL, layers = pcall(C_Map.GetMapArtLayers, fl.uiMapID)
				if okL and type(layers) == "table" and layers[1] then
					local okT, tx = pcall(C_Map.GetMapArtLayerTextures, fl.uiMapID, 1)
					if okT and type(tx) == "table" and #tx > 0 then
						layer, textures = layers[1], tx
					end
				end
			end
			if textures and layer then
				local layerW = tonumber(layer.layerWidth) or 1002
				local layerH = tonumber(layer.layerHeight) or 668
				local tileW = tonumber(layer.tileWidth) or 256
				local tileH = tonumber(layer.tileHeight) or 256
				local cols = math.max(1, math.ceil(layerW / tileW))
				local sx, sy = artW / layerW, artH / layerH
				for i = 1, #textures do
					local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
					local t = Tile(i)
					t:SetSize(tileW * sx, tileH * sy)
					t:SetPoint("TOPLEFT", holder, "TOPLEFT", col * tileW * sx, -row * tileH * sy)
					local loaded = t:SetTexture(textures[i])
					if loaded == false and fl.tiles then
						t:SetTexture(fl.tiles .. i)
					end
					t:SetTexCoord(0, 1, 0, 1)
					t:SetDrawLayer("ARTWORK", 0)
					t:Show()
				end
			elseif fl.tiles then
				local scale = artW / 1002
				for i = 1, 12 do
					local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
					local t = Tile(i)
					t:SetSize(256 * scale, 256 * scale)
					t:SetPoint("TOPLEFT", holder, "TOPLEFT", col * 256 * scale, -row * 256 * scale)
					t:SetTexture(fl.tiles .. i)
					t:SetTexCoord(0, 1, 0, 1)
					t:SetDrawLayer("ARTWORK", 0)
					t:Show()
				end
			end
			-- parchment patches that cover the map's printed title banner
			for p, patch in ipairs(fl.patches or {}) do
				local t = Tile(12 + p)
				t:SetDrawLayer("ARTWORK", 1)
				t:SetPoint("TOPLEFT", holder, "TOPLEFT", patch.x0 * artW, -patch.y0 * artH)
				t:SetPoint("BOTTOMRIGHT", holder, "TOPLEFT", patch.x1 * artW, -patch.y1 * artH)
				t:SetTexture(patch.tex)
				t:SetTexCoord(0, 1, 0, 1)
				t:SetAlpha(patch.alpha or 1)
				t:Show()
			end
		end

		-- floor selector (several floors only)
		for i = 1, math.max(#floors, #floorBtns) do
			local btn = floorBtns[i]
			if i <= #floors and #floors > 1 then
				if not btn then
					btn = W.Button(panel, 60, 20)
					btn:SetScript("OnClick", function(frame)
						self.floor = frame.floorIndex
						self:ResetView()
						self:Render()
					end)
					btn:SetScript("OnEnter", function(frame)
						if frame.floorLabel then
							GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
							GameTooltip:SetText(frame.floorLabel, 1, 0.82, 0)
							GameTooltip:Show()
						end
					end)
					btn:SetScript("OnLeave", TipOff)
					floorBtns[i] = btn
				end
				btn.floorIndex = i
				btn.floorLabel = floors[i].label
				btn:SetText(Txt("MAP_FLOOR", i))
				local fs = btn:GetFontString()
				btn:SetSize(math.max(70, math.ceil((fs and fs:GetStringWidth() or 50) + 20)), 22)
				btn:ClearAllPoints()
				btn:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10 - (i - 1) * 24)
				btn:SetFrameLevel(holder:GetFrameLevel() + 30)
				if i == floorIndex then
					btn:Disable()
				else
					btn:Enable()
				end
				btn:Show()
			elseif btn then
				btn:Hide()
			end
		end

		-- bosses
		local size = math.floor(math.max(26, math.floor(baseH * 0.095)) * BossScale())
		sizer.value:SetText(math.floor(BossScale() * 100 + 0.5) .. "%")
		sizer.minus:SetEnabled(BossScale() > 0)
		sizer.plus:SetEnabled(BossScale() < 1)
		local shown = 0
		for _, mb in ipairs(data.bosses or {}) do
			local questEntry
			if mb.quest then
				for _, q in ipairs(dungeonRec and dungeonRec.quests or {}) do
					if type(q) == "table" and q.id == mb.quest then
						questEntry = q
						break
					end
				end
			end
			if (mb.floor or 1) == floorIndex and not (mb.quest and not questEntry) then
				shown = shown + 1
				local m = Pool(markers, shown, MakeMarker)
				m:SetSize(size, size)
				m.border:SetSize(size * 1.55, size * 1.55)
				m:SetFrameLevel(holder:GetFrameLevel() + 10)
				if mb.quest then
					if not m.badge then
						m.badge = CreateFrame("Frame", nil, m)
						m.badge.icon = m.badge:CreateTexture(nil, "OVERLAY", nil, 2)
						m.badge.icon:SetAllPoints()
						m.badge.icon:SetTexture("Interface\\TargetingFrame\\PortraitQuestBadge")
					end
					local bs = math.max(22, math.floor(size * 0.85))
					m.badge:SetSize(bs, bs)
					m.badge:ClearAllPoints()
					m.badge:SetPoint("CENTER", m, "TOPRIGHT", -bs * 0.05, -bs * 0.05)
					m.badge:SetFrameLevel(m:GetFrameLevel() + 3)
					m.badge:Show()
					m.questTitle = opts.locQuest and opts.locQuest(mb.quest, "name") or (questEntry and questEntry.name)
				else
					if m.badge then
						m.badge:Hide()
					end
					m.questTitle = nil
				end
				local rec, idx
				for k, cand in ipairs(dungeonRec and dungeonRec.bosses or {}) do
					if cand.name == mb.name then
						rec, idx = cand, k
						break
					end
				end
				local has = BP and BP.Set(m.portrait, rec or { npcID = mb.npcID, name = mb.name })
				if not has then
					m.portrait:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
					m.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				end
				m.bossName = opts.locBoss and opts.locBoss(rec and rec.name or mb.name) or mb.name
				m:SetScript("OnClick", function()
					if idx and opts.onBoss then
						opts.onBoss(idx)
					end
				end)
				m:ClearAllPoints()
				m:SetPoint("CENTER", holder, "TOPLEFT", mb.x * artW, -(mb.y * artH))
				m:SetShown(size > 0)
			end
		end
		HideFrom(markers, shown + 1)

		-- entrances
		local entList = data.entrances or (data.entrance and { data.entrance }) or {}
		local es = 0
		for _, ent in ipairs(entList) do
			if (ent.floor or 1) == floorIndex then
				es = es + 1
				local e = Pool(entrances, es, MakeEntrance)
				local iconSize = math.max(22, math.floor(baseH * 0.075))
				e:SetSize(iconSize, iconSize)
				e:SetFrameLevel(holder:GetFrameLevel() + 15)
				e:ClearAllPoints()
				e:SetPoint("CENTER", holder, "TOPLEFT", ent.x * artW, -(ent.y * artH))
				e.label:SetText(Txt(ent.labelKey or "MAP_ENTRANCE"))
				local c = ent.color
				if c then
					e.label:SetTextColor(c[1], c[2], c[3])
				else
					e.label:SetTextColor(1, 0.82, 0)
				end
				e.label:ClearAllPoints()
				if ent.labelPos == "top" then
					e.label:SetPoint("BOTTOM", e, "TOP", 0, 1)
				elseif math.cos(math.rad(ent.angle or 0)) < -0.3 then
					e.label:SetPoint("RIGHT", e, "LEFT", -3, 0)
				else
					e.label:SetPoint("LEFT", e, "RIGHT", 3, 0)
				end
				e:Show()
			end
		end
		HideFrom(entrances, es + 1)

		-- ladders (floor changes) and hint spots
		local used = 0
		for _, tr in ipairs(data.transitions or {}) do
			if tr.floor == floorIndex and (floors[tr.to] or tr.note) then
				used = used + 1
				local t = Pool(ladders, used, MakeLadder)
				t.toFloor = tr.to
				local len = math.max(28, math.floor(baseH * 0.10))
				t:SetSize(len, len)
				t:SetFrameLevel(holder:GetFrameLevel() + 14)
				t:ClearAllPoints()
				t:SetPoint("CENTER", holder, "TOPLEFT", tr.x * artW, -(tr.y * artH))
				t.noteText = tr.note and Txt(tr.labelKey, tr.to) or nil
				t.label:SetText(tr.note and "" or Txt(tr.labelKey or "MAP_FLOOR", tr.to))
				t:Show()
			end
		end
		HideFrom(ladders, used + 1)

		-- numbered markers and statues
		local nn = 0
		for _, mk in ipairs(data.markers or {}) do
			if (mk.floor or 1) == floorIndex then
				nn = nn + 1
				local m = Pool(numbers, nn, MakeNumber)
				m.text:SetText(tostring(mk.text or mk.n or ""))
				m.title = mk.titleKey and Txt(mk.titleKey, mk.n) or nil
				if m.title and mk.dirKey then
					m.title = m.title .. " - " .. Txt(mk.dirKey)
				end
				local boss = mk.tipBoss and ((opts.locBoss and opts.locBoss(mk.tipBoss)) or mk.tipBoss) or nil
				m.body = mk.tipKey and Txt(mk.tipKey, boss or "") or nil
				m:ClearAllPoints()
				m:SetPoint("CENTER", holder, "TOPLEFT", mk.x * artW, -(mk.y * artH))
				m.badge:ClearAllPoints()
				if mk.statue then
					local sh = math.max(26, math.floor(baseH * 0.08))
					local sw = math.floor(sh * STATUE.aspect + 0.5)
					local bs = math.max(14, math.floor(baseH * 0.042))
					m:SetSize(sw, sh)
					m.statue:SetTexture(STATUE.texture)
					if mk.flip then
						m.statue:SetTexCoord(1, 0, 0, STATUE.bottom)
					else
						m.statue:SetTexCoord(0, 1, 0, STATUE.bottom)
					end
					m.statue:Show()
					m:SetFrameLevel(holder:GetFrameLevel() + 8)
					m.badge:SetSize(bs, bs)
					local hx = mk.flip and (1 - STATUE.headX) or STATUE.headX
					m.badge:SetPoint("CENTER", m, "TOPLEFT", hx * sw, bs * 0.22)
				else
					local s = math.max(18, math.floor(baseH * 0.055))
					m:SetSize(s, s)
					m.statue:Hide()
					m:SetFrameLevel(holder:GetFrameLevel() + 15)
					m.badge:SetAllPoints(m)
				end
				m.badge:SetFrameLevel(holder:GetFrameLevel() + 15)
				m.badge:Show()
				m:Show()
			end
		end
		HideFrom(numbers, nn + 1)

		-- quest turn-in spots (yellow ?)
		local nt = 0
		for _, t in ipairs(data.turnins or {}) do
			if (t.floor or 1) == floorIndex then
				nt = nt + 1
				local q = Pool(turnins, nt, MakeIcon("Interface\\GossipFrame\\ActiveQuestIcon"))
				q.title = t.npc and ((opts.locBoss and opts.locBoss(t.npc)) or t.npc) or ""
				q.body = Txt("TURN_IN_HERE")
				local s = math.max(24, math.floor(baseH * 0.08))
				q:SetSize(s, s)
				q:SetFrameLevel(holder:GetFrameLevel() + 16)
				q:ClearAllPoints()
				q:SetPoint("CENTER", holder, "TOPLEFT", t.x * artW, -(t.y * artH))
				q:Show()
			end
		end
		HideFrom(turnins, nt + 1)

		-- quest spots: ! where a quest starts, ? where it ends or is done
		local nq = 0
		for _, pin in ipairs((ns.MAP_QUEST_PINS or {})[self.dungeon] or {}) do
			if (pin.floor or 1) == floorIndex then
				nq = nq + 1
				local q = Pool(quests, nq, MakeIcon("Interface\\GossipFrame\\AvailableQuestIcon"))
				local lines, starts = {}, false
				local title
				for _, spot in ipairs(pin.spots or {}) do
					title = title or spot.name
					for _, qq in ipairs(spot.quests or {}) do
						local acts = {}
						for _, a in ipairs(qq.acts or {}) do
							acts[a] = true
						end
						starts = starts or acts.start
						local name = (opts.locQuest and opts.locQuest(qq.id, "name")) or qq.name or "?"
						local hint = acts.start and Txt("QUEST_STARTS_HERE") or (acts["end"] and Txt("TURN_IN_HERE"))
						if qq.textKey and ns.MapText then
							local txt = Txt(qq.textKey, qq.itemName or "")
							hint = txt ~= qq.textKey and txt or hint
						end
						lines[#lines + 1] = name .. (hint and (" - " .. hint) or "")
					end
				end
				q.icon:SetTexture(starts and "Interface\\GossipFrame\\AvailableQuestIcon"
					or "Interface\\GossipFrame\\ActiveQuestIcon")
				q.title = title or L.DJ_QUESTS
				q.body = table.concat(lines, "\n")
				local s = math.max(22, math.floor(baseH * 0.07))
				q:SetSize(s, s)
				q:SetFrameLevel(holder:GetFrameLevel() + 15)
				q:ClearAllPoints()
				q:SetPoint("CENTER", holder, "TOPLEFT", pin.x * artW, -(pin.y * artH))
				q:Show()
			end
		end
		HideFrom(quests, nq + 1)
		self:ListUnplaced()
	end

	return self
end
