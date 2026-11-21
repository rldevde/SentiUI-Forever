-- SentiUI locales. Keys are English; missing translations fall back to the key.
local _, S = ...

local L = setmetatable({}, { __index = function(t, k) rawset(t, k, k) return k end })
S.L = L
