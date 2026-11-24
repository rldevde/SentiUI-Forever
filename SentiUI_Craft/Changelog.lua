-- In-game changelog shown on SentiUI > Changelog.
local _, ns = ...

ns.CHANGELOG = {
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
