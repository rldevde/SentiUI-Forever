-- Item/spell tooltip extras: quality-colored border and top edge
-- (uncommon and up), an item-level line when the game didn't already
-- write one, max-stack line and item/spell IDs. Every added line goes
-- through a dedup check: the item post-call can fire more than once per
-- show and plain AddLine would stack the same line.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Item = {}
ns.Item = Item

local function plain(v)
	if S.IsSecret(v) then return nil end
	return v
end

local function TipLink(tip, data)
	-- the data block usually carries the link; GetItem is the fallback
	local link = type(data) == "table" and plain(data.hyperlink) or nil
	if type(link) == "string" then return link end
	local ok, _, l = pcall(tip.GetItem, tip)
	l = ok and plain(l)
	return type(l) == "string" and l or nil
end

local QUALITY_FALLBACK = {
	[0] = { 0.62, 0.62, 0.62 }, [1] = { 1, 1, 1 },
	[2] = { 0.12, 1.00, 0.00 }, [3] = { 0.00, 0.44, 0.87 },
	[4] = { 0.64, 0.21, 0.93 }, [5] = { 1.00, 0.50, 0.00 },
	[6] = { 0.90, 0.80, 0.50 }, [7] = { 0.90, 0.80, 0.50 },
	[8] = { 0.00, 0.80, 1.00 },
}

local function Quality(tip, link)
	local ok, q = pcall(function()
		return select(3, C_Item.GetItemInfo(link))
	end)
	q = ok and plain(q)
	if type(q) ~= "number" or q < 2 then return end -- common and below keep the default edge
	local c = (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]) or QUALITY_FALLBACK[q]
	if type(c) == "table" and not S.IsSecretTable(c) then
		local r, g, b = c.r or c[1], c.g or c[2], c.b or c[3]
		ns.Skin.SetBorder(tip, r, g, b)
		if ns.Cfg().coloredEdge then ns.Skin.SetAccent(tip, r, g, b) end
	end
end

-- whether a tooltip line already contains one of the given needles
local function HasLine(tip, needles)
	local name = tip:GetName()
	if type(name) ~= "string" then return true end
	for i = 1, tip:NumLines() or 0 do
		local fs = _G[name .. "TextLeft" .. i]
		local t = fs and fs.GetText and fs:GetText()
		if type(t) == "string" and not S.IsSecret(t) then
			for _, n in ipairs(needles) do
				if t:find(n, 1, true) then return true end
			end
		end
	end
	return false
end

local ILVL_NEEDLES = { "Item Level", "Gegenstandsstufe", "item level" }

local function AddItemLevel(tip, link)
	if not (C_Item and C_Item.GetDetailedItemLevelInfo) then return end
	local ok, v = pcall(C_Item.GetDetailedItemLevelInfo, link)
	v = ok and plain(v)
	if type(v) ~= "number" or v <= 1 then return end
	if HasLine(tip, ILVL_NEEDLES) then return end
	tip:AddLine("|cff" .. S.Hex(S.colors.accent) .. L["Item Level"]
		.. "|r " .. math.floor(v + 0.5))
end

local function AddStack(tip, link)
	if not (C_Item and C_Item.GetItemInfo) then return end
	local ok, n = pcall(function() return select(8, C_Item.GetItemInfo(link)) end)
	n = ok and plain(n)
	if type(n) == "number" and n > 1 and not HasLine(tip, { L["Max stack"] }) then
		tip:AddLine("|cff" .. S.Hex(S.colors.accent) .. L["Max stack"]
			.. "|r " .. n)
	end
end

local function AddID(tip, link, data)
	local id = type(data) == "table" and plain(data.id) or nil
	if type(id) ~= "number" and C_Item and C_Item.GetItemInfoInstant then
		local ok, v = pcall(C_Item.GetItemInfoInstant, link)
		id = ok and plain(v) or nil
	end
	if type(id) == "number" and not HasLine(tip, { L["Item ID"] }) then
		tip:AddLine("|cff" .. S.Hex(S.colors.accent) .. L["Item ID"]
			.. "|r " .. id)
	end
end

-- owned count: "Bags: x | Bank: y" - GetItemCount includeCharges=false,
-- includeBank toggles the second read
local function AddCount(tip, link)
	if not (C_Item and C_Item.GetItemCount) then return end
	local okB, bags = pcall(C_Item.GetItemCount, link, false)
	bags = okB and plain(bags) or 0
	local okT, total = pcall(C_Item.GetItemCount, link, true)
	total = okT and plain(total) or bags
	if type(bags) ~= "number" or type(total) ~= "number" then return end
	local bank = total - bags
	if bags <= 0 and bank <= 0 then return end
	if HasLine(tip, { L["Owned:"] }) then return end
	tip:AddLine("|cff" .. S.Hex(S.colors.accent) .. L["Owned:"] .. "|r "
		.. bags .. (bank > 0 and " (+" .. bank .. " " .. L["bank"] .. ")" or ""))
end

function Item.Apply(tip, data)
	local db = ns.Cfg()
	local link = TipLink(tip, data)
	if not link then return end
	if db.qualityBorder then Quality(tip, link) end
	if db.itemLevel then AddItemLevel(tip, link) end
	if db.stackSize then AddStack(tip, link) end
	if db.itemCount ~= false then AddCount(tip, link) end
	if db.showIDs then AddID(tip, link, data) end
end

-- spells get just the ID (the game's own spell layout stays untouched)
function Item.Spell(tip, data)
	if not ns.Cfg().showIDs then return end
	local id = type(data) == "table" and plain(data.id) or nil
	if type(id) == "number" and not HasLine(tip, { L["Spell ID"] }) then
		tip:AddLine("|cff" .. S.Hex(S.colors.accent) .. L["Spell ID"]
			.. "|r " .. id)
	end
end
