local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.6.9",
		changes = {
			"Aura timers sit under the icons now: the cooldown keeps its swipe but its on-icon countdown numbers are hidden; the duration goes to a small outlined fontstring below each icon via SetDurationText, in a compact 45s/10m/2h/3d format - the jumbled '10m1h10m' look is gone. Rows get a wider gap so the text has room.",
		},
		changesDE = {
			"Aura-Timer sitzen jetzt unter den Icons: Der Cooldown behält seinen Swipe, aber seine Countdown-Zahlen auf dem Icon sind aus; die Dauer geht über SetDurationText in einen kleinen outlined FontString unter jedem Icon, im kompakten 45s/10m/2h/3d-Format - das verquatschte '10m1h10m' ist weg. Zeilen bekommen einen größeren Abstand, damit der Text Platz hat.",
		},
	},
	{
		version = "0.6.8",
		changes = {
			"Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.",
		},
		changesDE = {
			"Park-/Versteck-Frames stubben jetzt die Blizzard-Layout-Methoden (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame), die Client-Skripte auf GetParent() aufrufen - behebt einen StatusTrackingManager-UpdateShownState-Fehler durch unter einem nackten versteckten Parent geparkte Frames.",
		},
	},
	{
		version = "0.6.7",
		changes = {
			"The Sentinel border and dispel-colored debuff settings actually work now: both were in the options but never read - icons always drew the ring and the engine always tinted debuffs. Border off now hides the ring, dispel colors off keeps every border Sentinel gold.",
		},
		changesDE = {
			"Die Einstellungen Sentinel-Rahmen und Dispel-farbige Debuffs funktionieren jetzt: beide standen in den Optionen, wurden aber nie gelesen - Icons zeichneten immer den Ring und Debuffs wurden immer eingefärbt. Rahmen aus blendet den Ring aus, Dispel-Farben aus lässt alle Ränder Sentinel-Gold.",
		},
	},
	{
		version = "0.6.6",
		changes = {
			"Fixed a Lua error on login: the anchor watch was assigned as an OnUpdate script ON the AuraContainer, but that handler is forbidden on this frame type ('cannot replace a forbidden script handler') - the watch now runs on a helper frame instead. This also restores the re-pin fix from 0.6.5, which silently never ran because of it.",
		},
		changesDE = {
			"Lua-Fehler beim Login behoben: Der Anker-Watch war als OnUpdate-Script AUF dem AuraContainer registriert, aber dieser Handler ist auf dem Frame-Typ verboten ('cannot replace a forbidden script handler') - der Watch läuft jetzt auf einem Helper-Frame. Dadurch funktioniert auch der Re-Pin-Fix aus 0.6.5 wieder, der dadurch still nie lief.",
		},
	},
	{
		version = "0.6.5",
		changes = {
			"Fixed bars resetting to their default spot after reload/login: the client re-anchors the container on its own layout passes and keeps doing so whenever it lays out again - the container now re-pins to the mover holder automatically whenever its anchor no longer points at the holder (checked every 0.5s, skipped in combat).",
		},
		changesDE = {
			"Leisten kehren nach Reload/Login nicht mehr auf die Standard-Position zurück: Der Client setzt den Container-Anker bei eigenen Layout-Läufen immer wieder neu - der Container pinnt sich jetzt automatisch zurück auf den Mover-Holder, sobald sein Anker nicht mehr auf ihn zeigt (alle 0,5s geprüft, im Kampf pausiert).",
		},
	},
	{
		version = "0.6.4",
		changes = {
			"Fixed bars snapping back after dragging: the client owns the container's geometry and re-anchors it on its own layout passes - the container is now pinned back onto the mover holder after aura updates (debounced) and after every mover move.",
		},
		changesDE = {
			"Leisten springen nach dem Ziehen nicht mehr zurück: Der Client besitzt die Container-Geometrie und setzt den Anker bei eigenen Layout-Läufen zurück - der Container wird jetzt nach Aura-Updates (gedrosselt) und nach jedem Mover-Zug wieder auf den Holder gepinnt.",
		},
	},
	{
		version = "0.6.3",
		changes = {
			"Bars are movable now: the mover grabs a holder frame sized like the icon row instead of the container itself (a container is one icon big while buttons fan out past its rect - the handle was untouchable). The container anchors to the holder's TOPRIGHT and follows it.",
			"Container created with plain CustomAuraContainerTemplate like DaylightUI - DisableUntrustedLayoutScriptsTemplate on the container itself could suppress its combat updates.",
			"Default positions dock each bar's top-right edge just left of the minimap, buffs above debuffs.",
		},
		changesDE = {
			"Leisten sind jetzt verschiebbar: Der Mover greift einen Holder-Frame in Reihenbreite statt des Containers selbst (ein Container ist nur ein Icon groß, die Buttons ragen über sein Rechteck hinaus - der Griff war nicht zu treffen). Der Container ankert an der TOPRIGHT-Ecke des Holders und folgt ihm.",
			"Container wird mit schlichtem CustomAuraContainerTemplate erstellt wie bei DaylightUI - DisableUntrustedLayoutScriptsTemplate am Container selbst konnte dessen Kampf-Updates unterdrücken.",
			"Standard-Positionen docken die obere rechte Kante jeder Leiste links neben der Minimap an, Buffs über Debuffs.",
		},
	},
	{
		version = "0.6.2",
		changes = {
			"Default bar position now also falls back to MinimapCluster and, if no minimap rect is found at all, to the screen's top-right corner instead of a center offset.",
		},
		changesDE = {
			"Standard-Position nutzt jetzt auch MinimapCluster als Fallback und - falls gar kein Minimap-Rechteck gefunden wird - die obere rechte Bildschirmecke statt eines Offsets von der Mitte.",
		},
	},
	{
		version = "0.6.1",
		changes = {
			"Fixed default bar position: the mover anchors the container's center while icons hang off its TOPRIGHT corner - the offset now compensates so the row docks just left of the minimap, level with its top edge.",
		},
		changesDE = {
			"Standard-Position der Leisten korrigiert: Der Mover ankert die Container-Mitte, die Icons hängen aber an der TOPRIGHT-Ecke - der Offset gleicht das jetzt aus, sodass die Reihe direkt links neben der Minimap auf deren Höhe dockt.",
		},
	},
	{
		version = "0.6.0",
		changes = {
			"Reworked onto the client's own AuraContainer - the engine path ElvUI uses on modern clients (SecureAuraHeaderTemplate does not exist here): the engine assigns auras to its own buttons, so buffs and debuffs appear and disappear correctly even in combat and secret data never reaches Lua.",
			"Each button is wired through initializeFrame with our widgets: icon texture, dispel-tinted border ring (engine colors debuffs by type), cooldown swipe with the engine's own '19m' countdown text, stack count and secure right-click buff cancel.",
			"Weapon enchants show ahead of the buffs via the container's item enchantment slots.",
		},
		changesDE = {
			"Auf den eigenen AuraContainer des Clients umgebaut - der Engine-Pfad, den ElvUI auf modernen Clients nutzt (SecureAuraHeaderTemplate existiert hier nicht): Die Engine weist ihren eigenen Buttons die Auras zu, deshalb kommen und gehen Buffs und Debuffs auch mitten im Kampf korrekt und Secret-Daten erreichen Lua gar nicht erst.",
			"Jeder Button wird über initializeFrame mit unseren Widgets verdrahtet: Icon-Textur, banngefärbter Rand (die Engine färbt Debuffs nach Typ), Cooldown-Swipe mit dem eigenen '19m'-Countdown der Engine, Stapelzahl und sicherem Rechtsklick-Abbrechen.",
			"Waffenverzauberungen erscheinen über die Item-Enchantment-Slots des Containers vor den Buffs.",
		},
	},
	{
		version = "0.5.0",
		changes = {
			"Reworked onto SecureAuraHeaderTemplate - the same engine path ElvUI uses: the client assigns auras to buttons inside the restricted environment, so buffs and debuffs appear and disappear correctly even in combat.",
			"Durations now render through C_UnitAuras.GetAuraDuration as a duration object on the cooldown widget - the engine draws the '19m' countdown itself, secret-proof. Stacks and dispel colors use the dedicated client APIs as well.",
			"Right-click cancels a buff again (secure cancelaura button template); weapon enchants show on the buff bar via the header's tempEnchant slots.",
		},
		changesDE = {
			"Auf SecureAuraHeaderTemplate umgebaut - derselbe Engine-Pfad wie bei ElvUI: Der Client weist die Auras den Buttons im Restricted-Kontext zu, deshalb kommen und gehen Buffs und Debuffs jetzt auch mitten im Kampf korrekt.",
			"Laufzeiten werden über C_UnitAuras.GetAuraDuration als Duration-Objekt an das Cooldown-Widget gereicht - die Engine zeichnet den '19m'-Countdown selbst, secret-sicher. Stapelzahlen und Bannfarben nutzen ebenfalls die dedizierten Client-APIs.",
			"Rechtsklick bricht Buffs wieder ab (sicheres CancelAura-Button-Template); Waffenverzauberungen erscheinen über die TempEnchant-Slots des Headers auf der Buff-Leiste.",
		},
	},
	{
		version = "0.4.2",
		changes = {
			"Bars no longer empty in combat: when the client turns aura data secret mid-fight the API either throws (bar freezes and refreshes after the fight) or hands back secret tables (slots keep their icons) - the pool is never wiped anymore.",
		},
		changesDE = {
			"Leisten werden im Kampf nicht mehr leer: Wenn der Client Aura-Daten mitten im Kampf geheim macht, wirft die API entweder (Leiste friert ein und wird nach dem Kampf aktualisiert) oder liefert Secret-Tabellen (Slots behalten ihre Icons) - der Pool wird nie mehr komplett geleert.",
		},
	},
	{
		version = "0.4.1",
		changes = {
			"Bar defaults now dock next to the actual minimap (computed from its real position, icons grow left) instead of a fixed screen-center offset - existing saved positions still win, so reset the movers once to get the new spots.",
		},
		changesDE = {
			"Leisten-Defaults docken jetzt an der echten Minimap an (aus ihrer tatsächlichen Position berechnet, Icons wachsen nach links) statt an einem festen Offset von der Bildschirmmitte - gespeicherte Positionen gewinnen weiterhin, also einmal die Mover zurücksetzen für die neuen Plätze.",
		},
	},
	{
		version = "0.4.0",
		changes = {
			"Reworked into fully custom aura icons: buffs and debuffs are enumerated via C_UnitAuras and every icon is a SentiUI widget - icon texture, Sentinel border, compact '19m'/'2h' timer, stack count, cooldown swipe and dispel-colored debuff edges.",
			"Layout options are back (our own frames): icon size, spacing, icons per row, grow direction, scale.",
			"Tooltips on hover; Blizzard buff frames are parked when enabled.",
		},
		changesDE = {
			"Auf komplett eigene Aura-Icons umgebaut: Buffs und Debuffs werden über C_UnitAuras gelesen und jedes Icon ist ein SentiUI-Widget - Icon-Textur, Sentinel-Rahmen, kompakter '19m'/'2h'-Timer, Stapelzahl, Cooldown-Swipe und bannfarbene Debuff-Ränder.",
			"Layout-Optionen sind zurück (eigene Frames): Icon-Größe, Abstand, Icons pro Zeile, Wachstumsrichtung, Skalierung.",
			"Tooltips beim Überfahren; die Blizzard-Buff-Fenster werden bei Bedarf versteckt.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Fixed UNIT_AURA error: the engine's duration is a secret string - type() says 'string' but comparisons throw. All text handling now sits inside pcall.",
			"New: own timer string per icon - the remaining time is computed from the aura's expirationTime and rendered as '19m'/'2h'/'45s' while the secret engine text is faded out. Falls back to the engine text when the aura is unreadable.",
		},
		changesDE = {
			"UNIT_AURA-Fehler behoben: Die Engine-Laufzeit ist ein Secret-String - type() sagt 'string', aber Vergleiche werfen. Alle Textzugriffe laufen jetzt komplett in pcall.",
			"Neu: eigener Timer-String pro Icon - die Restzeit wird aus dem expirationTime der Aura berechnet und als '19m'/'2h'/'45s' gerendert, während der Secret-Engine-Text ausgeblendet wird. Bei unlesbarer Aura fällt es auf den Engine-Text zurück.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"Complete pass over the styling core: empty pool buttons are hidden with the secure state driver (plain Hide loses on this client - SentinelForeverCore proves the driver on these very buttons) and woken when their icon gains a real texture.",
			"Timer texts are found via the named globals (BuffButton1Duration...) instead of field access, so the '51m' compaction and icon-centered font actually reach the strings this client uses.",
		},
		changesDE = {
			"Kompletter Durchgang über den Styling-Kern: Leere Pool-Buttons werden jetzt per securem State-Driver versteckt (einfaches Hide verliert auf diesem Client - SentinelForeverCore beweist den Driver an genau diesen Buttons) und wachen auf, sobald ihr Icon eine echte Textur bekommt.",
			"Timer-Texte werden über die benannten Globals gefunden (BuffButton1Duration...) statt über Feldzugriff, damit die '51m'-Kompaktierung und die Icon-mittige Schrift die Strings dieses Clients wirklich erreichen.",
		},
	},
	{
		version = "0.3.2",
		changes = {
			"Ghost borders, final logic: a border now needs positive proof of an aura (readable slot id or a real icon texture) - unreadable pool buttons hide instead of drawing ghosts.",
			"'/suibuffs' also reports how many FontStrings each button has and whether their text is a readable string or secret.",
		},
		changesDE = {
			"Geister-Rahmen, finale Logik: Ein Rahmen braucht jetzt einen positiven Aura-Nachweis (lesbare Slot-ID oder echte Icon-Textur) - unlesbare Pool-Buttons werden versteckt statt Geister zu zeichnen.",
			"'/suibuffs' meldet jetzt auch, wie viele FontStrings jeder Button hat und ob deren Text lesbar oder secret ist.",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Fixed resurrected pool slots: only buttons this module hid are ever shown again - the pool's red '?' placeholder icons (INV_Misc_QuestionMark) now count as empty and stay hidden.",
			"Aura counting hardened against stub tables.",
		},
		changesDE = {
			"Wiederbelebte Pool-Slots behoben: Nur Buttons, die dieses Modul versteckt hat, werden wieder eingeblendet - die roten '?'-Platzhalter-Icons des Pools (INV_Misc_QuestionMark) gelten jetzt als leer und bleiben versteckt.",
			"Aura-Zählung gegen Stub-Tabellen gehärtet.",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Empty boxes were the engine's own unused pool slots, not our borders: buttons with a hidden/textureless icon (or past the real aura count) are now hidden outright and re-shown the moment they carry an aura.",
		},
		changesDE = {
			"Die Leerkästen waren die ungenutzten Pool-Slots der Engine selbst, nicht unsere Rahmen: Buttons ohne sichtbare Icon-Textur (oder hinter der echten Aura-Anzahl) werden jetzt komplett versteckt und sofort wieder eingeblendet, sobald sie eine Aura tragen.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Timer text actually compacts now: all FontString regions on the buttons are found (field names differ between clients) and SetText is hooked, so every engine refresh is shortened to '51m'/'2h' immediately.",
		},
		changesDE = {
			"Timer-Text wird jetzt wirklich kompaktiert: Alle FontString-Regionen der Buttons werden gefunden (Feldnamen unterscheiden sich je nach Client) und SetText wird gehookt - jede Engine-Aktualisierung wird sofort zu '51m'/'2h' gekürzt.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"'/suibuffs' now works: the command is registered at file scope and dumps on any call - it no longer silently does nothing when invoked without 'debug'.",
		},
		changesDE = {
			"'/suibuffs' funktioniert jetzt: Der Befehl wird auf Dateiebene registriert und gibt bei jedem Aufruf den Dump aus - er schweigt nicht mehr, wenn er ohne 'debug' eingegeben wird.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Added '/suibuffs debug': dumps the native frames' children with shown/alpha/icon/texture state, so stubborn ghost boxes can be identified as ours or the engine's.",
		},
		changesDE = {
			"Neu: '/suibuffs debug': zeigt die Kinder der nativen Fenster mit Shown/Alpha/Icon/Textur-Status, damit hartnäckige Geisterboxen als eigene oder Engine-Elemente erkannt werden.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Empty-slot borders gone for good: buttons are counted against the player's real aura count (C_UnitAuras), so pool slots past the last actual aura never get a border.",
			"Duration text compacted ('60 min' -> '60m') and sized down, so timers stay inside the icon instead of overlapping neighbors.",
		},
		changesDE = {
			"Leer-Kästen endgültig weg: Buttons werden gegen die echte Aura-Anzahl des Spielers geprüft (C_UnitAuras), Pool-Slots hinter der letzten echten Aura bekommen keinen Rahmen.",
			"Laufzeit-Text kompaktiert ('60 Min.' -> '60m') und verkleinert, damit Timer im Icon bleiben statt die Nachbarn zu überlappen.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Timer text no longer spills over the icon: duration is set in a smaller thick-outlined font centered on the icon.",
			"Ghost borders on empty slots: the border now also follows the icon's shown state and a readable aura-slot id when the client exposes one.",
		},
		changesDE = {
			"Timer-Text ragt nicht mehr über das Icon hinaus: Die Laufzeit steht jetzt in kleinerer Thick-Outline-Schrift mittig auf dem Icon.",
			"Geister-Rahmen auf leeren Slots: Der Rahmen folgt jetzt zusätzlich der Sichtbarkeit des Icons und einer lesbaren Aura-Slot-ID, wenn der Client sie anbietet.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Ghost borders gone: buttons are now taken from the provider's active/auraFrames list, which only holds live auras - the engine's empty pool slots (and the collapse arrow) are no longer styled.",
		},
		changesDE = {
			"Geister-Rahmen weg: Buttons kommen jetzt aus der active/auraFrames-Liste des Providers, die nur echte Auras enthält - die leeren Pool-Slots der Engine (und der Einklapp-Pfeil) werden nicht mehr gestylt.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Aura timers restyled: the duration now sits centered on the icon in the SentiUI font with a thick outline and hard shadow, readable on any artwork; stack counts move to the top-right corner.",
		},
		changesDE = {
			"Aura-Timer neu gestylt: Die Laufzeit liegt jetzt mittig auf dem Icon in der SentiUI-Schrift mit dickem Outline und hartem Schatten - auf jedem Artwork lesbar; Stapelzahlen wandern in die obere rechte Ecke.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Icons were hidden behind the border frame: the template's dark fill covered the button - the backdrop now draws its edge only, with a transparent fill.",
		},
		changesDE = {
			"Icons lagen hinter dem Rahmen-Frame: Die dunkle Füllung des Templates deckte den Button ab - das Backdrop zeichnet jetzt nur noch die Kante, die Füllung ist transparent.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Fixed borders drawn on empty pool buttons and the collapse arrow: the border now only shows while the button actually carries an aura icon.",
		},
		changesDE = {
			"Rahmen wurden auf leeren Pool-Buttons und dem Einklapp-Pfeil gezeichnet: Der Rahmen erscheint jetzt nur, solange der Button wirklich ein Aura-Icon trägt.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Reworked around the client's own buff/debuff/weapon-enchant frames: the native frames keep doing all aura work and are re-anchored onto SentiUI movers, with the Sentinel border and square icons drawn over each button.",
			"Settings slimmed to what the native frames allow: enable, scale, square icons, Sentinel border.",
		},
		changesDE = {
			"Auf die eigenen Buff-/Debuff-/Waffenverzauberungs-Fenster des Clients umgebaut: Die nativen Fenster machen weiterhin die gesamte Aura-Arbeit und werden auf SentiUI-Mover verankert, mit Sentinel-Rahmen und eckigen Icons über jedem Button.",
			"Einstellungen auf das reduziert, was die nativen Fenster hergeben: Aktivierung, Skalierung, eckige Icons, Sentinel-Rahmen.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"No icons spawned: an AuraContainer built inside the module's xpcall/event context hands its button provider the caller's accessRestrictions, so the engine could not wire the AuraButtons' onshow. Container setup now runs in a clean C_Timer.After context.",
		},
		changesDE = {
			"Es wurden keine Icons erzeugt: Ein AuraContainer, der im xpcall/Event-Kontext des Moduls gebaut wird, vererbt dem Button-Provider die accessRestrictions des Aufrufers - die AuraButtons konnten ihr onshow nicht verdrahten. Der Container-Aufbau läuft jetzt in einem sauberen C_Timer.After-Kontext.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"Buttons stayed blank: the aura template ships its Icon/Count/Duration regions unwired - initializeFrame now hands each region back to the button (icon, duration cooldown, stack count).",
		},
		changesDE = {
			"Buttons blieben leer: Das Aura-Template liefert seine Icon/Count/Duration-Regionen unverdrahtet - initializeFrame übergibt jetzt jede Region zurück an den Button (Icon, Laufzeit-Cooldown, Stapelzahl).",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Bars were registered but hidden behind the minimap's LOW-strata panel - containers and holders now live on MEDIUM strata, and the container gets a real size.",
		},
		changesDE = {
			"Leisten waren registriert, aber hinter dem LOW-Strata-Minimap-Panel versteckt - Container und Holder liegen jetzt auf MEDIUM, und der Container bekommt eine echte Größe.",
		},
	},
	{
		version = "0.6.7",
		changes = {
			"AddAuraSlot fallback when AddAuraGroup is unavailable, plus a one-shot status print after load showing whether containers and groups registered.",
		},
		changesDE = {
			"AddAuraSlot-Fallback, falls AddAuraGroup fehlt, plus einmaliger Status-Print nach dem Laden, der zeigt, ob Container und Gruppen registriert wurden.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Bars actually render now: the aura container starts disabled on this client - SetEnabled(true) plus Show() is what makes it spawn its group buttons. Default spot moved up next to the minimap.",
		},
		changesDE = {
			"Leisten rendern jetzt wirklich: Der Aura-Container startet auf diesem Client deaktiviert - SetEnabled(true) plus Show() lässt ihn seine Gruppen-Buttons überhaupt erst spawnen. Standard-Position weiter oben neben die Minimap gelegt.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Fixed invisible bars: the aura container must sit on UIParent (its parent becomes protected for button spawns - a tiny holder could starve it); the mover holder is now a real one-row handle.",
		},
		changesDE = {
			"Unsichtbare Leisten behoben: Der Aura-Container muss an UIParent hängen (sein Parent wird für Button-Spawns geschützt - ein winziger Holder konnte ihn blockieren); der Mover-Holder ist jetzt ein echter einzeiliger Griff.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"Buff and debuff bars on the native aura container - icons, cooldowns, stacks and cancel come from the engine, so no secret aura data crosses addon code.",
			"Two movable bars (SentiUI movers), icon size/spacing/row wrap, grow direction and scale options.",
			"Temporary weapon enchants ride ahead of the buffs; right-click cancels a buff; stock Blizzard buff frames are parked.",
			"Debuff bar can narrow to dispellable-only.",
		},
		changesDE = {
			"Buff- und Debuff-Leisten auf dem nativen Aura-Container - Icons, Cooldowns, Stapel und Abbrechen kommen vom Engine, keine geheimen Aura-Daten im Addon-Code.",
			"Zwei bewegliche Leisten (SentiUI-Mover), Optionen für Icon-Größe, Abstand, Zeilenumbruch, Wachstumsrichtung und Skalierung.",
			"Temporäre Waffenverzauberungen vor den Buffs; Rechtsklick bricht einen Buff ab; Blizzard-Bufffenster werden versteckt.",
			"Debuff-Leiste kann auf nur bannbare Schwächungszauber eingegrenzt werden.",
		},
	},
}
