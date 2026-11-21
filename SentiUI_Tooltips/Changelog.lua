local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.9",
		changes = {
			"Interface-dispatch audit: tooltip re-anchoring and the unit status-bar shell no longer run from OnShow/OnHide scripts on GameTooltip and its status bar - secure visibility watchers apply the work outside the client dispatch, which can carry secret unit values.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Tooltip-Verankerung und die Statusleisten-Shell laufen nicht mehr ueber OnShow/OnHide-Scripts auf GameTooltip und dessen Statusleiste - sichere Sichtbarkeits-Watcher wenden die Arbeit ausserhalb des Client-Dispatch an, der Secret-Unit-Werte tragen kann.",
		},
	},

	{
		version = "0.2.8",
		changes = {
			"Removed the player item level line from unit tooltips (per request) - the option, the line and its toggle are gone; Specialization keeps the inspect machinery. The item-level line on item tooltips stays available.",
		},
		changesDE = {
			"Die Spieler-Gegenstandsstufen-Zeile wurde aus den Unit-Tooltips entfernt (auf Wunsch) - Option, Zeile und Schalter sind weg; Spezialisierung behält die Inspect-Maschinerie. Die Gegenstandsstufen-Zeile bei Item-Tooltips bleibt verfügbar.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Class name in the level line colors again: the classFile return of UnitClass reads secret on this client, so the color lookup came back empty and 'Priester'/'Schamane' stayed white. The token now comes from the ClassToken fallback chain (classID, GUID) plus the tooltip's own text, and a secret localized class name is picked straight off the level line.",
			"New option 'My Guild' text tag (default off): the accent color alone marks your own guild - the literal '· My Guild' suffix only shows when enabled. Guild member highlight still controls the color.",
		},
		changesDE = {
			"Klassenname in der Stufenzeile wird wieder gefärbt: Der classFile-Return von UnitClass ist auf diesem Client ein Secret, dadurch blieb die Farbsuche leer und 'Priester'/'Schamane' blieben weiß. Das Token kommt jetzt aus der ClassToken-Fallback-Kette (classID, GUID) plus dem Tooltip-Text selbst, und ein geheimer lokalisierter Klassenname wird direkt von der Stufenzeile gelesen.",
			"Neue Option 'Meine Gilde'-Texttag (Standard aus): Die Akzentfarbe allein markiert die eigene Gilde - das wörtliche '· Meine Gilde' zeigt nur bei Bedarf. Das Gildenmitglied-Highlight steuert weiterhin die Farbe.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Fixed cut-off tooltips and the 'missing' right border: the client sizes the frame before our post-call lines and font swap land, so rewritten or added lines (and the wider SentiUI font) could outgrow the frame and draw over the edge. The skin now measures the real width of every line after styling and grows the frame to fit - the border and top accent edge stay visible and nothing is clipped.",
		},
		changesDE = {
			"Abgeschnittene Tooltips und der 'fehlende' rechte Rand behoben: Der Client dimensioniert den Rahmen bevor unsere Zeilen und der Font-Tausch ankommen - neu geschriebene oder hinzugefügte Zeilen (und der breitere SentiUI-Font) konnten über den Rahmen hinauswachsen und über die Kante zeichnen. Der Skin misst jetzt nach dem Styling die echte Breite jeder Zeile und verbreitert den Rahmen bei Bedarf - Rahmen und Akzentkante bleiben sichtbar und nichts wird abgeschnitten.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Class-colored names actually paint now: the client's own name line can embed its own color codes, which silently win over SetTextColor - the line is rebuilt instead (base name wrapped in the unit color) while our appended tags ([Allianz], -Realm, <AFK>) are tracked per fontstring and re-applied with their original colors, so repeat tooltip passes stay idempotent and a new unit never inherits stale tags.",
		},
		changesDE = {
			"Klassengefärbte Namen malen jetzt wirklich: Die Namenszeile des Clients kann eigene Farbcodes tragen, die SetTextColor still schlagen - die Zeile wird stattdessen neu aufgebaut (Basisname in der Einheitenfarbe), während unsere angehängten Tags ([Allianz], -Realm, <AFK>) pro FontString getrackt und mit ihren Originalfarben neu angehängt werden. Wiederholte Tooltip-Läufe bleiben idempotent und eine neue Einheit erbt keine alten Tags.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Name line no longer doubles the surname: this client's second UnitName return is the character's last name, not a realm, so 'Raziel Lucas' gained a '-Lucas' tag. The realm tag now only shows when the value differs from the surname in the full name - real realms still get their '-Realm'.",
		},
		changesDE = {
			"Die Namenszeile verdoppelt den Nachnamen nicht mehr: Der zweite UnitName-Return dieses Clients ist der Nachname des Charakters, kein Realm - aus 'Raziel Lucas' wurde 'Raziel Lucas -Lucas'. Das Realm-Tag erscheint jetzt nur noch, wenn der Wert vom Nachnamen im vollen Namen abweicht - echte Realms bekommen weiterhin ihr '-Realm'.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Faction detection fixed: UnitFactionGroup only returns a single (sometimes localized) value on this client - the english-faction check we relied on always came back nil, so neither the [Allianz] tag on the name line nor the faction-colored guild name ever painted. Detection now tests every return, matches the localized FACTION_* globals and falls back to the race's faction group.",
			"Hover item level for non-group players: the queue gated on CanInspect, which answers 'no' for plain hovering here and silently dropped every request. It now gates on inspect range (CheckInteractDistance) and lets a dead NotifyInspect expire into the fail path instead. Negative cache entries also only stick for 8s now, so someone walking into range gets a retry quickly.",
		},
		changesDE = {
			"Fraktions-Erkennung gefixt: UnitFactionGroup liefert auf diesem Client nur einen einzelnen (teilweise lokalisierten) Wert - unsere Prüfung auf den englischen Return kam immer nil zurück, deshalb zeichneten weder das [Allianz]-Tag auf der Namenszeile noch die fraktionsgefärbte Gilde. Die Erkennung testet jetzt alle Rückgaben, matcht die lokalisierten FACTION_*-Globals und fällt auf die Fraktionsgruppe der Rasse zurück.",
			"Hover-Gegenstandsstufe für Nicht-Gruppenspieler: Die Warteschlange ging über CanInspect, was für einfaches Hovern hier 'nein' sagt und jede Anfrage still verworfen hat. Jetzt wird auf Inspect-Reichweite (CheckInteractDistance) geprüft und ein toter NotifyInspect läuft einfach in den Fail-Pfad. Negative Cache-Einträge halten außerdem nur noch 8s - wer in Reichweite läuft, bekommt schnell einen neuen Versuch.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Guild names can now wear the faction color: new toggle 'Guild name in faction colors' (default on) paints Horde guilds red and Alliance guilds blue, using the client's own faction palette. It overrides the guild name color; your own guild still keeps the accent gold.",
		},
		changesDE = {
			"Gildennamen können jetzt die Fraktionsfarbe tragen: Der neue Schalter 'Gildenname in Fraktionsfarbe' (Standard an) färbt Horde-Gilden rot und Allianz-Gilden blau, mit der Fraktionspalette des Clients. Er übersteuert die Gildennamenfarbe; die eigene Gilde behält das Akzent-Gold.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Guild colors: the guild name on unit tooltips is now recolored - foreign guilds in a configurable color (default Sentinel blue), your own guild in the accent gold. The rank tag on the same line gets its own configurable color (default gold) instead of the grey it used to borrow.",
			"Two new pickers under SentiUI > Tooltips: 'Guild name color' and 'Guild rank color'.",
		},
		changesDE = {
			"Gildenfarben: Der Gildenname auf Einheiten-Tooltips wird jetzt eingefärbt - fremde Gilden in einer konfigurierbaren Farbe (Standard Sentinel-Blau), die eigene Gilde im Gold-Akzent. Das Rang-Tag in derselben Zeile bekommt eine eigene konfigurierbare Farbe (Standard Gold) statt dem geliehenen Grau.",
			"Zwei neue Farbwähler unter SentiUI > Tooltips: 'Gildennamenfarbe' und 'Gildenrangfarbe'.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Full rework. Fixed duplicated lines (Guild member and every other added line stacked once per post-call): all tooltip lines are now idempotent - label lines update in place, one-shot lines are deduped.",
			"Player item level now works the TipTac way: own ilvl live via GetAverageItemLevel + GetItemLevelColor; others via throttled NotifyInspect -> INSPECT_READY -> GetInspectItemLevel, and when that stays empty the equipped gear is scanned slot by slot (upgrade-aware Item mixin) and averaged over 16 slots. The number is tinted by average item quality.",
			"New: specialization line for players (live for you, via inspect for others, incl. role), difficulty-colored level number, faction/status/realm tags on the name line, the guild line itself carries the rank + a 'My Guild' mark instead of a separate line, elite/rare/boss badge in its own color, target-of-target name colored by that unit's color, top accent edge tinted by class/quality color, dark shell + optional 'cur / max · %' text on the health bar.",
		},
		changesDE = {
			"Komplett-Überarbeitung. Doppelte Zeilen behoben (Gildenmitglied und alle anderen angehängten Zeilen stapelten sich bei jedem Post-Call): Alle Tooltip-Zeilen sind jetzt idempotent - Label-Zeilen werden ersetzt statt dupliziert.",
			"Spieler-Gegenstandsstufe jetzt wie bei TipTac: eigene ilvl live via GetAverageItemLevel + GetItemLevelColor; andere über gedrosseltes NotifyInspect -> INSPECT_READY -> GetInspectItemLevel, und wenn das leer bleibt, wird die Ausrüstung Slot für Slot gescannt (upgrade-sicherer Item-Mixin) und über 16 Slots gemittelt. Die Zahl trägt die durchschnittliche Qualitätsfarbe.",
			"Neu: Spezialisierungs-Zeile für Spieler (live bei dir, via Inspect bei anderen, inkl. Rolle), Stufen-Zahl in Schwierigkeitsfarbe, Fraktions-/Status-/Realm-Tags auf der Namenszeile, die Gildenzeile trägt Rang + 'Meine Gilde'-Markierung statt eigener Zeile, Elite-/Rar-/Boss-Abzeichen in eigener Farbe, Ziel-des-Ziels in dessen Farbe, Akzentkante oben in Klassen-/Qualitätsfarbe, dunkle Hülle + optionaler 'aktuell / max · %'-Text am Lebensbalken.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Other players' item levels now really show: a throttled inspect queue calls NotifyInspect (max one in flight, ~2s spacing, CanInspect + InspectFrame guards, level-10 minimum), waits for INSPECT_READY, then reads C_PaperDollInfo.GetInspectItemLevel. Results cache per guid for 30s and the line is appended live if the tip still shows that player.",
		},
		changesDE = {
			"Gegenstandsstufen anderer Spieler werden jetzt wirklich angezeigt: Eine gedrosselte Inspect-Warteschlange ruft NotifyInspect (max. einer aktiv, ~2s Abstand, CanInspect- + InspectFrame-Guards, Mindeststufe 10), wartet auf INSPECT_READY und liest dann C_PaperDollInfo.GetInspectItemLevel. Ergebnisse werden 30s pro GUID gecacht und die Zeile live angehängt, wenn der Tooltip den Spieler noch zeigt.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Faction tag: Horde/Alliance units get a line in their faction color (horde red / alliance blue, localized name).",
			"Player item level: your own average ilvl always shows, other players once the game holds their inspect data. Both toggleable under Units.",
		},
		changesDE = {
			"Fraktions-Tag: Horde-/Allianz-Einheiten bekommen eine Zeile in ihrer Fraktionsfarbe (Horde-Rot / Allianz-Blau, lokalisierter Name).",
			"Spieler-Gegenstandsstufe: deine eigene durchschnittliche Stufe wird immer gezeigt, bei anderen Spielern sobald deren Inspect-Daten vorliegen. Beides unter Einheiten schaltbar.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Class colors, root cause found: GameTooltip:GetUnit() returns a dead token on this client, so every unit lookup silently failed. The tooltip now resolves its unit from its own tooltip data guid via UnitTokenFromGUID, and class resolution additionally uses the numeric classID (3rd UnitClass return) through C_CreatureInfo.GetClassInfo - both paths proven on this client.",
		},
		changesDE = {
			"Klassenfarben, Ursache gefunden: GameTooltip:GetUnit() liefert auf diesem Client ein totes Token, sodass jede Unit-Abfrage still fehlschlug. Der Tooltip löst seine Einheit jetzt über die eigene Tooltip-Data-GUID via UnitTokenFromGUID auf, und die Klassenauflösung nutzt zusätzlich die numerische classID (3. UnitClass-Rückgabe) über C_CreatureInfo.GetClassInfo - beide Pfade auf diesem Client bewährt.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"Class colors for real this time: UnitIsPlayer itself reads secret on this client, which skipped the whole class lookup before it started. The player check now falls back to the GUID prefix, and an unreadable answer still gets the text-based class read (the localized class name inside the tooltip's own lines) plus the engine's secret class color.",
		},
		changesDE = {
			"Klassenfarben jetzt wirklich: UnitIsPlayer liest auf diesem Client secret, wodurch die komplette Klassen-Abfrage übersprungen wurde, bevor sie anfing. Der Spieler-Check fällt jetzt auf das GUID-Präfix zurück, und eine unlesbare Antwort bekommt trotzdem den textbasierten Klassen-Read (der lokalisierte Klassenname in den Tooltip-Zeilen) plus die geheime Engine-Klassenfarbe.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Fixed class colors never applying: a secret UnitIsPlayer threw inside the color lookup and aborted the whole unit pass. Classes hidden behind secrets are now resolved through the engine's C_ClassColor path and their secret rgb goes straight into the color setters.",
		},
		changesDE = {
			"Fix: Klassenfarben wurden nie angewandt - ein geheimes UnitIsPlayer warf innerhalb der Farb-Abfrage und brach den kompletten Einheiten-Durchlauf ab. Hinter Secrets versteckte Klassen werden jetzt über den C_ClassColor-Pfad der Engine aufgelöst und ihr geheimes RGB geht direkt in die Farb-Setter.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"New unit info, all individually switchable: class name in class color inside the level line, health numbers on the bar, elite/rare/boss badge, group role for party members and an AFK/DND tag on the name.",
			"Guild extras: the guild line already carries the rank; new is the \"Guild member\" highlight when the target is in your own guild.",
		},
		changesDE = {
			"Neue Einheiten-Infos, alle einzeln schaltbar: Klassenname in Klassenfarbe in der Stufenzeile, Lebenspunkte auf dem Balken, Elite-/Rar-/Boss-Abzeichen, Gruppenrolle für Gruppenmitglieder und ein AFK/DND-Anhängsel am Namen.",
			"Gilden-Extras: Die Gildenzeile trägt schon den Rang; neu ist das \"Gildenmitglied\"-Highlight, wenn das Ziel in der eigenen Gilde ist.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"The fixed point now really is fixed: every tooltip show is checked, so world and unit tooltips that skip the default-anchor call are pulled to the anchor too. Tooltips anchored to a specific owner (bag slots, action buttons, links) keep their spot.",
		},
		changesDE = {
			"Der feste Punkt ist jetzt wirklich fest: Jede Tooltip-Anzeige wird geprüft, sodass auch Welt- und Einheiten-Tooltips, die den Standard-Anker umgehen, dorthin gezogen werden. Tooltips mit eigenem Owner (Taschen-Slots, Aktionsbuttons, Links) bleiben an ihrem Platz.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Tooltips now carry the Sentinel gold edge line across the top, matching every other panel.",
			"Fixed the default anchor sitting mid-screen: the fixed spot is now the classic bottom-right tooltip corner and resets there too.",
		},
		changesDE = {
			"Tooltips tragen jetzt die Sentinel-Goldkante oben wie jedes andere Panel.",
			"Fix: Der Standard-Anker saß mitten im Bildschirm - die feste Position ist jetzt die klassische Tooltip-Ecke unten rechts und wird auch dahin zurückgesetzt.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"New module: Sentinel-styled tooltips (flat dark backdrop, Sentinel font) for all the game's tooltips.",
			"Units: class-colored player name, reaction-colored NPC name, border in class/reaction color, slim restyled health bar, guild rank on the guild line and a target-of-target line.",
			"Items: border in item quality color (uncommon and up), item level line (only when the game didn't write one), optional max stack and item/spell IDs.",
			"Placement: fixed movable anchor or at-cursor with X/Y offsets, scale slider, optional hide-in-combat (Shift bypasses).",
		},
		changesDE = {
			"Neues Modul: Tooltips im Sentinel-Look (flaches dunkles Backdrop, Sentinel-Font) für alle Spiel-Tooltips.",
			"Einheiten: Spielername in Klassenfarbe, NPC-Name in Reaktionsfarbe, Rahmen in Klassen-/Reaktionsfarbe, schlanker Lebensbalken, Gildenrang in der Gildenzeile und Ziel-des-Ziels-Zeile.",
			"Gegenstände: Rahmen in Qualitätsfarbe (ab ungewöhnlich), Gegenstandsstufen-Zeile (nur wenn das Spiel keine schreibt), optional Max. Stapel und Item-/Zauber-IDs.",
			"Platzierung: fester verschiebbarer Anker oder am Cursor mit X/Y-Versatz, Skalierungs-Slider, optionale Kampf-Ausblendung (Shift umgeht).",
		},
	},
}
