local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.40",
		changes = {
			"Offline status delay fixes: the 30s join grace now runs BEFORE the friend/guild roster corroboration - those flags update on their own cadence and reported joiners as offline, so guildies and friends still flashed offline despite the grace. Roster updates now repaint all group frames (coalesced over 0.5s so mass joins do not hitch), and the stale-offline revalidation ticker polls every second instead of every four.",
		},
		changesDE = {
			"Offline-Status-Delay-Fixes: Die 30s-Join-Gnadenfrist greift jetzt VOR der Freundes-/Gilden-Korrobation - deren Flags aktualisieren in eigenem Takt und meldeten Joiner als offline, sodass Gildenmitglieder und Freunde trotz Gnadenfrist weiter offline blinkten. Roster-Updates repainten jetzt alle Gruppen-Frames (auf 0,5s gebuendelt, damit Mass-Joins nicht ruckeln), und der Stale-Offline-Ticker pollt jede Sekunde statt alle vier.",
		},
	},
	{
		version = "0.2.39",
		date = "2026-11-23",
		changes = {
			"Party members joining no longer stick on 'offline': the client keeps conn=false through the join handshake, so new roster names now get a 30s join grace before the offline label may show. Friends and guild rosters act as extra online sources when the raid roster does not cover party members, and a slow 4s revalidation repaints offline-marked frames so a silently healing conn clears the state without an event.",
		},
		changesDE = {
			"Beitretende Gruppenmitglieder kleben nicht mehr auf 'offline': der Client hält conn=false durch den Join-Handshake, neue Roster-Namen bekommen deshalb 30s Join-Gnadenfrist, bevor das Offline-Label erscheinen darf. Freundes- und Gildenroster liefern zusätzliche Online-Quellen, wo der Raid-Roster Party-Mitglieder nicht abdeckt, und ein langsamer 4s-Revalidation-Ticker repaintet offline-markierte Frames, damit ein still heilender conn auch ohne Event gelöscht wird.",
		},
	},
	{
		version = "0.2.38",
		date = "2026-11-23",
		changes = {
			"Offline check gets a second opinion for out-of-sight members too: when UnitIsConnected reads false for a raid member we cannot see, the raid roster's own online flag decides before the frame greys out.",
		},
		changesDE = {
			"Offline-Check bekommt auch für unsichtbare Mitglieder eine zweite Meinung: liest UnitIsConnected bei einem Raid-Mitglied false, das wir nicht sehen können, entscheidet das Online-Flag des Raid-Rosters, bevor der Frame abgedunkelt wird.",
		},
	},
	{
		version = "0.2.37",
		date = "2026-11-23",
		changes = {
			"Members no longer stick on 'offline' while online: UnitIsConnected can return plainly-false for visible units on this client, so the check now double-checks via UnitIsVisible (a unit we can see is online by definition), holds the flag for 3s to survive zoning flicker, and the name text is restored when the member reads connected again.",
		},
		changesDE = {
			"Mitglieder bleiben nicht mehr auf 'offline' kleben, obwohl sie online sind: UnitIsConnected kann auf diesem Client für sichtbare Einheiten fälschlich false liefern - der Check prüft jetzt per UnitIsVisible gegen (eine sichtbare Einheit ist per Definition online), hält das Flag 3s gegen Zonen-Flackern und der Namenstext wird restauriert, sobald das Mitglied wieder als verbunden gelesen wird.",
		},
	},
	{
		version = "0.2.36",
		date = "2026-11-23",
		changes = {
			"Castbar visual pass (player/target - covers interact casts like opening chests): raised panel with the 0.70-alpha gold border of the frames, darker unfilled area + glass sheen, spell icon in its own inset tile, uninterruptible shield as a badge on the icon corner.",
			"Empower cast events added so empower spells drive the castbar too.",
		},
		changesDE = {
			"Castleisten-Optik (Spieler/Ziel - deckt auch Interaktions-Casts wie Truhen oeffnen ab): raised-Panel mit dem 0.70-Alpha-Goldrand der Frames, dunklerer unfuellter Bereich + Glasreflex, Zauber-Icon in eigener Inset-Kachel, Unterbrechbarkeits-Schild als Badge auf der Icon-Ecke.",
			"Empower-Cast-Events ergaenzt, damit Empower-Zauber die Castleiste auch treiben.",
		},
	},
	{
		version = "0.2.35",
		date = "2026-11-23",
		changes = {
			"Layout fix: bars now inset 4px from all edges so they sit cleanly inside the PillEdge backdrop fill area (not bleeding into the gold border). Health top y=-4 (was -1), power bottom y=4 (was 1).",
			"Removed AccentLine and BottomLine interior textures from player/target frames.",
			"Player/target backdrop border alpha raised from 0.45 to 0.70.",
			"healthTextMode migration: BOTH (old default) auto-updated to VALUE on first load.",
		},
		changesDE = {
			"Layout-Fix: Leisten jetzt 4px von allen Raendern eingerueckt, damit sie sauber im PillEdge-Backdrop-Bereich sitzen. Health oben y=-4 (war -1), Power unten y=4 (war 1).",
			"AccentLine und BottomLine interne Texturen von Spieler-/Ziel-Frames entfernt.",
			"Spieler-/Ziel-Backdrop-Rand-Alpha von 0.45 auf 0.70 erhoehen.",
			"healthTextMode-Migration: BOTH (alter Standard) wird beim ersten Laden automatisch auf VALUE aktualisiert.",
		},
	},
	{
		version = "0.2.34",
		date = "2026-11-23",
		changes = {
			"Visual overhaul - player/unit/party/raid frames: HP text shows absolute value (no percent). Power bar 8px for player/target. Bar bg opacity 0.55->0.65. Class colour dimmed 12% on health bars. Glass sheen 0.14->0.20. CornerCut on health (r3) and power (r2) bars for rounded pill ends. Top gold accent 90% alpha. New 1px bottom gold closure line. Portrait separator.",
		},
		changesDE = {
			"Visuelle Ueberarbeitung - Spieler-/Einheits-/Gruppen-/Raid-Frames: HP-Text zeigt absoluten Wert (kein Prozent). Power-Leiste 8px fuer Spieler/Ziel. Leisten-BG-Opazitaet 0.55->0.65. Klassenfarbe auf Gesundheitsbalken um 12% gedaempft. Glasreflex 0.14->0.20. CornerCut auf Gesundheits- (r3) und Mana-Leiste (r2) fuer abgerundete Pill-Enden. Obere Goldlinie 90% Alpha. Neue 1px untere Gold-Abschlusslinie. Portrait-Trenner.",
		},
	},
	{
		version = "0.2.33",
		date = "2026-11-23",
		changes = {
			"Aggro/threat/dispel border strips still partially hidden: EdgeGlow container g was at f:GetFrameLevel()+6, below the text-holder frame th at f:GetFrameLevel()+8. th has SetAllPoints() and sits higher in Z-order, covering the strips. Fixed: EdgeGlow raised to f:GetFrameLevel()+10, above all internal unit-frame layers (portrait +2, bars +1, text-holder +8).",
		},
		changesDE = {
			"Aggro-/Threat-/Dispel-Rahmen-Streifen noch teilweise versteckt: EdgeGlow-Container g war bei f:GetFrameLevel()+6, unterhalb des Text-Holder-Frames th bei f:GetFrameLevel()+8. th hat SetAllPoints() und liegt hoeher im Z-Order und verdeckte die Streifen. Fix: EdgeGlow auf f:GetFrameLevel()+10 angehoben, ueber allen internen Unit-Frame-Ebenen (Portrait +2, Leisten +1, Text-Holder +8).",
		},
	},
	{
		version = "0.2.32",
		date = "2026-11-23",
		changes = {
			"Aggro/threat border incomplete: ns.EdgeGlow keyed strips by their first anchor point (p1). Both the top horizontal strip (TOPLEFT->TOPRIGHT) and the left vertical strip (TOPLEFT->BOTTOMLEFT) share 'TOPLEFT' as p1, so the left strip silently overwrote the top in g.strips. SetEdgeColor colored only left/bottom/right; the top strip stayed white/invisible. Fixed: array indices (#g.strips+1) ensure all four strips are stored and colored.",
		},
		changesDE = {
			"Aggro-/Threat-Rahmen unvollständig: ns.EdgeGlow schlüsselte Streifen über ihren ersten Ankerpunkt (p1). Sowohl der obere horizontale Streifen (TOPLEFT->TOPRIGHT) als auch der linke vertikale Streifen (TOPLEFT->BOTTOMLEFT) teilen 'TOPLEFT' als p1 - der linke Streifen überschrieb den oberen in g.strips. SetEdgeColor färbte nur links/unten/rechts; der obere Streifen blieb weiß/unsichtbar. Fix: Array-Indizes (#g.strips+1) stellen sicher, dass alle vier Streifen gespeichert und gefärbt werden.",
		},
	},
	{
		version = "0.2.31",
		date = "2026-11-23",
		changes = {
			"Player and target frames use the 'raised' panel style: Sentinel gold border tint and lifted bgRaised background give them visual prominence over secondary frames (pet, focus, tot, party, raid) which stay on 'panel'. A 2px gold top accent line is added to player and target frames.",
		},
		changesDE = {
			"Spieler- und Ziel-Frames nutzen jetzt den 'raised'-Panel-Stil: Sentinel-Gold-Border-Tint und angehobener bgRaised-Hintergrund geben ihnen visuelle Prominenz gegenüber sekundären Frames (Begleiter, Fokus, ZdZ, Party, Raid), die auf 'panel' bleiben. Eine 2px-Gold-Akzentlinie wird Spieler- und Ziel-Frame hinzugefügt.",
		},
	},
	{
		version = "0.2.30",
		date = "2026-11-22",
		changes = {
			"EdgeGlow (threat/dispel ring on unit frames) replaced with a simple square 4-strip border - no corner arcs, no OnSizeChanged complexity, immune to the chevron geometry bug on short bars. CastBar CornerCut removed to match the flat bar style.",
		},
		changesDE = {
			"EdgeGlow (Threat-/Dispel-Ring auf Unit-Frames) durch einen einfachen quadratischen 4-Streifen-Rand ersetzt - keine Eck-Boegen, keine OnSizeChanged-Komplexitaet, kein Chevron-Geometrie-Bug auf kurzen Balken. CastBar-CornerCut entfernt um dem flachen Balken-Stil zu entsprechen.",
		},
	},
	{
		version = "0.2.29",
		date = "2026-11-22",
		changes = {
			"Threat/dispel edge ring on short frames: ns.EdgeGlow now clamps the corner inset to half the frame height and (re)builds strips+arcs via OnSizeChanged once the frame has a real size - previously radius-7 arcs overlapped on ~12px bars and rendered as pointed pink chevrons at the bar ends while the side strips collapsed.",
		},
		changesDE = {
			"Threat-/Dispel-Ring auf kurzen Frames: ns.EdgeGlow klemmt den Eck-Inset jetzt auf die halbe Frame-Hoehe und (re)baut Streifen+Boegen ueber OnSizeChanged sobald der Frame echte Masse hat - vorher ueberlappten Radius-7-Boegen auf ~12px-Balken und zeichneten als spitze pinke Klammern an den Balkenenden, waehrend die Seitenstreifen zusammenfielen.",
		},
	},
	{
		version = "0.2.28",
		date = "2026-11-22",
		changes = {
			"Generated icons wired in: role icons use the RoleTank/RoleHeal/RoleDps glyph files instead of the Blizzard atlas texcoords, the leader crown uses LeaderIcon.tga, resting/combat use RestingIcon/CombatIcon.tga, and every aura tile gets the thin IconBorder ring. Fix: AbsorbBar.tga was dark-based and muddied the shield overlay - reverted to the pale band; IncomingHeal.tga is already green so it tints white now instead of double-darkening.",
		},
		changesDE = {
			"Generierte Icons verdrahtet: Rollen-Icons nutzen die RoleTank/RoleHeal/RoleDps-Glyph-Dateien statt des Blizzard-Atlas-TexCoords, die Leader-Krone LeaderIcon.tga, Ruhe/Kampf RestingIcon/CombatIcon.tga, und jede Auren-Kachel bekommt den duennen IconBorder-Ring. Fix: AbsorbBar.tga war dunkel basiert und trübte das Schild-Overlay - zurueck zur hellen Bande; IncomingHeal.tga ist bereits gruen und tont jetzt weiss statt doppelt abzudunkeln.",
		},
	},
	{
		version = "0.2.27",
		date = "2026-11-22",
		changes = {
			"Generated media wired in: threat/dispel rings now use the ThreatGlow.tga edgeFile - one anti-aliased border texture replaces the strip+arc raster, so the outline is bilinear-smooth at every size. The cast bar spark uses BarSpark.tga (soft glow instead of a hard 2px line), the uninterruptible shield uses CastShield.tga, and heal-prediction/absorb overlays ride the IncomingHeal/AbsorbBar textures. Every asset is probed and falls back to the rastered look when missing.",
		},
		changesDE = {
			"Generierte Media verdrahtet: Bedrohungs-/Dispel-Ringe nutzen jetzt die ThreatGlow.tga-EdgeFile - eine geglattete Bordueren-Textur ersetzt die Streifen+Bogen-Rasterung, die Kontur ist bei jeder Groesse bilinear glatt. Der Zauberleisten-Funke nutzt BarSpark.tga (weiches Glühen statt harter 2px-Linie), das Unterbrechungs-Schild CastShield.tga, und Heil-Vorhersage/Absorb fahren auf den IncomingHeal-/AbsorbBar-Texturen. Jedes Asset wird geprobt und faellt bei Fehlen auf das rasterte Aussehen zurueck.",
		},
	},
	{
		version = "0.2.26",
		date = "2026-11-22",
		changes = {
			"Bar corner caps moved to OVERLAY sublevel 7: the sheen overlay created after the bars drew over the caps and poked a faint white tip into every rounded corner - visible pixel errors on player, target, target-of-target, pet, focus, party and raid bars. The cast bar caps get the same pin.",
		},
		changesDE = {
			"Balken-Eckkappen auf OVERLAY-Sublevel 7 gehoben: der nach den Leisten erzeugte Glanz-Overlay zeichnete ueber die Kappen und ragte als helle weisse Spitze in jede abgerundete Ecke - sichtbare Pixelfehler auf Spieler-, Ziel-, Ziel-des-Ziels-, Begleiter-, Fokus-, Party- und Raid-Leisten. Die Zauberleisten-Kappen bekommen denselben Pin.",
		},
	},
	{
		version = "0.2.25",
		date = "2026-11-22",
		changes = {
			"Edge glow corners: the threat highlight and dispel-type border were four strips ending 7px short of every corner - rasterized quarter arcs (new core S.EdgeArc) now close the outline, and SetEdgeColor recolors strips and arcs together so threat states and dispel types keep one continuous ring.",
		},
		changesDE = {
			"Edge-Glow-Ecken: Bedrohungs-Markierung und Dispel-Typ-Rahmen waren vier Streifen, die 7px vor jeder Ecke endeten - rasterte Viertelboegen (neuer Core-Helper S.EdgeArc) schliessen die Kontur jetzt, und SetEdgeColor faerbt Streifen und Boegen gemeinsam: Bedrohungsstufen und Dispel-Typen behalten einen durchgehenden Ring.",
		},
	},
	{
		version = "0.2.24",
		date = "2026-11-22",
		changes = {
			"Rounded bars: health and power bars now read as rounded rects - anti-aliased caps in the panel color cover the corner notches (new core S.CornerCut). Applies to every frame sharing the bar plumbing: player, target, target-of-target, pet, focus, party and raid.",
			"Cast bar fill ends rounded the same way with inset-colored caps; the alternate power bar picks up the look automatically.",
		},
		changesDE = {
			"Abgerundete Leisten: Gesundheits- und Ressourcenleisten wirken jetzt als abgerundete Rechtecke - geglattete Kappen in Panel-Farbe decken die Eckkerben ab (neuer Core-Helper S.CornerCut). Gilt fuer alle Frames mit der Leisten-Plumbing: Spieler, Ziel, Ziel-des-Ziels, Begleiter, Fokus, Party und Raid.",
			"Zauberleisten-Enden ebenfalls abgerundet mit Kappen in Inset-Farbe; die alternative Ressourcenleiste uebernimmt den Look automatisch.",
		},
	},
	{
		version = "0.2.23",
		date = "2026-11-22",
		changes = {
			"Portrait tile now sits centered in the left edge (2px inset, clear of the corner arcs), and both bars share one flush left edge right of it - the power bar no longer runs underneath. Both bars also end 4px before the right edge: the square power bar otherwise poked past the panel's rounded bottom-right corner and looked longer than the health bar.",
		},
		changesDE = {
			"Porträt-Kachel sitzt jetzt zentriert am linken Rand (2px eingesetzt, frei von den Eckbögen), beide Leisten teilen sich eine bündige linke Kante rechts davon - die Ressourcenleiste läuft nicht mehr darunter. Beide Leisten enden außerdem 4px vor der rechten Kante: der eckige Ressourcenbalken ragte sonst über die abgerundete rechte untere Ecke des Panels hinaus und wirkte länger als die Gesundheitsleiste.",
		},
	},
	{
		version = "0.2.22",
		date = "2026-11-22",
		changes = {
			"Portrait tile for party and raid frames (Unit Frames > Party / Raid): the shared portrait machinery is now offered on the group cells too - a square tile on the left edge showing the class icon for players or the engine's 3D portrait for everything else (and in model mode for all units). Party defaults to the class icon; raid stays off by default since cells are small. The health bar shifts right to make room; the option flips live without a reload.",
			"Fix: portrait tiles rendered as empty dark squares. The icon was only painted during a full Refresh, but Configure builds the tile lazily after the first Refresh (party layout, late raid children) and unit events never call UpdatePortrait - the icon is now painted inside Configure and re-painted on UNIT_PORTRAIT_UPDATE. Also the class icon atlas switched to the WorldStateFrame Icons-Classes sheet that actually ships on this client.",
		},
		changesDE = {
			"Porträt-Kachel für Party- und Raid-Frames (Einheitenfenster > Party / Raid): die vorhandene Porträt-Mechanik gibt es jetzt auch auf den Gruppen-Zellen - eine quadratische Kachel am linken Rand mit dem Klassen-Icon für Spieler oder dem 3D-Porträt der Engine für alles andere (im Model-Modus für alle Einheiten). Party steht standardmäßig auf Klassen-Icon; Raid bleibt standardmäßig aus, da die Zellen klein sind. Die Gesundheitsleiste rückt zur Seite, um Platz zu schaffen; die Option greift ohne Reload.",
			"Fix: Porträt-Kacheln blieben leere dunkle Quadrate. Das Icon wurde nur beim vollen Refresh gemalt, Configure baut die Kachel aber erst nach dem ersten Refresh (Party-Layout, späte Raid-Kinder) und Unit-Events rufen UpdatePortrait nie - das Icon wird jetzt direkt im Configure gemalt und bei UNIT_PORTRAIT_UPDATE neu gesetzt. Außerdem nutzt das Klassen-Icon jetzt die WorldStateFrame-Icons-Classes-Datei, die auf diesem Client wirklich existiert.",
		},
	},
	{
		version = "0.2.21",
		date = "2026-11-22",
		changes = {
			"New raid tools tray (Unit Frames > Raid): a slim tab docked to the top screen edge unfolds a tray with target markers, world markers, ready check and a 10s pull timer - visible only while grouped. Click the tab to fold the tray away (works in combat); the fold state is remembered. Marker buttons run through the client's own /tm and /wm slash commands in the secure macro path, so no protected calls leave addon code.",
			"Alternate power bar: a SentiUI bar replaces the parked PlayerPowerBarAlt - it watches the encounter power index via UnitPower/UnitPowerMax (secret-safe, values feed the widget raw) and shows name and percent while a bar is active. Movable via its own mover.",
			"External defensive indicators on party and raid cells: small corner icons fed by an engine AuraContainer filtered to HELPFUL|EXTERNAL_DEFENSIVE (pain suppression, ironbark, ...), so the icons render even while aura data is secret.",
		},
		changesDE = {
			"Neue Raid-Werkzeugleiste (Einheitenfenster > Raid): eine schmale Leiste am oberen Bildschirmrand klappt eine Ablage mit Zielmarken, Weltmarken, Bereitschaftscheck und 10s-Pull-Timer aus - nur in der Gruppe sichtbar. Klick auf die Leiste klappt die Ablage weg (funktioniert im Kampf); der Zustand bleibt gespeichert. Die Marken-Buttons laufen über die /tm- und /wm-Kommandos des Clients im sicheren Makro-Pfad - keine geschützten Aufrufe aus Addon-Code.",
			"Alternative Kraftleiste: eine SentiUI-Leiste ersetzt die versteckte PlayerPowerBarAlt - sie überwacht den Encounter-Kraftindex über UnitPower/UnitPowerMax (secret-sicher, Werte gehen roh ins Widget) und zeigt Name und Prozent, solange eine Leiste aktiv ist. Über eigenen Mover verschiebbar.",
			"Externe Defensiv-Indikatoren auf Party- und Raid-Zellen: kleine Eck-Icons aus einem Engine-AuraContainer mit Filter HELPFUL|EXTERNAL_DEFENSIVE (Schmerzunterdrückung, Eisenborke, ...) - die Icons rendern auch bei geheimen Aura-Daten.",
		},
	},
	{
		version = "0.2.20",
		date = "2026-11-22",
		changes = {
			"Fixed the dark blob hanging below the unit frame: the aura tile's dark fill was registered with the engine's dispel-type texture system with showWithoutDispelType = true. The engine may scale a managed dispel texture past the button bounds, so an always-on dark one rendered as a lumpy dark mass under every debuff row. The tile fill is now an unmanaged texture, and the engine-managed dispel overlay only appears with a real dispel type (tinted by type).",
			"Heal prediction and absorb bars showed far too small: the band anchors at the health fill's right edge so it only spans the missing-health region, but its scale used UnitHealthMax - the fill came out (max-cur)/max times too small (a sliver at high health). The scale now uses UnitHealthMissing with a UnitHealthMax fallback, secret-safe.",
		},
		changesDE = {
			"Dunkle Masse unter dem Einheitenfenster behoben: die dunkle Fuellung der Auren-Kachel war beim Engine-Dispel-System mit showWithoutDispelType = true registriert. Die Engine kann verwaltete Dispel-Texturen ueber den Button hinaus skalieren - eine dauerhaft sichtbare dunkle Textur ergab eine klumpige Masse unter jeder Debuff-Reihe. Die Kachel-Fuellung ist jetzt eine unverwaltete Textur, das Engine-Dispel-Overlay erscheint nur bei echtem Dispel-Typ (typgefaerbt).",
			"Heilungs-Prognose und Absorb-Balken zeigten viel zu wenig: die Band haengt an der rechten Kante der Health-Fuellung und deckt nur den fehlenden Bereich ab, skalierte aber mit UnitHealthMax - die Fuellung kam (max-cur)/max mal zu klein raus (ein Fliz bei hoher HP). Die Skala nutzt jetzt UnitHealthMissing mit UnitHealthMax-Fallback, secret-sicher.",
		},
	},
	{
		version = "0.2.19",
		date = "2026-11-22",
		changes = {
			"New portrait option per single frame (Unit Frames > Player & Target): Off, Class icon or 3D portrait. The portrait is a rounded tile inside the left edge, sized to the health bar's height; the health bar starts right of it while the power bar keeps full width. 'Class icon' shows the class emblem from the UI-CHARACTERCREATE-CLASSES atlas for players and falls back to the engine's 3D portrait for creatures or when the class is secret; '3D portrait' uses SetPortraitTexture for every unit. Player and target default to the class icon. The tile builds lazily so the option applies live without a reload.",
		},
		changesDE = {
			"Neue Portraet-Option pro Einzelframe (Einheitenfenster > Spieler & Ziel): Aus, Klassen-Icon oder 3D-Portraet. Das Portraet ist eine gerundete Kachel am linken Rand in Health-Bar-Hoehe; die Lebensleiste beginnt rechts davon, die Ressourcenleiste behaelt volle Breite. 'Klassen-Icon' zeigt das Klassen-Emblem aus dem UI-CHARACTERCREATE-CLASSES-Atlas fuer Spieler und faellt bei Kreaturen oder geheimer Klasse auf das 3D-Portraet der Engine zurueck; '3D-Portraet' nutzt SetPortraitTexture fuer jede Einheit. Spieler und Ziel nutzen standardmaessig das Klassen-Icon. Die Kachel wird erst bei Bedarf gebaut, die Option gilt also live ohne Reload.",
		},
	},
	{
		version = "0.2.18",
		date = "2026-11-22",
		changes = {
			"Threat highlight redesigned: the square backdrop ring behind the frame is gone - a new ns.EdgeGlow draws four thin strips that follow the rounded panel silhouette (inset past the corner arc), colored red/orange by threat state. The dispel-type border on group frames uses the same edge glow instead of a square backdrop edge.",
			"Ambient bar tints: health and power bar backdrops pick up a whisper of the health/power color instead of flat black (secret-safe - skipped when the client hides the rgb).",
			"Aura icons clip to soft rounded corners via S.IconRound, and the dispel-type background shares the same mask so the whole aura tile keeps one rounded silhouette. The cast bar icon is clipped the same way, and the cast bar fill rides a warm spark at its leading edge. The class-colored health blade is inset past the corner arc.",
		},
		changesDE = {
			"Bedrohungs-Markierung neu: der eckige Backdrop-Ring hinter dem Frame ist weg - ein neuer ns.EdgeGlow zeichnet vier duenne Streifen, die der gerundeten Panel-Silhouette folgen (hinter den Eckbogen eingesetzt), je nach Bedrohung rot/orange gefaerbt. Der Dispel-Typ-Rahmen der Gruppenframes nutzt denselben Edge-Glow statt einer eckigen Backdrop-Kante.",
			"Ambient-Balkentints: Health- und Power-Hintergruende nehmen einen Hauch der Balkenfarbe an statt flachem Schwarz (secret-sicher - uebersprungen wenn der Client das rgb versteckt).",
			"Auren-Icons werden ueber S.IconRound auf weich runde Ecken geclippt, der Dispel-Hintergrund teilt sich dieselbe Maske - die ganze Auren-Kachel behaelt eine runde Silhouette. Das Zauberleisten-Icon wird genauso geclippt, die Fuellung traegt einen warmen Funken an ihrer Spitze. Die klassenfarbene Health-Klinge ist hinter den Eckbogen eingesetzt.",
		},
	},
	{
		version = "0.2.17",
		changes = {
			"Dispatcher rollback: PLAYER_TARGET_CHANGED/PLAYER_FOCUS_CHANGED/RAID_TARGET_UPDATE events are back; the poll is the plain targettarget poll again.",
		},
		changesDE = {
			"Dispatcher-Rollback: PLAYER_TARGET_CHANGED/PLAYER_FOCUS_CHANGED/RAID_TARGET_UPDATE-Events sind zurueck; der Poll ist wieder der schlichte TargetTarget-Poll.",
		},
	},
	{
		version = "0.2.16",
		changes = {
			"ESC-forbidden-call hardening: PLAYER_TARGET_CHANGED, PLAYER_FOCUS_CHANGED and RAID_TARGET_UPDATE removed - they fire inside the protected input dispatch (ESC deselect/unmark), tainting the client's follow-up protected calls. The existing 0.5s poll now watches target/focus GUIDs and a raid-mark signature instead and triggers the same refreshes.",
		},
		changesDE = {
			"ESC-Blockier-Härtung: PLAYER_TARGET_CHANGED, PLAYER_FOCUS_CHANGED und RAID_TARGET_UPDATE entfernt - sie feuern im geschützten Input-Dispatch (ESC-Abwählen/Markierung lösen) und tainten die folgenden geschützten Aufrufe. Der vorhandene 0,5s-Poll überwacht jetzt Ziel-/Fokus-GUIDs und eine Raid-Marken-Signatur und löst dieselben Refreshes aus.",
		},
	},
	{
		version = "0.2.15",
		changes = {
			"Group members no longer show as Offline while they are online: UnitIsConnected can return a secret boolean on this client, which read as nil and flipped every check to 'offline'. Only a plainly-false result now marks a unit offline.",
		},
		changesDE = {
			"Gruppenmitglieder werden nicht mehr als Offline angezeigt, obwohl sie online sind: UnitIsConnected kann auf diesem Client einen Secret-Boolean liefern, der als nil gelesen wurde und jeden Check auf 'offline' drehte. Nur ein eindeutig false lesbarer Wert markiert eine Einheit jetzt als offline.",
		},
	},
	{
		version = "0.2.14",
		changes = {
			"Cast bar fill is now driven per frame off the engine duration object (UnitCastingDuration) instead of relying on SetTimerDuration alone - the raw (possibly secret) getter values go straight into the status bar, so the fill animates even where the engine call accepts the duration but never repaints.",
		},
		changesDE = {
			"Der Castbalken wird jetzt pro Frame direkt aus dem Duration-Objekt der Engine gespeist (UnitCastingDuration) statt sich nur auf SetTimerDuration zu verlassen - die rohen (ggf. geheimen) Getter-Werte gehen direkt in die Statusbar, sodass die Füllung auch dort animiert, wo der Engine-Aufruf die Duration akzeptiert, aber nie neu zeichnet.",
		},
	},
	{
		version = "0.2.13",
		changes = {
			"No countdown numbers on buff/debuff icons - the sweep still runs, just without the digit clutter.",
		},
		changesDE = {
			"Keine Countdown-Zahlen mehr auf Buff-/Debuff-Icons - der Sweep läuft weiter, nur ohne Ziffernwirrwar.",
		},
	},
	{
		version = "0.2.12",
		changes = {
			"Buff/debuff icons breathe: size 18px with a minimum 6px gap instead of cramped 16px/4px, so the rows read as icons instead of a squashed strip.",
		},
		changesDE = {
			"Buff-/Debuff-Icons bekommen Luft: 18px groß mit mindestens 6px Abstand statt gequetschter 16px/4px, sodass die Reihen als Icons lesbar sind statt als gequetschter Streifen.",
		},
	},
	{
		version = "0.2.11",
		changes = {
			"Cast bars rebuilt the client-proven way: the bar lives on UIParent now (children of the secure unit buttons inherit combat lockdown, so their Show/SetPoint could be refused exactly when you cast). Fill runs on the engine duration when offered, else per-frame timestamp math, else a static full bar with the spell name - something always shows while you cast.",
		},
		changesDE = {
			"Cast-Leisten nach dem client-erprobten Rezept neu gebaut: Die Leiste lebt jetzt auf UIParent (Kinder der Secure-Unitframes erben den Kampf-Lockdown, weshalb Show/SetPoint genau beim Casten verweigert werden konnten). Füllung läuft über die Engine-Duration wenn vorhanden, sonst Timestamp-Math pro Frame, sonst statischer Vollbalken mit Zaubername - während des Castens ist immer etwas zu sehen.",
		},
	},
	{
		version = "0.2.10",
		changes = {
			"Cast bars are back: the aura container's creation could fail in combat or restricted zones and its throw aborted Refresh before CastBar.Update ran. Container creation is now fully pcall-wrapped, lazily retried on the next update, and the cast bar clears the debuff icon row by its row height instead of anchoring to the container.",
		},
		changesDE = {
			"Cast-Leisten sind zurück: Die Erzeugung des Aura-Containers konnte im Kampf oder in Restriktionszonen fehlschlagen und ihr Wurf brach Refresh vor CastBar.Update ab. Container-Erzeugung ist jetzt komplett pcall-geschützt, wird beim nächsten Update erneut versucht, und die Cast-Leiste räumt die Debuff-Iconreihe über deren Höhe frei statt am Container zu hängen.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Level text uses real difficulty colors (red/orange/yellow/green/gray) via the new S.LevelColor helper instead of staying light gray.",
		},
		changesDE = {
			"Der Stufentext nutzt echte Schwierigkeitsfarben (rot/orange/gelb/grün/grau) über den neuen S.LevelColor-Helfer statt dauerhaft hellgrau.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"Buff/debuff icon rows now run on engine AuraContainers (the buff bars' path): the engine assigns and renders auras itself, so icons show even while the aura data is secret - in combat your curses/dots finally appear on target. Icons carry the cooldown widget's own countdown, stack counts and dispel-colored edges on harmful rows; the group dispel border keeps its readable scan and degrades gracefully.",
		},
		changesDE = {
			"Buff-/Debuff-Iconreihen laufen jetzt über Engine-AuraContainer (der Weg der Buff-Leisten): Die Engine vergibt und rendert Auren selbst, sodass Icons auch bei secret Aura-Daten erscheinen - im Kampf siehst du endlich deine Flüche/DoTs auf dem Ziel. Icons tragen das Countdown-Widget, Stapelzahlen und Dispel-farbige Kanten bei schädlichen Reihen; der Gruppen-Dispel-Rand behält seinen lesbaren Scan und degradiert elegant.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Cast bars on unit frames now actually show and animate: they are driven by SetTimerDuration fed by UnitCastingDuration/UnitChannelDuration (the engine animates the fill itself) instead of Lua GetTime() math that could not touch secret timestamps, and the spell name/icon/notInterruptible values pass through pcall so a secret name no longer hides the whole bar. The remaining-time text uses the duration object's own GetRemainingDuration.",
		},
		changesDE = {
			"Zauberleisten an Unit-Frames werden jetzt angezeigt und laufen flüssig: Sie werden über SetTimerDuration mit UnitCastingDuration/UnitChannelDuration angetrieben (die Engine animiert die Füllung selbst) statt über Lua-GetTime()-Rechnung, die secret Zeitstempel nicht anfassen konnte; Name/Icon/Nicht-Unterbrechbar-Werte laufen durch pcall, sodass ein secret Name die Leiste nicht mehr komplett versteckt. Der Restzeittext nutzt GetRemainingDuration des Duration-Objekts.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.",
		},
		changesDE = {
			"Park-/Versteck-Frames stubben jetzt die Blizzard-Layout-Methoden (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame), die Client-Skripte auf GetParent() aufrufen - behebt einen StatusTrackingManager-UpdateShownState-Fehler durch unter einem nackten versteckten Parent geparkte Frames.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Boss and arena frame settings are live: width, height and the power bar were defined in the defaults but ignored - the frames always rendered at 160x26 with a power bar. All three are now configurable per stack on the Extras page.",
		},
		changesDE = {
			"Boss- und Arena-Fenster-Einstellungen sind aktiv: Breite, Höhe und die Kraftleiste standen in den Defaults, wurden aber ignoriert - die Fenster renderten immer bei 160x26 mit Kraftleiste. Alle drei sind jetzt pro Stapel auf der Extras-Seite konfigurierbar.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Range fade finally works: UnitInRange's secret boolean read as 'always in range' (Plain() nil is not false) - secret results now go to SetAlphaFromBoolean so the engine evaluates them, the same path SentiHeal uses. Disabled range-fade toggles are now honoured too (they always faded before).",
			"Incoming-heal/absorb bands now anchor at the health fill's right edge (fill-texture anchor) instead of stretching from the bar's left edge, and they re-read on UNIT_HEALTH/UNIT_MAXHEALTH - the UNIT_HEAL_PREDICTION event may never fire on this client.",
		},
		changesDE = {
			"Reichweiten-Fade funktioniert endlich: UnitInRanges geheimes Boolean las als 'immer in Reichweite' (Plain() nil ist nicht false) - geheime Ergebnisse gehen jetzt an SetAlphaFromBoolean, damit die Engine sie auswertet, derselbe Weg wie bei SentiHeal. Deaktivierte Reichweiten-Fade-Schalter werden jetzt auch respektiert (vorher wurde immer gefadet).",
			"Heil-/Absorbtionsbänder docken jetzt an der rechten Kante des HP-Fills an (Fill-Textur-Anker) statt sich von der linken Balkenkante auszudehnen, und lesen bei UNIT_HEALTH/UNIT_MAXHEALTH neu - das UNIT_HEAL_PREDICTION-Event feuert auf diesem Client evtl. nie.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Combat text errored on its first number: FontStrings cannot take OnUpdate scripts - the pool is now animated from its holder frame.",
		},
		changesDE = {
			"Kampftext warf bei der ersten Zahl einen Fehler: FontStrings können kein OnUpdate-Script - der Pool wird jetzt vom Holder-Frame animiert.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Combat text actually fires now - the event bus passes the event name first and the wrapper was shifting every argument.",
			"Secret-safe extras: heal prediction, threat percent and the phase/resurrect/summon icons feed secret values to the widgets raw instead of comparing them (everything stayed silently hidden before).",
		},
		changesDE = {
			"Kampftext feuert jetzt wirklich — der Event-Bus übergibt zuerst den Event-Namen und der Wrapper hat alle Argumente verschoben.",
			"Secret-sichere Extras: Heil-Vorhersage, Bedrohungs-Prozent und Phasen-/Res-/Summon-Icons geben geheime Werte roh an die Widgets statt sie zu vergleichen (vorher blieb alles still unsichtbar).",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Fixed the absorb overlay comparing a secret number (error on every frame refresh); secret absorb amounts now feed the widget raw instead.",
		},
		changesDE = {
			"Das Absorb-Overlay verglich eine geheime Zahl (Fehler bei jeder Frame-Aktualisierung); geheime Absorbtionswerte gehen jetzt roh ins Widget.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Heal prediction (incoming heals) and absorb shield overlays on every health bar.",
			"Class power pips above the player frame: combo points, holy power, chi, shards, arcane charges, essence.",
			"Combat text on the player frame - damage, healing, misses and absorbs rise out of the bar.",
			"Boss (boss1-5) and arena (arena1-5) frame stacks with own movers; Blizzard boss/arena frames are parked too.",
			"Focus castbar, threat percent on the target frame, phase/resurrect/summon icons, offline dimming, party pet bars.",
			"New Extras options page plus toggles for party pets, party/raid auras, target threat and the focus castbar.",
		},
		changesDE = {
			"Heil-Vorhersage (eingehende Heilung) und Absorb-Schild-Overlays auf jeder Lebensleiste.",
			"Klassenressourcen-Punkte über dem Spielerfach: Combopunkte, Heilige Kraft, Chi, Splitter, Arkan-Aufladungen, Essenz.",
			"Kampftext am Spielerfach - Schaden, Heilung, Fehlschläge und Absorbtionen steigen aus der Leiste auf.",
			"Boss- (boss1-5) und Arena- (arena1-5) Fensterstapel mit eigenen Movern; Blizzard-Boss/Arena-Fenster werden ebenfalls versteckt.",
			"Fokus-Zauberleiste, Bedrohung in Prozent am Ziel, Phasen-/Res-/Summon-Icons, Offline-Abdimmung, Party-Begleiter-Leisten.",
			"Neue Extras-Einstellungsseite plus Schalter für Party-Begleiter, Party-/Raid-Auren, Ziel-Bedrohung und Fokus-Zauberleiste.",
		},
	},
	{
		version = "0.1.11",
		changes = {
			"Role icons recognize the role more reliably now: the lookup tries both client APIs (UnitGroupRolesAssigned + GetPartyAssignment), uppercases the token and maps DPS/DAMAGE spellings before matching the icon - a secret or differently-cased answer no longer silently hides the icon.",
		},
		changesDE = {
			"Rollen-Icons erkennen die Rolle jetzt zuverlässiger: Die Abfrage nutzt beide Client-APIs (UnitGroupRolesAssigned + GetPartyAssignment), normalisiert das Token auf Großbuchstaben und mappt DPS/DAMAGE-Schreibweisen - eine geheime oder anders geschriebene Antwort versteckt das Icon nicht mehr still.",
		},
	},
	{
		version = "0.1.10",
		changes = {
			"Aura icon spacing raised from 2px to 4px so icons no longer touch.",
		},
		changesDE = {
			"Auren-Abstand von 2px auf 4px erhöht — die Icons kleben nicht mehr aneinander.",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"Aura rows no longer sit inside the bars: buffs 3px above, debuffs 3px below the frame, duration text moved inside each icon's top edge.",
			"Castbar anchors below the debuff row while it is visible so nothing overlaps; role icons shifted along the top edge clear of raid-target icons.",
		},
		changesDE = {
			"Auren-Reihen liegen nicht mehr in den Leisten: Stärkungen 3px oberhalb, Schwächungen 3px unterhalb des Frames, Laufzeit-Text ins Icon hinein.",
			"Die Zauberleiste dockt unter der Schwächungs-Reihe an, solange diese sichtbar ist; Rollen-Icons weiter links an der Oberkante, frei vom Raid-Symbol.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Role icons moved onto the top-right corner edge, clear of name and health texts.",
			"New Health text option: percent, raw values, or both (default: both) — values are abbreviated (4.8m / 12.3k).",
			"Smooth bar animation: health/power fills ease out via the client's status-bar interpolation (toggleable).",
		},
		changesDE = {
			"Rollen-Icons sitzen jetzt auf der oberen rechten Kante, frei von Namen- und Lebenstext.",
			"Neue Option Lebenstext: Prozent, Lebenswerte oder beides (Standard: beides) — Werte werden abgekürzt (4.8m / 12.3k).",
			"Weiche Leisten-Animation: Füllungen gleiten über die StatusBar-Interpolation des Clients (abschaltbar).",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Role marks now use the real Blizzard role icons (tank/healer/damager portrait-role texture) instead of colored letters.",
			"Style pass: health/power bars get a top-fade gloss like the other SentiUI bars, texts anchor to their bars and clear the class-colored edge, role icons sit inside the frame corners.",
		},
		changesDE = {
			"Rollen-Marken nutzen jetzt die echten Blizzard-Rollen-Icons (Tank-/Heiler-/Damager-Portrait-Textur) statt farbiger Buchstaben.",
			"Style-Pass: Gesundheits-/Ressourcenleisten bekommen den Gloss-Verlauf der übrigen SentiUI-Leisten, Texte sitzen auf ihren Bars frei von der Klassenkante, Rollen-Icons liegen in den Frame-Ecken.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Fix: party frames showed as an empty box — UF.Configure was never called for party buttons, so bars and texts had no anchors. The layout pass now configures every button.",
		},
		changesDE = {
			"Fix: Party-Frames zeigten nur eine leere Box — UF.Configure wurde für Party-Buttons nie aufgerufen, Bars und Texte hatten keine Anker. Der Layout-Pass konfiguriert jetzt jeden Button.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"Fix: hidden class colors — when the client keeps a unit's class secret, C_ClassColor.GetClassColor accepts the secret token from UnitClassBase and returns secret rgb values that feed straight into the bar/text color setters. Name coloring moved to SetTextColor so secrets never hit string formatting.",
		},
		changesDE = {
			"Fix: Versteckte Klassenfarben — hält der Client die Klasse einer Einheit geheim, akzeptiert C_ClassColor.GetClassColor das geheime Token aus UnitClassBase und liefert geheime RGB-Werte, die direkt in die Leisten-/Text-Setter fließen. Die Namensfärbung läuft jetzt über SetTextColor, damit Secrets nie in String-Formatierung landen.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Fix: class colors still fell back to reaction yellow — UnitIsPlayer is unreliable on this client, so player detection is now GUID-based ('Player-' prefix) and the class token falls back to GetPlayerInfoByGUID when UnitClass returns a secret.",
		},
		changesDE = {
			"Fix: Klassenfarben fielen weiter auf Reaktions-Gelb zurück — UnitIsPlayer ist auf diesem Client unzuverlässig, deshalb erkennt die Spieler-Prüfung jetzt über den GUID-Präfix ('Player-') und das Klassen-Kürzel fällt auf GetPlayerInfoByGUID zurück, wenn UnitClass ein Secret liefert.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Fix: class colors on health bars — the fallback color table used array values but was read with .r/.g/.b fields, and a secret/failed UnitIsPlayer silently fell through to reaction green. RAID_CLASS_COLORS indexing is now guarded and the player unit is recognized directly.",
		},
		changesDE = {
			"Fix: Klassenfarben auf den Gesundheitsleisten — die Fallback-Farbtabelle wurde mit .r/.g/.b gelesen, obwohl sie Array-Werte speichert, und ein geheimes/fehlerndes UnitIsPlayer fiel still auf Reaktions-Grün zurück. RAID_CLASS_COLORS-Zugriff ist jetzt abgesichert und die Spieler-Einheit wird direkt erkannt.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Fix: health/power values arrive as secret values on this client — bars now feed them to the StatusBar widgets directly (percent text via UnitHealthPercent/UnitPowerPercent) instead of clamping to 0.",
			"Fix: power bar now sits inside the frame instead of hanging below it; aura duration text normalized (no more raw mega numbers like '4843600'), stack counts via GetAuraApplicationDisplayCount.",
		},
		changesDE = {
			"Fix: Gesundheits-/Ressourcenwerte kommen auf diesem Client als Secret-Values — die Leisten reichen sie jetzt direkt an die StatusBar-Widgets (Prozenttext über UnitHealthPercent/UnitPowerPercent) statt auf 0 zu klemmen.",
			"Fix: Ressourcenleiste sitzt jetzt im Frame statt darunter; Auren-Laufzeittext normalisiert (keine rohen Megazahlen wie '4843600' mehr), Stapelzahlen über GetAuraApplicationDisplayCount.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Fix: UNIT_HEALTH_FREQUENT / UNIT_POWER_FREQUENT do not exist on this client — event registration now skips unknown events instead of throwing, which also unblocked frame setup for every unit.",
		},
		changesDE = {
			"Fix: UNIT_HEALTH_FREQUENT / UNIT_POWER_FREQUENT existieren auf diesem Client nicht — die Event-Registrierung überspringt unbekannte Events jetzt statt zu werfen; der Frame-Aufbau lief dadurch für alle Einheiten wieder durch.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"Initial release: player, target, target-of-target, pet and focus frames on secure unit buttons, a five-button party block (joins/leaves mid-combat handled by unit watch) and a secure raid grid header.",
			"Health bars in class/reaction/static colors with percent + absolute text, power bars in power-type colors, names with level, raid icons, leader/role marks, threat border, dead/ghost/offline/AFK status text.",
			"Castbars for player and target with icon, name, time and uninterruptible shield. Auras above (buffs) and below (debuffs) the frame with stack counts, timers and dispel-type borders; dispellable debuffs tint the frame border on party/raid.",
			"Out-of-range fading for party/raid, ready-check marks, hide-Blizzard toggles, SentiUI movers for every block, and a full settings section.",
		},
		changesDE = {
			"Erste Version: Spieler-, Ziel-, Ziel-des-Ziels-, Begleiter- und Fokus-Fenster auf sicheren Unit-Buttons, ein Fünfer-Party-Block (Beitritte/Austritte im Kampf über Unit Watch) und ein sicheres Raid-Raster.",
			"Gesundheitsleisten in Klassen-/Reaktions-/statischer Farbe mit Prozent- und Absoluttext, Ressourcenleisten in Ressourcenfarben, Namen mit Stufe, Raid-Symbole, Leader-/Rollen-Marken, Bedrohungsrahmen, Tot-/Geist-/Offline-/AFK-Statustext.",
			"Zauberleisten für Spieler und Ziel mit Symbol, Name, Zeit und Schild für ununterbrechbare Zauber. Auren über (Stärkungen) und unter (Schwächungen) dem Fenster mit Stapelzahlen, Timern und Dispel-Farbrändern; banbare Schwächungen färben den Rahmen in Party/Raid.",
			"Reichweiten-Abdimmung für Party/Raid, Ready-Check-Marken, Blizzard-ausblenden-Schalter, SentiUI-Mover für jeden Block und eine eigene Settings-Sektion.",
		},
	},
}
