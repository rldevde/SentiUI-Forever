local _, ns = ...
local S = {}
ns.Outfitter = S

S.name = "SentiUI_Outfitter"
S.GOLD = { 0.92, 0.68, 0.20 }
S.BLUE = { 0.20, 0.62, 1.00 }
S.WHITE = "Interface\\Buttons\\WHITE8X8"
-- common labels fall back to Blizzard's own global strings, which are
-- correct in every client language (covers locales we don't ship yet)
local BLIZZ = {
	["Cancel"] = "CANCEL", ["OK"] = "OKAY", ["Delete"] = "DELETE",
	["Settings"] = "SETTINGS", ["None"] = "NONE", ["Never"] = "NEVER",
	["Locked"] = "LOCKED", ["Done"] = "DONE", ["Update"] = "UPDATE",
}
S.L = setmetatable({}, { __index = function(_, k)
	local loc = rawget(_G, "SentiUIOutfitterLocale")
	local v = loc and loc[k]
	if v == nil then
		local g = BLIZZ[k]
		v = g and rawget(_G, g) or nil
	end
	return v or k
end })
local L = S.L

local issecretvalue = issecretvalue
function S.Sec(v) return issecretvalue ~= nil and issecretvalue(v) end
function S.Clean(v) if v ~= nil and issecretvalue and issecretvalue(v) then return nil end return v end

function S:Print(...)
	print("|cffebad33SentiUI Outfitter|r:", ...)
end

-- ===================================================================
-- Out-of-combat deferral
-- ===================================================================
local deferred, order = {}, {}
function S:Defer(key, fn, ...)
	if not InCombatLockdown() then return fn(...) end
	if not deferred[key] then order[#order + 1] = key end
	deferred[key] = { fn, select("#", ...), ... }
end
S.RunOutOfCombat = S.Defer

local function Flush()
	local keys = order
	order = {}
	for _, k in ipairs(keys) do
		local d = deferred[k]
		deferred[k] = nil
		if d then
			local ok, err = pcall(d[1], unpack(d, 3, 2 + d[2]))
			if not ok then S.lastErr = err end
		end
	end
end

-- ===================================================================
-- Events
-- ===================================================================
local handlers = {}
local ev = CreateFrame("Frame")
S.ev = ev
function S:On(event, fn)
	if not handlers[event] then
		handlers[event] = {}
		if not pcall(ev.RegisterEvent, ev, event) then handlers[event] = nil return false end
	end
	table.insert(handlers[event], fn)
	return true
end

ev:SetScript("OnEvent", function(_, event, ...)
	local h = handlers[event]
	if h then for i = 1, #h do h[i](event, ...) end end
end)

-- ===================================================================
-- Defaults / DB
-- ===================================================================
S.DEFAULTS = {
	enabled = true,
	bar = {
		enabled = true, scale = 0.9, vertical = false, locked = false,
		alpha = 1, combatAlpha = 0.45, showNames = false,
	},
	tooltip = { mode = "ALWAYS" }, -- ALWAYS / OOC / NEVER
	ui = { scale = 1, followChar = true, protectSell = true, bagMarker = true },
	minimap = { hide = false, angle = -35 },
	position = nil, -- filled lazily
}

local function Merge(dst, src)
	for k, v in pairs(src) do
		if dst[k] == nil then
			dst[k] = type(v) == "table" and CopyTable(v) or v
		elseif type(v) == "table" and type(dst[k]) == "table" then
			Merge(dst[k], v)
		end
	end
end
S.MergeDefaults = Merge

-- legacy values must WIN over defaults, so the migration overlay
-- writes leaves unconditionally (Merge only fills gaps)
local function Overlay(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			Overlay(dst[k], v)
		else
			dst[k] = type(v) == "table" and CopyTable(v) or v
		end
	end
end

function S:InitDB(db)
	db.bar = db.bar or {}
	db.tooltip = db.tooltip or {}
	db.ui = db.ui or {}
	db.minimap = db.minimap or {}
	Merge(db.bar, self.DEFAULTS.bar)
	Merge(db.tooltip, self.DEFAULTS.tooltip)
	Merge(db.ui, self.DEFAULTS.ui)
	Merge(db.minimap, self.DEFAULTS.minimap)
	-- one-time import of the standalone addon's per-character saved vars,
	-- so existing sets, bar position and options carry over
	if not db._migrated and type(_G.SentiOutfitterDB) == "table" then
		Overlay(db, _G.SentiOutfitterDB)
		db._migrated = true
	end
	self.db = db
end

function S:CharKey()
	return (GetUnitName("player", false) or UnitName("player")) .. "-" .. (GetRealmName() or "")
end

-- ===================================================================
-- Refresh dispatcher
-- ===================================================================
function S:Refresh(kind)
	if kind == "bar" then self:RefreshBar()
	elseif kind == "sets" then self:RefreshSets()
	elseif kind == "ui" then self:RefreshUI()
	else self:RefreshSets() end
end

function S:RefreshSets()
	self:InvalidateItemSets()
	if self.RefreshBar then self:RefreshBar() end
	if self.RefreshUI then self:RefreshUI() end
end

-- ===================================================================
-- Boot (driven by the SentiUI module host: Module.lua calls S.Boot
-- with the module's saved-variables table)
-- ===================================================================
function S.Boot(mod)
	if S.booted then return end
	if not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs) then
		S:Print("C_EquipmentSet API missing - Outfitter disabled.")
		return
	end
	S.booted = true
	S:InitDB(mod.db)
	S:InitSlots()
	S:InitBar()
	S:InitUI()
	S:InitTooltip()
	S:InitMinimap()
	S:InitProtect()
	S:InitBadges()
	S:Defer("layout", S.ApplyBarLayout, S)

	-- keep the worn-set marker and item states in sync with live gear
	S:On("PLAYER_EQUIPMENT_CHANGED", function()
		S:Defer("equipchanged", S.RefreshSets, S)
	end)
	S:On("EQUIPMENT_SETS_CHANGED", function()
		S:Defer("setschanged", S.RefreshSets, S)
	end)
end

-- the /sui module page writes mod.db paths - dispatch them to the
-- subsystem they affect
function S.SettingChanged(path)
	if not S.db then return end
	if type(path) == "string" and path:find("^bar%.") then
		if S.RefreshBar then S:RefreshBar() end
		if S.ApplyBarLayout then S:ApplyBarLayout() end
	elseif type(path) == "string" and path:find("^minimap%.") then
		if S.ApplyMinimapVisibility then S:ApplyMinimapVisibility() end
	else
		S:RefreshSets()
	end
end

-- the suite's settings/changelog reads ns.L and ns.DEFAULTS
ns.L = S.L
ns.DEFAULTS = S.DEFAULTS

S:On("PLAYER_REGEN_ENABLED", Flush)

SLASH_SENTIOUTFITTER1, SLASH_SENTIOUTFITTER2 = "/so", "/sentioutfitter"
SlashCmdList["SENTIOUTFITTER"] = function(msg)
	msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if msg == "" then
		S:ToggleUI()
	elseif msg == "bar" then
		S.db.bar.enabled = not S.db.bar.enabled
		S:Refresh("bar")
		S:Print(L["Outfit bar"] .. ": " .. (S.db.bar.enabled and L["on"] or L["off"]))
	elseif msg == "debug" then
		S:Print("last error:", tostring(S.lastErr))
	elseif msg == "options" then
		S:ToggleOptions()
	elseif msg == "bags" then
		if S.BagDebug then S:BagDebug() end
	elseif msg == "scan" then
		if S.ScanCharFrames then S:ScanCharFrames() end
	else
		local name = msg
		local id = S:FindSetID(name)
		if id then
			S:WearSet(id)
		else
			S:Print(L["Unknown outfit"] .. ": " .. name)
			S:ToggleUI()
		end
	end
end


