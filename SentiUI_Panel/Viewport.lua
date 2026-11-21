-- Viewport ("Adjust UI"): shrinks UIParent inside WorldFrame so Blizzard's
-- managed frames stay clear of the bars, like Titan Panel's screen
-- adjustment. The 3D world still renders fullscreen behind the bars.
--
-- UIParent and WorldFrame are PROTECTED frames on this client - calling
-- methods on them from addon code is forbidden (ADDON_ACTION_FORBIDDEN).
-- The native way to reposition protected frames is the restricted
-- environment: SecureHandlerExecute + SetFrameRef.
local _, ns = ...
local S = SentiUI
local L = ns.L

local PAD = 2

local Viewport = {}
ns.Viewport = Viewport

-- space each enabled+adjusting bar reserves on its edge
function Viewport.Offsets()
	local top, bottom = 0, 0
	local t = ns.db.bars.top
	if t.enabled and t.adjustUI then top = t.margin + t.height + PAD end
	local b = ns.db.bars.bottom
	if b.enabled and b.adjustUI then bottom = b.margin + b.height + PAD end
	return top, bottom
end

local function EnsureSecure()
	if Viewport.secure then return Viewport.secure end
	if not SecureHandlerExecute then return nil end
	local h = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
	h:SetFrameRef("uip", UIParent)
	h:SetFrameRef("wf", WorldFrame)
	Viewport.secure = h
	return h
end

function Viewport.Apply()
	S.RunOutOfCombat(function()
		local top, bottom = Viewport.Offsets()
		local h = EnsureSecure()
		if not h then
			if not Viewport.warned then
				Viewport.warned = true
				S.Print("|cffffcc33" .. L["Adjust UI:"] .. "|r " .. L["restricted environment unavailable - bars overlay the UI"])
			end
			return
		end
		h:SetAttribute("topOff", top)
		h:SetAttribute("botOff", bottom)
		SecureHandlerExecute(h, [[
			local u, w = self:GetFrameRef("uip"), self:GetFrameRef("wf")
			u:ClearAllPoints()
			u:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -(self:GetAttribute("topOff") or 0))
			u:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", 0, self:GetAttribute("botOff") or 0)
		]])
	end)
end

function Viewport.Initialize()
	C_Timer.After(0, function() Viewport.Apply() end)
	for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
		ns.RegisterBusEvent(ev, function() Viewport.Apply() end)
	end
end
