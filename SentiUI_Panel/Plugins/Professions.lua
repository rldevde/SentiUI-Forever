-- Professions plugin: the bottom bar shows the first learned profession
-- (icon + name + rank); a click opens the professions menu - every
-- learned profession listed with its skill level, clicking one opens the
-- game's profession window via C_TradeSkillUI.OpenTradeSkill. That call
-- needs a hardware event, which a menu click provides - but it is still
-- protected under combat lockdown (ADDON_ACTION_BLOCKED), so a click mid
-- fight queues the open for PLAYER_REGEN_ENABLED instead.
local _, ns = ...
local S = SentiUI
local L = ns.L
local P = ns.Plugins
local TipHead, TipSub = ns.TipHead, ns.TipSub
local format = string.format

local function ProfList()
	local out = {}
	if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
		return out
	end
	local slots = { GetProfessions() }
	for i = 1, 7 do
		local idx = slots[i]
		if type(idx) == "number" and idx > 0 and not S.IsSecret(idx) then
			local ok, name, icon, c, d, e, f, g, h = pcall(GetProfessionInfo, idx)
			if ok and type(name) == "string" then
				-- the return order differs between builds: rank is the
				-- 3rd value on one, the 4th on another - resolve by type
				local rank = (type(c) == "number" and not S.IsSecret(c)) and c or d
				local max = (type(d) == "number" and not S.IsSecret(d)) and d or e
				local line = (type(g) == "number" and not S.IsSecret(g)) and g or h
				out[#out + 1] = {
					name = name,
					icon = (type(icon) == "string" or type(icon) == "number")
						and icon or nil,
					rank = tonumber(rank) or 0,
					max = tonumber(max) or 0,
					skillLine = (type(line) == "number" and line) or nil,
					primary = i <= 2,
				}
			end
		end
	end
	return out
end

local function OpenProfession(p)
	if not p.skillLine then return end
	local open = C_TradeSkillUI and C_TradeSkillUI.OpenTradeSkill
	if type(open) ~= "function" then return end
	-- blocked under combat lockdown even with the click's hardware event:
	-- hold the open for after the fight instead of tripping the flag
	if InCombatLockdown and InCombatLockdown() then
		ns.Toasts.Push(L["Opens after combat"] .. ": " .. p.name, p.icon)
		S.RunOutOfCombat(function()
			ns.HardAPI("OpenTradeSkill", open, p.skillLine)
		end)
		return
	end
	ns.HardAPI("OpenTradeSkill", open, p.skillLine)
end

ns.RegisterPlugin({
	id = "professions",
	label = L["Professions"],
	icon = "Interface\\Icons\\Trade_BlackSmithing",
	bar = "bottom", zone = "CENTER", order = 55,
	events = { "SKILL_LINES_CHANGED", "PLAYER_ENTERING_WORLD", "CHAT_MSG_SKILL" },
	update = function(def)
		local list = ProfList()
		if #list == 0 then return "" end
		local p = list[1]
		local b = def.button
		if b and b.icon and p.icon then pcall(b.icon.SetTexture, b.icon, p.icon) end
		local txt = format("%s |cff%s%d|r", p.name, ns.accentHex, p.rank)
		if #list > 1 then
			txt = txt .. " |cff8c919f+" .. (#list - 1) .. "|r"
		end
		return txt
	end,
	tooltip = function(tip)
		local list = ProfList()
		TipHead(tip, L["Professions"])
		if #list == 0 then
			tip:AddLine("|cff8c919f" .. L["No professions learned"] .. "|r")
		else
			for _, p in ipairs(list) do
				tip:AddDoubleLine(
					(p.icon and ("|T" .. p.icon .. ":14:14|t ") or "") .. p.name,
					p.rank .. "/" .. p.max,
					1, 1, 1, 1, 1, 1)
			end
		end
		TipSub(tip, L["Click: professions menu"])
	end,
	click = function(b)
		P.Menu(P.byId["professions"], b)
	end,
	menu = function(def, items)
		local list = ProfList()
		if #list == 0 then
			items[#items + 1] = { text = L["No professions learned"], disabled = true }
			return
		end
		for _, p in ipairs(list) do
			items[#items + 1] = {
				text = (p.icon and ("|T" .. p.icon .. ":14:14:0:0|t ") or "")
					.. p.name .. "  |cff8c919f" .. p.rank .. "/" .. p.max .. "|r",
				disabled = not p.skillLine,
				onClick = function() OpenProfession(p) end,
			}
		end
	end,
})
