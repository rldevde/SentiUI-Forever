local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.15",
		changes = {
			"Dispatcher rollback: PLAYER_TARGET_CHANGED and RAID_TARGET_UPDATE are registered again and the raid icon moved back out of the volatile color pass.",
		},
		changesDE = {
			"Dispatcher-Rollback: PLAYER_TARGET_CHANGED und RAID_TARGET_UPDATE sind wieder registriert, das Raid-Icon ist aus dem volatilen Farb-Pass wieder raus.",
		},
	},
	{
		version = "0.1.14",
		changes = {
			"ESC-forbidden-call hardening: PLAYER_TARGET_CHANGED and RAID_TARGET_UPDATE are gone from the event list - both fire inside the protected ESC/click dispatch (deselect/unmark) and any Lua there taints the client's follow-up protected calls. The 0.25s RefreshAll pass now also repaints the raid icon, so target highlight and marks still update without the events.",
		},
		changesDE = {
			"ESC-Blockier-Härtung: PLAYER_TARGET_CHANGED und RAID_TARGET_UPDATE sind aus der Event-Liste raus - beide feuern im geschützten ESC-/Klick-Dispatch (Abwählen/Markierung lösen) und jegliches Lua dort taintet die folgenden geschützten Aufrufe des Clients. Der 0,25s-RefreshAll-Durchlauf zeichnet jetzt auch das Raid-Icon neu, Ziel-Highlight und Markierungen aktualisieren weiter ohne die Events.",
		},
	},
	{
		version = "0.1.13",
		changes = {
			"Enemy cast bars on plates now actually animate: the fill is driven per frame off the engine duration object (UnitCastingDuration), reading its getters raw - which keeps working when the cast timestamps are secret values, and even where SetTimerDuration accepts the duration but never repaints the bar. /snptest now reports the duration object and cast-info values for debugging.",
		},
		changesDE = {
			"Gegner-Castbalken auf den Plaketten laufen jetzt wirklich: Die Füllung wird pro Frame direkt aus dem Duration-Objekt der Engine gespeist (UnitCastingDuration), dessen Getter roh gelesen werden - das funktioniert auch dann, wenn die Cast-Zeitstempel secret sind, und selbst dort, wo SetTimerDuration die Duration akzeptiert, den Balken aber nie neu zeichnet. /snptest zeigt jetzt Duration-Objekt und Cast-Info-Werte zur Fehlersuche.",
		},
	},
	{
		version = "0.1.12",
		changes = {
			"Tap detection: mobs tagged by a player outside your group now paint grey - health fill and name both dim like the game's own plates, so you see at a glance the kill gives no credit. Grey wins over threat, class and reaction colors; a 'Grey tapped targets' toggle controls it.",
		},
		changesDE = {
			"Tap-Erkennung: Gegner, die ein Spieler außerhalb deiner Gruppe getappt hat, werden jetzt grau gemalt - Lebensbalken und Name dimmen wie bei den eigenen Plaketten des Spiels, damit du sofort siehst, dass der Kill keinen Credit gibt. Grau gewinnt vor Threat-, Klassen- und Reaktionsfarben; ein 'Getappte Ziele grau'-Schalter steuert es.",
		},
	},
	{
		version = "0.1.11",
		changes = {
			"No countdown numbers on plate debuff icons - the sweep still runs.",
		},
		changesDE = {
			"Keine Countdown-Zahlen mehr auf Plaketten-Debuff-Icons - der Sweep läuft weiter.",
		},
	},
	{
		version = "0.1.10",
		changes = {
			"Debuff icons on plates get more room: 16px with a minimum 4px gap instead of 15px/2px, so the row no longer looks squashed.",
		},
		changesDE = {
			"Debuff-Icons auf Plaketten bekommen mehr Luft: 16px mit mindestens 4px Abstand statt 15px/2px, die Reihe wirkt nicht mehr gequetscht.",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"Cast bars rebuilt the client-proven way: engine duration fill when offered, else per-frame timestamp math, else a static full bar with the spell name - something always shows while the unit casts.",
		},
		changesDE = {
			"Cast-Leisten nach dem client-erprobten Rezept neu gebaut: Engine-Duration-Füllung wenn vorhanden, sonst Timestamp-Math pro Frame, sonst statischer Vollbalken mit Zaubername - während des Castens ist immer etwas zu sehen.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Cast bars are back: the aura container's creation could fail in combat or restricted zones and its throw aborted the plate update before the cast refresh ran. Container creation and SetUnit are now fully pcall-wrapped and retried on the next update; the plate update itself can no longer take the cast bar down.",
		},
		changesDE = {
			"Cast-Leisten sind zurück: Die Erzeugung des Aura-Containers konnte im Kampf oder in Restriktionszonen fehlschlagen und ihr Wurf brach das Plaketten-Update vor dem Cast-Refresh ab. Container-Erzeugung und SetUnit sind jetzt komplett pcall-geschützt und werden beim nächsten Update erneut versucht; das Plaketten-Update kann die Cast-Leiste nicht mehr mitreißen.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Debuffs now show WHO applied them: your own get a gold edge, your group's a blue edge, debuffs from outside the group are desaturated with the dark edge. Level text uses real difficulty colors (red/orange/yellow/green/gray) instead of staying gray at equal level.",
		},
		changesDE = {
			"Debuffs zeigen jetzt, WER sie gewirkt hat: eigene bekommen eine goldene Kante, die der Gruppe eine blaue, Debuffs von außerhalb der Gruppe sind entsättigt mit dunkler Kante. Der Stufentext nutzt echte Schwierigkeitsfarben (rot/orange/gelb/grün/grau) statt dauerhaft grau.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Debuffs on enemy nameplates now actually show - the manual C_UnitAuras scan is replaced by an engine AuraContainer (same path the buff bars use), which renders secret aura data itself instead of handing it to Lua. Your curses/dots now appear in combat: icon, cooldown sweep, stack count and dispel-colored edge, left-aligned above the name. 'Only my debuffs' filters the container to HARMFUL|PLAYER.",
		},
		changesDE = {
			"Debuffs auf Gegner-Namensplaketten werden jetzt angezeigt - der manuelle C_UnitAuras-Scan wurde durch einen Engine-AuraContainer ersetzt (derselbe Weg wie die Buff-Leisten), der secret Aura-Daten selbst rendert statt sie an Lua zu geben. Deine Flüche/DoTs erscheinen jetzt im Kampf: Icon, Cooldown-Sweep, Stapelzahl und Dispel-farbige Kante, links über dem Namen. 'Nur eigene Debuffs' filtert den Container auf HARMFUL|PLAYER.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"Fixed the 'attempt to compare secret number' error spam: this client hands back threat percentages (and potentially levels/health) as secret numbers that type() still reports as 'number' and issecretvalue does not flag - only the comparison itself throws. Threat.State now runs its whole status/pct decision inside one pcall (secret -> no threat coloring instead of an error), and the level text plus the health-percent fallback got the same treatment.",
			"Style pass: health and cast bars now carry the SentiUI bar look - darker unfilled background plus the vertical white gloss fade the unit frames use, with the texts parented onto the bars above the gloss layer.",
		},
		changesDE = {
			"Behebt den 'attempt to compare secret number'-Fehlerspam: Der Client liefert Bedrohungsprozente (und evtl. Stufen/Leben) als secret numbers, die type() weiterhin als 'number' meldet und issecretvalue nicht erkennt - erst der Vergleich selbst wirft. Threat.State fasst die gesamte Status/Prozent-Entscheidung jetzt in einem pcall zusammen (secret -> keine Aggro-Färbung statt Fehler); Stufentext und Lebensprozent-Fallback erhielten dieselbe Behandlung.",
			"Style-Pass: Lebens- und Zauberleisten tragen jetzt den SentiUI-Bar-Look - dunklerer unfüllter Hintergrund plus der vertikale Gloss-Verlauf der Unit-Frames; die Texte liegen auf den Bars über der Gloss-Ebene.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Cast bar hardening: UnitCastingInfo/UnitChannelInfo reads are pcall-guarded so a throwing secret return can no longer kill Refresh mid-flight and hide the bar, and the spell name goes straight into SetText inside the pcall instead of evaluating an 'or' fallback on a possibly-secret value outside it.",
		},
		changesDE = {
			"Zauberleisten-Härtung: UnitCastingInfo/UnitChannelInfo lesen jetzt durch pcall, sodass ein werfender secret Rückgabewert Refresh nicht mehr mitten im Lauf abbricht und die Leiste versteckt; der Zaubername geht direkt ins SetText statt vorher ein 'or'-Fallback auf einem möglicherweise secret Wert auszuwerten.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Long unit names no longer run through the level text: the name is truncated with ... to the space left of the level field - font strings never clip at their anchors, so anchoring alone could not stop the overlap.",
			"New /snptest debug command dumps the live state of the target's plate (attach count, box sizes, health min/max readability, cast duration API, whether the game's unit frame is parked) so broken layers report themselves.",
			"Secret-value fix in the health percent path: comparing a secret result to nil throws, which could kill a whole refresh pass - the format call now carries the pcall.",
		},
		changesDE = {
			"Lange Einheitennamen laufen nicht mehr durch den Stufentext: Der Name wird mit ... auf den Platz links vom Stufenfeld gekürzt - FontStrings clippen nie an ihren Ankern, darum konnte das alleinige Verankern die Überlappung nicht stoppen.",
			"Neuer /snptest-Befehl: zeigt den Live-Zustand der Plakette am Ziel (Anzahl Attachments, Boxgrößen, Lesbarkeit der Health-MinMax, Cast-Duration-API, ob der Blizzard-UnitFrame geparkt ist) - damit melden kaputte Ebenen sich selbst.",
			"Secret-Wert-Fix im Lebens-Prozentpfad: Der Vergleich eines secret Ergebnisses mit nil wirft und konnte einen ganzen Refresh-Pass töten - der format-Call trägt jetzt den pcall.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Cast bar now animates smoothly and can no longer freeze mid-fill: it is driven by SetTimerDuration fed by UnitCastingDuration/UnitChannelDuration - the engine does the animation itself because cast timestamps are secret on this client and Lua arithmetic on them threw (that is what pinned the bar at the static 50% fallback).",
			"The plate name no longer runs into the level text: the name field is clipped against the level field and word wrap is off on both.",
			"Health values and percent now refresh on the 0.25s plate ticker too, not only on UNIT_HEALTH - the fill is self-healing even when health events never fire for nameplate units.",
			"Attach robustness: Manager.forbidden() pcalls the IsForbidden result comparison - a secret boolean there could previously kill the whole attach and leave the game's own plate visible.",
			"Threat colors are no longer skipped when UnitCanAttack comes back secret - only a plain 'cannot attack' skips them.",
		},
		changesDE = {
			"Zauberleiste läuft jetzt flüssig und friert nicht mehr mitten drin ein: Sie wird über SetTimerDuration mit UnitCastingDuration/UnitChannelDuration angetrieben - die Engine animiert selbst, weil Cast-Zeitstempel auf diesem Client secret sind und Lua-Arithmetik darauf warf (das hat die Leiste auf dem statischen 50%-Fallback festgepinnt).",
			"Der Plaketten-Name läuft nicht mehr in den Stufentext: Das Namensfeld wird am Stufenfeld geklippt und beide haben keinen Zeilenumbruch.",
			"Lebenswerte und Prozent werden jetzt auch über den 0.25s-Plaketten-Ticker aktualisiert, nicht nur per UNIT_HEALTH - die Füllung heilt sich selbst, auch wenn Health-Events für Nameplate-Units ausbleiben.",
			"Attach-Robustheit: Manager.forbidden() pcallt jetzt den Vergleich des IsForbidden-Ergebnisses - ein secret boolean dort konnte vorher den kompletten Attach töten und die Blizzard-Plakette sichtbar lassen.",
			"Bedrohungsfarben werden nicht mehr übersprungen, wenn UnitCanAttack secret zurückkommt - nur ein lesbares 'nicht angreifbar' überspringt sie.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Health and cast bars now use the proven unit-frame pattern: every StatusBar setter is pcall'd individually so one rejected secret value can no longer freeze the bar, cast progress runs on normalized 0..1 fractions in seconds (UnitCastingInfo/UnitChannelInfo through plain()), and the health percent text reads UnitHealthPercent - the engine API that accepts secret values - before falling back to plain math.",
		},
		changesDE = {
			"Lebens- und Zauberbalken laufen jetzt wie im bewährten Unit-Frames-Muster: Jeder StatusBar-Setter wird einzeln per pcall aufgerufen, sodass ein abgelehnter Secret-Wert die Leiste nicht mehr einfriert; der Zauber-Fortschritt läuft über normalisierte 0..1-Bruchteile in Sekunden (UnitCastingInfo/UnitChannelInfo durch plain()), und der Lebens-Prozenttext nutzt UnitHealthPercent - die Engine-API, die Secret-Werte akzeptiert - bevor auf plain gerechnete Werte zurückgegriffen wird.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: fully custom nameplates in the Sentinel style - flat health bars with a 1px border, name and level above, cast bar below.",
			"Threat colors on the health fill: holding it (tank) / safe (dps) teal, slipping orange, lost or on you red - tank mode auto-detects role/spec, overridable.",
			"Class-colored bars for players, reaction colors for NPCs, level, elite/rare/boss marker, raid target icon, gold accent border on your current target.",
			"Cast bar with spell icon and spell name; non-interruptible casts show darker so you don't waste the kick.",
			"Debuff row above the name (optionally only your own debuffs), friendly nameplates can collapse to name-only.",
			"Enemy/friendly plate CVar toggles, width/height/scale sliders - everything under SentiUI > Nameplates.",
		},
		changesDE = {
			"Erste Version: komplett eigene Namensplaketten im Sentinel-Stil - flache Lebensbalken mit 1px-Rahmen, Name und Stufe darüber, Zauberbalken darunter.",
			"Bedrohungsfarben auf dem Lebensbalken: gehalten (Tank) / sicher (DD) in Teal, Abrutschen Orange, verloren bzw. auf dir Rot - Tank-Modus erkennt Rolle/Spec automatisch, überschreibbar.",
			"Balken in Klassenfarbe für Spieler, Reaktionsfarben für NPCs, Stufe, Elite-/Rar-/Boss-Markierung, Schlachtzugsymbol, Gold-Rahmen beim aktuellen Ziel.",
			"Zauberbalken mit Icon und Zaubername; nicht unterbrechbare Zauber erscheinen dunkler, damit kein Kick verschwendet wird.",
			"Debuff-Reihe über dem Namen (optional nur eigene Debuffs), freundliche Plaketten können auf Namen-only schrumpfen.",
			"CVar-Schalter für feindliche/freundliche Plaketten, Breiten-/Höhen-/Skalierungs-Regler - alles unter SentiUI > Namensplaketten.",
		},
	},
}
