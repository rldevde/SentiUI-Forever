-- Registration with the SentiUI core. The module's pages appear as their own
-- "Chat" section in the settings; settings land in SentiUIDB.modules.Chat.
local _, ns = ...

SentiUI:RegisterModule("Chat", {
	label = ns.L["Chat"],
	order = 110,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		ns.Core.Enable(mod)
	end,
	OnSettingChanged = function(mod, path) ns.Core.SettingChanged(mod, path) end,
})

-- installer step: chat setup like the other UI suites do it - font sizes,
-- panels and the loot window, applied live through the module's own
-- setting path (S:Set fires OnSettingChanged, so nothing needs a reload)
do
	local S = SentiUI
	local Inst = S.Installer
	if Inst and Inst.AddModuleStep then
		Inst.AddModuleStep({
			title = "Chat",
			text = ns.L["Set the chat font size and the panels. Every chat window (general, loot, whispers ...) follows the same size."],
			build = function(host)
				-- no enabled-guard: an empty step is worse than controls
				-- that write settings a disabled module picks up later
				local f = CreateFrame("Frame", nil, host)
				f:SetAllPoints()

				-- left column: the two font sizes
				local lab = S.Font(f, 11)
				lab:SetPoint("TOPLEFT", 0, -2)
				lab:SetText(ns.L["Font size"])
				local val = S.Font(f, 11, S.colors.accent)
				val:SetPoint("LEFT", lab, "RIGHT", 10, 0)
				local sl = S.Widgets.Slider(f, 8, 24, 1)
				sl:SetPoint("TOPLEFT", lab, "BOTTOMLEFT", 0, -8)
				sl:SetWidth(250)
				local cur = tonumber(S:Get("Chat", "fontSize")) or 12
				sl:SetValue(cur, true)
				val:SetText(string.format("%d px", cur))
				sl.onChanged = function(v, final)
					val:SetText(string.format("%d px", v))
					-- applying rebuilds every chat line: only on release,
					-- not on every drag tick
					if final then S:Set("Chat", "fontSize", v) end
				end

				local lab2 = S.Font(f, 11)
				lab2:SetPoint("TOPLEFT", sl, "BOTTOMLEFT", 0, -14)
				lab2:SetText(ns.L["Tab font size"])
				local val2 = S.Font(f, 11, S.colors.accent)
				val2:SetPoint("LEFT", lab2, "RIGHT", 10, 0)
				local sl2 = S.Widgets.Slider(f, 8, 20, 1)
				sl2:SetPoint("TOPLEFT", lab2, "BOTTOMLEFT", 0, -8)
				sl2:SetWidth(250)
				local cur2 = tonumber(S:Get("Chat", "tabFontSize")) or 11
				sl2:SetValue(cur2, true)
				val2:SetText(string.format("%d px", cur2))
				sl2.onChanged = function(v, final)
					val2:SetText(string.format("%d px", v))
					if final then S:Set("Chat", "tabFontSize", v) end
				end

				-- right column: loot window + panels
				local cb = S.Widgets.Check(f)
				cb:SetPoint("TOPLEFT", 270, -2)
				cb:SetChecked(S:Get("Chat", "lootChat") == true)
				local cblab = S.Font(f, 11)
				cblab:SetPoint("LEFT", cb, "RIGHT", 6, 0)
				cblab:SetText(ns.L["Loot chat window"])
				cb.onChanged = function(v) S:Set("Chat", "lootChat", v) end

				local ddlab = S.Font(f, 11)
				ddlab:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -14)
				ddlab:SetText(ns.L["Panels"])
				local dd = S.Widgets.Dropdown(f, 130)
				dd:SetPoint("LEFT", ddlab, "RIGHT", 10, 0)
				dd:SetOptions({
					SHOWBOTH = ns.L["Both"], LEFT = ns.L["Left only"],
					RIGHT = ns.L["Right only"], HIDEBOTH = ns.L["Hidden"],
				}, { "SHOWBOTH", "LEFT", "RIGHT", "HIDEBOTH" })
				dd:SetValue(S:Get("Chat", "panelBackdrop") or "SHOWBOTH")
				dd.onPick = function(k) S:Set("Chat", "panelBackdrop", k) end

				local note = S.Font(f, 10, S.colors.textDim)
				note:SetPoint("TOPLEFT", ddlab, "BOTTOMLEFT", 0, -12)
				note:SetWidth(500)
				note:SetJustifyH("LEFT")
				note:SetText(ns.L["Changes apply immediately and are saved."])
				return f
			end,
		})
	end
end
