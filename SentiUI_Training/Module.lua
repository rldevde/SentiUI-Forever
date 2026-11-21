-- Registration with the SentiUI core: the trainers window lives behind
-- the panel plugin and /suitr; the service and data tables are loaded at
-- file scope, so enabling is only about handing the module its db.
local _, ns = ...

SentiUI:RegisterModule("Training", {
	label = ns.L["Trainers"],
	order = 135,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod) ns.mod = mod end,
})

SLASH_SUITRAINING1 = "/suitr"
SlashCmdList.SUITRAINING = function()
	if SentiUITraining then SentiUITraining.Toggle() end
end
