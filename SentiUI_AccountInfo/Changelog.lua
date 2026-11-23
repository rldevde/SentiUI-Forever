local _, ns = ...

ns.CHANGELOG = {
	{
		version = "1.5.4",
		date = "2026-11-22",
		changes = {
			"The sidebar navigation uses the shared Sentinel tab chip now: dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active page, page icons kept - one design language across the whole suite instead of the module's own constants.",
		},
		changesDE = {
			"Die Seitenleisten-Navigation nutzt jetzt den gemeinsamen Sentinel-Tab-Chip: dunkler Inset-Koerper mit 2px Akzent-Klinge an der linken Kante, die bei Hover glimmt und auf der aktiven Seite brennt, Seiten-Icons bleiben - eine Designsprache fuer die ganze Suite statt eigener Konstanten.",
		},
	},
	{
		version = "1.5.3",
		date = "2026-11-22",
		changes = {
			"Fixed: the addon could be invisible to the client and the scanner stayed silent. Removed a game-type gate no other module uses, and character name/realm lookups now use the APIs that actually exist on this client (GetUnitName/GetRealmName) with pcall fallbacks.",
			"Realm resolution hardened like the reference UIs do it: when the client reports an empty realm for a whole session, the realm this character was already saved under is used instead - and once the character key resolves it stays fixed for the session, so a hiccup in the APIs can never split the record.",
			"A session without any realm name no longer blocks the scan at all: the record is written under a bare 'Name-' key and folded into the real 'Name-Realm' key once a realm resolves. realmName cvar added as an extra realm source.",
			"Error isolation: one throwing event or internal callback can no longer kill the scanner's hooks - handlers run pcall'd and report to chat instead of aborting the chain.",
			"New /sai scan diagnostic: prints the boot/db/key state and forces a rescan so a dead link in the scan chain shows up in chat instead of failing silently.",
		},
		changesDE = {
			"Fix: das Addon konnte für den Client unsichtbar sein und der Scanner blieb stumm. Ein Game-Type-Gate entfernt, das kein anderes Modul nutzt, und Char-/Realm-Namen nutzen jetzt die APIs, die auf diesem Client existieren (GetUnitName/GetRealmName), mit pcall-Fallbacks.",
			"Realm-Auflösung gehärtet wie in den Referenz-UIs: Meldet der Client eine Session lang einen leeren Realm, wird der Realm genutzt, unter dem der Charakter bereits gespeichert war - und sobald der Char-Key aufgelöst ist, bleibt er für die Session fix, damit ein API-Aussetzer den Eintrag nie teilt.",
			"Eine Session ganz ohne Realm-Name blockiert den Scan nicht mehr: Der Eintrag wird unter dem bloßen 'Name-'-Key angelegt und in den echten 'Name-Realm'-Key überführt, sobald ein Realm auflöst. realmName-CVar als zusätzliche Realm-Quelle.",
			"Fehler-Isolation: ein werfender Event- oder interner Callback kann die Scanner-Hooks nicht mehr killen - Handler laufen per pcall und melden Fehler im Chat statt die Kette abzubrechen.",
			"Neuer /sai scan Diagnosebefehl: zeigt Boot-/DB-/Key-Status und erzwingt einen Rescan, damit ein totes Glied in der Scan-Kette im Chat sichtbar wird statt still zu scheitern.",
		},
	},
	{
		version = "1.5.2",
		date = "2026-11-22",
		changes = {
			"Fixed: the current character was never scanned when PLAYER_ENTERING_WORLD fired before the module enable. The scanner now runs an initial scan on boot, retrying until the realm name is known.",
		},
		changesDE = {
			"Fix: der aktuelle Charakter wurde nie gescannt, wenn PLAYER_ENTERING_WORLD vor dem Modul-Enable feuerte. Der Scanner scannt jetzt beim Boot, mit Wiederholung bis der Realm-Name bekannt ist.",
		},
	},
	{
		version = "1.5.1",
		date = "2026-11-22",
		changes = {
			"No more 'unknown event' spam at login: RegisterEvent now validates via C_EventUtils.IsEventValid, so events this client dropped (PLAYERBANKBAGSLOTS_CHANGED, PLAYERREAGENTBANKSLOTS_CHANGED) are skipped quietly. Bank data still scans on BANKFRAME_OPENED.",
		},
		changesDE = {
			"Kein 'unknown event'-Spam mehr beim Login: RegisterEvent validiert über C_EventUtils.IsEventValid - Events, die dieser Client nicht kennt (PLAYERBANKBAGSLOTS_CHANGED, PLAYERREAGENTBANKSLOTS_CHANGED), werden still übersprungen. Bankdaten werden weiterhin bei BANKFRAME_OPENED gescannt.",
		},
	},
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
