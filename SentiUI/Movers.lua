-- Every movable SentiUI frame registers here; the move mode shows a drag
-- handle on each registered frame plus an alignment grid and an edit bar.
-- Ported to the proven SentinelForeverCore mechanics for this client:
--   * the real frame is moved via SetMovable + StartMoving (no manual
--     offset tracking on the handle)
--   * handles live on UIParent so even hidden/tiny frames keep a handle,
--     with a minimum grab size
--   * positions are saved relative to the NEAREST screen anchor (point +
--     offset in UIParent space) and restored with scale conversion
--   * frame:GetSize()/GetPoint() results can be secret on this client -
--     every read is guarded before it hits arithmetic
-- Extras on top of the SFC version: mouse-wheel scaling (opts.scale),
-- proxy movers, edge snapping (magnet), ESC via the edit bar, arrow-key
-- nudging of the selected handle.
local _, S = ...
local L = S.L
local C = S.colors

local M = {}
S.Movers = M

local entries, order, handles = {}, {}, {}
local gridFrame, dimFrame, editBar
local selected

local POINTS = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "TOP", "BOTTOM", "LEFT", "RIGHT", "CENTER" }
local POINT_COORDS = {
	TOPLEFT = { 0, 1 }, TOPRIGHT = { 1, 1 }, BOTTOMLEFT = { 0, 0 }, BOTTOMRIGHT = { 1, 0 },
	TOP = { 0.5, 1 }, BOTTOM = { 0.5, 0 }, LEFT = { 0, 0.5 }, RIGHT = { 1, 0.5 }, CENTER = { 0.5, 0.5 },
}
local SNAP = 8

-- this client ships the GLOBAL unpack; table.unpack may be missing here
local unpack = unpack or table.unpack

-- scaled frames report coordinates in their own (root-scale) units; the
-- saved offset lives in UIParent space, so convert through this factor
local function ToUI(frame)
	local ok, fs = pcall(frame.GetEffectiveScale, frame)
	local ok2, us = pcall(UIParent.GetEffectiveScale, UIParent)
	if not ok or not fs or S.IsSecret(fs) then fs = 1 end
	if not ok2 or not us or S.IsSecret(us) or us <= 0 then us = 1 end
	return fs / us
end

-- nearest screen anchor for a frame (in UIParent coordinate space).
-- Returns nil when the rect is unreadable - callers skip the save then:
-- storing a fake {BOTTOMLEFT,0,0} would teleport the frame into the
-- corner on the next apply, losing the real position.
local function NearestAnchor(frame)
	local f2u = ToUI(frame)
	local ok, cx, cy = pcall(frame.GetCenter, frame)
	local ok2, w, h = pcall(UIParent.GetSize, UIParent)
	if not ok or not cx or S.IsSecret(cx) or S.IsSecret(cy)
		or not ok2 or not w or S.IsSecret(w) or S.IsSecret(h) then
		return nil
	end
	cx, cy = cx * f2u, cy * f2u
	local ok3, fw, fh = pcall(frame.GetSize, frame)
	if not ok3 or S.IsSecret(fw) or S.IsSecret(fh) then fw, fh = 0, 0 end
	local best, bestDist, bx, by
	for _, p in ipairs(POINTS) do
		local c = POINT_COORDS[p]
		local px, py = c[1] * w, c[2] * h
		local fx = cx + (c[1] - 0.5) * fw * f2u
		local fy = cy + (c[2] - 0.5) * fh * f2u
		local d = (fx - px) ^ 2 + (fy - py) ^ 2
		if not bestDist or d < bestDist then
			bestDist, best, bx, by = d, p, fx - px, fy - py
		end
	end
	if not best then return nil end
	return best, bx or 0, by or 0
end

local function Place(frame, point, x, y)
	local f2u = ToUI(frame)
	frame:ClearAllPoints()
	frame:SetPoint(point, UIParent, point, x / f2u, y / f2u)
end

-- raw-anchor fallback for when rect math is impossible: GetCenter/GetSize
-- can come back secret inside hardware handlers (drag/key callbacks) on
-- this client. The frame's own first anchor against UIParent stores and
-- restores verbatim - same units out, same units in.
local function RawAnchor(frame)
	local ok, a1, rel, a3, x, y = pcall(frame.GetPoint, frame, 1)
	if not ok or not a1 or rel ~= UIParent then return nil end
	if S.IsSecret(a1) or S.IsSecret(x) or S.IsSecret(y) then return nil end
	return a1, a3 or a1, x or 0, y or 0
end

-- registration -------------------------------------------------------------------------
-- opts.scale:  truthy = mouse wheel on the handle scales the frame
-- opts.proxy:  the frame is placed by something else; the handle moves and
--              saves, opts.onMoved(key) is called - the frame is untouched
-- opts.active(): the handle only shows while this returns true
-- opts.onMoved(key): called after every move and reset
function M.Register(frame, key, label, default, opts)
	assert(type(frame) == "table" and type(key) == "string", "mover needs a frame and a key")
	assert(not entries[key], "mover already registered: " .. key)
	opts = opts or {}
	local e = { frame = frame, key = key, label = label, default = default,
		proxy = opts.proxy == true, scale = opts.scale, active = opts.active,
		onMoved = opts.onMoved }
	-- keep the frame's own anchor so a reset restores it live, no reload
	local ok, a1, a2, a3, a4, a5 = pcall(frame.GetPoint, frame, 1)
	if ok and a1 then e.defPoint = { a1, a2, a3, a4, a5 } end
	entries[key] = e
	order[#order + 1] = key
	if not e.proxy then
		pcall(frame.SetMovable, frame, true)
		pcall(frame.SetClampedToScreen, frame, true)
	end
	M.Apply(key)
	if M.unlocked then M.Recheck() end
end

function M.Get(key) return entries[key] end

function M.Entries()
	local i = 0
	return function()
		i = i + 1
		local key = order[i]
		if key then return key, entries[key] end
	end
end

local function pieceScale(e)
	if not e.scale then return nil end
	local g = S.DB.General()
	return (g.uiScale or 1) * ((g.frameScales or {})[e.key] or 1)
end

local function applyScale(e)
	local s = pieceScale(e)
	if not s or e.proxy then return end
	S.RunOutOfCombat(function()
		if e.frame.SetScale then pcall(e.frame.SetScale, e.frame, s) end
	end)
end

function M.Apply(key)
	local e = entries[key]
	if not e then return end
	if e.proxy then applyScale(e) return end
	local pos = S.DB.Positions()[key]
	S.RunOutOfCombat(function()
		if type(pos) == "table" and pos.point and pos.raw then
			-- verbatim anchor replay (the secret-reads fallback wrote it)
			pcall(e.frame.ClearAllPoints, e.frame)
			pcall(e.frame.SetPoint, e.frame, pos.point, UIParent,
				pos.rel or pos.point, pos.x or 0, pos.y or 0)
		elseif type(pos) == "table" and pos.point then
			pcall(Place, e.frame, pos.point, pos.x or 0, pos.y or 0)
		elseif type(pos) == "table" and type(pos.x) == "number" then
			-- legacy center-offset positions from the first mover pass
			pcall(e.frame.ClearAllPoints, e.frame)
			pcall(e.frame.SetPoint, e.frame, "CENTER", UIParent, "CENTER", pos.x, pos.y or 0)
		elseif e.defPoint then
			pcall(e.frame.ClearAllPoints, e.frame)
			pcall(e.frame.SetPoint, e.frame, unpack(e.defPoint))
		elseif type(e.default) == "table" then
			pcall(e.frame.ClearAllPoints, e.frame)
			pcall(e.frame.SetPoint, e.frame, "CENTER", UIParent, "CENTER", e.default.x or 0, e.default.y or 0)
		end
	end)
	applyScale(e)
end

function M.ApplyAll()
	for _, key in ipairs(order) do M.Apply(key) end
end

local function save(e)
	-- proxy movers carry their position on the handle, not the frame
	local src = (e.proxy and e.handle) or e.frame
	local point, x, y = NearestAnchor(src)
	if point then
		S.DB.Positions()[e.key] = { point = point, x = x, y = y }
	else
		-- rect reads came back secret: store the raw UIParent anchor
		-- instead - losing the position is the snap-back bug, a slightly
		-- different anchor shape is not
		local p, rp, rx, ry = RawAnchor(src)
		if not p then return end -- truly unreadable: keep the old position
		S.DB.Positions()[e.key] =
			{ point = p, rel = rp, x = rx, y = ry, raw = true }
	end
	if e.onMoved then S.SafeCall("mover:" .. e.key, e.onMoved, e.key) end
	S.Fire("MoversChanged")
end

-- public save for registered frames that are dragged directly, outside
-- move mode (e.g. bag windows by their title bar): persists the position
-- through the mover DB so Apply/Reset stay authoritative. The write is
-- deferred one tick because callers run inside drag handlers, where
-- rect reads on this client answer secret and the save would skip.
function M.Save(key)
	local e = entries[key]
	if not e then return end
	C_Timer.After(0, function() save(e) end)
end

function M.Reset(key)
	S.DB.Positions()[key] = nil
	S.DB.General().frameScales[key] = nil
	M.Apply(key)
	local e = entries[key]
	if e and e.onMoved then S.SafeCall("mover:" .. e.key, e.onMoved, e.key) end
	S.Fire("MoversChanged")
end

function M.ResetAll()
	wipe(S.DB.Positions())
	wipe(S.DB.General().frameScales)
	M.ApplyAll()
	if M.unlocked then M.Recheck() end
	S.Fire("MoversChanged")
end

-- snapping: screen edges/center and other movers (magnet), grid, or a plain
-- 8px nudge - applied on drag stop, saved through the same anchor logic
local function snapFrame(e)
	local g = S.DB.General()
	if not g.magnet then return end
	local f = e.frame
	local ok, fl, fr, fb, ft = pcall(function()
		return f:GetLeft(), f:GetRight(), f:GetBottom(), f:GetTop()
	end)
	if not ok or not fl or S.IsSecret(fl) then return end
	local fcx, fcy = (fl + fr) / 2, (fb + ft) / 2
	local okR, ul, ur, ub, ut = pcall(UIParent.GetRect, UIParent)
	if not okR or not ul or S.IsSecret(ul) then return end
	local ucx, ucy = (ul + ur) / 2, (ub + ut) / 2

	local dx, dy
	local bestX, bestY = SNAP + 1, SNAP + 1
	for _, t in ipairs({ ucx, ul, ur }) do
		for _, p in ipairs({ fcx, fl, fr }) do
			local d = math.abs(t - p)
			if d < bestX then bestX = d; dx = t - p end
		end
	end
	for _, t in ipairs({ ucy, ub, ut }) do
		for _, p in ipairs({ fcy, fb, ft }) do
			local d = math.abs(t - p)
			if d < bestY then bestY = d; dy = t - p end
		end
	end
	for _, key in ipairs(order) do
		local o = entries[key]
		if o ~= e and o.frame ~= f and o.frame:IsShown() then
			local ok2, ol, orr, ob, ot = pcall(function()
				return o.frame:GetLeft(), o.frame:GetRight(), o.frame:GetBottom(), o.frame:GetTop()
			end)
			if ok2 and ol and not S.IsSecret(ol) then
				for _, t in ipairs({ ol, orr, (ol + orr) / 2 }) do
					for _, p in ipairs({ fcx, fl, fr }) do
						local d = math.abs(t - p)
						if d < bestX then bestX = d; dx = t - p end
					end
				end
				for _, t in ipairs({ ob, ot, (ob + ot) / 2 }) do
					for _, p in ipairs({ fcy, fb, ft }) do
						local d = math.abs(t - p)
						if d < bestY then bestY = d; dy = t - p end
					end
				end
			end
		end
	end
	if not (dx or dy) then return end
	local point, x, y = NearestAnchor(f)
	if not point then return end
	Place(f, point, x + (dx or 0), y + (dy or 0))
end

-- move mode ------------------------------------------------------------------------------
local function entryShown(e)
	-- handles live on UIParent, so even a frame that is hidden right now
	-- keeps a placeable handle (SFC behaviour); only an active() gate or a
	-- missing frame keeps it away
	if not e.frame then return false end
	if e.active and not e.active() then return false end
	return true
end

local function RefreshHandle(e)
	local h, f = e.handle, e.frame
	if not h then return end
	if e.proxy then
		-- the frame stays put on purpose; the handle itself carries the
		-- position, so refresh it from the saved rect (or keep where it is)
		h:SetScale(1)
		local pos = S.DB.Positions()[e.key]
		if pos and pos.point then
			Place(h, pos.point, pos.x or 0, pos.y or 0)
		end
		return
	end
	local ok, w, hh = pcall(f.GetSize, f)
	if not ok or S.IsSecret(w) or S.IsSecret(hh) then w, hh = 0, 0 end
	local s = ToUI(f)
	h:SetScale(s > 0 and s or 1)
	h:ClearAllPoints()
	h:SetPoint("CENTER", f, "CENTER", 0, 0)
	h:SetSize(math.max(w or 0, 70), math.max(hh or 0, 26))
end

local function Select(e)
	if selected and selected.handle then
		selected.handle:EnableKeyboard(false)
		selected.handle:SetBackdropBorderColor(C.accent.r, C.accent.g, C.accent.b, 0.95)
		selected.handle.bg:SetAlpha(0.25)
	end
	selected = e
	if e and e.handle then
		e.handle:EnableKeyboard(true)
		e.handle:SetBackdropBorderColor(1, 1, 1, 1)
		e.handle.bg:SetAlpha(0.5)
	end
end

local function Nudge(e, dx, dy)
	if InCombatLockdown() then return end
	local point, x, y = NearestAnchor(e.frame)
	if point then
		Place(e.frame, point, x + dx, y + dy)
	end
	-- keyboard callbacks share the secret-read problem: write next tick
	C_Timer.After(0, function() save(e) end)
end

local ARROWS = { UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 } }

local function makeHandle(e)
	if e.handle then return e.handle end
	local h = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
	h:SetFrameStrata("TOOLTIP")
	h:SetFrameLevel(100)
	h:EnableMouse(true)
	h.bg = h:CreateTexture(nil, "BACKGROUND")
	h.bg:SetAllPoints()
	h.bg:SetTexture(S.media.blank)
	h.bg:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 1)
	h.bg:SetAlpha(0.25)
	S.Template(h, "none")
	h:SetBackdrop({ edgeFile = S.media.blank, edgeSize = 1 })
	h:SetBackdropBorderColor(C.accent.r, C.accent.g, C.accent.b, 0.95)

	h.label = S.Font(h, 11, C.accent)
	h.label:SetPoint("CENTER")
	h.label:SetText(e.label and (L[e.label] or e.label) or e.key)

	h:RegisterForClicks("AnyUp")
	h:RegisterForDrag("LeftButton")
	h:SetScript("OnDragStart", function()
		if InCombatLockdown() then return end
		Select(e)
		if e.proxy then
			-- proxy frames are placed elsewhere; the handle itself carries
			-- the position and the module re-anchors via onMoved
			h:SetMovable(true)
			h:StartMoving()
		else
			-- a frame born under combat lockdown is protected and
			-- StartMoving throws - then the HANDLE drags instead and the
			-- frame is parked on its drop spot
			local ok = pcall(e.frame.SetMovable, e.frame, true)
			ok = ok and pcall(e.frame.StartMoving, e.frame)
			if not ok then
				e._hDrag = true
				h:SetMovable(true)
				h:StartMoving()
			end
		end
	end)
	h:SetScript("OnDragStop", function()
		if InCombatLockdown() then return end
		if e.proxy then
			h:StopMovingOrSizing()
			-- defer the write one tick: rect reads inside the hardware
			-- handler answer secret on this client and the save skips -
			-- a skipped save is exactly how a moved frame snaps back
			C_Timer.After(0, function() save(e) end)
		elseif e._hDrag then
			e._hDrag = nil
			h:StopMovingOrSizing()
			C_Timer.After(0, function()
				-- park the frame where the handle landed
				local pt, x, y = NearestAnchor(h)
				if pt then
					pcall(Place, e.frame, pt, x, y)
				end
				save(e)
				RefreshHandle(e)
			end)
		else
			e.frame:StopMovingOrSizing()
			C_Timer.After(0, function()
				-- a failing snap must not take the save down with it
				pcall(snapFrame, e)
				save(e)
				RefreshHandle(e)
			end)
		end
	end)
	h:SetScript("OnMouseDown", function(_, button)
		if button == "LeftButton" then Select(e) end
	end)
	h:SetScript("OnMouseUp", function(_, button)
		if button == "RightButton" then
			M.Reset(e.key)
			RefreshHandle(e)
		end
	end)
	-- arrow keys nudge the selected element by 1px (Shift: 10px); every
	-- other key passes straight through. SetPropagateKeyboardInput is
	-- restricted in combat on this client - bail there, pcall elsewhere
	h:SetScript("OnKeyDown", function(f, key)
		if InCombatLockdown() then return end
		local a = ARROWS[key]
		if a then
			local step = IsShiftKeyDown() and 10 or 1
			Nudge(e, a[1] * step, a[2] * step)
			RefreshHandle(e)
			pcall(f.SetPropagateKeyboardInput, f, false)
		else
			pcall(f.SetPropagateKeyboardInput, f, true)
		end
	end)
	h:EnableMouseWheel(e.scale and true or false)
	h:SetScript("OnMouseWheel", function(_, delta)
		if not e.scale then return end
		local g = S.DB.General()
		local s = (g.frameScales[e.key] or 1) + delta * 0.05
		s = math.max(0.5, math.min(2, math.floor(s / 0.05 + 0.5) * 0.05))
		g.frameScales[e.key] = s
		applyScale(e)
	end)
	h:SetScript("OnEnter", function(f)
		GameTooltip:SetOwner(f, "ANCHOR_TOP")
		GameTooltip:AddLine(e.label and (L[e.label] or e.label) or e.key, C.accent.r, C.accent.g, C.accent.b)
		GameTooltip:AddLine(L["Drag: move - right-click: reset"], 0.8, 0.8, 0.8)
		GameTooltip:AddLine(L["Arrow keys nudge the selected element (Shift: 10px)"], 0.5, 0.5, 0.5)
		if e.scale then GameTooltip:AddLine(L["Mouse wheel: scale"], 0.8, 0.8, 0.8) end
		GameTooltip:Show()
	end)
	h:SetScript("OnLeave", function() GameTooltip:Hide() end)
	e.handle = h
	RefreshHandle(e)
	return h
end

-- Grid overlay -------------------------------------------------------------------------
local function drawGrid()
	if not gridFrame then
		dimFrame = CreateFrame("Frame", "SentiUIMoverDim", UIParent)
		dimFrame:SetAllPoints(UIParent)
		dimFrame:SetFrameStrata("LOW")
		dimFrame.tex = dimFrame:CreateTexture(nil, "BACKGROUND")
		dimFrame.tex:SetAllPoints()
		dimFrame.tex:SetTexture(S.media.blank)
		dimFrame.tex:SetVertexColor(0, 0, 0, 0.35)

		gridFrame = CreateFrame("Frame", "SentiUIMoverGrid", UIParent)
		gridFrame:SetAllPoints(UIParent)
		gridFrame:SetFrameStrata("DIALOG")
		gridFrame:SetFrameLevel(1)
		gridFrame.lines = {}
	end
	local g = S.DB.General()
	local size = math.max(8, g.gridSize or 24)
	local w, h = UIParent:GetSize()
	local pool, n = gridFrame.lines, 0
	local function line(vertical, pos, center)
		n = n + 1
		local t = pool[n]
		if not t then
			t = gridFrame:CreateTexture(nil, "ARTWORK")
			t:SetTexture(S.media.blank)
			pool[n] = t
		end
		t:ClearAllPoints()
		if vertical then
			t:SetPoint("TOP", gridFrame, "TOPLEFT", pos, 0)
			t:SetPoint("BOTTOM", gridFrame, "BOTTOMLEFT", pos, 0)
			t:SetWidth(1)
		else
			t:SetPoint("LEFT", gridFrame, "BOTTOMLEFT", 0, pos)
			t:SetPoint("RIGHT", gridFrame, "BOTTOMRIGHT", 0, pos)
			t:SetHeight(1)
		end
		if center then t:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.55)
		else t:SetVertexColor(1, 1, 1, 0.10) end
		t:Show()
	end
	-- lines run outward from the screen center so the middle is exact
	line(true, w / 2, true)
	line(false, h / 2, true)
	for i = 1, math.floor(w / 2 / size) do
		line(true, w / 2 + i * size)
		line(true, w / 2 - i * size)
	end
	for i = 1, math.floor(h / 2 / size) do
		line(false, h / 2 + i * size)
		line(false, h / 2 - i * size)
	end
	for i = n + 1, #pool do pool[i]:Hide() end
	dimFrame:Show()
	gridFrame:Show()
end

-- The edit bar along the bottom edge while move mode is on. A named frame in
-- UISpecialFrames, so ESC also leaves the mode.
local function buildBar()
	editBar = CreateFrame("Frame", "SentiUIMoversBar", UIParent, "BackdropTemplate")
	editBar:SetSize(540, 58)
	S.Template(editBar, "panel")
	S.SetBorderLit(editBar, true)
	editBar:SetFrameStrata("DIALOG")
	editBar:SetFrameLevel(80)
	editBar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 36)
	editBar:SetMovable(true)
	editBar:RegisterForDrag("LeftButton")
	editBar:EnableMouse(true)
	editBar:SetScript("OnDragStart", editBar.StartMoving)
	editBar:SetScript("OnDragStop", editBar.StopMovingOrSizing)
	S.EscClosable(editBar)
	-- WatchHide, not OnHide: an OnHide script would run inside the
	-- Escape dispatch and taint the engine's protected spell-stop
	-- calls - the watcher polls the transition from OnUpdate instead
	S.WatchHide(editBar, function()
		if M.unlocked then M.SetUnlocked(false) end
	end)

	local edge = S.Line(editBar, C.accent, 2)
	-- inset past the corner arc so the line ends on the straight edge
	edge:SetPoint("TOPLEFT", 7, 0)
	edge:SetPoint("TOPRIGHT", -7, 0)

	local title = S.Font(editBar, 13, C.accent)
	title:SetPoint("TOPLEFT", 12, -8)
	title:SetText(L["Move mode"])

	editBar.count = S.Font(editBar, 10, C.textDim)
	editBar.count:SetPoint("LEFT", title, "RIGHT", 10, -1)

	editBar.hint = S.Font(editBar, 10, C.textDim)
	editBar.hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

	local lock = S.Widgets.Button(editBar, L["Lock"], 76, 26)
	lock:SetPoint("RIGHT", -10, 0)
	lock:SetScript("OnClick", function() M.SetUnlocked(false) end)

	local reset = S.Widgets.Button(editBar, L["Reset all"], 90, 22)
	reset:SetPoint("RIGHT", lock, "LEFT", -8, 0)
	reset:SetScript("OnClick", function()
		M.AskReset()
	end)
end

function M.Recheck()
	if not M.unlocked then return 0 end
	local shown = 0
	for _, key in ipairs(order) do
		local e = entries[key]
		if entryShown(e) then
			-- one broken handle must not kill the rest of the mode
			local ok, h = pcall(makeHandle, e)
			if ok and h then
				shown = shown + 1
				pcall(RefreshHandle, e)
				h:Show()
			end
		elseif e.handle then
			e.handle:Hide()
		end
	end
	if editBar then
		if editBar.count then
			editBar.count:SetText(string.format(L["%d frames"], shown))
		end
		if editBar.hint then
			editBar.hint:SetText(shown == 0
				and L["Nothing movable yet - enable 'Show test frame' in the settings or install a SentiUI module."]
				or L["Drag frames to move them - right-click resets - wheel scales - ESC locks"])
		end
	end
	return shown
end

-- If the settings window was open when move mode started, it comes back on lock.
local reopenPanel

local function showMode()
	reopenPanel = S.OptionsPanel and S.OptionsPanel.IsShown and S.OptionsPanel.IsShown() or false
	if reopenPanel then S.OptionsPanel.Hide() end
	drawGrid()
	if not editBar then buildBar() end
	editBar:Show()
	return M.Recheck()
end

function M.SetUnlocked(on)
	on = on and true or false
	if on == M.unlocked then
		-- already on but the user clicked again: rebuild the visuals, a
		-- wedged mode must never swallow the click silently
		if on then pcall(showMode) end
		return
	end
	if on and InCombatLockdown() then
		S.Print(L["Can't move frames during combat."])
		return
	end
	M.unlocked = on
	if on then
		local ok, shown = pcall(showMode)
		if not ok then
			-- leave no half-on state: reset and show what broke
			M.unlocked = nil
			reopenPanel = nil
			if gridFrame then gridFrame:Hide() end
			if dimFrame then dimFrame:Hide() end
			if editBar then editBar:Hide() end
			S.Print("|cffff5555Move mode: " .. tostring(shown) .. "|r")
			return
		end
		S.Print(string.format(L["Move mode: %d frames"], shown))
	else
		Select(nil)
		if gridFrame then gridFrame:Hide() end
		if dimFrame then dimFrame:Hide() end
		if editBar then editBar:Hide() end
		for _, e in pairs(entries) do
			if e.handle then
				e.handle:EnableKeyboard(false)
				e.handle:Hide()
			end
		end
		if reopenPanel and S.OptionsPanel and S.OptionsPanel.Show then
			S.OptionsPanel.Show()
		end
		reopenPanel = nil
	end
	S.Fire("MoversToggled", on)
end

function M.Toggle() M.SetUnlocked(not M.unlocked) end

-- Leaving combat re-checks which handles may show.
S.RegisterEvent("PLAYER_REGEN_ENABLED", function() if M.unlocked then M.Recheck() end end)

-- A sample frame so move mode can be tried before any module ships movers.
-- Toggled by the "Test frame" switch (SentiUI > General) and remembered in
-- general.testFrame.
local testFrame = S.Panel(UIParent, 190, 60, "panel")
testFrame:SetFrameStrata("MEDIUM")
local testLabel = S.Font(testFrame, 11, C.accent)
testLabel:SetPoint("CENTER")
testLabel:SetText("SentiUI Test")
testFrame:Hide()
M.Register(testFrame, "sentiui.test", "Test frame", { x = 0, y = -260 }, { scale = true })
testFrame:HookScript("OnShow", M.Recheck)
testFrame:HookScript("OnHide", M.Recheck)

function M.SetTestFrameShown(on)
	testFrame:SetShown(on and true or false)
end

S.RegisterEvent("PLAYER_LOGIN", function()
	testFrame:SetShown(S.DB.General().testFrame == true)
end)

function M.AskReset()
	S.Confirm(L["Reset every frame position and scale?"],
		function() M.ResetAll() end,
		{ okText = YES or "Yes", cancelText = NO or "No" })
end
