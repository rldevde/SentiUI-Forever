-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.5",
		changes = {
			"Blocked/forbidden action events are no longer stored as 'simple' entries: the grabber captures the full stack trace now, so the BugSack window shows which file and line triggered the blocked call.",
		},
		changesDE = {
			"Blocked/Forbidden-Events werden nicht mehr als 'simple' Eintraege gespeichert: Der Grabber erfasst jetzt den kompletten Stacktrace, das BugSack-Fenster zeigt also welche Datei und Zeile den blockierten Call ausgeloest hat.",
		},
	},

	{
		version = "0.1.4",
		changes = {
			"Escape-forbidden-call fix: the three OnEscapePressed handlers ran inside the Escape dispatch and tainted the engine's protected spell-stop calls - the window is in UISpecialFrames, so Escape closes it natively.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Die drei OnEscapePressed-Handler liefen im Escape-Dispatch und tainteten die geschuetzten Spell-Stop-Aufrufe der Engine - das Fenster steht in UISpecialFrames, Escape schliesst es nativ.",
		},
	},

	{
		version = "0.1.3",
		changes = {
			"Fixed the empty error list: the list scroll frame anchored its left edge twice (TOPLEFT + BOTTOMLEFT), collapsing it to zero width - every row was clipped invisible while the counter still showed the errors. The right edge is anchored properly now, so the grouped error rows and the detail pane render.",
		},
		changesDE = {
			"Leere Fehlerliste gefixt: Die Listen-ScrollFrame hat ihre linke Kante zweimal verankert (TOPLEFT + BOTTOMLEFT) und kollabierte auf Null-Breite - alle Zeilen wurden unsichtbar geclippt, während der Zähler die Fehler noch anzeigte. Die rechte Kante ist jetzt korrekt verankert, die gruppierten Fehlerzeilen und die Detailansicht rendern.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Fixed the window never opening: the filter/nav buttons and the list rows were plain Frames (S.Panel), and this client rejects OnClick on a Frame (\"script type not supported by this object\"), so the whole build died on the first click handler. Buttons and rows are real Buttons now with the same panel styling, so the error list and detail view appear.",
		},
		changesDE = {
			"Fenster öffnete nie: Die Filter-/Nav-Buttons und die Listen-Zeilen waren einfache Frames (S.Panel), und dieser Client lehnt OnClick auf einem Frame ab (\"script type not supported by this object\") - der gesamte Aufbau starb am ersten Click-Handler. Buttons und Zeilen sind jetzt echte Buttons mit demselben Panel-Styling, sodass Fehlerliste und Detailansicht erscheinen.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Fixed an error flood: if window construction failed after the frame was created, every new captured error re-ran the half-built list renderer and threw again, feeding an endless capture loop until the flood throttle kicked in. The refresh path now hard-guards on a missing list, window build failures surface the real error once instead of staying silent, and the error-notify callback is pcall-wrapped so window bugs can never feed the grabber loop.",
			"Scroll frames degrade gracefully now: FauxScrollFrameTemplate and UIPanelScrollFrameTemplate creations fall back to plain ScrollFrames if the templates are missing on this client.",
		},
		changesDE = {
			"Fehler-Flut behoben: Schlug der Fensteraufbau nach der Frame-Erstellung fehl, rief jeder neu erfasste Fehler den halbfertigen Listen-Renderer auf und warf erneut - eine endlose Erfassungsschleife bis zur Drossel. Der Refresh-Pfad prüft jetzt hart auf eine fehlende Liste, Fehler beim Fensterbau werden einmal sichtbar gemeldet statt still verschluckt, und der Fehler-Benachrichtigungs-Callback ist pcall-geschützt, damit Fenster-Fehler die Grabber-Schleife nie füttern können.",
			"Scroll-Frames bauen jetzt defensiv: FauxScrollFrameTemplate und UIPanelScrollFrameTemplate fallen auf normale ScrollFrames zurück, wenn die Templates auf diesem Client fehlen.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"Initial release: a fully internal BugGrabber + BugSack for the SentiUI suite - no external error addons needed.",
			"The grabber installs the client's error handler (BugGrabber style: seterrorhandler is stubbed so nothing can replace it), listens for LUA_WARNING and ADDON_ACTION_BLOCKED/FORBIDDEN, deduplicates repeats into a counter, caps the store at 500 errors and tracks session numbers.",
			"BugSack-style window: All/Current/Previous session filters plus search, error list grouped and collapsible by addon, a copyable plain-text detail pane, prev/next navigation and wipe with confirmation.",
			"Export view selects the whole report in one box (Ctrl+A, Ctrl+C) so it pastes cleanly into the bug tracker at https://dev.xrl-dev.de/bugtracker - the hint sits in the window and the export pane.",
			"Slash commands: /sbs or /bugsack toggles the window, /sbs wipe clears, /sbs export and /sbs export all open the export, /sbs <n> prints error n.",
			"New errors can print a clickable chat line, play a sound and auto-open the window (never in combat) - all three are options under SentiUI > BugSack.",
			"The window is a real mover: drag it anywhere and it reopens where you left it.",
		},
		changesDE = {
			"Erste Version: ein komplett interner BugGrabber + BugSack für die SentiUI-Suite - kein externes Fehler-Addon mehr nötig.",
			"Der Grabber installiert den Error-Handler des Clients (BugGrabber-Art: seterrorhandler ist gestubt, damit ihn nichts ersetzt), lauscht auf LUA_WARNING und ADDON_ACTION_BLOCKED/FORBIDDEN, zählt Wiederholungen als Zähler, begrenzt den Speicher auf 500 Fehler und führt Sitzungsnummern.",
			"Fenster im BugSack-Stil: Filter Alle/Aktuelle/Vorige Sitzung plus Suche, Fehlerliste nach Addon gruppiert und einklappbar, kopierbare Klartext-Detailansicht, Vor/Zurück-Navigation und Löschen mit Bestätigung.",
			"Export-Ansicht markiert den ganzen Bericht in einem Feld (Strg+A, Strg+C), damit er sauber im Bugtracker unter https://dev.xrl-dev.de/bugtracker eingefügt werden kann - der Hinweis steht im Fenster und im Export-Bereich.",
			"Slash-Befehle: /sbs oder /bugsack schaltet das Fenster, /sbs wipe löscht, /sbs export und /sbs export all öffnen den Export, /sbs <n> zeigt Fehler n.",
			"Neue Fehler können eine anklickbare Chatzeile ausgeben, einen Sound spielen und das Fenster öffnen (nie im Kampf) - alle drei sind Optionen unter SentiUI > BugSack.",
			"Das Fenster ist ein echter Mover: wohin ziehen, dort öffnet es wieder.",
		},
	},
}
