local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.5.43",
		changes = {
			"FBL sync: whispering a pull answer to an offline peer spammed 'no player named X online' once per chunk (~80 system lines). Those system lines are now filtered for our own whisper targets, the rest of that peer's copy is aborted, and the peer is skipped for 30 minutes.",
		},
		changesDE = {
			"FBL-Sync: Eine Pull-Antwort per Whisper an einen offline Peer spammte 'kein Spieler namens X online' einmal pro Chunk (~80 Systemzeilen). Diese Zeilen werden jetzt fuer unsere eigenen Whisper-Ziele gefiltert, der Rest der Kopie abgebrochen und der Peer 30 Minuten uebersprungen.",
		},
	},
	{
		version = "0.5.42",
		changes = {
			"FBL sync speed: a full list now travels in seconds instead of half a minute. Chunks grew to 236 bytes (still under the 255-byte message cap), the addon drain sends 3 chunks per 0.15s tick (~20 msg/s, was 1 per 0.3s), and every broadcast additionally pushes one guild copy - reaching guildmates who never joined the sync channel.",
			"Pull answers go direct: when a peer asks for a newer list, we now whisper them a full copy via addon message first (not channel- or hardware-gated) before the jittered channel broadcast. Pull cooldown 600s -> 300s, answer jitter 5-40s -> 3-10s.",
			"Chat fallback flood cap: channel sends inside an input event are now limited to 12 lines per event so the client spam throttle stops silently eating chunks.",
		},
		changesDE = {
			"FBL-Sync-Tempo: Eine volle Liste kommt jetzt in Sekunden statt in einer halben Minute an. Chunks auf 236 Bytes gewachsen (weiter unter der 255-Byte-Grenze), der Addon-Drain sendet 3 Chunks pro 0,15s-Tick (~20 Msg/s, vorher 1 pro 0,3s), und jeder Broadcast pusht zusaetzlich eine Gilden-Kopie - erreicht Gildenmitglieder, die nie im Sync-Channel sind.",
			"Pull-Antworten gehen direkt: Fragt ein Peer eine neuere Liste an, bekommt er zuerst eine komplette Kopie per Addon-Whisper (weder channel- noch hardware-gated), bevor der verzoegerte Channel-Broadcast folgt. Pull-Cooldown 600s -> 300s, Antwort-Jitter 5-40s -> 3-10s.",
			"Chat-Fallback-Flutbremse: Channel-Sends innerhalb eines Input-Events sind jetzt auf 12 Zeilen pro Event begrenzt, damit der Spam-Schutz des Clients keine Chunks mehr stillschweigend verschluckt.",
		},
	},
	{
		version = "0.5.41",
		changes = {
			"FBL sync: the receive notice now names the sender's client - 'Blacklist received from X via SentiUI' vs 'via ForeverBlackListed', learned from each peer's FBLver ping (SentiUI announces SentiUI_Panel-x.y, the standalone a bare version).",
		},
		changesDE = {
			"FBL-Sync: Die Empfangs-Meldung nennt jetzt den Client des Senders - 'Blacklist von X via SentiUI empfangen' vs 'via ForeverBlackListed', erkannt am FBLver-Ping des Peers (SentiUI meldet SentiUI_Panel-x.y, der Standalone eine nackte Version).",
		},
	},
	{
		version = "0.5.40",
		changes = {
			"FBL sync: receiving a blacklist is now visible in chat, not just sending. A complete incoming list prints 'Blacklist received from <name> (n chunks)' in gold before the trust/accept step - previously only the merge result printed, and only when entries actually changed, so unchanged or echoed lists arrived silently.",
		},
		changesDE = {
			"FBL-Sync: Empfangene Blacklists sind jetzt auch im Chat sichtbar, nicht nur gesendete. Eine komplette eingehende Liste druckt 'Blacklist von <Name> empfangen (n Blöcke)' in Gold vor dem Trust-/Accept-Schritt - bisher druckte nur das Merge-Ergebnis, und auch das nur bei echten Änderungen, sodass unveränderte oder geechte Listen lautlos ankamen.",
		},
	},
	{
		version = "0.5.39",
		changes = {
			"FBL sync channel: 'invalid channel name' spam gone. JoinSync retried the 18-char preferred name every cycle (up to 30 times per session), printing the system error each pass. Names that miss their join check twice are now remembered in db.sync.badNames and skipped on all later attempts, converging on the FBLsync fallback like the standalone; if every name ever turns bad the marks reset and retry (transient failures).",
		},
		changesDE = {
			"FBL-Sync-Channel: 'Ungueltiger Channelname'-Spam weg. JoinSync versuchte den 18-Zeichen-Primaernamen in jedem Zyklus erneut (bis zu 30 Mal pro Session), jedes Mal mit Systemfehler. Namen, die ihren Join-Check zweimal verfehlen, werden jetzt in db.sync.badNames gemerkt und bei allen spaeteren Versuchen uebersprungen - konvergiert aufs FBLsync-Fallback wie der Standalone; werden alle Namen schlecht, werden die Markierungen zurueckgesetzt und erneut versucht (transiente Fehler).",
		},
	},
	{
		version = "0.5.38",
		changes = {
			"FBL send crash + false rejections: the channel drain could run before anything was queued (sendQueue nil, 'attempt to index upvalue'), and an over-strict SendAddonMessage result check treated a delivered send as failed, dropping whole payloads ('106 blocks rejected'). The queue now normalizes before drain and the send counts as sent on pcall success, matching the standalone.",
		},
		changesDE = {
			"FBL-Sende-Crash + falsche Ablehnungen: Der Channel-Drain konnte laufen, bevor etwas gequeued war (sendQueue nil, 'attempt to index upvalue'), und ein zu strikter SendAddonMessage-Result-Check wertete einen zugestellten Send als Fehlschlag und verwarf ganze Payloads ('106 Blöcke abgelehnt'). Die Queue wird vor dem Drain normalisiert und ein Send gilt bei pcall-Erfolg als gesendet, wie beim Standalone.",
		},
	},
	{
		version = "0.5.37",
		changes = {
			"FBL sync transport fix: SentiUI's blacklist never reached ForeverBlackListed users. The module sent every channel message via SendAddonMessage 'CHANNEL' - a path this client does not route to custom channels, and the wrapper hid the failure, so 'Blacklist sent' printed while nothing went out. The panel now mirrors the standalone's model: a self-echo probe detects whether addon traffic reaches the channel; when it does not, sends fall back to SendChatMessage, which is hardware-gated and therefore drains inside the real input events (Sync buttons, removal request). Version pings and pull requests park in pending slots until a transport exists, ADDON_ACTION_BLOCKED during a chat send disables the chat path for the session, and F.Debug now reports the probed transport state.",
		},
		changesDE = {
			"FBL-Sync-Transport-Fix: SentiUIs Blacklist erreichte ForeverBlackListed-Nutzer nie. Das Modul schickte jede Channel-Nachricht via SendAddonMessage 'CHANNEL' - ein Weg, den dieser Client nicht auf Custom-Channels routet, und der Wrapper versteckte den Fehlschlag, sodass 'Blacklist gesendet' erschien, waehrend nichts rausging. Das Panel spiegelt jetzt das Standalone-Modell: Ein Self-Echo-Probe erkennt, ob Addon-Traffic den Channel erreicht; wenn nicht, faellt der Versand auf SendChatMessage zurueck, das hardware-gated ist und daher nur in echten Input-Events drainen kann (Sync-Buttons, Loeschanfrage). Versions-Pings und Pull-Requests parken in Pending-Slots, bis ein Transport existiert, ADDON_ACTION_BLOCKED waehrend eines Chat-Sends deaktiviert den Chat-Pfad fuer die Session, und F.Debug zeigt jetzt den probten Transport-Status.",
		},
	},
	{
		version = "0.5.36",
		changes = {
			"Guild plugin combat fix: hovering the guild tile mid-fight fired ADDON_ACTION_BLOCKED - the tooltip called GetGuildRosterMOTD/GetGuildRosterInfo live and the roster API is protected under lockdown (a pcall does not stop the flag). MOTD and the member list are now cached inside the combat-guarded GuildRefresh and the tooltip only reads the cache; a dirty flag flushes one refresh on PLAYER_REGEN_ENABLED.",
		},
		changesDE = {
			"Gilden-Plugin-Kampffix: Hover ueber der Gilden-Kachel mitten im Kampf feuerte ADDON_ACTION_BLOCKED - der Tooltip rief GetGuildRosterMOTD/GetGuildRosterInfo live auf und die Roster-API ist unter Lockdown protected (pcall stoppt das Flag nicht). MOTD und Mitgliederliste werden jetzt im kampfgeschuetzten GuildRefresh gecacht, der Tooltip liest nur noch den Cache; ein Dirty-Flag holt den Refresh bei PLAYER_REGEN_ENABLED nach.",
		},
	},
	{
		version = "0.5.35",
		date = "2026-11-23",
		changes = {
			"FBL realm fix: entries added from a unit lost the target's server - GetUnitFullName called GetUnitName without the realm flag and CleanName stripped any -Realm suffix, so AddEntry silently stored our own realm. A ported GetUnitNameRealm (name + realm returns) now feeds AddUnit, the window's Target button (name field carries First Last-Realm) and the tooltip auto-add, matching the standalone ForeverBlackListed.",
		},
		changesDE = {
			"FBL-Realm-Fix: Eintraege von Units verloren den Server des Ziels - GetUnitFullName rief GetUnitName ohne Realm-Flag auf und CleanName strippte jeden -Realm-Suffix, sodass AddEntry still unseren eigenen Realm speicherte. Ein portiertes GetUnitNameRealm (Name + Realm als Returns) versorgt jetzt AddUnit, den Target-Button im Fenster (das Namensfeld traegt Vorname Nachname-Realm) und das Tooltip-Auto-Add, identisch zum Standalone ForeverBlackListed.",
		},
	},
	{
		version = "0.5.34",
		date = "2026-11-22",
		changes = {
			"Layer channel parking fix: the join/leave timers in the world plugin ran unguarded seconds later, tripping 'forbidden call: UNKNOWN()' when combat started in between. Each timer step now bails under InCombatLockdown.",
		},
		changesDE = {
			"Layer-Channel-Parking-Fix: die Join/Leave-Timer im World-Plugin liefen ungeschuetzt Sekunden spaeter und loesten 'forbidden call: UNKNOWN()' aus, wenn zwischendurch Kampf begann. Jeder Timer-Schritt bricht jetzt unter InCombatLockdown ab.",
		},
	},
	{
		version = "0.5.33",
		date = "2026-11-22",
		changes = {
			"Accent edge lines (top/bottom bars, plugins menu, toasts) are now inset 7px past the corner arc so they end on the straight edge instead of poking past the rounded frame silhouette.",
		},
		changesDE = {
			"Akzent-Kantenlinien (obere/untere Leisten, Plugins-Menue, Toasts) sind jetzt 7px hinter den Eckbogen eingesetzt, damit sie an der geraden Kante enden statt ueber die gerundete Rahmensilhouette hinauszuragen.",
		},
	},
	{
		version = "0.5.32",
		date = "2026-11-22",
		changes = {
			"The blacklist window's filter chips use the shared Sentinel tab chip now: dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active chip - one design language across the whole suite.",
		},
		changesDE = {
			"Die Filter-Chips des Blacklist-Fensters nutzen jetzt den gemeinsamen Sentinel-Tab-Chip: dunkler Inset-Koerper mit 2px Akzent-Klinge an der linken Kante, die bei Hover glimmt und auf dem aktiven Chip brennt - eine Designsprache fuer die ganze Suite.",
		},
	},
	{
		version = "0.5.31",
		date = "2026-11-22",
		changes = {
			"New installer step 'Bottom bar plugins': a scrollable checklist of every registered plugin - tick what should show on the bottom bar, untick what should not. Changes apply live and stay editable under SentiUI > Panel > Plugins.",
		},
		changesDE = {
			"Neuer Installer-Schritt 'Plugins der unteren Leiste': eine scrollbare Checkliste aller gemeldeten Plugins - ankreuzen, was unten erscheinen soll, abhaken, was nicht. Aenderungen greifen sofort und bleiben unter SentiUI > Panel > Plugins editierbar.",
		},
	},
	{
		version = "0.5.30",
		date = "2026-11-22",
		changes = {
			"The performance plugin defaults to hidden: the same readout now lives as a gear icon on the minimap (SentiUI_Minimap 0.3.14). The bar entry stays available under Panel > Plugins; existing configs keep their choice.",
		},
		changesDE = {
			"Das Leistungs-Plugin ist jetzt standardmäßig versteckt: dieselbe Anzeige liegt als Zahnrad-Symbol an der Minimap (SentiUI_Minimap 0.3.14). Der Leisten-Eintrag bleibt unter Panel > Plugins verfügbar; bestehende Konfigurationen behalten ihre Wahl.",
		},
	},
	{
		version = "0.5.29",
		date = "2026-11-22",
		changes = {
			"Overlapping plugin texts fixed: GetStringWidth can return 0 (not nil) before a string has rendered on this client - the width fallback never kicked in, so a freshly updated plugin collapsed to icon width and its neighbor drew over it.",
		},
		changesDE = {
			"Überlappende Plugin-Texte behoben: GetStringWidth kann auf diesem Client 0 liefern (nicht nil), bevor ein String gerendert wurde - der Breiten-Fallback griff nie, ein frisch aktualisiertes Plugin kollabierte auf Iconbreite und der Nachbar zeichnete darüber.",
		},
	},
	{
		version = "0.5.28",
		date = "2026-11-22",
		changes = {
			"Plugin secure overlays (item/macro targets) no longer replace the template OnClick - clicks run through the client's secure dispatch.",
		},
		changesDE = {
			"Secure-Overlays der Plugins (Item-/Makro-Ziele) ersetzen das Template-OnClick nicht mehr - Klicks laufen über den sicheren Dispatch des Clients.",
		},
	},
	{
		version = "0.5.27",
		date = "2026-11-22",
		changes = {
			"The bottom bar starts leaner: only brand, gold, bags, clock, mail, layer, friends, guild, performance, professions and account info show on a fresh profile; location, spec, item level, XP, durability, trainers, compendium and blacklist default to hidden (re-enable under Panel > Plugins). Existing configs are untouched.",
		},
		changesDE = {
			"Die untere Leiste startet schlanker: auf einem neuen Profil sind nur Brand, Gold, Taschen, Uhr, Post, Layer, Freunde, Gilde, Performance, Berufe und AccountInfo sichtbar; Location, Spec, Itemlevel, XP, Haltbarkeit, Lehrer, Kompendium und Blacklist sind standardmäßig versteckt (wieder aktivierbar unter Panel > Plugins). Bestehende Konfigurationen bleiben unverändert.",
		},
	},
	{
		version = "0.5.26",
		date = "2026-11-22",
		changes = {
			"New bottom-bar plugin \"AccountInfo\": shows total account gold and character count from the SentiUI_AccountInfo module; click opens its window, the menu lists the richest characters and offers a rescan.",
		},
		changesDE = {
			"Neues Bottom-Bar-Plugin \"AccountInfo\": zeigt Gesamtgold und Charakteranzahl aus dem SentiUI_AccountInfo-Modul; Klick öffnet das Fenster, das Menü listet die reichsten Charaktere und bietet einen Rescan.",
		},
	},
	{
		version = "0.5.25",
		date = "2026-11-22",
		changes = {
			"New 'Professions' plugin (bottom bar): shows the first learned profession with icon, name and rank; a click opens the professions menu listing every learned profession with its skill level (rank/max) - clicking one opens the game's profession window via C_TradeSkillUI.OpenTradeSkill (works from a click, even in combat). Hides itself while no profession is learned.",
		},
		changesDE = {
			"Neues 'Berufe'-Plugin (untere Leiste): zeigt den ersten gelernten Beruf mit Symbol, Name und Fertigkeit; ein Klick oeffnet das Berufs-Menue mit allen gelernten Berufen samt Fertigkeitsstufe (Rang/Max) - ein Klick darauf oeffnet das Berufsfenster des Spiels ueber C_TradeSkillUI.OpenTradeSkill (geht per Klick, sogar im Kampf). Versteckt sich, solange kein Beruf gelernt ist.",
		},
	},
	{
		version = "0.5.24",
		date = "2026-11-22",
		changes = {
			"Embedded ForeverBlackListed dialogs (note edit, removal request, sync accept) converted to the shared own dialog instead of StaticPopupDialogs entries; all panel windows now close on Escape via S.EscClosable. Both changes remove addon-written entries from game tables that the Escape dispatch reads in Lua - the source of the 'ADDON_ACTION_FORBIDDEN SpellStopCasting' blame.",
		},
		changesDE = {
			"Eingebettete ForeverBlackListed-Dialoge (Notiz, Entfernen-Anfrage, Sync-Angebot) auf den eigenen Dialog statt StaticPopupDialogs-Eintraegen umgestellt; alle Panel-Fenster schliessen jetzt per S.EscClosable auf Escape. Beides entfernt Addon-geschriebene Eintraege aus Spiel-Tabellen, die der Escape-Dispatch in Lua liest - die Quelle des 'ADDON_ACTION_FORBIDDEN SpellStopCasting'-Blames.",
		},
	},
	{
		version = "0.5.23",
		date = "2026-11-22",
		changes = {
			"Player right-click menus now carry the same ForeverBlackListed entries the standalone adds: blacklist, good list, guild entries and a group picker - on Menu.ModifyMenu, classic UnitPopup and a docked fallback, so they show whichever backend draws the menu. Skipped when the standalone addon is installed (it registers them itself).",
		},
		changesDE = {
			"Spieler-Rechtsklickmenüs tragen jetzt dieselben ForeverBlackListed-Einträge wie das Standalone: Blacklist, Good List, Gilden-Einträge und Gruppenauswahl - über Menu.ModifyMenu, klassisches UnitPopup und ein angedocktes Fallback, egal welches Backend das Menü zeichnet. Übersprungen, wenn das Standalone installiert ist (es registriert sie selbst).",
		},
	},
	{
		version = "0.5.22",
		changes = {
			"UNIT vital events join the poll: UNIT_HEALTH/POWER/AURA/HAPPINESS/PET handlers shared the unit-frame update dispatch with Blizzard's secret health-bar compares ('execution tainted by SentiUI_Panel' in HealthBar/UnitFrame) - the vitals/buffs/pet plugins now refresh on the 1.5s ticker with a synthesized 'player' unit arg so their filters still pass. Also fixed: extdb() (the standalone FBL db when ForeverBlackListed is loaded) never ran through our defaults guarantee - callers indexing db.sync crashed again; it now guarantees .sync the same way DB() does.",
		},
		changesDE = {
			"UNIT-Vital-Events jetzt auch gepollt: UNIT_HEALTH/POWER/AURA/HAPPINESS/PET-Handler teilten den Unitframe-Update-Dispatch mit Blizzards Secret-Healthbar-Vergleichen ('execution tainted by SentiUI_Panel' in HealthBar/UnitFrame) - Vitals-/Buff-/Pet-Plugins refreshen jetzt auf dem 1,5s-Ticker mit synthetisiertem 'player'-Unit-Arg, damit ihre Filter greifen. Ausserdem: extdb() (die Standalone-FBL-DB bei geladenem ForeverBlackListed) lief nie durch unsere Defaults-Garantie - db.sync-Zugriffe crashten erneut; es garantiert .sync jetzt wie DB().",
		},
	},

	{
		version = "0.5.21",
		changes = {
			"Event-bus de-taint: the client fires window-data events (durability, equipment/ilvl, spells/talents, friends/guild, quests, tradeskill/AH, mail, bags, money/xp/honor, tracking) INSIDE the window-open or input dispatch - a handler running there taints the dispatch and the client's secret status-bar compare right after fails with 'execution tainted by SentiUI_Panel' (the 16x TextStatusBar error on pressing C). Those events are now polled on a 1.5s ticker; arg-carrying events (UNIT_*, TIME_PLAYED_MSG, layer protocol) stay event-driven.",
		},
		changesDE = {
			"Event-Bus ent-taintet: Der Client feuert Fensterdaten-Events (Haltbarkeit, Ausruestung/Itemlevel, Zauber/Talente, Freunde/Gilde, Quests, Beruf/AH, Post, Taschen, Geld/XP/Ehre, Tracking) INNERHALB des Fenster-Oeffnungs- oder Input-Dispatch - ein dort laufender Handler taintet den Dispatch und der Secret-Statusbar-Vergleich des Clients danach schlaegt fehl ('execution tainted by SentiUI_Panel' - der 16x-TextStatusBar-Fehler beim Druecken von C). Diese Events werden jetzt auf einem 1,5s-Ticker gepollt; arg-tragende Events (UNIT_*, TIME_PLAYED_MSG, Layer-Protokoll) bleiben eventbasiert.",
		},
	},

	{
		version = "0.5.20",
		changes = {
			"Blacklist window joins the combat deferral: opening it mid-combat queues for after the fight with a chat note, and an open window hides on combat start and returns after (core S:CombatDeferWindow).",
		},
		changesDE = {
			"Blacklist-Fenster haengt an der Kampf-Verzoegerung Oeffnen im Kampf wird mit Chat-Notiz bis nach dem Kampf zurueckgestellt, ein offenes Fenster versteckt sich bei Kampfbeginn und kommt danach wieder (Core S:CombatDeferWindow).",
		},
	},

	{
		version = "0.5.19",
		changes = {
			"Blacklist peers strip now shows whether someone's list is complete: a lightweight FBLstat message (rev + entry count, ignored by older clients and the standalone) rides alongside the version ping, so each peer row displays 'rev N  theirs/ours' - green when the peer is caught up, red when behind. Our own stats re-announce shortly after merges and manual imports.",
		},
		changesDE = {
			"Blacklist-Peerliste zeigt jetzt ob eine Liste vollstaendig angekommen ist: eine leichte FBLstat-Nachricht (Rev + Eintraegezahl, von aelteren Clients und dem Standalone ignoriert) fliegt mit dem Versions-Ping mit, sodass jede Peer-Zeile 'rev N  deren/unsere' anzeigt - gruen bei Stand gleich, rot bei Rueckstand. Eigene Stats werden nach Merges und manuellen Importen zeitnah neu angekuendigt.",
		},
	},

	{
		version = "0.5.18",
		changes = {
			"Blacklist sync log: fixed the search box overlapping the new chip (window is wider now) and added a peers strip on the sync page - known FBL clients on the channel with addon version, list revision and last-seen time, plus a live channel member count when the roster API resolves.",
		},
		changesDE = {
			"Blacklist Sync-Log: Suchfeld-Ueberlappung mit dem neuen Chip behoben (Fenster jetzt breiter) und eine Peer-Leiste auf der Sync-Seite ergaenzt - bekannte FBL-Clients im Channel mit Addon-Version, Listen-Revision und Zeitpunkt des letzten Kontakts, plus Live-Mitgliederzahl des Channels wenn die Roster-API aufloesbar ist.",
		},
	},

	{
		version = "0.5.17",
		changes = {
			"Blacklist: new 'Sync log' page in the list window (for every user, not just admins) - live status (channel, own/peer revision, live share, auto-accept, trust, last sender) plus a persisted ring buffer of all sync traffic: list sends/receives, chunk counts, pull requests, version pings, peers, removal requests, imports and delegations to the standalone addon. 'Request update' and 'Clear log' buttons included.",
		},
		changesDE = {
			"Blacklist: neue 'Sync-Log'-Seite im Listenfenster (fuer jeden Nutzer, nicht nur Admins) - Live-Status (Channel, eigene/Peer-Revision, Live-Teilen, Auto-Annehmen, Vertrauen, letzter Absender) plus persistenter Ringspeicher des gesamten Sync-Verkehrs: Listen-Versand/-Empfang, Chunk-Anzahlen, Pull-Anfragen, Versions-Pings, Peers, Loeschanfragen, Importe und Delegationen an das Standalone-Addon. Buttons 'Update anfragen' und 'Log leeren'.",
		},
	},

	{
		version = "0.5.16",
		changes = {
			"Hardened the FBL channel handler further: DB() now guarantees .sync is a table on every resolved store (pcall'd merge + a secret-safe table check), and the FBLver handler self-heals a missing sync field instead of indexing nil.",
		},
		changesDE = {
			"Den FBL-Kanal-Handler weiter gehaertet: DB() garantiert jetzt dass .sync auf jedem aufgeloesten Store eine Tabelle ist (gepcallter Merge + secret-sicherer Typ-Check), und der FBLver-Handler heilt ein fehlendes sync-Feld selbst statt nil zu indexieren.",
		},
	},

	{
		version = "0.5.15",
		changes = {
			"Fixed 'attempt to index field sync (a nil value)' on incoming FBL channel messages: a saved-variables file of another FBLDB declarer can hand us a global that never saw the defaults merge - DB() now guarantees merged defaults on every table it resolves, so .sync and friends always exist.",
		},
		changesDE = {
			"Fix fuer 'attempt to index field sync (a nil value)' bei eingehenden FBL-Kanalnachrichten: Eine Saved-Variables-Datei eines anderen FBLDB-Deklarierenden kann uns ein Global liefern, das nie den Defaults-Merge gesehen hat - DB() garantiert jetzt gemergte Defaults auf jeder Tabelle, die es aufloest, .sync & Co. existieren also immer.",
		},
	},

	{
		version = "0.5.14",
		changes = {
			"The shared blacklist now actually reaches other players: the importer routes through the sync owner's store (the standalone's ImportJSON when it is loaded, our live FBLDB otherwise) and runs non-quiet, so the list revision bumps and live-share rebroadcasts the fresh entries on the FBL channel. The probe now checks the sync store too, not just the saved global.",
		},
		changesDE = {
			"Die geteilte Blacklist erreicht jetzt wirklich andere Spieler: Der Importer laeuft ueber den Store des Sync-Besitzers (ImportJSON des Standalone wenn geladen, sonst unser live FBLDB) und nicht-quiet, sodass die Listen-Revision steigt und Live-Share die neuen Eintraege auf dem FBL-Kanal sendet. Die Pruefung schaut jetzt ebenfalls in den Sync-Store statt nur ins gespeicherte Global.",
		},
	},

	{
		version = "0.5.13",
		changes = {
			"Fixed the shared-blacklist import re-running (and reporting) every login: FBLDB is declared by several addons and the last saved-variables file to load replaces the global - the cached F.db pointed at an orphaned table, so the once-flag and imported entries never reached disk. All FBL reads now resolve the live global, the importer probes for present entries before running and stays silent either way.",
		},
		changesDE = {
			"Der Blacklist-Import lief (und meldete) bei jedem Login erneut: FBLDB wird von mehreren Addons deklariert und die zuletzt geladene Saved-Variables-Datei ersetzt das Global - das gecachte F.db zeigte auf eine verwaiste Tabelle, sodass Einmal-Flag und importierte Eintraege nie gespeichert wurden. Alle FBL-Zugriffe lesen jetzt das live Global, der Importer prueft vorhandene Eintraege vorher und bleibt in jedem Fall still.",
		},
	},

	{
		version = "0.5.12",
		changes = {
			"SecureAPI now delegates to the shared core wrapper: blocked or failed engine calls print their call site (file.lua:line) once, the same reporting every module gets.",
		},
		changesDE = {
			"SecureAPI delegiert jetzt an den gemeinsamen Core-Wrapper: Blockierte oder fehlgeschlagene Engine-Calls melden ihre Aufrufstelle (datei.lua:zeile) einmal - dasselbe Reporting, das jedes Modul bekommt.",
		},
	},

	{
		version = "0.5.11",
		changes = {
			"Interface-dispatch audit: plugin buttons got a secure-click overlay - bags, friends, guild, character, talents and calendar now forward a real click to the Blizzard micro buttons instead of calling Toggle* functions from addon code (securecall does not untaint on this client; the calls wrote window bookkeeping tainted). Reputation/itemlevel land on the matching Character-module page; durability uses the module API when it is loaded.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Plugin-Buttons bekamen ein Secure-Click-Overlay - Taschen, Freunde, Gilde, Charakter, Talente und Kalender leiten jetzt einen echten Klick an die Blizzard-Micro-Buttons weiter statt Toggle*-Funktionen aus Addon-Code zu rufen (securecall ent-taintet auf diesem Client nicht; die Aufrufe schrieben Fenster-Bookkeeping tainted). Ruf/Gegenstandsstufe landen auf der passenden Character-Modul-Seite; Haltbarkeit nutzt die Modul-API wenn geladen.",
		},
	},

	{
		version = "0.5.10",
		changes = {
			"Dispatcher rollback: the world plugin listens to PLAYER_TARGET_CHANGED/UPDATE_MOUSEOVER_UNIT again (GUID-poll ticker removed), TRADE_SKILL_*/AUCTION_HOUSE_* events and BAG_UPDATE_COOLDOWN on the hearthstone plugin are back.",
		},
		changesDE = {
			"Dispatcher-Rollback: Das World-Plugin hoert wieder auf PLAYER_TARGET_CHANGED/UPDATE_MOUSEOVER_UNIT (GUID-Poll-Ticker entfernt), TRADE_SKILL_*/AUCTION_HOUSE_*-Events und BAG_UPDATE_COOLDOWN beim Ruhestein-Plugin sind zurueck.",
		},
	},
	{
		version = "0.5.9",
		changes = {
			"Removed TRADE_SKILL_* and AUCTION_HOUSE_* window events from the world plugins - they fire inside the window's open dispatch and tainted Blizzard's CooldownFrame_Set on secret cooldown values (professions book error). Status refresh runs via the regular update path.",
		},
		changesDE = {
			"TRADE_SKILL_*- und AUCTION_HOUSE_*-Fenster-Events aus den Welt-Plugins entfernt - sie feuern im Oeffnungs-Dispatch des Fensters und tainteten Blizzards CooldownFrame_Set bei Secret-Cooldowns (Fehler im Berufefenster). Status laeuft ueber den normalen Update-Pfad.",
		},
	},
	{
		version = "0.5.8",
		changes = {
			"BAG_UPDATE_COOLDOWN removed from the hearthstone plugin: using its secure item button fires the event inside the click dispatch and taints the client's follow-up protected calls. The 1s refresh keeps the cooldown text current.",
		},
		changesDE = {
			"BAG_UPDATE_COOLDOWN aus dem Ruhestein-Plugin entfernt: Der gesicherte Item-Button feuert das Event im Klick-Dispatch und taintet die folgenden geschützten Aufrufe. Der 1s-Refresh hält den Cooldown-Text aktuell.",
		},
	},
	{
		version = "0.5.7",
		changes = {
			"Escape-forbidden-call fix, round 4 - the real last source: the layer plugin listened to PLAYER_TARGET_CHANGED and UPDATE_MOUSEOVER_UNIT. Both fire INSIDE the protected ESC/click dispatch (deselecting or re-targeting), so merely receiving them ran Lua inside the dispatch and tainted the client's SpellStopCasting/SpellStopTargeting calls right after - no defer can fix that, the events had to go. Target/mouseover sightings now poll on a 0.4s ticker (the votes only need the GUID), and nameplate sightings stay event-driven since NAME_PLATE_UNIT_ADDED fires on the render path, not the input path.",
		},
		changesDE = {
			"Escape-Blockier-Fix, Runde 4 - die wirklich letzte Quelle: Das Layer-Plugin hörte auf PLAYER_TARGET_CHANGED und UPDATE_MOUSEOVER_UNIT. Beide feuern INNERHALB des geschützten ESC-/Klick-Dispatch (Abwählen oder Umzielen), sodass schon ihr Empfang Lua im Dispatch laufen ließ und die direkt folgenden SpellStopCasting/SpellStopTargeting-Aufrufe taintete - kein Defer kann das retten, die Events mussten weg. Ziel-/Mouseover-Sichtungen pollen jetzt auf einem 0,4s-Ticker (die Stimmen brauchen nur die GUID), Nameplate-Sichtungen bleiben eventbasiert, da NAME_PLATE_UNIT_ADDED auf dem Render-Pfad feuert, nicht im Input-Pfad.",
		},
	},
	{
		version = "0.5.6",
		changes = {
			"Escape-forbidden-call fix, round 3: the last insecure code left in the Escape dispatch was the removal-request popup's OnHide callback plus two OnEditFocusLost handlers (even a deferred C_Timer call inside the handler marks the dispatch tainted, so SpellStopCasting right after got ADDON_ACTION_FORBIDDEN). The popup now tracks visibility via StaticPopup_Visible, the admin box saves on each keystroke, and the helper's focus-loss handler is gone entirely.",
		},
		changesDE = {
			"Escape-Blockier-Fix, Runde 3: Der letzte unsichere Code im Escape-Dispatch waren der OnHide-Callback des Entfernen-Request-Popups und zwei OnEditFocusLost-Handler (selbst ein verzögerter C_Timer-Aufruf im Handler markiert den Dispatch als tainted, danach wird SpellStopCasting als ADDON_ACTION_FORBIDDEN geblockt). Das Popup nutzt jetzt StaticPopup_Visible, die Admin-Box speichert bei jedem Tastendruck, der Fokusverlust-Handler ist komplett raus.",
		},
	},
	{
		version = "0.5.5",
		changes = {
			"Escape errors gone for real: the remaining OnEscapePressed and OnEditFocusLost handlers on panel/FBL windows ran insecure code inside the Escape dispatch, which tainted the engine's SpellStopCasting/SpellStopTargeting calls right after it (ADDON_ACTION_FORBIDDEN on window close). Both windows are in UISpecialFrames so Escape closes them natively - the handlers were removed, focus-loss work defers a frame.",
		},
		changesDE = {
			"Escape-Fehler jetzt wirklich weg: Die verbliebenen OnEscapePressed-/OnEditFocusLost-Handler an Panel-/FBL-Fenstern liefen unsicher innerhalb des Escape-Dispatch und tainteten damit die direkt folgenden SpellStopCasting/SpellStopTargeting-Aufrufe der Engine (ADDON_ACTION_FORBIDDEN beim Fenster-Schließen). Beide Fenster stehen in UISpecialFrames, Escape schließt sie nativ - die Handler sind raus, Fokus-Arbeit läuft einen Frame später.",
		},
	},
	{
		version = "0.5.4",
		changes = {
			"Removed the GameTooltip OnTooltipSetUnit HookScript fallback - an insecure handler on a Blizzard frame taints its whole dispatch, and the game then blamed SentiUI_Panel when its own unit-health code crashed on secret values (the 'blizzard: GameTooltip / TextStatusBar' reports). Blacklist tooltip lines now only draw through TooltipDataProcessor; without it they stay off.",
		},
		changesDE = {
			"GameTooltip-OnTooltipSetUnit-HookScript-Fallback entfernt - ein unsicherer Handler auf einem Blizzard-Frame taintet dessen gesamten Dispatch, und das Spiel gab dann SentiUI_Panel die Schuld, wenn sein eigener Lebensbalken-Code an Secret-Werten crashte (die 'blizzard: GameTooltip / TextStatusBar'-Meldungen). Blacklist-Tooltip-Zeilen zeichnen jetzt nur noch über TooltipDataProcessor; ohne ihn bleiben sie aus.",
		},
	},
	{
		version = "0.5.3",
		changes = {
			"Removed the SendChatMessage fallbacks from FBL sync - channel chat text is hardware-gated on this client, so every timer-driven retry raised a blocked call (the anonymous UNKNOWN() errors). Addon messages carry the same protocol and need no input event.",
			"Layer asks behave the same way now: the visible chat route is only attempted when you actually clicked, retried/timer asks use the addon-note path.",
		},
		changesDE = {
			"SendChatMessage-Fallbacks aus der FBL-Sync entfernt - Chat-Text auf Channels ist auf diesem Client hardware-gated, jeder Timer-Versuch erzeugte einen geblockten Aufruf (die anonymen UNKNOWN()-Fehler). Addon-Messages tragen dasselbe Protokoll und brauchen kein Eingabe-Event.",
			"Layer-Anfragen verhalten sich genauso: Die sichtbare Chat-Route wird nur bei echtem Klick versucht, Timer-/Retry-Anfragen laufen über den Addon-Notiz-Pfad.",
		},
	},
	{
		version = "0.5.2",
		changes = {
			"Routed every remaining FBL sync send and channel join through the named blocked-call diagnostic - if a call is still refused, the chat now prints which function and line instead of a bare UNKNOWN().",
		},
		changesDE = {
			"Alle verbliebenen FBL-Sync-Sends und Channel-Joins laufen jetzt durch die benannte Blocked-Call-Diagnose - falls ein Aufruf noch abgelehnt wird, steht im Chat jetzt Funktion und Zeile statt nur UNKNOWN().",
		},
	},
	{
		version = "0.5.1",
		changes = {
			"The sentilayer channel no longer grabs a default slot: when it sits on slot 1-6 a filler channel (sentipark) takes the low slot, the layer channel rejoins above it and the filler leaves. Checked on join, when already joined and once after entering the world.",
		},
		changesDE = {
			"Der sentilayer-Channel belegt keinen Standard-Slot mehr: Sitzt er auf Slot 1-6, nimmt ein Filler-Channel (sentipark) den niedrigen Slot, der Layer-Channel joint darueber neu und der Filler verlaesst wieder. Geprueft beim Join, wenn bereits gejoint und einmal nach dem Betreten der Welt.",
		},
	},
	{
		version = "0.5.0",
		changes = {
			"KillStats removed entirely: the kill-tracking window, map pins, /suipanel kills and wp commands, the kills and map-search plugins and the options button are gone - the feature kept tripping the client's taint radar around the world map.",
		},
		changesDE = {
			"KillStats komplett entfernt: Kill-Tracking-Fenster, Map-Pins, die /suipanel kills- und wp-Befehle, das Kills- und Map-Suche-Plugin sowie der Options-Button sind weg - das Feature loeste am WorldMap-Frame immer wieder Taint-Alarm aus.",
		},
	},
	{
		version = "0.4.8",
		changes = {
			"Kill-map pins no longer reparent into WorldMapFrame's canvas: our insecure child frames sat inside the map's protected frame tree, so ESC-close ran the teardown through addon code and blamed the panel. Pins are UIParent children anchored relative to the canvas now - same dots, zero taint.",
		},
		changesDE = {
			"Kill-Map-Pins werden nicht mehr in WorldMapFrames Canvas umgehaengt: Unsere unsicheren Kinder saßen im geschuetzten Frame-Baum der Karte, beim ESC-Schliessen lief der Teardown durch Addon-Code und die Schuld landete beim Panel. Pins sind jetzt UIParent-Kinder, relativ zur Canvas verankert - gleiche Punkte, null Taint.",
		},
	},
	{
		version = "0.4.7",
		changes = {
			"ns.HardAPI: a named wrapper for hardware/protected calls we cannot predict (party invites/leaves/kicks, channel joins, channel sends). When the client rejects one the panel prints 'blocked call: <name> @ file.lua:line' once - turning anonymous 'UNKNOWN()' blame into an exact call site.",
		},
		changesDE = {
			"ns.HardAPI: Ein benannter Wrapper fuer Hardware-/geschuetzte Aufrufe, die wir nicht vorhersagen koennen (Party-Invites/-Leaves/-Kicks, Channel-Joins, Channel-Sends). Lehnt der Client einen ab, gibt das Panel einmal 'blocked call: <name> @ datei.lua:zeile' aus - aus anonymem 'UNKNOWN()'-Blame wird eine exakte Aufrufstelle.",
		},
	},
	{
		version = "0.4.6",
		changes = {
			"Volume plugin: the legacy SetCVar global is protected on this client - pcall caught the error but the blocked-action event still fired ('UNKNOWN()'). Sound toggle and volume steps use C_CVar.SetCVar now.",
			"FBL channel sends respect combat lockdown: chunk drain, pull requests and version pings pause mid-fight instead of piling up blocked sends.",
		},
		changesDE = {
			"Lautstaerke-Plugin: Das alte SetCVar-Global ist auf diesem Client geschuetzt - pcall fing den Fehler ab, das Blocked-Event feuerte trotzdem ('UNKNOWN()'). Sound-Toggle und Lautstaerke-Stufen nutzen jetzt C_CVar.SetCVar.",
			"FBL-Channel-Sends respektieren den Kampf-Lockdown: Chunk-Drain, Pull-Requests und Versions-Pings pausieren im Kampf statt geblockte Sends zu stapeln.",
		},
	},
	{
		version = "0.4.5",
		changes = {
			"Removed insecure script hooks from Blizzard frames: kill-map rare pins no longer HookScript WorldMapFrame (ESC-close ran the protected teardown through the hooked frame -> 'forbidden call: UNKNOWN()'), they poll from an own ticker while the map is open.",
			"The minimap mail indicator polls IsShown on demand now instead of hooking OnShow/OnHide.",
		},
		changesDE = {
			"Unsichere Script-Hooks von Blizzard-Frames entfernt: Die Kill-Map-Rare-Pins haken WorldMapFrame nicht mehr per HookScript (ESC-Schliessen lief den geschuetzten Teardown ueber den gehookten Frame -> 'forbidden call: UNKNOWN()'), sie pollen jetzt ueber einen eigenen Ticker.",
			"Der Minimap-Mail-Indikator fragt IsShown bei Bedarf ab statt OnShow/OnHide zu hooken.",
		},
	},
	{
		version = "0.4.4",
		changes = {
			"More 'UNKNOWN()' sources closed: plugin updates fire on every bus event (gold, coords, bags - mid-combat too) and ran SetParent/SetPoint/SetShown on buttons holding the secure overlay; sizing + relayout now defer through S.RunOutOfCombat.",
			"The FBL channel join no longer runs during combat lockdown - JoinChannelByName is combat-protected and the retry timer kept getting blocked mid-fight.",
		},
		changesDE = {
			"Weitere 'UNKNOWN()'-Quellen geschlossen: Plugin-Updates feuern bei jedem Bus-Event (Gold, Koordinaten, Taschen - auch mitten im Kampf) und fuehrten SetParent/SetPoint/SetShown auf Buttons mit Secure-Overlay aus; Resize/Relayout laeuft jetzt ueber S.RunOutOfCombat.",
			"Der FBL-Channel-Join laeuft nicht mehr waehrend des Kampfes - JoinChannelByName ist kampfgeschuetzt und der Retry-Timer wurde mitten im Kampf geblockt.",
		},
	},
	{
		version = "0.4.3",
		changes = {
			"Taint hardening: bars hide during combat via a secure visibility driver instead of insecure SetShown on frames holding secure children (the hearthstone overlay made that path blockable -> 'UNKNOWN()'). Anchoring/layout defers through S.RunOutOfCombat.",
			"The plugin menu's screen-wide click catcher propagates mouse clicks to the world now, so right-click cancels (SpellStopTargeting) and Escape cancels (SpellStopCasting) are no longer eaten and blamed on the panel.",
		},
		changesDE = {
			"Taint-Haertung: Bars verstecken sich im Kampf ueber einen sicheren Visibility-Driver statt ueber unsicheres SetShown auf Frames mit Secure-Kindern (das Ruhestein-Overlay machte den Pfad blockierbar -> 'UNKNOWN()'). Anker/Layout laufen ueber S.RunOutOfCombat.",
			"Der bildschirmweite Klick-Faenger des Plugin-Menus reicht Mausklicks jetzt an die Welt weiter - Rechtsklick-Abbrueche (SpellStopTargeting) und Escape-Abbrueche (SpellStopCasting) werden nicht mehr gefressen und dem Panel angelastet.",
		},
	},
	{
		version = "0.4.2",
		changes = {
			"Forbidden 'UNKNOWN()' calls now identify themselves: when a SecureAPI-wrapped function is rejected, the panel prints the actual call site (file.lua:line) once instead of leaving the blame anonymous.",
			"The hearthstone plugin is a real secure button now - item-use APIs are protected on this client, so the old UseItemByName click could only fail. Left-click uses it natively, right-click still opens the menu.",
		},
		changesDE = {
			"Verbotene 'UNKNOWN()'-Aufrufe benennen sich jetzt selbst: Wird eine SecureAPI-gewrappte Funktion abgelehnt, gibt das Panel die tatsaechliche Aufrufstelle (datei.lua:zeile) einmal aus, statt die Schuld anonym zu lassen.",
			"Das Ruhestein-Plugin ist jetzt ein echter Secure-Button - Item-APIs sind auf diesem Client geschuetzt, der alte UseItemByName-Klick konnte nur fehlschlagen. Linksklick benutzt ihn nativ, Rechtsklick oeffnet weiter das Menue.",
		},
	},
	{
		version = "0.4.1",
		changes = {
			"Kill-stats note popup: its Escape handler now defers Hide() out of the key dispatch like the other panel fields, closing the last synchronous Escape->hide path that could feed the protected Escape binding (ADDON_ACTION_BLOCKED/FORBIDDEN spam).",
		},
		changesDE = {
			"Kill-Stats-Notiz-Popup: Der Escape-Handler verzoegert Hide() jetzt wie die anderen Panel-Felder aus dem Key-Dispatch heraus - der letzte synchrone Escape-zu-Hide-Pfad, der das geschuetzte Escape-Binding fuettern konnte (ADDON_ACTION_BLOCKED/FORBIDDEN-Spam), ist geschlossen.",
		},
	},
	{
		version = "0.4.0",
		changes = {
			"Fixed the FBL module dying at load: the version-ping ticker captured SendVersionPing before its assignment, so the file aborted mid-load and every blacklist entry point stayed nil (clicks threw 'attempt to call a nil value'). The ticker now calls through a closure.",
		},
		changesDE = {
			"FBL-Modul starb beim Laden: Der Versions-Ping-Ticker hat SendVersionPing vor seiner Zuweisung erfasst, die Datei brach mitten im Laden ab und alle Blacklist-Einstiegspunkte blieben nil (Klicks warfen 'attempt to call a nil value'). Der Ticker ruft jetzt ueber eine Closure.",
		},
	},
	{
		version = "0.3.9",
		changes = {
			"FBL sync now performs the standalone's full convergence handshake: version pings carry our list revision, peers with a newer revision make us pull, joining pushes our list when dirty, and a watchdog rejoins a lost channel - ForeverBlackListed and SentiUI_Panel converge to identical lists in both directions.",
		},
		changesDE = {
			"FBL-Sync nutzt jetzt den vollen Konvergenz-Handshake des Standalone: Versions-Pings tragen unsere Listen-Revision, Peers mit neuerer Revision lassen uns pullen, beim Join pushen wir unsere Liste bei Änderung, ein Watchdog joint verlorene Channels neu - ForeverBlackListed und SentiUI_Panel gleichen ihre Listen in beide Richtungen ab.",
		},
	},
	{
		version = "0.3.8",
		changes = {
			"Fixed a Lua scoping error on channel join: the pull-request callback was declared below its use, so the timer got nil and threw - the sync-channel pull now fires correctly.",
		},
		changesDE = {
			"Lua-Scope-Fehler beim Channel-Join behoben: Der Pull-Request-Callback war unterhalb seiner Verwendung deklariert, der Timer bekam nil und warf einen Fehler - der Sync-Channel-Pull feuert jetzt korrekt.",
		},
	},
	{
		version = "0.3.7",
		changes = {
			"Blacklist sync receives FBL pull/version traffic now: after joining the channel we broadcast 'FBLpull;rev' asking peers for the newest list (an online ForeverBlackListed client answers with a full push), and we answer pull requests ourselves when our revision is ahead - jittered like the standalone. '/suipanel fbl' prints a sync debug line (channel, prefix, entries, last sender).",
		},
		changesDE = {
			"Blacklist-Sync spricht jetzt FBL-Pull/Versions-Traffic: nach dem Channel-Join broadcasten wir 'FBLpull;rev' und fragen nach der neuesten Liste (ein online ForeverBlackListed-Client antwortet mit einem Full-Push), und wir beantworten Pull-Anfragen selbst wenn unsere Revision vorn ist - gejittert wie das Standalone. '/suipanel fbl' gibt eine Sync-Debugzeile aus (Channel, Prefix, Einträge, letzter Sender).",
		},
	},
	{
		version = "0.3.6",
		changes = {
			"Blacklist sync no longer spams: your own broadcast echo is ignored (channel addon messages bounce back to the sender) and merges only print when entries were actually added or updated - silent merges stay silent.",
		},
		changesDE = {
			"Blacklist-Sync spammt nicht mehr: das eigene Echo wird ignoriert (Channel-Addon-Nachrichten kommen beim Sender wieder an) und Merges melden nur, wenn wirklich Einträge neu oder aktualisiert wurden - stille Merges bleiben still.",
		},
	},
	{
		version = "0.3.5",
		changes = {
			"Blacklist add-form: chips row is no longer clipped (taller form, fixed widths on Player/Guild/Good list). Sync send hardened: join waits for default channels and retries both channel names via all join APIs, the addon prefix registers at login, send falls back to channel chat when addon messages fail, progress and rejected chunks are reported.",
		},
		changesDE = {
			"Blacklist-Formular: Chip-Reihe wird nicht mehr abgeschnitten (höheres Formular, feste Breiten für Spieler/Gilde/Gute Liste). Sync-Versand gehärtet: Join wartet auf Standard-Channel und versucht beide Channelnamen über alle Join-APIs, das Addon-Prefix registriert beim Login, Versand fällt auf Channel-Chat zurück wenn Addon-Nachrichten scheitern, Fortschritt und abgelehnte Blöcke werden gemeldet.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Fixed ADDON_ACTION_FORBIDDEN (SpellStopCasting) blamed on the panel: Escape handlers in the blacklist fields, the text popup and the map search now defer focus loss/hide out of the key handler, so Escape no longer falls through to the protected binding.",
		},
		changesDE = {
			"ADDON_ACTION_FORBIDDEN (SpellStopCasting) behoben, das dem Panel zugerechnet wurde: Escape-Handler in den Blacklist-Feldern, dem Text-Popup und der Kartensuche verzögern Fokusverlust/Verstecken jetzt aus dem Key-Handler heraus, sodass Escape nicht mehr ins geschützte Binding durchfällt.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"Two builtin list admins now: Xenshi Lucas and Raziel Lucas - both can delete entries, moderate notes, answer removal requests and use Sync all. The standalone ForeverBlackListed honors the same pair.",
		},
		changesDE = {
			"Zwei eingebaute Listen-Admins: Xenshi Lucas und Raziel Lucas - beide können Einträge löschen, Notizen moderieren, Löschanfragen annehmen und Alles synchronisieren nutzen. Das Standalone-ForeverBlackListed gilt dasselbe Paar.",
		},
	},
	{
		version = "0.3.2",
		changes = {
			"Blacklist reached feature parity with the standalone: right-click context menu on entries (vote +/-, move between blacklist/good list, edit note, move to any group, remove), votes show your own mark; the admin page gained auto-accept + trust mode chips and JSON import/export popups. Ships a one-time importer that merges the shared ForeverBlackListed list into FBLDB.",
		},
		changesDE = {
			"Blacklist auf Standalone-Niveau: Rechtsklick-Kontextmenü auf Einträgen (Vote +/-, zwischen Blacklist/Guter Liste verschieben, Notiz bearbeiten, in beliebige Gruppe verschieben, entfernen), Votes zeigen die eigene Stimme; die Admin-Seite bekam Auto-Accept- und Vertrauens-Chips sowie JSON-Import/Export-Popups. Ein Einmal-Importer merged die geteilte ForeverBlackListed-Liste in FBLDB.",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Blacklist: full wire sync ported - 'Sync all' on the admin page pushes the whole list as chunked JSON on the FBLsync channel, incoming chunks are reassembled and merged last-write-wins (entries, notes, votes, tombstones) with the same trust/auto-accept rules and dedupe as the standalone; local changes rebroadcast via live-share. The add form now uses a real Player/Guild radio pair.",
		},
		changesDE = {
			"Blacklist: komplette Wire-Sync portiert - 'Alles synchronisieren' auf der Admin-Seite schickt die ganze Liste als gechunktes JSON auf den FBLsync-Channel, eingehende Chunks werden reassembliert und last-write-wins gemergt (Einträge, Notizen, Votes, Tombstones) mit denselben Trust-/Auto-Accept-Regeln und Dedupe wie das Standalone; lokale Änderungen gehen per Live-Share raus. Das Add-Formular nutzt jetzt ein echtes Spieler/Gilde-Radio-Paar.",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Blacklist admin page: an 'Admin' filter chip appears only for list admins and swaps the list for status, effective admins, the extra-admin field (shared sync.admin key) and pending removal requests with accept/decline.",
		},
		changesDE = {
			"Blacklist-Admin-Seite: Ein 'Admin'-Filterchip erscheint nur für Listen-Admins und tauscht die Liste gegen Status, wirksame Admins, das Extra-Admin-Feld (geteilter sync.admin-Key) und offene Löschanfragen mit Annehmen/Ablehnen.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Blacklist window rebuilt: icon header with accent rule, filter chips (All/Blocked/Good/Guild), live search across names, guilds and notes, group headers with counts and gold rules, zebra rows with kind icons, guild/realm/votes columns and rich tooltips (note, date, group).",
			"New add form at the bottom: name + note fields, Player/Guild and Good-list toggles, 'Target' fills the name box, 'Add' writes the entry.",
			"Proper empty states for empty list and empty search.",
		},
		changesDE = {
			"Blacklist-Fenster neu gebaut: Icon-Kopf mit Akzentlinie, Filter-Chips (Alle/Geblockt/Gut/Gilde), Live-Suche über Namen, Gilden und Notizen, Gruppenköpfe mit Zähler und Goldlinie, Zebra-Zeilen mit Art-Icon, Gilde/Realm/Votes und reichen Tooltips (Notiz, Datum, Gruppe).",
			"Neues Add-Formular unten: Name + Notiz, Spieler/Gilde- und Gut-Liste-Schalter, 'Ziel' füllt den Namen, 'Hinzufügen' schreibt den Eintrag.",
			"Saubere Leer-Zustände für leere Liste und leere Suche.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"Fixed a load error: the removal-request locale key contained a real line break inside a quoted string (unfinished string in deDE.lua).",
		},
		changesDE = {
			"Ladefehler behoben: Der Locale-Key der Löschanfrage enthielt einen echten Zeilenumbruch im String (unfinished string in deDE.lua).",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"FBL admin support: EffectiveAdmins (built-in admin + extra chars from sync.admin + the real addon's channel owner), IsAdmin checks, admin note deletion with tombstone stamps, and removal requests - 'FBLreq' messages ride the ForeverBlackListed/FBLsync channel both directions, admins get an accept popup, everyone else can request removal from the plugin menu.",
			"The list window marks admins in the subtitle.",
		},
		changesDE = {
			"FBL-Admin-Unterstützung: EffectiveAdmins (eingebauter Admin + Extrachars aus sync.admin + Channel-Besitzer des echten Addons), IsAdmin-Prüfung, Admin-Notizenlöschung mit Tombstone-Stempel sowie Löschanfragen - 'FBLreq'-Nachrichten laufen über den ForeverBlackListed/FBLsync-Channel in beide Richtungen, Admins bekommen ein Annahme-Popup, alle anderen können im Plugin-Menü eine Löschung anfragen.",
			"Das Listenfenster markiert Admins in der Unterzeile.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"ForeverBlackListed inside the panel: the 'Blacklist' plugin (bottom bar) shows the entry count and opens the list - with the real addon loaded it delegates to its window and sync, without it the panel keeps a fully compatible local store in the shared FBLDB.",
			"Adds/removes entries via right-click menu (target, mouseover), blacklist lines on unit tooltips including auto-add rules, whisper/invite warnings with auto-decline, plus a compact list window when the standalone addon is absent.",
		},
		changesDE = {
			"ForeverBlackListed im Panel: Das 'Blacklist'-Plugin (untere Leiste) zeigt die Eintragszahl und öffnet die Liste - ist das echte Addon geladen, übernimmt dessen Fenster und Sync, sonst führt das Panel einen voll kompatiblen lokalen Store im geteilten FBLDB.",
			"Eintragen/Austragen per Rechtsklick-Menü (Ziel, Mouseover), Blacklist-Zeilen in Unit-Tooltips inkl. Auto-Regeln, Flüster-/Einladungs-Warnungen mit Auto-Ablehnen sowie ein kompaktes Listenfenster, wenn das eigenständige Addon fehlt.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Plugin framework: new 'noLabel' flag lets a plugin suppress the 'Label:' prefix even when the label option is on - fixes 'Trainers: Trainers' staying after a saved config.",
		},
		changesDE = {
			"Plugin-Framework: Neues 'noLabel'-Flag unterdrückt das 'Label:'-Präfix auch bei aktiver Label-Option - behebt das hängengebliebene 'Lehrer: Lehrer' aus gespeicherter Config.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Fixed 'ADDON_ACTION_BLOCKED: UNKNOWN()' spam when hovering the Guild or Friends plugin: the tooltips refreshed rosters via pcall'd C_GuildInfo.GuildRoster / C_FriendList.ShowFriends, but pcall cannot stop the blocked-action log - both calls now go through SecureAPI (securecall), which runs them natively or fails quietly.",
		},
		changesDE = {
			"'ADDON_ACTION_BLOCKED: UNKNOWN()'-Spam beim Hovern über das Gilde- oder Freunde-Plugin behoben: Die Tooltips frischen Roster per pcall'd C_GuildInfo.GuildRoster / C_FriendList.ShowFriends auf, aber pcall kann das Blocked-Action-Log nicht verhindern - beide Aufrufe laufen jetzt über SecureAPI (securecall), der sie nativ ausführt oder still fehlschlägt.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Trainers and Compendium plugins no longer print their label twice ('Trainers: Trainers') - they show icon plus name once.",
		},
		changesDE = {
			"Lehrer- und Kompendium-Plugins zeigen ihr Label nicht mehr doppelt (\"Lehrer: Lehrer\") - nur noch Symbol plus Name.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"New 'Compendium' plugin (bottom bar): opens the SentiUI_Journal dungeon compendium when the module is installed.",
		},
		changesDE = {
			"Neues 'Kompendium'-Plugin (untere Leiste): öffnet das SentiUI_Journal-Dungeon-Kompendium, wenn das Modul installiert ist.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"New 'Trainers' plugin (bottom bar, book icon): opens the SentiUI_Training window - the trainer compendium with class spells, weapon skills and profession recipes. The plugin hides itself when the module is not installed.",
		},
		changesDE = {
			"Neues 'Lehrer'-Plugin (untere Leiste, Buch-Symbol): öffnet das SentiUI_Training-Fenster - das Lehrer-Kompendium mit Klassenzaubern, Waffenfertigkeiten und Berufsrezepten. Das Plugin versteckt sich, wenn das Modul nicht installiert ist.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Layer letters no longer balloon (Layer AA and friends): the vote winner was adopted instantly on every sighting, so layers overlapping in view flickered the display and each flicker minted a registry letter. A challenger now has to hold the majority for ~2.5s before the display flips; the first read still adopts at once. Registry writes are skipped during the stale window and on unreadable zones, and any per-zone list past Z (impossible in reality - pure flicker pollution) rebuilds itself.",
		},
		changesDE = {
			"Layer-Buchstaben explodieren nicht mehr (Layer AA und Kollegen): Der Vote-Sieger wurde bei jeder Sichtung sofort übernommen, sodass sich überlagernde Layer die Anzeige hin- und herrissen und jedes Flackern einen Registry-Buchstaben prägte. Ein Herausforderer muss die Mehrheit jetzt ~2,5s halten, bevor die Anzeige kippt; die erste Lesung übernimmt weiter sofort. Registry-Schreibzugriffe werden während des Stale-Fensters und bei unlesbarer Zone übersprungen, und jede Zonen-Liste hinter Z (real unmöglich - reines Flacker-Müll) baut sich neu auf.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Mail indicator rebuilt on the native signal: HasNewMail() is the verdict again (the call the engine's minimap envelope and SentinelForeverCore's info bar use). The minimap mail frame is only a fallback for a missing API, resolved as the icon child - never the always-shown IndicatorFrame container, which was the actual stuck-true bug - and tracked via OnShow/OnHide hooks like DaylightUI's mail dot. '/suipanel mail' now prints every candidate frame's state separately.",
		},
		changesDE = {
			"Post-Indikator auf das native Signal umgebaut: HasNewMail() ist wieder das Urteil (der Aufruf, den der Minimap-Brief des Spiels und SentinelForeverCores Infoleiste nutzen). Der Minimap-Mail-Frame ist nur noch Fallback bei fehlender API, aufgelöst als Icon-Kind - nie der immer sichtbare IndicatorFrame-Container, der der eigentliche Dauer-an-Bug war - und per OnShow/OnHide-Hooks verfolgt wie DaylightUIs Mail-Punkt. '/suipanel mail' zeigt jetzt jeden Kandidaten-Frame einzeln an.",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"World-map kill pins are now opt-in: nothing is drawn until you search for a mob. New 'Map search' plugin on the bottom bar (spyglass icon) - left-click opens a search box, matching kills light up their recorded spawn points on the world map, clearing the search hides every pin again. Right-click menu: search, clear, open statistics.",
		},
		changesDE = {
			"Weltkarten-Kill-Pins sind jetzt opt-in: Nichts wird gezeichnet, bis du nach einem Mob suchst. Neues 'Kartensuche'-Plugin in der unteren Leiste (Fernrohr-Symbol) - Links-Klick öffnet eine Suchbox, passende Kills markieren ihre gespeicherten Spawnpunkte auf der Weltkarte, Leeren der Suche versteckt alle Pins wieder. Rechts-Klick-Menü: Suchen, Löschen, Statistik öffnen.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Layer plugin: friendly layer names no longer require the standalone SentiLayer. The plugin now keeps its own per-zone layer registry in its saved options - layers get letters in first-seen order (Layer A, B, ...), persisted across reloads. SentiLayer's letters still win while that addon is loaded, so the naming stays consistent for anyone migrating.",
		},
		changesDE = {
			"Layer-Plugin: Freundliche Layer-Namen brauchen das eigenständige SentiLayer nicht mehr. Das Plugin führt jetzt eine eigene Layer-Registry pro Zone in den gespeicherten Optionen - Layer bekommen Buchstaben in Reihenfolge des ersten Sichtens (Layer A, B, ...), über Reloads hinweg gespeichert. Solange SentiLayer geladen ist, gewinnen dessen Buchstaben weiter, damit die Namen beim Umstieg gleich bleiben.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"The Layer plugin is now a self-contained SentiLayer replacement - the standalone addon is no longer needed. Left-click asks for a swap on the 'sentilayer' channel using the same protocol ('inv layer <SL zone not id>' plus hidden SentiLayer addon notes), so SentiLayer users still invite you; accept the invite, the votes confirm the move, and the host group is left automatically. A 'Host swaps' menu toggle (on by default) makes you a host too: asks on the channel are filtered by zone and wanted/avoided layers, answered invites are kicked after the guest moved. Known gaps vs. SentiLayer: no whisper-search fallback on restricted realms, no per-player notes log, no panel UI - this is the compact protocol surface.",
		},
		changesDE = {
			"Das Layer-Plugin ist jetzt ein vollständiger SentiLayer-Ersatz - das eigenständige Addon wird nicht mehr gebraucht. Links-Klick fragt einen Wechsel im 'sentilayer'-Channel mit demselben Protokoll an ('inv layer <SL zone not id>' plus versteckte SentiLayer-Addon-Notes), sodass SentiLayer-Nutzer dich weiterhin einladen; Einladung annehmen, die Votes bestätigen den Wechsel, die Host-Gruppe wird automatisch verlassen. Ein 'Wechsel hosten'-Menüpunkt (standardmäßig an) macht dich selbst zum Host: Anfragen im Channel werden nach Zone und gewünschter/vermiedener Layer gefiltert, angenommene Einladungen werden gekickt, sobald der Gast gewechselt ist. Bekannte Lücken ggü. SentiLayer: kein Whisper-Such-Fallback auf eingeschränkten Realms, kein Spieler-Notiz-Log, kein Panel-Fenster - nur die kompakte Protokoll-Oberfläche.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Layer plugin: the detected layer now persists across /reload - the last reading is kept in the plugin settings until the creature votes actually move to another layer (zone change, group join, Blizzard shard transfer), so the bar never flashes '?' on a relog while you still stand on the same shard.",
		},
		changesDE = {
			"Layer-Plugin: Die erkannte Layer bleibt jetzt über /reload erhalten - die letzte Lesung liegt in den Plugin-Einstellungen, bis die Kreaturen-Votes tatsächlich auf eine andere Layer umschlagen (Zonenwechsel, Gruppenbeitritt, Blizzard-Shard-Transfer). Die Leiste zeigt nach einem Relog kein '?' mehr, solange du auf demselben Shard stehst.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"New 'Layer' plugin (bottom bar, right side): reads your shard layer from the creature GUIDs in view, SentiLayer-style - server+zone of the GUID is the layer, the creatures present at a zone change or group join are frozen out for 10 seconds as leftovers of the old layer, and a majority vote over the last sightings decides. Shows the same per-zone letters (Layer A/B/C) when the standalone SentiLayer addon is loaded; left-click opens its panel, right-click asks for a layer swap.",
		},
		changesDE = {
			"Neues 'Layer'-Plugin (untere Leiste, rechts): liest deine Shard-Layer aus den Creature-GUIDs in Sichtweite nach SentiLayer-Art - Server+Zone der GUID ist die Layer, die bei Zonenwechsel oder Gruppenbeitritt sichtbaren Kreaturen werden 10 Sekunden als Reste der alten Layer eingefroren, und ein Mehrheitsvotum über die letzten Sichtungen entscheidet. Zeigt dieselben Zonen-Buchstaben (Layer A/B/C), wenn das eigenständige SentiLayer geladen ist; Links-Klick öffnet sein Fenster, Rechts-Klick fragt einen Layer-Wechsel an.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Mail detection reworked again after reports the indicator still stuck: the lookup now also covers MinimapCluster.MailFrame, falls back to the unread-sender list (GetLatestThreeSenders) when no mail frame exists, and only then to HasNewMail. New '/suipanel mail' command prints all three signal states plus the verdict so a stuck indicator can be traced to the layer that lies.",
		},
		changesDE = {
			"Post-Erkennung nach erneuten Meldungen nochmal überarbeitet: Die Suche deckt jetzt auch MinimapCluster.MailFrame ab, fällt auf die Ungelesen-Absenderliste (GetLatestThreeSenders) zurück, wenn kein Mail-Frame existiert, und erst dann auf HasNewMail. Neuer Befehl '/suipanel mail' zeigt alle drei Signalzustände plus Ergebnis, damit ein hängender Indikator zur lügenden Schicht verfolgt werden kann.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Fixed the mail indicator sticking on 'New mail': HasNewMail() stays true on this client after the mail was read, so the bottom bar never cleared. The plugin and the new-mail toast now trust the engine's minimap mail frame (shown = mail waiting) and only fall back to HasNewMail when the frame does not exist.",
		},
		changesDE = {
			"Post-Indikator klebte auf 'Neue Post': HasNewMail() bleibt auf diesem Client nach dem Lesen der Post auf true, die Leiste leerte sich nie. Plugin und Neuer-Post-Toast vertrauen jetzt dem Engine-Minimap-Post-Frame (sichtbar = Post wartet) und fallen nur auf HasNewMail zurück, wenn der Frame nicht existiert.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"The kill statistics window and the details/export text popup are now real movers: they get a handle in move mode, save via Movers.Save and keep their place across reloads.",
		},
		changesDE = {
			"Kill-Statistik-Fenster und das Detail-/Export-Textfenster sind jetzt echte Mover: Sie bekommen einen Griff im Verschiebe-Modus, speichern über Movers.Save und behalten ihre Position über Reloads.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Minimum plugin spacing: plugins inside a zone now always keep at least 8 px between each other, so a spacing of 0 can no longer glue them together. Plugin spacing slider starts at 8.",
		},
		changesDE = {
			"Mindestabstand für Plugins: Plugins in einer Zone halten jetzt immer mindestens 8 px zueinander - ein Abstand von 0 klebt sie nicht mehr zusammen. Der Plugin-Abstands-Regler beginnt bei 8.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"Initial release: Titan-style info bars at the top and bottom screen edge with LEFT / CENTER / RIGHT zones, right-click bar and plugin menus, shift+drag to move plugins between bars and zones, auto-hide, class-colored border, gloss and the secure Adjust-UI viewport.",
			"30 builtin plugins: clock, location/coords, performance, played, session, speed, volume, calendar events, tracking, vitals, XP, reputation, spec, item level, durability (vendor actions), ammo, soul shards, pet happiness, timed buffs, PvP rank, hearthstone, gold, bags, mail, friends, guild, quests, saved raids, auctions, profession cooldowns and kills - each with a proper tooltip and click/right-click actions.",
			"Kill statistics window: creature and NPC tracking with spawn points, drops, rare detection with toast+sound, NPC roles, quest book with texts and objectives, sidebar sections, name/zone/level/role filters, waypoints (TomTom or native), CSV export, notes and rare pins on the world map.",
			"Notification toasts for new mail, low durability, full bags and spotted rares. Slash: /suipanel (top|bottom|reset|kills [name]|wp <name>).",
		},
		changesDE = {
			"Erste Version: Infoleisten im Titan-Stil am oberen und unteren Bildschirmrand mit LINKS-/MITTE-/RECHTS-Zonen, Rechtsklick-Menüs für Leiste und Plugins, Verschieben per Shift+Ziehen zwischen Leisten und Zonen, Auto-Hide, klassenfarbiger Rahmen, Glanz und das sichere Adjust-UI-Viewport.",
			"30 eingebaute Plugins: Uhr, Ort/Koordinaten, Leistung, Spielzeit, Session, Tempo, Lautstärke, Kalender-Events, Tracking, Vitalwerte, EP, Ruf, Spezialisierung, Gegenstandsstufe, Haltbarkeit (Händler-Aktionen), Munition, Seelensplitter, Begleiterlaune, zeitliche Stärkungen, PvP-Rang, Ruhestein, Gold, Taschen, Post, Freunde, Gilde, Quests, ID-Speicherungen, Auktionen, Berufs-Cooldowns und Kills - jedes mit eigenem Tooltip und Klick-/Rechtsklick-Aktionen.",
			"Kill-Statistik-Fenster: Kreaturen- und NPC-Verfolgung mit Spawnpunkten, Drops, Rare-Erkennung mit Toast+Sound, NPC-Rollen, Questbuch mit Texten und Zielen, Seitenleisten-Bereiche, Name-/Zonen-/Stufen-/Rollen-Filter, Wegpunkte (TomTom oder nativ), CSV-Export, Notizen und Rare-Pins auf der Weltkarte.",
			"Benachrichtigungen für neue Post, niedrige Haltbarkeit, volle Taschen und gesichtete Rares. Slash: /suipanel (top|bottom|reset|kills [Name]|wp <Name>).",
		},
	},
}
