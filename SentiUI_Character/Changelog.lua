-- In-game changelog for the SentiUI > Changelog page.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.10",
		changes = {
			"Exposed the module API (Open/Close/Toggle per page) on the registered module so sibling addons can open exact window pages without calling the game's Toggle* bookkeeping functions.",
		},
		changesDE = {
			"Die Modul-API (Open/Close/Toggle pro Seite) am registrierten Modul verfuegbar gemacht, damit Schwestern-Addons exakte Fensterseiten oeffnen koennen ohne die Toggle*-Bookkeeping-Funktionen des Spiels zu rufen.",
		},
	},

	{
		version = "0.2.9",
		changes = {
			"Removed the ShowUIPanel post-hook: it ran our window code inside every managed-panel open dispatch (spellbook, talents, map, friends...), tainting the client's follow-up panel management - other windows opened broken. The CharacterFrame visibility watcher now covers every open path (key, micro menu, API) and toggles our window instead.",
		},
		changesDE = {
			"ShowUIPanel-Post-Hook entfernt: Er lief mit unserem Fenster-Code in jedem Panel-Oeffnungs-Dispatch (Zauberbuch, Talente, Karte, Freunde...) und taintete die Panel-Verwaltung des Clients - andere Fenster oeffneten kaputt. Der CharacterFrame-Waechter deckt jetzt alle Oeffnungswege ab (Taste, Mikromenue, API) und schaltet unser Fenster.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"The parked Blizzard character frame now hides via S.WatchShown polling instead of an OnShow hook - the frame is shown inside the ShowUIPanel dispatch, where addon Lua taints the client's follow-up protected calls.",
		},
		changesDE = {
			"Der geparkte Blizzard-Charakterframe wird jetzt per S.WatchShown-Polling versteckt statt per OnShow-Hook - der Frame wird im ShowUIPanel-Dispatch gezeigt, wo Addon-Lua die folgenden geschuetzten Aufrufe taintet.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"Character page layout reworked into a logical grid: left gear column, model, right gear column as one compact block and the stat panel docked flush to its right edge, full height to the window edge - instead of floating between model and items. The stat list now also scrolls with the mouse wheel anywhere over the panel.",
		},
		changesDE = {
			"Charakterseite als logisches Raster neu aufgebaut: linke Ausrüstungsspalte, Modell, rechte Spalte als kompakter Block und das Werte-Panel bündig direkt daneben angedockt, über die volle Höhe bis zum Fensterrand - statt schwebend zwischen Modell und Items. Die Werteliste scrollt jetzt auch mit dem Mausrad überall über dem Panel.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Escape-forbidden-call fix: the HideUIPanel post-hook ran insecure code inside the Escape dispatch when panels closed - removed; our window is in UISpecialFrames and C toggles through ShowUIPanel, so nothing is lost.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Der HideUIPanel-Post-Hook lief unsicher im Escape-Dispatch beim Schliessen von Panels - entfernt; unser Fenster steht in UISpecialFrames und C toggelt ueber ShowUIPanel, es geht also nichts verloren.",
		},
	},

	{
		version = "0.2.6",
		changes = {
			"Stat panel moved: instead of a wide strip under the gear it is a tall column right next to the character model now (gear - model - stats - gear), full page height with scrolling. The window is a bit wider to fit it.",
		},
		changesDE = {
			"Werte-Panel umgezogen: statt einer breiten Leiste unter der Ausrüstung ist es jetzt eine hohe Spalte direkt neben dem Charakter-Modell (Gear - Modell - Werte - Gear), volle Seitenhöhe mit Scrollen. Das Fenster ist dafür etwas breiter.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Stat groups scrolled out under the window edge - the stat panel is a real ScrollFrame now, so long group lists scroll inside the panel instead of painting past the footer.",
		},
		changesDE = {
			"Wertegruppen liefen unter dem Fensterrand hinaus - das Werte-Panel ist jetzt ein echter ScrollFrame, lange Listen scrollen innerhalb des Panels statt über die Fußzeile hinaus zu malen.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Same color crash one line down: the item-name SetTextColor also failed when the quality color came back as a table or secret - channels are extracted first, defaults applied, and the call is pcall'd.",
		},
		changesDE = {
			"Gleicher Farb-Crash eine Zeile tiefer: Das SetTextColor des Gegenstandsnamens schlug fehl, wenn die Qualitätsfarbe als Tabelle oder Secret zurückkam - Kanäle werden jetzt erst extrahiert, Defaults gesetzt und der Aufruf per pcall abgesichert.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Gear window no longer errors on the quality ring: this client's SetVertexColor takes a color object (r,g,b failed), quality colors may come back as a table or secret - the slot code now plain-checks every channel and tries both vertex-color forms.",
		},
		changesDE = {
			"Kein Fehler mehr am Qualitätsrand: SetVertexColor nimmt auf diesem Client ein Farbobjekt (r,g,b schlug fehl), Qualitätsfarben können als Tabelle oder Secret zurückkommen - jeder Kanal wird jetzt plain geprüft und beide Vertex-Color-Formen versucht.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Pressing C opened the Blizzard window: the earlier load error aborted the module before its hooks were installed. The swap now hooks ShowUIPanel/HideUIPanel too, so any path that opens the character frame routes to our window.",
		},
		changesDE = {
			"'C' öffnete das Blizzard-Fenster: Der frühere Ladefehler brach das Modul ab, bevor seine Hooks installiert waren. Der Tausch hooked jetzt zusätzlich ShowUIPanel/HideUIPanel, sodass jeder Weg zum Charakterfenster auf unser Fenster führt.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Fixed a load-time error when a stat API is missing on this client (e.g. UnitDefense) - all stat lookups now check the function exists before calling it.",
		},
		changesDE = {
			"Ladefehler behoben, wenn eine Werte-API auf diesem Client fehlt (z. B. UnitDefense) - alle Werte-Abfragen prüfen jetzt erst, ob die Funktion existiert.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Tabs: the window now routes every character-sheet tab - Pet, Reputation, Skills, PvP, Currency and Statistics render inside our window when the client exposes the API; unavailable tabs keep the Blizzard window.",
			"Equipment sets: a 'Sets' picker in the footer lists your equipment-manager sets and equips them out of combat.",
			"Slot clicks: left picks the item up, shift links it into chat, ctrl opens the dressing room, right/alt opens a small menu.",
			"Enchant and gem markers: an enchanted item shows a green marker in its info line, filled gem sockets show blue diamonds.",
		},
		changesDE = {
			"Tabs: Das Fenster übernimmt jetzt alle Charakterblatt-Tabs - Begleiter, Ruf, Fertigkeiten, PvP, Währung und Statistiken rendern in unserem Fenster, soweit der Client die API bietet; fehlende Tabs lassen das Blizzard-Fenster.",
			"Ausrüstungs-Sets: Ein 'Sets'-Auswahlmenü in der Fußzeile listet die Sets des Ausrüstungsmanagers und rüstet sie außerhalb des Kampfes an.",
			"Slot-Klicks: Links hebt den Gegenstand auf, Shift verlinkt ihn im Chat, Strg öffnet die Anprobe, Rechts/Alt öffnet ein kleines Menü.",
			"Verzauberungs- und Sockel-Marker: Ein verzauberter Gegenstand zeigt ein grünes Zeichen in der Infozeile, gefüllte Sockel zeigen blaue Rauten.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"New module: the SentiUI character window replaces the character sheet on 'C' - gear icons with quality rings, item names and item level, a rotatable 3D model, grouped stats (attributes, melee, defense, resistances) and a footer with item level plus durability.",
		},
		changesDE = {
			"Neues Modul: Das SentiUI-Charakterfenster ersetzt das Charakterblatt auf 'C' - Ausrüstungssymbole mit Qualitätsrand, Gegenstandsnamen und -stufe, drehbares 3D-Modell, gruppierte Werte (Attribute, Nahkampf, Verteidigung, Widerstände) und eine Fußzeile mit Gegenstandsstufe und Haltbarkeit.",
		},
	},
}
