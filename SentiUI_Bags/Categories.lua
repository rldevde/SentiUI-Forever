-- Item classification into display categories. Priority: fresh loot
-- ("New") > junk (quality 0) > item class > misc. Class ids come from
-- C_Item.GetItemInfoInstant - everything guarded, secret info just
-- falls through to misc.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Categories = {}
ns.Categories = Categories

-- display order: top of the window first
Categories.ORDER = { "new", "quest", "equipment", "consumables",
	"tradegoods", "misc", "junk", "empty" }

local LABEL_KEYS = {
	new = "New", quest = "Quest", equipment = "Equipment",
	consumables = "Consumables", tradegoods = "Trade goods",
	misc = "Miscellaneous", junk = "Junk", empty = "Empty",
}
function Categories.Label(key) return L[LABEL_KEYS[key] or "Miscellaneous"] end

-- Enum.ItemClass ids -> display category
local CLASSMAP = {
	[0] = "consumables",  -- Consumable
	[2] = "equipment",    -- Weapon
	[4] = "equipment",    -- Armor
	[7] = "tradegoods",   -- Tradeskill
	[9] = "tradegoods",   -- Recipe
	[12] = "quest",       -- Quest
	[16] = "equipment",   -- Glyph
	[5] = "tradegoods",   -- Reagent
	[11] = "tradegoods",  -- Ammo / quiver pieces
	[17] = "misc",        -- Battle pets
	[18] = "misc",        -- WoW token
}

local function ClassOf(info)
	if not (info and info.hyperlink) or S.IsSecret(info.hyperlink) then
		return nil
	end
	local get = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
	if type(get) ~= "function" then return nil end
	local ok, _, _, _, _, _, classID = pcall(get, info.hyperlink)
	if ok and type(classID) == "number" then return classID end
end

-- is this slot a fresh pickup? C_NewItems tracks what the bag flagged new
local function IsNew(bag, slot)
	if not (C_NewItems and C_NewItems.IsNewItem) then return false end
	local ok, v = pcall(C_NewItems.IsNewItem, bag, slot)
	return ok and v == true
end

-- returns the category key for a slot; info nil = empty slot
function Categories.Of(bag, slot, info)
	if not info then return "empty" end
	if Categories.db and Categories.db.showNew and IsNew(bag, slot) then
		return "new"
	end
	local q = info.quality
	if type(q) == "number" and not S.IsSecret(q) and q == 0 then
		return "junk"
	end
	local cid = ClassOf(info)
	if cid ~= nil and CLASSMAP[cid] then return CLASSMAP[cid] end
	return "misc"
end
