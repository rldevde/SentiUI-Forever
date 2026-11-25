-- In-game changelog shown on SentiUI > Changelog.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.4",
		date = "2026-11-25",
		changes = {
			"The recipe list no longer jumps to the top on every refresh: crafting an item, bag updates or a learned recipe refill the list and the old code always reset the scroll to zero. The scroll position is kept now - it only resets when the profession itself changes.",
			"Reagents and links behave like the game's window: hovering a material row shows the item tooltip, shift-click on a material, the output item or a list row pastes its link into the chat box. Recipe links are built by hand (enchant:<id> + the real name) - the client's GetRecipeLink displays the generic craft spell name.",
			"Auctionator reagent search: the addon plants its Search button on Blizzard's professions frame, which this window parks off screen - so nothing ever showed. A new 'AH search' button on the recipe page (and a 'Search reagents (AH)' entry in the list row's right-click menu) feeds the recipe's materials into Auctionator's API directly. Only visible while Auctionator runs.",
		},
		changesDE = {
			"Die Rezeptliste springt nicht mehr bei jeder Aktualisierung nach oben: Herstellen, Taschen-Updates oder ein gelerntes Rezept füllten die Liste neu und der alte Code setzte den Scroll jedes Mal auf null. Die Position bleibt jetzt - zurückgesetzt wird nur beim Berufswechsel.",
			"Materialien und Links verhalten sich wie im Spiel-Fenster: Hover über einer Materialzeile zeigt den Item-Tooltip, Shift-Klick auf Material, Ergebnis-Item oder Listenzeile postet den Link ins Chatfenster. Rezept-Links werden per Hand gebaut (enchant:<id> + echter Name) - der clientseitige GetRecipeLink zeigt den generischen Berufszauber-Namen.",
			"Auctionator-Reagenziensuche: Das Addon baut seinen Such-Button in Blizzards Berufsfenster ein, das dieses Fenster ausserhalb des Bildschirms parkt - darum erschien nie etwas. Ein neuer 'AH-Suche'-Button auf der Rezeptseite (und 'Reagenzien suchen (AH)' im Rechtsklick-Menü der Listenzeilen) füttert die Materialien des Rezepts direkt an Auctionators API. Nur sichtbar, solange Auctionator läuft.",
		},
	},
	{
		version = "0.1.3",
		date = "2026-11-23",
		changes = {
			"Fix the profession tabs, the Stop button and the Professions key still doing nothing: the secure spell attribute only fires when it carries the spell NAME on this client, never the ID (same lesson SentiUI_Pally learned). Tab overlays and the K-keybind button now resolve their spell ID to a name before the attribute is set, falling back to the tab's OpenTradeSkill click if the name can't be resolved.",
		},
		changesDE = {
			"Berufs-Tabs, Stop-Button und Berufs-Taste taten weiterhin nichts: Das secure spell-Attribut feuert auf diesem Client nur mit dem ZauberNAMEN, nie der ID (dieselbe Lektion wie bei SentiUI_Pally). Tab-Overlays und der K-Tasten-Button loesen ihre Spell-ID jetzt zu einem Namen auf, bevor das Attribut gesetzt wird; ohne Namen greift der OpenTradeSkill-Fallback des Tabs.",
		},
	},
	{
		version = "0.1.2",
		date = "2026-11-23",
		changes = {
			"Fix dead profession tabs and the craft Stop button: their secure overlays set spell attributes inside an insecure PreClick handler, which taints the click dispatch so the cast dies silently. The overlays now carry their type/spell/macrotext attributes statically (refreshed when the tabs rebuild, never in combat), register both click phases and honor useOnKeyDown=false - the same proven shape as the secure reload overlay. The open profession's tab casts nothing, so clicking it can never toggle the window shut.",
			"Fix the close X and the Unlearn link not clicking: the full-width drag strip across the title bar won hit-testing over them on this client (same bug the messenger had). The window now registers for drag itself and only starts moving when the title band is grabbed - no click-eating overlay frame at all.",
		},
		changesDE = {
			"Tote Berufs-Tabs und toter Stop-Button behoben: Ihre Secure-Overlays setzten die Zauber-Attribute in einem unsicheren PreClick-Handler, wodurch der Klick-Dispatch kontaminiert wurde und der Cast still starb. Die Overlays tragen ihre type/spell/macrotext-Attribute jetzt statisch (beim Tab-Aufbau erneuert, nie im Kampf), registrieren beide Klick-Phasen und nutzen useOnKeyDown=false - dieselbe bewaehrte Form wie das Secure-Reload-Overlay. Der Tab des offenen Berufs wirkt nichts, ein Klick darauf kann das Fenster also nie zuklappen.",
			"Schliess-X und Verlernen-Link klickten nicht: Der Drag-Streifen ueber der Titelzeile gewann auf diesem Client das Hit-Testing gegen sie (derselbe Bug wie im Messenger). Das Fenster registriert Drag jetzt selbst und bewegt sich nur beim Greifen des Titelbands - ganz ohne klickfressenden Overlay-Frame.",
		},
	},
	{
		version = "0.1.1",
		date = "2026-11-23",
		changes = {
			"Fix dead clicks: the parked game window was only invisible - alpha 0 keeps every child button hit-testing, so the hidden Blizzard list ate the clicks over our window. The game's frame is now parked off screen (still shown, still running) and re-parked if anything moves it back.",
		},
		changesDE = {
			"Tote Klicks behoben: Das geparkte Spiel-Fenster war nur unsichtbar - Alpha 0 laesst jeden Kind-Button weiter klickbar, die versteckte Blizzard-Liste fraß die Klicks ueber unserem Fenster. Das Spiel-Fenster wird jetzt ausserhalb des Bildschirms geparkt (weiterhin sichtbar aktiv) und neu geparkt, wenn etwas es zurueckschiebt.",
		},
	},
	{
		version = "0.1.0",
		date = "2026-11-23",
		changes = {
			"New professions window in SentiUI style: a recipe list (search, Skill-ups / Have materials / Slot filters, collapsible categories, favorites and tracking via right-click) on the left, the picked recipe with materials and owned counts on the right, and a create footer with amount stepper, Create all and a progress bar. Profession tabs sit under the title and switch by casting the profession's spell; the Professions key (K) opens the last used one and closes the window again. The game's own window stays parked underneath for NPC and guild lists.",
		},
		changesDE = {
			"Neues Berufsfenster im SentiUI-Stil: links eine Rezeptliste (Suche, Skill-ups- / Materialien- / Slot-Filter, einklappbare Kategorien, Favoriten und Tracking per Rechtsklick), rechts das gewählte Rezept mit Materialien und Bestand, unten ein Herstellen-Bereich mit Mengenwahl, 'Alle herstellen' und Fortschrittsbalken. Berufs-Tabs unter dem Titel wechseln durch Wirken des Berufszaubers; die Berufs-Taste (K) öffnet den zuletzt genutzten Beruf und schließt das Fenster wieder. Das Spiel-Fenster bleibt darunter geparkt für NPC- und Gilden-Listen.",
		},
	},
}
