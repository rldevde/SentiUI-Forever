local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.12",
		date = "2026-11-22",
		changes = {
			"Close button replaced with the shared S.Widgets.Close — consistent Sentinel look instead of the raw hand-built x text button.",
		},
		changesDE = {
			"Schliessen-Button durch das gemeinsame S.Widgets.Close ersetzt — einheitliches Sentinel-Aussehen statt des manuell gebauten x-Text-Buttons.",
		},
	},
	{
		version = "0.1.11",
		date = "2026-11-22",
		changes = {
			"Filter chips use the shared Sentinel tab chip now: dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active chip - one design language across the whole suite instead of scattered boxes.",
		},
		changesDE = {
			"Die Filter-Chips nutzen jetzt den gemeinsamen Sentinel-Tab-Chip: dunkler Inset-Koerper mit 2px Akzent-Klinge an der linken Kante, die bei Hover glimmt und auf dem aktiven Chip brennt - eine Designsprache fuer die ganze Suite statt verstreuter Kaestchen.",
		},
	},
	{
		version = "0.1.10",
		date = "2026-11-22",
		changes = {
			"Window now closes on Escape via the shared S.EscClosable helper instead of a UISpecialFrames entry - addon-written entries in that game table taint the Escape dispatch, which made protected calls (spell stop, reload) fail and get blamed on the addon.",
		},
		changesDE = {
			"Fenster schliesst jetzt per gemeinsamem S.EscClosable-Helfer auf Escape statt ueber einen UISpecialFrames-Eintrag - von Addons geschriebene Eintraege in dieser Spiel-Tabelle tainten den Escape-Dispatch, weshalb geschuetzte Aufrufe (Zauber abbrechen, Neuladen) fehlschlugen und dem Addon angelastet wurden.",
		},
	},
	{
		version = "0.1.9",
		date = "2026-11-22",
		changes = {
			"The dungeon map no longer registers GLOBAL_MOUSE_UP - the event fires inside the input dispatch that then delivers the click to a button, so any addon Lua there taints it and kills the protected call behind it (Reload in the addon list, SpellStopCasting on Escape). Drag release is detected by polling the button state in OnUpdate.",
		},
		changesDE = {
			"Die Dungeon-Karte registriert GLOBAL_MOUSE_UP nicht mehr - das Event feuert im selben Input-Dispatch, der danach den Klick an einen Button ausliefert; Addon-Lua dort vergiftet den Dispatch und tötet den geschützten Aufruf dahinter (Reload in der Addon-Liste, SpellStopCasting bei Escape). Das Drag-Ende wird jetzt per Button-State-Polling im OnUpdate erkannt.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Compile fix: a slot-parser loop assigned to its loop variable (LuaJIT const-assign error) - Page.lua failed to load. Uses a local instead.",
		},
		changesDE = {
			"Compile-Fix: Eine Slot-Parser-Schleife wies ihrer Schleifenvariable zu (LuaJIT-Const-Assign-Fehler) - Page.lua lud nicht. Nutzt jetzt ein Local.",
		},
	},

	{
		version = "0.1.7",
		changes = {
			"Journal window joins the combat deferral: opening it mid-combat queues for after the fight with a chat note, and an open window hides on combat start and returns after (core S:CombatDeferWindow).",
		},
		changesDE = {
			"Journal-Fenster haengt an der Kampf-Verzoegerung Oeffnen im Kampf wird mit Chat-Notiz bis nach dem Kampf zurueckgestellt, ein offenes Fenster versteckt sich bei Kampfbeginn und kommt danach wieder (Core S:CombatDeferWindow).",
		},
	},

	{
		version = "0.1.6",
		changes = {
			"Interface-dispatch audit: the map fallback no longer calls ToggleWorldMap via pcall - it goes through the same guarded call path as the protected waypoint APIs.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Der Karten-Fallback ruft ToggleWorldMap nicht mehr per pcall - er laeuft ueber denselben gehaerteten Call-Pfad wie die geschuetzten Waypoint-APIs.",
		},
	},

	{
		version = "0.1.5",
		changes = {
			"Escape-forbidden-call fix: search box OnEscapePressed/OnEditFocusLost and the dungeon map OnHide hook ran inside the Escape dispatch - hint syncs via OnTextChanged, stale drag state resets on show instead.",
		},
		changesDE = {
			"Escape-Blockier-Fix: OnEscapePressed/OnEditFocusLost der Suchbox und der OnHide-Hook der Dungeon-Karte liefen im Escape-Dispatch - der Hint synct ueber OnTextChanged, Drag-State wird beim Anzeigen zurueckgesetzt.",
		},
	},

	{
		version = "0.1.4",
		changes = {
			"Remaining English bits localized: profession tags on quests use localized names (Blacksmithing/Mining), faction names fall back to localized strings when the client globals are missing, and quest start items show the client's localized item name.",
		},
		changesDE = {
			"Restliches Englisch lokalisiert: Berufs-Tags bei Quests nutzen lokalisierte Namen (Schmiedekunst/Bergbau), Fraktionsnamen fallen auf lokalisierte Strings zurück, wenn die Client-Globals fehlen, und Queststart-Gegenstände zeigen den lokalisierten Item-Namen des Clients.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Fixed 'forbidden call: Button:SetPassThroughButtons' spam on load - the client protects that call, so UIPanelButtonTemplate/UIPanelCloseButton are replaced by Sentinel-styled homegrown buttons (map zoom +/-/floor buttons, window close).",
		},
		changesDE = {
			"'Forbidden call: Button:SetPassThroughButtons'-Spam beim Laden behoben - der Aufruf ist auf dem Client geschützt, daher wurden UIPanelButtonTemplate/UIPanelCloseButton durch eigene Buttons im Sentinel-Stil ersetzt (Karten-Zoom +/- und Etagen-Knöpfe, Fenster-Schließen).",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Waypoint buttons work again: when 'securecall' is missing the calls were silently skipped (issecurefunction is true for every C API) - they now fall back to a direct guarded call.",
			"Quest chains show progress: done steps get a green number and '(done)' tag, pending steps a gold number; steps inside this dungeon keep the rune marker and their waypoint button.",
			"Journal and Trainers are mutually exclusive - opening one closes the other.",
		},
		changesDE = {
			"Wegpunkt-Buttons gehen wieder: Ohne 'securecall' wurden die Aufrufe still übersprungen (issecurefunction ist für jede C-API wahr) - sie fallen jetzt auf einen direkten abgesicherten Aufruf zurück.",
			"Questreihen zeigen Fortschritt: erledigte Schritte bekommen grüne Nummer und '(erledigt)', offene eine goldene Nummer; Schritte in der Instanz behalten Rune und Wegpunkt-Knopf.",
			"Journal und Lehrer schließen sich gegenseitig - nur eines der Fenster kann offen sein.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Boss loot rows now show the item icon in a dark socket next to the quality-colored name instead of a bare indented line.",
		},
		changesDE = {
			"Boss-Beute zeigt jetzt das Gegenstands-Symbol in einer dunklen Fassung neben dem qualitätsgefärbten Namen statt einer nackten eingerückten Zeile.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"New module: the My-Social dungeon compendium as a standalone SentiUI addon.",
			"Dungeon list with search and aliases, Sentinel-styled detail view with art banner.",
			"Bosses tab with portraits, levels and quality-colored loot rows.",
			"Quests tab with faction filter, quest book page, chains, waypoints and rewards.",
			"Map tab with floor maps, boss/entrance/quest pins, zoom and drag panning.",
			"Panel plugin in the lower bar opens the window; /suij toggles it.",
		},
		changesDE = {
			"Neues Modul: Das My-Social-Dungeon-Kompendium als eigenständiges SentiUI-Addon.",
			"Dungeonliste mit Suche und Aliasen, Detailansicht im Sentinel-Stil mit Artwork-Banner.",
			"Bosse-Tab mit Porträts, Stufen und qualitätsgefärbten Beute-Zeilen.",
			"Quests-Tab mit Fraktionsfilter, Questbuch, Reihen, Wegpunkten und Belohnungen.",
			"Karten-Tab mit Ebenenkarten, Boss-/Eingangs-/Quest-Pins, Zoom und Verschieben.",
			"Panel-Plugin in der unteren Leiste öffnet das Fenster; /suij schaltet es um.",
		},
	},
}
