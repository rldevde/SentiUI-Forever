-- luacheck: read globals TooltipDataProcessor Enum GameTooltip hooksecurefunc
-- luacheck: read globals ItemRefTooltip ItemRefShoppingTooltip1 ItemRefShoppingTooltip2
local _, ns = ...

-- Adds "who owns this" lines to item tooltips: per character a line with
-- bags/bank/worn counts plus a total. Toggle in the settings page.
local Tooltip = {}
ns.Tooltip = Tooltip

local L = ns.L
local W = ns.Widgets
local Store = ns.Store

ns.dbDefaults.settings.tooltip = true

local MAX_OWNERS = 8

local function ItemIdFromLink(link)
	if type(link) == "string" then
		return tonumber(link:match("item:(%d+)"))
	end
end

local function AddLines(tooltip, itemID)
	if not ns.enabled then
		return
	end
	if not (ns.db and ns.db.settings.tooltip) then
		return
	end
	if not itemID then
		return
	end
	local owners = Store.OwnersOf(itemID)
	if #owners == 0 then
		return
	end
	tooltip:AddLine(" ")
	tooltip:AddLine(L.TOOLTIP_OWNED_BY, 0.92, 0.68, 0.20)
	local shown = 0
	local total = 0
	for _, entry in ipairs(owners) do
		total = total + entry.total
		if shown < MAX_OWNERS then
			shown = shown + 1
			local color = entry.char.class and W.ClassColorHex(entry.char.class)
				or "ffffffff"
			local parts = {}
			if entry.bags > 0 then
				parts[#parts + 1] = L.TOOLTIP_BAGS .. " x" .. entry.bags
			end
			if entry.bank > 0 then
				parts[#parts + 1] = L.TOOLTIP_BANK .. " x" .. entry.bank
			end
			if entry.mail and entry.mail > 0 then
				parts[#parts + 1] = L.TOOLTIP_MAIL .. " x" .. entry.mail
			end
			if entry.gear > 0 then
				parts[#parts + 1] = L.TOOLTIP_WORN
			end
			tooltip:AddLine(("  |c%s%s|r — %s"):format(color,
				ns.ShortName(entry.key), table.concat(parts, " · ")), 1, 1, 1)
		end
	end
	if #owners > shown then
		tooltip:AddLine(L.TOOLTIP_MORE:format(#owners - shown), 0.55, 0.57, 0.64)
	end
	if #owners > 1 then
		tooltip:AddLine(L.TOOLTIP_TOTAL:format(total), 0.20, 0.62, 1.00)
	end
	-- deliberately NO tooltip:Show() here: lines are added while the
	-- tooltip is still assembling (OnTooltipSetItem / data post-call),
	-- so every skin (Blizzard, ElvUI, DaylightUI) sizes its backdrop
	-- with them included. A nested Show() leaves the backdrop at the
	-- old size and the new lines spill out of the container.
end

local function OnSetItem(tooltip)
	local _, link = tooltip:GetItem()
	ns.SafeCall("Tooltip", AddLines, tooltip, ItemIdFromLink(link))
end

-- Hooks wait for SAI_BOOT so a disabled module never touches tooltips.
ns.RegisterCallback(Tooltip, "SAI_BOOT", function()

-- Primary path: OnTooltipSetItem fires before the tooltip lays out, so
-- appended lines are part of the initial size on every tooltip skin.
-- Hook every item tooltip frame the client knows, not only GameTooltip.
local hooked = false
for _, name in ipairs({ "GameTooltip", "ItemRefTooltip",
	"ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2",
	"ShoppingTooltip1", "ShoppingTooltip2" }) do
	local tt = _G[name]
	if tt and tt.HookScript then
		pcall(tt.HookScript, tt, "OnTooltipSetItem", OnSetItem)
		hooked = true
	end
end

-- Fallback for flavours where the widget script does not exist: the
-- retail data-processor post-call. Same rule - add lines only, the
-- processor sizes the tooltip afterwards.
if not hooked and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
	and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,
		function(tooltip, data)
			ns.SafeCall("Tooltip", AddLines, tooltip, data and data.id)
		end)
end

end) -- SAI_BOOT
