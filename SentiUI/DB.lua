-- SentiUIDB with defaults merged in and dotted-path access.
-- Layout: { general = {...}, modules = { [name] = {...} }, positions = { [key] = {x,y} } }
local _, S = ...

local DB = {}
S.DB = DB

DB.GENERAL_DEFAULTS = {
	minimap = {
		hide = false,   -- hide the SentiUI minimap button
		angle = 220,    -- position around the minimap, degrees
	},
	gridSnap = true,    -- move mode: snap frames to the grid
	gridSize = 24,      -- move mode: grid spacing, px
	magnet = true,      -- move mode: snap to other frames' edges and centers
	uiScale = 1,        -- master scale for SentiUI frames
	frameScales = {},   -- [mover key] = one frame's own scale, wheel on its handle
	testFrame = false,  -- show the sample frame to try move mode with
	installDone = false, -- the first-run wizard was completed or skipped
	afkOverlay = true,  -- dim the screen + info card while AFK
}

local function copyValue(v)
	if type(v) ~= "table" then return v end
	local t = {}
	for k, x in pairs(v) do t[k] = copyValue(x) end
	return t
end
DB.Copy = copyValue

-- Fills missing values in dest from defaults. List-style defaults ({ ... })
-- are taken as a whole; dictionary defaults merge key by key.
function DB.Merge(dest, defaults)
	for k, v in pairs(defaults) do
		if type(v) == "table" and v[1] == nil and type(dest[k]) == "table" then
			DB.Merge(dest[k], v)
		elseif dest[k] == nil then
			dest[k] = copyValue(v)
		end
	end
	return dest
end

function DB.GetPath(t, path)
	if type(path) ~= "string" then return nil end
	for part in string.gmatch(path, "[^%.]+") do
		if type(t) ~= "table" then return nil end
		t = t[part]
	end
	return t
end

function DB.SetPath(t, path, value)
	if type(path) ~= "string" then return end
	local parts = {}
	for part in string.gmatch(path, "[^%.]+") do parts[#parts + 1] = part end
	if #parts == 0 then return end
	for i = 1, #parts - 1 do
		local p = parts[i]
		if type(t[p]) ~= "table" then t[p] = {} end
		t = t[p]
	end
	t[parts[#parts]] = value
end

function DB.Init()
	SentiUIDB = type(SentiUIDB) == "table" and SentiUIDB or {}
	SentiUIDB.general = DB.Merge(type(SentiUIDB.general) == "table" and SentiUIDB.general or {}, DB.GENERAL_DEFAULTS)
	if type(SentiUIDB.modules) ~= "table" then SentiUIDB.modules = {} end
	if type(SentiUIDB.positions) ~= "table" then SentiUIDB.positions = {} end
end

function DB.General() return SentiUIDB.general end
function DB.Positions() return SentiUIDB.positions end

-- A module's settings table, defaults merged in.
function DB.Module(name, defaults)
	local m = SentiUIDB.modules
	m[name] = DB.Merge(type(m[name]) == "table" and m[name] or {}, defaults or {})
	return m[name]
end

-- Saved variables are already loaded when the files run, so init now: a
-- SentiUI_* addon may register a mover at its own file load, before login.
DB.Init()
