local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.8",
		changes = {
			"Training window joins the combat deferral: opening it mid-combat queues for after the fight with a chat note, and an open window hides on combat start and returns after (core S:CombatDeferWindow).",
		},
		changesDE = {
			"Trainings-Fenster haengt an der Kampf-Verzoegerung Oeffnen im Kampf wird mit Chat-Notiz bis nach dem Kampf zurueckgestellt, ein offenes Fenster versteckt sich bei Kampfbeginn und kommt danach wieder (Core S:CombatDeferWindow).",
		},
	},

	{
		version = "0.2.7",
		changes = {
			"Forbidden-call fix for the K keybind in combat: SPELLS_CHANGED and CRAFT_UPDATE can fire inside the keybind/craft-window dispatch that opens the spellbook - a handler executing there taints the client's protected FrameShow call right after. Both events are now only registered while their window is actually open via the polled WatchShown watcher, so the handler cannot run inside the input dispatch at all.",
		},
		changesDE = {
			"Forbidden-Call-Fix fuer die Taste K im Kampf: SPELLS_CHANGED und CRAFT_UPDATE koennen innerhalb des Tasten-/Craft-Dispatch feuern, der das Zauberbuch oeffnet - ein dort laufender Handler taintet den direkt folgenden geschuetzten FrameShow-Aufruf des Clients. Beide Events sind jetzt nur noch registriert, solange ihr Fenster tatsaechlich offen ist (gepollter WatchShown-Waechter) - der Handler kann im Input-Dispatch gar nicht mehr laufen.",
		},
	},

	{
		version = "0.2.6",
		changes = {
			"Interface-dispatch audit: the profession scan on CRAFT_UPDATE runs a frame outside the craft-window dispatch - the same dispatch family whose secret cooldown compare broke before.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Der Berufe-Scan auf CRAFT_UPDATE laeuft einen Frame ausserhalb des Craft-Fenster-Dispatch - dieselbe Dispatch-Familie, deren Secret-Cooldown-Vergleich vorher brach.",
		},
	},

	{
		version = "0.2.5",
		changes = {
			"Dispatcher rollback: the pet-craft scan listens to CRAFT_UPDATE again - the craft-frame state polling is removed.",
		},
		changesDE = {
			"Dispatcher-Rollback: Der Pet-Craft-Scan hoert wieder auf CRAFT_UPDATE - das Craft-Frame-Status-Polling ist entfernt.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"CRAFT_UPDATE replaced by craft-frame state polling - the event fires inside the craft window's protected update dispatch.",
		},
		changesDE = {
			"CRAFT_UPDATE durch Craft-Fenster-Zustandspolling ersetzt - das Event feuert im geschuetzten Update-Dispatch des Berufsfensters.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Escape-forbidden-call fix: the search box OnEscapePressed ran inside the Escape dispatch - Escape drops focus natively and the window joined UISpecialFrames so Escape closes it.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Der OnEscapePressed der Suchbox lief im Escape-Dispatch - Escape loest den Fokus nativ und das Fenster ist jetzt in UISpecialFrames, also schliesst es nativ.",
		},
	},

	{
		version = "0.2.2",
		changes = {
			"Fixed 'attempt to index global holder' on window open: the scroll-child frame was declared below the thumb/layout functions that capture it, so it resolved as a nil global - it is forward-declared now.",
		},
		changesDE = {
			"'attempt to index global holder' beim Fenster-Oeffnen behoben: Das Scroll-Child war unterhalb der Thumb-/Layout-Funktionen deklariert, die es erfassen, und loeste als nil-Global auf - es ist jetzt vordeklariert.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Trainers and the dungeon Journal are mutually exclusive - opening one closes the other.",
		},
		changesDE = {
			"Lehrer und Dungeon-Journal schließen sich gegenseitig - nur eines der Fenster kann offen sein.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Window rework: book icon header with accent divider, gold rules on section headers, zebra row striping, the list now sits in an inset card with a slim gold scroll thumb, slightly larger window.",
		},
		changesDE = {
			"Fenster überarbeitet: Kopfzeile mit Buch-Symbol und Akzent-Trennlinie, goldene Linien an Sektions-Überschriften, Zebra-Streifen in den Zeilen, die Liste liegt jetzt in einer Inset-Karte mit schmalem goldenem Scrollbalken, etwas größeres Fenster.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"Initial release: the trainer compendium as its own SentiUI module. Three tabs - Spells, Weapon skills, Professions - group everything your class and weapon masters still teach plus every unlearned profession recipe into learnable now / missing requirements / coming soon / later / ignored / known. Search box, profession filter chips, right-click to ignore entries (warlock tomes get marked learned), waypoint button on weapon-skill rows, spell and recipe tooltips with sources. Opens from the 'Trainers' plugin on the SentiUI Panel bottom bar or /suitr. Ignores and tome marks are saved per character.",
		},
		changesDE = {
			"Erstveröffentlichung: Das Lehrer-Kompendium als eigenes SentiUI-Modul. Drei Tabs - Zauber, Waffenfertigkeiten, Berufe - sortieren alles, was Klassen- und Waffenlehrer noch beibringen, plus jedes ungelernte Berufsrezept in jetzt lernbar / Voraussetzungen fehlen / bald / später / ignoriert / bekannt. Suchfeld, Berufs-Filterchips, Rechts-Klick ignoriert Einträge (Hexenmeister-Folianten werden als gelernt markiert), Wegpunkt-Knopf bei Waffenfertigkeiten, Zauber- und Rezept-Tooltips mit Quellen. Öffnet über das 'Lehrer'-Plugin in der unteren SentiUI-Leiste oder /suitr. Ignorierte und Folianten-Markierungen werden pro Charakter gespeichert.",
		},
	},
}
