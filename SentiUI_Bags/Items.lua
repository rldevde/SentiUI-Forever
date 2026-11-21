-- Item slot buttons: visuals (quality edge, count, ilvl, junk mark, search
-- dim) on top of the game's own ContainerFrameItemButtonTemplate. Its
-- trusted OnClick does everything natively - pickup, use, equip, sell at
-- a vendor, bank transfers, stack split, link/dressup - which no custom
-- click handler can reproduce, because protected actions only run on
-- genuine clicks inside game code. The template reads the bag id off its
-- parent frame's GetID and the slot off its own GetID, so slots are
-- parented to per-bag holder frames inside the window's grid.
local _, ns = ...
local S = SentiUI
local L = ns.L

local Items = {}
ns.Items = Items

local BLANK = "Interface\\Buttons\\WHITE8X8"
local ACC = S.colors.accent

Items.db = nil
Items.slots = {}   -- pooled buttons, keyed bag..":"..slot

-- per-grid per-bag holders: the template pulls the bag id from
-- parent:GetID()
Items.holders = setmetatable({}, { __mode = "k" })
local function Holder(host, bag)
	local list = Items.holders[host]
	if not list then list = {} Items.holders[host] = list end
	local h = list[bag]
	if not h then
		h = CreateFrame("Frame", nil, host)
		h:SetSize(1, 1)
		h:SetPoint("TOPLEFT", host, "TOPLEFT", 0, 0)
		h:SetID(bag)
		h:Show()
		list[bag] = h
	end
	return h
end

local function ItemName(link)
	if type(link) ~= "string" then return "" end
	return (link:match("%[(.-)%]")) or link
end

-- slot painting ---------------------------------------------------------------
-- view config comes from the button's window (bags.* vs bank.*)
function Items.Paint(b, info)
	local db = b.view or Items.db
	b.icon:SetTexture(nil)
	b.icon:SetDesaturated(false)
	-- icon fields can be numbers, texture paths or secret values on this
	-- client; even evaluating them can throw, so read+apply stays inside
	-- one pcall. Anything unreadable leaves a clean empty slot, not a
	-- stale icon from the previous occupant.
	pcall(function()
		local icon = info and info.iconFileID
		if icon == nil then icon = info and info.icon end
		if icon ~= nil then b.icon:SetTexture(icon) end
		b.icon:SetDesaturated(info and info.isLocked == true)
	end)

	-- quality edge: uncommon (2) and up only - colouring Common (1)
	-- too paints a plain white box around most of the inventory
	local q = info and (info.quality)
	if type(q) ~= "number" or S.IsSecret(q) then q = nil end
	if db.qualityBorder and q and q >= 2 then
		local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
		if c then b:SetBackdropBorderColor(c.r, c.g, c.b, 0.95)
		else b:SetBackdropBorderColor(0.16, 0.18, 0.25, 0.9) end
	else
		b:SetBackdropBorderColor(0.16, 0.18, 0.25, 0.9)
	end

	-- stack count
	local n = info and info.stackCount
	if type(n) == "number" and not S.IsSecret(n) and n > 1 then
		b.count:SetText(n > 999 and math.floor(n / 1000) .. "k" or n)
	else b.count:SetText("") end

	-- item level on gear
	local ilvl = ""
	if db.showIlvl and info and info.hyperlink
		and not S.IsSecret(info.hyperlink) then
		local ok, v = pcall(C_Item and C_Item.GetDetailedItemLevelInfo
			or GetDetailedItemLevelInfo, info.hyperlink)
		if ok and type(v) == "number" and v > 1 then
			-- only gear gets the number: classID 2 = weapon, 4 = armor.
			-- GetItemInfo's return order on this client doesn't put a
			-- reliable equip-slot string at #9, which stamped ilvls on
			-- trade goods too; GetItemInfoInstant is the stable source.
			local _, _, _, _, _, classID = pcall(
				C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant,
				info.hyperlink)
			if classID == 2 or classID == 4 then
				-- fractional levels (15.15) read like a colon at slot size
				ilvl = math.floor(v + 0.5)
			end
		end
	end
	b.ilvl:SetText(ilvl)

	-- junk mark
	b.junk:SetShown(db.showJunkIcon and q == 0)

	-- cooldown wheel: raw values (possibly secret) into the C helper
	if b.cd and C_Container and C_Container.GetContainerItemCooldown
		and CooldownFrame_Set then
		pcall(function()
			local start, dur, en = C_Container.GetContainerItemCooldown(
				b.bag, b.slot)
			CooldownFrame_Set(b.cd, start, dur, en)
		end)
	end

	-- search dim
	b.searchText = info and ItemName(info.hyperlink):lower() or ""
end

function Items.SetDimmed(b, dim)
	b:SetAlpha(dim and 0.18 or 1)
end

-- clicks: none of our own - the template's OnClick is the game's trusted
-- handler and covers pickup, use, sell, bank moves, splits and
-- link/dressup by itself.

local function Tip(b)
	GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
	local ok = pcall(GameTooltip.SetBagItem, GameTooltip, b.bag, b.slot)
	if not ok and b.info and b.info.hyperlink then
		pcall(GameTooltip.SetHyperlink, GameTooltip, b.info.hyperlink)
	end
	GameTooltip:Show()
end

-- slot factory ----------------------------------------------------------------
function Items.Get(bag, slot, host)
	local key = bag .. ":" .. slot
	local b = Items.slots[key]
	if b then
		if host then
			b:SetParent(Holder(host, bag))
			b.ownerGrid = host
		end
		return b
	end
	-- ItemButton class, not Button: the mixin click logic (pickup, use,
	-- sell, split, link) lives on the class on this client - a plain
	-- Button gets the template's look but not its behavior.
	b = CreateFrame("ItemButton", "SentiUIBag_" .. bag .. "_" .. slot,
		host and Holder(host, bag) or nil,
		"ContainerFrameItemButtonTemplate, BackdropTemplate")
	b:SetID(slot)
	b:SetSize(34, 34) -- Layout resizes every pass anyway

	-- kill the template's own chrome; the flat Sentinel look goes on top.
	-- The template's iconTexture and Count are kept and driven directly.
	if b.GetNormalTexture then
		local t = b:GetNormalTexture()
		if type(t) == "table" and t.SetAlpha then t:SetAlpha(0) end
	end
	for _, k in ipairs({ "IconBorder", "ItemSlotBackground", "Stock",
		"iconQuestTexture", "QuestIcon", "NewItemTexture", "flash",
		"BattlepayItemTexture", "JunkIcon", "UpgradeIcon" }) do
		local t = b[k]
		if type(t) == "table" and t.SetAlpha then t:SetAlpha(0) end
	end
	b:SetBackdrop({
		bgFile = BLANK, edgeFile = BLANK, edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	b:SetBackdropColor(0.06, 0.07, 0.10, 0.85)
	b:SetBackdropBorderColor(0.16, 0.18, 0.25, 0.9)
	-- clicks stay untouched: the template registered and handles them

	-- own icon texture on top; the template's iconTexture stays empty
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetPoint("TOPLEFT", 2, -2)
	b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
	b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	-- the template's cooldown wheel, driven in Paint
	b.cd = b.cooldown or b.Cooldown
	if not b.cd then
		for i = 1, select("#", b:GetChildren()) do
			local c = select(i, b:GetChildren())
			if c and c.IsObjectType and c:IsObjectType("Cooldown") then
				b.cd = c
				break
			end
		end
	end

	local raised = CreateFrame("Frame", nil, b)
	raised:SetAllPoints()
	raised:SetFrameLevel(b:GetFrameLevel() + 4)

	b.count = S.Font(raised, 10, nil, "OUTLINE")
	b.count:SetJustifyH("RIGHT")
	b.count:SetPoint("BOTTOMRIGHT", raised, "BOTTOMRIGHT", -2, 1)

	b.ilvl = S.Font(raised, 9, nil, "OUTLINE")
	b.ilvl:SetJustifyH("LEFT")
	b.ilvl:SetPoint("BOTTOMLEFT", raised, "BOTTOMLEFT", 3, 1)

	b.junk = raised:CreateTexture(nil, "OVERLAY")
	b.junk:SetSize(10, 10)
	b.junk:SetPoint("TOPLEFT", raised, "TOPLEFT", 2, -2)
	b.junk:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
	b.junk:Hide()

	-- hover sheen
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints(b.icon)
	hl:SetColorTexture(1, 1, 1, 0.10)

	b.bag, b.slot = bag, slot
	-- the modern mixin reads self.BagID/self.SlotID (parent GetID was the
	-- old path); without them its pickup/drag runs on a nil bag
	b.BagID, b.SlotID = bag, slot
	-- drag-pickup fallback: if the template's OnDragStart does not fire
	-- on this client, this still lifts the item so it can be moved or
	-- thrown out; a real pickup on the cursor first keeps it single
	b:RegisterForDrag("LeftButton")
	b:HookScript("OnDragStart", function(self)
		-- runs after the template: only picks up if nothing did
		if GetCursorInfo() then return end
		if C_Container and C_Container.PickupContainerItem then
			pcall(C_Container.PickupContainerItem, self.bag, self.slot)
		end
	end)
	b:SetScript("OnEnter", Tip)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	Items.slots[key] = b
	return b
end
