local _, ns = ...

ns.CHANGELOG = {
	{
		version = "1.1.1",
		date = "2026-11-25",
		changes = {
			"Minimap compatibility: when SentiUI_Minimap is loaded, the outfitter button opts into its '+' addon-button collector instead of floating as a separate ring button.",
		},
		changesDE = {
			"Minimap-Kompatibilitaet: Wenn SentiUI_Minimap geladen ist, meldet sich der Outfitter-Knopf in dessen '+'-Addon-Button-Sammlung an, statt als eigener Ringknopf zu schweben.",
		},
	},
	{
		version = "1.1.0",
		date = "2026-11-25",
		changes = {
			"SentiOutfitter is now a SentiUI module (SentiUI_Outfitter): it registers with the core, stores settings in SentiUIDB.modules.Outfitter and gets a page in /sui. Settings, saved sets and the bar position migrate from the standalone addon's saved variables on first load - nothing is lost.",
			"New /sui page: bar toggles (scale, combat alpha, names, vertical, lock), tooltip mode, sell protection, bag markers and the minimap button - all live-editable without /so.",
			"Everything else stays: the quick-swap bar, the sets window, sell buyback protection, bag outfit badges, the minimap button and /so.",
		},
		changesDE = {
			"SentiOutfitter ist jetzt ein SentiUI-Modul (SentiUI_Outfitter): Es registriert sich am Core, speichert in SentiUIDB.modules.Outfitter und bekommt eine Seite in /sui. Einstellungen, gespeicherte Sets und die Leistenposition werden beim ersten Laden aus den SavedVariables des Standalone uebernommen - nichts geht verloren.",
			"Neue /sui-Seite: Leisten-Schalter (Skalierung, Kampf-Alpha, Namen, vertikal, Sperre), Tooltip-Modus, Verkaufsschutz, Taschen-Markierungen und der Minimap-Knopf - alles live aenderbar ohne /so.",
			"Alles andere bleibt: Schnellwechsel-Leiste, Sets-Fenster, Rueckkauf-Verkaufsschutz, Taschen-Outfit-Markierungen, Minimap-Knopf und /so.",
		},
	},
}
