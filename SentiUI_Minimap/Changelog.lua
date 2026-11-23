-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.3.21",
		date = "2026-11-23",
		changes = {
			"The pending-mail icon now sits inside the coords bar right next to the coordinates instead of the map's top-right corner (falls back to the corner while the bar is hidden).",
		},
		changesDE = {
			"Das Post-Icon sitzt jetzt in der Koordinatenleiste direkt neben den Koordinaten statt oben rechts auf der Karte (faellt auf die Ecke zurueck, solange die Leiste aus ist).",
		},
	},
	{
		version = "0.3.20",
		date = "2026-11-23",
		changes = {
			"Pending mail no longer kills minimap hover: MinimapCluster.IndicatorFrame shows together with the mail icon and covers the whole top strip with its own mouse. Mouse is now off on the IndicatorFrame/InstanceDifficulty/Tracking containers (icon children keep theirs), plus a width guard on wide invisible mail elements.",
		},
		changesDE = {
			"Anstehende Post blockiert keinen Minimap-Hover mehr: MinimapCluster.IndicatorFrame zeigt sich mit dem Post-Icon und deckt den ganzen oberen Streifen mit eigener Maus ab. Maus jetzt aus auf den IndicatorFrame-/InstanceDifficulty-/Tracking-Containern (Icon-Kinder behalten ihre), plus Breitenwache gegen breite unsichtbare Mail-Elemente.",
		},
	},
	{
		version = "0.3.19",
		date = "2026-11-23",
		changes = {
			"Addon button collector catches more buttons: now scans MinimapCluster and MinimapBackdrop children too, accepts click-scripted frames (not only Button objects), and adds a loose match for clickable 12-64px frames on the ring - buttons that never said Minimap in their name reach the + list now. Blizzard ring indicators are SKIP-listed.",
		},
		changesDE = {
			"Addon-Button-Sammler faengt mehr Buttons: scannt jetzt auch Kinder von MinimapCluster und MinimapBackdrop, akzeptiert Frames mit Click-Skripten (nicht nur Button-Objekte) und hat ein loses Match fuer klickbare 12-64px-Frames am Ring - Buttons, die nie Minimap im Namen trugen, landen jetzt in der +-Liste. Blizzard-Ring-Indikatoren stehen auf der SKIP-Liste.",
		},
	},
	{
		version = "0.3.18",
		date = "2026-11-22",
		changes = {
			"Square-minimap corner brackets ride the generated MinimapBorder.tga - one authored gold bracket texture replaces the eight rastered strips (kept out of the accent tint so its gold survives accent customization).",
		},
		changesDE = {
			"Eckwinkel der eckigen Minimap nutzen die generierte MinimapBorder.tga - eine gestaltete Gold-Bracket-Textur ersetzt die acht rasterten Streifen (ausserhalb der Akzent-Toenung, damit ihr Gold die Akzent-Anpassung ueberlebt).",
		},
	},
	{
		version = "0.3.17",
		date = "2026-11-22",
		changes = {
			"New installer step 'Minimap': shape (square/round) and size sliders, applied live through the module's setting path. The step no longer bails on an unready module - an empty step was cached forever.",
		},
		changesDE = {
			"Neuer Installer-Schritt 'Minimap': Form (eckig/rund) und Groesse, live ueber den eigenen Einstellungspfad des Moduls angewendet. Der Schritt bricht nicht mehr bei einem unbereiten Modul ab - ein leerer Schritt wurde fuer immer gecacht.",
		},
	},
	{
		version = "0.3.16",
		date = "2026-11-22",
		changes = {
			"The tracking menu now merges both tracking APIs (the modern C_Minimap table shape and the classic positional one) and dedupes by name - on this client each API lists a different subset, so the standard entries only showed up together.",
			"Auto profession tracking: with Mining or Herbalism the matching tracking (Find Minerals / Find Herbs) turns itself on at login when nothing is tracked yet. A tracking turned off through the menu stays off on the next login.",
			"New Tracking options group: the magnifier button and the auto profession tracking.",
		},
		changesDE = {
			"Das Tracking-Menue vereint jetzt beide Tracking-APIs (die moderne C_Minimap-Tabellenform und die klassische Positionsform) und dedupliziert nach Name - auf diesem Client listet jede API eine andere Teilmenge, die Standard-Eintraege erschienen nur zusammen.",
			"Berufs-Tracking automatisch: mit Bergbau oder Kraeuterkunde aktiviert sich das passende Tracking (Mineraliensuche / Kraeutersuche) beim Login selbst, solange noch nichts verfolgt wird. Ein ueber das Menue ausgeschaltetes Tracking bleibt beim naechsten Login aus.",
			"Neue Tracking-Optionsgruppe: der Lupen-Button und das automatische Berufs-Tracking.",
		},
	},
	{
		version = "0.3.15",
		date = "2026-11-22",
		changes = {
			"The tracking magnifier is back as our own button: a magnifier at the map's top-left (the classic spot) that shows the active tracking on hover and opens a tracking menu on click - built on the client's own C_Minimap tracking API, since Blizzard's tracking chrome never showed through the dock path. Right-click on the map opens it as the last fallback. Toggle under Minimap > Elements.",
			"Hover self-heal: the map's mouse and wheel enablement are checked every second - something disabling them killed every hover function (zone text, wheel zoom, tracking) until re-enabled.",
		},
		changesDE = {
			"Die Tracking-Lupe ist als eigener Button zurueck: eine Lupe oben links an der Karte (der klassische Platz), die bei Mouseover das aktive Tracking zeigt und per Klick ein Tracking-Menue oeffnet - gebaut auf der eigenen C_Minimap-Tracking-API des Clients, da Blizzards Tracking-Chrome ueber den Dock-Pfad nie erschien. Rechtsklick auf die Karte oeffnet es als letzten Fallback. Umschaltbar unter Minimap > Elemente.",
			"Hover-Selbstheilung: Maus- und Rad-Aktivierung der Karte werden jede Sekunde geprueft - etwas, das sie deaktiviert, hatte alle Hover-Funktionen (Zonentext, Rad-Zoom, Tracking) lahmgelegt, bis sie reaktiviert wurden.",
		},
	},
	{
		version = "0.3.14",
		date = "2026-11-22",
		changes = {
			"New performance icon next to the addon-button collection: a gear that shows home/world latency, framerate, addon memory and the heaviest addons on hover - the panel plugin's minimap twin. Right-click opens the settings. Toggle under Minimap > Elements.",
			"Zoom buttons are back: small + and - texts at the map's bottom-right corner (where the classic magnifier pair sat), quiet until hovered. The wheel zoom shares the same zoom step now. Toggle under Minimap > Zoom.",
			"Tracking magnifier gets an explicit Show on dock: the client can keep the frame hidden, and re-anchoring alone never revealed it.",
		},
		changesDE = {
			"Neues Leistungs-Symbol neben der Addon-Button-Sammlung: ein Zahnrad, das bei Mouseover Heim-/Welt-Latenz, Bildrate, Addon-Speicher und die größten Addons zeigt - der Minimap-Zwilling des Panel-Plugins. Rechtsklick öffnet die Einstellungen. Umschaltbar unter Minimap > Elemente.",
			"Zoom-Schaltflächen sind zurück: kleine +- und ---Texte unten rechts an der Karte (wo früher das Lupen-Paar saß), dezent bis zum Hover. Das Mausrad-Zoom nutzt jetzt denselben Zoom-Schritt. Umschaltbar unter Minimap > Zoom.",
			"Die Tracking-Lupe bekommt beim Andocken ein explizites Show: der Client kann den Frame versteckt halten, und ein reines Umankern hat ihn nie eingeblendet.",
		},
	},
	{
		version = "0.3.13",
		date = "2026-11-22",
		changes = {
			"Fixed flapping tooltips when hovering the minimap: interactive Blizzard chrome (zone text button, zoom buttons/hit area, calendar, addon compartment) was hidden while client hover scripts kept re-showing it. These frames now live in a hidden trash parent - their Show() calls land nowhere, no flicker, no tooltips.",
		},
		changesDE = {
			"Flatternde Tooltips beim Überfahren der Minimap behoben: interaktives Blizzard-Chrome (Zonentext-Button, Zoom-Buttons/Hit-Area, Kalender, Addon-Kompartment) wurde versteckt, während die Hover-Skripte des Clients es immer wieder einblendeten. Diese Frames liegen jetzt in einem versteckten Trash-Parent - ihre Show()-Aufrufe gehen ins Leere, kein Flackern, keine Tooltips.",
		},
	},
	{
		version = "0.3.12",
		date = "2026-11-22",
		changes = {
			"Minimap menu secure rows (Reload, /click micro forwards) no longer replace the template OnClick - hardware clicks now run the macro through the client's own secure dispatch instead of flagged addon code.",
		},
		changesDE = {
			"Die Secure-Zeilen des Minimap-Menüs (Reload, /click-Mikro-Weiterleitungen) ersetzen das Template-OnClick nicht mehr - Hardware-Klicks laufen jetzt über den eigenen sicheren Dispatch des Clients statt über markierten Addon-Code.",
		},
	},
	{
		version = "0.3.11",
		date = "2026-11-22",
		changes = {
			"The minimap menu's 'Reload' entry is now a real secure macro row (/reload through the engine's macro path) - calling C_UI.Reload from addon code is a blocked call on this client.",
		},
		changesDE = {
			"Der 'Reload'-Eintrag im Minimap-Menue ist jetzt eine echte gesicherte Makro-Zeile (/reload ueber den Makro-Pfad der Engine) - C_UI.Reload aus Addon-Code ist auf diesem Client ein blockierter Aufruf.",
		},
	},
	{
		version = "0.3.10",
		date = "2026-11-22",
		changes = {
			"The minimap menu now closes on Escape via the shared S.EscClosable helper instead of a UISpecialFrames entry - addon-written entries in that game table taint the Escape dispatch.",
		},
		changesDE = {
			"Das Minimap-Menue schliesst jetzt per gemeinsamem S.EscClosable-Helfer auf Escape statt ueber einen UISpecialFrames-Eintrag - von Addons geschriebene Eintraege in dieser Spiel-Tabelle tainten den Escape-Dispatch.",
		},
	},
	{
		version = "0.3.9",
		date = "2026-11-22",
		changes = {
			"The SetPoint post-hooks on Minimap and the cluster dock guards are replaced by polling: they ran inside the client's layout dispatch (panel opens) and tainted whatever protected work followed.",
		},
		changesDE = {
			"Die SetPoint-Post-Hooks auf Minimap und den Cluster-Dock-Guards sind durch Polling ersetzt: Sie liefen im Layout-Dispatch des Clients (Fenster-Öffnungen) und vergifteten die geschützte Arbeit danach.",
		},
	},
	{
		version = "0.3.8",
		changes = {
			"Interface-dispatch audit: the menu joined UISpecialFrames once instead of on every show (the list grew without bound). Decor-kill and dock-correction hooks no longer hide or re-anchor Blizzard frames inside their show/layout dispatch - watchers poll the transitions and a pump applies corrections a frame later.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Das Menue trat UISpecialFrames nur noch einmal bei statt bei jedem Oeffnen (die Liste wuchs unbegrenzt). Dekor- und Dock-Korrektur-Hooks verstecken bzw. verankern Blizzard-Frames nicht mehr in deren Show-/Layout-Dispatch - Watcher pollen die Uebergaenge und eine Pump korrigiert einen Frame spaeter.",
		},
	},

	{
		version = "0.3.7",
		changes = {
			"Escape-forbidden-call fix: the minimap menu's two OnHide hooks ran inside the Escape dispatch (it joins UISpecialFrames when shown) - the sub-menu and click watcher now fold into the existing OnUpdate watcher.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Die zwei OnHide-Hooks des Minimap-Menues liefen im Escape-Dispatch (es haengt in UISpecialFrames sobald gezeigt) - Sub-Menue und Klick-Watcher laufen jetzt im bestehenden OnUpdate-Watcher.",
		},
	},

	{
		version = "0.3.6",
		changes = {
			"Burger menu fixed: every entry with a Blizzard micro button was dead - the secure `click` attribute type does not fire on this client, so Character/Spellbook/Talents/Quest Log/Social/Guild/Group Finder/Achievements/Collections/Main Menu did nothing. Rows now dispatch `/click <micro button>` through the client's own secure macro engine (the proven path), so the micro handler runs untainted.",
			"Entries without a micro button got hardened fallbacks: Macros loads the LoD addon first (MacroFrame_LoadUI), Keybindings tries KeyBindingFrame_LoadUI + ToggleFrame, and a menu first opened in combat retries its secure wiring on the next peaceful open instead of staying on Lua fallbacks forever.",
		},
		changesDE = {
			"Burger-Menü repariert: Jeder Eintrag mit Blizzard-Micro-Button war tot - der secure `click`-Attributtyp feuert auf diesem Client nicht, also taten Charakter/Zauberbuch/Talente/Questlog/Sozial/Gilde/Gruppensuche/Erfolge/Sammlungen/Hauptmenü nichts. Die Zeilen senden jetzt `/click <Micro-Button>` über die secure Makro-Engine des Clients (der erprobte Weg), damit läuft der Micro-Handler untainted.",
			"Einträge ohne Micro-Button bekamen robustere Fallbacks: Makros laden vorher das LoD-Addon (MacroFrame_LoadUI), Tastaturbelegung versucht KeyBindingFrame_LoadUI + ToggleFrame, und ein erstmals im Kampf geöffnetes Menü wiederholt seine Secure-Verdrahtung beim nächsten friedlichen Öffnen statt für immer auf Lua-Fallbacks zu bleiben.",
		},
	},
	{
		version = "0.3.5",
		changes = {
			"The mail icon can finally show: indicator frames live inside the MinimapCluster's low strata, so a button only anchored onto the map still rendered under it. Docked frames are now lifted to the map's own strata and level band - mail, tracking, difficulty and queue indicators draw on top of the panel.",
		},
		changesDE = {
			"Das Post-Icon kann jetzt erscheinen: Indikator-Frames leben in der niedrigen Strata des MinimapCluster, ein nur an die Karte verankerter Button renderte trotzdem darunter. Angedockte Frames werden jetzt auf die Strata/Ebene der Karte gehoben - Post, Tracking, Schwierigkeit und Queue-Indikatoren zeichnen über dem Panel.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Mail/tracking/difficulty indicators stay docked now: their parent is a Blizzard layout frame that re-anchors its children every time one shows (pending mail snapped the mail button back into the cluster where the panel covered it). A SetPoint guard pushes any foreign anchor back onto the map, same mechanism the landing-page button already used.",
		},
		changesDE = {
			"Post-/Tracking-/Schwierigkeits-Symbole bleiben jetzt angedockt: Ihr Eltern-Frame ist ein Blizzard-Layout-Frame, der seine Kinder bei jedem Show neu verankert (ankommende Post riss das Briefsymbol zurück in den Cluster, wo das Panel es verdeckte). Eine SetPoint-Wache schiebt jede fremde Verankerung zurück auf die Karte - derselbe Mechanismus, den der Landing-Page-Button schon nutzte.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"Menu entries that open Blizzard panels no longer call the Toggle* functions from tainted code: rows are secure buttons whose type=click forwards the hardware click to the parked micro buttons, so the micro button's own handler runs untainted and may compare secret values. Fixes the 'compare a secret number value' error when opening the character panel for real - securecall does NOT untaint on this client. Entries without a micro button keep the direct call.",
		},
		changesDE = {
			"Menüeinträge, die Blizzard-Panels öffnen, rufen die Toggle*-Funktionen nicht mehr aus getaintetem Code: Die Zeilen sind secure Buttons, deren type=click den Hardware-Klick an die geparkten Micro-Buttons weiterreicht - deren eigener Handler läuft dann ungetainted und darf geheime Werte vergleichen. Fixt den 'compare a secret number value'-Fehler beim Charakterfenster wirklich - securecall ent-taintet auf diesem Client NICHT. Einträge ohne Micro-Button behalten den Direktaufruf.",
		},
	},
	{
		version = "0.3.2",
		changes = {
			"Menu entries that toggle Blizzard panels (character, spellbook, talents, ...) now run through securecall - untainted execution so the game's own handlers may compare secret values. Fixes the 'compare a secret number value (execution tainted by SentiUI_Minimap)' error when opening the character panel.",
		},
		changesDE = {
			"Menüeinträge, die Blizzard-Panels öffnen (Charakter, Zauberbuch, Talente, ...), laufen jetzt über securecall - untainted Ausführung, damit die eigenen Handler des Spiels geheime Werte vergleichen dürfen. Fixt den 'compare a secret number value (execution tainted by SentiUI_Minimap)'-Fehler beim Öffnen des Charakterfensters.",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Release history is now filed for the in-game changelog (SentiUI > Changelog, English + German).",
		},
		changesDE = {
			"Die Versionshistorie ist jetzt im In-Game-Changelog eingetragen (SentiUI > Changelog, Englisch + Deutsch).",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Rebuilt on the proven SentinelForeverCore approach: a dark panel wraps the client's own minimap and is the mover.",
			"Minimap decorations are faded instead of hidden and kept down by a ticker - they resurrect on this client.",
			"Zone bar above and coordinates bar below the map, hamburger menu in the bottom bar.",
			"Addon-button collection: LibDBIcon and named minimap buttons gather into a \"+\" dropdown.",
			"Forever-client frames removed: the day/night dial, compass underlay, Blizzard coordinates and the crafting-order icon.",
			"Day/night icon moved next to the clock (sun by day, moon at night); click the clock for the calendar.",
		},
		changesDE = {
			"Auf die bewährte SentinelForeverCore-Bauweise umgestellt: Ein dunkles Panel umrahmt die Minimap und ist der Mover.",
			"Minimap-Deko wird abgeblendet statt versteckt und per Ticker unten gehalten - sie kehrt auf diesem Client zurück.",
			"Zonenleiste über und Koordinatenleiste unter der Karte, Hamburger-Menü in der unteren Leiste.",
			"Addon-Button-Sammlung: LibDBIcon- und benannte Minimap-Buttons sammeln sich in einem \"+\"-Dropdown.",
			"Forever-Client-Frames entfernt: der Tag/Nacht-Dial, die Kompass-Textur, Blizzard-Koordinaten und das Crafting-Icon.",
			"Tag/Nacht-Symbol sitzt jetzt neben der Uhr (Sonne tagsüber, Mond nachts); Klick auf die Uhr öffnet den Kalender.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Sentinel look: amber corner brackets on the square map, ring and dark halo on the round one.",
			"Own zone text with PvP coloring, hamburger menu with game menu and SentiUI flyout.",
			"Mouse wheel zoom, right-click tracking menu, middle-click calendar; indicators re-dock onto the map.",
		},
		changesDE = {
			"Sentinel-Optik: Amber-Eckwinkel auf der eckigen Karte, Ring und dunkler Hof auf der runden.",
			"Eigener Zonentext mit PvP-Färbung, Hamburger-Menü mit Spielmenü und SentiUI-Flyout.",
			"Mausrad-Zoom, Rechtsklick-Trackingmenü, Mittelklick-Kalender; Indikatoren docken an der Karte an.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: shape, scale, border and per-element visibility for zoom, zone text, clock, calendar, tracking, mail and difficulty.",
			"The minimap is a SentiUI mover.",
		},
		changesDE = {
			"Erste Version: Form, Skalierung, Rahmen und Sichtbarkeit pro Element für Zoom, Zonentext, Uhr, Kalender, Tracking, Post und Schwierigkeit.",
			"Die Minimap ist ein SentiUI-Mover.",
		},
	},
}
