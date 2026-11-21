-- Parks Blizzard's own unit frames on a hidden container so they never
-- render, while our secure buttons take over. Frame names follow the
-- Camelot client (modern frame layout).
local _, ns = ...
local S = SentiUI
local Plain = ns.Plain

local CreateFrame = CreateFrame
local pairs = pairs

local B = {}
ns.Blizzard = B

local hidden = CreateFrame("Frame")
hidden:Hide()
-- Blizzard scripts call layout methods on GetParent() - stub them
hidden.Layout = function() end
hidden.MarkDirty = function() end
hidden.SetNeedsLayout = function() end
hidden.UpdateLayout = function() end
hidden.IsLayoutFrame = function() return false end
hidden:SetSize(1, 1)
hidden:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -500, -500)

local function Park(f)
	if not f then return end
	pcall(function()
		f:UnregisterAllEvents()
		f:Hide()
		f:SetParent(hidden)
		-- keep it quiet even if Blizzard re-shows it
		if f.SetScript then
			f:SetScript("OnShow", f.Hide)
		end
	end)
end

local LISTS = {
	player = function()
		Park(PlayerFrame)
		Park(PetFrame)
		Park(RuneFrame)
		Park(TotemFrame)
		Park(ComboFrame)
		Park(ComboPointPlayerFrame)
		Park(PlayerPowerBarAlt)
		if PlayerCastingBarFrame then Park(PlayerCastingBarFrame) end
	end,
	target = function()
		Park(TargetFrame)
		Park(TargetFrameToT)
		Park(TargetFrameSpellBar)
	end,
	pet = function()
		Park(PetFrame)
	end,
	focus = function()
		Park(FocusFrame)
		Park(FocusFrameToT)
	end,
	party = function()
		if PartyFrame then
			Park(PartyFrame)
			if PartyFrame.PartyMemberFramePool then
				for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do Park(frame) end
			end
		end
		for i = 1, 4 do Park(_G["PartyMemberFrame" .. i]) end
		Park(CompactPartyFrame)
		Park(PartyMemberBackground)
	end,
	raid = function()
		if CompactRaidFrameManager_SetSetting then
			pcall(CompactRaidFrameManager_SetSetting, "IsShown", "0")
		end
		Park(CompactRaidFrameManager)
		Park(CompactRaidFrameContainer)
	end,
	castbar = function()
		Park(CastingBarFrame)
		Park(PlayerCastingBarFrame)
		Park(PetCastingBarFrame)
	end,
	boss = function()
		Park(BossTargetFrameContainer)
		Park(BossTargetFrame)
		Park(ArenaEnemyFrames)
		Park(ArenaEnemyMatchFramesContainer)
		Park(CompactArenaFrame)
	end,
}

function B.Apply()
	local db = ns.db.hideBlizzard or {}
	for key, fn in pairs(LISTS) do
		if db[key] then S.SafeCall("uf:hide:" .. key, fn) end
	end
end
