-- Chat module defaults. Merged into SentiUIDB.modules.Chat at enable.
local _, ns = ...

ns.DEFAULTS = {
	enabled = true,

	-- panels behind the chat, Sentinel look: a shade fading to the top,
	-- hairline under the tab row, movers drag them
	panelWidth = 400,
	panelHeight = 160,
	panelTransparency = true,      -- shade fades out fully at the top
	panelBackdrop = "SHOWBOTH",    -- "SHOWBOTH" | "LEFT" | "RIGHT" | "HIDEBOTH"
	rightPanelEnable = true,       -- second panel for an undocked "Loot" tab

	-- fonts
	fontSize = 12,
	fontOutline = "OUTLINE",       -- "NONE" | "OUTLINE" | "THICKOUTLINE"
	tabFontSize = 11,

	editboxPosition = "BELOW_CHAT", -- "ABOVE_CHAT" | "BELOW_CHAT"

	-- message filter
	shortChannels = true,          -- [1. General] -> [1], [Party] -> [P]
	url = true,                    -- make links clickable, copy popup
	smilies = true,                -- :) -> icon, plus the emoji picker chip
	questLinks = true,             -- "[19] Name (id)" text -> clickable |Hquest link
	voiceButtons = true,           -- channel/voice/menu buttons stay, dimmed
	timestamp = "NONE",            -- "NONE" | "%H:%M" | "%H:%M:%S"
	timestampColor = { r = 0.55, g = 0.55, b = 0.55 },
	keywords = "",                 -- comma separated, %MYNAME% allowed
	keywordColor = { r = 1, g = 0.5, b = 0.2 },
	keywordAlert = true,           -- short sound on a keyword hit
	throttle = 0,                  -- drop identical spam within N seconds, 0 off

	-- history: last lines survive a reload
	history = false,
	historySize = 30,

	-- behaviour
	classColorMentions = true,     -- player names in class color
	playerLevel = true,            -- [52 Name] for known players
	hyperlinkHover = true,         -- tooltip on item/spell/quest links
	copyButton = true,             -- copy-chat button on every frame
	scrollDownButton = true,       -- visible jump-to-bottom arrow
	whisperSound = false,          -- play a sound on incoming whispers
	fade = true,
	fadeTime = 30,
	fadeUndockedTabs = false,
	maxLines = 256,
}
