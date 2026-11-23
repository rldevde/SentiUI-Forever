-- The module's options, filed under its own "Bags" section. Both views get
-- their own settings group (bags.* / bank.*), everything is switchable.
local _, ns = ...
local L = ns.L

local function viewItems(key)
	return {
		{ type = "slider", key = key .. ".iconSize", label = L["Slot size"], min = 24, max = 48, step = 1, unit = "px" },
		{ type = "slider", key = key .. ".spacing", label = L["Slot spacing"], min = 0, max = 8, step = 1, unit = "px" },
		{ type = "slider", key = key .. ".columns", label = L["Columns"], min = 6, max = 20, step = 1,
			desc = L["Slots per row."] },
		{ type = "toggle", key = key .. ".emptySlots", label = L["Empty slots"],
			desc = L["Draw empty slots too."] },
		{ type = "toggle", key = key .. ".qualityBorder", label = L["Quality border"],
			desc = L["The slot border takes the item's quality color."] },
		{ type = "toggle", key = key .. ".showIlvl", label = L["Item level"],
			desc = L["Gear shows its item level, bottom left."] },
		{ type = "toggle", key = key .. ".showJunkIcon", label = L["Junk mark"],
			desc = L["Grey items get a small coin mark."] },
	}
end

ns.OPTIONS = {
	pages = {
		{
			id = "bags",
			label = L["Bags"],
			desc = L["One clean bag window with search, sorting, auto sell of grey items and auto repair."],
			groups = {
				{
					label = L["Bags"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable bags"], reload = true,
							desc = L["Turns the SentiUI bag window off after a reload."] },
						{ type = "toggle", key = "search", label = L["Search"], reload = true,
							desc = L["Show the search box above the grid."] },
						{ type = "toggle", key = "categories", label = L["Categories"],
							desc = L["Group items under headers (New, Quest, Equipment, ...) instead of one flat grid."] },
						{ type = "toggle", key = "showNew", label = L["New items section"],
							desc = L["Fresh loot lands in a 'New' section first; it clears when you close the window."] },
						{ type = "toggle", key = "currency", label = L["Currency strip"],
							desc = L["Show backpack-tracked currencies next to the money in the footer."] },
					},
				},
				{ label = L["Bags window"], desc = L["Grid and overlays of the carried-bags window."],
					items = viewItems("bags") },
				{ label = L["Bank"], desc = L["Grid and overlays of the bank window."],
					items = viewItems("bank") },
				{
					label = L["Bag preferences"],
					desc = L["Designate a bag for a specific item category. Choose 'Everything' to keep the bag unrestricted."],
					items = {
						{ type = "dropdown", key = "bagPref.1", label = L["Bag 1"],
							choices = function()
								return { [""] = L["Everything"],
									quest = L["Quest"], equipment = L["Equipment"],
									consumables = L["Consumables"], tradegoods = L["Trade goods"],
									misc = L["Miscellaneous"], junk = L["Junk"] },
								{ "", "quest", "equipment", "consumables", "tradegoods", "misc", "junk" }
							end },
						{ type = "dropdown", key = "bagPref.2", label = L["Bag 2"],
							choices = function()
								return { [""] = L["Everything"],
									quest = L["Quest"], equipment = L["Equipment"],
									consumables = L["Consumables"], tradegoods = L["Trade goods"],
									misc = L["Miscellaneous"], junk = L["Junk"] },
								{ "", "quest", "equipment", "consumables", "tradegoods", "misc", "junk" }
							end },
						{ type = "dropdown", key = "bagPref.3", label = L["Bag 3"],
							choices = function()
								return { [""] = L["Everything"],
									quest = L["Quest"], equipment = L["Equipment"],
									consumables = L["Consumables"], tradegoods = L["Trade goods"],
									misc = L["Miscellaneous"], junk = L["Junk"] },
								{ "", "quest", "equipment", "consumables", "tradegoods", "misc", "junk" }
							end },
						{ type = "dropdown", key = "bagPref.4", label = L["Bag 4"],
							choices = function()
								return { [""] = L["Everything"],
									quest = L["Quest"], equipment = L["Equipment"],
									consumables = L["Consumables"], tradegoods = L["Trade goods"],
									misc = L["Miscellaneous"], junk = L["Junk"] },
								{ "", "quest", "equipment", "consumables", "tradegoods", "misc", "junk" }
							end },
					},
				},
				{
					label = L["Merchant"],
					items = {
						{ type = "toggle", key = "sellJunk", label = L["Auto sell grey items"],
							desc = L["Every grey item is sold when a vendor opens."] },
						{ type = "toggle", key = "autoRepair", label = L["Auto repair"],
							desc = L["Repairs your gear at repair-capable vendors, paid from your own gold."] },
						{ type = "toggle", key = "repairGuild", label = L["Guild repair first"],
							disabled = function(get) return not get("autoRepair") end,
							desc = L["Try to pay the repair bill from guild funds first; falls back to your own gold."] },
					},
				},
				{
					label = L["Position"],
					items = {
						{ type = "text", label = L["The bag window is a mover: unlock move mode and drag it. Right-click a handle to reset."] },
						{ type = "button", label = L["Move frames"], text = L["Unlock"],
							func = function() SentiUI.Movers.SetUnlocked(true) end },
						{ type = "button", label = L["Reset positions"], text = L["Reset"],
							func = function()
								SentiUI.Movers.Reset("bags.bags")
								SentiUI.Movers.Reset("bags.bank")
							end },
					},
				},
			},
		},
	},
}
