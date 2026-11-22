-- The module's options, filed under its own "Chat" section.
local _, ns = ...
local S = SentiUI
local L = ns.L

local function keywordRow()
	return {
		type = "custom", height = 30, noSearch = true,
		build = function(row)
			row.kwLabel = S.Font(row, 11)
			row.kwLabel:SetPoint("LEFT", 10, 0)
			row.kwLabel:SetText(L["Keywords"])
			local eb = CreateFrame("EditBox", nil, row, "BackdropTemplate")
			eb:SetAutoFocus(false)
			eb:SetFontObject(ChatFontNormal or GameFontHighlight)
			eb:SetSize(220, 18)
			eb:SetPoint("RIGHT", -12, 0)
			S.Template(eb, "inset")
			eb:SetScript("OnEnterPressed", function(self)
				S:Set("Chat", "keywords", self:GetText() or "")
				self:ClearFocus()
			end)
			-- no OnEscapePressed: Escape clears focus natively and a
			-- handler would taint the engine's spell-stop calls
			row.kwEdit = eb
		end,
		update = function(row)
			if row.kwEdit and not row.kwEdit:HasFocus() then
				row.kwEdit:SetText(S:Get("Chat", "keywords") or "")
			end
		end,
	}
end

ns.OPTIONS = {
	pages = {
		{
			id = "chat",
			label = L["Chat"],
			desc = L["Sentinel-styled chat: panels behind the dock, restyled tabs and edit box, message filter and history."],
			groups = {
				{
					label = L["Chat"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable chat styling"], reload = true,
							desc = L["Turns every chat change off after a reload."] },
						{ type = "slider", key = "fontSize", label = L["Font size"], min = 8, max = 24, step = 1, unit = "px" },
						{ type = "dropdown", key = "fontOutline", label = L["Font outline"],
							values = { NONE = L["None"], OUTLINE = L["Outline"], THICKOUTLINE = L["Thick outline"] },
							order = { "NONE", "OUTLINE", "THICKOUTLINE" } },
						{ type = "slider", key = "tabFontSize", label = L["Tab font size"], min = 8, max = 20, step = 1, unit = "px" },
						{ type = "slider", key = "maxLines", label = L["Scrollback lines"], min = 100, max = 1000, step = 50,
							desc = L["How many lines a chat window keeps."] },
					},
				},
				{
					label = L["Panels"],
					desc = L["The shade behind the chat windows. Drag them in move mode."],
					items = {
						{ type = "slider", key = "panelWidth", label = L["Width"], min = 200, max = 800, step = 5, unit = "px" },
						{ type = "slider", key = "panelHeight", label = L["Height"], min = 80, max = 400, step = 5, unit = "px" },
						{ type = "toggle", key = "panelTransparency", label = L["Fade at top"],
							desc = L["The shade fades out towards the top edge."] },
						{ type = "dropdown", key = "panelBackdrop", label = L["Backdrop"],
							values = { SHOWBOTH = L["Both"], LEFT = L["Left only"], RIGHT = L["Right only"], HIDEBOTH = L["Hidden"] },
							order = { "SHOWBOTH", "LEFT", "RIGHT", "HIDEBOTH" } },
						{ type = "toggle", key = "rightPanelEnable", label = L["Right panel"],
							desc = L["A second panel for an undocked Loot chat tab."] },
						{ type = "button", label = L["Move frames"], text = L["Unlock"],
							func = function() SentiUI.Movers.SetUnlocked(true) end },
					},
				},
				{
					label = L["Edit box"],
					items = {
						{ type = "dropdown", key = "editboxPosition", label = L["Position"],
							values = { ABOVE_CHAT = L["Above chat"], BELOW_CHAT = L["Below chat"] },
							order = { "ABOVE_CHAT", "BELOW_CHAT" } },
					},
				},
				{
					label = L["Messages"],
					items = {
						{ type = "toggle", key = "shortChannels", label = L["Short channel names"],
							desc = L["[1. General] becomes [1], [Party] becomes [P]."] },
						{ type = "toggle", key = "url", label = L["Clickable links"],
							desc = L["URLs become links that open a copy popup."] },
						{ type = "toggle", key = "smilies", label = L["Emoticons"], reload = true,
							desc = L["Type :name: codes or pick from the emoji palette - 60 icons in total."] },
						{ type = "toggle", key = "questLinks", label = L["Clickable quest links"],
							desc = L["Plain-text quest references like [19] Name (id) become clickable links that open the quest."] },
						{ type = "toggle", key = "voiceButtons", label = L["Channel & voice buttons"], reload = true,
							desc = L["Keeps the channel, voice and chat menu buttons next to the chat, dimmed until hovered."] },
						{ type = "dropdown", key = "timestamp", label = L["Timestamp"],
							values = { NONE = L["None"], ["%H:%M"] = "HH:MM", ["%H:%M:%S"] = "HH:MM:SS" },
							order = { "NONE", "%H:%M", "%H:%M:%S" } },
						{ type = "color", key = "timestampColor", label = L["Timestamp color"] },
						keywordRow(),
						{ type = "color", key = "keywordColor", label = L["Keyword color"],
							desc = L["Comma separated words to highlight; %MYNAME% is your character."] },
						{ type = "toggle", key = "keywordAlert", label = L["Keyword sound"] },
						{ type = "slider", key = "throttle", label = L["Spam throttle"], min = 0, max = 30, step = 1, unit = "s",
							desc = L["Drop an identical repeated message within this many seconds. 0 is off."] },
					},
				},
				{
					label = L["Behavior"],
					items = {
						{ type = "toggle", key = "classColorMentions", label = L["Class-colored names"] },
						{ type = "toggle", key = "playerLevel", label = L["Player level"],
							desc = L["Known players show as [52 Name] in chat."] },
						{ type = "toggle", key = "hyperlinkHover", label = L["Link tooltips"],
							desc = L["Hovering an item, spell or quest link shows its tooltip."] },
						{ type = "toggle", key = "copyButton", label = L["Copy button"], reload = true,
							desc = L["A small copy button on every chat frame opens the copy window."] },
						{ type = "toggle", key = "scrollDownButton", label = L["Scroll-to-bottom button"], reload = true },
						{ type = "toggle", key = "whisperSound", label = L["Whisper sound"] },
						{ type = "toggle", key = "fade", label = L["Fade messages"],
							desc = L["Old messages fade out on the docked frames."] },
						{ type = "slider", key = "fadeTime", label = L["Fade after"], min = 5, max = 120, step = 5, unit = "s",
							disabled = function(get) return not get("fade") end },
						{ type = "toggle", key = "fadeUndockedTabs", label = L["Fade floating tabs"],
							disabled = function(get) return not get("fade") end },
					},
				},
				{
					label = L["History"],
					items = {
						{ type = "toggle", key = "history", label = L["Keep history"],
							desc = L["The last lines of the main chat are restored after a reload."] },
						{ type = "slider", key = "historySize", label = L["Lines"], min = 0, max = 100, step = 5,
							disabled = function(get) return not get("history") end },
					},
				},
			},
		},
	},
}
