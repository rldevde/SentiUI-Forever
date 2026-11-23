-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
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
