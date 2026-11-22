-- In-game changelog shown on SentiUI > Changelog.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.3.9",
		date = "2026-11-22",
		changes = {
			"Fix the close X (hub) and the card header buttons not clicking: the full-width drag strip covered them and won hit-testing. The strips now stop short of the button row.",
		},
		changesDE = {
			"Fix: das X (Hub) und die Kopf-Buttons der Unterhaltungskarte ließen sich nicht klicken - der volle Drag-Streifen lag ueber ihnen und gewann den Hit. Die Streifen enden jetzt vor der Button-Reihe.",
		},
	},
	{
		version = "0.3.8",
		date = "2026-11-22",
		changes = {
			"Fix sent messages appearing twice: sendTo echoes the line right away and the CHAT_MSG_WHISPER_INFORM event then added it a second time - INFORM lines that repeat the just-echoed text are now skipped.",
		},
		changesDE = {
			"Fix: gesendete Nachrichten kamen doppelt - sendTo echot die Zeile sofort und das CHAT_MSG_WHISPER_INFORM-Event hat sie ein zweites Mal eingetragen; INFORM-Zeilen, die den gerade gechoten Text wiederholen, werden jetzt uebersprungen.",
		},
	},
	{
		version = "0.3.7",
		date = "2026-11-22",
		changes = {
			"Conversation windows now close on Escape via the shared S.EscClosable helper instead of UISpecialFrames entries - addon-written entries in that game table taint the Escape dispatch.",
		},
		changesDE = {
			"Unterhaltungsfenster schliessen jetzt per gemeinsamem S.EscClosable-Helfer auf Escape statt ueber UISpecialFrames-Eintraege - von Addons geschriebene Eintraege in dieser Spiel-Tabelle tainten den Escape-Dispatch.",
		},
	},
	{
		version = "0.3.6",
		changes = {
			"Messenger windows: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.",
		},
		changesDE = {
			"Das Fenster haengt an der Kampf-Verzoegerung: Oeffnen im Kampf wird mit Chat-Notiz nach dem Kampf nachgeholt, ein offenes Fenster versteckt sich bei Kampfbeginn und kehrt danach zurueck.",
		},
	},

	{
		version = "0.3.5",
		changes = {
			"Escape-forbidden-call fix: the copy window's OnEscapePressed ran inside the Escape dispatch - the window is in UISpecialFrames, so Escape closes it natively.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Der OnEscapePressed des Copy-Fensters lief im Escape-Dispatch - das Fenster steht in UISpecialFrames, Escape schliesst es nativ.",
		},
	},

	{
		version = "0.3.4",
		changes = {
			"The conversation window is a real mover now: its own entry in move mode and Movers.Save persistence replace the hand-rolled saveSpot/restoreSpot pair (same store, nearest-anchor format).",
		},
		changesDE = {
			"Das Unterhaltungsfenster ist jetzt ein echter Mover: eigener Eintrag im Verschiebe-Modus und Movers.Save-Persistenz ersetzen das handgerollte saveSpot/restoreSpot-Paar (gleicher Speicher, Nearest-Anchor-Format).",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"The hub's title-drag now saves through Movers.Save - nearest-anchor format plus a MoversChanged event, instead of a hand-rolled center offset that mixed frame-space and UIParent-space coordinates.",
		},
		changesDE = {
			"Der Titel-Drag des Hubs speichert jetzt über Movers.Save - Nearest-Anchor-Format plus MoversChanged-Event, statt eines handgerollten Mittelpunkts-Offsets, der Frame- und UIParent-Koordinaten vermischte.",
		},
	},
	{
		version = "0.3.2",
		changes = {
			"Tile strip default anchor now docks above whichever left-side strip is highest - chat tab row, XP bar or a rep bar stacked above it - so tiles no longer sit inside a data bar.",
			"Tiles got a small 'x' on the top-right corner (fades in on hover): clicking it deletes that conversation, the same as the hub's delete - an open card for it closes too.",
		},
		changesDE = {
			"Standard-Anker der Kachel-Leiste dockt jetzt über der höchsten linken Leiste - Chat-Tab-Zeile, XP-Leiste oder eine darüber gestapelte Ruf-Leiste - die Kacheln liegen nicht mehr in einer Datenleiste.",
			"Kacheln haben jetzt ein kleines 'x' an der oberen rechten Ecke (erscheint bei Hover): Klick löscht die Unterhaltung wie im Hub - eine offene Karte davon schließt mit.",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Fixed the header level: the German client abbreviates level as 'St.' with no number placeholder, so 'St. Paladin' lost the actual level - it now prints the number directly ('19 · Paladin').",
			"Moved the tile strip's default: it now anchors above the chat's tab row (GeneralDockManager) instead of the chat panel's top edge, which a data bar can occupy - no more tiles hiding inside the XP bar.",
		},
		changesDE = {
			"Kopf-Level gefixt: Der deutsche Client kürzt Level als 'St.' ohne Zahlenplatzhalter ab, wodurch 'St. Paladin' die eigentliche Stufe verlor - jetzt wird die Zahl direkt ausgegeben ('19 · Paladin').",
			"Neuer Standard-Anker der Kachel-Leiste: sie dockt jetzt über der Chat-Tab-Zeile (GeneralDockManager) statt an der Oberkante des Chat-Panels, die eine Datenleiste belegen kann - die Kacheln landen nicht mehr in der XP-Leiste.",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Header info line: the card (and the hub's thread) now show level, localized class name and guild under the sender's name - learned from the sender's GUID and probed by name.",
			"Header actions on the card: I = group invite, B = ignore, C = copy history, > = open in hub, x = close. Hovering each shows its meaning.",
			"Copy history window: the whole conversation as selectable plain text, every line with a timestamp (dd.mm hh:mm) - opened from the card's C button for copying the chat log out of the game. The conversation store already keeps every line's timestamp persistently.",
		},
		changesDE = {
			"Kopf-Infozeile: Die Karte (und der Thread im Hub) zeigen jetzt Level, lokalisierten Klassennamen und Gilde unter dem Absendernamen - gelernt aus der GUID des Absenders und per Name geprüft.",
			"Kopf-Aktionen auf der Karte: I = Gruppeneinladung, B = ignorieren, C = Verlauf kopieren, > = im Hub öffnen, x = schließen. Hover zeigt die Bedeutung.",
			"Verlauf-Kopierfenster: die ganze Unterhaltung als markierbarer Reintext, jede Zeile mit Zeitstempel (TT.MM HH:MM) - über den C-Knopf der Karte geöffnet, um den Chat-Log aus dem Spiel zu kopieren. Der Speicher hält den Zeitstempel jeder Zeile ohnehin persistent.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Moved the default tile strip: it now sits above the chat panel's TOP-LEFT edge and grows rightward like a tab row (was: top-right corner growing left). The preview toast follows to the left edge. /sui reset or right-click the mover handle once if you want the new default.",
		},
		changesDE = {
			"Neue Standard-Position der Kachel-Leiste: sie sitzt jetzt über der OBEREN LINKEN Kante des Chat-Panels und wächst nach rechts wie eine Tab-Reihe (vorher: obere rechte Ecke, nach links wachsend). Der Vorschau-Toast folgt an die linke Kante. /sui reset oder einmal Rechtsklick auf den Mover-Griff für den neuen Default.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"The conversation window now opens on its own for a new incoming whisper (option 'Open window on whisper', on by default).",
			"The reply key (r) opens the last whisperer's conversation window instead of the plain chat input - falls back to the game's own reply box if no whisper was recorded yet (option 'Reply key opens window').",
			"The tile strip renders on the MEDIUM strata so frames above LOW (unit frames, panels) can no longer cover it.",
		},
		changesDE = {
			"Das Unterhaltungsfenster öffnet jetzt bei eingehendem Whisper von selbst (Option 'Fenster bei Whisper öffnen', standardmäßig an).",
			"Die Antwort-Taste (r) öffnet das Fenster des letzten Flüsterers statt der Chat-Eingabe - ohne aufgezeichneten Whisper fällt es auf das normale Antwortfeld zurück (Option 'Antwort-Taste öffnet Fenster').",
			"Die Kachel-Leiste rendert auf der MEDIUM-Ebene, damit Frames darüber (Unitframes, Panels) sie nicht mehr verdecken können.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Whisper tiles: a row of small squares above the left chat panel, one per recent conversation - the sender's initial in their class color, unread count and pin marker. Left-click opens that chat's own window, right-click opens it in the hub, hovering shows the name and last line. The strip is a mover: /sui unlock to drag it wherever you want.",
			"Conversation card: each chat gets its own window - class-colored title, scrollable thread with clickable links, reply box and a button that expands the conversation into the hub. Draggable by its title bar, the position persists; Escape or the X tucks it away.",
			"New whisper preview: a small toast above the tiles flashes the sender and first line for a few seconds - clicking it opens the card.",
		},
		changesDE = {
			"Whisper-Kacheln: eine Reihe kleiner Quadrate über dem linken Chat-Panel, eine pro letzter Unterhaltung - Initial in Klassenfarbe, Ungelesen-Zahl und Pin-Markierung. Linksklick öffnet das eigene Fenster des Chats, Rechtsklick öffnet ihn im Hub, Hover zeigt Name und letzte Zeile. Die Leiste ist ein Mover: /sui unlock zum Verschieben.",
			"Konversations-Karte: jeder Chat bekommt ein eigenes Fenster - klassenfarbiger Titel, scrollbarer Thread mit klickbaren Links, Antwortbox und ein Knopf, der die Unterhaltung im Hub öffnet. An der Titelleiste verschiebbar, die Position bleibt erhalten; Escape oder X legt sie weg.",
			"Vorschau bei neuem Whisper: ein kleiner Toast über den Kacheln blendet Absender und erste Zeile einige Sekunden ein - ein Klick öffnet die Karte.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: a whisper hub in the Sentinel look. One window for every conversation - search and list on the left (pinned first, last line and unread count), the picked chat's thread on the right with its own reply box. Open with /smsg or /sm, from the settings page, or shift the window itself via /sui unlock.",
			"Conversations persist per account (80 lines each, oldest unpinned trimmed past 40 chats); Battle.net whispers last for the session. Class-colored names, clickable item/spell links, optional timestamps, unread badge on the minimap button and a throttled whisper sound.",
			"Optional away auto-reply: answers an incoming whisper once per person every 15 minutes while you are flagged away.",
		},
		changesDE = {
			"Erste Version: ein Whisper-Hub im Sentinel-Look. Ein Fenster für alle Unterhaltungen - Suche und Liste links (angepinnt zuerst, letzte Zeile und Ungelesen-Zahl), der Thread des gewählten Chats rechts mit eigener Antwortbox. Öffnen per /smsg oder /sm, über die Einstellungen oder verschieben per /sui unlock.",
			"Unterhaltungen bleiben accountweit erhalten (je 80 Zeilen, über 40 Chats werden die ältesten ungepinnten gekürzt); Battle.net-Whispers nur für die Sitzung. Klassenfarbige Namen, klickbare Item-/Zauber-Links, optionale Zeitstempel, Ungelesen-Zähler am Minimap-Button und gedrosselter Whisper-Sound.",
			"Optionale AFK-Automatwort: beantwortet eingehende Whispers einmal pro Person alle 15 Minuten, solange du als abwesend markiert bist.",
		},
	},
}
