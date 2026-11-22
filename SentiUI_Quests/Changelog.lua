-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.4.8",
		date = "2026-11-22",
		changes = {
			"AutoQuest fix: step detection ran only on dialog panel frame names, which never matched on this client - nothing auto-accepted or turned in. The QUEST_*/GOSSIP_* events now set a pending flag the 0.15s poll consumes outside the event dispatch, and the flag re-triggers a step on repeat visits (accept -> gossip -> accept chains).",
			"Turn-in order: gossip and greeting selection now pick only COMPLETE active quests (isComplete / IsActiveQuestComplete) before offered quests - an unfinished active no longer stalls the flow. /sqauto lists which dialog panels the client actually has.",
		},
		changesDE = {
			"AutoQuest-Fix: die Schritt-Erkennung lief nur ueber Dialog-Panel-Frame-Namen, die auf diesem Client nie passten - nichts nahm automatisch an oder gab ab. Die QUEST_*/GOSSIP_*-Events setzen jetzt ein Flag, das der 0.15s-Poll ausserhalb des Event-Dispatchs abarbeitet; das Flag loest einen Schritt auch bei Wiederholungen aus (Annehmen -> Gossip -> Annehmen-Ketten).",
			"Abgabe-Reihenfolge: Gossip- und Greeting-Auswahl nehmen jetzt nur ABGESCHLOSSENE aktive Quests (isComplete / IsActiveQuestComplete) vor den angebotenen Quests - eine unfertige aktive Quest blockiert den Ablauf nicht mehr. /sqauto listet, welche Dialog-Panels der Client wirklich hat.",
		},
	},
	{
		version = "0.4.7",
		date = "2026-11-22",
		changes = {
			"The tracker-choice prompt and the 'reload required?' confirms now use the shared own dialog instead of StaticPopupDialogs; the tracker window closes on Escape via S.EscClosable. Removes addon-written entries from game tables the Escape dispatch reads.",
		},
		changesDE = {
			"Tracker-Auswahl und 'Neuladen noetig?'-Bestaetigungen nutzen jetzt den eigenen Dialog statt StaticPopupDialogs; das Tracker-Fenster schliesst per S.EscClosable auf Escape. Entfernt Addon-geschriebene Eintraege aus Spiel-Tabellen, die der Escape-Dispatch liest.",
		},
	},
	{
		version = "0.4.6",
		changes = {
			"AutoQuest: quest, gossip and accept-confirm dialogs are now detected by a frame-visibility poll (step transitions) instead of QUEST_*/GOSSIP_* events that fire inside the NPC dialog dispatch.",
		},
		changesDE = {
			"AutoQuest: Quest-, Gossip- und Annehmen-Bestaetigungsdialoge werden jetzt per Sichtbarkeits-Poll (Schritt-Uebergaenge) erkannt statt ueber QUEST_*/GOSSIP_*-Events im NPC-Dialog-Dispatch.",
		},
	},
	{
		version = "0.4.5",
		changes = {
			"Quest item button, round 2: the green square was the client's missing-texture render - the icon picker now only accepts fileIDs above 100 or real path strings, preferring the second return so usable-flags are no longer mistaken for a texture. The button also passes the raw itemID to the 'item' attribute ('item:<id>' is macro syntax and never resolved), so it is clickable.",
		},
		changesDE = {
			"Quest-Gegenstands-Button, Runde 2: Das gruene Quadrat war das Missing-Texture-Render des Clients - die Icon-Auswahl akzeptiert jetzt nur FileIDs ueber 100 oder echte Pfad-Strings und bevorzugt den zweiten Rueckgabewert, sodass Usable-Flags nicht mehr als Textur gelten. Der Button uebergibt ausserdem die rohe itemID ans 'item'-Attribut ('item:<id>' ist Makro-Syntax und loeste nie auf), er ist jetzt klickbar.",
		},
	},
	{
		version = "0.4.4",
		changes = {
			"Quest item button fixed: the icon never showed because GetQuestLogSpecialItemInfo returns (id, texture) on this client while the texture was read from the third return - the icon is picked from whichever return is a texture, with C_Item.GetItemIconByID as fallback. The button also uses the native 'item' secure action instead of a /use macro, so quest items are clickable again.",
		},
		changesDE = {
			"Quest-Gegenstands-Button repariert: Das Icon blieb leer, weil GetQuestLogSpecialItemInfo auf diesem Client (id, textur) liefert, die Textur aber aus dem dritten Rueckgabewert gelesen wurde - sie wird jetzt aus dem passenden Rueckgabewert genommen, mit C_Item.GetItemIconByID als Fallback. Der Button nutzt ausserdem die native 'item'-Secure-Action statt eines /use-Makros, Quest-Gegenstaende sind wieder klickbar.",
		},
	},
	{
		version = "0.4.3",
		changes = {
			"Auto-accept now skips trivial (gray) quests - a new option 'Skip gray quests' (on by default) keeps them from being taken automatically; they can still be accepted manually or while holding SHIFT.",
		},
		changesDE = {
			"Auto-Annehmen überspringt jetzt triviale (graue) Quests - die neue Option 'Graue Quests überspringen' (standardmäßig an) verhindert das automatische Annehmen; manuell oder mit gedrückter SHIFT geht es weiterhin.",
		},
	},
	{
		version = "0.4.2",
		changes = {
			"Tracker now colors quest titles by difficulty like the quest log does: gray for trivial, green, yellow, orange, red - via GetQuestDifficultyColor with classic player-level thresholds as fallback. Completed quests keep the green checkmark styling.",
		},
		changesDE = {
			"Der Tracker färbt Questtitel jetzt nach Schwierigkeit wie das Questlog: grau für trivial, grün, gelb, orange, rot - über GetQuestDifficultyColor mit klassischen Spielerlevel-Schwellen als Fallback. Abgeschlossene Quests behalten das grüne Häkchen.",
		},
	},
	{
		version = "0.4.1",
		changes = {
			"The tracker no longer vanishes completely when the active filter matches nothing: with Zone or All active the frame stays up (header + filter buttons remain clickable) and shows a dim 'No quests in this zone' note instead. The default watched list still hides when empty.",
		},
		changesDE = {
			"Der Tracker verschwindet nicht mehr komplett, wenn der aktive Filter nichts findet: Bei aktivem Zone- oder Alle-Filter bleibt der Rahmen stehen (Kopf + Filter-Buttons bleiben klickbar) und zeigt stattdessen einen gedimmten 'Keine Quests in dieser Zone'-Hinweis. Die normale Verfolgt-Liste versteckt sich bei leer weiterhin.",
		},
	},
	{
		version = "0.4.0",
		changes = {
			"Shift-click a quest with the chat edit box open to paste its clickable quest link into the message - share quests in say/party/guild channels like the stock tracker. With no chat box open shift-click still untracks.",
		},
		changesDE = {
			"Shift-Klick auf eine Quest fügt bei geöffnetem Chat-Eingabefeld den klickbaren Quest-Link in die Nachricht ein - Quests in Sagen/Gruppe/Gilde teilen wie beim Standard-Tracker. Ohne offenes Chatfenster beendet Shift-Klick weiterhin das Tracking.",
		},
	},
	{
		version = "0.3.9",
		changes = {
			"Fixed tracker size: a new 'Fixed size' option (default on) keeps the tracker at the configured height whether the list is short or long - the scroll view clips inside the box instead of the window growing and shrinking with content. The 'Max height' slider is now 'Tracker height'.",
		},
		changesDE = {
			"Feste Tracker-Größe: Die neue Option 'Feste Größe' (Standard an) hält den Tracker auf der eingestellten Höhe, egal ob die Liste kurz oder lang ist - die Scroll-Ansicht clippt innerhalb der Box statt dass das Fenster mit dem Inhalt wächst und schrumpft. Der Slider 'Max. Höhe' heißt jetzt 'Trackerhöhe'.",
		},
	},
	{
		version = "0.3.8",
		changes = {
			"Tracker list filter: two small buttons in the header switch the list between watched quests (default, both dim), this zone's quests and the whole quest log - so the tracker stops flooding when the log is full. The active mode wears the accent color, clicking it again returns to watched. The filter is also a dropdown under SentiUI > Quests and is remembered.",
		},
		changesDE = {
			"Tracker-Listenfilter: Zwei kleine Buttons im Kopf schalten die Liste zwischen verfolgten Quests (Standard, beide gedimmt), den Quests dieser Zone und dem ganzen Questlog um - damit der Tracker bei vollem Log nicht überflutet. Der aktive Modus trägt die Akzentfarbe, ein erneuter Klick kehrt zu Verfolgt zurück. Der Filter liegt auch als Dropdown unter SentiUI > Quests und wird gespeichert.",
		},
	},
	{
		version = "0.3.7",
		changes = {
			"Fixed the ADDON_ACTION_FORBIDDEN spam in combat (Frame:ClearAllPoints/SetPoint): the progress bar holder and its rows could be created during lockdown and were then born protected - Progress.Apply now defers out of combat, the row pool and Paint never run under lockdown (entries queue and repaint on regen), and the tracker wheel scroll no longer re-anchors frames mid-fight.",
		},
		changesDE = {
			"ADDON_ACTION_FORBIDDEN-Spam im Kampf gefixt (Frame:ClearAllPoints/SetPoint): Der Fortschritts-Holder und seine Zeilen konnten im Lockdown erstellt werden und waren dann protected geboren - Progress.Apply deferrt jetzt aus dem Kampf, Zeilen-Pool und Paint laufen nie unter Lockdown (Einträge sammeln sich und repainten nach dem Kampf), und das Mausrad-Scrollen des Trackers verankert keine Frames mehr mitten im Kampf.",
		},
	},
	{
		version = "0.3.6",
		changes = {
			"Progress lines no longer wrap to a second row: the text has no width limit anymore (SetWordWrap off), the row now sizes itself to the string width up to a 560px cap, the font steps down a size first when a line would still overflow, and the count underline follows the actual row width.",
		},
		changesDE = {
			"Fortschrittszeilen brechen nicht mehr auf eine zweite Zeile um: Der Text hat kein Breitenlimit mehr (SetWordWrap aus), die Zeile passt ihre Breite an die Textbreite an (bis 560px), bei Überlänge sinkt zuerst die Schriftgröße stufenweise, und der Zähler-Strich folgt der tatsächlichen Zeilenbreite.",
		},
	},
	{
		version = "0.3.5",
		changes = {
			"The progress rows no longer sit permanently on screen: they were created visible (with the bar at full width = three bare gold lines) and only got hidden on the first paint. Rows are now born hidden and only show while a live progress entry exists.",
		},
		changesDE = {
			"Die Fortschritts-Zeilen stehen nicht mehr dauerhaft auf dem Schirm: sie wurden sichtbar erzeugt (mit voller Balkenbreite = drei nackte Goldlinien) und erst beim ersten Paint versteckt. Zeilen starten jetzt versteckt und zeigen nur, solange ein aktiver Fortschritts-Eintrag existiert.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Progress rows now use the shared S.ApplyFont path (Font object + verification instead of bare SetFont) - the same technique Daylight UI uses for guaranteed text on this client.",
		},
		changesDE = {
			"Fortschritts-Zeilen nutzen jetzt den gemeinsamen S.ApplyFont-Pfad (Font-Objekt + Verifikation statt purem SetFont) - dieselbe Technik, mit der Daylight UI Text auf diesem Client garantiert.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"Progress line text finally renders: the rows used S.Font -> SetFont(STANDARD_TEXT_FONT) which silently fails on this client, so bars showed with no text. Rows now use the same recipe as the tracker - a GameFontNormal-templated FontString restyled through a candidate list (media font, STANDARD_TEXT_FONT, FRIZQT) with secret guard.",
		},
		changesDE = {
			"Fortschritts-Text rendert endlich: die Zeilen nutzten S.Font -> SetFont(STANDARD_TEXT_FONT), das auf diesem Client still fehlschlägt - deshalb Balken ohne Text. Zeilen nutzen jetzt dasselbe Rezept wie der Tracker - ein GameFontNormal-basierter FontString, über eine Kandidatenliste (Media-Font, STANDARD_TEXT_FONT, FRIZQT) mit Secret-Guard nachgestylt.",
		},
	},
	{
		version = "0.3.2",
		changes = {
			"Fixed the doubled share line: quest turn-ins posted 'Quest complete: Quest complete: <title>' - the turn-in handler prepended the label and Share() prepended it again.",
			"AutoQuest: QUEST_ACCEPT_CONFIRM now confirms escort-style accept prompts too, and /sqauto prints whether the option is on and which dialog events actually registered on this client (events the client lacks fail silently).",
		},
		changesDE = {
			"Doppelte Share-Zeile behoben: Quest-Abgaben posteten 'Quest abgeschlossen: Quest abgeschlossen: <Titel>' - der Turn-in-Handler setzte das Label und Share() setzte es nochmal.",
			"AutoQuest: QUEST_ACCEPT_CONFIRM bestätigt jetzt auch Eskort-Annahme-Dialoge, und /sqauto zeigt, ob die Option an ist und welche Dialog-Events auf diesem Client wirklich registriert sind (fehlende Events schlagen still fehl).",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Progress rows restyled: the bare 150px accent bar under a row whose text failed to render looked like stray gold lines floating on screen. Rows now have a full-width dim backdrop + accent edge + a thin count track under the text, the text gets a guaranteed client font fallback, an explicit color and a width clip inside the row.",
		},
		changesDE = {
			"Fortschritts-Zeilen neu gestylt: die nackte 150px-Akzentleiste unter einer Zeile ohne gerenderten Text sah aus wie freischwebende Goldlinien. Zeilen haben jetzt einen vollflächigen dunklen Backdrop + Akzentkante + eine dünne Zählleiste unter dem Text; der Text bekommt einen garantierten Client-Font-Fallback, explizite Farbe und einen Breiten-Clip in der Zeile.",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Quest accept and turn-in now post to the party chat too (shareProgress covers the whole quest flow, not just objective counts).",
			"AutoQuest: optional auto accept / turn-in - accepts on QUEST_DETAIL, completes on QUEST_PROGRESS, turns in on QUEST_COMPLETE, and picks quests from gossip and greeting dialogs. A reward choice is never auto-picked; holding SHIFT talks to the NPC manually.",
		},
		changesDE = {
			"Quest-Annehmen und -Abgeben werden jetzt ebenfalls in den Gruppenchat gepostet (shareProgress deckt den ganzen Quest-Fluss ab, nicht nur Objective-Zähler).",
			"AutoQuest: optionales Auto-Annehmen/-Abgeben - nimmt bei QUEST_DETAIL an, schließt bei QUEST_PROGRESS ab, gibt bei QUEST_COMPLETE ab und wählt Quests aus Gossip- und Greeting-Dialogen. Eine Belohnungs-Auswahl wird nie automatisch getroffen; SHIFT gedrückt halten für manuelles Reden mit dem NPC.",
		},
	},
	{
		version = "0.2.17",
		changes = {
			"Chevrons aimed a few millimetres off the marker: GetCenter answers in the frame's own scale space, so a scaled nav frame put the aim point radially off. Coordinates are now converted through the effective scale into UIParent space before the direction is computed.",
		},
		changesDE = {
			"Chevrons zielten ein paar Millimeter neben den Marker: GetCenter antwortet im eigenen Skalierungsraum des Frames, ein skalierter Nav-Frame versetzt den Zielpunkt radial. Die Koordinaten werden jetzt über die effektive Skalierung in UIParent-Raum umgerechnet, bevor die Richtung gerechnet wird.",
		},
	},
	{
		version = "0.2.16",
		changes = {
			"Group posting of quest progress silently never sent: SendChatMessage may only exist as C_ChatInfo.SendChatMessage on this client (pcall swallowed the nil call) and IsInGroup may be missing. Share now resolves either send path and checks IsInGroup or GetNumGroupMembers.",
		},
		changesDE = {
			"Gruppen-Posting des Quest-Fortschritts wurde still nie gesendet: SendChatMessage existiert auf diesem Client evtl. nur als C_ChatInfo.SendChatMessage (pcall hat den nil-Aufruf geschluckt) und IsInGroup fehlt evtl. Share nutzt jetzt beide Sende-Wege und prüft IsInGroup oder GetNumGroupMembers.",
		},
	},
	{
		version = "0.2.15",
		changes = {
			"Fixed the pin crash (Tracker.lua:218 attempt to call a nil value): PinQuest called OpenOnMap, which was only declared as a local further down the file - the reference resolved to a nil global and every pin click died at the last step. OpenOnMap now sits above PinQuest.",
		},
		changesDE = {
			"Pin-Absturz behoben (Tracker.lua:218 attempt to call a nil value): PinQuest rief OpenOnMap auf, das erst weiter unten als local deklariert war - die Referenz zeigte auf ein leeres Global und jeder Pin-Klick starb beim letzten Schritt. OpenOnMap steht jetzt über PinQuest.",
		},
	},
	{
		version = "0.2.14",
		changes = {
			"Chevrons overshot a moving marker: the trail segment was only recomputed every 0.1 s, so at close range the chevrons slid past where the marker had already moved to. The segment now refreshes every frame (cheap math; the heavy reads stay on the 0.1 s tick) and the line ends a fixed ~22 px before the marker instead of a percentage, so it can never reach past the diamond.",
		},
		changesDE = {
			"Chevrons schossen über einen bewegten Marker hinaus: das Spur-Segment wurde nur alle 0,1 s neu berechnet, bei Nahdistanz rutschten die Chevrons über die Position, zu der der Marker schon gewandert war. Das Segment aktualisiert jetzt jeden Frame (billige Mathe, die teuren Reads bleiben im 0,1-s-Tick) und die Linie endet fix ~22 px vor dem Marker statt prozentual - Überschreiten unmöglich.",
		},
	},
	{
		version = "0.2.13",
		changes = {
			"Reverted the rotation flip - the original angle was right, negating pointed the arrows down. The real miss was the trail ending at 88% plus a wide fade: the chevrons now run to 97% of the distance with the fade squeezed into the last 10%, so they visibly arrive at the marker while the wrap still happens at low alpha.",
		},
		changesDE = {
			"Die Rotations-Umkehr wurde zurückgenommen - der ursprüngliche Winkel stimmte, das Negieren ließ die Pfeile nach unten zeigen. Der echte Mangel: die Spur endete bei 88% plus breiter Fade-Zone. Chevrons laufen jetzt bis 97% der Strecke, der Fade ist auf die letzten 10% gequetscht - sie kommen sichtbar am Marker an, der Wrap bleibt bei niedrigem Alpha unsichtbar.",
		},
	},
	{
		version = "0.2.12",
		changes = {
			"Chevrons aimed at a mirrored direction - SetRotation turns clockwise on this client while our atan2 angle is counter-clockwise. The rotation is negated now, so the arrows lie along the actual line to the marker.",
		},
		changesDE = {
			"Chevrons zielten in die gespiegelte Richtung - SetRotation dreht auf diesem Client im Uhrzeigersinn, unser atan2-Winkel ist gegen den Uhrzeigersinn. Die Rotation wird jetzt negiert, die Pfeile liegen auf der echten Linie zum Marker.",
		},
	},
	{
		version = "0.2.11",
		changes = {
			"Chevrons pointed straight up no matter where the target was: math.atan on this client takes one argument, so the two-arg call returned atan(dy) - ~90 degrees for any positive dy. A real atan2 (slope + quadrant fix) now computes the direction, so the arrows actually aim at the marker.",
		},
		changesDE = {
			"Chevrons zeigten immer senkrecht hoch, egal wo das Ziel lag: math.atan nimmt auf diesem Client nur ein Argument, der Zwei-Argument-Aufruf lieferte atan(dy) - ~90 Grad für jedes positive dy. Ein echtes atan2 (Steigung + Quadranten-Fix) rechnet jetzt die Richtung, die Pfeile zielen wirklich auf den Marker.",
		},
	},
	{
		version = "0.2.10",
		changes = {
			"Trail polish: chevrons now fade in near the player and fade OUT before the marker - the wrap around the loop happens at alpha 0, so nothing ever jumps past the target. Positions are cached per tick and the march re-animates every frame, so the flow is smooth instead of stepping at 10 Hz.",
		},
		changesDE = {
			"Spur poliert: Chevrons faden beim Spieler ein und VOR dem Marker wieder aus - der Sprung zurück zum Anfang passiert bei Alpha 0, also hüpft nie was übers Ziel hinaus. Positionen werden pro Tick gecacht und der Marsch jeden Frame neu animiert - flüssig statt 10-Hz-Geruckel.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Real art instead of placeholder pixels: NavMarker.tga (gold rune diamond with halo), NavChevron.tga (soft arrow) and NavDot.tga (glow orb) ship in Media/. The marker uses the new diamond over an orb glow; the trail is now chevrons actually pointing at the target, marching toward it with a size and fade ramp - the screen-space Line approach was dropped.",
		},
		changesDE = {
			"Echte Grafik statt Platzhalter-Pixel: NavMarker.tga (goldene Runen-Raute mit Halo), NavChevron.tga (weicher Pfeil) und NavDot.tga (Glow-Orb) liegen in Media/. Der Marker nutzt die neue Raute über einem Orb-Glow; die Spur sind jetzt Chevrons, die wirklich zum Ziel zeigen und mit Größen- und Fade-Rampe darauf zuwandern - der Line-Ansatz wurde verworfen.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"The direction trail looks like a trail now: where the client's Line widget exists, a soft wide gold glow under a thin bright stroke runs from the player to the marker, inset a little at both ends. On clients without it the dots stay, but with a size and alpha ramp drifting toward the target instead of flat identical pixels.",
		},
		changesDE = {
			"Die Richtungs-Spur sieht jetzt wie eine Spur aus: wo der Client das Line-Widget hat, läuft ein weiches breites goldenes Glühen unter einem dünnen hellen Strich vom Spieler zum Marker, an beiden Enden leicht eingekürzt. Auf Clients ohne Widget bleiben die Punkte, aber mit Größen- und Alpha-Rampe zum Ziel statt flacher gleicher Pixel.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Fixed a constant nav:tick error (attempt to call a nil value): Nav.Restore called HideTrail before the local function was declared, so the reference resolved to a nil global. The trail code is now declared ahead of Restore.",
		},
		changesDE = {
			"Dauerfehler nav:tick behoben (attempt to call a nil value): Nav.Restore rief HideTrail auf, bevor die lokale Funktion deklariert war - die Referenz zeigte auf ein leeres Global. Der Trail-Code steht jetzt vor Restore.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"The way marker no longer lingers at the destination: once the engine reports a distance of 2 yards or less, our diamond, distance text, trail and the arrow hide - the engine keeps its frame parked on the last spot, this just stops drawing on it.",
		},
		changesDE = {
			"Der Weg-Marker bleibt am Ziel nicht mehr hängen: sobald die Engine eine Distanz von 2 Metern oder weniger meldet, verschwinden Raute, Distanztext, Spur und Pfeil - die Engine lässt ihren Frame auf der letzten Position geparkt, wir zeichnen nur nichts mehr drauf.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"/sqtest now also dumps the row's font string state (font, text, string width, alpha, shown) and how many progress message types we claim - so the missing-text issue can be pinned down instead of guessed.",
		},
		changesDE = {
			"/sqtest gibt jetzt auch den FontString-Status der Zeile aus (Font, Text, Textbreite, Alpha, sichtbar) und wie viele Fortschritts-Typen wir claimen - damit das fehlende Text-Problem festgenagelt statt geraten werden kann.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Direction trail: small gold diamonds drift along the screen line from the player to the way marker (off while the nav frame's position is unreadable).",
			"Pin now has fallbacks for clients without GetNextWaypoint / UiMapPoint / SetSuperTrackedQuestID (current-map quest pins, plain-coord SetUserWaypoint, SetSuperTrackedQuest).",
			"Row left-click now pins the way too (map + waypoint), pin is bigger and shows its own tooltip; if the Pin.tga media file does not load, a gold diamond is drawn instead.",
			"/sqnav prints which navigation APIs this client actually has.",
		},
		changesDE = {
			"Richtungs-Spur: kleine goldene Rauten ziehen entlang der Linie vom Spieler zum Weg-Marker (aus, solange die Position des Nav-Frames nicht lesbar ist).",
			"Pin hat jetzt Fallbacks für Clients ohne GetNextWaypoint / UiMapPoint / SetSuperTrackedQuestID (Quest-Pins der aktuellen Karte, SetUserWaypoint mit einfachen Koordinaten, SetSuperTrackedQuest).",
			"Zeilen-Linksklick markiert jetzt ebenfalls den Weg (Karte + Wegpunkt), der Pin ist größer und hat einen eigenen Tooltip; lädt Pin.tga nicht, wird eine goldene Raute gezeichnet.",
			"/sqnav zeigt, welche Navigations-APIs dieser Client wirklich hat.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Progress rows showed their bar but no text: the line's font string is now built with the shared S.Font factory (the one every SentiUI text uses) instead of a manual GameFontNormal template + SetFont, and SetText is pcall-guarded. /sqtest paints three sample lines so the styling can be checked without a quest update.",
		},
		changesDE = {
			"Fortschritts-Zeilen zeigten nur ihren Balken ohne Text: die FontStrings werden jetzt über die gemeinsame S.Font-Factory gebaut (die jeder SentiUI-Text nutzt) statt manuell mit GameFontNormal-Template + SetFont, und SetText ist pcall-abgesichert. /sqtest malt drei Beispielzeilen, damit der Stil ohne Quest-Update geprüft werden kann.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Pin click now drops the client's own waypoint on the quest's spot (C_QuestLog.GetNextWaypoint + C_Map.SetUserWaypoint) - that's what draws the route line on the world map and the edge marker on the minimap, on top of super-tracking the quest for the way marker. Right-click a pin to clear waypoint + tracking.",
		},
		changesDE = {
			"Pin-Klick setzt jetzt den eigenen Wegpunkt des Clients auf den Quest-Ort (C_QuestLog.GetNextWaypoint + C_Map.SetUserWaypoint) - der zeichnet die Route-Linie auf der Weltkarte und den Rand-Marker auf der Minimap, zusätzlich zum Super-Track für die Weg-Markierung. Rechtsklick auf einen Pin löscht Wegpunkt + Verfolgung.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Progress lines (new 'progress' option): the game's yellow quest-progress text mid-screen is claimed via the client's own BLACK_LISTED_MESSAGE_TYPES and ours show instead - dim line, count in accent, a thin gold bar, a tick for finished objectives and gold for a finished quest. It's a mover.",
			"Share progress in group (new 'shareProgress' option): objective progress and quest completion are posted to the party chat - the game's own localized lines, so they read right for everyone.",
		},
		changesDE = {
			"Fortschritts-Zeilen (neue Option 'progress'): der gelbe Quest-Fortschrittstext des Spiels wird über die eigene BLACK_LISTED_MESSAGE_TYPES des Clients übernommen - stattdessen zeigen unsere Zeilen: dezenter Text, Zähler in Akzent, dünner Goldbalken, Haken bei fertigen Objectives und Gold bei Quest-Abschluss. Es ist ein Mover.",
			"Fortschritt in Gruppe teilen (neue Option 'shareProgress'): Objective-Fortschritt und Quest-Abschluss werden in den Gruppenchat gepostet - die eigenen lokalisierten Zeilen des Spiels, damit jeder sie richtig liest.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Fixed-height tracker: the list caps at a 'Max height' setting and clips into a scroll view - the mouse wheel scrolls the rows and a slim gold bar shows the position, instead of the tracker growing down the screen whenever quests come and go.",
			"Way marker (new 'nav' option): an in-world marker rides the client's tracked position - a gold diamond with the distance under it on the spot, and an accent-tinted arrow at the screen edge pointing the way while the target is off-screen. Click a quest's pin in the tracker to make it the tracked target.",
		},
		changesDE = {
			"Tracker mit fester Höhe: Die Liste begrenzt sich über 'Max. Höhe' und clippt in eine Scroll-Ansicht - das Mausrad scrollt die Zeilen und ein schmaler Goldbalken zeigt die Position, statt dass der Tracker bei jeder Quest-Änderung den Bildschirm hinunterwächst.",
			"Weg-Markierung (neue Option 'nav'): eine In-World-Markierung folgt der getrackten Position des Clients - goldene Raute mit Entfernung auf dem Ziel, und ein akzentfarbener Pfeil am Bildschirmrand weist den Weg, solange das Ziel außerhalb liegt. Klick auf das Pin-Icon einer Quest macht sie zum verfolgten Ziel.",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"Fixed the tracker not rendering at all: the objective-line list was declared inside the quest branch but used by the structural pass below it - out of scope, so Refresh errored on the first watched quest and every row stayed hidden.",
			"Pressing ESC on the 'Which quest tracker?' popup no longer switches to Questie's tracker - closing the dialog only dismisses it now.",
		},
		changesDE = {
			"Tracker renderte gar nichts mehr: Die Objective-Liste war innerhalb des Quest-Zweigs deklariert, wurde aber darunter noch benutzt - außerhalb des Scopes, Refresh brach bei der ersten Quest ab und keine Zeile wurde gezeigt.",
			"ESC im 'Welcher Tracker?'-Popup wechselt nicht mehr zu Questies Tracker - Schließen lässt jetzt alles beim SentiUI-Tracker.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"The quest-item tooltip fill now runs untainted via securecall - its internals read secret item data.",
		},
		changesDE = {
			"Der Quest-Item-Tooltip läuft jetzt untainted über securecall - intern liest er geheime Item-Daten.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Reworked the tracker refresh so NO Button widget method is ever called during combat lockdown - only regions (text/icons) update live, and the structural pass (show/hide/position/size) is deferred to combat end. This kills the forbidden-call spam for good regardless of why a row might count as protected.",
		},
		changesDE = {
			"Der Tracker-Refresh ruft im Kampf jetzt GAR KEINE Button-Methoden mehr auf - nur Regionen (Text/Icons) aktualisieren sich live, der strukturelle Durchlauf (Show/Hide/Position/Größe) läuft erst nach Kampfende. Damit ist der forbidden-Spam endgültig weg, egal warum eine Zeile als protected gilt.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Fixed ADDON_ACTION_FORBIDDEN spam (Button:Show/SetPoint/SetWidth/SetHeight/EnableMouse): frames created during combat lockdown are born protected - the tracker and its row pool are now built while out of combat, and no new rows are ever created mid-fight.",
		},
		changesDE = {
			"ADDON_ACTION_FORBIDDEN-Spam gefixt (Button:Show/SetPoint/SetWidth/SetHeight/EnableMouse): Im Kampf erstellte Frames werden protected geboren - Tracker und Zeilen-Pool werden jetzt außerhalb des Kampfes gebaut, im Kampf werden nie neue Zeilen erstellt.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"Zone headers are now collapsible - click a zone name to fold/unfold its quests.",
			"Usable quest items now show an icon button next to the quest - click to use it.",
			"Each quest row has a map-pin button that opens the world map on that quest.",
			"The completion check now uses a real texture instead of a glyph the font can't render (looked like empty boxes).",
		},
		changesDE = {
			"Zonen-Header sind jetzt einklappbar - Klick auf den Zonennamen klappt deren Quests zu/auf.",
			"Benutzbare Quest-Gegenstände zeigen jetzt einen Icon-Button neben der Quest - Klick benutzt ihn.",
			"Jede Quest-Zeile hat einen Karten-Pin-Button, der die Weltkarte auf der Quest öffnet.",
			"Das Fertig-Häkchen ist jetzt eine echte Textur statt eines Glyphen, den die Schrift nicht rendern kann (sah wie leere Kästchen aus).",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Clicking a quest now opens the world map on the quest's map and pings it - the old quest log window is an empty leftover on this client.",
		},
		changesDE = {
			"Ein Klick auf eine Quest öffnet jetzt die Weltkarte auf der richtigen Karte und pingt sie an - das alte Questlog-Fenster ist auf diesem Client ein leeres Relikt.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Fixed \"FontString:SetText(): Font not set\": the tracker's font strings are created with the GameFontNormal font object so a font is always set.",
		},
		changesDE = {
			"\"FontString:SetText(): Font not set\" gefixt: Die FontStrings des Trackers werden mit dem GameFontNormal-FontObject erstellt - eine Schrift ist immer gesetzt.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"The tracker was empty: watched quests are now found through the client's own watch list (GetNumQuestWatches + GetQuestIDForQuestWatchIndex).",
			"Objectives read C_QuestLog.GetQuestObjectives first, with the older API as fallback.",
		},
		changesDE = {
			"Der Tracker war leer: Verfolgte Quests werden jetzt über die eigene Watch-Liste des Clients gefunden (GetNumQuestWatches + GetQuestIDForQuestWatchIndex).",
			"Ziele lesen zuerst C_QuestLog.GetQuestObjectives, die ältere API bleibt als Fallback.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Hardened every quest data read against secret values and secret tables - the source of the repeating refresh error.",
		},
		changesDE = {
			"Alle Quest-Datenlesevorgänge gegen Secret-Werte und Secret-Tabellen abgehärtet - die Ursache des wiederholten Refresh-Fehlers.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: the SentiUI quest tracker module.",
			"Tracker choice: SentiUI tracker, Questie's tracker (when installed) or the Blizzard tracker; Questie users get a one-time choice dialog.",
			"SentiUI tracker: watched quests grouped by zone, [level] prefix, objective progress, completions in green; click opens the quest log, shift-click untracks.",
			"Questie's tracker steps aside while ours is in charge (settings preserved and restored); its map and minimap icons keep working.",
			"The Blizzard objective tracker is starved before it initializes and muted visually; it returns after a reload with the module off.",
			"Release history shows on SentiUI > Changelog (English + German).",
		},
		changesDE = {
			"Erste Version: das Questverfolgungs-Modul für SentiUI.",
			"Tracker-Wahl: SentiUI-Tracker, Questies Tracker (falls installiert) oder der Blizzard-Tracker; Questie-Nutzer bekommen einmalig einen Auswahl-Dialog.",
			"SentiUI-Tracker: verfolgte Quests nach Zone gruppiert, [Stufen]-Präfix, Ziel-Fortschritt, Abgeschlossenes in Grün; Klick öffnet den Questlog, Shift-Klick entfernt die Verfolgung.",
			"Questies Tracker tritt beiseite, solange unserer läuft (Einstellungen werden gemerkt und zurückgespielt); Karten- und Minimap-Icons laufen weiter.",
			"Der Blizzard-Tracker wird vor seiner Initialisierung ausgehungert und optisch stummgeschaltet; er kehrt nach einem Neuladen zurück, wenn das Modul aus ist.",
			"Die Versionshistorie erscheint unter SentiUI > Changelog (Englisch + Deutsch).",
		},
	},
}
