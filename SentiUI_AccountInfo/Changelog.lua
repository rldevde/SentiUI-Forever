local _, ns = ...

ns.CHANGELOG = {
	{
		version = "1.5.0",
		date = "2026-11-22",
		changes = {
			"SentiAccountInfo is now the SentiUI module SentiUI_AccountInfo: same window, same data (SentiAccountInfoDB carries over), registered under SentiUI > AccountInfo with an enable switch.",
			"Everything stays: dashboard, characters, search, per-character view, statistics, lockouts, currency/reputation, recipes, sync (export/import strings) and settings - plus item tooltips showing who owns what.",
			"The own minimap button is gone - SentiUI's minimap button and the new panel bar plugin cover it. Escape closes the window via S.EscClosable instead of UISpecialFrames.",
			"A disabled module is fully inert now: scanning, events and tooltip hooks only start when the module is enabled.",
		},
		changesDE = {
			"SentiAccountInfo ist jetzt das SentiUI-Modul SentiUI_AccountInfo: gleiches Fenster, gleiche Daten (SentiAccountInfoDB bleibt erhalten), registriert unter SentiUI > AccountInfo mit Aktiv-Schalter.",
			"Alles bleibt: Übersicht, Charaktere, Suche, Einzelcharakter, Statistiken, Lockouts, Währung/Ruf, Rezepte, Sync (Export-/Import-Strings) und Einstellungen - plus Item-Tooltips, die zeigen, wer was besitzt.",
			"Der eigene Minimap-Button entfällt - der SentiUI-Minimap-Button und das neue Panel-Leisten-Plugin decken das ab. Escape schließt das Fenster über S.EscClosable statt UISpecialFrames.",
			"Ein deaktiviertes Modul ist jetzt komplett inert: Scannen, Events und Tooltip-Hooks starten erst, wenn das Modul aktiv ist.",
		},
	},
}
