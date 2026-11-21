-- Notification toasts: a small card that slides in above the bottom bar
-- (or below the top bar) for short-lived events - new mail, low
-- durability, full bags, known rares targeted. Each source can be
-- switched off in the options.
local _, ns = ...
local S = SentiUI
local L = ns.L
local Plain = ns.Plain

local CreateFrame = CreateFrame
local format = string.format

local Toasts = {}
ns.Toasts = Toasts

local queue = {}
local showing, fadeIn, holdT
local toast

local function EnsureFrame()
	if toast then return toast end
	toast = CreateFrame("Frame", "SentiUIPanelToast", UIParent, "BackdropTemplate")
	toast:SetSize(320, 34)
	toast:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 60)
	toast:SetFrameStrata("HIGH")
	toast:SetAlpha(0)
	S.Template(toast, "raised")
	ns.AccentEdge(toast, "TOP")
	toast.icon = toast:CreateTexture(nil, "ARTWORK")
	toast.icon:SetSize(18, 18)
	toast.icon:SetPoint("LEFT", 10, 0)
	toast.txt = ns.Font(toast, 11)
	toast.txt:SetPoint("LEFT", toast.icon, "RIGHT", 8, 0)
	toast.txt:SetPoint("RIGHT", toast, "RIGHT", -10, 0)
	toast.txt:SetJustifyH("LEFT")
	local el = 0
	toast:SetScript("OnUpdate", function(self, dt)
		el = el + dt
		if showing == "in" then
			fadeIn = math.min(1, fadeIn + dt * 6)
			self:SetAlpha(fadeIn)
			if fadeIn >= 1 then showing, holdT = "hold", 3 end
		elseif showing == "hold" then
			if holdT and el > holdT then showing = "out" end
		elseif showing == "out" then
			fadeIn = math.max(0, fadeIn - dt * 4)
			self:SetAlpha(fadeIn)
			if fadeIn <= 0 then
				showing = nil
				el = 0
				Toasts.Pump()
			end
		end
	end)
	toast:Hide()
	return toast
end

function Toasts.Pump()
	if showing or #queue == 0 then return end
	local m = queue[1]
	table.remove(queue, 1)
	local f = EnsureFrame()
	f.icon:SetTexture(m.icon or S.media.logo)
	f.txt:SetText(m.text)
	f:Show()
	showing, fadeIn, el = "in", 0, 0
end

function Toasts.Push(text, icon)
	if #queue > 4 then return end
	queue[#queue + 1] = { text = text, icon = icon }
	if not showing then Toasts.Pump() end
end

-- source flags under db.notify[flag]
function Toasts.On(flag, text, icon)
	if ns.db.notify and ns.db.notify[flag] ~= false then
		Toasts.Push(text, icon)
	end
end

function Toasts.Initialize()
	ns.RegisterBusEvent("MAIL_INBOX_UPDATE", function()
		local has = ns.MailWaiting()
		if has and has ~= Toasts._mail then
			Toasts.On("mail", L["New mail received"], "Interface\\Icons\\INV_Letter_15")
		end
		Toasts._mail = has
	end)
	ns.RegisterBusEvent("UPDATE_INVENTORY_DURABILITY", function()
		if not GetInventoryItemDurability then return end
		local worst
		for i = 1, 19 do
			local ok, cur, max = pcall(GetInventoryItemDurability, i)
			cur, max = ok and Plain(cur) or nil, ok and Plain(max) or nil
			if cur and max and max > 0 then
				local p = cur / max
				if not worst or p < worst then worst = p end
			end
		end
		if worst and worst < 0.25 and not Toasts._duraWarn then
			Toasts._duraWarn = true
			Toasts.On("dura", format(L["Durability low: %d%%"], worst * 100), "Interface\\Icons\\Trade_BlackSmithing")
		elseif worst and worst >= 0.4 then
			Toasts._duraWarn = nil
		end
	end)
	ns.RegisterBusEvent("BAG_UPDATE", function()
		if not (C_Container and C_Container.GetContainerNumFreeSlots) then return end
		local free = 0
		for b = 0, 4 do
			local ok, n = pcall(C_Container.GetContainerNumFreeSlots, b)
			free = free + (ok and Plain(n) or 0)
		end
		if free == 0 and not Toasts._bagsWarn then
			Toasts._bagsWarn = true
			Toasts.On("bags", L["Bags are full"], "Interface\\Icons\\INV_Misc_Bag_08")
		elseif free > 0 then
			Toasts._bagsWarn = nil
		end
	end)
end
