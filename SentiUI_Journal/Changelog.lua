local _, ns = ...

ns.CHANGELOG = {
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
