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

local function EnsureBackdrop(frame)
	if frame.SetBackdrop then return end
	if not BackdropTemplateMixin then return end
	Mixin(frame, BackdropTemplateMixin)
	if frame.OnBackdropLoaded then frame:OnBackdropLoaded() end
end

function S.Template(f, style)
	if not f then return end
	EnsureBackdrop(f)
	if not f.SetBackdrop then return end
	style = style or "panel"
	if style == "none" then
		f:SetBackdrop(nil)
		return
	end
	f:SetBackdrop(backdropFlat)
	if style == "panel" then
		f:SetBackdropColor(C.bg.r, C.bg.g, C.bg.b, C.bg.a)
	elseif style == "raised" then
		f:SetBackdropColor(C.bgRaised.r, C.bgRaised.g, C.bgRaised.b, C.bgRaised.a)
	elseif style == "inset" then
		f:SetBackdropColor(C.bgInset.r, C.bgInset.g, C.bgInset.b, C.bgInset.a)
	end
	f:SetBackdropBorderColor(C.border.r, C.border.g, C.border.b, 1)
end

function S.SetBorderLit(f, lit, color)
	if not (f and f.SetBackdropBorderColor) then return end
	local c = lit and (color or C.accent) or C.border
	f:SetBackdropBorderColor(c.r, c.g, c.b, 1)
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
