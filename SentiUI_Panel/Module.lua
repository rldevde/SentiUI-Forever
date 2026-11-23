-- Registration with the SentiUI core. The module's pages appear as their
-- own "Panel" section in the settings; settings land in
-- SentiUIDB.modules.Panel.
local _, ns = ...

SentiUI:RegisterModule("Panel", {
	label = ns.L["Panel"],
	order = 130,
	defaults = ns.DEFAULTS,
	options = ns.OPTIONS,
	changelog = ns.CHANGELOG,
	OnEnable = function(mod)
		if not mod.db.enabled then return end
		ns.CoreEnable(mod)
	end,
	OnSettingChanged = function(mod, path) ns.SettingChanged(mod, path) end,
})

-- installer step: pick which plugins show on the bottom bar. Registered
-- as a module step so it lands before the installer's finish page.
do
	local Inst = SentiUI.Installer
	if Inst and Inst.AddModuleStep then
		Inst.AddModuleStep({
			title = "Bottom bar plugins",
			-- the installer renders step texts raw: translate through the
			-- panel's own locale table here (the key is the English text)
			text = ns.L["Choose which plugins show on the bottom bar. Everything can be changed later under SentiUI > Panel > Plugins."],
			build = function(host)
				if not (ns.db and ns.Plugins) then
					print("|cffebad33SentiUI|r installer: Panel plugins not ready (db=" ..
						tostring(ns.db ~= nil) .. ")")
					return nil
				end
				local S = SentiUI
				local f = CreateFrame("Frame", nil, host)
				f:SetAllPoints()
				local scroll, child = S.Widgets.Scroll(f)
				scroll:SetPoint("TOPLEFT", 0, 0)
				scroll:SetPoint("BOTTOMRIGHT", -6, 0)
				child:SetWidth(496)
				local defs = {}
				for _, d in ipairs(ns.Plugins.defs) do defs[#defs + 1] = d end
				table.sort(defs, function(a, b)
					return (a.label or a.id) < (b.label or b.id)
				end)
				local y = -2
				for _, d in ipairs(defs) do
					local cfg = ns.Plugins.Cfg(d)
					local row = CreateFrame("Button", nil, child)
					row:SetHeight(20)
					row:SetPoint("TOPLEFT", 0, y)
					row:SetPoint("TOPRIGHT", 0, y)
					row.hl = row:CreateTexture(nil, "HIGHLIGHT")
					row.hl:SetAllPoints()
					row.hl:SetTexture("Interface\\Buttons\\WHITE8X8")
					row.hl:SetVertexColor(0.92, 0.68, 0.2, 0.12)
					local cb = S.Widgets.Check(row)
					cb:SetPoint("LEFT", 2, 0)
					cb:SetChecked(cfg.shown ~= false)
					local lab = S.Font(row, 11)
					lab:SetPoint("LEFT", cb, "RIGHT", 6, 0)
					lab:SetText(d.label or d.id)
					cb.onChanged = function(v)
						cfg.shown = v and true or false
						d.last = nil
						if ns.Plugins.UpdateOne then ns.Plugins.UpdateOne(d) end
						if ns.Bars and ns.Bars.Relayout then
							ns.Bars.Relayout(cfg.bar or "bottom")
						end
					end
					row:SetScript("OnClick", function() cb:Click() end)
					y = y - 20
				end
				child:SetHeight(-y + 2)
				return f
			end,
		})
	end
end
