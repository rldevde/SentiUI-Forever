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
		version = "0.4.6",
		date = "2026-11-23",
		changes = {
			"The loss-of-control alert ('Stunned 1.3 sec') no longer shows the pixelated stock art: all of the game's textures are hidden and a same-size overlay in SentiUI style covers the frame - dark rounded panel, gold accent line, icon plus our font for the name and the live countdown. The game's frame still decides what to show; the texts are passed through untouched (secret-safe).",
		},
		changesDE = {
			"Die Kontrollverlust-Anzeige ('Bewegungsunfähig 1,3 Sek.') zeigt nicht mehr die pixelige Stock-Grafik: alle Spiel-Texturen werden ausgeblendet und ein gleich grosses Overlay im SentiUI-Stil deckt den Frame ab - dunkles abgerundetes Panel, Gold-Akzentlinie, Icon plus eigene Schrift für Name und laufenden Countdown. Der Spiel-Frame entscheidet weiterhin, was gezeigt wird; die Texte werden unangetastet durchgereicht (secret-sicher).",
		},
	},
	{
		version = "0.4.5",
		date = "2026-11-23",
		changes = {
			"Fixed 'forbidden call' + 'Interface action failed' at login: the useUiScale/uiScale CVars are forbidden to addons on this build, so S.ApplyGameScale no longer writes them - the scale now goes straight onto UIParent (combat-deferred, clamped 0.5-1.2). Affects the installer's scale step and the Interface settings slider.",
		},
		changesDE = {
			"'forbidden call' + 'Interface-Aktion fehlgeschlagen' beim Login behoben: die useUiScale/uiScale-CVars sind für Addons auf diesem Build verboten, S.ApplyGameScale schreibt sie nicht mehr - die Skalierung geht direkt auf UIParent (combat-deferred, auf 0,5-1,2 begrenzt). Betrifft den Scale-Schritt des Installers und den Interface-Slider in den Einstellungen.",
		},
	},
	{
		version = "0.4.4",
		date = "2026-11-23",
		changes = {
			"The 'update available' notice now prints in the client's system-message style (yellow, like deaths/rested notices) via the new S.PrintSystem helper instead of the normal addon prefix line.",
		},
		changesDE = {
			"Die 'Update verfügbar'-Meldung erscheint jetzt im Systemnachrichten-Stil des Clients (gelb, wie Todes-/Erholt-Meldungen) über den neuen S.PrintSystem-Helfer statt als normale Addon-Zeile.",
		},
	},
	{
		version = "0.4.3",
		date = "2026-11-23",
		changes = {
			"Outdated peers now get told: when a received manifest shows older or missing SentiUI modules, the peer is whispered an addon message with the modules to update (SUIver;n). Their client prints 'SentiUI update available: mod: old -> new' locally - the same fires on our side when a peer's suite is newer than ours. One notice per peer per session, no spam.",
		},
		changesDE = {
			"Veraltete Peers werden jetzt benachrichtigt: zeigt ein empfangenes Manifest ältere oder fehlende SentiUI-Module, bekommt der Peer eine Addon-Message mit den zu aktualisierenden Modulen geflüstert (SUIver;n). Sein Client zeigt lokal 'SentiUI-Update verfügbar: mod: alt -> neu' - dasselbe passiert bei uns, wenn ein Peer neuer ist. Eine Meldung pro Peer pro Sitzung, kein Spam.",
		},
	},
	{
		version = "0.4.2",
		date = "2026-11-23",
		changes = {
			"Comms version exchange is now fully automatic both ways: a query broadcasts every 30 min so peers re-send their manifests (peers who joined before us or whose announce we missed), and a JOINED notice triggers a jittered re-announce so newcomers learn our version even if their own query fails.",
		},
		changesDE = {
			"Der Comms-Versionsaustausch läuft jetzt in beide Richtungen vollautomatisch: alle 30 Min geht eine Abfrage an alle Peers (für Spieler, die vor uns beitraten oder deren Meldung wir verpasst haben), und ein JOINED-Notice löst eine zeitversetzte Neu-Meldung aus, damit Neulinge unsere Version auch ohne eigene erfolgreiche Abfrage erfahren.",
		},
	},
	{
		version = "0.4.1",
		date = "2026-11-23",
		changes = {
			"Comms log maps the raw channel notices YOU_CHANGED / NOT_MEMBER / WRONG_PASSWORD to readable localized text instead of showing the event token.",
		},
		changesDE = {
			"Das Comms-Log übersetzt die rohen Channel-Notices YOU_CHANGED / NOT_MEMBER / WRONG_PASSWORD in lesbaren lokalisierten Text statt dem Event-Token.",
		},
	},
	{
		version = "0.4.0",
		date = "2026-11-23",
		changes = {
			"New shared comms layer (S.Comms): the suite now joins a common \"SentiUI\" channel on login, rejoins automatically when lost and answers addon messages on the SUIv1 prefix.",
			"Version exchange: every client announces its full SentiUI suite manifest (all SentiUI_* addon versions) on join, re-answers queries and re-announces periodically - Comms.Peers() and Comms.PeerStatus() compare remote players against the local suite.",
			"Channel log: joins, leaves, kicks, bans and moderator changes are recorded (SentiUIDB.modules.Comms.log, kept across sessions) for the admin console to display.",
			"Modules can hook in via Comms.OnMessage / Comms.OnNotice / Comms.OnLog - channel work no longer has to be re-implemented per addon.",
		},
		changesDE = {
			"Neuer gemeinsamer Comms-Layer (S.Comms): die Suite tritt beim Login einem gemeinsamen \"SentiUI\"-Channel bei, tritt bei Verlust automatisch wieder bei und beantwortet Addon-Nachrichten auf dem SUIv1-Prefix.",
			"Versions-Austausch: jeder Client meldet beim Beitritt sein komplettes SentiUI-Manifest (alle SentiUI_*-Addon-Versionen), beantwortet Abfragen erneut und meldet sich regelmäßig neu - Comms.Peers() und Comms.PeerStatus() vergleichen andere Spieler mit der lokalen Suite.",
			"Channel-Log: Beitritte, Austritte, Kicks, Banns und Moderatoren-Wechsel werden aufgezeichnet (SentiUIDB.modules.Comms.log, sitzungsübergreifend) für die Admin-Konsole.",
			"Module können sich über Comms.OnMessage / Comms.OnNotice / Comms.OnLog einklinken - Channel-Arbeit muss nicht mehr pro Addon neu gebaut werden.",
		},
	},
	{
		version = "0.3.40",
		date = "2026-11-23",
		changes = {
			"Mover snap-back fix: dragged frames returned to their default position because rect reads (GetCenter/GetSize) answer secret inside the drag/keyboard hardware handlers on this client, so the save silently skipped. Saves now run one tick later where reads are plain, fall back to storing the raw UIParent anchor when the rect is still unreadable, and M.Save (window title drags) defers the same way.",
			"Protected frames can be moved now: when a frame refuses StartMoving (born under combat lockdown) the drag handle moves instead and the frame is parked on its drop spot.",
		},
		changesDE = {
			"Mover-Ruecksprung-Fix: gezogene Frames sprangen auf die Standardposition zurueck, weil Rect-Reads (GetCenter/GetSize) innerhalb der Drag-/Tastatur-Hardware-Handler auf diesem Client secret antworten und das Speichern still uebersprang. Saves laufen jetzt einen Tick spaeter wo die Reads normal sind, fallen im Notfall auf den rohen UIParent-Anker zurueck, und M.Save (Fenster-Titel-Drags) deferred genauso.",
			"Geschuetzte Frames sind jetzt verschiebbar: verweigert ein Frame StartMoving (unter Combat-Lockdown geboren), zieht stattdessen der Drag-Handle und der Frame wird auf dessen Zielposition geparkt.",
		},
	},
	{
		version = "0.3.39",
		date = "2026-11-22",
		changes = {
			"Design system overhaul: S.Template now gives 'raised'/'gold' panels a soft Sentinel gold border tint; PillReady re-enabled — when make_edges.py has been run, all panels get smooth rounded corners via the edgeFile backdrop instead of the pixelated raster arcs. S.SetBorderLit restores the saved border color on hover-off. S.TabChip shows a gold border when selected.",
		},
		changesDE = {
			"Design-System-Ueberarbeitung: S.Template gibt 'raised'/'gold'-Panels jetzt einen weichen Sentinel-Gold-Border-Tint; PillReady wieder aktiv — wenn make_edges.py ausgefuehrt wurde, bekommen alle Panels glatte Rundecken via edgeFile statt der pixeligen Raster-Boegen. S.SetBorderLit stellt die gespeicherte Randfarbe nach Hover wieder her. S.TabChip zeigt Gold-Rand wenn ausgewaehlt.",
		},
	},
	{
		version = "0.3.38",
		date = "2026-11-22",
		changes = {
			"Short-frame chevron fix: S.EdgeArc now clamps its radius to half the host height at build time - a radius taller than the frame made the top and bottom quarter arcs overlap into pointed brackets instead of a smooth pill end.",
		},
		changesDE = {
			"Chevron-Fix auf kurzen Frames: S.EdgeArc klemmt seinen Radius beim Bau jetzt auf die halbe Host-Hoehe - ein Radius groesser als die Frame-Hoehe liess obere und untere Viertelboegen zu spitzen Klammern ueberlappen statt zu einem runden Pill-Ende.",
		},
	},
	{
		version = "0.3.37",
		date = "2026-11-22",
		changes = {
			"Media pipeline disabled on request: S.Tex() returns nil and the pill-edge probe reports false, so EVERY consumer falls back to its code-drawn look - panels and tooltips get the programmatic rounded-9slice raster again, the gold window edge is strips+arcs, bars/glyphs/widgets use blank fills and native art. No generated texture is loaded anywhere; the Media\\Textures files stay on disk but unused.",
		},
		changesDE = {
			"Media-Pipeline auf Wunsch deaktiviert: S.Tex() liefert nil und die Pill-Edge-Probe meldet false, sodass JEDER Verbraucher auf seinen Code-Look zurueckfaellt - Panels und Tooltips bekommen wieder den programmierten Rundeck-Raster, der Gold-Fensterrand ist Streifen+Boegen, Balken/Glyphen/Widgets nutzen Blank-Fills und native Art. Keine generierte Textur wird mehr geladen; die Media\\Textures-Dateien bleiben auf der Platte, aber ungenutzt.",
		},
	},
	{
		version = "0.3.36",
		date = "2026-11-22",
		changes = {
			"Regenerated the edge-file media in-house (make_edges.py): the AI-delivered TGAs put a squashed full ring in slice 0, left the right/top/bottom edge slices EMPTY and drew diagonal brackets in the corner slices - which is exactly why edges rendered as a fat band on one side plus pink corner stubs. The new PillEdge, SquareEdge, TooltipEdge, GoldEdge, TargetRing, ThreatGlow and GlowEdge follow the real 8-slice spec (L,R,T,B + TL,TR,BL,BR corners), supersampled for true anti-aliased lines - every panel, tooltip, threat ring and target ring now gets a proper closed border.",
		},
		changesDE = {
			"Edge-File-Media selbst regeneriert (make_edges.py): die KI-TGAs hatten in Slice 0 einen gequetschten Gesamtring, liessen die rechte/obere/untere Seiten-Slices LEER und zeichneten diagonale Klammern in die Eck-Slices - genau darum renderten Kanten als fettes Band auf einer Seite plus pinke Eckstummel. Die neuen PillEdge-, SquareEdge-, TooltipEdge-, GoldEdge-, TargetRing-, ThreatGlow- und GlowEdge-Dateien folgen der echten 8-Slice-Spec (L,R,T,B + TL,TR,BL,BR-Ecken), supersampelt fuer echte Anti-Aliasing-Linien - jedes Panel, Tooltip, jeder Threat-Ring und Ziel-Ring bekommt jetzt eine sauber geschlossene Kontur.",
		},
	},
	{
		version = "0.3.35",
		date = "2026-11-22",
		changes = {
			"Own widgets ride the generated media: checkboxes use the CheckEmpty/CheckOn widget art (dark box, gold check) instead of an inset template + accent square, dropdowns show the DropdownArrow glyph instead of a text 'v', and slider thumbs carry the SliderThumb grip glyph.",
		},
		changesDE = {
			"Eigene Widgets nutzen die generierte Media: Checkboxen bekommen die CheckEmpty/CheckOn-Widget-Art (dunkle Box, goldener Haken) statt Inset-Template + Akzent-Quadrat, Dropdowns zeigen das DropdownArrow-Glyph statt eines Text-'v', und Slider-Thumbs tragen das SliderThumb-Griff-Glyph.",
		},
	},
	{
		version = "0.3.34",
		date = "2026-11-22",
		changes = {
			"Media wiring: new S.Tex(name) registry probes each shipped texture once via GetFileIDFromPath and returns the path only when the client resolves it - every consumer keeps a programmatic fallback. Tooltips now ride the TooltipEdge.tga edgeFile for a real border instead of the 1px flat edge.",
		},
		changesDE = {
			"Media-Verdrahtung: neue S.Tex(name)-Registry probt jede ausgelieferte Textur einmal ueber GetFileIDFromPath und gibt den Pfad nur zurueck, wenn der Client sie aufloest - jeder Verbraucher behaelt einen programmierten Fallback. Tooltips nutzen jetzt die TooltipEdge.tga-EdgeFile fuer eine echte Borduere statt der 1px-Flachkante.",
		},
	},
	{
		version = "0.3.33",
		date = "2026-11-22",
		changes = {
			"Full texture suite: make_media.py now generates all 88 SentiUI interface textures into Media/Textures/ - window/tooltip/glow/target edge files, panel fills, status-bar textures, control glyphs, icon/button frames, unit-frame overlays, role/dispel/status icons and suite furniture, as 32bpp TGAs with PNG previews and a contact sheet.",
		},
		changesDE = {
			"Komplette Textur-Suite: make_media.py erzeugt jetzt alle 88 SentiUI-Interface-Texturen in Media/Textures/ - Edge-Files fuer Fenster/Tooltip/Glow/Ziel, Panel-Fuellungen, Statusbar-Texturen, Control-Glyphen, Icon-/Button-Rahmen, Unit-Frame-Overlays, Rollen-/Dispel-/Status-Icons und Suite-Elemente, als 32bpp-TGAs mit PNG-Previews und Contact Sheet.",
		},
	},
	{
		version = "0.3.32",
		date = "2026-11-22",
		changes = {
			"Rounded-edge media pipeline: added make_media.py, which generates Media/Textures/PillEdge.tga - an 8-slice edgeFile with an anti-aliased quarter ring, a ~1px border and a dark inner band that doubles as a subtle inner shadow. Once generated, S.Template switches every panel, button, chip and skinned window from the programmed 1px-column raster to real texture borders with bilinear-smooth corners.",
		},
		changesDE = {
			"Rundkanten-Media-Pipeline: make_media.py erzeugt Media/Textures/PillEdge.tga - ein 8-Slice-EdgeFile mit geglattetem Viertelring, ~1px-Border und dunklem Innenband, das zugleich als dezenter Innenschatten wirkt. Nach dem Generieren schaltet S.Template alle Panels, Buttons, Chips und gestylten Fenster von der programmierten 1px-Spalten-Rasterung auf echte Textur-Bordueren mit bilinear glatten Ecken um.",
		},
	},
	{
		version = "0.3.31",
		date = "2026-11-22",
		changes = {
			"S.CornerCut gains a subLevel parameter: corner caps can now sit at OVERLAY sublevel 7, above regions created after the caps. Fixes a pixel artifact where the bar gloss overlay (created after the caps on unit frames) drew over them and poked a faint white tip into every rounded bar corner.",
		},
		changesDE = {
			"S.CornerCut bekommt einen subLevel-Parameter: die Eckkappen koennen jetzt auf OVERLAY-Sublevel 7 liegen, ueber Regionen, die nach den Kappen erzeugt werden. Behebt ein Pixel-Artefakt, bei dem der Gloss-Overlay (nach den Kappen auf den Unitframes erzeugt) ueber sie zeichnete und eine helle weisse Spitze in jede abgerundete Balkenecke ragte.",
		},
	},
	{
		version = "0.3.30",
		date = "2026-11-22",
		changes = {
			"Edge arc pixel fix: S.EdgeArc covered each column as [arc top minus local rise, arc top], which left a gap in the ring's lower half on steep columns and overfilled elsewhere - visible pixel errors on the gold window edge and the unit-frame edge glow. Columns now cover the true band between the inner circle (radius minus stroke width) and the outer arc, keeping a constant ring thickness.",
		},
		changesDE = {
			"Edge-Bogen-Pixelfix: S.EdgeArc deckte jede Spalte als [Bogenoben minus lokale Steigung, Bogenoben] ab - an steilen Stellen blieb die untere Haelfte des Rings unbedeckt und andere Stellen liefen ueber: sichtbare Pixelfehler am goldenen Fensterrand und am Edge-Glow der Unitframes. Die Spalten decken jetzt das echte Band zwischen innerem Kreis (Radius minus Strichstaerke) und aeusserem Bogen - gleichmaessige Ringstaerke.",
		},
	},
	{
		version = "0.3.29",
		date = "2026-11-22",
		changes = {
			"New core helper S.EdgeArc rasterizes a quarter-circle border segment (1px columns, any stroke thickness) - edge borders built from four straight strips (the gold window edge, the unit-frame edge glow) ended 7px before each corner and read as open stubs. The arcs close the outline into one continuous rounded frame.",
		},
		changesDE = {
			"Neuer Core-Helper S.EdgeArc rastert ein Viertelkreis-Rahmensegment (1px-Spalten, beliebige Strichstaerke) - Rahmen aus vier geraden Streifen (die goldene Fensterkante, der Edge-Glow der Unitframes) endeten 7px vor jeder Ecke und wirkten wie offene Stummel. Die Boegen schliessen die Kontur zu einem durchgehenden gerundeten Rahmen.",
		},
	},
	{
		version = "0.3.28",
		date = "2026-11-22",
		changes = {
			"WatchShown fix: a frame discovered already shown silently initialized its state instead of firing the transition, so the onShow callback never ran for the first-ever open - load-on-demand windows (auction house, collections, most modern panels) only got their skins from the second open on. The first observed shown-state now fires the callback; skins are idempotent so the extra run is safe.",
		},
		changesDE = {
			"WatchShown-Fix: Ein bereits sichtbar entdeckter Frame initialisierte seinen Zustand still, statt den Uebergang zu feuern - der onShow-Callback lief beim allerersten Oeffnen nie, also bekamen Load-on-Demand-Fenster (Auktionshaus, Sammlungen, die meisten modernen Panels) ihren Skin erst ab dem zweiten Oeffnen. Der erste beobachtete sichtbare Zustand feuert den Callback jetzt; Skins sind idempotent, der zusaetzliche Lauf ist sicher.",
		},
	},
	{
		version = "0.3.27",
		date = "2026-11-22",
		changes = {
			"Anti-aliased rounded corners: every S.Roundize corner column now carries a 1px sliver at the arc boundary whose alpha is the fractional coverage - the hard 1px staircase becomes a smooth, evenly rasterized curve. Panels, buttons, chips and every skinned Blizzard window get visibly softer corners, still fully programmed with no media files.",
			"New S.CornerCut helper: raster caps in the color of the surface behind a region cover the corner notch outside a quarter disc - the Roundize arc math inverted, with the same AA slivers. Makes any bar or icon read as a rounded rect; used for status bars and icon rounding.",
			"S.IconRound now delegates to S.CornerCut: icon corner caps get the anti-aliased edges too (portrait tiles, aura icons, action slots, roll cards).",
		},
		changesDE = {
			"Anti-Aliased-Eckrundungen: Jede S.Roundize-Eckspalte traegt jetzt einen 1px-Sliver an der Bogengrenze, dessen Alpha die Restabdeckung ist - die harte 1px-Treppe wird eine weiche, gleichmaessig gerasterte Kurve. Panels, Buttons, Chips und jedes gestylte Blizzard-Fenster bekommen sichtbar weichere Ecken, weiterhin komplett programmiert ohne Mediendateien.",
			"Neuer S.CornerCut-Helper: Raster-Kappen in der Farbe der Flaeche hinter einer Region decken die Eckkerbe ausserhalb einer Viertelscheibe ab - die Roundize-Bogenmathematik invertiert, mit denselben AA-Slivers. Jede Leiste oder jedes Icon wirkt damit als abgerundetes Rechteck; genutzt fuer Statusleisten und Icon-Rundung.",
			"S.IconRound delegiert jetzt an S.CornerCut: Icon-Eckkappen bekommen ebenfalls die geglätteten Kanten (Portraet-Kacheln, Auren-Icons, Aktions-Slots, Wuerfel-Karten).",
		},
	},
	{
		version = "0.3.26",
		date = "2026-11-22",
		changes = {
			"TabChip fix: the label's RIGHT anchor clamped GetStringWidth() to the chip's current width (0 on a new chip), so every chip sized to 22px and rendered as a featureless dark square without text. Removed the anchor — all chip tabs (Character, BugSack, Training, Journal, Blacklist, AccountInfo) now size to their caption.",
			"S.Roundize rewritten: corner arcs are rasterized in pure code as 1px columns (h(i) = sqrt(r² - (r-i-.5)²)) from WHITE8X8 — no external mask file can turn rounded corners into dark boxes. Tinting runs through one flat f.roundPieces list.",
			"Corner strip anchor fix: WoW y-offsets run UP, not DOWN — the arc strips were parked outside the frame, drawing a floating dark nub at every corner of every panel and button (the 'four corner points' bug). They now sit inside the corner tile hugging the arc.",
			"Edge decorations inset: the installer top accent edge and the move-mode edit bar edge line now end on the straight edge (7px inset) instead of poking past the rounded corners.",
			"S.IconRound rewritten AGAIN — the MaskTexture approach rendered its oversized white circle as a visible blob at every icon corner on this client (the 'white corners' bug). Icon rounding now uses tiny raster caps in the slot's background color covering only the outer corner notch (the Roundize arc math inverted) — no mask, no file, and a missing cap can never paint a visible artifact.",
			"S.IconRound relayout hook fixed: OnSizeChanged is not a supported script type on Texture objects (HookScript threw 'script type not supported' for every action slot, bag slot, cast bar and unit frame icon). The relayout now hooks the icon's host frame inside pcall.",
			"S.IconRound secret-dimension guard: aura-container icons report secret width/height — comparing them threw inside Blizzard's frame-creation dispatch. Secret dimensions now leave the icon square instead of comparing.",
			"Sentinel tooltip skin: GameTooltip, ItemRefTooltip, shopping and comparison tooltips get the dark background, 1px border and a gold accent line at the top. Applied at PLAYER_LOGIN via S.StyleTooltips.",
		},
		changesDE = {
			"TabChip-Fix: Der RIGHT-Anker des Labels klemmte GetStringWidth() auf die aktuelle Chip-Breite (0 bei neuen Chips), sodass jeder Chip 22px gross wurde und als dunkles Quadrat ohne Text renderte. Anker entfernt — alle Chip-Tabs (Charakter, BugSack, Training, Journal, Blacklist, AccountInfo) passen sich jetzt ihrer Beschriftung an.",
			"S.Roundize neu geschrieben: Eckenboegen werden jetzt rein im Code als 1px-Spalten gerastert (h(i) = sqrt(r² - (r-i-.5)²)) aus WHITE8X8 — keine externe Maskendatei kann abgerundete Ecken mehr in dunkle Kästchen verwandeln. Faerbung laeuft ueber eine flache f.roundPieces-Liste.",
			"Ecken-Streifen-Anker-Fix: WoW-Y-Offsets laufen nach OBEN, nicht nach UNTEN — die Bogen-Streifen parkten ausserhalb des Frames und malten an jeder Ecke jedes Panels und Buttons einen schwebenden dunklen Nub (der 'vier Eck-Punkte'-Fehler). Sie sitzen jetzt innerhalb der Eckkachel am Bogen.",
			"Kanten-Dekor eingesetzt: die obere Akzentkante des Installers und die Kantenlinie der Verschiebe-Leiste enden jetzt an der geraden Kante (7px eingesetzt) statt ueber die abgerundeten Ecken hinauszuragen.",
			"S.IconRound NOCHMAL neu geschrieben — die MaskTexture renderte ihre uebergrosse weisse Kreistextur als sichtbaren Blob an jeder Icon-Ecke (der 'weisse Ecken'-Fehler). Icon-Rundung nutzt jetzt winzige Raster-Kappen in Slot-Hintergrundfarbe, die nur die aeussere Eckkerbe abdecken (die Roundize-Bogen-Mathematik invertiert) — keine Maske, keine Datei, und eine fehlende Kappe kann nie ein sichtbares Artefakt malen.",
			"S.IconRound-Relayout-Hook gefixt: OnSizeChanged ist kein unterstuetzter Script-Typ auf Texture-Objekten (HookScript warf 'script type not supported' fuer jeden Action-Slot, Bag-Slot, Zauberleisten- und Unitframe-Icon). Das Relayout hookt jetzt den Host-Frame des Icons innerhalb von pcall.",
			"S.IconRound-Secret-Mass-Guard: Aura-Container-Icons liefern Secret-Breite/-Hoehe — der Vergleich warf mitten in Blizzards Frame-Erzeugungs-Dispatch. Secret-Maesse lassen das Icon jetzt eckig statt zu vergleichen.",
			"Sentinel-Tooltip-Skin: GameTooltip, ItemRefTooltip, Shopping- und Vergleichs-Tooltips bekommen dunklen Hintergrund, 1px-Rahmen und eine goldene Akzentlinie oben. Wird bei PLAYER_LOGIN ueber S.StyleTooltips angewendet.",
		},
	},
	{
		version = "0.3.25",
		date = "2026-11-22",
		changes = {
			"New S.IconRound helper: places background-colored arc pieces over an icon's square corners using CircleMask.tga with inverse UV mapping relative to S.Roundize. The opaque circle center maps to the outer tile corner (covering the icon's square corner) and the transparent circle exterior maps to the inner tile corner (showing the icon body). Used by ActionBars, Bags and Loot roll cards for consistent soft icon corners without any external media.",
		},
		changesDE = {
			"Neuer S.IconRound-Helfer: Legt hintergrundfarbige Bogenstücke über die eckigen Icon-Ecken unter Verwendung von CircleMask.tga mit inverser UV-Abbildung relativ zu S.Roundize. Das opake Kreiszentrum mappt zur äußeren Kachel-Ecke (überdeckt die eckige Icon-Ecke) und das transparente Kreisäußere mappt zur inneren Kachel-Ecke (zeigt den Icon-Körper). Verwendet von ActionBars, Bags und Loot-Roll-Karten für konsistente weiche Icon-Ecken ohne externe Medien.",
		},
	},
	{
		version = "0.3.24",
		date = "2026-11-22",
		changes = {
			"S.Roundize UV fix: corner tiles now map correctly — outer corners land outside the circle (transparent) and inner corners land at the circle center (filled), producing true quarter-circle arcs. All chips and tabs are visually rounded on /reload.",
			"S.Template now uses the Roundize 9-slice as default when PillEdge media is absent: every frame, button, input box and panel gets rounded corners without any external files. The PillEdge backdrop path is preserved for the future.",
			"S.SetBorderLit updated for Roundize frames: corner arcs glow to the accent color on hover and the fill brightens; on leave they restore to the base. Backdrop-border frames keep the existing SetBackdropBorderColor path.",
			"Settings cards now carry a subtle 1px gold accent line along their top edge for clearer section delineation.",
		},
		changesDE = {
			"S.Roundize UV-Fix: Ecken-Kacheln werden jetzt korrekt gemappt — äussere Ecken landen ausserhalb des Kreises (transparent) und innere Ecken im Kreiszentrum (ausgefüllt), das ergibt echte Viertelkreis-Boegen. Alle Chips und Tabs sind sofort nach /reload visuell abgerundet.",
			"S.Template nutzt jetzt standardmaessig den Roundize-9-Slice wenn das PillEdge-Medium fehlt: Jeder Frame, Button, Eingabefeld und Panel bekommt abgerundete Ecken ohne externe Dateien. Der PillEdge-Backdrop-Pfad bleibt fuer die Zukunft erhalten.",
			"S.SetBorderLit fuer Roundize-Frames aktualisiert: Ecken-Boegen leuchten bei Hover in der Akzentfarbe auf und das Fill wird heller; beim Verlassen kehren sie zur Basis zurück. Backdrop-Border-Frames behalten den vorhandenen SetBackdropBorderColor-Pfad.",
			"Einstellungs-Karten haben jetzt eine dezente 1px-Goldakzent-Linie an ihrer Oberkante fuer klarere Abschnittstrennung.",
		},
	},
	{
		version = "0.3.23",
		date = "2026-11-22",
		changes = {
			"Installer finish did not reload: the secure /reload overlay was built once at frame creation - if the installer first opened during combat it stayed missing forever. It is now built lazily when the finish step shows.",
			"SecureReload carries no addon scripts at all now: a PostClick set via SetScript could taint the click dispatch just like the old OnClick override did.",
			"The installer's game UI scale choice now persists: this client does not write the uiScale CVar to config-cache.wtf, so a plain SetCVar was gone after relog. The value is kept in SentiUIDB.general.gameScale and re-applied on every login.",
			"Settings resetting every login: the client loads SavedVariables too late unless told otherwise - modules enabled at PLAYER_LOGIN got fresh default tables and every options write went into them. All TOCs with SavedVariables now declare LoadSavedVariablesFirst: 1 (SentiUI, Panel, Training, Journal, Nameplates).",
			"Escape-close windows no longer throw ADDON_ACTION_FORBIDDEN in combat: SetPropagateKeyboardInput is restricted during a fight on this client, so S.EscClosable and the mover arrow keys now guard the call. The keyboard only goes live once propagation actually took, and propagation resets on key-up/hide.",
			"The installer now persists the UI scale even when the slider is never touched: the current scale is stored at the scale step, so any completed run keeps the choice across relogs.",
			"The finish page has a real visible secure button now: the old invisible overlay ate the pointer (no hover feedback) and a combat-time build failure left a silent no-reload finish. Next is swapped for the secure button on the last step, the combat fallback keeps working.",
			"Modules can add installer steps: new SentiUI.Installer.AddModuleStep places them before the finish page.",
			"The finish button never fired its /reload: without the useOnKeyDown=false attribute the secure dispatch follows the key-down CVar and ignores the Up click. The button now registers both click phases, carries the attribute and is built the proven DaylightUI way - parented to UIParent, laid over Next on show. Installer step build errors are printed to chat instead of showing as an empty step.",
			"The installer pages are interactive now, ElvUI-style: the Modules step is a scrollable checklist that enables/disables every loaded module (applied with the finish reload), and the controls step carries buttons for move mode and the settings window.",
			"Module installer steps no longer cache a failed build: a step whose module was not ready yet showed up empty forever. Nil builds are retried on the next visit and the reason is printed to chat; the chat and minimap steps drop their enabled-guard entirely.",
			"The game UI scale is now a real setting: new 'Game UI scale' slider under SentiUI > Interface, sharing S.ApplyGameScale with the installer's scale step (CVar + general.gameScale, re-applied on every login). Before, the game scale existed only inside the installer.",
			"Installer buttons no longer overlap: Back is anchored to Next's left edge instead of a fixed offset, and Next/Finish are wide enough for the localized 'Finish & reload' label.",
			"New shared design language for small tabs and filter chips: S.TabChip builds a dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active tab. Adopted by the character window tabs, the BugSack view tabs and the filter chips of Training, Journal and the blacklist window - one system instead of scattered boxes.",
			"Soft rounded corners for every tab and filter chip - fully programmed, zero setup: S.Roundize assembles the chip body from nine texture pieces (four quarter-disc corners cut from the circle mask the minimap module ships, five straight WHITE8X8 pieces) instead of a backdrop fill - an overlay disc can never cut a square fill away, so the fill IS the nine pieces now. Chips round immediately on /reload; panels keep the flat look until the PillEdge media exists ('Media erzeugen (doppelklicken).bat' in SentinelUI-Tools).",
			"The media script's target folder is created on the fly (it crashed on the missing Media\\Textures directory before) and the media path points at the _forever_ SentiUI tree now.",
			"Neue gemeinsame Designsprache fuer kleine Tabs und Filter-Chips: S.TabChip baut einen dunklen Inset-Koerper mit 2px Akzent-Klinge an der linken Kante, der bei Hover glimmt und auf dem aktiven Tab brennt. Übernommen von den Charakterfenster-Tabs, den BugSack-Ansicht-Tabs und den Filter-Chips von Training, Journal und dem Blacklist-Fenster - ein System statt verstreuter Kaestchen.",
			"Weiche abgerundete Ecken fuer jeden Tab und Filter-Chip - komplett programmiert, ganz ohne Setup: S.Roundize baut den Chip-Koerper aus neun Textur-Stuecken (vier Viertelkreis-Ecken aus der Kreis-Maske des Minimap-Moduls, fuenf gerade WHITE8X8-Stuecke) statt eines Backdrop-Fills - eine Overlay-Scheibe kann ein quadratisches Fill nie ausschneiden, daher IST der Fill jetzt die neun Stuecke. Die Chips runden sofort per /reload; Panels bleiben flach, bis das PillEdge-Medium existiert ('Media erzeugen (doppelklicken).bat' in SentinelUI-Tools).",
			"Der Zielordner des Medien-Skripts wird jetzt angelegt (vorher crashte es am fehlenden Media\\Textures-Verzeichnis) und der Medien-Pfad zeigt auf den _forever_-SentiUI-Baum.",
		},
		changesDE = {
			"Der Fertig-Schritt des Installers lud nicht neu: das gesicherte /reload-Overlay wurde einmal beim Fensterbau erstellt - bei einem ersten Öffnen im Kampf fehlte es dauerhaft. Es wird jetzt gebaut, wenn der Fertig-Schritt erscheint.",
			"SecureReload trägt jetzt gar keine Addon-Skripte mehr: ein per SetScript gesetzter PostClick konnte den Klick-Dispatch genauso kontaminieren wie der alte OnClick-Override.",
			"Die UI-Skalierung aus dem Installer bleibt jetzt erhalten: dieser Client schreibt den uiScale-CVar nicht in die config-cache.wtf - ein einfaches SetCVar war nach dem Relog weg. Der Wert liegt in SentiUIDB.general.gameScale und wird bei jedem Login neu angewendet.",
			"Einstellungen, die sich bei jedem Login zurücksetzten: der Client lädt SavedVariables zu spät, wenn man es ihm nicht sagt - Module bekamen beim PLAYER_LOGIN frische Defaults-Tabellen und jeder Options-Schreibzugriff ging in die. Alle TOCs mit SavedVariables deklarieren jetzt LoadSavedVariablesFirst: 1 (SentiUI, Panel, Training, Journal, Nameplates).",
			"Escape-Fenster werfen im Kampf kein ADDON_ACTION_FORBIDDEN mehr: SetPropagateKeyboardInput ist auf diesem Client waehrend des Kampfes gesperrt, daher wird der Aufruf in S.EscClosable und den Mover-Pfeiltasten jetzt geschuetzt. Die Tastatur wird erst aktiv, wenn Propagation wirklich gesetzt ist, und wird bei Key-Up/Verstecken zurueckgesetzt.",
			"Der Installer speichert die UI-Skalierung jetzt auch, wenn der Slider nie beruehrt wird: der aktuelle Scale wird beim Scale-Schritt gesichert, damit jeder abgeschlossene Durchlauf die Wahl ueber Relogs hinweg haelt.",
			"Die Fertig-Seite hat jetzt einen echten sichtbaren Secure-Button: das alte unsichtbare Overlay fraß den Zeiger (kein Hover-Feedback) und ein Fehler beim Bauen im Kampf liess einen stillen Abschluss ohne Neuladen zurueck. Auf dem letzten Schritt wechselt Next auf den Secure-Button, der Kampf-Fallback bleibt.",
			"Module koennen Installer-Schritte ergaenzen: neues SentiUI.Installer.AddModuleStep platziert sie vor der Fertig-Seite.",
			"Der Fertig-Button loeste sein /reload nie aus: ohne das useOnKeyDown=false-Attribut folgt der Secure-Dispatch dem Key-Down-CVar und ignoriert den Up-Klick. Der Button registriert jetzt beide Klick-Phasen, traegt das Attribut und wird nach dem bewaehrten DaylightUI-Muster gebaut - an UIParent gehaengt, beim Anzeigen ueber Next gelegt. Fehler beim Bauen von Installer-Schritten werden im Chat ausgegeben statt als mysterioes leerer Schritt zu erscheinen.",
			"Die Installer-Seiten sind jetzt interaktiv, im ElvUI-Stil: der Module-Schritt ist eine scrollbare Checkliste, die jedes geladene Modul ein-/ausschaltet (angewendet mit dem Neuladen am Ende), und der Steuerungs-Schritt hat Buttons fuer Verschiebemodus und Einstellungsfenster.",
			"Installer-Schritte von Modulen cachen einen fehlgeschlagenen Build nicht mehr: ein Schritt, dessen Modul noch nicht bereit war, blieb fuer immer leer. Nil-Builds werden beim naechsten Besuch wiederholt und der Grund wird im Chat ausgegeben; der Chat- und Minimap-Schritt verzichten ganz auf ihren Enabled-Guard.",
			"Die Spiel-UI-Skalierung ist jetzt eine echte Einstellung: neuer 'Spiel-UI-Skalierung'-Slider unter SentiUI > Interface, teilt S.ApplyGameScale mit dem Scale-Schritt des Installers (CVar + general.gameScale, bei jedem Login neu angewendet). Vorher gab es die Spiel-Skalierung nur im Installer.",
			"Die Installer-Buttons ueberlappen nicht mehr: Zurueck hängt an der linken Kante von Weiter statt an einem festen Versatz, und Weiter/Fertig sind breit genug fuer das lokalisierte 'Fertig & neu laden'.",
		},
	},
	{
		version = "0.3.22",
		date = "2026-11-22",
		changes = {
			"Secure button clicks were still tainted: SetScript('OnClick') replaced the template's own secure handler, flagging RunMacroText as FORBIDDEN. The template handler now runs untouched everywhere (reload overlay, minimap submenu, panel overlays, talent pill).",
		},
		changesDE = {
			"Gesicherte Button-Klicks waren weiterhin kontaminiert: SetScript('OnClick') ersetzte den eigenen sicheren Handler des Templates, RunMacroText wurde als FORBIDDEN gemeldet. Der Template-Handler läuft jetzt überall unangetastet (Reload-Overlay, Minimap-Untermenü, Panel-Overlays, Talent-Pill).",
		},
	},
	{
		version = "0.3.21",
		date = "2026-11-22",
		changes = {
			"Reload fix everywhere: C_UI.Reload/ReloadUI is a protected call on this client (ADDON_ACTION_BLOCKED: Reload()). New S.SecureReload helper lays an invisible SecureActionButton running the secure /reload macro over the real button - used by the installer's Finish step, the options 'Reload the interface' button, the options reload-confirm dialog (secureAccept) and the minimap menu's Reload entry.",
		},
		changesDE = {
			"Reload-Fix ueberall: C_UI.Reload/ReloadUI ist auf diesem Client ein geschuetzter Aufruf (ADDON_ACTION_BLOCKED: Reload()). Neuer S.SecureReload-Helfer legt einen unsichtbaren SecureActionButton mit dem gesicherten /reload-Makro ueber den echten Button - genutzt vom Fertig-Schritt des Installers, dem 'Interface neu laden'-Knopf in den Optionen, dem Neuladen-Bestaetigungsdialog (secureAccept) und dem Reload-Eintrag im Minimap-Menue.",
		},
	},
	{
		version = "0.3.20",
		date = "2026-11-22",
		changes = {
			"Installer rework: the wizard has an interactive step area now. New 'Interface scale' step with a live slider and a Recommended button that picks the scale matching your resolution; the last step's Finish button reloads the UI (C_UI.Reload) so every setting takes effect cleanly.",
		},
		changesDE = {
			"Installer-Ueberarbeitung: der Assistent hat jetzt einen interaktiven Schrittbereich. Neuer Schritt 'Interface-Skalierung' mit Live-Schieberegler und Empfohlen-Knopf, der die zur Aufloesung passende Skalierung waehlt; der Fertig-Knopf des letzten Schritts laedt das UI neu (C_UI.Reload), damit alle Einstellungen sauber greifen.",
		},
	},
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
