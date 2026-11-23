-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.3.60",
		changes = {
			"Loss-of-control banner (stun/root/silence) gets a dedicated skin: Blizzard blackBg and red line art removed outright, icon docked to the left edge at bar height (was overlapping the ability text), SentiUI panel + gold edge, restyled fonts.",
		},
		changesDE = {
			"Kontrollverlust-Banner (Betäubung/Wurzel/Stille) bekommt einen eigenen Skin: Blizzard-blackBg und rote Linien komplett entfernt, Icon links am Rand in Leistenhöhe angedockt (ueberlappte vorher den Faehigkeits-Text), SentiUI-Panel + Goldkante, Schriften restylt.",
		},
	},
	{
		version = "0.3.59",
		changes = {
			"Fixed Lua ordering error: SKINS.MirrorTimerContainer called the local SweepStart function before its definition line, so it resolved nil and errored on load - the mirror timer skin never ran. The proxy + skin are now defined after SweepStart.",
		},
		changesDE = {
			"Lua-Reihenfolge-Fehler behoben: SKINS.MirrorTimerContainer rief die lokale SweepStart-Funktion vor ihrer Definitionszeile auf, loeste nil aus und warf beim Laden einen Fehler - der Mirror-Timer-Skin lief nie. Proxy + Skin sind jetzt nach SweepStart definiert.",
		},
	},
	{
		version = "0.3.58",
		changes = {
			"Mirror timer bars (breath, fatigue, feign death) now get the SentiUI skin properly: the StatusBar fill widget lives on a child inside MirrorTimerN on this client and was never found - now resolved correctly and filled flat gold. Wooden border texture killed outright instead of dimmed to 15%.",
		},
		changesDE = {
			"Mirror-Timer-Leisten (Atem, Erschoepfung, Totstellen) bekommen jetzt den SentiUI-Skin: das StatusBar-Fuell-Widget liegt auf diesem Client in einem Kind von MirrorTimerN und wurde nie gefunden - jetzt korrekt aufgeloest und flach in Gold gefaerbt. Holzrahmen-Textur wird komplett entfernt statt auf 15% gedimmt.",
		},
	},
	{
		version = "0.3.57",
		date = "2026-11-23",
		changes = {
			"Breath/fatigue bars (MirrorTimer) get the SentiUI skin now: they spawn lazily on first use on this client, so the one-time MirrorTimer1-3 loop found nothing. A lazy sweep now catches every new bar (container children + MirrorTimer1-10 globals) with flat fill, dark panel, gold edge and SentiUI font.",
		},
		changesDE = {
			"Atem-/Erschoepfungsbalken (MirrorTimer) bekommen jetzt den SentiUI-Skin: Sie spawnen auf diesem Client erst bei Bedarf, darum fand die einmalige MirrorTimer1-3-Schleife nichts. Ein Lazy-Sweep faengt jetzt jeden neuen Balken ab (Container-Kinder + MirrorTimer1-10-Globals) mit flacher Fuellung, dunklem Panel, Goldrand und SentiUI-Schrift.",
		},
	},
	{
		version = "0.3.56",
		date = "2026-11-23",
		changes = {
			"Cooldowns surviving a reload: PEW repaints all buttons but action data is often unreadable then, and already-running cooldowns fire no more events - long cooldowns stayed unpainted. PEW now schedules delayed cooldown sweeps at +0.5s/+1.5s/+3s so restored cooldowns get swipe and numbers back.",
		},
		changesDE = {
			"Cooldowns ueberleben jetzt einen Reload: PEW malt zwar alle Buttons neu, aber die Aktionsdaten sind dann oft noch nicht lesbar und bereits laufende Cooldowns feuern keine Events mehr - lange Cooldowns blieben ungemalt. PEW plant jetzt verzoegerte Cooldown-Sweeps nach +0.5s/+1.5s/+3s, damit wiederhergestellte Cooldowns Swipe und Zahlen zurueckbekommen.",
		},
	},
	{
		version = "0.3.55",
		date = "2026-11-23",
		changes = {
			"Cooldown numbers readable now: the countdown font was plain white (GameFontHighlightSmall) - invisible over bright icons. Now SystemFont_Outline_Small with a dark outline, like Blizzard's own digits.",
		},
		changesDE = {
			"Cooldown-Zahlen jetzt lesbar: die Countdown-Font war einfach weiss (GameFontHighlightSmall) - ueber hellen Icons unsichtbar. Jetzt SystemFont_Outline_Small mit dunkler Kontur, wie Blizzards eigene Ziffern.",
		},
	},
	{
		version = "0.3.54",
		date = "2026-11-23",
		changes = {
			"NPC/quest/gossip dialog text stays near-black like the parchment originals instead of being lifted to bright text - readability on the dark panel now comes from a tiny 1px white shadow rim bottom-right that does not glare.",
		},
		changesDE = {
			"NPC-/Quest-/Gossip-Texte bleiben jetzt fast schwarz wie die Pergament-Originale statt aufgehellt - die Lesbarkeit auf dem dunklen Panel kommt von einer winzigen 1px weissen Schattenkante unten-rechts, die nicht in den Augen sticht.",
		},
	},
	{
		version = "0.3.53",
		date = "2026-11-23",
		changes = {
			"Cooldown numbers on action buttons: the template cooldown hid its countdown digits on this client (only the swipe showed). Buttons now unhide countdown numbers and get GameFontHighlightSmall via SetCountdownFont. Charge/loss-of-control cooldowns are picked up from the template too - they were never assigned, so those swipes never painted.",
		},
		changesDE = {
			"Cooldown-Zahlen auf Aktionsbuttons: das Template-Cooldown hat die Countdown-Ziffern auf diesem Client versteckt (nur der Swipe lief). Buttons zeigen jetzt Countdown-Zahlen mit GameFontHighlightSmall ueber SetCountdownFont. Charge-/Kontrollverlust-Cooldowns werden jetzt auch vom Template uebernommen - sie wurden nie zugewiesen, diese Swipes liefen nie.",
		},
	},
	{
		version = "0.3.52",
		date = "2026-11-23",
		changes = {
			"Action bar frame: replaced the 4 thin gold edge strips with S.Template(holder, panel) - the holder now gets a proper dark panel backdrop with accent-tinted border flush behind the button grid instead of a thin disconnected line at the outer edge.",
		},
		changesDE = {
			"Aktionsleisten-Rahmen: die 4 duennen Goldkanten durch S.Template(holder, panel) ersetzt - der Holder bekommt jetzt ein richtiges dunkles Panel mit akzentfarbenem Rand bündig hinter dem Button-Raster statt einer duennen frei schwebenden Linie am Aussenrand.",
		},
	},
	{
		version = "0.3.51",
		date = "2026-11-23",
		changes = {
			"Mail compose window: SkinMail finds the body ScrollFrame (MailBody, MailScroll*, or any ScrollFrame with an EditBox child) and applies dark inset fill to the whole message area - not just the thin EditBox inside. Parchment is faded: no more black bar on orange paper.",
			"SkinQuestDialog moved after SkinDialog in file order - Lua local functions must be declared before use; original order caused nil call on QuestFrame and GossipFrame.",
		},
		changesDE = {
			"Post-Fenster: SkinMail findet das Textfeld-ScrollFrame (MailBody, MailScroll* oder ScrollFrame mit EditBox-Kind) und legt dunklen inset-Fuellung auf das ganze Nachrichtenfeld - nicht nur die duenne EditBox. Pergament wird ausgeblendet: kein schwarzer Balken auf orangem Papier mehr.",
			"SkinQuestDialog nach SkinDialog in der Datei verschoben - Lua lokale Funktionen muessen vor Verwendung definiert sein; die Reihenfolge verursachte nil-Aufruf auf QuestFrame und GossipFrame.",
		},
	},
	{
		version = "0.3.50",
		date = "2026-11-23",
		changes = {
			"Quest/NPC dialog font fix: removed OUTLINE flag from RestyleFonts. The thick black stroke produced a heavy border around all white text on the dark panel; quest/gossip fonts carry their own shadow and read cleanly without it.",
			"Quest/Gossip frame structure: SkinQuestDialog adds a subtle gold divider (28% alpha, 1px) below the NPC greeting area at y=-55, giving the frame a titled section structure instead of floating text.",
			"Action bar gold border: four 1px gold strips on the bar holder BORDER layer (below buttons) frame every bar in Sentinel gold at 55% alpha.",
			"Action bar bottom offset raised from 10px to 16px.",
			"Action bar button icon inset 1px->3px: icons were bleeding into the PillEdge backdrop corner arc and appearing cut off.",
		},
		changesDE = {
			"Quest-/NPC-Dialog-Font-Fix: OUTLINE-Flag aus RestyleFonts entfernt. Der dicke schwarze Strich erzeugte einen schweren Rand um allen weissen Text auf dem dunklen Panel; Quest-/Gossip-Fonts tragen ihren eigenen Schatten und lesen sauber ohne.",
			"Quest-/Gossip-Frame-Struktur: SkinQuestDialog fuegt eine feine Gold-Linie (28% Alpha, 1px) unter dem NPC-Begruessungsbereich bei y=-55 ein, dem Frame eine benannte Abschnittsstruktur statt frei schwebendem Text.",
			"Aktionsleisten-Goldrand: vier 1px Goldstreifen auf der Halter-BORDER-Ebene (unter Buttons) rahmen jede Leiste in Sentinel-Gold bei 55% Alpha.",
			"Aktionsleisten-Bodenabstand von 10px auf 16px erhoeht.",
			"Aktionsleisten-Button-Icon-Inset 1px->3px: Icons bluteten in die PillEdge-Backdrop-Ecke und erschienen abgeschnitten.",
		},
	},
	{
		version = "0.3.49",
		date = "2026-11-23",
		changes = {
			"Cooldown fix: complete rewrite of PaintCooldown/sweep. Root cause: isActive, startTime and duration are secret/tainted; any Lua comparison throws under addon taint and aborts the painter. Even catching the throw and treating it as 'not active' was wrong - it caused sweep to explicitly Clear() all running cooldowns. Fix: isActive is never read; the raw info table is passed directly to CooldownFrame_Set (Blizzard C++, handles secrets internally). C++ decides show/hide from duration. Fallback chain: SetCooldownFromDurationObject > CooldownFrame_Set > cd:SetCooldown.",
		},
		changesDE = {
			"Cooldown-Fix: vollständige Neufassung von PaintCooldown/sweep. Ursache: isActive, startTime und duration sind secret/tainted; jeder Lua-Vergleich wirft unter Addon-Taint und bricht den Painter ab. Sogar den Throw abzufangen und als 'nicht aktiv' zu behandeln war falsch - es führte dazu, dass sweep alle laufenden Cooldowns explizit Clear()te. Fix: isActive wird nie gelesen; die rohe info-Tabelle wird direkt an CooldownFrame_Set (Blizzard-C++, behandelt Geheimnisse intern) übergeben. C++ entscheidet anhand von duration über Anzeige/Ausblendung. Fallback: SetCooldownFromDurationObject > CooldownFrame_Set > cd:SetCooldown.",
		},
	},
	{
		version = "0.3.48",
		date = "2026-11-23",
		changes = {
			"Dark text fix: luminance threshold in RestyleFonts raised from 0.35 to 0.52 - catches the parchment mid-tones WoW's QuestFont/GossipFont objects use (~0.40-0.50 luminance) which slipped through and appeared black on the dark panel.",
		},
		changesDE = {
			"Schwarze-Text-Fix: Luminanz-Schwellwert in RestyleFonts von 0,35 auf 0,52 angehoben - erfasst jetzt die Pergament-Mitteltöne von WoW's QuestFont/GossipFont (~0,40-0,50 Luminanz), die bisher durchfielen und schwarz auf dem dunklen Panel erschienen.",
		},
	},
	{
		version = "0.3.47",
		date = "2026-11-22",
		changes = {
			"Design system: Blizzard windows (SkinPanelish) now get dark fill via 'raised' template for a consistent gold border tint, plus four clean corner-to-corner gold strips (no arc offsets, no EdgeArc arcs that left gaps). Action buttons get a gold 1px ring overlay shown on hover and while a spell is toggled active.",
		},
		changesDE = {
			"Design-System: Blizzard-Fenster (SkinPanelish) erhalten jetzt dunkle Fuellung via 'raised'-Template fuer einen einheitlichen Gold-Border-Tint sowie vier saubere Rand-zu-Rand-Goldstreifen (keine Arc-Offsets, keine EdgeArc-Boegen die Luecken hinterliessen). Actionbuttons erhalten einen goldenen 1px-Ring-Overlay der beim Hover und bei aktivem Zauber erscheint.",
		},
	},
	{
		version = "0.3.46",
		date = "2026-11-22",
		changes = {
			"The golden window edge uses the GoldEdge edgeFile again - now backed by the regenerated, spec-correct texture (continuous side lines + rounded corners), it replaces the strip+arc raster as intended.",
		},
		changesDE = {
			"Die goldene Fensterkante nutzt wieder das GoldEdge-EdgeFile - jetzt mit der regenerierten, spec-korrekten Textur (durchgehende Seitenlinien + gerundete Ecken) ersetzt sie wie geplant den Streifen+Bogen-Raster.",
		},
	},
	{
		version = "0.3.45",
		date = "2026-11-22",
		changes = {
			"Reverted the GoldEdge.tga window edge: the generated file renders a fat band on one side and open corners instead of a closed thin ring - the gold contrast edge is back to the strip+arc raster. Black dialog text: gossip/quest/book bodies are re-painted by the game after the show pass, so the dark-text lift now re-runs on the content events (GOSSIP_SHOW, QUEST_*, ITEM_TEXT_*) and also catches strings whose FONT OBJECT carries the dark color while the vertex color reads white.",
		},
		changesDE = {
			"GoldEdge.tga-Fensterrand zurueckgenommen: die Datei rendert ein fettes Band auf einer Seite und offene Ecken statt eines geschlossenen duennen Rings - die Goldkante ist wieder der Streifen+Bogen-Raster. Schwarzer Dialogtext: Gossip-/Quest-/Buchtexte werden vom Spiel nach dem Show-Pass neu gemalt, der Dunkeltext-Lift laeuft jetzt erneut auf den Content-Events (GOSSIP_SHOW, QUEST_*, ITEM_TEXT_*) und erwischt auch Strings, deren FONT-Objekt die dunkle Farbe traegt, waehrend die Vertexfarbe weiss meldet.",
		},
	},
	{
		version = "0.3.44",
		date = "2026-11-22",
		changes = {
			"Action-button states ride the media: the pushed state uses the ButtonPushed soft-light overlay instead of a white blank tint, and the checked state uses the ButtonChecked gold outline ring instead of an accent fill - pressed and toggled buttons now read as designed states, not color washes.",
		},
		changesDE = {
			"Aktionsbutton-Zustaende auf Media: der Gedrueckt-Zustand nutzt das ButtonPushed-Softlight-Overlay statt einer weissen Flaeche, und der Checked-Zustand den ButtonChecked-Goldring statt einer Akzent-Fuellung - gedrueckte und aktive Buttons lesen sich jetzt als gestaltete Zustaende, nicht als Farbwaesche.",
		},
	},
	{
		version = "0.3.43",
		date = "2026-11-22",
		changes = {
			"Generated media in the window skin: the golden contrast edge uses the GoldEdge.tga edgeFile - one anti-aliased accent ring replaces the strip+arc raster on every skinned window. Scrollbar thumbs ride the real SliderThumb.tga glyph (accent-tinted) instead of a solid strip, and checkboxes use the CheckOn/CheckEmpty widget art - dark box, gold check - instead of a tinted Blizzard check.",
		},
		changesDE = {
			"Generierte Media im Fenster-Skin: der goldene Kontrastrand nutzt die GoldEdge.tga-EdgeFile - ein geglatteter Akzent-Ring ersetzt die Streifen+Bogen-Rasterung auf jedem gestylten Fenster. Scrollbar-Thumbs nutzen das echte SliderThumb.tga-Glyph (akzentgetoent) statt eines Solid-Streifens, und Checkboxen bekommen die CheckOn/CheckEmpty-Widget-Art - dunkle Box, goldener Haken - statt eines gefaerbten Blizzard-Hakens.",
		},
	},
	{
		version = "0.3.42",
		date = "2026-11-22",
		changes = {
			"Forbidden-object hardening, second pass: TradeFrame's own GetRegions passes but a CHILD inside it is forbidden - RestyleFonts walked in and threw 'Attempt to access forbidden object'. The forbidden probe now checks both GetRegions and GetChildren, and every walk entry point (StripChrome, RestyleFonts, FadeTextures, HideSubChrome, ReHideDeep, ReapplyChrome, SkinChildren, SkinDialog, SkinButton, MapSkin) carries the cached check so no path can still touch a protected frame.",
		},
		changesDE = {
			"Forbidden-Objekt-Haertung, zweite Runde: TradeFrames eigenes GetRegions laeuft, aber ein Kind darin ist forbidden - RestyleFonts lief hinein und warf 'Attempt to access forbidden object'. Der Probe prueft jetzt GetRegions UND GetChildren, und jeder Walk-Einstieg (StripChrome, RestyleFonts, FadeTextures, HideSubChrome, ReHideDeep, ReapplyChrome, SkinChildren, SkinDialog, SkinButton, MapSkin) traegt den gecachten Check - kein Pfad kann ein geschuetztes Objekt mehr anfassen.",
		},
	},
	{
		version = "0.3.41",
		date = "2026-11-22",
		changes = {
			"The gold window edge was missing its corners: the four accent strips ended 7px short of every corner, leaving the border open on all skinned Blizzard windows. Rasterized quarter arcs (new core S.EdgeArc) now close the frame - center and radius land exactly on the strip ends and follow the panel's rounded corner.",
		},
		changesDE = {
			"Der goldene Fensterrand hatte keine Ecken: die vier Akzent-Streifen endeten 7px vor jeder Ecke und liessen den Rahmen an allen gestylten Blizzard-Fenstern offen. Rasterte Viertelboegen (neuer Core-Helper S.EdgeArc) schliessen den Rahmen jetzt - Zentrum und Radius treffen exakt die Streifenenden und folgen der gerundeten Panel-Ecke.",
		},
	},
	{
		version = "0.3.40",
		date = "2026-11-22",
		changes = {
			"Fix: forbidden objects (TradeFrame, StoreFrame on this client) threw 'Attempt to access forbidden object' errors on login and every open - even GetRegions/GetName is refused there. The skin now probes a frame once, caches the verdict and leaves forbidden objects completely alone: no more error spam, no half-applied skins. Child-level probes (object type, name) inside styled windows are silent pcalls now, so protected children skip quietly instead of printing 'blocked api' warnings.",
		},
		changesDE = {
			"Fix: Forbidden-Objekte (TradeFrame, StoreFrame auf diesem Client) warfen 'Attempt to access forbidden object'-Fehler beim Login und bei jedem Oeffnen - schon GetRegions/GetName wird dort verweigert. Der Skin prueft einen Frame jetzt einmalig, merkt sich das Ergebnis und laesst Forbidden-Objekte komplett in Ruhe: kein Fehler-Spam mehr, keine halb applizierten Skins. Kind-Probes (Objekttyp, Name) in gestylten Fenstern sind jetzt stille pcalls - geschuetzte Kinder werden leise uebersprungen statt 'blocked api'-Warnungen zu drucken.",
		},
	},
	{
		version = "0.3.39",
		date = "2026-11-22",
		changes = {
			"Golden contrast edge: every skinned Blizzard window now carries the 1px accent frame around its panel - strong on top, softer on the other three sides, inset past the corner arcs like every own SentiUI window.",
			"Fix: styled windows flipped back to the old Blizzard look mid-session. The game rebuilds its chrome on every open (NineSlice children, region alphas, backdrops) - the chrome kill now re-runs on every show, and scrollbars, checkboxes and status bars re-apply their skin every walk instead of once. A deferred re-walk catches content populated a tick after OnShow (AH result rows).",
		},
		changesDE = {
			"Goldener Kontrast-Rahmen: Jedes gestylte Blizzard-Fenster traegt jetzt den 1px-Akzentrahmen um sein Panel - oben kraeftig, an den anderen drei Seiten weicher, hinter dem Eckbogen eingesetzt wie jedes eigene SentiUI-Fenster.",
			"Fix: Gestylte Fenster fielen mitten in der Sitzung auf den alten Blizzard-Look zurueck. Das Spiel baut sein Chrome bei jedem Oeffnen neu auf (NineSlice-Kinder, Regions-Alphas, Backdrops) - der Chrome-Kill laeuft jetzt bei jedem Show erneut, und Scrollbars, Checkboxen und Statusleisten wenden ihren Skin bei jedem Walk neu an statt einmalig. Ein verzoegerter Re-Walk faengt Inhalt ab, der erst einen Tick nach OnShow befuellt wird (AH-Ergebniszeilen).",
		},
	},
	{
		version = "0.3.38",
		date = "2026-11-22",
		changes = {
			"Skinned dialog buttons now light their border on hover - the same border-lit feedback every own SentiUI widget has. Icon/art buttons stay untouched: they keep their art and never carry addon scripts on this client.",
		},
		changesDE = {
			"Gestylte Dialog-Buttons leuchten jetzt beim Hover ihre Border auf - dasselbe Border-Lit-Feedback, das jedes eigene SentiUI-Widget hat. Icon-/Art-Buttons bleiben unangetastet: sie behalten ihre Grafik und tragen auf diesem Client keine Addon-Skripte.",
		},
	},
	{
		version = "0.3.37",
		date = "2026-11-22",
		changes = {
			"Close buttons keep their X glyph but tint accent gold now, matching the scrollbar arrows. Window titles (TitleText, TitleContainer on modern windows) read in accent gold instead of the default parchment heading color.",
		},
		changesDE = {
			"Schliessen-Buttons behalten ihr X-Glyph, faerben sich aber Akzent-Gold - passend zu den Scrollbar-Pfeilen. Fenster-Titel (TitleText, TitleContainer auf modernen Fenstern) lesen sich jetzt in Akzent-Gold statt der Standard-Pergamentfarbe.",
		},
	},
	{
		version = "0.3.36",
		date = "2026-11-22",
		changes = {
			"Scrollbar up/down arrow buttons get tinted accent gold instead of keeping the wooden button art - the glyph stays (it is the content) but now matches the accent thumb and the rest of the palette.",
		},
		changesDE = {
			"Scrollbar-Auf/Ab-Pfeile werden jetzt Akzent-Gold gefaerbt statt ihre Holz-Button-Grafik zu behalten - das Glyph bleibt (es ist der Inhalt), passt aber jetzt zum Akzent-Thumb und zum Rest der Palette.",
		},
	},
	{
		version = "0.3.35",
		date = "2026-11-22",
		changes = {
			"The widget sweep now also covers UIWidgetCenterDisplayFrame (center-screen widget texts/bars), and the pet battle queue ready popup plus the old browse/raid browser frame names join the dialog skin list.",
		},
		changesDE = {
			"Der Widget-Sweep deckt jetzt auch UIWidgetCenterDisplayFrame ab (Widget-Texte/Balken in Bildschirmmitte), und das Pet-Battle-Queue-Popup sowie die alten Browse-/Raid-Browser-Frame-Namen stehen in der Dialog-Skin-Liste.",
		},
	},
	{
		version = "0.3.34",
		date = "2026-11-22",
		changes = {
			"Closed the leftover gaps inside styled windows (visible at the auction house): nested panels carry their own NineSlice/Border fields and named inset children, and the chrome pass now runs at every depth of the child walk instead of only the top frame. The window's own backdrop edge gets cleared too - BackdropTemplateMixin borders are not texture regions, so they survived the fade. Modern MenuUtil DropdownButton objects (the AH filter dropdowns) now count as buttons and get the raised style. Ornate border art drawn on the ARTWORK layer fades as well when the region name reads border/background-ish - content icons and portraits stay protected.",
		},
		changesDE = {
			"Die verbliebenen Luecken in gestylten Fenstern geschlossen (beim AH sichtbar): verschachtelte Panels tragen eigene NineSlice-/Border-Felder und Inset-Kinder - der Chrome-Pass laeuft jetzt in jeder Tiefe des Kinder-Walks statt nur am Top-Frame. Das fenster-eigene Backdrop wird ebenfalls geleert (BackdropTemplateMixin-Raender sind keine Textur-Regionen und ueberlebten das Fade). Moderne MenuUtil-DropdownButtons (die AH-Filter-Dropdowns) gelten jetzt als Buttons und bekommen den Raised-Style. Verzierte Rand-Art auf dem ARTWORK-Layer fadet ebenfalls, wenn der Regions-Name nach Rand/Hintergrund klingt - Inhalts-Icons und Portraets bleiben geschuetzt.",
		},
	},
	{
		version = "0.3.33",
		date = "2026-11-22",
		changes = {
			"Fixed erased icons in the group finder and friends: the deep walk faded any button whose name did not read icon-ish, which killed the LFG role/activity tiles - they carry their art in unnamed texture regions with no label text. The guard now keeps a button's art when any texture region sits on the ARTWORK layer (content lives there, chrome on BACKGROUND/OVERLAY) or when the button has textures but no label text. Also added the alternate finder frame names (GroupFinderFrame, PremadeGroupsFrame, LFGFrame) in case the window exists under another global.",
		},
		changesDE = {
			"Geloeschte Icons im Gruppenfinder und Freunde-Fenster gefixt: der Deep-Walk fadete jeden Button ohne Icon-Namen - damit starben die LFG-Rollen-/Aktivitaets-Kacheln, die ihre Grafik in unbenannten Textur-Regionen ohne Label tragen. Der Guard behaelt jetzt die Grafik, wenn eine Textur-Region auf dem ARTWORK-Layer liegt (Inhalt lebt dort, Chrome auf BACKGROUND/OVERLAY) oder wenn der Button Texturen aber keinen Label-Text hat. Ausserdem die alternativen Finder-Frame-Namen ergaenzt (GroupFinderFrame, PremadeGroupsFrame, LFGFrame), falls das Fenster unter anderem Global existiert.",
		},
	},
	{
		version = "0.3.32",
		date = "2026-11-22",
		changes = {
			"Chat popup menus (chat menu, emotes, language, voice macros) and the chat autocomplete dropdown get panel + fonts - no module owned them. The pet battle frame and the dungeon difficulty banner get the font pass only: pet battle buttons are content art, and a generic skin would break more than it fixes there.",
		},
		changesDE = {
			"Chat-Popup-Menues (Chat-Menue, Emotes, Sprache, Sprach-Makros) und das Chat-Autocomplete-Dropdown bekommen Panel + Fonts - kein Modul besass sie. Das Pet-Battle-Frame und der Schwierigkeitsgrad-Banner bekommen nur den Font-Pass: Pet-Battle-Buttons sind Inhalts-Grafik, und ein generischer Skin wuerde dort mehr kaputt als schoen machen.",
		},
	},
	{
		version = "0.3.31",
		date = "2026-11-22",
		changes = {
			"The world map gets its own skin: panel behind, top-level chrome and fonts styled - but no child walk, because map pins are plain button children without icon-ish names and the deep pass would have faded them invisible. The per-show deep re-walk now also only runs for real dialogs, so panel-only skins keep their button art safe.",
			"More stragglers skinned: barber shop, audio options, transmogrify frame, raid parent, contribution collection, torghast level picker - and the battleground always-up score display gets the font pass.",
		},
		changesDE = {
			"Die Weltkarte bekommt einen eigenen Skin: Panel dahinter, Top-Level-Chrome und Fonts gestylt - aber kein Kinder-Walk, weil Karten-Pins schlichte Button-Kinder ohne Icon-Namen sind und der Deep-Pass sie unsichtbar gefaded haette. Der Show-Re-Walk laeuft jetzt auch nur noch fuer echte Dialoge - Panel-only-Skins behalten ihre Button-Grafik.",
			"Weitere Reste gestylt: Barbier, Audio-Optionen, Transmogrifizier-Fenster, Raid-Parent, Kriegsfront-Beitraege, Torghast-Level-Auswahl - und die Schlachtfeld-Daueranzeige bekommt den Font-Pass.",
		},
	},
	{
		version = "0.3.30",
		date = "2026-11-22",
		changes = {
			"The deep child walk now re-runs on every window show, not just once: widgets the game builds lazily (tab pages on first click, scroll rows on populate, late-spawned buttons) get styled as soon as the window reopens. Marker flags keep already-skinned children cheap.",
		},
		changesDE = {
			"Der Deep-Child-Walk laeuft jetzt bei jedem Fenster-Show, nicht nur einmal: Widgets, die das Spiel lazy baut (Tab-Seiten beim ersten Klick, Scroll-Zeilen beim Befuellen, spaet erzeugte Buttons), werden beim Wiederoeffnen sofort gestylt. Marker-Flags halten bereits gestylte Kinder billig.",
		},
	},
	{
		version = "0.3.29",
		date = "2026-11-22",
		changes = {
			"Backdrop chrome dies too: modern inset frames carry their border through the backdrop mixin rather than texture regions, so the chrome pass now clears SetBackdrop on NineSlice/Border/Inset/Bg/TopTileStreaks children and fades one child level deeper - the frame edge can no longer survive the texture fade.",
			"Last named stragglers skinned: battle tag invite, recruit-a-friend recruitment/sent dialogs, quest sync start/join dialogs, edit mode system settings, generic popup frame, and the loss-of-control splash gets panel+fonts.",
		},
		changesDE = {
			"Backdrop-Chrome stirbt auch: moderne Inset-Frames tragen ihren Rand ueber das Backdrop-Mixin statt Textur-Regionen - der Chrome-Pass leert jetzt SetBackdrop auf NineSlice-/Border-/Inset-/Bg-/TopTileStreaks-Kindern und fadet eine Kinder-Ebene tiefer. Der Fensterrand kann das Fade nicht mehr ueberleben.",
			"Letzte benannte Reste gestylt: BattleTag-Einladung, Werbt-einen-Freund-Dialoge, Quest-Sync-Start/Beitritt, EditMode-Systemeinstellungen, Generisches Popup, und der Kontrollverlust-Splash bekommt Panel+Fonts.",
		},
	},
	{
		version = "0.3.28",
		date = "2026-11-22",
		changes = {
			"Fourth wave of window skins: auction house (both frame names), black market, the read-mail window, stable master, arena registrar, movie frame, store, script errors, bonus roll, party pose screens, keystone frame, macro icon picker, community ticket manager, quest log popup detail, recruit-a-friend, scrapper, azerite frames, reputation detail and token popups, all calendar sub-windows, tutorial frame, and the compact raid manager pullout gets panel+fonts.",
		},
		changesDE = {
			"Vierte Fenster-Skin-Welle: Auktionshaus (beide Frame-Namen), Schwarzmarkt, das Brief-Lesen-Fenster, Stallmeister, Arena-Registrator, Movie-Frame, Shop, Script-Fehler, Bonus-Wurf, Party-Pose-Bildschirme, Schlüsselstein-Fenster, Makro-Icon-Auswahl, Community-Ticket-Manager, Questlog-Popup-Detail, Werbt-einen-Freund, Verschrotter, Azerit-Fenster, Ruf-Detail und Waehrungs-Popups, alle Kalender-Unterfenster, Tutorial-Frame - und der Kompakt-Raid-Manager bekommt Panel+Fonts.",
		},
	},
	{
		version = "0.3.27",
		date = "2026-11-22",
		changes = {
			"Third wave of window skins: the modern SettingsPanel (which replaces the old options frame on new builds), click bindings, edit mode manager, all group-finder popups (ready dialog, invite, role check), PvP match results/scoreboard, player choice dialogs, warboard, archaeology, item interaction, obliterum, islands queue, chromie time, inspect guild, guild control/invite/text edit, model preview, splash, death recap, report, generic traits, delves pickers, crafting orders, and the garrison/order hall/covenant/soulbind/runeforge/anima system windows all get the Sentinel dialog skin.",
			"Modern window chrome is gone too: chrome that lives in named child frames (NineSlice, Border, Inset, Bg, TopTileStreaks) now fades along with the field-based chrome, and status bars inside windows (reputation, progress) swap their wood fill for the flat blank texture while keeping their status color.",
		},
		changesDE = {
			"Dritte Fenster-Skin-Welle: das moderne SettingsPanel (ersetzt auf neuen Builds das alte Optionsfenster), Klick-Belegung, EditMode-Manager, alle Gruppensuche-Popups (Bereitschaftsdialog, Einladung, Rollen-Check), PvP-Ergebnis/Wertung, Player-Choice-Dialoge, Kriegsbrett, Archaeologie, Item-Interaktion, Obliterum, Insel-Queue, Chromie-Zeit, Gilden-Betrachtung, Gilden-Kontrolle/Einladung/Textedit, Modell-Vorschau, Splash, Todesrueckblick, Melden, Generische Traits, Delves-Auswahl, Handwerksauftraege sowie die Garnisons-/Ordenshallen-/Paktsystem-/Seelenband-/Runenschmiede-/Anima-Fenster bekommen den Sentinel-Dialog-Skin.",
			"Modernes Fenster-Chrome ist auch weg: Chrome in benannten Kind-Frames (NineSlice, Border, Inset, Bg, TopTileStreaks) fadet jetzt mit, und Statusbalken in Fenstern (Ruf, Fortschritt) tauschen die Holz-Fuellung gegen die flache Blank-Textur - die Statusfarbe bleibt.",
		},
	},
	{
		version = "0.3.26",
		date = "2026-11-22",
		changes = {
			"The window skin now walks the full child tree, so nested page buttons, scroll children and tab-page widgets inside the big windows get the raised/inset treatment too instead of staying wooden. Text tabs (merchant, spellbook, friends, character) become raised chips; dropdown fields in windows lose their pill chrome and sit in a dark inset while label and arrow stay. The icon guard got sharper: buttons whose name, icon field or texture regions read icon/item/slot/spell/glyph/portrait keep their art - spellbook and glyph icons can not be erased by the deep walk.",
		},
		changesDE = {
			"Der Fenster-Skin wandert jetzt den kompletten Kind-Baum: verschachtelte Seiten-Buttons, Scroll-Kinder und Tab-Widgets in den grossen Fenstern bekommen ebenfalls den Raised-/Inset-Look statt Holz zu behalten. Text-Tabs (Haendler, Zauberbuch, Freunde, Charakter) werden zu Raised-Chips; Dropdown-Felder verlieren ihr Pill-Chrome und sitzen in dunklem Inset, Label und Pfeil bleiben. Der Icon-Schutz wurde geschaerft: Buttons, deren Name, Icon-Feld oder Textur-Regionen nach Icon/Item/Slot/Spell/Glyph/Portraet klingen, behalten ihre Grafik - Zauberbuch- und Glyphen-Icons kann der Deep-Walk nicht loeschen.",
		},
	},
	{
		version = "0.3.25",
		date = "2026-11-22",
		changes = {
			"Second wave of window skins: collections, encounter journal, achievements, calendar, guild/communities, PvE finder, challenges, talents, professions/tradeskill, wardrobe/transmog, void storage, item upgrade/socketing, weekly rewards, perks, landing pages, flight map, loot history, BG scoreboard, quest log detail, raid info, guild registrar, color picker and opacity frames all get the Sentinel dialog skin. Load-on-demand frames resolve through the show watcher.",
			"Scrollbars and checkboxes inside the skinned windows now get a deep styling pass: the scrollbar track fades and the thumb becomes a solid accent bar (arrow art stays - that is their content), and checkbox checks tint accent gold.",
		},
		changesDE = {
			"Zweite Fenster-Skin-Welle: Sammlungen, Dungeonkompendium, Erfolge, Kalender, Gilde/Communities, PvE-Finder, Mythisch+, Talente, Berufe, Transmog/Kleiderschrank, Leerenlager, Item-Aufwertung/Sockelung, wöchentliche Belohnungen, Perks, Landing-Pages, Flugkarte, Beuteverlauf, Schlachtfeld-Punkte, Questlog-Detail, Raid-Info, Gildenregistrator, Farbwahl und Opazität bekommen den Sentinel-Dialog-Skin. Load-on-Demand-Fenster loest der Show-Watcher auf.",
			"Scrollbalken und Checkboxen in den gestylten Fenstern bekommen einen Deep-Pass: die Scroll-Spur fadet und der Griff wird ein solider Akzent-Balken (Pfeil-Grafik bleibt - die ist der Inhalt), Checkbox-Häkchen faerben sich Akzent-Gold.",
		},
	},
	{
		version = "0.3.24",
		date = "2026-11-22",
		changes = {
			"Dark text on the dark panel is readable now: Blizzard dialog fonts are painted black for parchment, so a luminance check in the font pass lifts only strings that still read dark onto the normal text color - quality/link/header colors keep their role color. The font pass also re-runs on every show, since the game repaints text colors per open (quest pages, merchant tabs).",
		},
		changesDE = {
			"Dunkle Schrift auf dem dunklen Panel ist jetzt lesbar: Blizzard-Dialogschriften sind schwarz fuer Pergament gefaerbt, daher hebt ein Luminanz-Check im Font-Pass nur Strings an, die noch dunkel lesen, auf die normale Textfarbe - Quality-/Link-/Headerfarben behalten ihre Rollenfarbe. Der Font-Pass laeuft ausserdem bei jedem Anzeigen erneut, da das Spiel die Textfarben pro Oeffnung neu malt (Quest-Seiten, Haendler-Tabs).",
		},
	},
	{
		version = "0.3.23",
		date = "2026-11-22",
		changes = {
			"The dialog skin now covers the big everyday windows too: quest giver and quest log, gossip, merchant, mail, spellbook, trade, inspect, taxi, dressing room, tabard, petition, friends, macro, trainer/craft, battlefield/PvP/honor/LFG, bank/guild bank/auction, quest timer, time manager, help, interface options/keybindings and the addon list all get the dark panel with SentiUI fonts and buttons. Missing names are skipped and load-on-demand windows are styled on first show via the visibility watcher.",
			"Item slot buttons inside those windows keep their icons: the child-button skin used to fade every texture region, which would have erased merchant slots, quest reward icons and mail attachments - buttons whose name or fields mark them as item/icon/slot/tab/attachment now only get the font pass.",
		},
		changesDE = {
			"Der Dialog-Skin deckt jetzt auch die grossen Alltags-Fenster ab: Questgeber und Questlog, Gossip, Haendler, Post, Zauberbuch, Handel, Betrachten, Flugkarte, Anprobe, Wappenrock, Petition, Freunde, Makros, Lehrer/Craft, Schlachtfeld/PvP/Ehre/LFG, Bank/Gildenbank/Auktion, Quest-Timer, Zeitmanager, Hilfe, Interface-Optionen/Tastaturbelegung und die Addon-Liste bekommen das dunkle Panel mit SentiUI-Schrift und -Buttons. Fehlende Namen werden uebersprungen, nachgeladene Fenster beim ersten Anzeigen ueber den Sichtbarkeits-Watcher gestylt.",
			"Item-Slot-Buttons in diesen Fenstern behalten ihre Icons: der Kind-Button-Skin fadete bisher jede Texture-Region, womit Haendler-Slots, Quest-Belohnungs-Icons und Mail-Anhaenge geloescht worden waeren - Buttons, deren Name oder Felder sie als Item/Icon/Slot/Tab/Attachment markieren, bekommen jetzt nur noch den Font-Pass.",
		},
	},
	{
		version = "0.3.22",
		date = "2026-11-22",
		changes = {
			"Cooldown Manager viewers opt-in (Action Bars > Extra buttons): the parked Essential/Utility/Buff viewers come back with a SentiUI skin and movable positions instead of staying hidden - off by default.",
			"Mover-framed Blizzard UI gets the SentiUI look: TalkingHead, the mirror timers and the vehicle seat indicator lose their parchment chrome and gain the dark panel backdrop; large screen texts (zone/subzone announcements, raid warnings, boss emotes, UI errors) use the SentiUI font with accent coloring.",
			"The remaining Blizzard leftovers get skinned too: the ESC game menu, StaticPopup confirm dialogs, ready check, item text reader, chat config, stack split and cinematic close dialogs get the dark panel with SentiUI buttons and fonts; dropdown menus, Battle.net toasts, queue and ticket status, the durability doll and the ghost release button get the panel look; boss/level-up banners switch to the SentiUI font; alert toasts, top-center and below-minimap widgets and battleground timer bars are styled as they spawn via a slow sweep.",
		},
		changesDE = {
			"Cooldown-Manager-Anzeigen als Opt-in (Aktionsleisten > Extrabuttons): die versteckten Essential-/Utility-/Buff-Anzeigen kommen mit SentiUI-Skin und verschiebbaren Positionen zurueck statt versteckt zu bleiben - standardmaessig aus.",
			"Blizzard-Fenster an den Movern bekommen den SentiUI-Look: TalkingHead, die Mirror-Timer und die Fahrzeugsitz-Anzeige verlieren ihr Pergament-Chrome und bekommen das dunkle Panel; grosse Screen-Texte (Zonen-/Unterzonen-Ansagen, Raid-Warnungen, Boss-Emotes, UI-Fehler) nutzen die SentiUI-Schrift mit Akzentfaerbung.",
			"Auch die restlichen Blizzard-Reste bekommen den Skin: das ESC-Spielmenue, StaticPopup-Dialoge, Bereitschaftscheck, Item-Text-Leser, Chat-Konfiguration, Stack-Split und der Cinematic-Dialog bekommen das dunkle Panel mit SentiUI-Buttons und -Schrift; Dropdown-Menues, Battle.net-Toasts, Warteschlangen- und Ticket-Status, das Ruestungs-Maennchen und der Geist-Button bekommen den Panel-Look; Boss-/Level-Up-Banner wechseln auf die SentiUI-Schrift; Alert-Toasts, obere und untere Minimap-Widgets sowie Schlachtfeld-Timer werden per Sweep beim Erscheinen gestylt.",
		},
	},
	{
		version = "0.3.21",
		date = "2026-11-22",
		changes = {
			"Fixed a cooldown error spam: the button template's own handlers call SetCooldown(start, duration, modRate) with values that are secret on this client - SetCooldown refuses secrets under addon taint ('bad argument #1 to SetCooldown'). Our buttons now swallow that throw on their own cooldown widget; the visible cooldown still paints via our SetCooldownFromDurationObject painter and the game's untainted cooldown events.",
		},
		changesDE = {
			"Cooldown-Fehlerspam behoben: die eigenen Handler des Button-Templates rufen SetCooldown(start, duration, modRate) mit auf diesem Client geheimen Werten auf - SetCooldown verweigert Secrets unter Addon-Taint ('bad argument #1 to SetCooldown'). Unsere Buttons schlucken den Wurf jetzt auf ihrem eigenen Cooldown-Widget; die sichtbare Abklingzeit wird weiterhin ueber unseren SetCooldownFromDurationObject-Painter und die untainted Cooldown-Events des Spiels gezeichnet.",
		},
	},
	{
		version = "0.3.20",
		date = "2026-11-22",
		changes = {
			"Empty action slots now dim their button body to 18% opacity instead of showing a full dark square — the bar grid stays readable without prominent black boxes where no action is assigned.",
			"Icon rounding now uses the rewritten core S.IconRound: the icon is clipped by a real MaskTexture (rounded-square silhouette), so a failing mask can never paint a dark box over the icon.",
		},
		changesDE = {
			"Leere Aktions-Slots dimmen jetzt ihren Button-Koerper auf 18% Deckkraft statt ein volles dunkles Quadrat zu zeigen — das Leisten-Raster bleibt lesbar ohne markante schwarze Kaestchen, wo keine Aktion belegt ist.",
			"Icon-Rundung nutzt jetzt den neu geschriebenen Core-S.IconRound: Das Icon wird von einer echten MaskTexture geclippt (abgerundete Quadrat-Silhouette), eine fehlschlagende Maske kann also nie eine dunkle Box ueber das Icon malen.",
		},
	},
	{
		version = "0.3.19",
		date = "2026-11-22",
		changes = {
			"Action button icons now have soft rounded corners: S.IconRound covers each icon's square corner with a background-colored arc using CircleMask.tga — the inverse UV mapping of S.Roundize. The 6px radius matches the button body rounding from S.Template.",
		},
		changesDE = {
			"Aktionsbutton-Icons haben jetzt weiche abgerundete Ecken: S.IconRound überdeckt jede eckige Icon-Ecke mit einem hintergrundfarbigen Bogen aus CircleMask.tga — inverse UV-Abbildung von S.Roundize. Der 6px-Radius passt zur Körper-Rundung durch S.Template.",
		},
	},
	{
		version = "0.3.18",
		date = "2026-11-22",
		changes = {
			"Talent alert pill: same secure-click fix - the /click forward keeps the template's own OnClick handler so the macro runs untainted.",
		},
		changesDE = {
			"Talent-Hinweis-Pill: gleicher Secure-Klick-Fix - die /click-Weiterleitung behält den eigenen OnClick-Handler des Templates, damit das Makro ungetaintet läuft.",
		},
	},
	{
		version = "0.3.17",
		date = "2026-11-22",
		changes = {
			"Fix the 'forbidden call' spam in combat: the 2s mouse-unblock sweep touched protected children inside parked Blizzard bars (EnableMouse is forbidden mid-fight) and got blamed on SentiUI. The sweep and KillMouseDeep now skip while in combat; the next tick after REGEN catches up.",
		},
		changesDE = {
			"Fix: 'forbidden call'-Spam im Kampf - der 2s-Maus-Sweep beruehrte geschuetzte Kinder in geparkten Blizzard-Leisten (EnableMouse ist im Kampf verboten) und wurde SentiUI angelastet. Der Sweep und KillMouseDeep ueberspringen jetzt den Kampf; der naechste Tick nach REGEN holt auf.",
		},
	},
	{
		version = "0.3.16",
		date = "2026-11-22",
		changes = {
			"Fix 'hide when empty' bars blinking on fresh characters: the bare SetShown fought the visibility state driver, which re-asserted 'show' and made the bar flicker every check tick. Empty bars now hide by unregistering the visibility driver and re-registering it when a slot gains an action; they also reappear while dragging a spell (ACTIONBAR_SHOWGRID) so they can receive drops.",
		},
		changesDE = {
			"Fix: 'Verstecken wenn leer'-Leisten blinkten auf frischen Charakteren - das nackte SetShown kaempfte gegen den Sichtbarkeits-State-Driver, der 'show' zuruecksetzte und die Leiste pro Pruef-Tick flackern liess. Leere Leisten verstecken sich jetzt ueber das Abmelden des Drivers und melden ihn wieder, sobald ein Platz eine Aktion traegt; beim Ziehen eines Zaubers erscheinen sie ebenfalls (ACTIONBAR_SHOWGRID), damit sie Drops annehmen.",
		},
	},
	{
		version = "0.3.15",
		date = "2026-11-22",
		changes = {
			"Real click blocker found via /suibars foci: parked Blizzard bars keep CHILD frames at their old rects with mouse enabled (an unnamed MultiBarBottomLeft child at MEDIUM/level 1001 sat over the extra bar). Parked subtrees and the status-tracking containers now lose their mouse recursively; secure twin buttons keep theirs (click targets). Unnamed fullscreen ModelScenes lose the mouse in the sweep.",
		},
		changesDE = {
			"Echter Klick-Blocker via /suibars foci gefunden: geparkte Blizzard-Leisten behalten KIND-Frames an alter Position mit aktiver Maus (ein namenloses MultiBarBottomLeft-Kind auf MEDIUM/Level 1001 lag ueber der Zusatzleiste). Geparkte Teilbaeume und Status-Tracking-Container verlieren jetzt rekursiv ihre Maus; die sicheren Twin-Buttons behalten ihre (Klick-Ziele). Namenlose Vollbild-ModelScenes verlieren die Maus im Sweep.",
		},
	},
	{
		version = "0.3.14",
		date = "2026-11-22",
		changes = {
			"TextOverlayContainer can be created lazily after the button - its mouse now gets disabled in the 2s sweep too, not only at button creation.",
		},
		changesDE = {
			"TextOverlayContainer kann erst lazy nach dem Button entstehen - seine Maus wird jetzt auch im 2s-Sweep abgestellt, nicht nur bei der Button-Erzeugung.",
		},
	},
	{
		version = "0.3.13",
		date = "2026-11-22",
		changes = {
			"Follow-up click fix: the widget CONTAINER frames themselves (UIWidgetBelowMinimap/TopCenter/PowerBar, ObjectiveTrackerUIWidget, ContainerFrame) also lose their mouse - they are pure layout frames; children keep their own hit flags. New /suibars foci prints the mouse-enabled frames under the cursor so any remaining click blocker names itself.",
		},
		changesDE = {
			"Klick-Fix Nachtrag: die Widget-CONTAINER selbst (UIWidgetBelowMinimap/TopCenter/PowerBar, ObjectiveTrackerUIWidget, ContainerFrame) verlieren ebenfalls ihre Maus - reine Layout-Frames, die Kinder behalten eigene Hit-Flags. Neu: /suibars foci zeigt die mausaktiven Frames unter dem Cursor, damit sich ein verbleibender Klick-Blocker selbst nennt.",
		},
	},
	{
		version = "0.3.12",
		date = "2026-11-22",
		changes = {
			"Fix extension bar slots only clicking on a thin lower rim: the template's TextOverlayContainer rides at frame level 500 with its mouse enabled and covered the whole button, and the client's global FX/widget model scenes at high strata swallowed clicks where they overlap the bars. The container's mouse is dropped per button; the FX/widget model scenes lose theirs on a 2s sweep (they respawn late).",
		},
		changesDE = {
			"Fix: Slots der Zusatzleisten liessen sich nur an einem schmalen unteren Rand klicken - der TextOverlayContainer des Templates liegt auf Frame-Level 500 mit aktiver Maus ueber dem ganzen Button, und die globalen FX-/Widget-ModelScenes des Clients auf hohen Strata schluckten Klicks, wo sie die Leisten ueberlagern. Die Maus des Containers wird je Button abgestellt; die FX-/Widget-ModelScenes verlieren ihre im 2s-Sweep (sie spawnen spaet neu).",
		},
	},
	{
		version = "0.3.11",
		date = "2026-11-22",
		changes = {
			"Holder attach keeps ExtraAbilityContainer and friends in place by a 0.5s drift poll instead of SetParent/SetPoint post-hooks - the hooks ran inside the client's layout dispatch and tainted whatever protected work followed.",
		},
		changesDE = {
			"Die Holder-Befestigung hält ExtraAbilityContainer & Co. per 0,5s-Drift-Poll statt SetParent/SetPoint-Post-Hooks - die Hooks liefen im Layout-Dispatch des Clients und vergifteten die geschützte Arbeit danach.",
		},
	},
	{
		version = "0.3.10",
		changes = {
			"The labelled Call/Sec wrappers now delegate to the shared core wrapper (S.Call): blocked engine calls print the api name AND the call site (file.lua:line) once.",
		},
		changesDE = {
			"Die gelabelten Call/Sec-Wrapper delegieren jetzt an den gemeinsamen Core-Wrapper (S.Call): Blockierte Engine-Calls melden API-Namen UND Aufrufstelle (datei.lua:zeile) einmal.",
		},
	},

	{
		version = "0.3.9",
		changes = {
			"Fixed the action-button press point covering only the slot's center: ActionBarButtonTemplate ships an inset hit rect (the artwork ring is not clickable), while our slot look fills the whole button - the hit rect is reset to the full frame now.",
		},
		changesDE = {
			"Der Druckpunkt auf Aktionsbuttons traf nur die Slot-Mitte: ActionBarButtonTemplate bringt einen eingezogenen Hit-Rect mit (der Artwork-Ring ist nicht klickbar), waehrend unser Slot den ganzen Button fuellt - der Hit-Rect deckt jetzt den vollen Frame ab.",
		},
	},

	{
		version = "0.3.8",
		changes = {
			"Interface-dispatch audit: micro-button alert frames are hidden via visibility watchers instead of OnShow hooks (insecure scripts in the alert dispatch taint the client's follow-up). The talent pill forwards a real secure click to the micro button instead of calling ToggleTalentFrame; watcher installation is deduplicated.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Micro-Button-Alerts werden ueber Sichtbarkeits-Watcher statt OnShow-Hooks versteckt (unsichere Scripts im Alert-Dispatch tainten die Folgearbeit des Clients). Die Talent-Pille leitet einen echten Secure-Click an den Micro-Button weiter statt ToggleTalentFrame zu rufen; Watcher-Installation dedupliziert.",
		},
	},

	{
		version = "0.3.7",
		changes = {
			"Dispatcher rollback: the event-removal/poll rework broke the bars - the full native event set is back (slot/state/autorepeat/combat/mount/cooldown/usable/range/charges/target/shapeshift/page/vehicle), the 0.2s state poll and button signatures are gone.",
		},
		changesDE = {
			"Dispatcher-Rollback: Der Event-Entfernungs-/Poll-Umbau hat die Leisten kaputtgemacht - das volle native Event-Set ist zurueck (Slot/State/Autorepeat/Kampf/Mount/Cooldown/Usable/Range/Charges/Target/Shapeshift/Page/Vehicle), der 0,2s-Status-Poll und die Button-Signaturen sind weg.",
		},
	},
	{
		version = "0.3.6",
		changes = {
			"Cooldown repaint fixed: cooldown times are secret so they cannot live in the button signature - a spell recast during an active cooldown produced no transition and the sweep froze, which made healer bars look dead. A button now repaints whenever its signature changes AND on every tick while a cooldown runs (the sweep handles secret times natively). The signature also diffs the slot texture id and checked state, so ACTIONBAR_SLOT_CHANGED/UPDATE_STATE/AUTOREPEAT events could go too - they fired inside the spell-drag and auto-shot click dispatches. Combat and mount state moved into the poll as well.",
		},
		changesDE = {
			"Cooldown-Repaint gefixt: Cooldown-Zeiten sind secret und können nicht in die Button-Signatur - ein Recast bei laufendem Cooldown erzeugte keinen Wechsel und der Sweep fror ein, wodurch Heiler-Leisten tot wirkten. Ein Button zeichnet jetzt bei jedem Signatur-Wechsel UND bei jedem Tick, solange ein Cooldown läuft (der Sweep verarbeitet Secret-Zeiten nativ). Die Signatur prüft zusätzlich die Slot-Textur-ID und den Checked-State, sodass auch ACTIONBAR_SLOT_CHANGED/UPDATE_STATE/AUTOREPEAT-Events weg konnten - sie feuerten im Spell-Drag- und Autoschuss-Klick-Dispatch. Kampf- und Mount-Status laufen ebenfalls über den Poll.",
		},
	},
	{
		version = "0.3.5",
		changes = {
			"Cooldown/usable/range/charge events moved into the 0.2s bar state poll as a per-button signature - those events fire inside the protected cast and target-swap dispatches and tainted Blizzard's CooldownFrame_Set on secret times.",
		},
		changesDE = {
			"Cooldown-/Usable-/Reichweiten-/Ladungs-Events als Pro-Button-Signatur in den 0,2s-Bar-State-Poll verlagert - die Events feuern im geschuetzten Cast- und Zielwechsel-Dispatch und tainteten Blizzards CooldownFrame_Set bei Secret-Werten.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Input-dispatch events replaced by a state poll: PLAYER_TARGET_CHANGED, UPDATE_SHAPESHIFT_FORM(S), UPDATE_BONUS_ACTIONBAR, ACTIONBAR_PAGE_CHANGED, UPDATE_VEHICLE_ACTIONBAR and UPDATE_OVERRIDE_ACTIONBAR all fire inside protected key/click dispatches, where Lua taints the client's follow-up protected calls. A 0.2s poll now watches target presence, action page, shapeshift form and vehicle/override/bonus/possess state and issues the same queued repaints.",
		},
		changesDE = {
			"Input-Dispatch-Events durch State-Poll ersetzt: PLAYER_TARGET_CHANGED, UPDATE_SHAPESHIFT_FORM(S), UPDATE_BONUS_ACTIONBAR, ACTIONBAR_PAGE_CHANGED, UPDATE_VEHICLE_ACTIONBAR und UPDATE_OVERRIDE_ACTIONBAR feuern in geschützten Tasten-/Klick-Dispatches, wo Lua die folgenden geschützten Aufrufe taintet. Ein 0,2s-Poll überwacht jetzt Ziel, Aktionsseite, Gestalt und Fahrzeug-/Override-/Bonus-/Besessen-Status und stößt dieselben gequeuüten Repaints an.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"Escape-forbidden-call fix: the EditMode manager's OnHide hook ran inside the Escape dispatch when leaving Edit Mode - it watches the hidden transition via S.WatchHide now.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Der OnHide-Hook des EditMode-Managers lief im Escape-Dispatch beim Verlassen des Edit-Modus - er beobachtet den Uebergang jetzt ueber S.WatchHide.",
		},
	},

	{
		version = "0.3.2",
		changes = {
			"Status tracking bars are no longer reparented into the park frame - layout passes call their manager methods, which expect the real parent (caused 'blizzard: TextStatusBar' errors). They now stay put with events off and alpha 0.",
			"Extra-button attach: when another addon's holder frame claims the same Blizzard frame, we yield instead of fighting it - two holder hooks ping-ponged ExtraAbilityContainer into a C stack overflow when both UI suites were loaded.",
		},
		changesDE = {
			"Status-Tracking-Leisten werden nicht mehr in den Park-Frame umgarentet - Layout-Pässe rufen ihre Manager-Methoden auf, die den echten Parent erwarten (verursachte 'blizzard: TextStatusBar'-Fehler). Sie bleiben jetzt mit abgeschalteten Events und Alpha 0 an Ort und Stelle.",
			"Extra-Button-Verankerung: Beansprucht ein fremder Holder-Frame dasselbe Blizzard-Frame, geben wir nach statt zu kämpfen - zwei Holder-Hooks haben ExtraAbilityContainer per Ping-Pong in einen C-Stack-Overflow getrieben, wenn beide UI-Suiten geladen waren.",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Stopped the StatusTrackingBarManager's events under the park frame - its Blizzard TextStatusBar updates kept running while hidden and errored on the client's secret XP/reputation values (error source 'blizzard: TextStatusBar').",
		},
		changesDE = {
			"Events des StatusTrackingBarManager unter dem Park-Frame abgeschaltet - seine Blizzard-TextStatusBar-Updates liefen versteckt weiter und crashten an den Secret-EP-/Rufwerten des Clients (Fehlerquelle 'blizzard: TextStatusBar').",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Unspent-talent-points hint redone in SentiUI style: the game's micro-button alert anchored to the parked micro bar and floated mid-screen - all *MicroButtonAlert frames are now re-hidden, and a small gold-lit pill above the bottom bars shows 'Unspent talent points: N' instead (count via UnitCharacterPoints / C_ClassTalents where available, otherwise it still follows the game's own alert). Click opens the talent frame. German label 'Unverteilte Talentpunkte'.",
		},
		changesDE = {
			"Hinweis auf unverteilte Talentpunkte im SentiUI-Stil: Der Micro-Button-Hinweis des Spiels ankerte an der geparkten Micro-Leiste und schwebte mitten im Bild - alle *MicroButtonAlert-Frames werden jetzt wieder versteckt, stattdessen zeigt eine kleine gold umrandete Pille über der unteren Leiste 'Unverteilte Talentpunkte: N' (Zähler über UnitCharacterPoints / C_ClassTalents wo verfügbar, sonst folgt sie dem Spiel-Hinweis). Klick öffnet das Talentfenster.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.",
		},
		changesDE = {
			"Park-/Versteck-Frames stubben jetzt die Blizzard-Layout-Methoden (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame), die Client-Skripte auf GetParent() aufrufen - behebt einen StatusTrackingManager-UpdateShownState-Fehler durch unter einem nackten versteckten Parent geparkte Frames.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"Every bar now fires through the game's own twin button (type=click on ActionButton1-12 / MultiBar*ButtonN): the twin knows its real action slot AND handles the Shift pickup modifier natively, so casting and pickup behave exactly like the client's own buttons. Bar 1's twins get their page pushed by the existing state snippet.",
			"Click registration is AnyDown+AnyUp again: this client ignores useOnKeyDown=false and fires on the down half, so AnyUp alone made all bars dead. Drag-out pickup stays gated on Shift / unlocked bars.",
			"Removed the custom OnMouseDown pickup hack - the twin's own modified click logic covers press-to-pickup.",
		},
		changesDE = {
			"Jede Leiste feuert jetzt über den eigenen Zwillingsbutton des Spiels (type=click auf ActionButton1-12 / MultiBar*ButtonN): Der Twin kennt seinen echten Action-Slot UND handhabt den Shift-Aufnahme-Modifikator nativ - Zaubern und Aufnehmen verhalten sich exakt wie bei den Original-Buttons. Die Twins von Leiste 1 bekommen ihre Seite vom vorhandenen State-Snippet gepusht.",
			"Click-Registrierung ist wieder AnyDown+AnyUp: Der Client ignoriert useOnKeyDown=false und feuert auf der Down-Hälfte - nur AnyUp machte alle Leisten tot. Drag-out-Pickup bleibt an Shift / entsperrte Leisten gebunden.",
			"Der eigene OnMouseDown-Pickup-Hack ist raus - die Modified-Click-Logik des Twins deckt Press-to-Pickup ab.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Bars 2-4 now actually cast: instead of type=action + a guessed slot, each button clicks through to the game's own twin button (type=click + clickbutton on MultiBarBottomLeftButtonN etc.) - the twin holds the client's real action mapping, so the spell it shows is the spell that fires. The slot attribute still feeds painting and pickup.",
		},
		changesDE = {
			"Leisten 2-4 wirken jetzt wirklich: Statt type=action + geratenem Slot klickt jeder Button auf den eigenen Zwillingsbutton des Spiels (type=click + clickbutton auf MultiBarBottomLeftButtonN etc.) - der Twin trägt das echte Action-Mapping des Clients, also feuert der Zauber, der angezeigt wird. Das Slot-Attribut bleibt für Painting und Aufnehmen.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Fixed bars 2-4 doing nothing: their buttons pointed at main-bar page slots (61-72, 49-60, 25-36) instead of the multi-bar ranges. Buttons now read their action slot from the game's own twin button (MultiBarBottomLeft = 85-96 etc. on this client's 132-slot map), so the mapping is correct whatever the client uses; the old page math stays as fallback only.",
		},
		changesDE = {
			"Leisten 2-4 taten nichts: Ihre Buttons zeigten auf Hauptleisten-Seiten-Slots (61-72, 49-60, 25-36) statt auf die Multi-Leisten-Bereiche. Buttons lesen ihren Action-Slot jetzt vom eigenen Zwillingsbutton des Spiels (MultiBarBottomLeft = 85-96 etc. im 132-Slot-Mapping des Clients) - das Mapping ist damit korrekt, egal was der Client nutzt; die alte Seitenrechnung bleibt nur als Fallback.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Fixed dead action bars: IsModifiedClick(\"PICKUPACTION\") can return truthy on this client without the key being held, so every button press picked the spell up instead of casting it. Pickup now requires Shift held (the game's default modifier) or unlocked action bars.",
		},
		changesDE = {
			"Tote Aktionsleisten gefixt: IsModifiedClick(\"PICKUPACTION\") kann auf diesem Client truthy antworten, ohne dass die Taste gehalten wird - jeder Tastendruck nahm den Zauber auf statt ihn zu wirken. Aufnehmen braucht jetzt gehaltene Shift-Taste (Spiel-Standard) oder entsperrte Aktionsleisten.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Dragging an action off a bar no longer triggers it: pickup now needs the pick-up modifier (Shift by default, remappable via the PICKUPACTION binding) or unlocked action bars, matching normal WoW behavior.",
			"Buttons fire on release only (AnyUp) - the AnyDown registration let a plain press cast before a drag could start.",
		},
		changesDE = {
			"Das Herausziehen einer Aktion löst sie nicht mehr aus: Das Aufnehmen braucht jetzt den Aufnahme-Modifikator (Standard Shift, per PICKUPACTION-Belegung änderbar) oder entsperrte Aktionsleisten - wie im normalen Spiel.",
			"Buttons feuern erst beim Loslassen (AnyUp) - die AnyDown-Registrierung ließ ein einfaches Drücken schon zaubern, bevor ein Ziehen starten konnte.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"The Counts toggle is honored now: the count painter ignored the setting and always drew item and charge counts.",
		},
		changesDE = {
			"Der Counts-Schalter greift jetzt: Der Zähler-Painter ignorierte die Einstellung und malte Item-/Charge-Zahlen immer.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Fixed the park pass dying mid-list: BagsBar and MicroButtonAndBagsBar are plain controller tables on this client, not frames - a nil GetParent call aborted the loop and left everything after them (status tracking bar, micro menu, totem bar, cooldown viewers) visible.",
			"Fixed clicks on the action bars: the un-parked MultiCastActionBarFrame sat on top of the buttons and ate them.",
			"Buttons now also register for AnyDown so press-and-hold casting works.",
		},
		changesDE = {
			"Der Park-Durchlauf starb mitten in der Liste: BagsBar und MicroButtonAndBagsBar sind auf diesem Client reine Tabellen, keine Frames - der nil-Call brach die Schleife ab und ließ alles danach (Fortschrittsleiste, Micro-Menü, Totem-Leiste, Cooldown-Viewer) sichtbar.",
			"Klicks auf den Aktionsleisten gehen wieder: Das ungeparkte MultiCastActionBarFrame lag über den Buttons und fraß sie.",
			"Buttons registrieren jetzt auch AnyDown, damit Press-and-Hold-Casting geht.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Fixed cooldowns never sweeping: without a DurationObject the sweep fell through to Clear() on every paint - now it uses raw times while they are readable, and leaves an active sweep alone instead of clearing it.",
			"Fixed parked game frames coming back: the game re-parents its bars on its own layout passes, so the park now rechecks behind UpdateMicroButtons, the micro menu fullscreen hand-offs, talent/spec updates, Edit Mode changes and the vehicle/override events.",
			"Each post-build enable step runs on its own now - one failure can no longer take the extras (pet/stance/totem bars) down with it.",
		},
		changesDE = {
			"Cooldowns zeichneten nie: Ohne DurationObject lief der Sweep bei jedem Paint in Clear() - jetzt nutzt er lesbare Rohzeiten und lässt einen laufenden Sweep stehen statt ihn zu löschen.",
			"Geparkte Spiel-Frames kamen zurück: Das Spiel setzt seine Bars bei eigenen Layout-Durchläufen zurück - der Park prüft jetzt hinter UpdateMicroButtons, den Fullscreen-Übergaben, Talent-/Spec-Updates, Edit-Mode-Änderungen und den Vehicle-/Override-Events nach.",
			"Jeder Enable-Schritt nach dem Bau läuft jetzt einzeln abgesichert - ein Fehler reißt die Extras (Pet-/Stance-/Totem-Bars) nicht mehr mit.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Full rework of the bar engine to the proven native architecture: every button is detached from the game's dispatch lists right after creation - the template's OnLoad had signed each button up, so the game ran its own protected writes (SetAttribute/SetShown) on our buttons under addon taint and every one of them was the 'UNKNOWN()' blocked call. That root cause is gone; no pcall can hide a blocked call, so now nothing shared ever runs on our buttons.",
			"Painting is event-driven now (no more 0.15s poll): per-painter updates on the real game events, queued to one flush per frame, plus the range watch only while a target exists.",
			"Keybinds work natively again: they press the game's hidden twin buttons and the secure page driver copies bar 1's page onto them (actionpage) - cast-on-key-down included, no override bindings. Only flyout slots are re-pointed.",
			"The game's bars are parked (reparented under a hidden frame) instead of alpha-faded; their twin buttons are unlisted and parked too so no in-fight layout pass touches them.",
			"Stance and pet bars adopt the game's own buttons (StanceButton*/PetActionButton*) - their updates, keybinds and tooltips stay the game's.",
			"Cooldowns stay secret-safe through the DurationObject path; the slot mapping now matches the client's real bar pages (bar2=6, bar3=5, bar4=3).",
		},
		changesDE = {
			"Leisten-Engine komplett auf die bewährte native Architektur umgebaut: Jeder Button wird direkt nach dem Erstellen aus den Dispatch-Listen des Spiels getragen - das Template-OnLoad hatte jeden Button eingetragen, also liefen die geschützten Schreibzugriffe des Spiels (SetAttribute/SetShown) unter Addon-Taint auf unseren Buttons und jeder war der 'UNKNOWN()'-Block. Die Ursache ist weg; kein pcall versteckt einen geblockten Call - jetzt läuft nichts Geteiltes mehr auf unseren Buttons.",
			"Das Zeichnen ist jetzt event-getrieben (kein 0.15s-Poll mehr): Pro-Painter-Updates auf die echten Spiel-Events, gebündelt in einen Flush pro Frame, plus der Range-Watch nur mit Ziel.",
			"Keybinds laufen wieder nativ: Sie drücken die versteckten Twin-Buttons des Spiels und der Secure-Page-Driver kopiert die Seite von Bar 1 auf sie (actionpage) - inklusive Cast-on-Key-Down, keine Override-Bindings. Nur Flyout-Slots werden umgelenkt.",
			"Die Leisten des Spiels werden geparkt (unter einen versteckten Frame gelegt) statt ge-alphat; auch ihre Twin-Buttons sind unlisted und geparkt, damit kein Layout-Durchlauf im Kampf sie anfasst.",
			"Stance- und Pet-Bar adoptieren die eigenen Buttons des Spiels (StanceButton*/PetActionButton*) - Updates, Keybinds und Tooltips bleiben beim Spiel.",
			"Cooldowns bleiben über den DurationObject-Pfad secret-sicher; das Slot-Mapping nutzt jetzt die echten Bar-Seiten des Clients (bar2=6, bar3=5, bar4=3).",
		},
	},
	{
		version = "0.1.22",
		changes = {
			"Fixed the action bars not loading at all (Blizzard bars visible again): the labelled Call() helper was declared below DriverHide, so Blizzard suppression called a nil global and Enable aborted before creating a single bar - leaving Core.enabled stuck on so no retry ever ran. Call/Sec are now declared at the top of the file.",
			"Fixed the duration-object reads: Call() returns its ok flag first, so GetActionCooldownDuration's object never reached the cooldown widget.",
		},
		changesDE = {
			"Actionbars luden gar nicht mehr (Blizzard-Leisten wieder sichtbar): Der Call()-Helper stand unter DriverHide, die Blizzard-Unterdrückung rief also ein nil-Global auf und Enable brach ab, bevor eine Leiste gebaut wurde - Core.enabled blieb true, kein Retry lief je. Call/Sec stehen jetzt ganz oben.",
			"DurationObject-Lesefehler gefixt: Call() gibt zuerst sein ok-Flag zurück, das Objekt von GetActionCooldownDuration kam nie beim Cooldown-Widget an.",
		},
	},
	{
		version = "0.1.21",
		changes = {
			"Fixed the 100x cooldown spam ('Cooldown.lua: attempt to compare local start (a secret number value)'): the cooldown widget now gets a DurationObject (GetActionCooldownDuration / C_DurationUtil.CreateDuration) instead of raw secret numbers - the widget handles secrets natively in C++, no Lua compare. Raw CooldownFrame_Set is only used when the values are actually readable.",
			"securecall was tested and does NOT untaint on this client - removed from the cooldown path.",
		},
		changesDE = {
			"Der 100x Cooldown-Spam gefixt ('Cooldown.lua: attempt to compare local start (a secret number value)'): Der Cooldown-Widget bekommt jetzt ein DurationObject (GetActionCooldownDuration / C_DurationUtil.CreateDuration) statt roher Secret-Werte - das Widget verarbeitet Secrets nativ in C++, ohne Lua-Vergleich. Rohes CooldownFrame_Set läuft nur noch bei wirklich lesbaren Werten.",
			"securecall wurde getestet und ent-taintet auf diesem Client NICHT - aus dem Cooldown-Pfad entfernt.",
		},
	},
	{
		version = "0.1.20",
		changes = {
			"Cooldown and tooltip calls that touch secret values internally now run through securecall (untainted) - fixes 'attempt to compare local start (a secret number value)' in the client's cooldown code and the resulting blocked/forbidden spam.",
		},
		changesDE = {
			"Cooldown- und Tooltip-Calls, die intern geheime Werte anfassen, laufen jetzt über securecall (untainted) - fixt 'attempt to compare local start (a secret number value)' im Cooldown-Code des Clients und den entstehenden blocked/forbidden-Spam.",
		},
	},
	{
		version = "0.1.19",
		changes = {
			"Every engine call in the module now runs through a labelled wrapper that tracks the current call site - since ADDON_ACTION_FORBIDDEN fires synchronously, the chat now names the exact call that got blocked (e.g. 'forbidden during GameTooltip:SetAction') instead of UNKNOWN().",
		},
		changesDE = {
			"Jeder Engine-Call im Modul läuft jetzt durch einen gelabelten Wrapper, der die aktuelle Aufrufstelle mitführt - da ADDON_ACTION_FORBIDDEN synchron feuert, nennt der Chat jetzt den exakten blockierten Call (z.B. 'forbidden during GameTooltip:SetAction') statt UNKNOWN().",
		},
	},
	{
		version = "0.1.18",
		changes = {
			"The blocked-api diagnostic now also shows the bug tracker hint (https://dev.xrl-dev.de/bugtracker).",
		},
		changesDE = {
			"Die blocked-api-Diagnose zeigt jetzt auch den Bugtracker-Hinweis (https://dev.xrl-dev.de/bugtracker).",
		},
	},
	{
		version = "0.1.17",
		changes = {
			"If the module enables during combat (e.g. /reload mid-fight), bar construction is deferred until combat ends - frames created during lockdown are born protected and every layout call would fire ADDON_ACTION_FORBIDDEN.",
		},
		changesDE = {
			"Wenn das Modul im Kampf aktiviert wird (z.B. /reload im Kampf), wird der Leistenbau bis zum Kampfende verschoben - im Lockdown erstellte Frames werden protected geboren und jeder Layout-Call würde ADDON_ACTION_FORBIDDEN feuern.",
		},
	},
	{
		version = "0.1.16",
		changes = {
			"Fixed the ADDON_ACTION_FORBIDDEN spam: GetBindingKey/GetBindingText are now read once per binding change instead of ~320x/sec in the refresh tick - binding queries from insecure code are restricted on this client.",
			"Every client API read in the button update is now labelled - if another protected call ever fires, the error names the exact API instead of UNKNOWN().",
		},
		changesDE = {
			"ADDON_ACTION_FORBIDDEN-Spam gefixt: GetBindingKey/GetBindingText werden jetzt einmal pro Binding-Änderung gelesen statt ~320x/Sek im Refresh-Tick - Binding-Abfragen aus insecurem Code sind auf diesem Client eingeschränkt.",
			"Jeder Client-API-Read im Button-Update ist jetzt gelabelt - falls noch ein protected Call feuert, nennt der Fehler die genaue API statt UNKNOWN().",
		},
	},
	{
		version = "0.1.15",
		changes = {
			"SetFont rounds sizes first - the client rejects float font sizes and silently leaves the FontString without a font.",
		},
		changesDE = {
			"SetFont rundet Größen jetzt - der Client lehnt Float-Schriftgrößen ab und lässt den FontString ohne Schrift.",
		},
	},
	{
		version = "0.1.14",
		changes = {
			"The combat checked-state path no longer calls GetCheckedTexture on the protected button - the texture is captured at creation.",
		},
		changesDE = {
			"Der Kampf-Checked-Pfad ruft kein GetCheckedTexture mehr auf dem geschützten Button auf - die Textur wird bei der Erstellung gespeichert.",
		},
	},
	{
		version = "0.1.13",
		changes = {
			"Stopped the repeating \"forbidden call\" reports: the button tick no longer calls restricted methods on protected buttons in combat (checked state only on change via the texture, cached hotkeys, layouts deferred to after combat).",
			"More secret-value guards in the pet/stance/totem updates - IsSecret is checked before any comparison.",
		},
		changesDE = {
			"Die wiederholten \"forbidden call\"-Meldungen gestoppt: Der Button-Tick ruft im Kampf keine beschränkten Methoden mehr auf geschützten Buttons auf (Checked-Zustand nur bei Änderung über die Textur, Hotkeys gecacht, Layouts auf nach dem Kampf verschoben).",
			"Mehr Secret-Wert-Guards in den Begleiter-/Haltungs-/Totem-Updates - IsSecret wird vor jedem Vergleich geprüft.",
		},
	},
	{
		version = "0.1.12",
		changes = {
			"Vehicle exit and taxi landing buttons show Sentinel icons now instead of red text.",
		},
		changesDE = {
			"Fahrzeug-Ausstieg und Taxi-Landung zeigen jetzt Sentinel-Icons statt rotem Text.",
		},
	},
	{
		version = "0.1.11",
		changes = {
			"Internal error reports use S.Stack now - the real traceback prints instead of \"error in error handling\".",
		},
		changesDE = {
			"Interne Fehlermeldungen nutzen jetzt S.Stack - der echte Traceback erscheint statt \"error in error handling\".",
		},
	},
	{
		version = "0.1.10",
		changes = {
			"Release history is now filed for the in-game changelog (SentiUI > Changelog, English + German).",
		},
		changesDE = {
			"Die Versionshistorie ist jetzt im In-Game-Changelog eingetragen (SentiUI > Changelog, Englisch + Deutsch).",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"Stance bar capped at the real form/stance count - no more phantom buttons on characters without forms, and it still grows as stances are learned.",
		},
		changesDE = {
			"Haltungsleiste auf die echte Form-/Haltungsanzahl begrenzt - keine Phantom-Buttons mehr ohne Formen, und sie wächst weiter automatisch mit.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Removed the micro menu bar: the minimap menu already covers the game menu and the client does not expose usable button icons.",
		},
		changesDE = {
			"Micro-Leiste entfernt: Das Minimap-Menü deckt das Spielmenü ab und der Client liefert keine brauchbaren Button-Icons.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Micro bar rebuilt on own Sentinel buttons forwarding clicks to the hidden Blizzard buttons via /click.",
		},
		changesDE = {
			"Micro-Leiste neu: eigene Sentinel-Buttons leiten Klicks per /click an die versteckten Blizzard-Buttons weiter.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Fixed \"hide when empty\": HasAction returns secret values on this client - the check now looks for an action texture, so empty bars actually vanish.",
		},
		changesDE = {
			"\"Verstecken wenn leer\" gefixt: HasAction liefert auf diesem Client Secret-Werte - jetzt zählt die Aktions-Textur, und leere Leisten verschwinden wirklich.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"New \"Vertical\" option on every bar: action bars fill columns, pet/stance/totem bars stack downward.",
			"New micro bar with the Blizzard menu buttons reparented into a movable Sentinel bar.",
		},
		changesDE = {
			"Neue \"Vertikal\"-Option auf jeder Leiste: Aktionsleisten füllen Spalten, Begleiter-/Haltungs-/Totem-Leisten stapeln nach unten.",
			"Neue Micro-Leiste mit den Blizzard-Menübuttons in einer verschiebbaren Sentinel-Leiste.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Internal error reports now include a Lua traceback - the failing file and line show in chat.",
		},
		changesDE = {
			"Interne Fehlermeldungen zeigen jetzt einen Lua-Traceback - Datei und Zeile stehen im Chat.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Buttons now use the native C_ActionBar.* API: real cooldown sweeps via DurationObject, display counts, and the checked glow on active abilities.",
		},
		changesDE = {
			"Buttons nutzen jetzt die native C_ActionBar.*-API: echte Cooldown-Sweeps per DurationObject, Anzeigezahlen und der Aktiv-Glow auf laufenden Fähigkeiten.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"New per-bar option \"Hide when empty\" (default on for bars 2-4): no more dark empty rows.",
		},
		changesDE = {
			"Neue Option \"Verstecken wenn leer\" pro Leiste (Standard: an für Leiste 2-4): keine dunklen Leerreihen mehr.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"The client's Cooldown Manager viewers (Essential/Utility/BuffIcon/BuffBar) are suppressed too - they load on demand, so suppression re-runs after every addon load.",
		},
		changesDE = {
			"Die Cooldown-Manager-Anzeigen des Clients (Essential/Utility/BuffIcon/BuffBar) werden ebenfalls unterdrückt - sie laden bei Bedarf, also läuft die Unterdrückung nach jedem Addon-Load erneut.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release, ported from the proven SentinelForeverCore implementation.",
			"Bar 1 pages through druid forms, warrior stances, stealth, shadowform, monk/evoker states, vehicles, override and possess bars.",
			"Bars 2-4 on the free pages, pet bar, stance bar, totem bar, extra/zone buttons, vehicle exit and taxi landing.",
			"Secure buttons with drag & drop, key binds, hotkey/count/macro text, range coloring and tooltips; all bars are movers.",
		},
		changesDE = {
			"Erste Version, portiert aus der bewährten SentinelForeverCore-Umsetzung.",
			"Leiste 1 blättert durch Druidenformen, Kriegerhaltungen, Verstohlenheit, Schattengestalt, Mönch-/Evoker-Zustände, Fahrzeug-, Override- und Possess-Leisten.",
			"Leisten 2-4 auf den freien Seiten, Begleiter-, Haltungs- und Totemleiste, Extra-/Zonen-Buttons, Fahrzeugausstieg und Taxi-Landung.",
			"Sichere Buttons mit Drag & Drop, Tastenbelegung, Hotkey-/Anzahl-/Makrotext, Reichweitenfärbung und Tooltips; alle Leisten sind Mover.",
		},
	},
}
