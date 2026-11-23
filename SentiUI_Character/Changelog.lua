-- In-game changelog for the SentiUI > Changelog page.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.17",
		date = "2026-11-22",
		changes = {
			"Icon-glyph boxes fixed: the gem counter's '◆' diamonds and the stat group '▾/▸' collapse arrows are glyphs the SentiUI font does not carry - they rendered as empty squares and are now safe '•' bullets and 'v'/'>' ASCII arrows.",
		},
		changesDE = {
			"Icon-Glyph-Kaesten gefixt: die '◆'-Diamanten des Gem-Counters und die '▾/▸'-Collapse-Pfeile der Stat-Gruppen sind Glyphen, die die SentiUI-Font nicht enthaelt - sie renderten als leere Vierecke und sind jetzt sichere '•'-Kugeln und 'v'/'>'-ASCII-Pfeile.",
		},
	},
	{
		version = "0.2.16",
		date = "2026-11-22",
		changes = {
			"The custom character window is shelved for now: the module passes everything through to the Blizzard CharacterFrame - no window build, no hooks, no watcher. Menu/API callers (e.g. the panel's character and reputation entries) are forwarded to ToggleCharacter with the correct tab. The window code stays in place and returns by flipping ns.PASSTHROUGH in Core.lua.",
		},
		changesDE = {
			"Das eigene Charakterfenster ist vorerst deaktiviert: Das Modul reicht alles an das Blizzard-Charakterfenster durch - kein Fensterbau, keine Hooks, kein Waechter. Menue-/API-Aufrufer (z.B. Charakter- und Ruf-Eintraege im Panel) werden mit dem passenden Tab an ToggleCharacter weitergeleitet. Der Fenster-Code bleibt erhalten und kommt per ns.PASSTHROUGH in Core.lua zurueck.",
		},
	},
	{
		version = "0.2.15",
		date = "2026-11-22",
		changes = {
			"Tab chips size to their captions again: a core TabChip label fix (removed the right anchor that collapsed GetStringWidth to 0) restores readable tab text in the character window and everywhere else chips are used.",
			"Gear slot icons now clip to soft rounded corners via the rewritten S.IconRound MaskTexture, and hovering a slot shows a subtle light sheen inside the icon box while the quality border stays untouched.",
			"The player model now sits in a framed inset portrait panel instead of floating on the dark page.",
		},
		changesDE = {
			"Tab-Chips passen sich wieder ihrer Beschriftung an: ein Core-TabChip-Label-Fix (entfernter rechter Anker, der GetStringWidth auf 0 kollabierte) stellt lesbaren Tab-Text im Charakterfenster und ueberall sonst wieder her.",
			"Ausruestungs-Icons werden jetzt ueber die neu geschriebene S.IconRound-MaskTexture auf weich abgerundete Ecken geclippt, und Hover zeigt einen dezenten Lichtschimmer in der Icon-Box waehrend der Qualitaetsrahmen unberuehrt bleibt.",
			"Das Spielermodell sitzt jetzt in einem gerahmten Inset-Portraet-Panel statt frei auf der dunklen Seite zu schweben.",
		},
	},
	{
		version = "0.2.14",
		date = "2026-11-22",
		changes = {
			"Tab strip redesigned with the new shared Sentinel tab chip: a dark inset body with a 2px accent blade on the left edge - the blade glows on hover and burns on the active tab, active tabs raise with a lit border and accent text. One design language instead of scattered boxes.",
			"Window refresh for the rounded look: the header title wears the class color, the Blizzard ornate X is replaced by the Sentinel close chip (accent on hover, Escape-close unchanged via S.EscClosable) and the equipment-set picker is a small chip in the footer.",
		},
		changesDE = {
			"Tab-Leiste im neuen gemeinsamen Sentinel-Tab-Chip neu gestaltet: dunkler Inset-Koerper mit 2px Akzent-Klinge an der linken Kante - die Klinge glimmt bei Hover und brennt auf dem aktiven Tab, aktive Tabs heben sich mit leuchtendem Rahmen und Akzent-Text ab. Eine Designsprache statt verstreuter Kaestchen.",
			"Fenster-Frischzelle fuer den abgerundeten Look: der Header-Titel traegt die Klassenfarbe, das Blizzard-Zier-X weicht dem Sentinel-Schliessen-Chip (Akzent bei Hover, Escape-Schliessen unveraendert ueber S.EscClosable) und der Equipment-Set-Picker ist ein kleiner Chip im Fuss.",
		},
	},
	{
		version = "0.2.13",
		date = "2026-11-22",
		changes = {
			"Window now closes on Escape via the shared S.EscClosable helper instead of a UISpecialFrames entry - addon-written entries in that game table taint the Escape dispatch, which made protected calls (spell stop, reload) fail and get blamed on the addon.",
		},
		changesDE = {
			"Fenster schliesst jetzt per gemeinsamem S.EscClosable-Helfer auf Escape statt ueber einen UISpecialFrames-Eintrag - von Addons geschriebene Eintraege in dieser Spiel-Tabelle tainten den Escape-Dispatch, weshalb geschuetzte Aufrufe (Zauber abbrechen, Neuladen) fehlschlugen und dem Addon angelastet wurden.",
		},
	},
	{
		version = "0.2.12",
		date = "2026-11-22",
		changes = {
			"Gear slots now draw a flat inset box with a 1px border colored by item quality - the UI-Quickslot2 ring that rendered as a clunky square frame is gone. Durability warnings still tint the border red.",
			"All page scrollbars use the thin Sentinel bar (was: the stock Blizzard template strips). Mouse-wheel scrolling now works on every list page, not just the stats panel.",
			"Tab strip reworked: real inset/raised chips with a lit border for the active page and hover feedback instead of bare text with a hairline.",
		},
		changesDE = {
			"Ausruestungs-Slots zeichnen jetzt eine flache Inset-Box mit 1px-Rahmen in der Qualitaetsfarbe - der UI-Quickslot2-Ring, der als klobiger Kasten renderte, ist weg. Haltbarkeits-Warnungen faerben den Rahmen weiterhin rot.",
			"Alle Seiten-Scrollbars nutzen die duenne Sentinel-Leiste (vorher: die Blizzard-Template-Streifen). Mausrad-Scrollen funktioniert jetzt auf jeder Listenseite, nicht nur im Statistik-Panel.",
			"Tab-Leiste ueberarbeitet: echte Inset/Raised-Chips mit leuchtendem Rahmen fuer die aktive Seite und Hover-Feedback statt nacktem Text mit Haarlinie.",
		},
	},
	{
		version = "0.2.11",
		changes = {
			"Character window: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.",
		},
		changesDE = {
			"Das Fenster haengt an der Kampf-Verzoegerung: Oeffnen im Kampf wird mit Chat-Notiz nach dem Kampf nachgeholt, ein offenes Fenster versteckt sich bei Kampfbeginn und kehrt danach zurueck.",
		},
	},

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
