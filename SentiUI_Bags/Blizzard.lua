-- Blizzard bag replacement: the game's container frames get REPARENTED
-- under a hidden holder instead of being hidden. This is deliberate -
-- frames under a hidden parent are invisible to the player but keep
-- their own shown state, so IsAnyBagOpen()/IsBagOpen() stay truthful,
-- the game's open/close bookkeeping and its bag events keep working and
-- every open/close/toggle call still reaches the hooks below.
-- Alpha-ghosting them instead made the client flap the state open and
-- closed in a loop; hiding the frames directly breaks the bookkeeping
-- and is what made the bag key feel dead.
local _, ns = ...
local S = SentiUI

local Blizzard = {}
ns.Blizzard = Blizzard

local hidden = CreateFrame("Frame")
hidden:Hide()
-- Blizzard scripts call layout methods on GetParent() - stub them
hidden.Layout = function() end
hidden.MarkDirty = function() end
hidden.SetNeedsLayout = function() end
hidden.UpdateLayout = function() end
hidden.IsLayoutFrame = function() return false end

local function Park(name)
	local f = _G[name]
	if type(f) == "table" and f.SetParent then
		pcall(f.SetParent, f, hidden)
	end
end

local function Apply()
	Park("ContainerFrameCombinedBags")
	Park("BankFrame")
	for i = 1, (type(NUM_CONTAINER_FRAMES) == "number" and NUM_CONTAINER_FRAMES) or 13 do
		Park("ContainerFrame" .. i)
	end
end

-- Closes the game's bags by hiding their container frames, the same way
-- their own close buttons do. Never call CloseAllBags from addon code:
-- it writes the client's who-opened bookkeeping, which the client reads
-- back inside the same call chain - a tainted write there breaks every
-- follow-up protected call.
function Blizzard.CloseGame()
	for i = 1, (type(NUM_CONTAINER_FRAMES) == "number" and NUM_CONTAINER_FRAMES) or 13 do
		local f = _G["ContainerFrame" .. i]
		if f and f:IsShown() then pcall(f.Hide, f) end
	end
	local cb = _G.ContainerFrameCombinedBags
	if cb and cb:IsShown() then pcall(cb.Hide, cb) end
end

function Blizzard.Enable()
	Apply()
	-- every bag function goes through the same sync: the game settles
	-- its own open/closed state first, then we mirror it onto our window.
	-- The hook itself only flags: post-hooks run inside the client's
	-- keypress dispatch (B key, bag buttons), and running our Lua there
	-- taints the client's follow-up protected calls.
	local dirty = false
	local function Sync() dirty = true end
	C_Timer.NewTicker(0.05, function()
		if dirty then
			dirty = false
			S.SafeCall("bags:sync", ns.Core.Sync)
		end
	end)
	local hooks = {
		ToggleBag = Sync, ToggleAllBags = Sync, ToggleBackpack = Sync,
		OpenAllBags = Sync, OpenBackpack = Sync, OpenBag = Sync,
		CloseAllBags = Sync, CloseBackpack = Sync,
	}
	local hooked = {}
	local function Install()
		for name, fn in pairs(hooks) do
			if not hooked[name] and type(_G[name]) == "function" then
				hooksecurefunc(name, fn)
				hooked[name] = true
			end
		end
	end
	Install()
	-- the container frames / globals can appear later (load-on-demand
	-- FrameXML): re-check whenever another addon or frame pack loads
	S.RegisterEvent("ADDON_LOADED", function()
		Apply()
		Install()
	end)
end
