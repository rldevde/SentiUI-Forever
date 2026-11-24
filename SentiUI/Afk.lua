-- AFK overlay: dims the screen and shows a card (name, class, guild,
-- elapsed AFK time) while the AFK flag is up. PLAYER_FLAGS_CHANGED
-- toggles it; a slow ticker moves the clock. The dim is a static
-- BACKGROUND texture - built once, never re-anchored, so showing it in
-- combat is legal.
local _, S = ...

local ov, startT

local function fmtTime(sec)
	if sec < 60 then return sec .. "s" end
	if sec < 3600 then return math.floor(sec / 60) .. "m" end
	return math.floor(sec / 3600) .. "h " .. math.floor((sec % 3600) / 60) .. "m"
end

local function Build()
	if ov then return end
	ov = CreateFrame("Frame", "SentiUIAFK", UIParent)
	ov:SetAllPoints()
	ov:SetFrameStrata("FULLSCREEN_DIALOG")
	ov:EnableMouse(true) -- the whole point: you cannot click through AFK

	local dim = ov:CreateTexture(nil, "BACKGROUND")
	dim:SetAllPoints()
	dim:SetColorTexture(0, 0, 0, 0.55)

	local card = CreateFrame("Frame", nil, ov)
	S.Template(card, "raised")
	card:SetSize(320, 132)
	card:SetPoint("CENTER", 0, 80)

	local title = S.Font(card, 20, S.colors.accent, "OUTLINE")
	title:SetPoint("TOP", 0, -16)
	title:SetText("AFK")

	local name = S.Font(card, 14)
	name:SetPoint("TOP", title, "BOTTOM", 0, -10)
	ov.name = name

	local sub = S.Font(card, 10, S.colors.textDim)
	sub:SetPoint("TOP", name, "BOTTOM", 0, -4)
	ov.sub = sub

	local timer = S.Font(card, 10, S.colors.textDim)
	timer:SetPoint("TOP", sub, "BOTTOM", 0, -10)
	ov.timer = timer

	ov:SetScript("OnUpdate", function(self, dt)
		self._t = (self._t or 0) + (dt or 0.05)
		if self._t < 1 then return end
		self._t = 0
		if startT then ov.timer:SetText(fmtTime(math.floor(GetTime() - startT))) end
	end)

	ov:Hide()
end

local function Fill()
	local okN, n = pcall(GetUnitName, "player")
	local _, cls = pcall(UnitClass, "player")
	local lvl = pcall(UnitLevel, "player") and UnitLevel("player") or nil
	local g = GetGuildInfo and select(1, GetGuildInfo("player")) or nil
	local nameTxt = type(n) == "string" and n or ""
	ov.name:SetText(nameTxt)
	local r, gg, b
	if C_ClassColor and C_ClassColor.GetClassColor and type(cls) == "string" then
		local c = C_ClassColor.GetClassColor(cls)
		if c then r, gg, b = c.r, c.g, c.b end
	end
	ov.name:SetTextColor(r or 1, gg or 1, b or 1)
	local bits = {}
	if type(lvl) == "number" and lvl > 0 then bits[#bits + 1] = lvl end
	if type(cls) == "string" then
		local okL, loc = pcall(function()
			return select(1, UnitClass("player")) end)
		if okL and type(loc) == "string" and loc ~= "" then
			bits[#bits + 1] = loc
		end
	end
	if type(g) == "string" and g ~= "" then bits[#bits + 1] = "<" .. g .. ">" end
	ov.sub:SetText(table.concat(bits, "  ·  "))
	ov.timer:SetText("0s")
end

local function Sync()
	if not S.DB then return end
	local on = S.DB.General().afkOverlay ~= false
	local ok, afk = pcall(UnitIsAFK, "player")
	if on and ok and afk == true then
		if not ov then Build() end
		if not ov:IsShown() then
			startT = GetTime()
			Fill()
			ov:Show()
		end
	elseif ov then
		ov:Hide()
	end
end

S.RegisterEvent("PLAYER_FLAGS_CHANGED", function(_, unit)
	if unit and unit ~= "player" then return end
	S.SafeCall("afk", Sync)
end)
S.RegisterEvent("PLAYER_LOGIN", function()
	C_Timer.After(2, function() S.SafeCall("afk", Sync) end)
end)

S.AfkSync = Sync -- options toggle re-checks live
