-- Messenger module defaults. Merged into SentiUIDB.modules.Messenger at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	-- notifications
	sound = true,           -- play the whisper sound on new messages (throttled)
	minimapBadge = true,    -- unread counter on the SentiUI minimap button

	-- whisper tiles: small squares over the chat, one per recent chat,
	-- click opens that conversation's own window
	tiles = true,
	tileMax = 6,            -- tiles shown at once
	preview = true,         -- short preview toast on a new whisper
	previewSec = 6,         -- seconds the preview stays
	autoOpen = true,        -- open the conversation window on a new whisper
	keyR = true,            -- the "r" reply key opens the window too

	-- conversations
	historySize = 80,       -- lines kept per conversation
	maxConvos = 40,         -- conversations kept, oldest unpinned drop first
	timestamps = true,      -- show HH:MM in front of thread lines

	-- away auto-reply: answers an incoming whisper once per person every
	-- 15 minutes while you are flagged away
	autoReply = false,
	autoReplyText = "",     -- empty = the client's own away text
}
