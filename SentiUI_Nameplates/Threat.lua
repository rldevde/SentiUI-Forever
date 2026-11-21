-- Threat state per plate: where you stand on a mob and whether you are the
-- tank. Reads stay on plain values only - against bosses the numbers can be
-- secret (drawable, never comparable), and those never reach a comparison.
--
-- UnitThreatSituation: 0 not tanking below the tank, 1 not tanking above
-- (about to pull), 2 tanking but losing it, 3 tanking securely.
local _, ns = ...
local S = SentiUI

local Threat = {}
ns.Threat = Threat

local function plain(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, v = pcall(fn, ...)
	if not ok or S.IsSecret(v) then return nil end
	return v
end

-- "onyou" | "warn" | "below" | nil
-- Every read runs inside one pcall: status/pct can come back as a "secret
-- number" that type() still reports as "number" and issecretvalue does not
-- flag - only the comparison itself throws, so the compare IS the check.
function Threat.State(unit)
	if type(UnitThreatSituation) ~= "function" then return nil end
	local status = plain(UnitThreatSituation, "player", unit)
	if type(status) ~= "number" then return nil end
	local ok, state = pcall(function()
		if status >= 2 then return "onyou" end
		if status == 1 then return "warn" end
		local _, _, pct = UnitDetailedThreatSituation("player", unit)
		if pct and pct >= 80 then return "warn" end
		return "below"
	end)
	if ok then return state end
	return nil
end

-- is someone else a possible holder: grouped or a pet out. Solo every mob is
-- on you anyway, so threat colors would only ever repeat "onyou".
local function Shared()
	return IsInGroup() == true or plain(UnitExists, "pet") == true
end
Threat.Shared = Shared

local tankCache
local function readTank()
	if plain(UnitGroupRolesAssigned, "player") == "TANK" then return true end
	if GetSpecialization and GetSpecializationRole then
		local spec = plain(GetSpecialization)
		if spec then return plain(GetSpecializationRole, spec) == "TANK" end
	end
	return false
end
function Threat.IsTank()
	local mode = ns.Cfg() and ns.Cfg().threatRole or "auto"
	if mode == "tank" then return true end
	if mode == "dps" then return false end
	if tankCache == nil then tankCache = readTank() end
	return tankCache
end
function Threat.Forget() tankCache = nil end

-- fill color key from the active role's view:
-- tank -> onyou good / warn warn / below-or-lost bad
-- dps  -> onyou bad / warn warn / below good
function Threat.ColorKey(state)
	local inCombat = InCombatLockdown() == true
	if Threat.IsTank() then
		if state == "onyou" then return "good" end
		if state == "warn" then return "warn" end
		if state == "below" or (state == nil and inCombat and Shared()) then
			return "bad"
		end
	else
		if state == "onyou" then return "bad" end
		if state == "warn" then return "warn" end
		if state == "below" then return "good" end
	end
	return nil
end
