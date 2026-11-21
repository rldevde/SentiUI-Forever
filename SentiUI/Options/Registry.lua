-- Options registry. Sections and pages are plain data; the window draws
-- whatever is registered, so a module adds its own pages without touching
-- window code.
--
-- Page:  { id, section, label, desc?, scope, defaults, groups, order?, hidden? }
--        groups may be a table or a function returning one (dynamic pages).
-- Group: a card { label, desc?, items }
-- Items:
--   toggle   { key, label }
--   slider   { key, label, min, max, step?, unit? ("%", "px" or "x") }
--   dropdown { key, label, values = { key = text }, order? }   or choices() -> values, order
--   button   { label, text?, func, confirm? }
--   text     { label }                          label may be a function
--   color    { key, label, alpha? }             the value is { r, g, b(, a) }
--   custom   { label?, build(row), update?(row), height? }   draws its own row
-- Any item may have:
--   desc            hover text
--   disabled(get), hidden(get)   get(key) reads another setting in the scope
--   get()/set(v)    read/write somewhere else instead of key
--   default()       the value a reset writes (with get/set)
--   invert = true   a toggle shows its value flipped
--   reload = true   a change asks for a UI reload
--   noSearch = true keep the row out of search
local _, S = ...
local L = S.L

local Options = {}
S.Options = Options

local sections, pages = {}, {}

local KNOWN = { toggle = true, slider = true, dropdown = true, color = true, button = true, text = true, custom = true }
local VALUE = { toggle = true, slider = true, dropdown = true, color = true }
Options.VALUE = VALUE

-- Item tables hold English text and get translated only when drawn.
function Options.Text(s)
	if type(s) == "string" then return L[s] end
	return s
end

-- ---------------------------------------------------------------------
-- Sections and pages
-- ---------------------------------------------------------------------

function Options.RegisterSection(id, label, order)
	if not sections[id] then
		sections[id] = { id = id, label = label, order = order or 100, pages = {} }
	end
	return sections[id]
end

local function validate(page)
	if type(page.groups) == "function" then return end
	for gi, group in ipairs(page.groups or {}) do
		for i, item in ipairs(group.items or {}) do
			local where = tostring(page.id) .. "[" .. gi .. "." .. i .. "]"
			if not KNOWN[item.type] then
				S.Print(string.format(L["Options (%s): unknown item type %s"], where, tostring(item.type)))
			elseif item.label == nil and item.type ~= "custom" then
				S.Print(string.format(L["Options (%s): item without label"], where))
			elseif VALUE[item.type] and not item.get and type(item.key) ~= "string" then
				S.Print(string.format(L["Options (%s): %s needs a key or get/set"], where, tostring(item.type)))
			elseif item.type == "slider" and (type(item.min) ~= "number" or type(item.max) ~= "number" or item.min >= item.max) then
				S.Print(string.format(L["Options (%s): slider with a bad range"], where))
			end
		end
	end
end

function Options.RegisterPage(page)
	assert(not pages[page.id], "options page already registered: " .. tostring(page.id))
	local section = assert(sections[page.section], "unknown options section: " .. tostring(page.section))
	validate(page)
	page.order = page.order or (#section.pages + 1) * 10
	pages[page.id] = page
	section.pages[#section.pages + 1] = page
	table.sort(section.pages, function(a, b) return a.order < b.order end)
	S.Fire("OptionsChanged")
	return page
end

local function pageShown(page)
	return page.hidden == nil or page.hidden(Options.Getter(page)) ~= true
end

function Options.GetPage(id)
	local page = pages[id]
	if page and pageShown(page) then return page end
end

-- A page's groups, resolving a function for dynamic pages.
function Options.Groups(page)
	if type(page.groups) == "function" then
		local ok, g = pcall(page.groups)
		return (ok and type(g) == "table") and g or {}
	end
	return page.groups or {}
end

-- Sections in window order, each holding its shown pages in order.
function Options.Sections()
	local list = {}
	for _, s in pairs(sections) do
		local shown = {}
		for _, p in ipairs(s.pages) do
			if pageShown(p) then shown[#shown + 1] = p end
		end
		if #shown > 0 then
			list[#list + 1] = setmetatable({ pages = shown }, { __index = s })
		end
	end
	table.sort(list, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.id < b.id
	end)
	return list
end

function Options.Pages()
	local list = {}
	for _, s in ipairs(Options.Sections()) do
		for _, p in ipairs(s.pages) do list[#list + 1] = p end
	end
	local i = 0
	return function()
		i = i + 1
		local p = list[i]
		if p then return p.id, p end
	end
end

-- A module's options: { pages = { { id, label, desc?, groups } } }.
-- They get a section named after the module, with the module as scope.
-- mod.section files the pages under another section instead.
function Options.RegisterModule(mod)
	local section = mod.section or mod.name
	if not mod.section then Options.RegisterSection(mod.name, mod.label or mod.name, mod.order or 100) end
	for i, p in ipairs(mod.options.pages or {}) do
		Options.RegisterPage({
			id = mod.name .. "." .. tostring(p.id),
			section = section,
			label = p.label, desc = p.desc,
			order = (mod.pageOrder or 0) + i * 10,
			scope = mod.name, defaults = mod.defaults or {},
			groups = p.groups, hidden = p.hidden, onShow = p.onShow,
		})
	end
end

-- ---------------------------------------------------------------------
-- Values, defaults, state
-- ---------------------------------------------------------------------

-- One cached reader per page: get(key) reads a setting in the page's scope.
local getters = setmetatable({}, { __mode = "k" })
function Options.Getter(page)
	local g = getters[page]
	if not g then
		g = function(key) return S:Get(page.scope, key) end
		getters[page] = g
	end
	return g
end

local function saved(page, item)
	if item.get then return item.get() end
	return S:Get(page.scope, item.key)
end

function Options.Get(page, item)
	local v = saved(page, item)
	if item.invert then return v ~= true end
	return v
end

local function askReload()
	StaticPopup_Show("SENTIUI_RELOAD")
end

function Options.Set(page, item, value)
	if Options.IsDisabled(page, item) then return false end
	if item.invert then value = value ~= true end
	local before = item.reload and saved(page, item)
	local ok
	if item.set then
		ok = item.set(value) ~= false
	else
		ok = S:Set(page.scope, item.key, value)
	end
	if ok and item.reload and before ~= value then askReload() end
	return ok
end

function Options.Default(page, item)
	local d
	if item.get then
		d = item.default and item.default()
	else
		d = S.DB.GetPath(page.defaults or {}, item.key or "")
	end
	if item.invert and d ~= nil then return d ~= true end
	return d
end

local function sameRGB(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for i = 1, 3 do
		if type(a[i]) ~= "number" or type(b[i]) ~= "number" or math.abs(a[i] - b[i]) > 1e-3 then return false end
	end
	return true
end

function Options.IsDefault(page, item)
	if not VALUE[item.type] or (item.get and not item.default) then return true end
	local v, d = Options.Get(page, item), Options.Default(page, item)
	if type(v) == "number" and type(d) == "number" then return math.abs(v - d) < 1e-6 end
	if type(v) == "table" and type(d) == "table" then return sameRGB(v, d) end
	return v == d
end

function Options.ResetItem(page, item)
	if Options.IsDisabled(page, item) or Options.IsDefault(page, item) then return end
	local d = Options.Default(page, item)
	if type(d) == "table" then d = S.DB.Copy(d) end
	Options.Set(page, item, d)
end

function Options.ResetPage(page)
	for _, group in ipairs(Options.Groups(page)) do
		for _, item in ipairs(group.items or {}) do Options.ResetItem(page, item) end
	end
end

function Options.IsDisabled(page, item)
	return item.disabled ~= nil and item.disabled(Options.Getter(page)) == true
end

function Options.IsHidden(page, item)
	return item.hidden ~= nil and item.hidden(Options.Getter(page)) == true
end

-- An item's displayed label, resolving label functions.
function Options.Label(item)
	local label = item.label
	if type(label) == "function" then
		local ok, s = pcall(label)
		label = ok and s or ""
	end
	return Options.Text(label)
end

-- ---------------------------------------------------------------------
-- Search
-- ---------------------------------------------------------------------

-- Matches both the translated text and the English, since guides use English.
local function has(text, query)
	if type(text) ~= "string" then return false end
	if string.find(string.lower(text), query, 1, true) ~= nil then return true end
	local shown = L[text]
	return shown ~= text and string.find(string.lower(shown), query, 1, true) ~= nil
end

function Options.Matches(page, group, item, query)
	if query == nil or query == "" then return true end
	if item.type == "text" or item.type == "custom" or item.noSearch then return false end
	query = string.lower(query)
	return has(item.label, query) or has(item.desc, query) or has(item.text, query)
		or (group and has(group.label, query))
		or (page and has(page.label, query))
end

StaticPopupDialogs["SENTIUI_RELOAD"] = {
	text = L["This change needs a reload to take effect. Reload now?"],
	button1 = L["Reload"],
	button2 = L["Later"],
	OnAccept = function() (C_UI and C_UI.Reload or ReloadUI)() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
