-- Tooltip skin: the game's own art is alpha'd out (never Hide() - hiding a
-- shared tooltip from addon code taints its handlers), the tooltip itself
-- gets the flat Sentinel backdrop and the Sentinel font family on every
-- FontString. Border tinting is just SetBackdropBorderColor.
local _, ns = ...
local S = SentiUI

local Skin = {}
ns.Skin = Skin

local BLANK = S.media.blank
local TIP_EDGE = S.Tex and S.Tex("TooltipEdge")
local BACKDROP = TIP_EDGE
	and { bgFile = BLANK, edgeFile = TIP_EDGE, edgeSize = 16,
		insets = { left = 2, right = 2, top = 2, bottom = 2 } }
	or  { bgFile = BLANK, edgeFile = BLANK, edgeSize = 1 }

local skinned = setmetatable({}, { __mode = "k" })

-- tooltip names the game (and most addons) use
Skin.NAMED = {
	"GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
	"ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2",
	"EmbeddedItemTooltip", "BuffFrameTooltip",
}

local function StyleFont(fs)
	if fs.__sentiTipFont then return end
	local ok, _, size, flags = pcall(fs.GetFont, fs)
	size = (ok and type(size) == "number" and size) or 11
	if type(flags) ~= "string" then flags = "" end
	S.ApplyFont(fs, nil, size, flags)
	fs.__sentiTipFont = true
end

function Skin.Fonts(tip)
	for _, r in ipairs({ tip:GetRegions() }) do
		if type(r) == "table" and r.IsObjectType and r:IsObjectType("FontString") then
			StyleFont(r)
		end
	end
end

function Skin.SetBorder(tip, r, g, b)
	if tip.SetBackdropBorderColor then
		pcall(tip.SetBackdropBorderColor, tip, r, g, b, 1)
	elseif tip.__sentiShell then
		pcall(tip.__sentiShell.SetBackdropBorderColor, tip.__sentiShell, r, g, b, 1)
	end
end

-- the shared panel border is #222838 - invisible on a dark tooltip over a
-- dark world, which reads as "the right edge is missing". Tooltips get a
-- lifted steel edge that stays visible everywhere; class/quality tints
-- still override it per-tip
local TIP_BORDER = { r = 0.32, g = 0.36, b = 0.47 }

function Skin.ResetBorder(tip)
	Skin.SetBorder(tip, TIP_BORDER.r, TIP_BORDER.g, TIP_BORDER.b)
end

-- the gold top edge can take the unit/quality color; rgb may be secret
-- numbers - SetVertexColor accepts them raw
function Skin.SetAccent(tip, r, g, b)
	local e = tip.__sentiEdge
	if type(e) == "table" and e.SetVertexColor then
		pcall(e.SetVertexColor, e, r, g, b, 0.95)
	end
end

function Skin.ResetAccent(tip)
	local a = S.colors.accent
	Skin.SetAccent(tip, a.r, a.g, a.b)
end

function Skin.Tip(tip)
	if type(tip) ~= "table" or skinned[tip] then return end
	skinned[tip] = true

	-- kill the game's own art; alpha, not Hide. Only BACKGROUND/BORDER
	-- layer textures: artwork regions are embedded icons (item, money)
	-- and must stay
	local ns9 = tip.NineSlice
	if type(ns9) == "table" and ns9.SetAlpha then pcall(ns9.SetAlpha, ns9, 0) end
	for _, r in ipairs({ tip:GetRegions() }) do
		if type(r) == "table" and r.IsObjectType and r:IsObjectType("Texture") then
			local ok, layer = pcall(r.GetDrawLayer, r)
			-- a secret layer value cannot be compared (throws) - skip
			-- classification for it rather than alpha-ing a possible icon
			if ok and not S.IsSecret(layer)
				and (layer == "BACKGROUND" or layer == "BORDER") then
				pcall(r.SetAlpha, r, 0)
			end
		end
	end

	if tip.SetBackdrop then
		tip:SetBackdrop(BACKDROP)
		local c = S.colors
		tip:SetBackdropColor(c.bg.r, c.bg.g, c.bg.b, c.bg.a)
		Skin.ResetBorder(tip)
	else
		-- oddball tooltip without backdrop support: give it a shell child
		local shell = CreateFrame("Frame", nil, tip, "BackdropTemplate")
		shell:SetAllPoints()
		shell:SetFrameLevel(1)
		shell:SetBackdrop(BACKDROP)
		local c = S.colors
		shell:SetBackdropColor(c.bg.r, c.bg.g, c.bg.b, c.bg.a)
		shell:SetBackdropBorderColor(TIP_BORDER.r, TIP_BORDER.g, TIP_BORDER.b, 1)
		tip.__sentiShell = shell
	end

	-- Sentinel signature: the gold edge line across the top
	if tip.CreateTexture and not tip.__sentiEdge then
		local edge = tip:CreateTexture(nil, "OVERLAY")
		edge:SetTexture(BLANK)
		local a = S.colors.accent
		edge:SetVertexColor(a.r, a.g, a.b, 0.9)
		edge:SetHeight(1)
		edge:SetPoint("TOPLEFT", tip, "TOPLEFT", 1, -1)
		edge:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -1, -1)
		tip.__sentiEdge = edge
	end

	Skin.Fonts(tip)
end

-- the client sizes the tip before our post-call lines/rewrites land, so a
-- line we touched (or the wider SentiUI font) can outgrow the frame: text
-- then draws over the right border, which reads as "the frame is cut off".
-- Measure the real line widths and grow the frame to fit; the game's own
-- next layout pass shrinks it again when the content needs less.
function Skin.Reflow(tip)
	if not (tip and tip.GetNumLines and tip.SetWidth) then return end
	local name = tip.GetName and tip:GetName()
	if type(name) ~= "string" then return end
	local need = 0
	for i = 1, tip:NumLines() or 0 do
		local w = 0
		for _, side in ipairs({ "TextLeft", "TextRight" }) do
			local fs = _G[name .. side .. i]
			local ok, sw = pcall(function()
				return fs and fs.GetStringWidth and fs:GetStringWidth()
			end)
			if ok and type(sw) == "number" and not S.IsSecret(sw) then
				w = w + sw + (w > 0 and 8 or 0)
			end
		end
		if w > need then need = w end
	end
	if need <= 0 then return end
	-- side inset the client puts around its text columns
	local pad = 24
	local okp, lp, rp = pcall(function()
		return tip.GetPadding and tip:GetPadding()
	end)
	if okp then
		lp = type(lp) == "number" and not S.IsSecret(lp) and lp or 0
		rp = type(rp) == "number" and not S.IsSecret(rp) and rp or 0
		if lp + rp > 0 then pad = lp + rp + 4 end
	end
	need = need + pad
	local okc, cur = pcall(tip.GetWidth, tip)
	if okc and type(cur) == "number" and not S.IsSecret(cur)
		and need > cur + 0.5 then
		pcall(tip.SetWidth, tip, need)
	end
end

function Skin.All()
	for _, name in ipairs(Skin.NAMED) do
		local tip = _G[name]
		if type(tip) == "table" then Skin.Tip(tip) end
	end
end

-- tooltips the skin claims: the game's shared family only. Third-party
-- addon tooltips draw their own art (often on BACKGROUND layers or as
-- WHITE8X8 fills) - running the chrome kill / blank-icon sweep on them
-- erased the tip entirely, which is why other addons' tooltips broke.
local TIP_PREFIX = { "GameTooltip", "ItemRef", "ShoppingTooltip",
	"ItemRefShoppingTooltip", "EmbeddedItemTooltip", "BuffFrameTooltip" }
function Skin.IsOurs(tip)
	local name = type(tip) == "table" and tip.GetName and tip:GetName()
	if type(name) ~= "string" then return false end
	for _, p in ipairs(TIP_PREFIX) do
		if name:sub(1, #p) == p then return true end
	end
	return false
end

-- a tooltip created later shows up through the post-calls; skin it on
-- first sight
function Skin.Ensure(tip)
	if type(tip) == "table" and tip.GetObjectType
		and tip:GetObjectType() == "GameTooltip" and Skin.IsOurs(tip) then
		Skin.Tip(tip)
	end
end

-- Blank-icon guard: tooltips embed ARTWORK textures for item/spell icons.
-- When the icon path cannot be resolved (failed atlas lookup, nil from
-- GetItemIcon, unregistered spell icon) the region draws as the WHITE8X8
-- fallback or stays un-textured — both appear as a bright white square on
-- the dark panel. Scan ARTWORK textures in the tip: hide any that are
-- using WHITE8X8 or have no texture set, as long as they are large enough
-- to be an icon slot (>= 8px) and are not our own overlay accent line
-- (which lives on OVERLAY, not ARTWORK, so it passes this filter safely).
function Skin.FixBlankIcons(tip)
	if type(tip) ~= "table" or not tip.GetRegions then return end
	for _, r in ipairs({ tip:GetRegions() }) do
		if type(r) == "table" and r.IsObjectType
			and r:IsObjectType("Texture") then
			local okL, layer = pcall(r.GetDrawLayer, r)
			if okL and not S.IsSecret(layer) and layer == "ARTWORK" then
				local okT, path = pcall(r.GetTexture, r)
				if not okT or S.IsSecret(path) then
					-- can't inspect: leave it alone
				else
					local isBlank = (path == nil or path == "")
						or (type(path) == "string"
							and (path:find("WHITE8X8")
								or path:find("white8x8")))
					if isBlank then
						local okW, w = pcall(r.GetWidth, r)
						local okH, h = pcall(r.GetHeight, r)
						-- only icon-sized regions: tiny structural
						-- spacers (< 8px) are left untouched
						if okW and okH
							and not S.IsSecret(w) and not S.IsSecret(h)
							and type(w) == "number" and type(h) == "number"
							and w >= 8 and h >= 8 then
							pcall(r.SetAlpha, r, 0)
						end
					end
				end
			end
		end
	end
end
