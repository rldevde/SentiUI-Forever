-- Settings pages for the unit frames, filed under their own
-- "Unit Frames" section.
local _, ns = ...
local S = SentiUI
local L = ns.L

local function UnitGroup(key, label, extra)
	local items = {
		{ type = "toggle", key = key .. ".enable", label = L["Enabled"], reload = true,
			desc = L["Show this unit frame."] },
		{ type = "slider", key = key .. ".w", label = L["Width"], min = 60, max = 400, step = 2, unit = "px" },
		{ type = "slider", key = key .. ".h", label = L["Height"], min = 12, max = 80, step = 1, unit = "px" },
		{ type = "toggle", key = key .. ".power", label = L["Show power bar"], reload = true },
		{ type = "toggle", key = key .. ".auras", label = L["Show auras"], reload = true },
		{ type = "dropdown", key = key .. ".portrait", label = L["Portrait"],
			options = {
				{ value = "off", label = L["Off"] },
				{ value = "class", label = L["Class icon"] },
				{ value = "model", label = L["3D portrait"] },
			},
			desc = L["Portrait tile on the left edge: class icon for players, a 3D face for everything else, or the 3D portrait for all."] },
	}
	if extra then
		for _, it in ipairs(extra) do items[#items + 1] = it end
	end
	return { label = label, items = items }
end

ns.OPTIONS = { pages = {
	{
		id = "unitframes",
		label = L["Unit Frames"],
		desc = L["Player, target, party and raid frames in the SentiUI look."],
		groups = {
			{
				label = L["Unit Frames"],
				items = {
					{ type = "toggle", key = "enabled", label = L["Enable unit frames"], reload = true,
						desc = L["Turns every unit frame off after a reload."] },
					{ type = "slider", key = "fontSize", label = L["Font size"], min = 8, max = 20, step = 1, unit = "px" },
					{ type = "dropdown", key = "healthColorMode", label = L["Health color"],
						options = {
							{ value = "CLASS", label = L["Class color"] },
							{ value = "REACTION", label = L["Reaction"] },
							{ value = "STATIC", label = L["Static green"] },
						},
						desc = L["How health bars are colored: class color for players, reaction color, or a flat green."] },
					{ type = "dropdown", key = "healthTextMode", label = L["Health text"],
						options = {
							{ value = "PERCENT", label = L["Percent only"] },
							{ value = "VALUE", label = L["Health values"] },
							{ value = "BOTH", label = L["Value + percent"] },
						},
						desc = L["What the health text shows next to the name."] },
					{ type = "toggle", key = "smoothBars", label = L["Smooth bar animation"],
						desc = L["Bars ease into their new value instead of snapping."] },
					{ type = "slider", key = "rangeFadeAlpha", label = L["Out-of-range opacity"], min = 0.1, max = 1, step = 0.05,
						desc = L["Alpha for party/raid members out of spell range."] },
				},
			},
			{
				label = L["Hide Blizzard frames"],
				items = {
					{ type = "toggle", key = "hideBlizzard.player", label = L["Player frame"], reload = true },
					{ type = "toggle", key = "hideBlizzard.target", label = L["Target frame"], reload = true },
					{ type = "toggle", key = "hideBlizzard.pet", label = L["Pet frame"], reload = true },
					{ type = "toggle", key = "hideBlizzard.focus", label = L["Focus frame"], reload = true },
					{ type = "toggle", key = "hideBlizzard.party", label = L["Party frames"], reload = true },
					{ type = "toggle", key = "hideBlizzard.raid", label = L["Raid frames"], reload = true },
					{ type = "toggle", key = "hideBlizzard.castbar", label = L["Cast bar"], reload = true },
				},
			},
		},
	},
	{
		id = "ufsingles",
		label = L["Player & Target"],
		desc = L["Single unit frames. Position them with the SentiUI movers (/sui unlock)."],
		groups = {
			UnitGroup("player", L["Player"], {
				{ type = "toggle", key = "player.castbar", label = L["Show cast bar"], reload = true },
				{ type = "toggle", key = "player.classPower", label = L["Class power"], reload = true,
					desc = L["Pips above the player frame: combo points, holy power, chi, shards, arcane, essence - runes as per-pip recharge fills on a death knight."] },
			}),
			UnitGroup("target", L["Target"], {
				{ type = "toggle", key = "target.castbar", label = L["Show cast bar"], reload = true },
				{ type = "slider", key = "target.maxBuffs", label = L["Max buffs"], min = 0, max = 16, step = 1 },
				{ type = "slider", key = "target.maxDebuffs", label = L["Max debuffs"], min = 0, max = 24, step = 1 },
			{ type = "toggle", key = "target.threatPct", label = L["Threat percent"],
				desc = L["Show your threat percentage on the target."] },
			}),
			UnitGroup("tot", L["Target of Target"]),
			UnitGroup("pet", L["Pet"]),
			UnitGroup("focus", L["Focus"], {
				{ type = "toggle", key = "focus.castbar", label = L["Show cast bar"], reload = true },
			}),
		},
	},
	{
		id = "ufparty",
		label = L["Party"],
		desc = L["Five-button party block; joins/leaves mid-combat are handled by unit watch."],
		groups = {
			{
				label = L["Party"],
				items = {
					{ type = "toggle", key = "party.enable", label = L["Enabled"], reload = true },
					{ type = "slider", key = "party.w", label = L["Width"], min = 60, max = 300, step = 2, unit = "px" },
					{ type = "slider", key = "party.h", label = L["Height"], min = 12, max = 60, step = 1, unit = "px" },
					{ type = "slider", key = "party.spacing", label = L["Spacing"], min = 0, max = 20, step = 1, unit = "px" },
					{ type = "dropdown", key = "party.growth", label = L["Growth"],
						options = {
							{ value = "DOWN", label = L["Down"] },
							{ value = "UP", label = L["Up"] },
							{ value = "RIGHT", label = L["Right"] },
							{ value = "LEFT", label = L["Left"] },
						} },
					{ type = "toggle", key = "party.showPlayer", label = L["Show player"], reload = true },
					{ type = "toggle", key = "party.showSolo", label = L["Show while solo"], reload = true },
					{ type = "toggle", key = "party.power", label = L["Show power bar"], reload = true },
					{ type = "toggle", key = "party.rangeFade", label = L["Fade out of range"] },
					{ type = "toggle", key = "party.showRole", label = L["Show role"] },
					{ type = "toggle", key = "party.showPets", label = L["Show pets"], reload = true,
						desc = L["Small pet bars attached below each party member."] },
					{ type = "toggle", key = "party.auras", label = L["Show auras"], reload = true },
					{ type = "toggle", key = "party.defensiveIcons", label = L["Defensive icons"],
						desc = L["Small corner icons for external defensive cooldowns on party cells."] },
					{ type = "dropdown", key = "party.portrait", label = L["Portrait"],
						options = {
							{ value = "off", label = L["Off"] },
							{ value = "class", label = L["Class icon"] },
							{ value = "model", label = L["3D portrait"] },
						},
						desc = L["Portrait tile on the left edge: class icon for players, a 3D face for everything else, or the 3D portrait for all."] },
				},
			},
		},
	},
	{
		id = "ufraid",
		label = L["Raid"],
		desc = L["Raid grid driven by a secure group header; visibility flips live on an unprotected holder so combat never blocks layout."],
		groups = {
			{
				label = L["Raid"],
				items = {
					{ type = "toggle", key = "raid.enable", label = L["Enabled"], reload = true },
					{ type = "slider", key = "raid.w", label = L["Width"], min = 30, max = 200, step = 2, unit = "px" },
					{ type = "slider", key = "raid.h", label = L["Height"], min = 12, max = 60, step = 1, unit = "px" },
					{ type = "slider", key = "raid.spacing", label = L["Spacing"], min = 0, max = 12, step = 1, unit = "px" },
					{ type = "slider", key = "raid.unitsPerColumn", label = L["Units per column"], min = 1, max = 10, step = 1, reload = true },
					{ type = "slider", key = "raid.maxColumns", label = L["Max columns"], min = 1, max = 8, step = 1, reload = true },
					{ type = "dropdown", key = "raid.growth", label = L["Fill direction"],
						options = {
							{ value = "RIGHT", label = L["Columns right"] },
							{ value = "DOWN", label = L["Rows down"] },
						} },
					{ type = "dropdown", key = "raid.groupBy", label = L["Group by"],
						options = {
							{ value = "GROUP", label = L["Group"] },
							{ value = "CLASS", label = L["Class"] },
							{ value = "ROLE", label = L["Role"] },
						} },
					{ type = "toggle", key = "raid.showSolo", label = L["Show while solo"], reload = true },
					{ type = "toggle", key = "raid.rangeFade", label = L["Fade out of range"] },
					{ type = "toggle", key = "raid.showRole", label = L["Show role"] },
					{ type = "toggle", key = "raid.readyCheck", label = L["Ready check"], reload = true },
					{ type = "toggle", key = "raid.auras", label = L["Show auras"], reload = true,
						desc = L["Aura icons on raid cells - busy on small cells."] },
					{ type = "toggle", key = "raid.defensiveIcons", label = L["Defensive icons"],
						desc = L["Small corner icons for external defensive cooldowns on raid cells."] },
					{ type = "toggle", key = "raidTools.enable", label = L["Raid tools"], reload = true,
						desc = L["Strip with target/world markers, ready check and a pull timer. Only shows while grouped."] },
					{ type = "dropdown", key = "raid.portrait", label = L["Portrait"],
						options = {
							{ value = "off", label = L["Off"] },
							{ value = "class", label = L["Class icon"] },
							{ value = "model", label = L["3D portrait"] },
						},
						desc = L["Portrait tile on the left edge: class icon for players, a 3D face for everything else, or the 3D portrait for all."] },
				},
			},
		},
	},
	{
		id = "ufextras",
		label = L["Extras"],
		desc = L["Boss/arena blocks and indicators added on top of the core frames."],
		groups = {
			{
				label = L["Frames"],
				items = {
					{ type = "toggle", key = "boss.enable", label = L["Boss frames"], reload = true,
						desc = L["Stack of boss1-5 frames, shown while boss units exist."] },
					{ type = "slider", key = "boss.w", label = L["Boss width"], min = 80, max = 300, step = 2, unit = "px", reload = true },
					{ type = "slider", key = "boss.h", label = L["Boss height"], min = 12, max = 60, step = 1, unit = "px", reload = true },
					{ type = "toggle", key = "boss.power", label = L["Boss power bar"], reload = true },
					{ type = "toggle", key = "arena.enable", label = L["Arena frames"], reload = true,
						desc = L["Stack of arena1-5 frames, shown while arena units exist."] },
					{ type = "slider", key = "arena.w", label = L["Arena width"], min = 80, max = 300, step = 2, unit = "px", reload = true },
					{ type = "slider", key = "arena.h", label = L["Arena height"], min = 12, max = 60, step = 1, unit = "px", reload = true },
					{ type = "toggle", key = "arena.power", label = L["Arena power bar"], reload = true },
					{ type = "toggle", key = "hideBlizzard.boss", label = L["Hide Blizzard boss/arena"], reload = true },
				},
			},
			{
				label = L["Indicators"],
				items = {
					{ type = "toggle", key = "healPredict", label = L["Heal prediction"],
						desc = L["Lighter fill showing heals landing on the unit."] },
					{ type = "toggle", key = "player.combatText", label = L["Combat text"],
						desc = L["Damage and healing numbers rising out of the player frame."] },
					{ type = "toggle", key = "altPower", label = L["Alt power bar"],
						desc = L["The encounter power bar (replaces the parked Blizzard bar)."] },
					{ type = "toggle", key = "party.cooldownIcons", label = L["Cooldown tracker"], reload = true,
						desc = L["Small icons under each party cell when a member casts an interrupt or signature defensive, tracked via the combat log."] },
					{ type = "slider", key = "party.cooldownMax", label = L["Tracker icons"], min = 1, max = 8, step = 1,
						disabled = function(get) return get("party.cooldownIcons") == false end },
					{ type = "toggle", key = "raid.cooldownIcons", label = L["Tracker on raid cells"], reload = true,
						desc = L["The same cooldown icons on raid cells - off by default, the cells are cramped."] },
					{ type = "slider", key = "raid.cooldownMax", label = L["Tracker icons (raid)"], min = 1, max = 8, step = 1,
						disabled = function(get) return get("raid.cooldownIcons") == false end },
					{ type = "toggle", key = "party.missingBuff", label = L["Missing buff marker"],
						desc = L["A gold ! above the cell when a member lacks a buff your class can give."] },
					{ type = "toggle", key = "raid.missingBuff", label = L["Missing buff marker (raid)"],
						desc = L["A gold ! above the raid cell when a member lacks a buff your class can give."] },
					{ type = "toggle", key = "lowHP", label = L["Low health pulse"],
						desc = L["A red vignette pulses at the screen edges while your health runs low."] },
					{ type = "slider", key = "lowHPPct", label = L["Pulse threshold"], min = 10, max = 60, step = 5, unit = "%",
						disabled = function(get) return get("lowHP") == false end },
					{ type = "toggle", key = "levelFlash", label = L["Level-up flash"],
						desc = L["A gold flash at the screen edges when you level up."] },
					{ type = "toggle", key = "shotLevelUp", label = L["Screenshot on level up"] },
					{ type = "toggle", key = "shotAchieve", label = L["Screenshot on achievements"] },
				},
			},
		},
	},
} }

function ns.SettingChanged(mod, path)
	if not ns.db then return end
	-- live-apply what we can; structural changes stay reload-flagged
	if path == "fontSize" or path == "healthColorMode" or path == "healthTextMode"
		or path == "smoothBars" then
		ns.Repaint()
		return
	end
	if path and path:match("^party%.") then
		local G = ns.Group
		if G and G.partyHolder then
			if path:match("rangeFade$") or path:match("showRole$") then
				for _, b in ipairs(G.partyButtons) do
					if not ns.db.party.showRole and b.RoleIcon then b.RoleIcon:Hide() end
					ns.UF.UpdateIcons(b)
				end
			elseif path:match("portrait$") then
				-- portrait tile resizes the health bar: reconfigure, then
				-- refresh so UpdatePortrait paints the new mode
				for _, b in ipairs(G.partyButtons) do
					ns.UF.Configure(b)
					ns.UF.Refresh(b)
				end
			else
				G.PartyLayout()
			end
		end
		return
	end
	if path and path:match("^raid%.") then
		local G = ns.Group
		if G and G.raidHeader then
			G.ApplyRaidAttributes(G.raidHeader)
			if path:match("portrait$") then
				for i = 1, 40 do
					local c
					if G.raidHeader.GetFrameRef then
						local ok, c2 = pcall(G.raidHeader.GetFrameRef, G.raidHeader, "child" .. i)
						c = ok and c2
					end
					c = c or _G[G.raidHeader:GetName() .. "UnitButton" .. i]
					if not c then break end
					if c.suiInit then ns.UF.Refresh(c) end
				end
			end
		end
		return
	end
	local key = path and path:match("^(%a+)%.[wh]$")
	if key and ns.units[key] then
		ns.UF.Configure(ns.units[key])
	end
	local pkey = path and path:match("^(%a+)%.portrait$")
	if pkey and ns.units[pkey] then
		ns.UF.Configure(ns.units[pkey])
		ns.UF.Refresh(ns.units[pkey])
	end
end
