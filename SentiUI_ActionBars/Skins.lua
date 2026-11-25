-- Skins for the Blizzard leftovers SentiUI does not replace: the frames
-- that ride our movers (TalkingHead, mirror timers, alerts, vehicle
-- seats, the durability doll, the ghost button), the standalone dialogs
-- (ESC menu, confirm popups, ready check, item text, chat config, stack
-- split), the menus and toasts (dropdowns, Battle.net toasts, queue and
-- ticket status), the banner texts, the large screen texts (zone
-- announcements, raid warnings, boss emotes), lazy-content containers
-- (alert toasts, top-center/below-minimap widgets, battleground timer
-- bars) and the opt-in Cooldown Manager viewers.
local _, ns = ...
local S = SentiUI
local L = ns.L
local SetFont = ns.SetFont
local Call = ns.Call

local ipairs, pairs, type = ipairs, pairs, type
local unpack = unpack or table.unpack
local CreateFrame = CreateFrame

local BLANK = "Interface\\Buttons\\WHITE8X8"
local ACC = S.colors.accent

local Skins = {}
ns.Skins = Skins

local db

-- forbidden objects (TradeFrame, StoreFrame on this client) refuse EVERY
-- access - GetRegions/GetName throw "Attempt to access forbidden object".
-- Probe once and cache: skinning must leave them fully alone instead of
-- erroring through SafeCall on every open.
local function IsForbidden(f)
	if f._sentiForbidden ~= nil then return f._sentiForbidden end
	-- a forbidden object refuses EVERY access, but the refusal is
	-- per-method on this client: probe both walks, one clean pass
	-- is not proof the other is allowed
	local ok = pcall(f.GetRegions, f)
	if ok and f.GetChildren then ok = pcall(f.GetChildren, f) end
	f._sentiForbidden = not ok
	return f._sentiForbidden
end

-- generic chrome kill: hide the usual Blizzard border/backdrop regions on
-- a frame's children, then wrap the frame in our rounded panel look
local function StripChrome(frame)
	if IsForbidden(frame) then return end
	for _, r in ipairs({ frame:GetRegions() }) do
		if type(r) == "table" and r.GetDrawLayer and r.Hide then
			local okL, layer = Call("layer", r.GetDrawLayer, r)
			if okL and not S.IsSecret(layer) then
				-- keep textures that carry real content (portrait etc.):
				-- TalkingHead keeps its model ring, the rest fades
				local okN, n = Call("texname", r.GetName, r)
				local name = okN and n or nil
				local content = name and (name:find("Icon")
					or name:find("icon") or name:find("Portrait"))
				if not content then
					-- border art also lives on ARTWORK in some windows
					-- (the ornate frame edge on the LFG finder), so
					-- border-named artwork fades too - unnamed artwork
					-- stays because it might be content
					local chromeArt = layer == "ARTWORK" and name
						and (name:find("Border") or name:find("Bg$")
							or name:find("TopTileStreaks")
							or name:find("Background"))
					if layer == "BACKGROUND" or layer == "BORDER"
						or chromeArt then
						Call("region:alpha", r.SetAlpha, r, 0.15)
					end
				end
			end
		end
	end
end

local function SkinPanelish(frame)
	if not frame or frame._sentiSkinned or IsForbidden(frame) then return end
	frame._sentiSkinned = true
	StripChrome(frame)
	-- the window's own backdrop edge counts as chrome too: modern
	-- frames draw the border through BackdropTemplateMixin, not
	-- regions - clear it or the frame edge survives the fade
	if frame.SetBackdrop then
		Call("win:bd", frame.SetBackdrop, frame, nil)
	end
	-- dark background panel: "raised" style gives the gold tint border
	-- that every Sentinel window carries via the backdrop system
	if not frame._sentiBg then
		local bg = CreateFrame("Frame", nil, frame)
		bg:SetAllPoints()
		bg:SetFrameLevel(math.max(0, frame:GetFrameLevel() - 1))
		S.Template(bg, "raised")
		bg._sentiBg = true
		frame._sentiBg = bg
	end
	-- gold accent edge overlay: four 1px strips corner-to-corner on all
	-- sides (no arc offsets — clean square corners, top line strongest)
	if not frame._sentiEdge then
		local e = CreateFrame("Frame", nil, frame)
		e:SetAllPoints()
		e:SetFrameLevel((frame:GetFrameLevel() or 1) + 3)
		e._sentiEdge = true
		local function Strip(p1, p2, horizontal, alpha)
			local t = e:CreateTexture(nil, "OVERLAY")
			t:SetTexture(BLANK)
			t:SetVertexColor(ACC.r, ACC.g, ACC.b, alpha)
			if horizontal then
				t:SetPoint(p1)
				t:SetPoint(p2)
				t:SetHeight(1)
			else
				t:SetPoint(p1)
				t:SetPoint(p2)
				t:SetWidth(1)
			end
		end
		Strip("TOPLEFT",    "TOPRIGHT",    true,  0.85)
		Strip("BOTTOMLEFT", "BOTTOMRIGHT", true,  0.45)
		Strip("TOPLEFT",    "BOTTOMLEFT",  false, 0.45)
		Strip("TOPRIGHT",   "BOTTOMRIGHT", false, 0.45)
		frame._sentiEdge = e
	end
end

-- font pass: swap a frame's fontstrings to the SentiUI font. Blizzard
-- dialog text is painted black for parchment - and it stays black here
-- (like the parchment originals), but on the dark panel it needs a
-- hairline of contrast: a 1px white shadow peeking out bottom-right
-- lifts the dark glyphs without flashing a full outline. Colored
-- strings (quality, links, headers) keep their role color. Explicit
-- r,g,b pins a color and skips the check.
local function RestyleFonts(frame, size, r, g, b)
	-- forbidden objects refuse every access - this check also stops the
	-- recursion below from walking into a forbidden child frame
	if IsForbidden(frame) then return end
	for _, rgn in ipairs({ frame:GetRegions() }) do
		if type(rgn) == "table" and rgn.GetObjectType
			and rgn:GetObjectType() == "FontString" then
			-- no OUTLINE flag: the thick black stroke reads as a heavy
			-- black border on our dark panel — WoW quest/gossip fonts
			-- carry their own subtle shadow and read cleanly without it
			SetFont(rgn, size or 12)
			if r then
				Call("col", rgn.SetTextColor, rgn, r, g, b)
			else
				local ok, cr, cg, cb = Call("tcol", rgn.GetTextColor, rgn)
				-- threshold 0.52: catches pure black (0), near-black browns
				-- (#3f2f10 → 0.21) and the parchment mid-tone used by
				-- WoW's QuestFont/GossipFont objects (~0.45) - all of
				-- which read as illegible dark text on our near-black panel
				local dark = ok and type(cr) == "number" and type(cg) == "number"
					and type(cb) == "number" and not S.IsSecret(cr)
					and not S.IsSecret(cg) and not S.IsSecret(cb)
					and cr * 0.30 + cg * 0.59 + cb * 0.11 < 0.52
				if not dark then
					-- the vertex color can read white while the FONT
					-- OBJECT itself carries parchment black (gossip
					-- and quest body fonts): check that too
					local fo = rgn.GetFontObject and rgn:GetFontObject()
					if type(fo) == "table" and fo.GetTextColor then
						local okF, fr, fg, fb = pcall(fo.GetTextColor, fo)
						dark = okF and type(fr) == "number"
							and type(fg) == "number" and type(fb) == "number"
							and not S.IsSecret(fr) and not S.IsSecret(fg)
							and not S.IsSecret(fb)
							and fr * 0.30 + fg * 0.59 + fb * 0.11 < 0.52
					end
				end
				if dark then
					-- near-black fill (not pure void so it keeps a hair of
					-- warmth) + tiny white rim from a 1px offset shadow
					Call("col", rgn.SetTextColor, rgn, 0.10, 0.09, 0.08)
					if rgn.SetShadowColor then
						pcall(rgn.SetShadowColor, rgn, 1, 1, 1, 0.85)
					end
					if rgn.SetShadowOffset then
						pcall(rgn.SetShadowOffset, rgn, 1, -1)
					end
				end
			end
		end
	end
	for _, c in ipairs({ frame:GetChildren() }) do
		if type(c) == "table" and c.GetRegions then
			RestyleFonts(c, size, r, g, b)
		end
	end
end

-- fade every texture region of a frame: used for dialog buttons whose
-- wood texture we replace with the raised template, and for modern
-- border art that lives in sub-frames (NineSlice/Border) not regions
local function FadeTextures(f, alpha)
	if IsForbidden(f) then return end
	for _, r in ipairs({ f:GetRegions() }) do
		if type(r) == "table" and r.GetObjectType and r.SetAlpha then
			local okT, ot = Call("otype", r.GetObjectType, r)
			if okT and ot == "Texture" then
				Call("fade", r.SetAlpha, r, alpha)
			end
		end
	end
end

local function HideSubChrome(f)
	if IsForbidden(f) then return end
	for _, key in ipairs({ "NineSlice", "Border" }) do
		local sub = f[key]
		if type(sub) == "table" and sub.GetRegions then
			FadeTextures(sub, 0)
		end
	end
	-- modern windows draw their chrome as named child frames, not
	-- frame fields: *NineSlice, *Border, *Inset, *Bg, *TopTileStreaks.
	-- Fade them too; actual content (portraits, icons) lives in
	-- differently named children. Insets carry their border via the
	-- backdrop mixin, not texture regions - clear that too or the
	-- frame edge survives the fade.
	for _, c in ipairs({ f:GetChildren() }) do
		if type(c) == "table" and c.GetName and c.GetRegions then
			-- silent pcall: protected children inside windows are
			-- routine (a forbidden GetName must not spam the chat
			-- every open)
			local okN, n = pcall(c.GetName, c)
			if okN and type(n) == "string" and not S.IsSecret(n)
				and (n:find("NineSlice") or n:find("Border")
					or n:find("Inset") or n:find("Bg$")
					or n:find("TopTileStreaks")) then
				FadeTextures(c, 0)
				if c.SetBackdrop then
					Call("chrome:bd", c.SetBackdrop, c, nil)
				end
				for _, g in ipairs({ c:GetChildren() }) do
					if type(g) == "table" and g.GetRegions
						and pcall(g.GetRegions, g) then
						FadeTextures(g, 0)
					end
				end
			end
		end
	end
end

-- chrome kill at every depth below a window: only touches children
-- NAMED like chrome (*NineSlice/*Border/*Inset/*Bg/*TopTileStreaks),
-- so content frames pass through untouched. Skips our own injected
-- panel and edge frames.
local function ReHideDeep(f)
	if IsForbidden(f) then return end
	for _, c in ipairs({ f:GetChildren() }) do
		if type(c) == "table" and c.GetChildren
			and not c._sentiBg and not c._sentiEdge
			and pcall(c.GetChildren, c) then
			HideSubChrome(c)
			ReHideDeep(c)
		end
	end
end

-- every open rebuilds the window chrome: the game re-shows NineSlice
-- children, repaints region alphas and re-applies its backdrops, which
-- flipped styled windows back to wood mid-session. Re-kill all of it on
-- every show - `deep` recurses the named-chrome sweep for real dialogs.
local function ReapplyChrome(f, deep)
	if IsForbidden(f) then return end
	StripChrome(f)
	if f.SetBackdrop then
		Call("win:bd", f.SetBackdrop, f, nil)
	end
	HideSubChrome(f)
	if deep then ReHideDeep(f) end
end

-- a button carries real picture content when its name or any texture
-- region reads icon/spell/item/slot/portrait, or the button object
-- exposes an icon field. Those keep their art (fading would erase
-- the icon) and only get the font pass.
local function IsIconish(c, name)
	if name:find("Item") or name:find("Icon") or name:find("Slot")
		or name:find("Attachment") or name:find("Spell")
		or name:find("Glyph") or name:find("Portrait") then
		return true
	end
	if c.icon or c.Icon or c.ItemIcon or c.iconTexture
		or c.spellTexture then
		return true
	end
	for _, r in ipairs({ c:GetRegions() }) do
		if type(r) == "table" and r.GetName then
			local okN, rn = Call("rname", r.GetName, r)
			if okN and type(rn) == "string" and not S.IsSecret(rn)
				and (rn:find("[Ii]con") or rn:find("Portrait")) then
				return true
			end
		end
	end
	return false
end

-- deep child pass over a styled window: raised buttons, inset edit
-- boxes, chip-styled text tabs, accent thumbs on scrollbars, accent
-- checks on checkboxes and inset dropdown fields - then recursion
-- into nested frames so page buttons and scroll children get styled
-- too. Marker flags keep every widget single-visit.
local function SkinChildren(f)
	if IsForbidden(f) then return end
	for _, c in ipairs({ f:GetChildren() }) do
		if type(c) == "table" and c.GetObjectType then
			-- silent pcall probes: protected children inside windows
			-- are routine - a forbidden object skips quietly instead
			-- of printing "blocked api" every open
			local okT, ot = pcall(c.GetObjectType, c)
			local okN, n = pcall(c.GetName, c)
			local name = (okN and type(n) == "string" and not S.IsSecret(n))
				and n or ""
			if okT and (ot == "Button" or ot == "EditBox"
				or ot == "DropdownButton") then
				-- close buttons keep their art - no glyph without
				-- it - but the X tints accent like the scroll arrows
				if not c._sentiBtn and name:find("Close") then
					c._sentiBtn = true
					for _, r in ipairs({ c:GetRegions() }) do
						if type(r) == "table" and r.GetObjectType
							and r:GetObjectType() == "Texture"
							and r.SetVertexColor then
							Call("close:col", r.SetVertexColor, r,
								ACC.r, ACC.g, ACC.b)
						end
					end
				elseif not c._sentiBtn then
					c._sentiBtn = true
					local iconish = IsIconish(c, name)
					-- deeper guards: real content sits on the ARTWORK
					-- layer (role icons, category banners, activity
					-- tiles) while chrome lives on BACKGROUND/OVERLAY.
					-- And a button without label text but with texture
					-- art is an icon button. Both keep their art - the
					-- fade would have erased the LFG role/activity
					-- icons with neither name nor field to catch them.
					if not iconish and ot == "Button" then
						local fs = c.GetFontString and c:GetFontString()
						local okH, hasLabel = Call("btn:lbl", function()
							local t = fs and fs:GetText()
							return type(t) == "string" and t ~= ""
						end)
						local hasArt = false
						for _, r in ipairs({ c:GetRegions() }) do
							if type(r) == "table" and r.GetObjectType
								and r:GetObjectType() == "Texture" then
								hasArt = true
								local okL, layer = Call("layer",
									r.GetDrawLayer, r)
								if okL and not S.IsSecret(layer)
									and layer == "ARTWORK" then
									iconish = true
									break
								end
							end
						end
						if not iconish and hasArt
							and not (okH and hasLabel) then
							iconish = true
						end
					end
					-- text tabs become raised chips; icon tabs count as
					-- iconish and keep their art
					if not iconish then
						FadeTextures(c, 0)
						-- chrome lives where the region fade cannot
						-- reach: a NineSlice child frame, named
						-- texture/frame fields and chrome child frames
						-- (professions red button face rides one of
						-- those and painted over our fill + border)
						for _, k in ipairs({ "NineSlice", "ButtonTexture",
							"ArtOverlay", "Background", "bg", "Border",
							"ButtonArt", "ButtonBackground",
							"NormalTexture", "PushedTexture",
							"DisabledTexture", "HighlightTexture" }) do
							local sub = c[k]
							if type(sub) == "table" and sub.SetAlpha then
								Call("btn:sub", sub.SetAlpha, sub, 0)
							end
						end
						-- a text button's content is its FontString
						-- label (a region) - child frames are chrome:
						-- alpha them and every texture they carry
						if ot == "Button" then
							for _, g in ipairs({ c:GetChildren() }) do
								if type(g) == "table" and g.SetAlpha then
									Call("btn:kid", g.SetAlpha, g, 0)
									FadeTextures(g, 0)
								end
							end
						end
						-- widget-level state textures: some templates keep
						-- them off GetRegions, so the fade missed them and
						-- a stale normal/pushed face rendered over our fill
						for _, m in ipairs({ "GetNormalTexture",
							"GetPushedTexture", "GetDisabledTexture",
							"GetHighlightTexture" }) do
							if c[m] then
								local okT2, wt = pcall(c[m], c)
								if okT2 and type(wt) == "table" and wt.SetAlpha then
									Call("btn:tex", wt.SetAlpha, wt, 0)
								end
							end
						end
						S.Template(c, ot == "EditBox" and "inset"
							or "raised")
						-- raised skinned buttons get our border-lit
						-- hover like every own widget; art buttons
						-- stay untouched (protected item slots never
						-- carry addon scripts on this client)
						if ot == "Button" and not c._sentiHl
							and c.HookScript then
							c._sentiHl = true
							c:HookScript("OnEnter", function(s2)
								S.SetBorderLit(s2, true)
							end)
							c:HookScript("OnLeave", function(s2)
								S.SetBorderLit(s2, false)
							end)
						end
					end
					RestyleFonts(c, 11)
				end
			elseif okT and ot == "Slider" then
				-- no once-guard: the game repaints its thumb/track and
				-- arrow art on show - re-applying every walk keeps the
				-- gold thumb from flipping back to wood
				FadeTextures(c, 0.35)
				local th = c.GetThumbTexture and c:GetThumbTexture()
				if th and th.SetTexture then
					Call("thumb:tex", th.SetTexture, th,
						(S.Tex and S.Tex("SliderThumb")) or BLANK)
					Call("thumb:col", th.SetVertexColor, th,
						ACC.r, ACC.g, ACC.b)
				end
				-- up/down arrows: keep the glyph (it is the content),
				-- tint it accent so the wooden button look dies
				for _, g in ipairs({ c:GetChildren() }) do
					if type(g) == "table" and g.GetObjectType then
						local okG, got = pcall(g.GetObjectType, g)
						if okG and got == "Button" then
							for _, r in ipairs({ g:GetRegions() }) do
								if type(r) == "table" and r.GetObjectType
									and r:GetObjectType() == "Texture"
									and r.SetVertexColor then
									Call("arrow:col", r.SetVertexColor,
										r, ACC.r, ACC.g, ACC.b)
								end
							end
						end
					end
				end
			elseif okT and ot == "CheckButton" then
				local chkOn = S.Tex and S.Tex("CheckOn")
				local chkOff = S.Tex and S.Tex("CheckEmpty")
				if chkOn and chkOff and c.SetNormalTexture then
					-- real widget art: dark box, gold check
					Call("chk:off", c.SetNormalTexture, c, chkOff)
					Call("chk:on", c.SetCheckedTexture, c, chkOn)
				else
					local t = c.GetCheckedTexture and c:GetCheckedTexture()
					if t and t.SetVertexColor then
						Call("chk:col", t.SetVertexColor, t,
							ACC.r, ACC.g, ACC.b)
					end
				end
			elseif okT and ot == "StatusBar" then
				-- reputation/progress bars inside windows: flat blank
				-- texture keeps the status color, kills the wood fill
				if c.SetStatusBarTexture then
					Call("bar:tex", c.SetStatusBarTexture, c,
						S.media and S.media.blank or BLANK)
				end
				StripChrome(c)
			elseif okT and (ot == "Frame" or ot == "ScrollFrame") then
				-- no once-guard on the descent either: scroll frames and
				-- tab pages spawn their rows lazily, so every show
				-- re-walks the whole tree. The per-widget flags still
				-- keep already-styled children cheap.
				if name:find("DropDown") or name:find("Dropdown") then
					-- dropdown field: fade the pill chrome, keep label
					-- and arrow; descendants stay untouched so the
					-- arrow button never gets the raised template
					FadeTextures(c, 0)
					S.Template(c, "inset")
					RestyleFonts(c, 11)
					for _, g in ipairs({ c:GetChildren() }) do
						if type(g) == "table" then g._sentiBtn = true end
					end
				else
					-- chrome at every depth: nested panels carry their
					-- own NineSlice/Border fields and named inset
					-- children (the AH buy/sell displays, list boxes)
					if not c._sentiBg then HideSubChrome(c) end
					SkinChildren(c)
				end
			end
		end
	end
end

-- one skin for every standalone dialog window: strip the frame art,
-- park our rounded panel behind the content, restyle text, buttons
local function SkinDialog(f)
	if not f or f._sentiSkinned or IsForbidden(f) then return end
	SkinPanelish(f)
	HideSubChrome(f)
	RestyleFonts(f)
	SkinChildren(f)
	-- window title reads in accent gold: region or child-frame text
	-- named *Title* (TitleContainer.TitleText on modern windows)
	local function TintTitle(owner)
		for _, r in ipairs({ owner:GetRegions() }) do
			if type(r) == "table" and r.GetObjectType
				and r:GetObjectType() == "FontString" then
				local okN, n = Call("tname", r.GetName, r)
				if okN and type(n) == "string" and n:find("Title") then
					Call("title:col", r.SetTextColor, r,
						ACC.r, ACC.g, ACC.b)
				end
			end
		end
	end
	TintTitle(f)
	for _, c in ipairs({ f:GetChildren() }) do
		if type(c) == "table" and c.GetRegions
			and pcall(c.GetRegions, c) then TintTitle(c) end
	end
end

-- MailFrame: the body ScrollFrame (MailBody / MailEditBox parent) keeps
-- its parchment texture while the thin EditBox inside gets "inset" -
-- that leaves a black bar floating on orange parchment. SkinMail gives
-- the scroll area itself the dark inset fill and fades the paper.
local function SkinMail(f)
	SkinDialog(f)
	for _, c in ipairs({ f:GetChildren() }) do
		if type(c) == "table" and c.GetObjectType then
			local okT, ot = pcall(c.GetObjectType, c)
			local okN, n = pcall(c.GetName, c)
			local name = okN and type(n) == "string" and n or ""
			if okT and ot == "ScrollFrame" then
				-- match MailBody, MailScrollFrame and any scroll frame
				-- that directly contains an EditBox (the mail body)
				local hit = name:find("MailBody") or name:find("MailScroll")
				if not hit then
					for _, g in ipairs({ c:GetChildren() }) do
						if type(g) == "table" and g.GetObjectType then
							local okG, got = pcall(g.GetObjectType, g)
							if okG and got == "EditBox" then hit = true break end
						end
					end
				end
				if hit then
					FadeTextures(c, 0)
					S.Template(c, "inset")
				end
			end
		end
	end
	-- "Open all" button: drains the inbox one letter at a time on a
	-- ticker - letters leave the list after looting, so index 1 works
	-- until the box is empty
	if not f.sentiOpenAll and _G.InboxFrame and S.Widgets
		and S.Widgets.Button then
		local b = S.Widgets.Button(f, L["Open all"], 72, 18)
		b:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 34)
		b:SetScript("OnClick", function()
			if b._drain then return end
			b._drain = C_Timer.NewTicker(0.35, function(t)
				local n = GetInboxNumItems and GetInboxNumItems() or 0
				if n <= 0 then
					b._drain = nil
					t:Cancel()
					return
				end
				if AutoLootMailItem then
					pcall(AutoLootMailItem, 1)
				else
					pcall(TakeInboxItem, 1)
					pcall(TakeInboxMoney, 1)
				end
			end)
		end)
		f.sentiOpenAll = b
	end
end

-- quest/gossip frames get a gold divider under the header zone so the
-- NPC greeting reads as a titled section, not a floating text block.
-- Y offset -55 lands just below the greeting/portrait area on standard
-- quest frame heights (WoW classic ~70px header zone).
local function SkinQuestDialog(f)
	SkinDialog(f)
	if not f._sentiQuestDiv then
		local div = f:CreateTexture(nil, "OVERLAY")
		div:SetTexture(BLANK)
		div:SetVertexColor(ACC.r, ACC.g, ACC.b, 0.28)
		div:SetHeight(1)
		div:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, -55)
		div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -55)
		f._sentiQuestDiv = div
	end
end

-- a lone Blizzard button (ghost/release, etc): our raised look
local function SkinButton(f)
	if not f or f._sentiSkinned or IsForbidden(f) then return end
	f._sentiSkinned = true
	FadeTextures(f, 0)
	S.Template(f, "raised")
	RestyleFonts(f, 11)
end

-- per-frame skinners -------------------------------------------------------
local SKINS = {}

function SKINS.TalkingHeadFrame(f)
	SkinPanelish(f)
	-- hide the model's parchment chrome, keep the 3D head itself
	for _, c in ipairs({ f:GetChildren() }) do
		if type(c) == "table" and c.GetRegions then
			StripChrome(c)
		end
	end
end

-- mirror timers: the bar fill lives on a StatusBar child widget inside
-- MirrorTimerN; the wooden border frame is a BORDER texture that
-- StripChrome only dims to 0.15. Walk the children, find the StatusBar,
-- restyle it flat with our accent colour.
local function SkinMirrorTimer(c)
	-- find the StatusBar widget: MirrorTimerN itself on some builds,
	-- a child named MirrorTimerNStatusBar / MirrorTimerN.StatusBar on others
	local sb = c
	if not sb.SetStatusBarTexture then
		local name = c.GetName and c:GetName()
		sb = c.StatusBar or (name and _G[name .. "StatusBar"])
	end
	-- also walk children for a bare StatusBar child
	if not (sb and sb.SetStatusBarTexture) then
		for _, kid in ipairs({ c:GetChildren() }) do
			if type(kid) == "table" and kid.SetStatusBarTexture then
				sb = kid break
			end
		end
	end
	if sb and sb.SetStatusBarTexture then
		Call("mt:tex",  sb.SetStatusBarTexture, sb, S.media.blank)
		Call("mt:col",  sb.SetStatusBarColor,   sb, ACC.r, ACC.g, ACC.b)
	end
	-- kill the wooden/parchment frame texture outright (alpha 0.15 was
	-- still visible as the border ring in the screenshot)
	for _, r in ipairs({ c:GetRegions() }) do
		if type(r) == "table" and r.GetDrawLayer and r.SetAlpha then
			local okL, layer = Call("mt:layer", r.GetDrawLayer, r)
			if okL and (layer == "BORDER" or layer == "BACKGROUND") then
				Call("mt:hide", r.SetAlpha, r, 0)
			end
		end
	end
	SkinPanelish(c)
end

function SKINS.VehicleSeatIndicator(f)
	SkinPanelish(f)
end

function SKINS.DurabilityFrame(f)
	SkinPanelish(f)
end

-- loss-of-control banner ("Bewegungsunfaehig 0,4 Sek."): PanelSkin alone
-- left the Blizzard art visible and the icon overlapping the label -
-- the client anchors the icon so it eats the first characters. Kill the
-- art, dock the icon at the left edge, restyle the fonts.
local function ApplyLocStyle(f)
	for _, k in ipairs({ "blackBg", "BlackBg", "RedLineTop",
		"RedLineBottom", "RedX", "redX" }) do
		local t = f[k]
		if t and t.SetAlpha then Call("loc:art", t.SetAlpha, t, 0) end
	end
	SkinPanelish(f)
	-- icon: fixed square on the left edge so the centred ability text
	-- starts clear of it
	local icon = f.Icon
	if icon and icon.SetSize then
		local okH, h = Call("loc:h", f.GetHeight, f)
		local size = (okH and h or 40) - 6
		Call("loc:isz", icon.SetSize, icon, size, size)
		Call("loc:cp", icon.ClearAllPoints, icon)
		Call("loc:sp", icon.SetPoint, icon, "LEFT", f, "LEFT", 4, 0)
		if icon.SetTexCoord then
			Call("loc:tc", icon.SetTexCoord, icon, 0.07, 0.93, 0.07, 0.93)
		end
	end
	RestyleFonts(f, 11)
end

function SKINS.LossOfControlFrame(f)
	ApplyLocStyle(f)
	if f._locTicker then return end
	f._locTicker = true
	-- the game re-alphas its red art and re-anchors icon+text on every
	-- display tick, AFTER our watch-shown skin ran - re-apply while the
	-- banner is visible so the layout sticks
	C_Timer.NewTicker(0.15, function()
		if f:IsShown() then S.SafeCall("loc:tick", ApplyLocStyle, f) end
	end)
end

function SKINS.GhostFrame(f)
	SkinButton(f)
end

-- dialog windows: our panel behind, wood/parchment art gone
local function DialogSkin(f) SkinDialog(f) end

-- the world map gets the panel + top-level chrome + fonts but NO
-- child walk: map pins are plain button children without icon-ish
-- names - the deep pass would fade them invisible
local function MapSkin(f)
	if not f or f._sentiSkinned or IsForbidden(f) then return end
	SkinPanelish(f)
	HideSubChrome(f)
	RestyleFonts(f)
end

-- frames whose CONTENT is created lazily per use (alerts queue their
-- toasts, widget containers spawn per encounter, timers per battleground):
-- a slow sweep styles each new child once, font pass every time
local sweepTicker, sweepSpecs
local function SweepStart(specs)
	sweepSpecs = sweepSpecs or {}
	for _, s in ipairs(specs) do sweepSpecs[#sweepSpecs + 1] = s end
	if sweepTicker then return end
	sweepTicker = C_Timer.NewTicker(1.5, function()
		for _, spec in ipairs(sweepSpecs) do
			local okR, cont = pcall(spec.resolver)
			cont = okR and cont or nil
			if type(cont) == "table" and cont.GetChildren then
				for _, c in ipairs({ cont:GetChildren() }) do
					if type(c) == "table" and c.GetRegions then
						if not c._sentiSkinned then
							c._sentiSkinned = true
							spec.skin(c)
						end
						spec.fonts(c)
					end
				end
			end
		end
	end)
end

-- the mirror timers (breath underwater, fatigue, feign death) spawn
-- lazily on first use on this client - some builds hand them out as
-- container children, others as MirrorTimer1..N globals. The proxy
-- merges both sources so the slow sweep skins every new bar as it
-- appears. Defined AFTER SweepStart: local functions are nil before
-- their definition line.
local mirrorProxy = { GetChildren = function()
	local kids = {}
	local cont = _G.MirrorTimerContainer
	if type(cont) == "table" and cont.GetChildren then
		for _, k in ipairs({ cont:GetChildren() }) do kids[#kids + 1] = k end
	end
	for i = 1, 10 do
		local mt = _G["MirrorTimer" .. i]
		if type(mt) == "table" then kids[#kids + 1] = mt end
	end
	return unpack(kids)
end }

function SKINS.MirrorTimerContainer(f)
	SweepStart({ { resolver = function() return mirrorProxy end,
		skin = SkinMirrorTimer,
		fonts = function(c) RestyleFonts(c, 11) end } })
end

local function SkinToast(c)
	SkinPanelish(c)
	RestyleFonts(c, 11)
end

local function SkinWidgetChild(c)
	HideSubChrome(c)
end

local function SkinTimerBar(c)
	-- TimerTrackerTimer1..N are StatusBar widgets
	if c.SetStatusBarTexture then
		Call("tb:tex", c.SetStatusBarTexture, c, S.media.blank)
	end
	StripChrome(c)
end

function SKINS.AlertFrame(f)
	SweepStart({ { resolver = function() return f end,
		skin = SkinToast, fonts = function(c) RestyleFonts(c, 11) end } })
end

function SKINS.WidgetContainers()
	SweepStart({
		{ resolver = function() return _G.UIWidgetBelowMinimapContainerFrame end,
			skin = SkinWidgetChild, fonts = function(c) RestyleFonts(c, 11) end },
		{ resolver = function() return _G.UIWidgetTopCenterContainerFrame end,
			skin = SkinWidgetChild, fonts = function(c) RestyleFonts(c, 11) end },
		{ resolver = function() return _G.UIWidgetCenterDisplayFrame end,
			skin = SkinWidgetChild, fonts = function(c) RestyleFonts(c, 11) end },
	})
end

function SKINS.TimerTracker()
	SweepStart({ { resolver = function() return _G.TimerTracker end,
		skin = SkinTimerBar, fonts = function(c) RestyleFonts(c, 11) end } })
end

-- big screen texts ----------------------------------------------------------
local function StyleBigText()
	local C = S.colors
	local jobs = {
		{ "ZoneTextFrame", 32, C.accent },
		{ "SubZoneTextFrame", 24, C.text },
		{ "RaidWarningFrame", 20, C.text },
		{ "RaidBossEmoteFrame", 20, C.accent },
		{ "UIErrorsFrame", 14, C.text },
	}
	for _, j in ipairs(jobs) do
		local f = _G[j[1]]
		if type(f) == "table" and f.GetRegions then
			RestyleFonts(f, j[2], j[3].r, j[3].g, j[3].b)
		end
	end
	-- zone/warning frames build strings lazily in some builds: a re-apply
	-- on their show events keeps the font after the first use
	for _, name in ipairs({ "ZoneTextFrame", "SubZoneTextFrame",
		"RaidWarningFrame", "RaidBossEmoteFrame" }) do
		local f = _G[name]
		if type(f) == "table" and f.HookScript and not f._sentiFontHook then
			f._sentiFontHook = true
			f:HookScript("OnShow", function(self)
				local C2 = S.colors
				local col = (name:find("Emote") or name == "ZoneTextFrame")
					and C2.accent or C2.text
				RestyleFonts(self, nil, col.r, col.g, col.b)
			end)
		end
	end
end

-- cooldown manager viewers ---------------------------------------------------
local VIEWERS = { "EssentialCooldownViewer", "UtilityCooldownViewer",
	"BuffIconCooldownViewer", "BuffBarCooldownViewer" }

local function SkinViewer(v)
	if v._sentiSkinned then return end
	v._sentiSkinned = true
	for _, c in ipairs({ v:GetChildren() }) do
		if type(c) == "table" and c.GetRegions then
			StripChrome(c)
			for _, r in ipairs({ c:GetRegions() }) do
				if type(r) == "table" and r.GetObjectType
					and r:GetObjectType() == "Texture"
					and r.GetDrawLayer then
					local okL, layer = Call("layer", r.GetDrawLayer, r)
					if okL and not S.IsSecret(layer) and layer == "ARTWORK" then
						Call("tex:coord", r.SetTexCoord, r,
							0.07, 0.93, 0.07, 0.93)
					end
				end
			end
		end
	end
end

function Skins.SetupViewers()
	for _, name in ipairs(VIEWERS) do
		local v = _G[name]
		if type(v) == "table" then
			Call("viewer:parent", v.SetParent, v, UIParent)
			Call("viewer:show", v.SetShown, v, true)
			SkinViewer(v)
			local key = "cdv." .. name
			if not S.Movers.Get(key) then
				S.Movers.Register(v, key, L["Cooldown viewer"] .. " " .. name,
					{ x = 0, y = 240 })
			end
		end
	end
end

function Skins.HideViewers()
	for _, name in ipairs(VIEWERS) do
		local v = _G[name]
		if type(v) == "table" then
			Call("viewer:park", v.SetParent, v, ns.ParkFrame())
		end
	end
end

-- enable --------------------------------------------------------------------
function Skins.Enable(mod)
	db = mod.db
	-- style the mover-framed Blizzard UI once it exists: dialogs get the
	-- full skin, status/toast frames the panel, banners fonts only
	local function PanelSkin(f) SkinPanelish(f) RestyleFonts(f) end
	for _, h in ipairs({
		{ "TalkingHeadFrame", SKINS.TalkingHeadFrame },
		{ "MirrorTimerContainer", SKINS.MirrorTimerContainer },
		{ "AlertFrame", SKINS.AlertFrame },
		{ "VehicleSeatIndicator", SKINS.VehicleSeatIndicator },
		{ "DurabilityFrame", SKINS.DurabilityFrame },
		{ "GhostFrame", SKINS.GhostFrame },
		{ "StaticPopup1", DialogSkin }, { "StaticPopup2", DialogSkin },
		{ "StaticPopup3", DialogSkin }, { "StaticPopup4", DialogSkin },
		{ "GameMenuFrame", DialogSkin },
		{ "ReadyCheckFrame", DialogSkin },
		{ "CinematicFrameCloseDialog", DialogSkin },
		{ "ItemTextFrame", DialogSkin },
		{ "ChatConfigFrame", DialogSkin },
		{ "StackSplitFrame", DialogSkin },
		-- the big everyday windows: quest giver and log, vendor, mail,
		-- spellbook, trade, inspect, flight map, dressing room, social,
		-- trainer/craft, options. Names vary by client build - missing
		-- frames are skipped and late-loaded ones styled on first show
		{ "QuestFrame", SkinQuestDialog },
		{ "GossipFrame", SkinQuestDialog },
		{ "QuestLogFrame", DialogSkin },
		{ "MerchantFrame", DialogSkin },
		{ "MailFrame", SkinMail },
		{ "SpellBookFrame", DialogSkin },
		{ "TradeFrame", DialogSkin },
		{ "InspectFrame", DialogSkin },
		{ "TaxiFrame", DialogSkin },
		{ "DressUpFrame", DialogSkin },
		{ "TabardFrame", DialogSkin },
		{ "PetitionFrame", DialogSkin },
		{ "FriendsFrame", DialogSkin },
		{ "MacroFrame", DialogSkin },
		{ "ClassTrainerFrame", DialogSkin },
		{ "TrainerFrame", DialogSkin },
		{ "CraftFrame", DialogSkin },
		{ "BattlefieldFrame", DialogSkin },
		{ "PVPFrame", DialogSkin },
		{ "HonorFrame", DialogSkin },
		{ "LFGParentFrame", DialogSkin },
		{ "ArenaFrame", DialogSkin },
		{ "BankFrame", DialogSkin },
		{ "GuildBankFrame", DialogSkin },
		{ "AuctionFrame", DialogSkin },
		{ "QuestTimerFrame", DialogSkin },
		{ "TimeManagerFrame", DialogSkin },
		{ "HelpFrame", DialogSkin },
		{ "InterfaceOptionsFrame", DialogSkin },
		{ "OptionsFrame", DialogSkin },
		{ "KeyBindingFrame", DialogSkin },
		{ "VideoOptionsFrame", DialogSkin },
		{ "AddonList", DialogSkin },
		{ "ChannelFrame", DialogSkin },
		-- second wave: collections, journal, achievements, guild,
		-- talents, professions, PvE finder, wardrobe and the rest of
		-- the big panels. LoD frames resolve through WatchShown.
		{ "CollectionsJournal", DialogSkin },
		{ "EncounterJournal", DialogSkin },
		{ "AchievementFrame", DialogSkin },
		{ "CalendarFrame", DialogSkin },
		{ "CommunitiesFrame", DialogSkin },
		{ "GuildFrame", DialogSkin },
		{ "PVEFrame", DialogSkin },
		{ "LFGListFrame", DialogSkin },
		{ "GroupFinderFrame", DialogSkin },
		{ "PremadeGroupsFrame", DialogSkin },
		{ "LFGFrame", DialogSkin },
		{ "ChallengesFrame", DialogSkin },
		{ "TalentFrame", DialogSkin },
		{ "PlayerTalentFrame", DialogSkin },
		{ "ClassTalentFrame", DialogSkin },
		{ "ProfessionsFrame", DialogSkin },
		{ "TradeSkillFrame", DialogSkin },
		{ "InspectRecipeFrame", DialogSkin },
		{ "ProfessionsBookFrame", DialogSkin },
		{ "WardrobeFrame", DialogSkin },
		{ "TransmogFrame", DialogSkin },
		{ "VoidStorageFrame", DialogSkin },
		{ "ItemUpgradeFrame", DialogSkin },
		{ "ItemSocketingFrame", DialogSkin },
		{ "WeeklyRewardsFrame", DialogSkin },
		{ "PerksProgramFrame", DialogSkin },
		{ "ExpansionLandingPage", DialogSkin },
		{ "GarrisonLandingPage", DialogSkin },
		{ "FlightMapFrame", DialogSkin },
		{ "LootHistoryFrame", DialogSkin },
		{ "WorldStateScoreFrame", DialogSkin },
		{ "QuestLogDetailFrame", DialogSkin },
		{ "RaidInfoFrame", DialogSkin },
		{ "GuildRegistrarFrame", DialogSkin },
		{ "ColorPickerFrame", DialogSkin },
		{ "OpacityFrame", DialogSkin },
		-- third wave: the modern settings UI (replaces the old
		-- InterfaceOptionsFrame on new builds), group-finder popups,
		-- expansion systems and big choice dialogs
		{ "SettingsPanel", DialogSkin },
		{ "ClickBindingFrame", DialogSkin },
		{ "EditModeManagerFrame", DialogSkin },
		{ "LFGDungeonReadyDialog", DialogSkin },
		{ "LFGDungeonReadyPopup", DialogSkin },
		{ "LFGInvitePopup", DialogSkin },
		{ "LFDRoleCheckPopup", DialogSkin },
		{ "PetBattleQueueReadyFrame", DialogSkin },
		{ "LFGBrowseFrame", DialogSkin },
		{ "RaidBrowserFrame", DialogSkin },
		{ "PVPMatchResults", DialogSkin },
		{ "PVPMatchScoreboard", DialogSkin },
		{ "PlayerChoiceFrame", DialogSkin },
		{ "WarboardQuestChoiceFrame", DialogSkin },
		{ "ArchaeologyFrame", DialogSkin },
		{ "ItemInteractionFrame", DialogSkin },
		{ "ObliterumForgeFrame", DialogSkin },
		{ "IslandsQueueFrame", DialogSkin },
		{ "ChromieTimeFrame", DialogSkin },
		{ "InspectGuildFrame", DialogSkin },
		{ "GuildControlUI", DialogSkin },
		{ "GuildInviteFrame", DialogSkin },
		{ "GuildTextEditFrame", DialogSkin },
		{ "ModelPreviewFrame", DialogSkin },
		{ "SplashFrame", DialogSkin },
		{ "DeathRecapFrame", DialogSkin },
		{ "ReportFrame", DialogSkin },
		{ "GenericTraitFrame", DialogSkin },
		{ "DelvesDifficultyPickerFrame", DialogSkin },
		{ "DelvesCompanionConfigurationFrame", DialogSkin },
		{ "ProfessionsCustomerOrdersFrame", DialogSkin },
		{ "ArtifactFrame", DialogSkin },
		{ "OrderHallTalentFrame", DialogSkin },
		{ "GarrisonMissionFrame", DialogSkin },
		{ "GarrisonShipyardFrame", DialogSkin },
		{ "GarrisonBuildingFrame", DialogSkin },
		{ "GarrisonRecruiterFrame", DialogSkin },
		{ "GarrisonRecruitSelectFrame", DialogSkin },
		{ "GarrisonCapacitiveDisplayFrame", DialogSkin },
		{ "OrderHallMissionFrame", DialogSkin },
		{ "BFAMissionFrame", DialogSkin },
		{ "CovenantMissionFrame", DialogSkin },
		{ "AnimaDiversionFrame", DialogSkin },
		{ "SoulbindViewer", DialogSkin },
		{ "RuneforgeFrame", DialogSkin },
		{ "CovenantSanctumFrame", DialogSkin },
		-- fourth wave: auction variants, mail reader, stable master,
		-- bonus roll, calendar sub-windows, macro icon picker and the
		-- remaining standalone dialogs
		{ "AuctionHouseFrame", DialogSkin },
		{ "BlackMarketFrame", DialogSkin },
		{ "OpenMailFrame", DialogSkin },
		{ "PetStableFrame", DialogSkin },
		{ "ArenaRegistrarFrame", DialogSkin },
		{ "MovieFrame", DialogSkin },
		{ "StoreFrame", DialogSkin },
		{ "ScriptErrorsFrame", DialogSkin },
		{ "BonusRollFrame", DialogSkin },
		{ "PartyPoseFrame", DialogSkin },
		{ "WarfrontsPartyPoseFrame", DialogSkin },
		{ "IslandsPartyPoseFrame", DialogSkin },
		{ "ChallengesKeystoneFrame", DialogSkin },
		{ "MacroPopupFrame", DialogSkin },
		{ "CommunitiesTicketManagerDialog", DialogSkin },
		{ "QuestLogPopupDetailFrame", DialogSkin },
		{ "RecruitAFriendFrame", DialogSkin },
		{ "RecruitAFriendRewardsFrame", DialogSkin },
		{ "ScrappingMachineFrame", DialogSkin },
		{ "AzeriteEmpoweredItemUI", DialogSkin },
		{ "AzeriteRespecFrame", DialogSkin },
		{ "ReputationDetailFrame", DialogSkin },
		{ "TokenFramePopup", DialogSkin },
		{ "CalendarCreateEventFrame", DialogSkin },
		{ "CalendarViewEventFrame", DialogSkin },
		{ "CalendarViewHolidayFrame", DialogSkin },
		{ "CalendarViewRaidFrame", DialogSkin },
		{ "CalendarEventPickerFrame", DialogSkin },
		{ "TutorialFrame", DialogSkin },
		-- the raid manager pullout is not a dialog: panel + fonts only
		{ "CompactRaidFrameManager", PanelSkin },
		-- last named stragglers: friends recruit dialogs, quest sync,
		-- edit mode settings and the loss-of-control splash
		{ "BattleTagInviteFrame", DialogSkin },
		{ "RecruitAFriendRecruitmentFrame", DialogSkin },
		{ "RecruitAFriendSentFrame", DialogSkin },
		{ "QuestSessionStartDialog", DialogSkin },
		{ "QuestSessionJoinDialog", DialogSkin },
		{ "EditModeSystemSettingsDialog", DialogSkin },
		{ "GenericPopupFrame", DialogSkin },
		{ "LossOfControlFrame", SKINS.LossOfControlFrame },
		-- the map: biggest remaining window, but child buttons are
		-- pins without icon names - chrome+fonts only, no deep walk
		{ "WorldMapFrame", MapSkin },
		-- late stragglers
		{ "BarberShopFrame", DialogSkin },
		{ "AudioOptionsFrame", DialogSkin },
		{ "TransmogrifyFrame", DialogSkin },
		{ "RaidParentFrame", DialogSkin },
		{ "ContributionCollectionFrame", DialogSkin },
		{ "TorghastLevelPickerFrame", DialogSkin },
		{ "WorldStateAlwaysUpFrame",
			function(f) RestyleFonts(f, nil) end },
		-- chat popup menus and the autocomplete dropdown are
		-- dropdown-style lists: panel + fonts
		{ "ChatMenu", PanelSkin },
		{ "EmoteMenu", PanelSkin },
		{ "LanguageMenu", PanelSkin },
		{ "VoiceMacroMenu", PanelSkin },
		{ "AutoCompleteBox", PanelSkin },
		-- fonts-only: pet battle keeps its fullscreen art (its
		-- buttons ARE content), the difficulty banner its icon
		{ "PetBattleFrame", function(f) RestyleFonts(f, nil) end },
		{ "PlayerDifficultyFrame",
			function(f) RestyleFonts(f, nil) end },
		{ "DropDownList1", PanelSkin }, { "DropDownList2", PanelSkin },
		{ "DropDownList3", PanelSkin },
		{ "BNToastFrame", PanelSkin },
		{ "TicketStatusFrame", PanelSkin },
		{ "QueueStatusFrame", PanelSkin },
		{ "BossBanner", function(f) RestyleFonts(f, nil) end },
		{ "LevelUpDisplay", function(f) RestyleFonts(f, nil) end },
	}) do
		local name, fn = h[1], h[2]
		local f = _G[name]
		if type(f) == "table" and not IsForbidden(f) then
			S.SafeCall("skin:" .. name, fn, f)
		end
		-- late-loaded frames: restyle on first show. The font pass also
		-- re-runs on every show - the game repaints text colors per open
		-- (quest pages, merchant tabs), which would undo the dark-text lift
		S.WatchShown(function() return _G[name] end, function(fr)
			-- forbidden frames (TradeFrame, StoreFrame) refuse every
			-- access - leave them alone instead of erroring each open
			if IsForbidden(fr) then return end
			S.SafeCall("skin:" .. name, fn, fr)
			-- the game rebuilds its chrome on every open (NineSlice,
			-- backdrops, region alphas) - re-kill it or the window
			-- flips back to the old look mid-session
			local deep = fn == DialogSkin
			S.SafeCall("skin:chrome:" .. name, ReapplyChrome, fr, deep)
			S.SafeCall("skin:fonts:" .. name, RestyleFonts, fr)
			-- re-walk the child tree on every show: widgets the game
			-- builds lazily (tab pages on first click, scroll rows on
			-- populate) get styled as soon as the window reopens;
			-- marker flags keep already-skinned children cheap. Only
			-- for real dialogs - panel-only skins like the world map
			-- have button children whose art is content (map pins)
			if deep then
				S.SafeCall("skin:deep:" .. name, SkinChildren, fr)
				-- lazy content lands a tick after OnShow (AH result
				-- rows, list children): one deferred re-walk catches
				-- whatever the populate pass built late
				C_Timer.After(0, function()
					if fr:IsShown() then
						S.SafeCall("skin:deep2:" .. name,
							SkinChildren, fr)
					end
				end)
			end
		end)
	end
	-- dialog text is re-painted on content events AFTER the show pass:
	-- gossip greetings, quest pages and book text land on the frame in
	-- their parchment-black and undo the dark-text lift. Re-run the
	-- font pass on those events, a tick late so the new text is there
	local refontTargets = {
		GOSSIP_SHOW = "GossipFrame",
		GOSSIP_CONFIRM = "GossipFrame",
		QUEST_DETAIL = "QuestFrame",
		QUEST_PROGRESS = "QuestFrame",
		QUEST_COMPLETE = "QuestFrame",
		QUEST_GREETING = "QuestFrame",
		QUEST_FINISHED = "QuestFrame",
		QUEST_ITEM_UPDATE = "QuestFrame",
		ITEM_TEXT_BEGIN = "ItemTextFrame",
		ITEM_TEXT_READY = "ItemTextFrame",
	}
	for ev, fname in pairs(refontTargets) do
		S.RegisterEvent(ev, function()
			local f = _G[fname]
			if type(f) == "table" and f.IsShown and f:IsShown()
				and not IsForbidden(f) then
				C_Timer.After(0, function()
					if f:IsShown() then
						S.SafeCall("refont:" .. fname, RestyleFonts, f)
					end
				end)
			end
		end)
	end
	StyleBigText()
	-- lazy-content containers: the sweeps start once and style each new
	-- child (queued toast, widget bar, BG timer) as it spawns
	S.SafeCall("skin:widgets", SKINS.WidgetContainers)
	S.SafeCall("skin:timers", SKINS.TimerTracker)
	if db.cooldownViewers then
		Skins.SetupViewers()
	end
end

function Skins.SettingChanged(path)
	if not db then return end
	if path == "cooldownViewers" then
		if db.cooldownViewers then
			S.RunOutOfCombat(Skins.SetupViewers)
		else
			S.RunOutOfCombat(Skins.HideViewers)
		end
	end
end
