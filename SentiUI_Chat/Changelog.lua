local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.14",
		date = "2026-11-22",
		changes = {
			"URL copy dialog, chat copy window and emote picker now use the own dialog/Escape handling instead of StaticPopupDialogs and UISpecialFrames.",
			"Removed the 'sticky channels' option: it wrote into ChatTypeInfo, and every addon-written value there taints the Enter dispatch that later calls the protected SendChatMessage. Channel stickiness now follows the client's own defaults.",
		},
		changesDE = {
			"URL-Kopierdialog, Kopierfenster und Emote-Picker nutzen jetzt den eigenen Dialog bzw. eigene Escape-Behandlung statt StaticPopupDialogs und UISpecialFrames.",
			"Option 'Sticky-Kanaele' entfernt: sie schrieb in ChatTypeInfo, und jeder dort von einem Addon geschriebene Wert taintet den Enter-Dispatch, der spaeter das geschuetzte SendChatMessage aufruft. Die Kanal-Stickiness folgt jetzt den Client-Standards.",
		},
	},
	{
		version = "0.2.13",
		date = "2026-11-22",
		changes = {
			"Fix the edit box losing its style: NineSlice was alpha'd before SetBackdrop - the backdrop draws through NineSlice, so the raised fill/border never rendered (transparent bar with gold focus brackets). The watchdog now also retries styling for late-created edit boxes and re-hides the header chrome every tick.",
		},
		changesDE = {
			"Editbox-Style repariert: NineSlice wurde vor SetBackdrop auf Alpha 0 gesetzt - das Backdrop zeichnet ueber die NineSlice, also wurden Fuellung und Rahmen nie gerendert (durchscheinender Balken mit goldenen Fokus-Winkeln). Der Watchdog holt das Styling fuer spaet erzeugte Editboxen nach und versteckt den Header-Chrome jeden Tick erneut.",
		},
	},
	{
		version = "0.2.12",
		date = "2026-11-22",
		changes = {
			"All post-hooks on Blizzard layout and chat functions are gone (UIParent_ManageFramePositions, FCF_*, ChatEdit_UpdateHeader, tab clicks): they ran inside input/panel dispatches and tainted them - the probable source of blocked SendChatMessage and secret-compare errors when windows opened. One 0.25s watchdog now re-docks the chat, restyles new frames, re-colors tabs and edit box borders and re-anchors the edit box.",
		},
		changesDE = {
			"Alle Post-Hooks auf Blizzard-Layout- und Chat-Funktionen sind weg (UIParent_ManageFramePositions, FCF_*, ChatEdit_UpdateHeader, Tab-Klicks): Sie liefen in Input-/Panel-Dispatches und vergifteten sie - die wahrscheinliche Quelle geblockter SendChatMessage-Aufrufe und Geheimwert-Fehler beim Fenster-Öffnen. Ein 0,25s-Watchdog dockt den Chat an, stylt neue Fenster, färbt Tabs und Editbox-Ränder und verankert die Editbox neu.",
		},
	},
	{
		version = "0.2.11",
		changes = {
			"Compile fix: UpdateKeywords assigned to the for-loop variable, which LuaJIT rejects as a const assign - the whole Chat.lua failed to load. Loop variable is now shadowed by a local.",
		},
		changesDE = {
			"Compile-Fix: UpdateKeywords wies der Schleifenvariable zu, was LuaJIT als Const-Assign ablehnt - die ganze Chat.lua lud nicht. Die Schleifenvariable ist jetzt ein lokales Shadowing.",
		},
	},

	{
		version = "0.2.10",
		changes = {
			"Chat copy window: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.",
		},
		changesDE = {
			"Das Fenster haengt an der Kampf-Verzoegerung: Oeffnen im Kampf wird mit Chat-Notiz nach dem Kampf nachgeholt, ein offenes Fenster versteckt sich bei Kampfbeginn und kehrt danach zurueck.",
		},
	},

	{
		version = "0.2.9",
		changes = {
			"Escape-forbidden-call fix: OnEscapePressed handlers on the URL popup and copy-chat window ran inside the Escape dispatch - both close natively via hideOnEscape/UISpecialFrames now.",
		},
		changesDE = {
			"Escape-Blockier-Fix: OnEscapePressed-Handler am URL-Popup und Copy-Chat-Fenster liefen im Escape-Dispatch - beide schliessen jetzt nativ ueber hideOnEscape/UISpecialFrames.",
		},
	},

	{
		version = "0.2.8",
		changes = {
			"Fixed the 'attempt to index global t' error on level ups: the snap-back ticker captured its handle before the local existed, so the 15th tick indexed a nil global. The ticker variable is now declared before the NewTicker call.",
		},
		changesDE = {
			"Den 'attempt to index global t'-Fehler bei Level-Ups behoben: Der Snapback-Ticker griff auf seinen Handle zu, bevor das Local existierte, sodass der 15. Tick ein nil-Global indizierte. Die Ticker-Variable wird jetzt vor dem NewTicker-Aufruf deklariert.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Fixed repeated errors on messages with secret sender values: the player-level filter guarded the message text but passed the raw sender into ShortName, which called :gsub on it - on this client sender can be a secret value, so every such message threw. The filter now skips secret senders and ShortName itself returns nil for non-plain strings.",
		},
		changesDE = {
			"Wiederholte Fehler bei Nachrichten mit geheimen Sender-Werten behoben: Der Spielerlevel-Filter prüfte den Nachrichtentext, reichte den rohen Sender aber an ShortName weiter, das :gsub darauf aufrief - auf diesem Client kann der Sender ein Secret-Value sein, also warf jede solche Nachricht. Der Filter überspringt jetzt geheime Sender und ShortName gibt für nicht-einfache Strings nil zurück.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Player links with names like 'Prinz Nexo' no longer tear: the link mask only matched |H..|h label |h pairs, but this client separates some link payloads with a single pipe - ':P' inside 'player:Prinz' was still reachable by the smiley pass. A second mask pass now covers leftover |H..|h payloads.",
		},
		changesDE = {
			"Spieler-Links mit Namen wie 'Prinz Nexo' reißen nicht mehr auf: Die Link-Maske fing nur |H..|h Label |h-Paare, doch dieser Client trennt manche Link-Payloads mit einer einzelnen Pipe - ':P' in 'player:Prinz' blieb für den Smiley-Pass erreichbar. Ein zweiter Masken-Pass deckt jetzt übrige |H..|h-Payloads ab.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"The copy-chat window is a real mover now: its own entry in move mode and Movers.Save persistence, so it reopens where you left it.",
		},
		changesDE = {
			"Das Chat-Kopierfenster ist jetzt ein echter Mover: eigener Eintrag im Verschiebe-Modus und Movers.Save-Persistenz - es öffnet wieder dort, wo du es gelassen hast.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Killed the visible chat jump on level up: instead of re-docking ChatFrame1 half a second after Blizzard's pass, its anchor is now re-asserted inside the same Lua pass - hooksecurefunc post-calls on the client's chat/dock positioning functions (FCF_SetWindowPosition, FCF_RestorePositionAndDimensions, FCF_DockUpdate, FloatingChatFrame_Update, UIParent_ManageFramePositions, ...) plus a short burst check after PLAYER_LEVEL_UP and the ignoreFramePositionManager attribute, so a displaced frame never reaches the screen.",
		},
		changesDE = {
			"Der sichtbare Chat-Sprung beim Level-Up ist weg: Statt ChatFrame1 erst eine halbe Sekunde nach Blizzards Lauf zurückzudocken, wird der Anker jetzt im selben Lua-Pass wieder gesetzt - hooksecurefunc-Post-Calls auf die Chat-/Dock-Positionierfunktionen des Clients (FCF_SetWindowPosition, FCF_RestorePositionAndDimensions, FCF_DockUpdate, FloatingChatFrame_Update, UIParent_ManageFramePositions, ...), dazu ein kurzer Burst-Check nach PLAYER_LEVEL_UP und das ignoreFramePositionManager-Attribut - ein verschobener Frame kommt so nie auf den Bildschirm.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Fixed broken player links in chat (raw |Hplayer text and icon garbage in names): the hyperlink mask only matched links whose label contains a bracket, so player links like |Hplayer:...|hName|h stayed unmasked and the smiley pass cut \":P\" out of names like \"Priemelchen\", tearing the whole link markup apart. All hyperlink labels now mask before the url/smiley passes.",
		},
		changesDE = {
			"Fix: Kaputte Spieler-Links im Chat (rohes |Hplayer und Icon-Müll in Namen): Die Hyperlink-Maske fing nur Links mit eckiger Klammer im Label, sodass Spieler-Links wie |Hplayer:...|hName|h unmaskiert blieben und die Smiley-Ersetzung aus Namen wie \"Priemelchen\" ein \":P\" rausschnitt - das Link-Markup riss komplett auf. Jetzt werden alle Hyperlink-Labels vor den URL-/Smiley-Pässen maskiert.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Fixed the chat frame jumping out of its panel after a level up: the client re-anchors chat windows on level ups and dock passes (the tabs stayed put because they hang on the dock manager, the frame itself was moved mid-screen). ChatFrame1 now re-docks whenever its anchor no longer points at the chat panel - checked once per second, skipped in combat - and PLAYER_LEVEL_UP triggers a delayed re-position after Blizzard's own pass settles.",
		},
		changesDE = {
			"Chat-Frame sprang nach einem Level-Up aus seinem Panel: Der Client verankert Chatfenster bei Level-Ups und Dock-Läufen neu (die Tabs hingen am Dock-Manager und blieben oben, der Frame landete mitten auf dem Bildschirm). ChatFrame1 dockt jetzt automatisch wieder an, sobald sein Anker nicht mehr auf das Chat-Panel zeigt - einmal pro Sekunde geprüft, im Kampf pausiert - und PLAYER_LEVEL_UP löst ein verzögertes Repositionieren aus, nachdem Blizzards eigener Lauf durch ist.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Quest references typed as plain text - [19] Name (questID) - are wrapped into real |Hquest hyperlinks so they can be clicked like normal links. Toggle: \"Clickable quest links\".",
		},
		changesDE = {
			"Quest-Verweise als Reintext - [19] Name (QuestID) - werden in echte |Hquest-Hyperlinks gewrappt und sind damit wie normale Links klickbar. Option: \"Klickbare Questlinks\".",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Proper emoji palette: the old 7-icon row became a real grid - 60 emotes in an 8-column panel with title bar, inset cells, hover accent and :name: tooltips. Classic smiley codes like :) or <3 still render, now mapped onto the same icon set, and Discord-style :name: codes work too: type :joy:, :fire:, :thumbsup: and they render as icons.",
		},
		changesDE = {
			"Echte Emoji-Palette: Aus der 7-Icon-Zeile wurde ein richtiges Gitter - 60 Emotes in einem 8-Spalten-Panel mit Titelzeile, Inset-Zellen, Hover-Accent und :name:-Tooltips. Klassische Codes wie :) oder <3 rendern weiter, jetzt auf dasselbe Icon-Set gemappt, und Discord-artige :name:-Codes gehen auch: :joy:, :fire:, :thumbsup: werden als Icons gerendert.",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"Rebuilt the channel, voice and chat-menu buttons as a proper strip: instead of sitting on Blizzard's default anchors half outside the panel, they are now 16px inset chips lined up in the tab row right in front of the emoji chip - dimmed until hovered, accent border on hover, re-anchored after dock updates so the game cannot pull them back.",
		},
		changesDE = {
			"Die Channel-, Voice- und Chatmenü-Buttons sind jetzt ein eigener Strip: Statt an Blizzards Standard-Ankern halb außerhalb des Panels zu hängen, sind es 16px-Inset-Chips in der Tab-Zeile direkt vor dem Emoji-Chip - abgedimmt bis Hover, Accent-Rahmen bei Hover, nach Dock-Updates neu verankert, damit das Spiel sie nicht zurückzieht.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Fixed the regression from the scroll-chip rebuild: HookScript threw on script names this client does not know (OnMessageScrollChanged, possibly OnHyperlinkEnter/Leave) - that aborted StyleChatFrame mid-way so everything after the scroll chip (tabs, edit box, copy button, hyperlink tooltips) never ran. All HookScript calls on chat frames now go through pcall.",
		},
		changesDE = {
			"Die Regression aus dem Scroll-Chip-Umbau ist gefixt: HookScript warf bei Scriptnamen, die dieser Client nicht kennt (OnMessageScrollChanged, evtl. OnHyperlinkEnter/Leave) - das brach StyleChatFrame mitten drin ab, sodass alles nach dem Scroll-Chip (Tabs, Eingabezeile, Copy-Button, Link-Tooltips) nie lief. Alle HookScript-Calls auf Chatframes laufen jetzt per pcall.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Isolated every module enable step (panels, buttons, emoji, filters, scans, positioning) so a failure in one can no longer abort the rest - each now reports with its own chat:* tag so the failing piece is identifiable instead of leaving the whole chat unstyled.",
		},
		changesDE = {
			"Jeder Enable-Schritt (Panels, Buttons, Emoji, Filter, Scans, Positionierung) läuft jetzt einzeln isoliert - ein Fehler bricht den Rest nicht mehr ab und jeder Schritt meldet sich mit eigenem chat:*-Tag, sodass der werfende Teil identifizierbar ist statt den ganzen Chat ungestylt zu lassen.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Hardened the whole style + position pass: every block now runs guarded so one bad frame can no longer skip the rest - which is what left the chat bar unstyled and unanchored. The edit box also resolves Blizzard's shared ChatFrameEditBox fallback, re-asserts its anchor on show and after ChatEdit_SetLastActiveWindow / dock updates, and secret-value reads in GetRegions/GetFont/GetMaxLines are pcall'd.",
		},
		changesDE = {
			"Der komplette Style- + Positionierungslauf ist jetzt abgesichert: Jeder Block läuft einzeln geguarded, damit ein kaputter Frame den Rest nicht mehr überspringt - genau das ließ die Chatleiste ungestylt und ohne Anker. Die Eingabezeile nutzt jetzt auch Blizzards geteilte ChatFrameEditBox-Fallback, setzt ihren Anker bei OnShow sowie nach ChatEdit_SetLastActiveWindow/Dock-Updates neu, und Secret-Value-Lesevorgänge in GetRegions/GetFont/GetMaxLines laufen per pcall.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"Fixed the chat never docking into the panel: PositionChat died during enable - FCF_SavePositionAndDimensions was not wrapped and unnamed temporary chat frames could break the name lookups. Every frame now styles on its own, the dock manager and tab colors are guarded, so one bad frame can no longer take the whole layout down.",
		},
		changesDE = {
			"Der Chat dockte nicht ins Panel: PositionChat starb beim Enable - FCF_SavePositionAndDimensions war nicht abgesichert und namenlose temporäre Chatfenster konnten die Namensauflösung brechen. Jetzt styled jeder Frame einzeln abgesichert, Dock-Manager und Tabfarben sind geguarded - ein kaputter Frame reißt das Layout nicht mehr mit.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"The edit box now sits below the chat by default; existing profiles are migrated once. The position stays switchable in the options.",
		},
		changesDE = {
			"Die Eingabezeile liegt jetzt standardmäßig unter dem Chat; bestehende Profile werden einmalig umgestellt. Die Position bleibt in den Optionen wählbar.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Fixed the scroll-to-bottom chip doing nothing: Blizzard's own button was reparented, which broke its click handler. It is a proper SentiUI chip now that scrolls the frame itself and only shows while you are scrolled up.",
		},
		changesDE = {
			"Der Nach-unten-Chip tat nichts: Blizzard's eigener Button wurde umparentet und sein Klick-Handler lief ins Leere. Jetzt ist es ein echter SentiUI-Chip, der selbst scrollt und nur sichtbar ist, wenn man hochgescrollt hat.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Fixed the copy chip: its text now fills the button and centers properly instead of spilling out.",
			"Emoticons: :) ;-) :D :( :P <3 o.O ^^ render as the Sentinel pixel icons in chat, and a ':)' chip in the tab strip opens a picker that inserts codes into the edit box.",
			"Channel, voice and chat menu buttons are no longer hidden - they sit next to the chat dimmed until hovered, toggleable in the options.",
		},
		changesDE = {
			"Kopier-Chip gefixt: Der Text füllt jetzt den Button und zentriert sauber statt herauszuragen.",
			"Emoticons: :) ;-) :D :( :P <3 o.O ^^ werden als Sentinel-Pixel-Icons im Chat gerendert, und ein ':)'-Chip in der Tab-Leiste öffnet einen Wähler, der Codes in die Eingabezeile einfügt.",
			"Kanal-, Voice- und Chatmenü-Buttons werden nicht mehr versteckt - sie liegen abgedimmt neben dem Chat, abschaltbar in den Optionen.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Panels now match the SentiUI look: the bordered dark panel every window uses, an accent hairline under the tab row and accent corner ticks at the bottom edge. 'Fade at top' still switches to the plain transparent shade.",
			"The copy button became a proper readable chip (inset style, accent text, lit border on hover); the copy window got the accent title line.",
			"The scroll-to-bottom button is a dark chip with an accent arrow now.",
		},
		changesDE = {
			"Panels sehen jetzt aus wie der Rest von SentiUI: dunkles Panel mit Rahmen, Accent-Linie unter den Tabs und Accent-Ecken unten. 'Oben ausblenden' schaltet weiterhin auf den transparenten Schatten um.",
			"Der Kopier-Button ist jetzt ein lesbarer Chip (Inset-Stil, Accent-Text, leuchtender Rahmen bei Hover); das Kopierfenster hat die Accent-Titellinie bekommen.",
			"Der Nach-unten-Button ist jetzt ein dunkler Chip mit Accent-Pfeil.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: Sentinel-styled chat for SentiUI - shade panels behind the dock (movable), restyled tabs with an accent underline, a borderless edit box above or below the chat that borrows the channel color.",
			"Message filter: short channel names, clickable links with a copy popup, keyword highlighting with an alert sound, timestamps in the panel color.",
			"Class-colored player names, player levels for known players, spam throttle, sticky channels, hyperlink hover tooltips, per-frame copy button and window, scroll-to-bottom arrow, optional chat history across reloads.",
		},
		changesDE = {
			"Erste Version: Sentinel-Chat für SentiUI - Schatten-Panels hinter dem Dock (verschiebbar), Tabs mit Accent-Unterstrich, rahmenlose Eingabezeile über oder unter dem Chat in Kanalfarbe.",
			"Nachrichtenfilter: kurze Kanalnamen, klickbare Links mit Kopier-Popup, Keyword-Hervorhebung mit Sound, Zeitstempel in Panelfarbe.",
			"Klassenfarbene Spielernamen, Level bekannter Spieler, Spam-Bremse, Sticky-Kanäle, Link-Tooltips, Kopier-Button und -Fenster je Frame, Nach-unten-Pfeil, optionale Chat-Historie über Reloads.",
		},
	},
}
