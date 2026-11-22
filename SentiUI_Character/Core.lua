-- Character module core: enable/disable, the Blizzard-frame swap and
-- shared secret-safe helpers. The window itself lives in Window.lua.
local _, ns = ...
local S = SentiUI

ns.C = {}
local C = ns.C

local mod           -- the registered module (holds mod.db)
local hooked = false

-- Secret-safe number read: nil when the client hands us a secret value.
function ns.Plain(v)
	if v == nil or S.IsSecret(v) then return nil end
	local ok, r = pcall(function() return v + 0 end)
	return ok and r or nil
end

-- Same for strings (item links, names).
function ns.PlainStr(v)
	if v == nil or S.IsSecret(v) then return nil end
	local ok, r = pcall(function() return v .. "" end)
	return ok and r or nil
end

function C.db() return mod and mod.db end

function C.IsOpen()
	local w = ns.Win.frame
	return w and w:IsShown() or false
end

function C.Open(page)
	if not mod or not mod.db.enabled then return end
	ns.Win.Show(page)
	if CharacterFrame and CharacterFrame:IsShown() then
		CharacterFrame:Hide()
	end
end

function C.Close()
	if ns.Win.frame then ns.Win.frame:Hide() end
end

function C.Toggle(page)
	if C.IsOpen() and (not page or page == ns.Win.currentPage) then
		C.Close()
	else
		C.Open(page)
	end
end

-- Blizzard frame name -> our page. Unknown/unavailable tabs fall through
-- to the Blizzard window untouched.
local TABMAP = {
	PaperDollFrame = "character",
	PetPaperDollFrame = "pet",
	ReputationFrame = "reputation",
	SkillFrame = "skills",
	HonorFrame = "pvp",
	TokenFrame = "currency",
	StatsFrame = "statistics",
}

function C.PageForTab(tab)
	if not tab then return "character" end
	local id = TABMAP[tab]
	if not id then return nil end
	local def = ns.Pages.defs[id]
	if def then
		local ok, avail = pcall(def.Available or function() return true end)
		if not (ok and avail) then return nil end
	end
	return id
end

-- ToggleCharacter is post-hooked only to note intent (which tab, and
-- that the show was user-driven). The assignment runs at the tail of
-- the key dispatch where nothing protected follows - harmless.
-- ShowUIPanel itself gets NO hook: it is called for every managed
-- panel (spellbook, talents, map, ...) and any Lua in its dispatch
-- taints the client's panel management. Everything else is observed
-- through WatchShown on the Blizzard frame instead.
local pendingTab, toggled, selfHide
local function OnToggleCharacter(tab)
	pendingTab = tab
	toggled = true
end

-- The game shows CharacterFrame for every open path (key, micro menu,
-- API). One watcher covers them all: a user toggle swaps to our window
-- (or closes it), an incidental re-show (UIParent management while ours
-- is open) just gets re-hidden, and a real close hides ours too.
local function WatchBlizzard()
	S.WatchShown(function() return _G.CharacterFrame end, function(f)
		if not (mod and mod.db.enabled) then return end
		selfHide = true
		if f:IsShown() then f:Hide() end
		if toggled then
			toggled = false
			if C.IsOpen() then C.Close()
			else C.Open(C.PageForTab(pendingTab) or "character") end
			pendingTab = nil
		elseif not C.IsOpen() then
			pendingTab = nil
			C.Open("character")
		end
	end, function()
		if selfHide then selfHide = false return end
		if C.IsOpen() then C.Close() end
	end)
end

function C.Enable(m)
	mod = m
	ns.Win.Build()
	S.EscClosable(ns.Win.frame)

	if not hooked then
		hooked = true
		if ToggleCharacter then
			hooksecurefunc("ToggleCharacter", OnToggleCharacter)
		end
	end

	-- CharacterFrame is load-on-demand; the resolver keeps polling until
	-- it exists, no event retry needed.
	WatchBlizzard()

	-- Batched refresh: inventory/stat events set a flag, OnUpdate applies it.
	local pending = false
	local function Dirty() pending = true end
	for _, e in ipairs({
		"UNIT_INVENTORY_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
		"UNIT_STATS", "UNIT_ATTACK_POWER", "UNIT_RANGED_ATTACK_POWER",
		"UNIT_ATTACK_SPEED", "UNIT_DAMAGE", "UNIT_DEFENSE", "UNIT_RESISTANCES",
		"COMBAT_RATING_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_INVENTORY_DURABILITY",
	}) do
		S.RegisterEvent(e, function(_, unit)
			-- UNIT_* events carry a unit; others (equipment slot etc.) don't.
			if e:sub(1, 5) == "UNIT_" and unit ~= "player" then return end
			if C.IsOpen() then Dirty() end
		end)
	end
	local pump = CreateFrame("Frame")
	pump:SetScript("OnUpdate", function()
		if pending then pending = false ns.Win.Refresh() end
	end)
end

function C.SettingChanged(m, path)
	mod = m
	local db = m.db
	if path == "enabled" then
		if db.enabled then C.Enable(m) else C.Close() end
		return
	end
	if not ns.Win.frame then return end
	if path == "names" or path == "itemLevel" or path == "ilvlInIcon"
		or path == "model" then
		ns.Win.Layout()
	end
	if C.IsOpen() then ns.Win.Refresh() end
end
