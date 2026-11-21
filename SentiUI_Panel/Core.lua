-- Shared helpers for the panel module: secret-safe value reads, the
-- tooltip vocabulary every plugin uses (header / key-value / section),
-- the small context-menu popup and a multi-line text popup for details
-- and exports. Bars, plugins and the kill window all build on these.
local _, ns = ...
local S = SentiUI
local L = ns.L

local ipairs, pairs, type = ipairs, pairs, type
local format, min = string.format, math.min
local tinsert = table.insert
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip

local BLANK = "Interface\\Buttons\\WHITE8X8"

ns.version = "0.1.0"
ns.accentHex = S.Hex(S.colors.accent)
ns.blueHex = S.Hex(S.colors.accent2)
ns.dimHex = S.Hex(S.colors.textDim)

local C = S.colors

-- secret values: reading/comparing a secret throws, so every external
-- value goes through Plain() first; tables through CanAccess().
function ns.Plain(v)
	if v == nil or S.IsSecret(v) then return nil end
	if type(v) == "table" and S.IsSecretTable(v) then return nil end
	return v
end

function ns.CanAccess(t)
	return type(t) == "table" and not S.IsSecretTable(t)
end

-- mail truth: HasNewMail() is the native signal the engine feeds the
-- minimap envelope with (the same call SentinelForeverCore's info bar
-- uses), so it is the verdict. The minimap mail frame is only a fallback
-- for a missing API - and only the icon child counts, never the
-- always-shown IndicatorFrame container it lives in. An OnShow/OnHide
-- hook keeps that fallback fresh the way DaylightUI tracks its mail dot.

local function MailFrame()
	local cluster = _G.MinimapCluster
	local ind = cluster and (cluster.IndicatorFrame or cluster.MailFrame)
	if ind and type(ind.MailFrame) == "table" then return ind.MailFrame end
	return _G.MiniMapMailFrame
end

local function MailFrameShown()
	-- poll instead of HookScript: an insecure script handler on a
	-- Blizzard frame is a taint vector on this client
	local f = MailFrame()
	if not (type(f) == "table" and type(f.IsShown) == "function") then
		return nil
	end
	local ok, s = pcall(f.IsShown, f)
	return ok and (ns.Plain(s) == true) or nil
end

function ns.MailWaiting()
	local ok, has = pcall(HasNewMail)
	has = ok and ns.Plain(has)
	if type(has) == "boolean" then return has end
	local shown = MailFrameShown()
	if shown ~= nil then return shown end
	if type(GetLatestThreeSenders) == "function" then
		local ok2, a = pcall(GetLatestThreeSenders)
		if ok2 and not S.IsSecret(a) then return a ~= nil end
	end
	return false
end

-- /suipanel mail: prints every mail signal so a stuck indicator can be
-- traced to the layer that lies
function ns.MailDebug()
	local function state(f)
		if type(f) ~= "table" then return "missing" end
		local ok, s = pcall(f.IsShown, f)
		return "shown=" .. tostring(ok
			and (S.IsSecret(s) and "secret" or s) or ("err:" .. tostring(s)))
	end
	local cluster = _G.MinimapCluster
	local ind = cluster and (cluster.IndicatorFrame or cluster.MailFrame)
	local parts = {
		"indicator=" .. state(ind and ind.MailFrame),
		"minimapmail=" .. state(_G.MiniMapMailFrame),
		"shown=" .. tostring(MailFrameShown()),
	}
	if type(GetLatestThreeSenders) == "function" then
		local ok, a = pcall(GetLatestThreeSenders)
		parts[#parts + 1] = "senders=" .. (ok
			and tostring(S.IsSecret(a) and "secret" or a)
			or ("err:" .. tostring(a)))
	else
		parts[#parts + 1] = "senders=api missing"
	end
	local ok, has = pcall(HasNewMail)
	parts[#parts + 1] = "hasnewmail=" .. (ok
		and tostring(S.IsSecret(has) and "secret" or has)
		or ("err:" .. tostring(has)))
	parts[#parts + 1] = "verdict=" .. tostring(ns.MailWaiting())
	S.Print("mail: " .. table.concat(parts, " | "))
end

-- for potentially protected Blizzard APIs: securecall runs them natively
-- when allowed and fails quietly instead of logging ADDON_ACTION_FORBIDDEN
local hardFailed = {}
-- for hardware/protected calls we cannot fully predict (party ops,
-- channel sends): runs the call, and when it is rejected prints the
-- call site ONCE with the function's name - the client's own report
-- only says UNKNOWN()
function ns.HardAPI(name, fn, ...)
	if type(fn) ~= "function" then return end
	local ok = pcall(fn, ...)
	if ok then return true end
	if not hardFailed[name] then
		hardFailed[name] = true
		local where = "?"
		if debug and debug.getinfo then
			local i = debug.getinfo(2, "Sl")
			where = i and (tostring(i.short_src) .. ":" .. tostring(i.currentline)) or "?"
		end
		S.Print("|cffffcc33blocked call:|r " .. tostring(name) .. " @ " .. where)
	end
	return nil
end

-- centralised in the core: every module shares the same wrapper with
-- call-site reporting (file.lua:line) for blocked/failed engine calls
ns.SecureAPI = S.SecureAPI

-- tooltip helpers --------------------------------------------------------------
function ns.TipHead(tip, text)
	tip:AddLine("|cff" .. ns.accentHex .. text .. "|r")
end

function ns.TipKV(tip, k, v)
	tip:AddDoubleLine("|cff" .. ns.dimHex .. tostring(k) .. "|r", tostring(v), 1, 1, 1, 1, 1, 1)
end

function ns.TipSub(tip, text)
	tip:AddLine(" ")
	tip:AddLine("|cff" .. ns.dimHex .. text .. "|r")
end

-- class-colored name, falls back to plain text
function ns.ClassColor(name, class)
	local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if not c then return name end
	local hex = c.colorStr or format("ff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
	return "|c" .. hex .. name .. "|r"
end

-- small visuals ----------------------------------------------------------------
function ns.Font(parent, size, color, flags)
	return S.Font(parent, size, color, flags)
end

-- 1px accent line pinned to one edge of a frame
function ns.AccentEdge(f, edge)
	if not f.accentEdge then
		f.accentEdge = f:CreateTexture(nil, "ARTWORK")
		f.accentEdge:SetColorTexture(C.accent.r, C.accent.g, C.accent.b, 0.6)
	end
	local t = f.accentEdge
	t:ClearAllPoints()
	if edge == "BOTTOM" then
		t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
		t:SetHeight(1)
	elseif edge == "LEFT" then
		t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
		t:SetWidth(1)
	elseif edge == "RIGHT" then
		t:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
		t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
		t:SetWidth(1)
	else
		t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		t:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
		t:SetHeight(1)
	end
	t:Show()
	return t
end

-- soft top gradient inside a panel, the Sentinel "gloss" strip
function ns.Gloss(f, show)
	if not f.shadeTex then
		f.shadeTex = f:CreateTexture(nil, "BORDER")
		f.shadeTex:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
		f.shadeTex:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
		f.shadeTex:SetColorTexture(1, 1, 1, 0.035)
	end
	f.shadeTex:SetHeight(min(f:GetHeight() or 22, 14) * 0.9)
	f.shadeTex:SetShown(show)
end

-- widgets ----------------------------------------------------------------------
function ns.Button(parent, w, h, label)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 90, h or 24)
	S.Template(b, "raised")
	b.label = ns.Font(b, 11)
	b.label:SetPoint("CENTER")
	b.label:SetWidth((w or 90) - 4)
	b.label:SetJustifyH("CENTER")
	b.label:SetText(label or "")
	b:SetScript("OnEnter", function() S.SetBorderLit(b, true) end)
	b:SetScript("OnLeave", function() S.SetBorderLit(b, false) end)
	return b
end

function ns.CloseButton(parent, size)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(size or 18, size or 18)
	local t = ns.Font(b, 12)
	t:SetAllPoints()
	t:SetJustifyH("CENTER")
	t:SetText("x")
	t:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b)
	b:SetScript("OnEnter", function() t:SetTextColor(C.accent.r, C.accent.g, C.accent.b) end)
	b:SetScript("OnLeave", function() t:SetTextColor(C.textDim.r, C.textDim.g, C.textDim.b) end)
	return b
end

-- context menu ------------------------------------------------------------------
local MENU_ITEM_H = 20
local menuFrame, menuCatcher

local function CloseMenu()
	if menuFrame then menuFrame:Hide() end
	if menuCatcher then menuCatcher:Hide() end
end
ns.CloseMenu = CloseMenu

-- items: { text, checked?, isTitle?, disabled?, noClose?, onClick? }
-- items may also be a function returning the list (regenerated per click
-- so noClose toggles redraw their checkmarks)
function ns.OpenMenu(anchor, items, above)
	if not menuFrame then
		menuCatcher = CreateFrame("Button", nil, UIParent)
		menuCatcher:SetAllPoints(UIParent)
		menuCatcher:SetFrameStrata("TOOLTIP")
		menuCatcher:SetFrameLevel(1)
		menuCatcher:RegisterForClicks("AnyUp", "AnyDown")
		menuCatcher:SetScript("OnClick", CloseMenu)
		-- let the click pass through to the world as well: swallowing a
		-- right-click cancel gets protected functions (SpellStopTargeting)
		-- blamed on us
		if menuCatcher.SetPropagateMouseClicks then
			menuCatcher:SetPropagateMouseClicks(true)
		end
		menuCatcher:Hide()

		menuFrame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		menuFrame:SetFrameStrata("TOOLTIP")
		menuFrame:SetFrameLevel(10)
		menuFrame:SetClampedToScreen(true)
		S.Template(menuFrame, "panel")
		ns.AccentEdge(menuFrame, "TOP")
		menuFrame.items = {}
	end
	CloseMenu()
	if type(items) == "function" then
		menuFrame.gen = items
		items = items()
	else
		menuFrame.gen = nil
	end
	for _, b in ipairs(menuFrame.items) do b:Hide() end

	local w = 120
	local y = -4
	for i, item in ipairs(items) do
		local b = menuFrame.items[i]
		if not b then
			b = CreateFrame("Button", nil, menuFrame)
			b:SetHeight(MENU_ITEM_H)
			b.check = b:CreateTexture(nil, "ARTWORK")
			b.check:SetSize(8, 8)
			b.check:SetPoint("LEFT", b, "LEFT", 8, 0)
			b.check:SetTexture(BLANK)
			b.check:SetVertexColor(C.accent.r, C.accent.g, C.accent.b)
			b.txt = ns.Font(b, 11)
			b.txt:SetPoint("LEFT", b.check, "RIGHT", 8, 0)
			b:SetScript("OnEnter", function()
				if not b.isTitle and not b.disabled then b.txt:SetTextColor(C.accent.r, C.accent.g, C.accent.b) end
			end)
			b:SetScript("OnLeave", function()
				b.txt:SetTextColor(b.isTitle and C.textDim.r or C.text.r,
					b.isTitle and C.textDim.g or C.text.g,
					b.isTitle and C.textDim.b or C.text.b)
			end)
			menuFrame.items[i] = b
		end
		b.isTitle = item.isTitle or false
		b.disabled = item.disabled or false
		b.check:SetShown(item.checked or false)
		b.txt:SetText(item.text or "")
		b.txt:SetTextColor(item.isTitle and C.textDim.r or C.text.r,
			item.isTitle and C.textDim.g or C.text.g,
			item.isTitle and C.textDim.b or C.text.b)
		b:SetScript("OnClick", function()
			if item.noClose then
				if item.onClick then item.onClick() end
				if menuFrame.gen then ns.OpenMenu(anchor, menuFrame.gen) end
			else
				CloseMenu()
				if item.onClick then item.onClick() end
			end
		end)
		b:EnableMouse(not b.isTitle and not b.disabled)
		b:ClearAllPoints()
		b:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 4, y)
		b:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -4, y)
		b:Show()
		local tw = (b.txt:GetStringWidth() or 0) + 34
		if tw > w then w = tw end
		y = y - MENU_ITEM_H
	end
	menuFrame:SetSize(min(w, 320), -y + 4)

	menuFrame:ClearAllPoints()
	if anchor and above then
		menuFrame:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
	elseif anchor then
		menuFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	else
		local scale = UIParent:GetEffectiveScale()
		local cx, cy = GetCursorPosition()
		menuFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cx / scale + 4, cy / scale + 4)
	end
	menuCatcher:Show()
	menuFrame:Show()
end

-- multi-line text popup (details / export) ---------------------------------------
local textPopup

function ns.TextPopup(title, text, onAccept)
	if not textPopup then
		local f = CreateFrame("Frame", "SentiUIPanelTextPopup", UIParent, "BackdropTemplate")
		f:SetSize(460, 320)
		f:SetPoint("CENTER")
		f:SetFrameStrata("DIALOG")
		f:SetMovable(true)
		f:EnableMouse(true)
		f:SetClampedToScreen(true)
		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", f.StartMoving)
		f:SetScript("OnDragStop", function(self)
			self:StopMovingOrSizing()
			S.Movers.Save("panel.textpopup")
		end)
		S.Template(f, "panel")
		ns.AccentEdge(f, "TOP")
		S.Movers.Register(f, "panel.textpopup", L["Text window"])
		f.title = ns.Font(f, 13, C.accent, "OUTLINE")
		f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
		local close = ns.CloseButton(f, 18)
		close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -10)
		close:SetScript("OnClick", function() f:Hide() end)

		local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
		scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -36)
		scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 44)
		local edit = CreateFrame("EditBox", nil, scroll)
		edit:SetMultiLine(true)
		edit:SetAutoFocus(false)
		edit:SetFontObject(GameFontHighlightSmall)
		edit:SetWidth(400)
		-- no OnEscapePressed handler on purpose: ANY insecure code in
		-- the Escape dispatch taints the engine's later spell-stop
		-- calls (protected SpellStopCasting/SpellStopTargeting,
		-- ADDON_ACTION_FORBIDDEN blamed on us). The frame is in
		-- UISpecialFrames, so the engine hides it natively and the
		-- edit box drops focus on its own.
		scroll:SetScrollChild(edit)
		f.edit = edit

		local ok = ns.Button(f, 90, 22, L["Accept"])
		ok:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
		f.accept = ok
		tinsert(UISpecialFrames, "SentiUIPanelTextPopup")
		textPopup = f
	end
	local f = textPopup
	f.title:SetText("|cff" .. ns.accentHex .. tostring(title or "") .. "|r")
	f.edit:SetText(text or "")
	if onAccept then
		f.accept:Show()
		f.accept:SetScript("OnClick", function()
			S.SafeCall("popup:accept", onAccept, f.edit:GetText())
			f:Hide()
		end)
	else
		f.accept:Hide()
	end
	f:Show()
	f.edit:HighlightText(0, 0)
	f.edit:SetCursorPosition(0)
end

-- module event bus: one frame, buckets per event ----------------------------------
local bus = CreateFrame("Frame")
local buckets = {}
bus:SetScript("OnEvent", function(_, event, ...)
	local list = buckets[event]
	if not list then return end
	for i = 1, #list do S.SafeCall("panel:" .. event, list[i], event, ...) end
end)

function ns.RegisterBusEvent(event, fn)
	local list = buckets[event]
	if not list then
		list = {}
		buckets[event] = list
		pcall(bus.RegisterEvent, bus, event)
	end
	list[#list + 1] = fn
end

-- boot ----------------------------------------------------------------------------
function ns.CoreEnable(mod)
	local db = mod.db
	db.plugins = db.plugins or {}
	db.chars = db.chars or {}
	db.notify = db.notify or { mail = true, dura = true, bags = true, rare = true }
	db.bars = db.bars or {}
	db.bars.top = db.bars.top or CopyTable(ns.DEFAULTS.bars.top)
	db.bars.bottom = db.bars.bottom or CopyTable(ns.DEFAULTS.bars.bottom)
	ns.db = db

	ns.Bars.Initialize()
	ns.Viewport.Initialize()
	ns.Toasts.Initialize()
	ns.Plugins.Initialize()

	SLASH_SENTIUIPANEL1 = "/suipanel"
	SLASH_SENTIUIPANEL2 = "/spnl"
	SlashCmdList.SENTIUIPANEL = function(msg) ns.Slash(msg) end
end

function ns.Slash(msg)
	msg = strtrim(msg or ""):lower()
	local B = ns.Bars
	if msg == "top" or msg == "bottom" then
		local cfg = ns.db.bars[msg]
		cfg.enabled = not cfg.enabled
		B.ApplyAll()
		S.Print(format("panel %s: %s", msg, cfg.enabled and L["On"] or L["Off"]))
	elseif msg == "reset" then
		wipe(ns.db.plugins)
		ns.Plugins.ResetLayout()
		S.Print(L["Layout reset"])
	elseif msg == "mail" then
		ns.MailDebug()
	elseif msg == "fbl" then
		if ns.FBL and ns.FBL.Debug then ns.FBL.Debug() end
	else
		if S.OptionsPanel and S.OptionsPanel.Toggle then S.OptionsPanel.Toggle() end
	end
end
