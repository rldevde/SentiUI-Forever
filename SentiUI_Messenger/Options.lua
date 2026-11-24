-- The module's options, filed under its own "Messenger" section.
local _, ns = ...
local L = ns.L

ns.OPTIONS = {
	pages = {
		{
			id = "messenger",
			label = L["Messenger"],
			desc = L["Whisper hub: every conversation in one window, unread counters, pinned chats, per-character history and an away auto-reply."],
			groups = {
				{
					label = L["Messenger"],
					items = {
						{ type = "toggle", key = "enabled", label = L["Enable messenger module"], reload = true,
							desc = L["Turns every messenger feature off after a reload."] },
						{ type = "button", label = L["Messenger"], text = L["Open"],
							func = function() ns.Core.Toggle() end },
						{ type = "text", label = "/smsg  |  /sm  -  " .. L["toggle the window"] },
					},
				},
				{
					label = L["Notifications"],
					items = {
						{ type = "toggle", key = "sound", label = L["Whisper sound"],
							desc = L["Play a short sound when a whisper arrives, at most every few seconds."] },
						{ type = "toggle", key = "minimapBadge", label = L["Minimap unread badge"],
							desc = L["Shows the number of unread whispers on the SentiUI minimap button."] },
					},
				},
				{
					label = L["Whisper tiles"],
					desc = L["Pill chips over the chat, one per recent conversation - first name in class color. Left-click opens that chat's own window, right-click opens it in the Messenger hub. Move the strip via /sui unlock."],
					items = {
						{ type = "toggle", key = "tiles", label = L["Show whisper tiles"] },
						{ type = "slider", key = "tileMax", label = L["Tiles shown"], min = 2, max = 10, step = 1,
							disabled = function(get) return not get("tiles") end },
						{ type = "toggle", key = "preview", label = L["New whisper preview"],
							desc = L["Flashes the sender and first line above the tiles for a few seconds."] },
						{ type = "slider", key = "previewSec", label = L["Preview seconds"], min = 2, max = 15, step = 1,
							disabled = function(get) return not get("preview") end },
						{ type = "toggle", key = "autoOpen", label = L["Open window on whisper"],
							desc = L["A new incoming whisper opens that person's conversation window right away."] },
						{ type = "toggle", key = "keyR", label = L["Reply key opens window"], reload = true,
							desc = L["Pressing the reply key (r) opens the conversation window instead of the chat input."] },
					},
				},
				{
					label = L["History"],
					desc = L["Character whispers persist per account; Battle.net chats last for the session."],
					items = {
						{ type = "slider", key = "historySize", label = L["Lines per conversation"], min = 20, max = 200, step = 10 },
						{ type = "slider", key = "maxConvos", label = L["Conversations kept"], min = 5, max = 80, step = 5 },
						{ type = "toggle", key = "timestamps", label = L["Show timestamps"] },
					},
				},
				{
					label = L["Away auto-reply"],
					desc = L["Answers an incoming whisper once per person every 15 minutes while you are flagged away."],
					items = {
						{ type = "toggle", key = "autoReply", label = L["Away auto-reply"] },
						{ type = "custom", height = 26,
							build = function(row)
								local e = SentiUI.Widgets.EditBox(row, 260, 22)
								e.holder:SetPoint("RIGHT", row, "RIGHT", -12, 0)
								e.placeholder:SetText(L["Reply text (empty = default)"])
								e.onChanged = function(t)
									local d = ns.Core.DB()
									if d then d.autoReplyText = t end
								end
								row.replyBox = e
							end,
							update = function(row)
								local d = ns.Core.DB()
								if d and row.replyBox:GetText() ~= (d.autoReplyText or "") then
									row.replyBox:SetText(d.autoReplyText or "")
								end
							end },
					},
				},
			},
		},
	},
}
