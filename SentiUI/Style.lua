-- Sentinel look: near-black panels, gold accent. Shared colors and the small
-- frame/font factories every SentiUI window uses.
local _, S = ...

local BLANK = "Interface\\Buttons\\WHITE8X8"

S.media = {
	font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",
	blank = BLANK,
	logo = "Interface\\AddOns\\SentiUI\\Media\\Logo.tga",
	-- wide banner (Alliance/Horde Sigillum): 1024x512 canvas, the art sits
	-- in the middle band - crop with SetTexCoord(0,1, band[1], band[2])
	longLogo = "Interface\\AddOns\\SentiUI\\Media\\LongLogo.tga",
	longLogoBand = { 0.166, 0.832 }, -- v-range of the art inside the canvas
}

local C = {
	bg = { r = 0.043, g = 0.051, b = 0.071, a = 0.95 },       -- #0B0D12
	bgRaised = { r = 0.075, g = 0.086, b = 0.114, a = 0.97 }, -- #13161D
	bgInset = { r = 0.028, g = 0.033, b = 0.047, a = 0.97 },  -- #07090C
	border = { r = 0.133, g = 0.157, b = 0.220 },             -- #222838
	accent = { r = 0.92, g = 0.68, b = 0.20 },                -- #EBAD33
	accent2 = { r = 0.20, g = 0.62, b = 1.00 },               -- #339EFF
	text = { r = 0.92, g = 0.93, b = 0.96 },
	textDim = { r = 0.55, g = 0.57, b = 0.64 },
	red = { r = 0.94, g = 0.32, b = 0.36 },
	green = { r = 0.30, g = 0.85, b = 0.47 },
}
S.colors = C

function S.Hex(c)
	return string.format("%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
end

-- templates ----------------------------------------------------------------------
local backdropFlat = { bgFile = BLANK, edgeFile = BLANK, edgeSize = 1 }

-- rounded chrome: soft corners for every panel, chip and tab (the
-- Daylight-style look). The pill textures carry the arc in their corners
-- so the edge stretches true at any size; the square fill is inset so its
-- corners hide under the arc. If the media was not generated yet
-- (make_media.py), the probe fails and the flat look stays - graceful.
local PILL_EDGE = "Interface\\AddOns\\SentiUI\\Media\\Textures\\PillEdge.tga"
local pillState
local function PillReady()
	-- probe once: if make_edges.py has been run and PillEdge.tga exists
	-- the client resolves it; all panels then get smooth rounded corners
	-- via the edgeFile backdrop. Without the file we fall back to flat.
	if pillState ~= nil then return pillState end
	local id = GetFileIDFromPath and GetFileIDFromPath(PILL_EDGE)
	pillState = type(id) == "number" and id > 0
	return pillState
end

-- media registry: every shipped texture is probed once, cached, and only
-- returned when the client actually resolves it - callers always keep a
-- programmatic fallback so missing media degrades gracefully.
local TEX_DIR = "Interface\\AddOns\\SentiUI\\Media\\Textures\\"
local texCache = {}
function S.Tex(name)
	local v = texCache[name]
	if v ~= nil then return v or nil end
	local path = TEX_DIR .. name .. ".tga"
	local id = GetFileIDFromPath and GetFileIDFromPath(path)
	local ok = type(id) == "number" and id > 0
	texCache[name] = ok and path or false
	return ok and path or nil
end

local function roundedTable()
	return {
		bgFile = BLANK,
		edgeFile = PILL_EDGE,
		edgeSize = 6,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	}
end

local function EnsureBackdrop(frame)
	if frame.SetBackdrop then return end
	if not BackdropTemplateMixin then return end
	Mixin(frame, BackdropTemplateMixin)
	if frame.OnBackdropLoaded then frame:OnBackdropLoaded() end
end

-- Design system border colours:
--   "raised" / "gold" panels → soft Sentinel gold border (outer windows)
--   "panel" / "inset"       → subtle dark border (inner sections)
-- Border colour is saved in f._suiBorderNorm so SetBorderLit can restore it.
local function BorderTint(style)
	if style == "raised" or style == "gold" then
		return C.accent.r, C.accent.g, C.accent.b, 0.45
	end
	return C.border.r, C.border.g, C.border.b, 1
end

function S.Template(f, style)
	if not f then return end
	style = style or "panel"
	if style == "none" then
		if f.SetBackdrop then pcall(f.SetBackdrop, f, nil) end
		return
	end
	local color = style == "raised" and C.bgRaised
		or style == "inset" and C.bgInset or C.bg
	local bR, bG, bB, bA = BorderTint(style)
	EnsureBackdrop(f)
	if f.SetBackdrop then
		-- smooth rounded corners when make_edges.py has been run;
		-- clean flat square when textures are absent — no pixelation either way
		f:SetBackdrop(PillReady() and roundedTable() or backdropFlat)
		f:SetBackdropColor(color.r, color.g, color.b, color.a or 1)
		f:SetBackdropBorderColor(bR, bG, bB, bA)
	end
	-- stash so SetBorderLit can restore after hover-off
	f._suiBorderNorm = { bR, bG, bB, bA }
end

function S.SetBorderLit(f, lit, color)
	if not f then return end
	if lit then
		local c = color or C.accent
		if f.SetBackdropBorderColor then
			pcall(f.SetBackdropBorderColor, f, c.r, c.g, c.b, 1)
		end
	else
		local n = f._suiBorderNorm
		if n and f.SetBackdropBorderColor then
			pcall(f.SetBackdropBorderColor, f, n[1], n[2], n[3], n[4])
		elseif f.SetBackdropBorderColor then
			pcall(f.SetBackdropBorderColor, f, C.border.r, C.border.g, C.border.b, 1)
		end
	end
end

-- A 1px line, for separators and the accent edge under window titles.
function S.Line(parent, color, height, layer)
	local t = parent:CreateTexture(nil, layer or "ARTWORK")
	t:SetTexture(BLANK)
	local c = color or C.border
	t:SetVertexColor(c.r, c.g, c.b, c.a or 1)
	t:SetHeight(height or 1)
	return t
end

-- Rounded corners, fully programmed: the frame's fill IS the pieces —
-- five straight WHITE8X8 strips plus four quarter-discs RASTERIZED in
-- code as radius columns of 1px per corner. No external mask file can
-- break the look: the arc math h(i) = sqrt(r² - (r - i - .5)²) yields the
-- exact fill height of each column inside the rounded rect.
-- Everything tints together via SetRoundFill (f.roundPieces, flat).
function S.Roundize(f, radius)
	radius = math.floor(radius or 6)
	if radius < 2 then radius = 2 end
	if f.SetBackdrop then pcall(f.SetBackdrop, f, nil) end
	f.roundStrips, f.roundCornerStrips, f.roundPieces = {}, {}, {}
	for _, name in ipairs({ "top", "bottom", "left", "right", "center" }) do
		local t = f:CreateTexture(nil, "BORDER")
		t:SetTexture(BLANK)
		f.roundStrips[name] = t
		f.roundPieces[#f.roundPieces + 1] = t
	end
	for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
		local list = {}
		f.roundCornerStrips[corner] = list
		for i = 0, radius - 1 do
			local t = f:CreateTexture(nil, "BORDER")
			t:SetTexture(BLANK)
			-- AA sliver: a 1px quad at the arc's fractional boundary whose
			-- alpha carries the leftover coverage - hard column steps become
			-- a smooth, evenly rasterized curve
			local s = f:CreateTexture(nil, "BORDER")
			s:SetTexture(BLANK)
			s:SetSize(1, 1)
			list[i] = { solid = t, sliver = s }
			f.roundPieces[#f.roundPieces + 1] = t
			f.roundPieces[#f.roundPieces + 1] = s
		end
	end
	function f:RoundLayout()
		local w, h = self:GetWidth() or 0, self:GetHeight() or 0
		local r = math.max(0, math.min(radius, w * 0.5, h * 0.5))
		local s, cs = self.roundStrips, self.roundCornerStrips
		-- corner arcs: column i sits i px from the outer edge; its fill
		-- height h(i) follows the quarter circle centered r px inward. The
		-- solid part covers floor(h(i)) px, the sliver the fractional px on
		-- top at alpha = frac(h(i)) - the anti-aliased arc edge.
		for corner, list in pairs(cs) do
			for i = 0, radius - 1 do
				local e = list[i]
				local t, sl = e.solid, e.sliver
				local d = r - (i + 0.5)
				local hh = d > 0 and math.sqrt(r * r - d * d) or 0
				local solidH = math.floor(hh)
				local frac = hh - solidH
				t:ClearAllPoints()
				t:SetSize(1, math.max(solidH, 0.1))
				sl:ClearAllPoints()
				sl:SetAlpha(frac)
				-- WoW y-offsets: positive is UP, negative is DOWN. The strip
				-- must sit INSIDE the corner tile (hugging the arc's inner
				-- edge) — a wrong sign parks it outside the frame as a
				-- floating dark nub at every corner.
				if corner == "TOPLEFT" then
					t:SetPoint("BOTTOMLEFT", f, "TOPLEFT", i, -r)
					sl:SetPoint("BOTTOMLEFT", f, "TOPLEFT", i, -r + solidH)
				elseif corner == "TOPRIGHT" then
					t:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -i, -r)
					sl:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -i, -r + solidH)
				elseif corner == "BOTTOMLEFT" then
					t:SetPoint("TOPLEFT", f, "BOTTOMLEFT", i, r)
					sl:SetPoint("TOPLEFT", f, "BOTTOMLEFT", i, r - solidH)
				else
					t:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -i, r)
					sl:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -i, r - solidH)
				end
				t:SetShown(d > 0 and solidH > 0)
				sl:SetShown(d > 0 and frac > 0.02)
			end
		end
		-- straight pieces, non-overlapping nine-grid
		s.top:ClearAllPoints()
		s.top:SetPoint("TOPLEFT", f, "TOPLEFT", r, 0)
		s.top:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", -r, -r)
		s.bottom:ClearAllPoints()
		s.bottom:SetPoint("TOPLEFT", f, "BOTTOMLEFT", r, r)
		s.bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -r, 0)
		s.left:ClearAllPoints()
		s.left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -r)
		s.left:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", r, r)
		s.right:ClearAllPoints()
		s.right:SetPoint("TOPLEFT", f, "TOPRIGHT", -r, -r)
		s.right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, r)
		s.center:ClearAllPoints()
		s.center:SetPoint("TOPLEFT", f, "TOPLEFT", r, -r)
		s.center:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -r, r)
	end
	function f:SetRoundFill(r, g, b, a)
		for _, t in ipairs(self.roundPieces) do t:SetVertexColor(r, g, b, a) end
	end
	local rawSize, rawWidth, rawHeight = f.SetSize, f.SetWidth, f.SetHeight
	function f:SetSize(w, h) rawSize(self, w, h) self:RoundLayout() end
	function f:SetWidth(w) rawWidth(self, w) self:RoundLayout() end
	function f:SetHeight(h) rawHeight(self, h) self:RoundLayout() end
	-- widths from anchor points (TOPLEFT+TOPRIGHT) never call SetWidth
	f:HookScript("OnSizeChanged", function() f:RoundLayout() end)
	f:RoundLayout()
	return f
end

-- S.CornerCut(host, target, radius, r, g, b, a, layer)
-- Rounded-rect silhouette for any region, fully programmed: raster caps in
-- the color of the surface BEHIND `target` cover the corner notch OUTSIDE
-- a quarter disc of `radius` px (the S.Roundize arc math inverted). Each
-- column carries a 1px sliver at the arc boundary whose alpha is the
-- fractional coverage - the cut edge antialiases instead of stair-stepping.
-- No MaskTexture, no media file: a missing cap can never paint a visible
-- artifact, worst case `target` stays square. Textures are created on
-- `host` at `layer`; `host` also carries the relayout hook (Textures have
-- no OnSizeChanged support - HookScript on one throws). `subLevel` pins
-- the caps above later-created regions (bar gloss would otherwise draw
-- over them and poke a white tip into every rounded corner).
function S.CornerCut(host, target, radius, r, g, b, a, layer, subLevel)
	if not (host and target and host.CreateTexture) then return end
	local c = math.floor(radius or 2)
	if c < 1 then return end
	if c > 12 then c = 12 end
	local caps = {}
	for _, corner in ipairs({ "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT" }) do
		for i = 0, c - 1 do
			local solid = host:CreateTexture(nil, layer or "OVERLAY",
				nil, subLevel)
			solid:SetTexture(BLANK)
			solid:SetVertexColor(r, g, b, a)
			local sliver = host:CreateTexture(nil, layer or "OVERLAY",
				nil, subLevel)
			sliver:SetTexture(BLANK)
			sliver:SetVertexColor(r, g, b, a)
			sliver:SetSize(1, 1)
			caps[#caps + 1] = { solid = solid, sliver = sliver,
				corner = corner, i = i }
		end
	end
	local function layout(attempt)
		local w = target.GetWidth and target:GetWidth() or 0
		local h = target.GetHeight and target:GetHeight() or 0
		-- secret dimensions (aura-container icons): any compare throws -
		-- leave the target square, the caps stay unanchored
		if S.IsSecret(w) or S.IsSecret(h) then return end
		if w <= 0 or h <= 0 then
			-- layout not resolved yet: retry next frame, then give up
			attempt = (attempt or 0) + 1
			if attempt <= 5 and C_Timer and C_Timer.After then
				C_Timer.After(0, function() layout(attempt) end)
			end
			return
		end
		local cc = math.max(0, math.min(c, w * 0.5, h * 0.5))
		for _, cap in ipairs(caps) do
			-- cover height of column i: the corner-tile region outside the
			-- quarter disc of radius cc centered cc px inward
			local dx = cc - (cap.i + 0.5)
			local cov = dx > 0
				and (cc - math.sqrt(math.max(cc * cc - dx * dx, 0))) or 0
			local solidH = math.floor(cov)
			local frac = cov - solidH
			local s, sl = cap.solid, cap.sliver
			s:ClearAllPoints()
			sl:ClearAllPoints()
			if cap.corner == "TOPLEFT" then
				s:SetPoint("TOPLEFT", target, "TOPLEFT", cap.i, 0)
				sl:SetPoint("TOPLEFT", target, "TOPLEFT", cap.i, -solidH)
			elseif cap.corner == "TOPRIGHT" then
				s:SetPoint("TOPRIGHT", target, "TOPRIGHT", -cap.i, 0)
				sl:SetPoint("TOPRIGHT", target, "TOPRIGHT", -cap.i, -solidH)
			elseif cap.corner == "BOTTOMLEFT" then
				s:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", cap.i, 0)
				sl:SetPoint("BOTTOMLEFT", target, "BOTTOMLEFT", cap.i, solidH)
			else
				s:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", -cap.i, 0)
				sl:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", -cap.i, solidH)
			end
			s:SetSize(1, math.max(solidH, 0.1))
			s:SetShown(solidH > 0)
			sl:SetAlpha(frac)
			sl:SetShown(frac > 0.02 and dx > 0)
		end
	end
	layout(0)
	-- the host frame resizes first, so hook it for relayout; pcall guards
	-- odd hosts with no script support either
	if host.HookScript then
		pcall(host.HookScript, host, "OnSizeChanged", function() layout(5) end)
	end
	return caps
end

-- S.EdgeArc(host, corner, center, radius, thick, r, g, b, a)
-- A quarter-circle border segment for one corner, rasterized as 1px
-- columns: edge strips (S.Line / ns.EdgeGlow / the window accent edge)
-- end `center` px before each corner, so without this arc the border
-- reads as four open stubs. `center` is the arc's pivot offset from the
-- corner point, `radius` its reach, `thick` the stroke width.
-- Returns the texture list so callers can recolor (threat/dispel).
function S.EdgeArc(host, corner, center, radius, thick, r, g, b, a)
	if not (host and host.CreateTexture) then return {} end
	local cx = center or 7
	local R = radius or 6
	local th = thick or 1
	-- short frames: a radius taller than half the height makes the top
	-- and bottom arcs overlap into a pointed chevron - clamp to what
	-- actually fits so the ring stays a smooth pill end
	local hh = host.GetHeight and host:GetHeight() or 0
	if hh and hh > 0 then
		R = math.max(1, math.min(R, math.floor(hh / 2)))
		cx = math.min(cx, R)
	end
	local Rin = R - th
	local arcs = {}
	for i = 0, math.floor(R) - 1 do
		local x0 = cx - R + i
		local x1 = x0 + 1
		local d0 = cx - x0
		-- the ring is a BAND between the inner circle (radius R-th) and
		-- the outer (R): covering [outer(x1) down to inner(x0)] keeps a
		-- constant stroke. Height-from-arc-rise instead leaves a gap in
		-- the ring's lower half on steep columns - the pixel error.
		local qin = (d0 < Rin) and math.sqrt(Rin * Rin - d0 * d0) or 0
		local q1 = math.sqrt(math.max(0, R * R - (cx - x1) ^ 2))
		local h = math.max(0.5, q1 - qin)
		local t = host:CreateTexture(nil, "OVERLAY")
		t:SetTexture(BLANK)
		t:SetVertexColor(r, g, b, a or 1)
		t:SetWidth(th)
		-- TOP corners rise toward the edge line (y = -cx + q); BOTTOM
		-- corners mirror it upward (y = cx - q).
		if corner == "TOPLEFT" then
			t:SetPoint("TOPLEFT", host, "TOPLEFT", x0, -cx + q1)
			t:SetHeight(h)
		elseif corner == "TOPRIGHT" then
			t:SetPoint("TOPRIGHT", host, "TOPRIGHT", -x0, -cx + q1)
			t:SetHeight(h)
		elseif corner == "BOTTOMLEFT" then
			t:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", x0, cx - q1)
			t:SetHeight(h)
		elseif corner == "BOTTOMRIGHT" then
			t:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -x0, cx - q1)
			t:SetHeight(h)
		else
			t:Hide()
		end
		arcs[#arcs + 1] = t
	end
	return arcs
end

-- S.IconRound(f, radius)
-- Soft icon corners via S.CornerCut in the slot's background color:
-- where the frame strips fill INSIDE the quarter disc, the caps cover
-- OUTSIDE it. A MaskTexture proved unreliable on this client (the 'white
-- corners' blob bug) - raster caps carry no such risk.
function S.IconRound(f, radius)
	-- icons are square; no corner caps
end

-- Sentinel tab chip - the shared small-tab design language. A dark
-- rounded body (no edge line - hover and selection brighten the fill)
-- with a 2px accent blade on the left edge: the blade glows on hover and
-- burns on the active tab, so a row of tabs reads as one system instead
-- of scattered boxes. Call SetLabel/SetSelected; size and click stay
-- with the caller.
function S.TabChip(parent, height)
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(height or 22)
	-- base template: rounded (texture) or flat — dark fill, subtle border
	S.Template(b, "inset")
	local function paint(state)
		if not b.SetBackdropColor then return end
		local fc = state == "active" and C.bgRaised
			or (state == "hover" and C.bgRaised or C.bgInset)
		b:SetBackdropColor(fc.r, fc.g, fc.b, state == "active" and 1 or (C.bgInset.a or 1))
		-- gold border when selected, subtle when idle/hover
		if b.SetBackdropBorderColor then
			if state == "active" then
				pcall(b.SetBackdropBorderColor, b, C.accent.r, C.accent.g, C.accent.b, 0.9)
			elseif state == "hover" then
				pcall(b.SetBackdropBorderColor, b, C.accent.r, C.accent.g, C.accent.b, 0.35)
			else
				pcall(b.SetBackdropBorderColor, b, C.border.r, C.border.g, C.border.b, 1)
			end
		end
	end
	-- 2px gold blade on the left edge — burns gold when active
	b.blade = b:CreateTexture(nil, "OVERLAY")
	b.blade:SetTexture(BLANK)
	b.blade:SetPoint("TOPLEFT", 1, -1)
	b.blade:SetPoint("BOTTOMLEFT", 1, 1)
	b.blade:SetWidth(2)
	b.blade:SetVertexColor(C.border.r, C.border.g, C.border.b, 1)
	b.label = S.Font(b, 11)
	b.label:SetPoint("LEFT", 12, 0)
	-- NO right anchor: GetStringWidth() must return the natural text width for
	-- auto-width measurement to work. A RIGHT anchor clamps the return to the
	-- current button width (0 on a freshly created chip) and every chip would
	-- be sized to 22px — rendering as a featureless dark square without text.
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetSize(15, 15)
	b.icon:SetPoint("LEFT", 8, 0)
	b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	b.icon:Hide()
	b:SetScript("OnEnter", function(bb)
		if not bb.selected then
			paint("hover")
			bb.blade:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.55)
		end
	end)
	b:SetScript("OnLeave", function(bb)
		bb:SetSelected(bb.selected)
	end)
	function b:SetLabel(text)
		self.label:SetText(text)
		if self.autoWidth then
			self:SetWidth((self.label:GetStringWidth() or 40) + 22)
		end
	end
	function b:SetIcon(tex)
		if tex then
			self.icon:SetTexture(tex)
			self.icon:SetShown(true)
			self.label:SetPoint("LEFT", 28, 0)
		else
			self.icon:SetShown(false)
			self.label:SetPoint("LEFT", 12, 0)
		end
	end
	function b:SetSelected(on)
		self.selected = on and true or false
		paint(self.selected and "active" or "idle")
		local bc = self.selected and C.accent or C.border
		self.blade:SetVertexColor(bc.r, bc.g, bc.b, 1)
		local tc = self.selected and C.accent or C.textDim
		self.label:SetTextColor(tc.r, tc.g, tc.b)
	end
	b:SetSelected(false)
	return b
end

-- On this client SetFont can silently do nothing (the string keeps no font
-- and draws blank) - the reliable path is a real Font object via
-- CreateFontFamily + SetFontObject, verified with GetFont afterwards.
local famCache, famN = {}, 0
local ALPHABETS = { "roman", "russian", "korean", "simplifiedchinese",
	"traditionalchinese" }
local ALPHABET_FILES = {
	russian = "Fonts\\FRIZQT___CYR.TTF",
	korean = "Fonts\\2002.ttf",
	simplifiedchinese = "Fonts\\ARKai_T.ttf",
	traditionalchinese = "Fonts\\blei00d.TTF",
}

function S.FontObject(file, size, flags)
	if type(CreateFontFamily) ~= "function" or type(file) ~= "string"
		or type(size) ~= "number" or size <= 0 then return nil end
	size = math.floor(size + 0.5)
	local key = file .. "|" .. size .. "|" .. (flags or "")
	if famCache[key] ~= nil then return famCache[key] or nil end
	local members = {}
	for i, a in ipairs(ALPHABETS) do
		members[i] = { alphabet = a,
			file = a == "roman" and file or (ALPHABET_FILES[a] or file),
			height = size, flags = flags or "" }
	end
	famN = famN + 1
	local ok, fam = pcall(CreateFontFamily, "SentiUIFont" .. famN, members)
	famCache[key] = ok and fam or false
	return famCache[key] or nil
end

-- Applies a font to a string the way this client actually accepts it:
-- Font object first, verified through GetFont, plain SetFont as fallback.
function S.ApplyFont(fs, file, size, flags)
	file, size, flags = file or S.media.font, (size or 12), (flags or "")
	local fam = S.FontObject(file, size, flags)
	if fam and fs.SetFontObject then
		pcall(fs.SetFontObject, fs, fam)
	end
	local _, h = fs:GetFont()
	if type(h) ~= "number" or math.abs(h - math.floor(size + 0.5)) > 0.3 then
		pcall(fs.SetFont, fs, file, size, flags)
	end
end

function S.Font(parent, size, color, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	S.ApplyFont(fs, S.media.font, size or 12, flags)
	local c = color or C.text
	fs:SetTextColor(c.r, c.g, c.b)
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 0.8)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("MIDDLE")
	return fs
end

function S.Panel(parent, w, h, style)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetSize(w or 100, h or 100)
	S.Template(f, style or "panel")
	return f
end

-- Text helpers ---------------------------------------------------------------------
function S.AccentText(text)
	return "|cff" .. S.Hex(C.accent) .. tostring(text) .. "|r"
end

function S.DimText(text)
	return "|cff" .. S.Hex(C.textDim) .. tostring(text) .. "|r"
end

-- A tooltip with the item's description, for option rows.
function S.AttachTooltip(frame, title, desc)
	if not desc then return end
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", function(f)
		GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
		if title then GameTooltip:AddLine(title, C.text.r, C.text.g, C.text.b) end
		GameTooltip:AddLine(desc, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Sentinel tooltip skin -------------------------------------------------------
-- Applied once at PLAYER_LOGIN. Hides the Blizzard NineSlice/region chrome
-- and replaces it with the same dark-bg + single-px border the rest of the
-- suite uses, plus a 1px gold accent line at the top. Safe to call more than
-- once (guarded by .suiSkin).
local TOOLTIP_LIST = {
	"GameTooltip", "ItemRefTooltip",
	"ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2",
	"ShoppingTooltip1", "ShoppingTooltip2",
	"GameTooltipComparisonItem",
}
-- chrome region name suffixes the client attaches to tooltip frames
local CHROME_KEYS = {
	"TopLeft", "Top", "TopRight", "Left", "Right",
	"BottomLeft", "Bottom", "BottomRight",
	"Background", "BackgroundTop",
}

local function SkinTooltip(tt)
	if not tt or tt.suiSkin then return end
	tt.suiSkin = true
	-- hide NineSlice (retail-style chrome container)
	if tt.NineSlice then tt.NineSlice:SetAlpha(0) end
	-- hide any individually-named region chrome
	local tn = type(tt.GetName) == "function" and tt:GetName()
	for _, k in ipairs(CHROME_KEYS) do
		local t = tn and _G[tn .. k]
		if type(t) == "table" and t.SetAlpha then t:SetAlpha(0) end
	end
	-- ensure SetBackdrop is available (may need the mixin on this client)
	if not tt.SetBackdrop and BackdropTemplateMixin then
		Mixin(tt, BackdropTemplateMixin)
	end
	if tt.SetBackdrop then
		tt:SetBackdrop({
			bgFile   = BLANK,
			edgeFile = S.Tex("TooltipEdge") or BLANK,
			edgeSize = S.Tex("TooltipEdge") and 16 or 1,
			insets   = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		tt:SetBackdropColor(C.bg.r, C.bg.g, C.bg.b, 0.96)
		tt:SetBackdropBorderColor(C.border.r, C.border.g, C.border.b, 1)
	end
	-- 1px gold accent line across the top
	if not tt.suiAccentLine then
		local ok, line = pcall(tt.CreateTexture, tt, nil, "OVERLAY", nil, 1)
		if ok and line then
			line:SetHeight(1)
			line:SetPoint("TOPLEFT",  tt, "TOPLEFT",  2, -2)
			line:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -2, -2)
			line:SetTexture(BLANK)
			line:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.85)
			tt.suiAccentLine = line
		end
	end
end

function S.StyleTooltips()
	for _, name in ipairs(TOOLTIP_LIST) do
		local tt = _G[name]
		if type(tt) == "table" then pcall(SkinTooltip, tt) end
	end
	-- GameTooltip is reused for many things; re-skin if something resets it
	if GameTooltip then
		pcall(GameTooltip.HookScript, GameTooltip, "OnShow", function(tt)
			pcall(SkinTooltip, tt)
		end)
	end
end

-- Loss-of-Control alert ("Bewegungsunfaehig 1,3 Sek.") --------------------
-- The game's frame still decides when/what to show - its values are secret
-- to addons - so we never read or rebuild the data, only pass the game's
-- text and icon through onto a same-size overlay in our style: dark rounded
-- panel, gold accent edge, our font. Every stock texture/fontstring gets
-- alpha-0; the overlay repaints from the live strings each frame.
local function SkinLossOfControl()
	local f = _G.LossOfControlFrame
	if not f or f.suiSkin then return end
	f.suiSkin = true

	local o = CreateFrame("Frame", nil, f, "BackdropTemplate")
	o:SetAllPoints(f)
	o:SetFrameLevel((f.GetFrameLevel and f:GetFrameLevel() or 1) + 5)
	S.Template(o, "raised")
	o.suiOverlay = true

	o.icon = o:CreateTexture(nil, "ARTWORK")
	o.icon:SetSize(30, 30)
	o.icon:SetPoint("LEFT", 10, 0)
	o.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
	o.name = S.Font(o, 13)
	o.name:SetPoint("TOPLEFT", o.icon, "TOPRIGHT", 8, -3)
	o.name:SetJustifyH("LEFT")
	o.name:SetWordWrap(false)
	o.time = S.Font(o, 10, C.textDim)
	o.time:SetPoint("TOPLEFT", o.name, "BOTTOMLEFT", 0, -2)
	local line = o:CreateTexture(nil, "OVERLAY", nil, 1)
	line:SetHeight(1)
	line:SetPoint("TOPLEFT", o, "TOPLEFT", 8, -3)
	line:SetPoint("TOPRIGHT", o, "TOPRIGHT", -8, -3)
	line:SetTexture(BLANK)
	line:SetVertexColor(C.accent.r, C.accent.g, C.accent.b, 0.85)

	-- every stock region the frame paints with; re-run on each show since
	-- the game can rebuild its art between displays
	local function hideStock()
		for _, r in ipairs({ f:GetRegions() }) do
			if r.SetAlpha then r:SetAlpha(0) end
		end
		for _, c in ipairs({ f:GetChildren() }) do
			if c ~= o and c.SetAlpha then c:SetAlpha(0) end
		end
	end
	hideStock()

	-- mirror the live texts: SetText on a secret value is allowed, only
	-- comparing it would throw - the pcall covers odd client shapes too
	o:SetScript("OnUpdate", function()
		if not f:IsShown() then return end
		hideStock()
		if f.AbilityName then
			pcall(o.name.SetText, o.name, f.AbilityName:GetText())
		end
		if f.TimeLeft and f.TimeLeft.NumberText then
			pcall(o.time.SetText, o.time, f.TimeLeft.NumberText:GetText())
		end
		if f.Icon then
			pcall(o.icon.SetTexture, o.icon, f.Icon:GetTexture())
		end
	end)
	f:HookScript("OnShow", hideStock)
end

function S.StyleLossOfControl()
	pcall(SkinLossOfControl)
end

-- fire once after everything is loaded
do
	local initF = CreateFrame("Frame")
	initF:RegisterEvent("PLAYER_LOGIN")
	initF:SetScript("OnEvent", function(self)
		S.StyleTooltips()
		S.StyleLossOfControl()
		self:UnregisterEvent("PLAYER_LOGIN")
	end)
end
