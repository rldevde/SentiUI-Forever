local _, ns = ...

ns.CHANGELOG = {
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
