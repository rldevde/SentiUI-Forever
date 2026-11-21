-- luacheck: read globals CreateFrame GetTime IsInInstance SetPortraitTextureFromCreatureDisplayID C_Timer
local _, ns = ...

-- Boss portraits for the compendium. Order of sources: explicit icon,
-- display id (bundled 2D picture first, live model portrait otherwise),
-- npc id -> display id table, and finally a hidden model that asks the
-- client which display an npc uses (queued, one at a time, never while a
-- loading screen is up or inside an instance).
local BP = {}
ns.BossPortrait = BP

local PATH = "Interface\\AddOns\\SentiUI_Journal\\Media\\Portraits\\"
local listeners = {}
local queue, queued, tries = {}, {}, {}
local current
local resumeAt = 0
local zoning = false

function BP.OnResolved(fn)
	listeners[#listeners + 1] = fn
end

local function Cache()
	if not ns.db then
		return {}
	end
	ns.db.portraitDisplay = ns.db.portraitDisplay or {}
	return ns.db.portraitDisplay
end

local function Paused()
	if zoning or (GetTime() < resumeAt) then
		return true
	end
	if IsInInstance then
		local ok, inside = pcall(IsInInstance)
		if ok and inside then
			return true
		end
	end
	return false
end

local function Display(tex, displayID)
	if type(displayID) ~= "number" or displayID <= 0 then
		return false
	end
	if ns.BAKED_PORTRAITS and ns.BAKED_PORTRAITS[displayID] then
		tex:SetTexture(PATH .. displayID)
		return true
	end
	if SetPortraitTextureFromCreatureDisplayID then
		local ok = pcall(SetPortraitTextureFromCreatureDisplayID, tex, displayID)
		return ok
	end
	return false
end

local resolver = CreateFrame("Frame")
local models = {}

local function Finish(request, displayID)
	if current ~= request then
		return
	end
	local npcID = request.npcID
	if type(displayID) == "number" and displayID > 0 then
		Cache()[npcID] = displayID
		tries[npcID] = nil
	else
		tries[npcID] = (tries[npcID] or 0) + 1
		if tries[npcID] < 5 and C_Timer and C_Timer.After then
			C_Timer.After(2.05, function()
				BP.Queue(npcID)
			end)
		end
	end
	request.model:SetScript("OnModelLoaded", nil)
	if request.model.ClearModel then
		pcall(request.model.ClearModel, request.model)
	end
	request.model:Hide()
	queued[npcID] = nil
	current = nil
	for _, fn in ipairs(listeners) do
		pcall(fn, npcID, displayID)
	end
end

local function StartNext()
	if current or Paused() then
		return
	end
	local npcID = table.remove(queue, 1)
	if not npcID then
		return
	end
	local model = models[npcID]
	if not model then
		model = CreateFrame("PlayerModel", nil, UIParent)
		model:SetSize(1, 1)
		model:SetPoint("CENTER")
		model:SetAlpha(0)
		models[npcID] = model
	end
	local request = { npcID = npcID, model = model, elapsed = 0 }
	current = request
	model:SetScript("OnModelLoaded", nil)
	model:Show()
	if model.ClearModel then
		pcall(model.ClearModel, model)
	end
	local ok, prev = pcall(model.GetDisplayInfo, model)
	request.previousID = ok and prev or nil
	model:SetScript("OnModelLoaded", function()
		if current == request then
			request.loaded = true
		end
	end)
	if not pcall(model.SetCreature, model, npcID) then
		request.failed = true
	end
end

resolver:SetScript("OnUpdate", function(self, elapsed)
	if not current then
		if #queue == 0 then
			self:Hide()
			return
		end
		StartNext()
		return
	end
	local request = current
	request.elapsed = request.elapsed + elapsed
	if request.failed then
		Finish(request, nil)
		return
	end
	if request.loaded or request.elapsed >= 0.10 then
		local ok, id = pcall(request.model.GetDisplayInfo, request.model)
		if ok and type(id) == "number" and id > 0 and (request.loaded or id ~= request.previousID) then
			Finish(request, id)
			return
		end
	end
	if request.elapsed >= 3.0 then
		Finish(request, nil)
	end
end)
resolver:Hide()

function BP.Queue(npcID)
	if not npcID or queued[npcID] or Cache()[npcID] then
		return
	end
	queued[npcID] = true
	queue[#queue + 1] = npcID
	resolver:Show()
end

-- loading screens: pause lookups, resume a few seconds after arriving
local ev = CreateFrame("Frame")
for _, e in ipairs({ "LOADING_SCREEN_ENABLED", "LOADING_SCREEN_DISABLED", "PLAYER_ENTERING_WORLD" }) do
	pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event)
	if event == "LOADING_SCREEN_ENABLED" then
		zoning = true
		if current then
			local request = current
			current = nil
			request.model:SetScript("OnModelLoaded", nil)
			request.model:Hide()
			queued[request.npcID] = nil
			table.insert(queue, 1, request.npcID)
			queued[request.npcID] = true
		end
	else
		zoning = false
		resumeAt = GetTime() + 5
	end
end)

-- Fills `tex` with the boss picture; false when none is available (yet).
function BP.Set(tex, boss)
	tex:SetTexture(nil)
	tex:SetTexCoord(0, 1, 0, 1)
	tex:SetAlpha(1)
	if not boss then
		return false
	end
	if boss.customIcon then
		tex:SetTexture(boss.customIcon)
		return true
	end
	if Display(tex, boss.displayID) then
		return true
	end
	local npc = boss.npcID or boss.portraitNpcID
	if npc then
		local id = (ns.STATIC_DISPLAY_IDS and ns.STATIC_DISPLAY_IDS[npc]) or Cache()[npc]
		if Display(tex, id) then
			return true
		end
		BP.Queue(npc)
	end
	return false
end
