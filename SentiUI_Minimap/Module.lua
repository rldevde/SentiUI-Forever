-- Registration with the SentiUI core. The module's pages appear as their own
-- "Minimap" section in the settings; settings land in SentiUIDB.modules.Minimap.
local _, ns = ...

SentiUI:RegisterModule("Minimap", {
	label = "Minimap",
	order = 100,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod) ns.Core.Enable(mod) end,
	OnSettingChanged = function(mod, path) ns.Core.SettingChanged(mod, path) end,
})

-- installer step: minimap shape and size, applied live through the
-- module's own setting path
do
	local S = SentiUI
	local Inst = S.Installer
	if Inst and Inst.AddModuleStep then
		Inst.AddModuleStep({
			title = "Minimap",
			text = ns.L["Pick the minimap's shape and size. Changes apply immediately."],
			build = function(host)
				-- no enabled-guard: an empty step is worse than controls
				-- that write settings a disabled module picks up later
				local f = CreateFrame("Frame", nil, host)
				f:SetAllPoints()
				local lab = S.Font(f, 11)
				lab:SetPoint("TOPLEFT", 0, -2)
				lab:SetText(ns.L["Shape"])
				local dd = S.Widgets.Dropdown(f, 130)
				dd:SetPoint("LEFT", lab, "RIGHT", 10, 0)
				dd:SetOptions(
					{ square = ns.L["Square"], round = ns.L["Round"] },
					{ "square", "round" })
				dd:SetValue(S:Get("Minimap", "shape") or "square")
				dd.onPick = function(k) S:Set("Minimap", "shape", k) end
				local lab2 = S.Font(f, 11)
				lab2:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -14)
				lab2:SetText(ns.L["Size"])
				local val = S.Font(f, 11, S.colors.accent)
				val:SetPoint("LEFT", lab2, "RIGHT", 10, 0)
				local sl = S.Widgets.Slider(f, 140, 320, 2)
				sl:SetPoint("TOPLEFT", lab2, "BOTTOMLEFT", 0, -8)
				sl:SetWidth(250)
				local cur = tonumber(S:Get("Minimap", "size")) or 190
				sl:SetValue(cur, true)
				val:SetText(string.format("%d px", cur))
				sl.onChanged = function(v, final)
					val:SetText(string.format("%d px", v))
					if final then S:Set("Minimap", "size", v) end
				end
				return f
			end,
		})
	end
end
