-- luacheck: read globals GameTooltip GetItemInfo C_Item C_TradeSkillUI
-- luacheck: read globals ChatEdit_InsertLink ChatFrame_InsertLink IsShiftKeyDown
-- luacheck: read globals GetServerTime
local _, ns = ...

-- Recipes page: search every captured profession recipe across all
-- characters. Recipe lists are harvested while a profession window is
-- open (GetAllRecipeIDs only covers the visible tradeskill), so the
-- data is per-character and only as fresh as the last window visit.
-- Hovering a row shows the item/recipe tooltip; shift-click posts the
-- recipe link into chat.
local L = ns.L
local UI = ns.UI
local W = ns.Widgets
local Store = ns.Store

-- strtrim is a FrameXML global and not guaranteed on this client.
local strtrim = strtrim or function(s)
	return (tostring(s or ""):match("^%s*(.-)%s*$"))
end

local PAD = 12
local ROW_H = 34
local MAX_RESULTS = 300

local QUALITY_COLOR = {}
local function QualityHex(q)
	if q == nil then
		return "ffffffff"
	end
	if not QUALITY_COLOR[q] then
		local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
		-- c.hex is a full escape ("|cff1eff00") - callers embed it in
		-- "|c%s...|r", so keep only the 8 hex digits.
		QUALITY_COLOR[q] = c and c.hex
			and (c.hex:match("^|c(%x%x%x%x%x%x%x%x)") or c.hex) or "ffffffff"
	end
	return QUALITY_COLOR[q]
end

-- Quality from an item/enchant hyperlink; nil when the link does not
-- resolve to an item (enchant recipes only carry a spell link).
local function LinkQuality(link)
	if not link or not GetItemInfo then
		return nil
	end
	local ok, _, _, q = pcall(GetItemInfo, link)
	if ok and type(q) == "number" then
		return q
	end
end

-- "4x Coarse Thread" colored by how much the logged-in character owns.
local function MatText(m)
	local name = Store.ItemName(m.i)
	local need = m.n or 1
	local have = 0
	if C_Item and C_Item.GetItemCount then
		local ok, n = pcall(C_Item.GetItemCount, m.i, true)
		have = (ok and tonumber(n)) or 0
	end
	local color = have >= need and "ff4dd25d" or "ffe04d4d"
	return ("|c%s%dx %s|r"):format(color, need, name or ("#" .. m.i))
end

local function Build(content)
	local page = {}
	local query = ""
	local charFilter

	local panel = W.Panel(content)
	panel:SetPoint("TOPLEFT", 10, -10)
	panel:SetPoint("BOTTOMRIGHT", -10, 10)

	local header = W.Text(panel, "GameFontNormal", W.GOLD)
	header:SetPoint("TOPLEFT", PAD, -PAD)
	header:SetText(L.RECIPE_TITLE)

	local hint = W.Text(panel, "GameFontDisableSmall", W.MUTED)
	hint:SetPoint("LEFT", header, "RIGHT", 10, 0)
	hint:SetPoint("RIGHT", -PAD, 0)
	hint:SetJustifyH("LEFT")
	hint:SetText(L.RECIPE_HINT)

	local search = W.SearchBox(panel, 220, L.RECIPE_PLACEHOLDER, function(text)
		query = text or ""
		page:Refresh()
	end)
	search:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)

	local dropdown = W.Dropdown(panel, 160, function()
		local out = { { value = false, label = L.SEARCH_ALL_CHARS } }
		for _, key in ipairs(Store.CharKeys()) do
			out[#out + 1] = { value = key, label = ns.ShortName(key) }
		end
		return out
	end, function()
		return charFilter or false
	end, function(value)
		charFilter = value or nil
		page:Refresh()
	end)
	dropdown:SetPoint("LEFT", search, "RIGHT", 10, 0)

	local stats = W.Text(panel, "GameFontDisableSmall", W.MUTED)
	stats:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)

	local scroll, holder = W.ScrollArea(panel)
	scroll:SetPoint("TOPLEFT", PAD, -64)
	scroll:SetPoint("BOTTOMRIGHT", -PAD - 8, PAD)

	local empty = W.Text(panel, "GameFontDisable")
	empty:SetPoint("CENTER")
	empty:SetWidth(460)
	empty:SetJustifyH("CENTER")
	empty:SetText(L.RECIPE_EMPTY)

	local pool = {}
	local used = 0
	local function Row()
		used = used + 1
		local row = pool[used]
		if not row then
			row = CreateFrame("Button", nil, holder, "BackdropTemplate")
			row:SetHeight(ROW_H)
			row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8",
				edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
			row:SetBackdropColor(W.BG_INSET[1], W.BG_INSET[2], W.BG_INSET[3], 0.6)
			row:SetBackdropBorderColor(0, 0, 0, 0)
			row:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
			row:GetHighlightTexture():SetVertexColor(0.92, 0.68, 0.20, 0.06)
			row:RegisterForClicks("AnyUp")
			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetSize(24, 24)
			row.icon:SetPoint("LEFT", 5, 0)
			row.name = W.Text(row, "GameFontHighlight", W.TEXT)
			row.name:SetPoint("TOPLEFT", 34, -4)
			row.name:SetPoint("RIGHT", -90, 0)
			row.name:SetJustifyH("LEFT")
			row.name:SetWordWrap(false)
			row.mats = W.Text(row, "GameFontDisableSmall", W.MUTED)
			row.mats:SetPoint("TOPLEFT", 34, -18)
			row.mats:SetPoint("RIGHT", -90, 0)
			row.mats:SetJustifyH("LEFT")
			row.mats:SetWordWrap(false)
			row.prof = W.Text(row, "GameFontDisableSmall", W.MUTED)
			row.prof:SetPoint("RIGHT", -8, 0)
			row.prof:SetJustifyH("RIGHT")
			row.prof:SetWidth(80)
			row.prof:SetWordWrap(false)
			-- Hover: item/recipe tooltip; shift-click posts the link.
			row:SetScript("OnEnter", function(self)
				if self.link then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetHyperlink(self.link)
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			row:SetScript("OnClick", function(self)
				if self.link and IsShiftKeyDown() then
					local insert = ChatEdit_InsertLink or ChatFrame_InsertLink
					if insert then
						insert(self.link)
					end
				end
			end)
			pool[used] = row
		end
		row:Show()
		return row
	end

	-- Owner names, class-colored. A gold "✓" marks characters whose
	-- stored bag/bank snapshot already covers every required material.
	local function OwnerText(e)
		local parts = {}
		for _, key in ipairs(e.owners) do
			local char = ns.db.chars[key]
			local color = char and char.class and W.ClassColorHex(char.class) or "ffffffff"
			local ready = e.mats and Store.CanCraftNow(key, e.mats)
			parts[#parts + 1] = ("|c%s%s|r%s"):format(color, ns.ShortName(key),
				ready and " |cff4dd25d✓|r" or "")
		end
		table.sort(parts)
		return table.concat(parts, "  ")
	end

	function page:Refresh()
		used = 0
		for _, row in ipairs(pool) do
			row:Hide()
		end
		local q = strtrim(query):lower()
		-- Active profession cooldowns of the logged-in character, by
		-- tradeskill name - marks rows that are still on cooldown.
		local cdByName = {}
		for _, cd in ipairs(Store.ProfCooldowns(Store.OwnKey() or "")) do
			cdByName[cd.n] = cd.x
		end
		local owners = Store.RecipeOwners()
		local list = {}
		for _, e in pairs(owners) do
			local include = (q == "" or (e.name and e.name:lower():find(q, 1, true)))
				and (not charFilter)
			if not include and charFilter then
				for _, key in ipairs(e.owners) do
					if key == charFilter then
						include = true
						break
					end
				end
			end
			if include then
				list[#list + 1] = e
			end
		end
		table.sort(list, function(a, b)
			return (a.name or "") < (b.name or "")
		end)
		stats:SetText(#list > 0 and tostring(#list) or "")
		empty:SetShown(#list == 0)
		local width = math.max(100, scroll:GetWidth() - 4)
		local y = 0
		for i, e in ipairs(list) do
			if i > MAX_RESULTS then
				break
			end
			local row = Row()
			row:SetWidth(width)
			row:SetPoint("TOPLEFT", 0, y)
			row.icon:SetTexture(e.icon or 134400)
			local link = e.link
			if not link and C_TradeSkillUI and C_TradeSkillUI.GetRecipeLink then
				local ok, l = pcall(C_TradeSkillUI.GetRecipeLink, e.id)
				link = ok and l or nil
			end
			row.link = link
			local hex = QualityHex(LinkQuality(link))
			local profs = Store.RecipeProfs(e)
			local cdX = e.name and cdByName[e.name]
			row.name:SetText(("|c%s%s|r%s  |cff8c919f%s|r"):format(hex,
				e.name or ("#" .. e.id),
				cdX and (" |cffebad33⏳ " .. W.Duration(cdX - GetServerTime())
					.. "|r") or "",
				OwnerText(e)))
			if e.mats and #e.mats > 0 then
				local parts = {}
				for _, m in ipairs(e.mats) do
					parts[#parts + 1] = MatText(m)
				end
				row.mats:SetText(table.concat(parts, "  ·  "))
			else
				row.mats:SetText("")
			end
			row.prof:SetText(profs[1] or "")
			y = y - ROW_H - 2
		end
		holder:SetHeight(math.max(1, -y))
	end

	return page
end

UI.RegisterPage(9, L.TAB_RECIPES, Build)
