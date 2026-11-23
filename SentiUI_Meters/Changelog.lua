-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.4",
		date = "2026-11-23",
		changes = {
			"Slimmer windows: default width 210 -> 160 px (existing installs parked on the old default are migrated; the Width slider still allows any size).",
		},
		changesDE = {
			"Schmalere Fenster: Standardbreite 210 -> 160 px (bestehende Installationen auf dem alten Standard werden migriert; der Breiten-Slider erlaubt weiter jede Groesse).",
		},
	},
	{
		version = "0.1.3",
		date = "2026-11-23",
		changes = {
			"Running overall: the 'Overall' segment is now a real accumulated total - every session the client reports (expired fights plus the live one) is summed per source and keeps counting through new fights. Interrupts, dispels, deaths and every other metric accumulate the same way.",
			"Lists survive reloads: the accumulator lives in the saved variables, so overall data is still there after /reload or relog instead of resetting.",
			"Reset prompt: entering an instance with stored meter data asks whether to reset the lists (Yes = C_DamageMeter.ResetAllCombatSessions + the saved accumulator). The window menu also got a 'Reset data' entry that raises the same prompt.",
		},
		changesDE = {
			"Durchzaehlender Gesamtwert: das Segment 'Gesamt' ist jetzt eine echte Summe - jede Session die der Client meldet (abgelaufene Kaempfe plus der laufende) wird pro Quelle aufsummiert und zaehlt ueber Kaempfe hinweg weiter. Unterbrechungen, Bannungen, Tode und jede andere Metrik summieren genauso.",
			"Listen ueberleben Reloads: der Akkumulator liegt in den SavedVariables, Gesamt-Daten bleiben nach /reload oder Relog erhalten statt zurueckzusetzen.",
			"Reset-Abfrage: beim Betreten einer Instanz mit vorhandenen Meter-Daten fragt ein Dialog, ob die Listen zurueckgesetzt werden sollen (Ja = C_DamageMeter.ResetAllCombatSessions + gespeicherter Akkumulator). Das Fenstermenue bekam ebenfalls einen 'Daten zuruecksetzen'-Eintrag mit demselben Dialog.",
		},
	},
	{
		version = "0.1.2",
		date = "2026-11-23",
		changes = {
			"More windows: the meter menu got a '+ New window' entry that turns on the next pool dock (up to four) and chains it onto the left edge of the previous shown one, toward the action bars - each with its own metric and segment like the first two.",
			"Menu edge fix: the popup's top border read as missing - the flat 1px backdrop edge was too faint. The menu now draws its own four accent edge strips so the frame is visibly complete.",
		},
		changesDE = {
			"Mehr Fenster: das Meter-Menue bekam einen '+ Neues Fenster'-Eintrag, der das naechste Dock aus dem Pool einschaltet (bis zu vier) und an die linke Kante des letzten sichtbaren dockt, Richtung Aktionsleisten - jedes mit eigener Metrik und eigenem Segment.",
			"Menue-Rand-Fix: der obere Rand des Popups wirkte wie fehlend - die flache 1px-Backdrop-Kante war zu schwach. Das Menue zeichnet jetzt eigene Akzent-Kanten auf allen vier Seiten.",
		},
	},
	{
		version = "0.1.1",
		date = "2026-11-23",
		changes = {
			"Fixed window sizes: the meters no longer grow with their entry count - width and a new height setting frame a clipped view the list scrolls inside of, with a gold thumb on the right edge and mouse-wheel scrolling (a full raid's threat list is 40 rows).",
			"Combat-safe rows: the 40-row pool is created at enable instead of lazily, so threat/damage lists render mid-fight without protected-frame errors and the wheel keeps scrolling in combat.",
		},
		changesDE = {
			"Feste Fenstergroessen: die Meter wachsen nicht mehr mit der Eintragszahl - Breite und die neue Hoehen-Einstellung rahmen eine Clip-View ein, in der die Liste scrollt, mit Gold-Thumb rechts und Mausrad (die Bedrohungsliste eines Raids hat 40 Zeilen).",
			"Kampffeste Zeilen: der 40-Zeilen-Pool wird beim Enable gebaut statt lazy, sodass Bedrohungs-/Schadenslisten mitten im Kampf rendern ohne Protected-Frame-Fehler und das Mausrad weiter scrollt.",
		},
	},
	{
		version = "0.1.0",
		date = "2026-11-23",
		changes = {
			"New module: up to two dockable meter windows beside the loot chat panel. Each dock shows its own metric from the client's damage meter data - damage done, DPS, healing, HPS, absorbs, damage taken, interrupts, dispels or deaths - plus a threat mode via UnitDetailedThreatSituation.",
			"Per-dock setup: right-click a meter's title to pick its metric and segment (current fight / overall); the same settings live on the Meters options page. Docks are movers and carry the Sentinel panel look with class-colored bars and a gold leader edge.",
		},
		changesDE = {
			"Neues Modul: bis zu zwei andockbare Meter-Fenster neben dem Plündern-Chatpanel. Jedes Dock zeigt eine eigene Metrik aus den Schadensmeter-Daten des Clients - Schaden, DPS, Heilung, HPS, Absorptionen, erlittener Schaden, Unterbrechungen, Bannungen oder Tode - plus ein Bedrohungs-Modus ueber UnitDetailedThreatSituation.",
			"Einstellung pro Dock: Rechtsklick auf den Meter-Titel waehlt Metrik und Segment (aktueller Kampf / Gesamt); dieselben Optionen liegen auf der Meter-Einstellungsseite. Docks sind Movers im Sentinel-Panel-Look mit klassengefaerbten Balken und Goldkante fuer den Ersten.",
		},
	},
}
