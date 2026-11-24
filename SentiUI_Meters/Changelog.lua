-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.3.7",
		date = "2026-11-25",
		changes = {
			"Share button: a new 'S' in the dock header posts the top five of the shown metric+segment to party chat, one line per rank. The send drains out of combat and echoes locally if the chat call is refused. Threat mode is excluded (nothing meaningful to post).",
		},
		changesDE = {
			"Teilen-Knopf: Ein 'S' im Dock-Kopf postet die Top fuenf der gezeigten Metrik+Segment in den Gruppenchat, eine Zeile pro Rang. Der Send wartet das Kampfende ab und gibt lokal aus, falls der Chat-Call abgelehnt wird. Bedrohungs-Modus ist ausgenommen.",
		},
	},
	{
		version = "0.3.6",
		date = "2026-11-24",
		changes = {
			"Row hover tooltips: hovering a meter row shows a GameTooltip with the source's name, rank #n, the metric value, its per-second rate and the percentage share of the segment (the share only computes while the client's numbers are readable - secret combat values render through engine formatting instead). Ends with the left-click spell-details hint.",
		},
		changesDE = {
			"Hover-Tooltips auf den Zeilen: Beim Ueberfahren einer Meter-Zeile zeigt ein GameTooltip Name, Rang #n, den Metrikwert, die Rate pro Sekunde und den prozentualen Anteil am Segment (der Anteil rechnet nur solange die Zahlen lesbar sind - Secret-Kampfwerte gehen ueber Engine-Formatierung). Unten der Hinweis auf Linksklick-Zauberdetails.",
		},
	},
	{
		version = "0.3.5",
		date = "2026-11-24",
		changes = {
			"Row text tuning after feedback: THICKOUTLINE read as a fat black box around every letter - back to regular OUTLINE with the drop shadow kept. The class fill brightens from 38 % to 58 % so bar colours are recognizable again while the text stays readable on them.",
		},
		changesDE = {
			"Zeilentext nachjustiert: THICKOUTLINE wirkte wie ein dicker schwarzer Kasten um jeden Buchstaben - zurueck auf normales OUTLINE, der Schlagschatten bleibt. Die Klassenfuellung hellt von 38 % auf 58 % auf, damit die Balkenfarben wieder erkennbar sind und der Text trotzdem lesbar bleibt.",
		},
	},
	{
		version = "0.3.4",
		date = "2026-11-24",
		changes = {
			"Row text was still washed out after the fill darkened - the new StatusBar fill is a widget frame whose texture renders on its own frame level, painting half over the row's plain font strings (white text showed grey under it). Names, values, icons and the rank edge now live on a text-holder frame raised above the fill, in the meter rows and the spell breakdown alike.",
		},
		changesDE = {
			"Zeilentext war auch nach dem Abdunkeln weiter verwaschen - die neue StatusBar-Fuellung ist ein Widget-Frame, dessen Textur auf eigenem Frame-Level rendert und die einfachen FontStrings der Zeile halb uebermalt hat (weisser Text wirkte grau). Namen, Werte, Icons und der Rang-Rand liegen jetzt auf einem Text-Holder-Frame ueber der Fuellung - in den Meter-Zeilen wie im Zauber-Breakdown.",
		},
	},
	{
		version = "0.3.3",
		date = "2026-11-24",
		changes = {
			"Meter rows get the real contrast fix: the class-colored fill renders as a dark muted tint (38 % brightness, Details-style) instead of a saturated fill - white row text now sits on a dark bar and stays readable. Class color remains recognizable as the bar's tint.",
		},
		changesDE = {
			"Meter-Zeilen bekommen den echten Kontrast-Fix: Die klassenfarbige Fuellung rendert als dunkle, gedaempfte Tönung (38 % Helligkeit, Details-Stil) statt saettig - der weisse Zeilentext liegt jetzt auf einem dunklen Balken und bleibt lesbar. Die Klassenfarbe bleibt als Farbstich erkennbar.",
		},
	},
	{
		version = "0.3.2",
		date = "2026-11-24",
		changes = {
			"Row text readable on bright class fills: meter and spell-breakdown name/value strings move from OUTLINE to THICKOUTLINE plus a black drop shadow (offset 1,-1, alpha 0.9).",
		},
		changesDE = {
			"Zeilentext auf hellen Klassenfuellungen lesbar: Name-/Wert-Strings im Meter und im Zauber-Breakdown wechseln von OUTLINE auf THICKOUTLINE plus schwarzem Schlagschatten (Offset 1,-1, Alpha 0.9).",
		},
	},
	{
		version = "0.3.1",
		date = "2026-11-24",
		changes = {
			"Meters render live data during combat now: every damage/healing read was filtered through the secret check, and the client marks totalAmount/amountPerSecond as secret mid-fight - so the docks showed \"No data\" exactly while you were fighting. Secret values are now passed through untouched: row fills are StatusBars (the engine scales SetMinMaxValues/SetValue on secret numbers), amounts print via SetFormattedText/AbbreviateNumbers (engine-side formatting), row order comes from the engine's own sorting instead of a Lua sort that would throw, your own row is flagged by isLocalPlayer (never secret), and spell ids/names/guids go to the API raw - lookups like GetCombatSessionSourceFromType and GetSpellTexture accept secret values. The overall accumulator keeps plain numbers only, so Overall freezes mid-fight but never breaks.",
		},
		changesDE = {
			"Meter zeigen jetzt auch im Kampf Live-Daten: Jede Schaden-/Heilungs-Abfrage lief durch den Secret-Check, und der Client markiert totalAmount/amountPerSecond mitten im Kampf als secret - die Docks zeigten ausgerechnet waehrend des Kampfes \"Keine Daten\". Secret-Werte werden jetzt unangetastet durchgereicht: Zeilenfuellungen sind StatusBars (die Engine skaliert SetMinMaxValues/SetValue auch auf Secret-Zahlen), Betraege gehen ueber SetFormattedText/AbbreviateNumbers (Engine-seitige Formatierung), die Reihenfolge kommt aus der Engine-Sortierung statt aus einem Lua-Sort der werfen wuerde, die eigene Zeile markiert isLocalPlayer (nie secret), und Spell-IDs/Namen/GUIDs gehen roh an die API - Lookups wie GetCombatSessionSourceFromType und GetSpellTexture akzeptieren Secret-Werte. Der Overall-Akkumulator nimmt weiterhin nur lesbare Zahlen, Overall friert deshalb im Kampf ein, bricht aber nicht.",
		},
	},
	{
		version = "0.3.0",
		date = "2026-11-23",
		changes = {
			"Reworked the Details way: no more embedded Blizzard session windows at all - every dock renders C_DamageMeter data itself, so the Blizzard_DamageMeter error class is gone for good. New on top: spec icons on rows (specIconID), a real session history in the right-click menu (named past fights via GetAvailableCombatSessions), and a spell breakdown window on left-clicking a player row (top spells per metric+segment via GetCombatSessionSourceFrom*). Secret-table guards now cover combatSources, session lists and spell containers.",
		},
		changesDE = {
			"Auf die Details-Art umgebaut: gar keine eingebetteten Blizzard-Session-Fenster mehr - jedes Dock rendert C_DamageMeter-Daten selbst, die komplette Blizzard_DamageMeter-Fehlerklasse ist damit weg. Obendrauf neu: Spec-Icons in den Zeilen (specIconID), echte Session-History im Rechtsklick-Menü (benannte Kämpfe via GetAvailableCombatSessions) und ein Zauber-Breakdown-Fenster per Linksklick auf eine Spielerzeile (Top-Zauber pro Metrik+Segment via GetCombatSessionSourceFrom*). Secret-Table-Guards decken jetzt combatSources, Session-Listen und Spell-Container ab.",
		},
	},
	{
		version = "0.2.3",
		date = "2026-11-23",
		changes = {
			"DamageMeter errors eliminated at the root: docks now only ADOPT session windows Blizzard spawned itself (windows born under our taint keep it, and every secret comparison their handlers hit gets blamed on us). Metric/segment/look are written as plain window fields + needsSourceWindowRefresh so the manager's own untainted pass applies them, and dock visibility drives SetAlpha/EnableMouse instead of Show/Hide - no call into Blizzard internals remains that could reach a secret read. Docks without a spare window fall back to the custom renderer and keep retrying.",
		},
		changesDE = {
			"DamageMeter-Fehler an der Wurzel beseitigt: Docks adoptieren nur noch Session-Fenster, die Blizzard selbst gespawnt hat (Fenster unter unserem Taint geboren behalten ihn, und jeder Secret-Vergleich ihrer Handler wird uns zugeschrieben). Metrik/Segment/Optik werden als plain Window-Fields + needsSourceWindowRefresh geschrieben, sodass Blizzards eigener untainter Pass sie übernimmt; die Sichtbarkeit läuft über SetAlpha/EnableMouse statt Show/Hide - es bleibt kein Call in Blizzard-Interna, der einen Secret-Read erreichen könnte. Docks ohne freies Fenster fallen auf den eigenen Renderer zurück und probieren weiter.",
		},
	},
	{
		version = "0.2.2",
		date = "2026-11-23",
		changes = {
			"Fixed the Blizzard_DamageMeter 'secret durationSeconds' error: Blizzard's session-timer path compares a secret number and throws whenever it runs inside our tainted call (Show -> UpdateShownState -> UpdateSessionTimerState). The timer is stripped chrome for us anyway, so windows we own get the whole session-timer path stubbed out before Show() can reach it.",
		},
		changesDE = {
			"Den Blizzard_DamageMeter-Fehler 'secret durationSeconds' behoben: Blizzards Session-Timer-Pfad vergleicht eine Secret-Number und wirft, sobald er in unserem getainteten Call läuft (Show -> UpdateShownState -> UpdateSessionTimerState). Der Timer ist für uns ohnehin gestrippte Chrome - unsere Fenster bekommen den kompletten Session-Timer-Pfad stillgelegt, bevor Show() ihn erreichen kann.",
		},
	},
	{
		version = "0.2.1",
		date = "2026-11-23",
		changes = {
			"Hardened every call into the Blizzard DamageMeter objects: session-window enumeration, entry-frame walks, children/regions, anchoring and Show/Hide are all pcall'd now - an error raised inside Blizzard code showed up as a Blizzard_DamageMeter error, not ours. SetSession also falls back to the bare (type) signature if the (type, id) form is rejected.",
		},
		changesDE = {
			"Alle Aufrufe in die Blizzard-DamageMeter-Objekte gehärtet: Session-Fenster-Enumeration, Entry-Frame-Walks, Children/Regions, Verankerung und Show/Hide laufen jetzt über pcall - ein Fehler in Blizzards Code erschien als Blizzard_DamageMeter-Fehler, nicht als unserer. SetSession fällt bei Ablehnung der (type, id)-Form auf die nackte (type)-Signatur zurück.",
		},
	},
	{
		version = "0.2.0",
		date = "2026-11-23",
		changes = {
			"Native meter windows: every dock now hosts one of Blizzard's own DamageMeter session windows (DamageMeter:ShowNewSessionWindow) parked inside its view - the client's trusted code refreshes the rows itself, so the meter updates live in combat and scrolls natively. The window's own chrome is stripped, class colours + bar metrics applied, metric and segment per dock via SetDamageMeterType/SetSession. Threat stays on the custom renderer (no DamageMeterType exists for it); docks without a native window fall back to it as well.",
		},
		changesDE = {
			"Native Meter-Fenster: jedes Dock hostet jetzt ein eigenes Blizzard-DamageMeter-Session-Window (DamageMeter:ShowNewSessionWindow) in seiner View - der Trusted-Code des Clients aktualisiert die Zeilen selbst, der Meter laeuft dadurch live im Kampf und scrollt nativ. Das eigene Chrome des Fensters wird entfernt, Klassenfarben + Balkenmasse gesetzt, Metrik und Segment pro Dock via SetDamageMeterType/SetSession. Bedrohung bleibt auf dem eigenen Renderer (kein DamageMeterType dafuer); Docks ohne natives Fenster fallen ebenfalls darauf zurueck.",
		},
	},
	{
		version = "0.1.6",
		date = "2026-11-23",
		changes = {
			"Fold + close: every window title now carries a '>' fold button and an 'x' close button (the menu got a 'Close window' row too). Folding shrinks the window to a slim gold-caret strip on its loot-facing edge; clicking the strip unfolds it. Closing disables the dock - '+ New window' or the Meters options brings it back.",
		},
		changesDE = {
			"Einklappen + Schliessen: jeder Fenstertitel traegt jetzt einen '>'-Fold-Button und ein 'x' zum Schliessen (das Menue bekam ebenfalls 'Fenster schliessen'). Einklappen schrumpft das Fenster zu einem schmalen Streifen mit goldener Markierung an der loot-seitigen Kante; Klick auf den Streifen klappt wieder auf. Schliessen deaktiviert das Dock - '+ Neues Fenster' oder die Meters-Optionen holen es zurueck.",
		},
	},
	{
		version = "0.1.5",
		date = "2026-11-23",
		changes = {
			"Row text readability: names and values now render with an outline and full text color instead of dim-on-dark-fill; the inline per-second value was brightened.",
		},
		changesDE = {
			"Zeilen-Lesbarkeit: Namen und Werte rendern jetzt mit Kontur und voller Textfarbe statt gedimmt auf dunklem Fill; die inline DPS/HPS-Zahl wurde aufgehellt.",
		},
	},
	{
		version = "0.1.4",
		date = "2026-11-23",
		changes = {
			"Slimmer windows: default width 210 -> 160 px (existing installs parked on the old default are migrated; the Width slider still allows any size).",
		},
		changesDE = {
			"Schmalere Fenster: Standardbreite 210 -> 160 px (bestehende Installationen auf dem alten Standard werden migriert; der Breiten-Slider erlaubt weiter jede Groesse).",
		},
	},
	{
		version = "0.1.3",
		date = "2026-11-23",
		changes = {
			"Running overall: the 'Overall' segment is now a real accumulated total - every session the client reports (expired fights plus the live one) is summed per source and keeps counting through new fights. Interrupts, dispels, deaths and every other metric accumulate the same way.",
			"Lists survive reloads: the accumulator lives in the saved variables, so overall data is still there after /reload or relog instead of resetting.",
			"Reset prompt: entering an instance with stored meter data asks whether to reset the lists (Yes = C_DamageMeter.ResetAllCombatSessions + the saved accumulator). The window menu also got a 'Reset data' entry that raises the same prompt.",
		},
		changesDE = {
			"Durchzaehlender Gesamtwert: das Segment 'Gesamt' ist jetzt eine echte Summe - jede Session die der Client meldet (abgelaufene Kaempfe plus der laufende) wird pro Quelle aufsummiert und zaehlt ueber Kaempfe hinweg weiter. Unterbrechungen, Bannungen, Tode und jede andere Metrik summieren genauso.",
			"Listen ueberleben Reloads: der Akkumulator liegt in den SavedVariables, Gesamt-Daten bleiben nach /reload oder Relog erhalten statt zurueckzusetzen.",
			"Reset-Abfrage: beim Betreten einer Instanz mit vorhandenen Meter-Daten fragt ein Dialog, ob die Listen zurueckgesetzt werden sollen (Ja = C_DamageMeter.ResetAllCombatSessions + gespeicherter Akkumulator). Das Fenstermenue bekam ebenfalls einen 'Daten zuruecksetzen'-Eintrag mit demselben Dialog.",
		},
	},
	{
		version = "0.1.2",
		date = "2026-11-23",
		changes = {
			"More windows: the meter menu got a '+ New window' entry that turns on the next pool dock (up to four) and chains it onto the left edge of the previous shown one, toward the action bars - each with its own metric and segment like the first two.",
			"Menu edge fix: the popup's top border read as missing - the flat 1px backdrop edge was too faint. The menu now draws its own four accent edge strips so the frame is visibly complete.",
		},
		changesDE = {
			"Mehr Fenster: das Meter-Menue bekam einen '+ Neues Fenster'-Eintrag, der das naechste Dock aus dem Pool einschaltet (bis zu vier) und an die linke Kante des letzten sichtbaren dockt, Richtung Aktionsleisten - jedes mit eigener Metrik und eigenem Segment.",
			"Menue-Rand-Fix: der obere Rand des Popups wirkte wie fehlend - die flache 1px-Backdrop-Kante war zu schwach. Das Menue zeichnet jetzt eigene Akzent-Kanten auf allen vier Seiten.",
		},
	},
	{
		version = "0.1.1",
		date = "2026-11-23",
		changes = {
			"Fixed window sizes: the meters no longer grow with their entry count - width and a new height setting frame a clipped view the list scrolls inside of, with a gold thumb on the right edge and mouse-wheel scrolling (a full raid's threat list is 40 rows).",
			"Combat-safe rows: the 40-row pool is created at enable instead of lazily, so threat/damage lists render mid-fight without protected-frame errors and the wheel keeps scrolling in combat.",
		},
		changesDE = {
			"Feste Fenstergroessen: die Meter wachsen nicht mehr mit der Eintragszahl - Breite und die neue Hoehen-Einstellung rahmen eine Clip-View ein, in der die Liste scrollt, mit Gold-Thumb rechts und Mausrad (die Bedrohungsliste eines Raids hat 40 Zeilen).",
			"Kampffeste Zeilen: der 40-Zeilen-Pool wird beim Enable gebaut statt lazy, sodass Bedrohungs-/Schadenslisten mitten im Kampf rendern ohne Protected-Frame-Fehler und das Mausrad weiter scrollt.",
		},
	},
	{
		version = "0.1.0",
		date = "2026-11-23",
		changes = {
			"New module: up to two dockable meter windows beside the loot chat panel. Each dock shows its own metric from the client's damage meter data - damage done, DPS, healing, HPS, absorbs, damage taken, interrupts, dispels or deaths - plus a threat mode via UnitDetailedThreatSituation.",
			"Per-dock setup: right-click a meter's title to pick its metric and segment (current fight / overall); the same settings live on the Meters options page. Docks are movers and carry the Sentinel panel look with class-colored bars and a gold leader edge.",
		},
		changesDE = {
			"Neues Modul: bis zu zwei andockbare Meter-Fenster neben dem Plündern-Chatpanel. Jedes Dock zeigt eine eigene Metrik aus den Schadensmeter-Daten des Clients - Schaden, DPS, Heilung, HPS, Absorptionen, erlittener Schaden, Unterbrechungen, Bannungen oder Tode - plus ein Bedrohungs-Modus ueber UnitDetailedThreatSituation.",
			"Einstellung pro Dock: Rechtsklick auf den Meter-Titel waehlt Metrik und Segment (aktueller Kampf / Gesamt); dieselben Optionen liegen auf der Meter-Einstellungsseite. Docks sind Movers im Sentinel-Panel-Look mit klassengefaerbten Balken und Goldkante fuer den Ersten.",
		},
	},
}
