-- Module locales: English keys, other locales fill the same table.
local _, ns = ...

local L = {}
setmetatable(L, { __index = function(_, k) return k end })
ns.L = L
