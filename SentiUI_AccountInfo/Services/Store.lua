-- luacheck: read globals C_Item GetItemInfo issecretvalue GetServerTime
local _, ns = ...

-- Data access over ns.db.chars plus item display helpers. Char records:
--   key     "Name-Realm"
--   char = {
--     name, realm, class, faction, race, level, guild,
--     money            copper
--     bags, bank       { [itemID] = totalCount }
--     gear             { [slot] = itemID }
--     bagsAt, bankAt, gearAt, moneyAt, updated   timestamps
--     account          home account label, nil = this WoW account
--     imported         true when the record came from outside
--   }
local Store = {}
ns.Store = Store

local L = ns.L

local function IsSecret(v)
	return issecretvalue ~= nil and issecretvalue(v)
end

function Store.OwnKey()
	return ns:GetPlayerFullName()
end

-- Own char record, creating it on first use. Nil early in loading.
function Store.OwnChar()
	local key = Store.OwnKey()
	if not key or not ns.db then
		return nil
	end
	local char = ns.db.chars[key]
	if not char then
		char = {}
		ns.db.chars[key] = char
	end
	return char, key
end

function Store.Char(key)
	return ns.db and ns.db.chars[key]
end

-- Sorted key list: this account first (alphabetical), then imported
-- records grouped by their account label.
function Store.CharKeys()
	local keys = {}
	if not ns.db then
		return keys
	end
	for key in pairs(ns.db.chars) do
		keys[#keys + 1] = key
	end
	table.sort(keys, function(a, b)
		local aa = Store.AccountOf(ns.db.chars[a]) or ""
		local ab = Store.AccountOf(ns.db.chars[b]) or ""
		if aa ~= ab then
			return aa < ab
		end
		return a < b
	end)
	return keys
end

-- Account label for grouping: nil account = this WoW account, imported
-- records without a label group under "Imported".
function Store.AccountOf(char)
	if char and char.account and char.account ~= "" then
		return char.account
	end
	if char and char.imported then
		return L.ACCOUNT_IMPORT
	end
	return nil
end

function Store.TotalMoney()
	local total = 0
	if ns.db then
		for _, char in pairs(ns.db.chars) do
			total = total + (tonumber(char.money) or 0)
		end
	end
	return total
end

function Store.CharCount()
	local n = 0
	if ns.db then
		for _ in pairs(ns.db.chars) do
			n = n + 1
		end
	end
	return n
end

-- Number of distinct item ids in a count table.
function Store.ItemKindCount(t)
	local n = 0
	if type(t) == "table" then
		for _ in pairs(t) do
			n = n + 1
		end
	end
	return n
end

function Store.DeleteChar(key)
	if not ns.db or key == Store.OwnKey() then
		return false
	end
	if ns.db.chars[key] then
		ns.db.chars[key] = nil
		ns:Fire("SAI_CHARS_CHANGED")
		return true
	end
	return false
end

-- Removes every record flagged as imported; returns how many.
function Store.DeleteImported()
	local n = 0
	if ns.db then
		for key, char in pairs(ns.db.chars) do
			if char.imported then
				ns.db.chars[key] = nil
				n = n + 1
			end
		end
	end
	if n > 0 then
		ns:Fire("SAI_CHARS_CHANGED")
	end
	return n
end

--------------------------------------------------------------------------------
-- Item lookup
--------------------------------------------------------------------------------

function Store.ItemIcon(id)
	if C_Item and C_Item.GetItemIconByID then
		local ok, icon = pcall(C_Item.GetItemIconByID, id)
		if ok and icon and not IsSecret(icon) then
			return icon
		end
	end
	local ok, _, _, _, _, _, _, _, _, icon = pcall(GetItemInfo, id)
	return (ok and icon and not IsSecret(icon)) and icon or 134400
end

function Store.ItemName(id)
	local name
	if C_Item and C_Item.GetItemNameByID then
		local ok, n = pcall(C_Item.GetItemNameByID, id)
		name = ok and n or nil
	end
	if not name and GetItemInfo then
		local ok, n = pcall(GetItemInfo, id)
		name = ok and n or nil
	end
	if IsSecret(name) then
		return nil
	end
	return name
end

function Store.ItemLink(id)
	if C_Item and C_Item.GetItemLinkByID then
		local ok, link = pcall(C_Item.GetItemLinkByID, id)
		if ok and link and not IsSecret(link) then
			return link
		end
	end
	local ok, _, link = pcall(GetItemInfo, id)
	if ok and link and not IsSecret(link) then
		return link
	end
end

function Store.ItemQuality(id)
	if C_Item and C_Item.GetItemQualityByID then
		local ok, q = pcall(C_Item.GetItemQualityByID, id)
		if ok and type(q) == "number" then
			return q
		end
	end
	local ok, _, _, q = pcall(GetItemInfo, id)
	return ok and q or 1
end

--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------

-- Who owns itemID. Returns list of { key, char, bags, bank, gear, total }
-- sorted by total descending.
function Store.OwnersOf(itemID)
	local out = {}
	if not ns.db then
		return out
	end
	for key, char in pairs(ns.db.chars) do
		local bags = char.bags and char.bags[itemID] or 0
		local bank = char.bank and char.bank[itemID] or 0
		local mail = char.mail and char.mail.items
			and char.mail.items[itemID] or 0
		local gear = 0
		if char.gear then
			for _, id in pairs(char.gear) do
				if id == itemID then
					gear = gear + 1
				end
			end
		end
		local total = bags + bank + mail + gear
		if total > 0 then
			out[#out + 1] = { key = key, char = char, bags = bags, bank = bank,
				mail = mail, gear = gear, total = total }
		end
	end
	table.sort(out, function(a, b)
		return a.total > b.total
	end)
	return out
end

-- Fulltext item search across every known char. Returns a list of
-- { id, name, icon, quality, total } sorted by total, capped at max.
-- charKey narrows the search to one character.
function Store.SearchItems(query, charKey, max)
	query = strtrim(query or ""):lower()
	max = max or 200
	if query == "" or not ns.db then
		return {}
	end
	local numeric = tonumber(query)
	local byId = {}
	for key, char in pairs(ns.db.chars) do
		if not charKey or key == charKey then
			for id, count in pairs(char.bags or {}) do
				local e = byId[id] or { total = 0 }
				e.total = e.total + count
				byId[id] = e
			end
			for id, count in pairs(char.bank or {}) do
				local e = byId[id] or { total = 0 }
				e.total = e.total + count
				byId[id] = e
			end
			for id, count in pairs(char.mail and char.mail.items or {}) do
				local e = byId[id] or { total = 0 }
				e.total = e.total + count
				byId[id] = e
			end
			if char.gear then
				for _, id in pairs(char.gear) do
					local e = byId[id] or { total = 0 }
					e.total = e.total + 1
					byId[id] = e
				end
			end
		end
	end
	local out = {}
	for id, e in pairs(byId) do
		local name = Store.ItemName(id)
		local match = numeric and id == numeric
		if not match and name and name:lower():find(query, 1, true) then
			match = true
		end
		if match then
			out[#out + 1] = { id = id, name = name, icon = Store.ItemIcon(id),
				quality = Store.ItemQuality(id), total = e.total }
		end
	end
	table.sort(out, function(a, b)
		if a.total ~= b.total then
			return a.total > b.total
		end
		return (a.name or "") < (b.name or "")
	end)
	if #out > max then
		for i = #out, max + 1, -1 do
			out[i] = nil
		end
	end
	return out
end

--------------------------------------------------------------------------------
-- Recipe ownership (captured per profession window; char.recipes[line])
--------------------------------------------------------------------------------

-- recipeID -> { id, name, icon, profs = {name,...}, owners = {charKey,...} }
function Store.RecipeOwners()
	local out = {}
	if not ns.db then
		return out
	end
	for key, char in pairs(ns.db.chars) do
		for _, prof in pairs(char.recipes or {}) do
			for id, r in pairs(prof.list or {}) do
				local e = out[id]
				if not e then
					e = { id = id, name = r.n, icon = r.i, link = r.l,
						mats = r.m, profs = {}, owners = {} }
					out[id] = e
				end
				e.owners[#e.owners + 1] = key
				if type(prof.name) == "string" then
					e.profs[prof.name] = true
				end
			end
		end
	end
	return out
end

-- Sorted prof names of an aggregated recipe entry.
function Store.RecipeProfs(entry)
	local out = {}
	for name in pairs(entry.profs or {}) do
		out[#out + 1] = name
	end
	table.sort(out)
	return out
end

--------------------------------------------------------------------------------
-- Derived queries (no API calls - stored snapshot data only)
--------------------------------------------------------------------------------

-- Stored inventory count of itemID for one character (bags + bank).
function Store.ItemCountFor(charKey, itemID)
	local char = ns.db and ns.db.chars[charKey]
	if not char then
		return 0
	end
	return (char.bags and char.bags[itemID] or 0)
		+ (char.bank and char.bank[itemID] or 0)
end

-- Could this character craft a recipe with these mats right now, based
-- on its last stored bag/bank snapshot?
function Store.CanCraftNow(charKey, mats)
	if type(mats) ~= "table" or #mats == 0 then
		return false
	end
	for _, m in ipairs(mats) do
		if Store.ItemCountFor(charKey, m.i) < (m.n or 1) then
			return false
		end
	end
	return true
end

-- Gold change over the last `days` from char.goldHist; nil when there
-- is not enough history yet. Positive = gained copper.
function Store.GoldDelta(charKey, days)
	local char = ns.db and ns.db.chars[charKey]
	local hist = char and char.goldHist
	if type(hist) ~= "table" or #hist < 2 then
		return nil
	end
	local cutoff = GetServerTime() - (days or 7) * 86400
	local base
	for _, e in ipairs(hist) do
		if (e.t or 0) <= cutoff then
			base = e.g
		else
			break
		end
	end
	base = base or hist[1].g
	local cur = tonumber(char.money) or hist[#hist].g
	if base and cur then
		return cur - base
	end
end

-- Characters whose snapshot is older than `days` (default 7), oldest
-- first. Returns { {key, char, ts}, ... }.
function Store.StaleChars(days)
	local cutoff = GetServerTime() - (days or 7) * 86400
	local out = {}
	for key, char in pairs(ns.db.chars or {}) do
		local ts = tonumber(char.updated) or 0
		if ts < cutoff then
			out[#out + 1] = { key = key, char = char, ts = ts }
		end
	end
	table.sort(out, function(a, b)
		return a.ts < b.ts
	end)
	return out
end

-- Instance checklist for the "who is NOT saved" view: every
-- name+difficulty any char is locked to -> which chars are saved.
-- Returns sorted list of { name, diff, saved = {key,...} }.
function Store.InstanceChecklist()
	local byKey = {}
	for key, char in pairs(ns.db.chars or {}) do
		for _, lo in ipairs(char.lockouts or {}) do
			local ik = tostring(lo.name) .. "|" .. tostring(lo.difficulty or "")
			local e = byKey[ik]
			if not e then
				e = { name = lo.name or ik, diff = lo.difficulty, saved = {} }
				byKey[ik] = e
			end
			e.saved[key] = true
		end
	end
	local out = {}
	for _, e in pairs(byKey) do
		out[#out + 1] = e
	end
	table.sort(out, function(a, b)
		return (a.name or "") < (b.name or "")
	end)
	return out
end

-- Seconds until a character is fully rested (150% bubble), or nil when
-- already full / no data. Rested accrues one 5%-of-level bubble per
-- 8 hours offline.
function Store.RestedSeconds(s)
	if type(s) ~= "table" or type(s.rested) ~= "number"
		or type(s.xpMax) ~= "number" or s.xpMax <= 0 or s.maxLevel then
		return nil
	end
	local missing = 1.5 * s.xpMax - s.rested
	if missing <= 0 then
		return 0
	end
	return math.floor(missing / s.xpMax / 0.05 * 28800)
end

-- Stored profession cooldowns of one char: list of { n = name,
-- x = expiry server-time }. Expired entries are dropped.
function Store.ProfCooldowns(charKey)
	local char = ns.db and ns.db.chars[charKey]
	local now = GetServerTime()
	local out = {}
	for _, prof in pairs(char and char.recipes or {}) do
		for _, cd in ipairs(prof.cds or {}) do
			if cd.x and cd.x > now then
				out[#out + 1] = cd
			end
		end
	end
	table.sort(out, function(a, b)
		return (a.x or 0) < (b.x or 0)
	end)
	return out
end
