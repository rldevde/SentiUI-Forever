local _, ns = ...
local S = SentiUI
local L = ns.L

S.Compendium = ns.Journal

SentiUI:RegisterModule("Journal", {
	label = L["Dungeon Journal"],
	order = 50,
	defaults = ns.DEFAULTS,
	changelog = ns.CHANGELOG,
	options = {},
	OnEnable = function() end,
})

SLASH_SENTIUIJOURNAL1 = "/suij"
SlashCmdList.SENTIUIJOURNAL = function() ns.Journal.Toggle() end
