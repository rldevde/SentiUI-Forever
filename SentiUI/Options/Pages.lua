-- The built-in option pages: SentiUI > Home, SentiUI > General and
-- Layout > Move frames. Modules file their own sections next to these.
local _, S = ...
local Options, W = S.Options, S.Widgets
local L = S.L
local C = S.colors

-- ---------------------------------------------------------------------
-- SentiUI > Home
-- ---------------------------------------------------------------------

Options.RegisterSection("sentiui", "SentiUI", 1)

Options.RegisterPage({
	id = "home",
	section = "sentiui",
	label = "Home",
	desc = "The SentiUI suite core. Modules from SentiUI_* addons dock their own sections here.",
	scope = "general",
	order = 1,
	groups = {
		{
			label = "Welcome",
			items = {
				{ type = "custom", height = 128, noSearch = true,
					build = function(row)
						local t = row:CreateTexture(nil, "ARTWORK")
						t:SetTexture(S.media.longLogo)
						local band = S.media.longLogoBand
						t:SetTexCoord(0, 1, band[1], band[2])
						t:SetSize(360, 120)
						t:SetPoint("CENTER", row, "CENTER", 0, 0)
					end },
				{ type = "text", label = function()
					return string.format(L["SentiUI %s - settings core for the SentiUI suite."], S.version)
				end },
				{ type = "text", label = "Type /sui to open this window, or use the minimap button." },
			},
		},
		{
			label = "Quick actions",
			items = {
				{ type = "button", label = "Move frames", text = "Unlock",
					desc = "Shows a labeled handle over every movable SentiUI frame.",
					func = function() S.Movers.SetUnlocked(true) end },
				{ type = "button", label = "Run installer", text = "Start",
					desc = "The first-run wizard, again from step one.",
					func = function() S.Installer.Show() end },
				{ type = "button", label = "Reload the interface", text = "Reload",
					func = function() (C_UI and C_UI.Reload or ReloadUI)() end },
			},
		},
		{
			label = "Loaded modules",
			items = {
				{ type = "text", label = function()
					local names = {}
					for name, mod in S.Modules() do
						if mod.enabled then names[#names + 1] = mod.label or name end
					end
					if #names == 0 then
						return L["No SentiUI modules loaded yet. SentiUI_* addons add their sections here."]
					end
					table.sort(names)
					return table.concat(names, "  |cff666666/|r  ")
				end },
			},
		},
	},
})

-- ---------------------------------------------------------------------
-- SentiUI > General
-- ---------------------------------------------------------------------

Options.RegisterPage({
	id = "general",
	section = "sentiui",
	label = "General",
	desc = "The minimap button, move mode and the master scale.",
	scope = "general",
	order = 2,
	groups = {
		{
			label = "Minimap button",
			items = {
				{ type = "toggle", key = "minimap.hide", label = "Show minimap button", invert = true,
					desc = "Left-click opens the settings, right-click toggles move mode. Drag repositions it." },
				{ type = "button", label = "Reset button position", text = "Reset",
					desc = "Back to the default spot at the minimap's lower left.",
					func = function()
						S.DB.General().minimap.angle = 220
						S.MinimapButton.Position()
					end },
			},
		},
		{
			label = "Move mode",
			desc = "How frames behave while they are unlocked.",
			items = {
				{ type = "toggle", key = "gridSnap", label = "Snap to grid" },
				{ type = "slider", key = "gridSize", label = "Grid size", min = 8, max = 64, step = 4, unit = "px",
					disabled = function(get) return not get("gridSnap") end },
				{ type = "toggle", key = "magnet", label = "Snap to frames and screen",
					desc = "Frames snap to other movers' edges and centers and to the screen's." },
				{ type = "toggle", key = "testFrame", label = "Show test frame",
					desc = "A sample frame to try move mode with before modules add their own." },
				{ type = "button", label = "Move frames", text = "Unlock",
					func = function() S.Movers.SetUnlocked(true) end },
				{ type = "button", label = "Reset all positions", text = "Reset all", confirm = true,
					func = function() S.Movers.ResetAll() end },
			},
		},
		{
			label = "Interface",
			items = {
				{ type = "slider", key = "uiScale", label = "Interface scale", min = 0.5, max = 1.5, step = 0.05, unit = "x",
					desc = "Master scale for SentiUI frames that opted into it." },
			},
		},
	},
})

-- ---------------------------------------------------------------------
-- SentiUI > Changelog
-- ---------------------------------------------------------------------

local clFilter = "all"

Options.RegisterPage({
	id = "changelog",
	section = "sentiui",
	label = "Changelog",
	desc = L["What's new in SentiUI and its modules."],
	scope = "general",
	order = 3,
	groups = function()
		local de = GetLocale() == "deDE"
		local list = S.Changelog.List()
		-- category filter: one entry per addon + "all"
		local values, order = { all = L["All modules"] }, { "all" }
		for _, slot in ipairs(list) do
			values[slot.addon] = slot.addon
			order[#order + 1] = slot.addon
		end
		local groups = {
			{ label = L["Filter"],
				items = { {
					type = "dropdown", label = L["Module"],
					get = function() return clFilter end,
					set = function(v)
						clFilter = v or "all"
						S.Fire("OptionsChanged")
					end,
					choices = function() return values, order end,
				} } },
		}
		if clFilter ~= "all" and not values[clFilter] then clFilter = "all" end
		for _, slot in ipairs(list) do
			if clFilter == "all" or slot.addon == clFilter then
				for _, e in ipairs(slot.entries) do
					local lines = (de and type(e.changesDE) == "table" and #e.changesDE > 0)
						and e.changesDE or e.changes or {}
					local items = {}
					for _, line in ipairs(lines) do
						items[#items + 1] = { type = "text", label = "|cff8b8f9a•|r  " .. line }
					end
					groups[#groups + 1] = {
						label = slot.addon .. "  |cff555c70" .. tostring(e.version)
							.. (e.date and ("  ·  " .. tostring(e.date)) or "") .. "|r",
						items = items,
					}
				end
			end
		end
		if #groups == 1 then
			groups[2] = { label = "Changelog",
				items = { { type = "text", label = L["No changelog entries yet."] } } }
		end
		return groups
	end,
})

-- ---------------------------------------------------------------------
-- Layout > Move frames
-- ---------------------------------------------------------------------

Options.RegisterSection("layout", "Layout", 20)

-- One custom row per registered mover: name, its saved offset, a reset button.
-- Item tables are cached per mover key so the window reuses its rows.
local moverItems = {}
local function moverItem(key, entry)
	local item = moverItems[key]
	if not item then
		item = {
			type = "custom",
			height = 26,
			moverKey = key,
			build = function(row)
				row.nameText = S.Font(row, 11)
				row.nameText:SetPoint("LEFT", 10, 0)
				row.posText = S.Font(row, 10, C.textDim)
				row.posText:SetPoint("LEFT", 220, 0)
				row.reset = W.Button(row, L["Reset"], 56, 18)
				row.reset:SetPoint("RIGHT", -12, 0)
				row.reset:SetScript("OnClick", function() S.Movers.Reset(key) end)
			end,
			update = function(row)
				row.nameText:SetText(entry.label and (L[entry.label] or entry.label) or key)
				local pos = S.DB.Positions()[key]
				if pos then
					row.posText:SetText(string.format("%d, %d", pos.x, pos.y))
				else
					row.posText:SetText(L["default"])
				end
			end,
		}
		moverItems[key] = item
	end
	item.label = entry.label
	return item
end

Options.RegisterPage({
	id = "movers",
	section = "layout",
	label = "Move frames",
	desc = "Every frame a SentiUI module registered for moving. Unlock to drag them, right-click a handle to reset one.",
	scope = "general",
	order = 10,
	groups = function()
		local items = {
			{ type = "button", label = "Move frames", text = "Unlock",
				func = function() S.Movers.SetUnlocked(true) end },
			{ type = "button", label = "Reset all positions", text = "Reset all", confirm = true,
				func = function() S.Movers.ResetAll() end },
		}
		for key, entry in S.Movers.Entries() do
			items[#items + 1] = moverItem(key, entry)
		end
		if #items == 2 then
			items[#items + 1] = { type = "text", label = "No movable frames yet. SentiUI modules register theirs here." }
		end
		return {
			{ label = "Move mode", items = items },
		}
	end,
})

-- General settings with side effects.
S.On("GeneralChanged", function(path, value)
	if path == "minimap.hide" then
		S.MinimapButton.Sync()
	elseif path == "uiScale" then
		S.Movers.ApplyAll()
	elseif path == "testFrame" then
		S.Movers.SetTestFrameShown(value)
	end
end)
