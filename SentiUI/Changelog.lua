-- Changelog registry. Every SentiUI addon files its release entries here
-- (modules pass `changelog = {...}` in their RegisterModule def, the core
-- registers its own below) and the settings show them on SentiUI > Changelog,
-- in the client's language. Entry shape:
--   { version = "x.y.z", date = "YYYY-MM-DD"?,
--     changes   = { "English line", ... },
--     changesDE = { "German line", ... }? }   -- falls back to `changes`
local _, S = ...

local CL = { list = {}, byName = {} }
S.Changelog = CL

function CL.Register(addon, entries)
	if type(addon) ~= "string" or type(entries) ~= "table" then return end
	local slot = CL.byName[addon]
	if not slot then
		slot = { addon = addon, entries = {} }
		CL.byName[addon] = slot
		CL.list[#CL.list + 1] = slot
	end
	for _, e in ipairs(entries) do slot.entries[#slot.entries + 1] = e end
end

function CL.List() return CL.list end

CL.Register("SentiUI", {
	{
		version = "0.3.19",
		date = "2026-11-22",
		changes = {
			"New shared helpers: S.EscClosable (Escape-close without a UISpecialFrames entry) and S.Dialog (own confirm/prompt dialog). All core windows (settings, installer, movers) converted - addon-written entries in UISpecialFrames/StaticPopupDialogs taint the game's Escape dispatch, which is what made protected calls fail and get blamed on the addon.",
			"The 'reload required?' confirm and the options reset confirm now use the own dialog (the reload still goes through C_UI.Reload).",
		},
		changesDE = {
			"Neue gemeinsame Helfer: S.EscClosable (Escape-Schliessen ohne UISpecialFrames-Eintrag) und S.Dialog (eigener Bestaetigungs-/Eingabedialog). Alle Core-Fenster (Einstellungen, Installer, Mover) umgestellt - von Addons geschriebene Eintraege in UISpecialFrames/StaticPopupDialogs tainten den Escape-Dispatch des Spiels, weshalb geschuetzte Aufrufe fehlschlugen und dem Addon angelastet wurden.",
			"Die 'Neuladen noetig?'- und Zuruecksetzen-Bestaetigungen nutzen jetzt den eigenen Dialog (das Neuladen geht weiterhin ueber C_UI.Reload).",
		},
	},
	{
		version = "0.3.18",
		date = "2026-11-22",
		changes = {
			"Reworked the combat deferral: the core no longer wraps ShowUIPanel/HideUIPanel/ToggleFrame or the Toggle* keybind functions - every wrapped call ran addon code inside the caller's dispatch and tainted it, which is what blocked Reload() in the addon list, SpellStopCasting() on Escape and secret comparisons when panels opened.",
			"Blocked window opens are now recognized inside the dead dispatch's stack (binding chunk, Toggle* name or panel file) and queued for after combat - same feature, zero taint.",
		},
		changesDE = {
			"Kampf-Verzögerung umgebaut: Der Kern umschreibt ShowUIPanel/HideUIPanel/ToggleFrame und die Toggle*-Tastenfunktionen nicht mehr - jeder umschriebene Aufruf führte Addon-Code im Dispatch des Aufrufers aus und vergiftete ihn, was Reload() in der Addon-Liste, SpellStopCasting() bei Escape und Geheimwert-Vergleiche beim Öffnen von Fenstern blockierte.",
			"Geblockte Fenster-Öffnungen werden jetzt im Stack des toten Dispatches erkannt (Binding-Chunk, Toggle*-Name oder Fenster-Datei) und für nach dem Kampf gequeued - gleiche Funktion, null Taint.",
		},
	},
	{
		version = "0.3.17",
		date = "2026-11-22",
		changes = {
			"Forbidden-call reports name the event the blocked call really ran inside (the dispatcher used to overwrite it with the blocked event itself).",
			"A blocked call raised while reporting another one stays silent in chat; BugSack still records it.",
			"When every stack frame is core machinery the report now names the real call line instead of the dispatcher line.",
		},
		changesDE = {
			"Verbotene-Aufruf-Meldungen nennen jetzt das Event, in dem der geblockte Aufruf wirklich lief (der Dispatcher überschrieb es vorher mit dem Block-Event selbst).",
			"Ein geblockter Aufruf, der während des Meldens eines anderen entsteht, bleibt im Chat still; BugSack zeichnet ihn weiterhin auf.",
			"Besteht der Stack nur aus Kern-Code, nennt der Report jetzt die echte Aufrufzeile statt der Dispatcher-Zeile.",
		},
	},
	{
		version = "0.3.16",
		changes = {
			"Compile fix: the combat-deferral entry used '...' inside a non-vararg function - LuaJIT rejects the whole file at load, so the entire core (and with it every module) failed to initialize. LuaJIT now compiles the suite clean; a full compile sweep also caught the same class of bug in Journal, Chat, SentiLayer and My-Social.",
		},
		changesDE = {
			"Compile-Fix: Der Combat-Deferral-Eintrag nutzte '...' in einer Nicht-Vararg-Funktion - LuaJIT lehnt die ganze Datei beim Laden ab, der komplette Core (und damit jedes Modul) startete nicht. LuaJIT kompiliert die Suite jetzt sauber; ein Komplett-Sweep fand denselben Fehlertyp in Journal, Chat, SentiLayer und My-Social.",
		},
	},

	{
		version = "0.3.15",
		changes = {
			"Combat deferral, full coverage: ShowUIPanel, HideUIPanel and ToggleFrame join the queued path, so micro-menu buttons and every other open path defer in combat too (deduped per frame - a double ToggleFrame would undo itself). Every suite window is now flagged for combat deferral: BugSack, Character, Messenger hub/card/copy, bags+bank and the chat copy window join settings, blacklist, training and journal - they defer their open, hide on combat start and return after.",
		},
		changesDE = {
			"Kampf-Verzoegerung, volle Abdeckung: ShowUIPanel, HideUIPanel und ToggleFrame haengen jetzt auch an der Warteschlange - Mikromenue-Buttons und jeder andere Oeffnungspfad verzoegern im Kampf (pro Frame dedupliziert - ein doppeltes ToggleFrame wuerde sich selbst aufheben). Alle Suite-Fenster sind jetzt geflaggt: BugSack, Charakter, Messenger Hub/Karte/Kopie, Taschen+Bank und das Chat-Kopierfenster neben Einstellungen, Blacklist, Training und Journal - Oeffnen wird verzoegert, bei Kampfbeginn verstecken sie sich und kommen danach wieder.",
		},
	},

	{
		version = "0.3.14",
		changes = {
			"Combat window deferral: opening a managed window mid-combat dies to ADDON_ACTION_FORBIDDEN on the client's protected FrameShow, so Blizzard key toggles (character C, spellbook K, talents N, quests L, map, friends, guild, pvp, calendar, help, group finder...) now queue the open for after combat with a chat note - and fire only when the window is still closed. Flagged own windows behave the same via S:CombatDeferWindow: Show() in combat defers with a note, an open window hides on combat start and returns after. Flagged so far: settings, panel blacklist, training, journal.",
		},
		changesDE = {
			"Kampf-Verzoegerung fuer Fenster: Das Oeffnen verwalteter Fenster im Kampf stirbt am ADDON_ACTION_FORBIDDEN des geschuetzten FrameShow - die Blizzard-Tastentoggles (Charakter C, Zauberbuch K, Talente N, Quests L, Karte, Freunde, Gilde, PvP, Kalender, Hilfe, Gruppensuche...) stellen das Oeffnen jetzt mit einer Chat-Notiz bis nach dem Kampf zurueck - und feuern nur, wenn das Fenster noch zu ist. Geflaggte eigene Fenster verhalten sich per S:CombatDeferWindow genauso: Show() im Kampf verzoegert mit Notiz, ein offenes Fenster versteckt sich bei Kampfbeginn und kommt danach wieder. Geflaggt bisher: Einstellungen, Panel-Blacklist, Training, Journal.",
		},
	},

	{
		version = "0.3.13",
		changes = {
			"Forbidden-action reports dig one frame deeper and name the dispatching event: core machinery frames (OnEvent dispatcher, SafeCall/S.Call wrappers) are skipped so the site points at the real module file.lua:line, and the report now includes 'during EVENT_NAME' when a client event was being dispatched inside the blocked call - a tainted event handler is identifiable at a glance.",
		},
		changesDE = {
			"Forbidden-Meldungen graben einen Frame tiefer und nennen das ausloesende Event: Core-Machinery-Frames (OnEvent-Dispatcher, SafeCall/S.Call-Wrapper) werden uebersprungen, sodass die Stelle auf die echte Modul-datei.lua:zeile zeigt, und die Meldung enthaelt jetzt 'during EVENT_NAME', wenn ein Client-Event im blockierten Call dispatcht wurde - ein taintender Event-Handler ist auf einen Blick erkennbar.",
		},
	},

	{
		version = "0.3.12",
		changes = {
			"Forbidden-action site reporting fixed: the handler's own frame was the first Lua frame on the debug stack, so reports always pointed at Core.lua instead of the real culprit. The topmost frame is now skipped and the next SentiUI frame below the event dispatch is named - the next ADDON_ACTION_FORBIDDEN report shows the actual file.lua:line that ran inside the protected dispatch.",
		},
		changesDE = {
			"Forbidden-Meldung zeigt jetzt die echte Stelle: Der eigene Handler-Frame stand als erstes Lua-Frame im Debug-Stack, daher zeigten Meldungen immer auf Core.lua statt auf den wirklichen Ausloeser. Der oberste Frame wird jetzt uebersprungen und das naechste SentiUI-Frame unter dem Event-Dispatch genannt - die naechste ADDON_ACTION_FORBIDDEN-Meldung zeigt die echte datei.lua:zeile, die im geschuetzten Dispatch lief.",
		},
	},

	{
		version = "0.3.11",
		changes = {
			"Central call-site reporting: S.Call (labelled pcall) and S.SecureAPI (securecall lane) live in the core now - every current and future module gets 'file.lua:line' reporting for failed or blocked engine calls for free. Module wrappers delegate to it.",
		},
		changesDE = {
			"Zentrales Call-Site-Reporting: S.Call (gelabeltes pcall) und S.SecureAPI (securecall-Lane) liegen jetzt im Core - jedes aktuelle und zukuenftige Modul bekommt 'datei.lua:zeile'-Meldungen fuer fehlgeschlagene oder blockierte Engine-Calls automatisch. Die Modul-Wrapper delegieren darauf.",
		},
	},

	{
		version = "0.3.10",
		changes = {
			"Forbidden-action reports now name the call site: ADDON_ACTION_BLOCKED/FORBIDDEN fires synchronously inside the blocked call, so the handler reads debugstack and prints the first SentiUI frame (file.lua:line) next to the blamed addon - an UNKNOWN() blame is no longer anonymous.",
		},
		changesDE = {
			"Forbidden-Meldungen nennen jetzt die Aufrufstelle: ADDON_ACTION_BLOCKED/FORBIDDEN feuert synchron im blockierten Call, daher liest der Handler debugstack und zeigt das erste SentiUI-Frame (datei.lua:zeile) neben dem beschuldigten Addon - ein UNKNOWN()-Blame ist nicht mehr anonym.",
		},
	},

	{
		version = "0.3.9",
		changes = {
			"WatchPump treats a non-boolean IsShown answer (error or secret) as unknown, not hidden - it could otherwise fake a shown->hidden transition that never happened.",
		},
		changesDE = {
			"WatchPump behandelt eine nicht-boolesche IsShown-Antwort (Fehler oder Secret) als unbekannt statt versteckt - sonst koennte ein nie passierter shown->hidden-Uebergang vorgetaeuscht werden.",
		},
	},
	{
		version = "0.3.8",
		changes = {
			"WatchPump hardened: a frame resolver or IsShown call that errors no longer kills the whole visibility watcher loop - every watched window after it stayed dead (bank, merchant, loot re-hide).",
		},
		changesDE = {
			"WatchPump gehaertet: Ein fehlernder Frame-Resolver oder IsShown-Aufruf killt nicht mehr die komplette Watcher-Schleife - alle danach ueberwachten Fenster (Bank, Haendler, Loot-Re-Hide) blieben tot.",
		},
	},
	{
		version = "0.3.7",
		changes = {
			"Added S.WatchShown: central ticker-based visibility-transition watcher (shown and hidden callbacks) for Blizzard windows that may open/close inside a protected dispatch.",
		},
		changesDE = {
			"Neu: S.WatchShown - zentraler Ticker-Waechter fuer Sichtbarkeitswechsel (Show- und Hide-Callbacks) bei Blizzard-Fenstern, die innerhalb eines geschuetzten Dispatch oeffnen/schliessen koennen.",
		},
	},
	{
		version = "0.3.6",
		changes = {
			"Escape-forbidden-call hardening, suite-wide: the shared edit box lost its OnEscapePressed/OnEditFocusLost handlers (they ran insecure Lua inside the Escape dispatch and tainted the engine's protected SpellStopCasting/SpellStopTargeting calls), the lit border now resets from a focus-poll timer, and new S.WatchHide replaces OnHide scripts on Escape-closed windows - movers bar included.",
		},
		changesDE = {
			"Escape-Blockier-Haertung fuer die ganze Suite: Die gemeinsame Editbox hat ihre OnEscapePressed-/OnEditFocusLost-Handler verloren (sie liefen unsicher im Escape-Dispatch und tainteten die geschuetzten SpellStopCasting/SpellStopTargeting-Aufrufe der Engine), der helle Rahmen wird jetzt per Fokus-Ticker zurueckgesetzt, und S.WatchHide ersetzt OnHide-Scripts an Escape-geschlossenen Fenstern - inklusive Movers-Leiste.",
		},
	},

	{
		version = "0.3.5",
		changes = {
			"Changelog page gets module categories: a filter dropdown on top lists every addon that filed entries (All modules, SentiUI, each SentiUI_* module) and narrows the cards to the picked module.",
		},
		changesDE = {
			"Changelog-Seite bekommt Modul-Kategorien: Ein Filter-Dropdown oben listet jedes Addon mit Einträgen (Alle Module, SentiUI, jedes SentiUI_*-Modul) und begrenzt die Karten auf das gewählte Modul.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Changelog/settings page fixed: text rows stayed at a fixed 26px height while long changelog lines wrapped onto two or three lines - entries drew over each other. Text rows now measure the wrapped label height (explicit width + word wrap) and grow to fit, controls rows stay single-line.",
		},
		changesDE = {
			"Changelog-/Einstellungsseite repariert: Textzeilen blieben auf fixen 26px, während lange Changelog-Zeilen auf zwei bis drei Zeilen umbrachen - Einträge übermalten sich. Textzeilen messen jetzt die umgebrochene Label-Höhe (explizite Breite + Wortumbruch) und wachsen mit, Kontrollzeilen bleiben einzeilig.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"New shared S.LevelColor(unit) helper: asks the server for the unit's content difficulty and maps it through GetDifficultyColor - real difficulty colors (red/orange/yellow/green/gray) for level text, secret-safe.",
		},
		changesDE = {
			"Neuer gemeinsamer Helfer S.LevelColor(unit): fragt die Content-Schwierigkeit der Einheit am Server ab und bildet sie über GetDifficultyColor ab - echte Schwierigkeitsfarben (rot/orange/gelb/grün/grau) für Stufentexte, secret-sicher.",
		},
	},
	{
		version = "0.3.2",
		changes = {
			"Mover hardening: a throwing snap pass could kill the drag-stop handler before the save ran - moved frames then looked placed but snapped back on the next apply/reload. The snap is now pcall'd so the save always happens, UIParent rect/size reads got their secret guards, and NearestAnchor returns nil instead of a fake {BOTTOMLEFT,0,0} so an unreadable rect skips the save instead of teleporting the frame into the corner. M.Apply on an unknown key no longer indexes nil, and proxy movers now save and refresh the handle's own rect instead of the unmoving frame's (no module uses proxies yet).",
		},
		changesDE = {
			"Mover-Härtung: Ein werfender Snap konnte den Drag-Stop-Handler vor dem Speichern abbrechen - verschobene Frames sahen platziert aus, sprangen aber beim nächsten Apply/Reload zurück. Der Snap läuft jetzt per pcall, sodass das Speichern immer passiert; UIParent-Rect/Größe bekamen ihre Secret-Guards, und NearestAnchor gibt nil statt eines falschen {BOTTOMLEFT,0,0} zurück - ein unlesbares Rect überspringt das Speichern statt den Frame in die Ecke zu werfen. M.Apply mit unbekanntem Key indexiert nicht mehr nil, und Proxy-Mover speichern und refreshen jetzt das eigene Rect des Handles statt das des unbewegten Frames (nutzt noch kein Modul).",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"New SentiUI artwork shipped as Media/Logo.tga (Alliance/Horde emblem, 1024x1024) and Media/LongLogo.tga (wide banner); S.media.longLogo + longLogoBand expose the banner crop band, and the settings Home page shows the banner as a hero row. The minimap button, installer and settings title now use the new emblem automatically via S.media.logo.",
		},
		changesDE = {
			"Neues SentiUI-Artwork als Media/Logo.tga (Allianz/Horde-Emblem, 1024x1024) und Media/LongLogo.tga (breites Banner); S.media.longLogo + longLogoBand exportieren den Banner-Ausschnitt, und die Einstellungen-Startseite zeigt das Banner als Hero-Zeile. Minimap-Button, Installer und Einstellungs-Titel nutzen das neue Emblem automatisch über S.media.logo.",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Settings search upgraded: results now scroll to and flash the matching option, page titles are searchable, the result header shows the hit count, and Enter jumps to the first result.",
			"The search field gets a gold accent edge so it reads as an input, and a strtrim fallback guards the filter on this client.",
		},
		changesDE = {
			"Einstellungs-Suche verbessert: Treffer scrollen jetzt zur passenden Option und markieren sie, Seitentitel sind durchsuchbar, der Kopf zeigt die Trefferzahl, Enter springt zum ersten Treffer.",
			"Das Suchfeld bekommt eine goldene Kante als Erkennungsmerkmal, plus strtrim-Fallback für den Client.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Fonts are now applied through real font objects (CreateFontFamily + SetFontObject with a GetFont verify) because plain SetFont fails silently on this client - fixes invisible text in module frames.",
			"New Movers.Save(key) lets modules persist a directly-dragged frame position through the mover DB (used by the bag windows' title-bar drag).",
		},
		changesDE = {
			"Fonts werden jetzt über echte Font-Objekte gesetzt (CreateFontFamily + SetFontObject mit GetFont-Verifikation), weil schlichtes SetFont auf diesem Client still fehlschlägt - behebt unsichtbaren Text in Modul-Frames.",
			"Neu: Movers.Save(key) speichert direkt gezogene Frame-Positionen in der Mover-DB (genutzt vom Titelzeilen-Drag der Taschenfenster).",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Widget buttons no longer throw on non-string captions: Button:SetText ignores secret values and coerces anything that is not a string or number to empty (installer SetText error).",
		},
		changesDE = {
			"Widget-Buttons werfen bei Nicht-String-Beschriftungen nicht mehr: Button:SetText ignoriert Secret-Werte und wandelt alles außer String/Zahl in einen leeren Text um (Installer-SetText-Fehler).",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Error messages now include a one-time hint per session pointing to the bug tracker at https://dev.xrl-dev.de/bugtracker (Lua errors via SafeCall and forbidden/blocked calls).",
		},
		changesDE = {
			"Fehlermeldungen enthalten jetzt einmal pro Sitzung einen Hinweis auf den Bugtracker unter https://dev.xrl-dev.de/bugtracker (Lua-Fehler via SafeCall und forbidden/blocked-Calls).",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Buttons and installer steps tolerate nil text now - no more \"bad argument to SetText\".",
		},
		changesDE = {
			"Buttons und Installer-Schritte vertragen jetzt leeren Text - kein \"bad argument to SetText\" mehr.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Error radar fully hardened: secret error messages no longer break the xpcall handler, and the forbidden report labels addon vs. function correctly.",
		},
		changesDE = {
			"Fehler-Radar vollständig abgehärtet: Secret-Fehlermeldungen brechen den Fehlerhandler nicht mehr, und der Forbidden-Report beschriftet Addon vs. Funktion korrekt.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Fixed the error radar: debug.traceback does not exist on this client - tracebacks now come from debugstack, so real errors print file and line instead of \"error in error handling\".",
			"New IsSecretTable helper: indexing a secret table throws before a field can be checked.",
		},
		changesDE = {
			"Fehler-Radar repariert: debug.traceback existiert auf diesem Client nicht - Tracebacks kommen jetzt von debugstack, echte Fehler zeigen wieder Datei und Zeile statt \"error in error handling\".",
			"Neuer IsSecretTable-Helfer: Das Indizieren einer Secret-Tabelle wirft, bevor ein Feld geprüft werden kann.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"New in-game changelog: SentiUI > Changelog lists the release history of the core and every module, in English and German.",
		},
		changesDE = {
			"Neuer In-Game-Changelog: Unter SentiUI > Changelog steht die Versionshistorie des Cores und aller Module, auf Englisch und Deutsch.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Error radar: failures print a Lua traceback with file and line.",
			"Forbidden and blocked protected calls are reported in chat with the function name and the blamed addon.",
		},
		changesDE = {
			"Fehler-Radar: Fehler zeigen jetzt einen Lua-Traceback mit Datei und Zeile.",
			"Verbotene und geblockte geschützte Aufrufe werden im Chat gemeldet - mit Funktionsname und beschuldigtem Addon.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Movers rebuilt on the proven SentinelForeverCore mechanics: real frames move via SetMovable/StartMoving, handles live on UIParent, hidden frames stay placeable.",
			"Positions save as the nearest screen anchor; every size/point read is secret-guarded.",
			"Mover extras: selection highlight, arrow-key nudging (Shift = 10px), live anchor restore on reset.",
		},
		changesDE = {
			"Mover auf die bewährte SentinelForeverCore-Mechanik umgebaut: echte Fenster bewegen per SetMovable/StartMoving, Griffe liegen auf UIParent, versteckte Fenster bleiben platzierbar.",
			"Positionen werden als nächster Bildschirm-Anker gespeichert; jede Größen-/Punkt-Abfrage ist Secret-gesichert.",
			"Mover-Extras: Auswahl-Markierung, Verschieben per Pfeiltasten (Shift = 10px), Live-Anker beim Zurücksetzen.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: settings shell for the SentiUI suite.",
			"Minimap button, options window with sections and search, mover system, first-run installer.",
			"Option types: toggle, slider, dropdown, color, button, text, custom. /sui opens the settings.",
		},
		changesDE = {
			"Erste Version: Settings-Hülle für die SentiUI-Suite.",
			"Minimap-Button, Optionsfenster mit Bereichen und Suche, Mover-System, Installer für den ersten Start.",
			"Optionstypen: Schalter, Slider, Dropdown, Farbe, Button, Text, Custom. /sui öffnet die Einstellungen.",
		},
	},
})
