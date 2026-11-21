-- Registration with the SentiUI core. The capture engine in Core.lua
-- installs at file load so it also catches errors that fire before the
-- module's enable pass; OnEnable only hands the module (and its db) over.
local _, ns = ...

SentiUI:RegisterModule("BugSack", {
	label = "BugSack",
	order = 170,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod) ns.mod = mod end,
})
