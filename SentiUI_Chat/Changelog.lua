local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.40",
		date = "2026-11-25",
		changes = {
			"Level-up chat jump fixed at the source: ChatFrame1 now gets the real ignoreFramePositionManager frame field instead of the ineffective secure attribute, its legacy managed-position entries are removed, and any already-registered managed-container membership is cleared.",
			"Fallback snap-back now saves the corrected rectangle to the chat cache so a later FCF restore cannot reapply the stale pre-panel position.",
			"Chat message/label guards now check secret values before type or truthiness tests, so protected chat text cannot throw inside the filter, throttle, loot-window detection or player-level rewrite paths.",
		},
		changesDE = {
			"Level-Up-Chat-Sprung an der Quelle gefixt: ChatFrame1 bekommt jetzt das echte ignoreFramePositionManager-Frame-Feld statt des wirkungslosen Secure-Attributs, seine alten Managed-Position-Eintraege werden entfernt und eine bereits registrierte Managed-Container-Mitgliedschaft wird geleert.",
			"Der Snap-back-Fallback speichert das korrigierte Rechteck jetzt auch im Chat-Cache, damit ein spaeteres FCF-Restore nicht wieder die veraltete Pre-Panel-Position anwendet.",
			"Chat-Text-/Label-Guards pruefen geheime Werte jetzt vor Type- oder Truthiness-Tests, damit geschuetzte Chattexte nicht in Filter, Throttle, Loot-Fenster-Erkennung oder Level-Umschreibung werfen.",
		},
	},
	{
		version = "0.2.39",
		date = "2026-11-23",
		changes = {
			"Chat tabs keep their Sentinel skin permanently: the tab style only ran once per frame but the engine re-paints the Selected/Highlight art on every dock/hover/select - StyleTab now re-runs every watchdog tick and kills a NineSlice on newer tab templates.",
		},
		changesDE = {
			"Chat-Tabs behalten jetzt dauerhaft den Sentinel-Skin: der Tab-Style lief nur einmal pro Frame, die Engine malt die Selected-/Highlight-Art aber bei jedem Dock/Hover/Select neu - StyleTab laeuft jetzt bei jedem Watchdog-Tick und killt bei neueren Tab-Templates auch die NineSlice.",
		},
	},
	{
		version = "0.2.38",
		date = "2026-11-23",
		changes = {
			"Input bar only appears while typing: the client never hides its editbox (IsShown always true), so the bar tracks HasFocus - shows on focus, hides when focus leaves.",
		},
		changesDE = {
			"Eingabeleiste erscheint nur noch beim Tippen: der Client versteckt die Editbox nie (IsShown immer true), darum folgt die Leiste jetzt HasFocus - zeigt sich bei Fokus, verschwindet beim Verlassen.",
		},
	},
	{
		version = "0.2.37",
		date = "2026-11-23",
		changes = {
			"Input bar is now slightly transparent to match the chat panel (55% fill when the panel runs transparent, 80% otherwise) - the client never hides its editbox so the bar is a permanent fixture and must blend in.",
		},
		changesDE = {
			"Eingabeleiste jetzt leicht transparent passend zum Chat-Panel (55% Fuellung bei transparentem Panel, sonst 80%) - der Client versteckt seine Editbox nie, die Leiste ist also Dauergast und muss sich einfuegen.",
		},
	},
	{
		version = "0.2.36",
		date = "2026-11-23",
		changes = {
			"Input bar now actually appears: the show/hide fast path read f.editBox directly, but that field is not populated on every chat window on this client - anyEbShown stayed false forever and the bar never showed. It now uses FindEditBox with the global fallback like the rest of the module.",
		},
		changesDE = {
			"Eingabeleiste erscheint jetzt wirklich: der Sichtbarkeits-Fast-Path las f.editBox direkt, aber das Feld ist auf diesem Client nicht bei jedem Chatfenster belegt - anyEbShown blieb fuer immer false und die Leiste zeigte sich nie. Jetzt wird FindEditBox mit dem globalen Fallback benutzt wie ueberall sonst im Modul.",
		},
	},
	{
		version = "0.2.35",
		date = "2026-11-23",
		changes = {
			"Input bar no longer permanently visible: shown only while an edit box is open, hidden otherwise.",
			"Input bar uses the same panel template as the chat panels - gold hairline top, channel-colour left strip.",
		},
		changesDE = {
			"Eingabeleiste nicht mehr dauerhaft sichtbar: wird nur angezeigt, waehrend eine Editbox offen ist.",
			"Eingabeleiste nutzt dasselbe Panel-Template wie die Chat-Panels - goldene Haarlinie oben, kanalfarbiger Streifen links.",
		},
	},
	{
		version = "0.2.34",
		date = "2026-11-23",
		changes = {
			"Edit bar completely rebuilt: previous versions rendered behind the panel (LOW strata, invisible) or stacked conflicting layers that cancelled each other out. New bar lives at DIALOG strata level 5, slightly lighter dark fill, 1px border, gold hairline at the top edge, 3px channel-coloured left strip. Fixed 26px height so text, hairline and border all have room.",
		},
		changesDE = {
			"Eingabeleiste komplett neu gebaut: Vorige Versionen renderten hinter dem Panel (LOW-Strata, unsichtbar) oder stapelten konkurrierende Layer, die sich gegenseitig aufhoben. Die neue Leiste liegt auf DIALOG-Strata Level 5, etwas hellerer dunkler Fill, 1px Rahmen, goldene Haarlinie oben, 3px kanalfarbiger linker Streifen. Feste 26px Hoehe, damit Text, Haarlinie und Rahmen Platz haben.",
		},
	},
	{
		version = "0.2.33",
		date = "2026-11-23",
		changes = {
			"Edit bar now carries the gold top hairline the data bars use (inset past the corner arc), so the input strip reads as the same band family as the XP/rep bar above the panels.",
		},
		changesDE = {
			"Die Eingabeleiste traegt jetzt die goldene Oberkanten-Haarlinie der Data Bars (hinter die Eckrundung eingesetzt), damit sie als dieselbe Leisten-Familie wie die EP-/Ruf-Leiste ueber den Panels wirkt.",
		},
	},
	{
		version = "0.2.32",
		date = "2026-11-23",
		changes = {
			"Edit bar height now follows the Data Bars height setting (default 14px): the gold input strip, the XP bar and the rep bar all read as one uniform band. Gloss is anchored to the bar's center so it scales with the height.",
		},
		changesDE = {
			"Die Hoehe der Eingabeleiste folgt jetzt der Data-Bars-Hoeheneinstellung (Standard 14px): die goldene Eingabeleiste, EP- und Ruf-Leiste lesen sich als ein einheitliches Band. Der Gloss ist am Leistenmittelpunkt verankert und skaliert mit der Hoehe.",
		},
	},
	{
		version = "0.2.31",
		date = "2026-11-23",
		changes = {
			"Edit bar template switched from raised to inset: the thin gold wireframe on black read as a hollow rectangle. Now a dark recessed field - gold stays on the left accent strip and the corner ticks.",
		},
		changesDE = {
			"Eingabeleiste von Raised auf Inset umgestellt: der duenne Goldrahmen auf Schwarz wirkte wie ein leeres Wireframe. Jetzt ein dunkles eingelassenes Feld - Gold bleibt nur am linken Akzentstreifen und den Eck-Ticks.",
		},
	},
	{
		version = "0.2.30",
		date = "2026-11-23",
		changes = {
			"Edit bar restyled to the full Sentinel panel recipe: inner fade gradient (same as the chat panels), top-half gloss, left gold accent strip, corner ticks at the bottom, 26px tall and docked flush (1px gap) under the chat panel instead of floating loose.",
		},
		changesDE = {
			"Eingabeleiste auf das volle Sentinel-Panel-Rezept umgestylt: innerer Fade-Verlauf (wie bei den Chat-Panels), Gloss in der oberen Haelfte, goldener Akzentstreifen links, Eck-Ticks unten, 26px hoch und bündig (1px Abstand) unter dem Chat-Panel angedockt statt frei zu schweben.",
		},
	},
	{
		version = "0.2.29",
		date = "2026-11-23",
		changes = {
			"The chat input is now a real styled bar: templating the Blizzard edit box directly rendered through its NineSlice as a thin black sliver. A dedicated SentiUIChatEditBar (dark raised fill, gold border, accent strip, 24px tall) sits behind the box; the box itself is transparent and fills it. Click the bar to focus, channel color now tints the bar's border.",
		},
		changesDE = {
			"Die Chat-Eingabe ist jetzt eine echte gestylte Leiste: Das Templating der Blizzard-Editbox renderte ueber deren NineSlice als duenner schwarzer Streifen. Eine eigene SentiUIChatEditBar (dunkler Raised-Fill, Goldrand, Akzentstreifen, 24px hoch) liegt hinter der Box; die Box selbst ist transparent und fuellt sie. Klick auf die Leiste fokussiert, die Kanalfarbe faerbt jetzt den Rahmen der Leiste.",
		},
	},
	{
		version = "0.2.28",
		date = "2026-11-23",
		changes = {
			"Chat no longer jumps out of the panel on level up: the client re-anchors chat windows several seconds apart (banner, spec/spell toasts, floating text each trigger their own pass) and the old 1.5s burst only caught the first shove. The snap-back burst now runs 5s with full dock passes at 0.6s / 1.6s / 3s / 5s.",
		},
		changesDE = {
			"Chat springt beim Level-Up nicht mehr aus dem Panel: der Client verankert Chatfenster mehrfach im Abstand von Sekunden neu (Banner, Spec-/Zauber-Toasts und Floating Text loesen je einen eigenen Pass aus) und der alte 1.5s-Burst fing nur den ersten Schub ab. Der Snap-Back-Burst laeuft jetzt 5s mit vollen Dock-Paessen nach 0.6s / 1.6s / 3s / 5s.",
		},
	},
	{
		version = "0.2.27",
		date = "2026-11-23",
		changes = {
			"Scrollbars and scroll buttons no longer jump: Blizzard re-shows the chat ScrollBar, ScrollToBottomButton and the button-frame up/down arrows on scroll events, so they flickered back until the next restyle tick. Each one now gets an OnShow -> Hide guard on top of alpha 0 - hidden for good.",
			"Edit box no longer jumps on open: Blizzard's header/resize passes re-anchor the edit box for a frame or two before the anchor watchdog caught it. A per-frame fast path re-anchors a shown edit box the same frame.",
			"Edit box polish: 6px text insets so the caret no longer hugs the border, plus the Sentinel gold accent strip on the left edge.",
		},
		changesDE = {
			"Scrollbalken und Scroll-Buttons springen nicht mehr: Blizzard zeigt den Chat-ScrollBar, den ScrollToBottomButton und die Hoch/Runter-Pfeile im Button-Frame bei Scroll-Events wieder an - sie flackerten bis zum naechsten Restyle-Tick auf. Jeder bekommt jetzt zusaetzlich zu Alpha 0 eine OnShow -> Hide-Sperre - dauerhaft weg.",
			"Schreibleiste springt beim Oeffnen nicht mehr: Blizzards Header-/Resize-Pass verankert die Editbox fuer ein, zwei Frames neu, bevor der Anker-Watchdog griff. Ein Fast-Path pro Frame setzt eine sichtbare Editbox noch im selben Frame zurueck.",
			"Schreibleiste aufgehuebscht: 6px Text-Inset, damit der Cursor nicht mehr am Rand klebt, plus der goldene Sentinel-Akzentstreifen an der linken Kante.",
		},
	},
	{
		version = "0.2.26",
		date = "2026-11-22",
		changes = {
			"Chat tabs ride the generated ChatTab/ChatTabActive plates instead of a tinted blank fill - the active tab swaps to its own plate art, inactive tabs dim the same texture.",
		},
		changesDE = {
			"Chat-Tabs nutzen die generierten ChatTab/ChatTabActive-Plates statt einer gefaerbten Leer-Fuellung - der aktive Tab wechselt auf seine eigene Plate-Art, inaktive Tabs dimmen dieselbe Textur.",
		},
	},
	{
		version = "0.2.25",
		date = "2026-11-22",
		changes = {
			"The loot window's floating channel tab is now hidden while the window lives inside the right chat panel - it poked out over the panel's top edge and clicking it toggled the whole chat frame off. It is also taken off the mouse so no click can reach it.",
			"Loot window detection hardened: the frame itself is remembered and matched, plus the German \"Plündern\" label - previously a loot window whose tab label did not match the list was never docked into the right panel and floated loose with its tab sticking out.",
		},
		changesDE = {
			"Der freischwebende Channel-Tab des Beute-Fensters wird jetzt ausgeblendet, solange das Fenster im rechten Chat-Panel liegt - er ragte ueber die obere Panel-Kante hinaus und ein Klick darauf schaltete das ganze Chatfenster aus. Er ist zusaetzlich nicht mehr klickbar.",
			"Beute-Fenster-Erkennung gehaertet: der Frame selbst wird gemerkt und verglichen, plus das deutsche Label \"Plündern\" - vorher wurde ein Beute-Fenster, dessen Tab-Label nicht in der Liste stand, nie ins rechte Panel gedockt und schwebte mit herausragendem Tab frei herum.",
		},
	},
	{
		version = "0.2.24",
		date = "2026-11-22",
		changes = {
			"Chat tabs now have a dark inset background chip: each tab gets a subtle dark fill (80% opacity active, 55% inactive) so the tab label reads clearly against the game world. The gold hairline at the bottom shows only on the active tab.",
			"Chat copy frame close button replaced with the shared W.Close — consistent Sentinel look instead of the Blizzard UIPanelCloseButton.",
			"Bottom corner ticks fixed: the right tick hung 4px outside the panel edge (same sign for both sides); both are now mirrored and inset past the rounded corner arc.",
			"The panel fade layer is now inset 7px so it can no longer show a dark square wedge behind each rounded corner.",
		},
		changesDE = {
			"Chat-Tabs haben jetzt einen dunklen Inset-Hintergrund-Chip: Jeder Tab bekommt einen dezenten dunklen Fill (80% aktiv, 55% inaktiv), damit das Tab-Label klar lesbar gegen die Spielwelt ist. Die goldene Haarlinie am unteren Rand ist nur beim aktiven Tab sichtbar.",
			"Schliessen-Button im Chat-Kopierfenster durch das gemeinsame W.Close ersetzt — einheitliches Sentinel-Aussehen statt dem Blizzard-UIPanelCloseButton.",
			"Eck-Ticks unten gefixt: der rechte Tick hing 4px ausserhalb der Panel-Kante (gleiches Vorzeichen fuer beide Seiten); beide sind jetzt gespiegelt und hinter die gerundete Ecke eingesetzt.",
			"Die Fade-Ebene des Panels ist jetzt 7px eingesetzt, damit hinter den abgerundeten Ecken kein dunkler Keil mehr durchscheint.",
		},
	},
	{
		version = "0.2.23",
		date = "2026-11-22",
		changes = {
			"Chat sizes scale for real now: neither frame:SetFont nor the Font object path reach a ScrollingMessageFrame on this client - the game's own wrapper FCF_SetChatWindowFontSize(nil, frame, size) is the path that works, and every size change (settings, installer, watchdog) goes through it now. The outline still applies via the Font object path when it differs.",
			"The watchdog re-pushes a drifted size only when the observed size actually moved, so a font API that never reflects the push cannot rebuild the chat lines every quarter second.",
			"The installer chat step no longer bails on an unready module - an empty step was cached forever; the controls now always render and write settings the module picks up when it runs.",
		},
		changesDE = {
			"Chat-Groessen skalieren jetzt wirklich: weder frame:SetFont noch der Font-Objekt-Pfad erreichen ein ScrollingMessageFrame auf diesem Client - der eigene Wrapper des Spiels FCF_SetChatWindowFontSize(nil, frame, size) ist der Weg, der funktioniert, und jede Groessenaenderung (Einstellungen, Installer, Watchdog) läuft jetzt darueber. Die Kontur greift weiterhin ueber den Font-Objekt-Pfad, wenn sie abweicht.",
			"Der Watchdog pusht eine abweichende Groesse nur noch, wenn die beobachtete Groesse sich wirklich bewegt hat - eine Font-API, die den Push nie reflektiert, kann so nicht alle Viertelsekunde die Chatzeilen neu bauen.",
			"Der Installer-Chat-Schritt bricht nicht mehr bei einem unbereiten Modul ab - ein leerer Schritt wurde fuer immer gecacht; die Bedienelemente erscheinen jetzt immer und schreiben Einstellungen, die das Modul uebernimmt, sobald es laeuft.",
		},
	},
	{
		version = "0.2.22",
		date = "2026-11-22",
		changes = {
			"Chat font sizes now actually apply: frame.SetFont silently does nothing on this client, so every size change (settings, installer, watchdog) went into the database while the visible size stayed whatever the game had cached. Fonts go through a real Font object via SetFontObject now, verified with GetFont, plain SetFont as fallback - the same reliable path the rest of the suite uses. Tab texts included.",
			"The watchdog no longer adopts a size that was never applied: a silent font failure used to be read back as a 'menu change' and overwrote the saved choice.",
			"The loot chat window reopens when it was closed by hand: EnsureLootChat shows the found window again and the dock pass re-anchors it into the right panel.",
		},
		changesDE = {
			"Chat-Schriftgroessen greifen jetzt wirklich: frame.SetFont tut auf diesem Client still nichts - jede Groessenaenderung (Einstellungen, Installer, Watchdog) landete in der Datenbank, waehrend die sichtbare Groesse beim vom Spiel gespeicherten Wert blieb. Schriften laufen jetzt ueber ein echtes Font-Objekt via SetFontObject, verifiziert mit GetFont, plain SetFont als Fallback - derselbe verlaessliche Pfad wie in der ganzen Suite. Auch die Tab-Texte.",
			"Der Watchdog uebernimmt keine Groesse mehr, die nie angewendet wurde: ein stummer Font-Fehler wurde bisher als 'Menue-Aenderung' gelesen und hat die gespeicherte Wahl ueberschrieben.",
			"Das Beute-Chatfenster oeffnet sich wieder, wenn es von Hand geschlossen wurde: EnsureLootChat zeigt das gefundene Fenster erneut an und der Dock-Durchlauf verankert es im rechten Panel.",
		},
	},
	{
		version = "0.2.21",
		date = "2026-11-22",
		changes = {
			"New installer step 'Chat': font size and tab font size sliders, the loot chat window toggle and the panel backdrop dropdown. Everything applies live through the module's setting path - every chat window (general, loot, whispers ...) takes the size immediately and the loot window is created and docked on the spot.",
		},
		changesDE = {
			"Neuer Installer-Schritt 'Chat': Schriftgroessen- und Tab-Schriftgroessen-Slider, der Beute-Chatfenster-Schalter und das Panel-Hintergrund-Dropdown. Alles greift sofort ueber den eigenen Einstellungspfad des Moduls - jedes Chatfenster (Allgemein, Beute, Fluestern ...) uebernimmt die Groesse sofort, und das Beute-Fenster wird direkt erstellt und angedockt.",
		},
	},
	{
		version = "0.2.20",
		date = "2026-11-22",
		changes = {
			"Default chat background came back after every reload: the frame styling ran once per frame and Blizzard's chat init finished after it, repainting the default background and buttons over the styled frame. The chrome kill is idempotent now and re-runs in the watchdog for every frame, plus a NineSlice/backdrop kill for backgrounds that are not plain regions.",
			"Font size arbitration after login: a mismatch seen in the first 15 seconds is Blizzard's chat-cache restore clobbering our application and gets put back to the saved size; a later mismatch is a live tab-menu change and is adopted into the settings. Before, the sync read the wrong GetFont return and never fired at all.",
			"The own-timestamp switch now uses C_CVar.SetCVar - the legacy SetCVar global is not guaranteed on this client.",
		},
		changesDE = {
			"Der Standard-Chat-Hintergrund kam nach jedem Neuladen zurueck: Das Frame-Styling lief pro Frame nur einmal und Blizzards Chat-Initialisierung beendete sich danach - sie malte Hintergrund und Buttons neu ueber das gestylte Frame. Der Chrome-Kill ist jetzt idempotent und laeuft im Watchdog fuer jedes Frame mit, plus NineSlice/Backdrop-Kill fuer Hintergruende, die keine einfachen Regionen sind.",
			"Font-Groessen-Schlichtung nach dem Login: Eine Abweichung in den ersten 15 Sekunden ist Blizzards Chat-Cache-Restore, der unsere Anwendung ueberschreibt - sie wird auf die gespeicherte Groesse zurueckgesetzt; eine spaetere Abweichung ist eine Live-Aenderung uebers Tab-Menue und wird in die Einstellungen uebernommen. Vorher las der Sync den falschen GetFont-Rueckgabewert und griff nie.",
			"Der eigene Zeitstempel-Schalter nutzt jetzt C_CVar.SetCVar - das legacy SetCVar-Global ist auf diesem Client nicht garantiert.",
		},
	},
	{
		version = "0.2.19",
		date = "2026-11-22",
		changes = {
			"Chat font size now persists no matter where it is changed: a size set through Blizzard's tab menu is written back into the module settings, so the next login applies your choice instead of resetting to the default 12.",
			"Font calls are now skipped when nothing changed - every SetFont rebuilds all chat lines and their links, so the unconditional per-tick calls could swallow link clicks.",
		},
		changesDE = {
			"Die Chat-Schriftgröße bleibt jetzt erhalten, egal wo sie geändert wird: Eine über Blizzards Tab-Menü eingestellte Größe wird in die Modul-Einstellungen zurückgeschrieben - beim nächsten Login wird deine Wahl angewendet statt auf 12 zurückzusetzen.",
			"Font-Aufrufe werden jetzt übersprungen, wenn sich nichts geändert hat - jedes SetFont baut alle Chatzeilen samt Links neu auf, die bisherigen Aufrufe pro Tick konnten Link-Klicks verschlucken.",
		},
	},
	{
		version = "0.2.18",
		date = "2026-11-22",
		changes = {
			"Loot lines now stay in the Loot window: every other chat window loses the loot, money and gain message groups - before, the same lines showed in the general chat and the Loot window at once.",
		},
		changesDE = {
			"Beutezeilen bleiben jetzt im Beute-Fenster: Jedes andere Chatfenster verliert die Beute-, Geld- und Gewinn-Meldungsgruppen - vorher erschienen dieselben Zeilen im allgemeinen Chat und im Beute-Fenster zugleich.",
		},
	},
	{
		version = "0.2.17",
		date = "2026-11-22",
		changes = {
			"New 'Loot chat window' option (on by default): a chat window named Loot is created automatically, stripped to loot, money and gain message groups only, and docked in the right panel - before, nothing ever created that window, so the right panel stayed empty.",
		},
		changesDE = {
			"Neue Option 'Beute-Chatfenster' (an): ein Chatfenster namens Beute wird automatisch erstellt, auf Beute-, Geld- und Gewinn-Meldungsgruppen beschraenkt und im rechten Panel angedockt - vorher legte nichts dieses Fenster an, das rechte Panel blieb leer.",
		},
	},
	{
		version = "0.2.16",
		date = "2026-11-22",
		changes = {
			"Chat panels and the docked chat now re-run their sizing pass on DISPLAY_SIZE_CHANGED and UI_SCALE_CHANGED - before, a resolution or UI-scale change left the chat at its stale size until a manual resize.",
		},
		changesDE = {
			"Chat-Panels und das angedockte Chatfenster fuehren ihren Groessen-Pass jetzt bei DISPLAY_SIZE_CHANGED und UI_SCALE_CHANGED erneut aus - vorher blieb der Chat nach einer Aufloesungs- oder Skalierungsaenderung in seiner alten Groesse bis zum manuellen Nachziehen.",
		},
	},
	{
		version = "0.2.15",
		date = "2026-11-22",
		changes = {
			"Smiley pass fixes: codes now need real boundaries, so ':3' inside a '04:39' timestamp and 'xD'/'o.O' inside names no longer tear into icons - while a smiley glued to a word ('moment;)') still converts. New codes: xD, XD, D:, ;D, ;P, :o, :3, :|, :/, :*, >:(, :'(, :').",
			"URL fix: links created by the url pass were unmasked when the smiley pass ran - a smiley code inside a linkified url tore the |H markup. Fresh |Hurl links are masked before smileys now.",
		},
		changesDE = {
			"Smiley-Pass-Fixes: Codes brauchen jetzt echte Grenzen, sodass ':3' in einem '04:39'-Zeitstempel und 'xD'/'o.O' in Namen nicht mehr zu Icons reissen - ein angeklebter Smiley ('moment;)') konvertiert trotzdem. Neue Codes: xD, XD, D:, ;D, ;P, :o, :3, :|, :/, :*, >:(, :'(, :').",
			"URL-Fix: vom URL-Pass erzeugte Links waren beim Smiley-Pass unmaskiert - ein Smiley-Code in einer linkifizierten URL riss das |H-Markup auf. Frische |Hurl-Links werden jetzt vor den Smileys maskiert.",
		},
	},
	{
		version = "0.2.14",
		date = "2026-11-22",
		changes = {
			"URL copy dialog, chat copy window and emote picker now use the own dialog/Escape handling instead of StaticPopupDialogs and UISpecialFrames.",
			"Removed the 'sticky channels' option: it wrote into ChatTypeInfo, and every addon-written value there taints the Enter dispatch that later calls the protected SendChatMessage. Channel stickiness now follows the client's own defaults.",
		},
		changesDE = {
			"URL-Kopierdialog, Kopierfenster und Emote-Picker nutzen jetzt den eigenen Dialog bzw. eigene Escape-Behandlung statt StaticPopupDialogs und UISpecialFrames.",
			"Option 'Sticky-Kanaele' entfernt: sie schrieb in ChatTypeInfo, und jeder dort von einem Addon geschriebene Wert taintet den Enter-Dispatch, der spaeter das geschuetzte SendChatMessage aufruft. Die Kanal-Stickiness folgt jetzt den Client-Standards.",
		},
	},
	{
		version = "0.2.13",
		date = "2026-11-22",
		changes = {
			"Fix the edit box losing its style: NineSlice was alpha'd before SetBackdrop - the backdrop draws through NineSlice, so the raised fill/border never rendered (transparent bar with gold focus brackets). The watchdog now also retries styling for late-created edit boxes and re-hides the header chrome every tick.",
		},
		changesDE = {
			"Editbox-Style repariert: NineSlice wurde vor SetBackdrop auf Alpha 0 gesetzt - das Backdrop zeichnet ueber die NineSlice, also wurden Fuellung und Rahmen nie gerendert (durchscheinender Balken mit goldenen Fokus-Winkeln). Der Watchdog holt das Styling fuer spaet erzeugte Editboxen nach und versteckt den Header-Chrome jeden Tick erneut.",
		},
	},
	{
		version = "0.2.12",
		date = "2026-11-22",
		changes = {
			"All post-hooks on Blizzard layout and chat functions are gone (UIParent_ManageFramePositions, FCF_*, ChatEdit_UpdateHeader, tab clicks): they ran inside input/panel dispatches and tainted them - the probable source of blocked SendChatMessage and secret-compare errors when windows opened. One 0.25s watchdog now re-docks the chat, restyles new frames, re-colors tabs and edit box borders and re-anchors the edit box.",
		},
		changesDE = {
			"Alle Post-Hooks auf Blizzard-Layout- und Chat-Funktionen sind weg (UIParent_ManageFramePositions, FCF_*, ChatEdit_UpdateHeader, Tab-Klicks): Sie liefen in Input-/Panel-Dispatches und vergifteten sie - die wahrscheinliche Quelle geblockter SendChatMessage-Aufrufe und Geheimwert-Fehler beim Fenster-Öffnen. Ein 0,25s-Watchdog dockt den Chat an, stylt neue Fenster, färbt Tabs und Editbox-Ränder und verankert die Editbox neu.",
		},
	},
	{
		version = "0.2.11",
		changes = {
			"Compile fix: UpdateKeywords assigned to the for-loop variable, which LuaJIT rejects as a const assign - the whole Chat.lua failed to load. Loop variable is now shadowed by a local.",
		},
		changesDE = {
			"Compile-Fix: UpdateKeywords wies der Schleifenvariable zu, was LuaJIT als Const-Assign ablehnt - die ganze Chat.lua lud nicht. Die Schleifenvariable ist jetzt ein lokales Shadowing.",
		},
	},

	{
		version = "0.2.10",
		changes = {
			"Chat copy window: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.",
		},
		changesDE = {
			"Das Fenster haengt an der Kampf-Verzoegerung: Oeffnen im Kampf wird mit Chat-Notiz nach dem Kampf nachgeholt, ein offenes Fenster versteckt sich bei Kampfbeginn und kehrt danach zurueck.",
		},
	},

	{
		version = "0.2.9",
		changes = {
			"Escape-forbidden-call fix: OnEscapePressed handlers on the URL popup and copy-chat window ran inside the Escape dispatch - both close natively via hideOnEscape/UISpecialFrames now.",
		},
		changesDE = {
			"Escape-Blockier-Fix: OnEscapePressed-Handler am URL-Popup und Copy-Chat-Fenster liefen im Escape-Dispatch - beide schliessen jetzt nativ ueber hideOnEscape/UISpecialFrames.",
		},
	},

	{
		version = "0.2.8",
		changes = {
			"Fixed the 'attempt to index global t' error on level ups: the snap-back ticker captured its handle before the local existed, so the 15th tick indexed a nil global. The ticker variable is now declared before the NewTicker call.",
		},
		changesDE = {
			"Den 'attempt to index global t'-Fehler bei Level-Ups behoben: Der Snapback-Ticker griff auf seinen Handle zu, bevor das Local existierte, sodass der 15. Tick ein nil-Global indizierte. Die Ticker-Variable wird jetzt vor dem NewTicker-Aufruf deklariert.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Fixed repeated errors on messages with secret sender values: the player-level filter guarded the message text but passed the raw sender into ShortName, which called :gsub on it - on this client sender can be a secret value, so every such message threw. The filter now skips secret senders and ShortName itself returns nil for non-plain strings.",
		},
		changesDE = {
			"Wiederholte Fehler bei Nachrichten mit geheimen Sender-Werten behoben: Der Spielerlevel-Filter prüfte den Nachrichtentext, reichte den rohen Sender aber an ShortName weiter, das :gsub darauf aufrief - auf diesem Client kann der Sender ein Secret-Value sein, also warf jede solche Nachricht. Der Filter überspringt jetzt geheime Sender und ShortName gibt für nicht-einfache Strings nil zurück.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Player links with names like 'Prinz Nexo' no longer tear: the link mask only matched |H..|h label |h pairs, but this client separates some link payloads with a single pipe - ':P' inside 'player:Prinz' was still reachable by the smiley pass. A second mask pass now covers leftover |H..|h payloads.",
		},
		changesDE = {
			"Spieler-Links mit Namen wie 'Prinz Nexo' reißen nicht mehr auf: Die Link-Maske fing nur |H..|h Label |h-Paare, doch dieser Client trennt manche Link-Payloads mit einer einzelnen Pipe - ':P' in 'player:Prinz' blieb für den Smiley-Pass erreichbar. Ein zweiter Masken-Pass deckt jetzt übrige |H..|h-Payloads ab.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"The copy-chat window is a real mover now: its own entry in move mode and Movers.Save persistence, so it reopens where you left it.",
		},
		changesDE = {
			"Das Chat-Kopierfenster ist jetzt ein echter Mover: eigener Eintrag im Verschiebe-Modus und Movers.Save-Persistenz - es öffnet wieder dort, wo du es gelassen hast.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Killed the visible chat jump on level up: instead of re-docking ChatFrame1 half a second after Blizzard's pass, its anchor is now re-asserted inside the same Lua pass - hooksecurefunc post-calls on the client's chat/dock positioning functions (FCF_SetWindowPosition, FCF_RestorePositionAndDimensions, FCF_DockUpdate, FloatingChatFrame_Update, UIParent_ManageFramePositions, ...) plus a short burst check after PLAYER_LEVEL_UP and the ignoreFramePositionManager attribute, so a displaced frame never reaches the screen.",
		},
		changesDE = {
			"Der sichtbare Chat-Sprung beim Level-Up ist weg: Statt ChatFrame1 erst eine halbe Sekunde nach Blizzards Lauf zurückzudocken, wird der Anker jetzt im selben Lua-Pass wieder gesetzt - hooksecurefunc-Post-Calls auf die Chat-/Dock-Positionierfunktionen des Clients (FCF_SetWindowPosition, FCF_RestorePositionAndDimensions, FCF_DockUpdate, FloatingChatFrame_Update, UIParent_ManageFramePositions, ...), dazu ein kurzer Burst-Check nach PLAYER_LEVEL_UP und das ignoreFramePositionManager-Attribut - ein verschobener Frame kommt so nie auf den Bildschirm.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Fixed broken player links in chat (raw |Hplayer text and icon garbage in names): the hyperlink mask only matched links whose label contains a bracket, so player links like |Hplayer:...|hName|h stayed unmasked and the smiley pass cut \":P\" out of names like \"Priemelchen\", tearing the whole link markup apart. All hyperlink labels now mask before the url/smiley passes.",
		},
		changesDE = {
			"Fix: Kaputte Spieler-Links im Chat (rohes |Hplayer und Icon-Müll in Namen): Die Hyperlink-Maske fing nur Links mit eckiger Klammer im Label, sodass Spieler-Links wie |Hplayer:...|hName|h unmaskiert blieben und die Smiley-Ersetzung aus Namen wie \"Priemelchen\" ein \":P\" rausschnitt - das Link-Markup riss komplett auf. Jetzt werden alle Hyperlink-Labels vor den URL-/Smiley-Pässen maskiert.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Fixed the chat frame jumping out of its panel after a level up: the client re-anchors chat windows on level ups and dock passes (the tabs stayed put because they hang on the dock manager, the frame itself was moved mid-screen). ChatFrame1 now re-docks whenever its anchor no longer points at the chat panel - checked once per second, skipped in combat - and PLAYER_LEVEL_UP triggers a delayed re-position after Blizzard's own pass settles.",
		},
		changesDE = {
			"Chat-Frame sprang nach einem Level-Up aus seinem Panel: Der Client verankert Chatfenster bei Level-Ups und Dock-Läufen neu (die Tabs hingen am Dock-Manager und blieben oben, der Frame landete mitten auf dem Bildschirm). ChatFrame1 dockt jetzt automatisch wieder an, sobald sein Anker nicht mehr auf das Chat-Panel zeigt - einmal pro Sekunde geprüft, im Kampf pausiert - und PLAYER_LEVEL_UP löst ein verzögertes Repositionieren aus, nachdem Blizzards eigener Lauf durch ist.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Quest references typed as plain text - [19] Name (questID) - are wrapped into real |Hquest hyperlinks so they can be clicked like normal links. Toggle: \"Clickable quest links\".",
		},
		changesDE = {
			"Quest-Verweise als Reintext - [19] Name (QuestID) - werden in echte |Hquest-Hyperlinks gewrappt und sind damit wie normale Links klickbar. Option: \"Klickbare Questlinks\".",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Proper emoji palette: the old 7-icon row became a real grid - 60 emotes in an 8-column panel with title bar, inset cells, hover accent and :name: tooltips. Classic smiley codes like :) or <3 still render, now mapped onto the same icon set, and Discord-style :name: codes work too: type :joy:, :fire:, :thumbsup: and they render as icons.",
		},
		changesDE = {
			"Echte Emoji-Palette: Aus der 7-Icon-Zeile wurde ein richtiges Gitter - 60 Emotes in einem 8-Spalten-Panel mit Titelzeile, Inset-Zellen, Hover-Accent und :name:-Tooltips. Klassische Codes wie :) oder <3 rendern weiter, jetzt auf dasselbe Icon-Set gemappt, und Discord-artige :name:-Codes gehen auch: :joy:, :fire:, :thumbsup: werden als Icons gerendert.",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"Rebuilt the channel, voice and chat-menu buttons as a proper strip: instead of sitting on Blizzard's default anchors half outside the panel, they are now 16px inset chips lined up in the tab row right in front of the emoji chip - dimmed until hovered, accent border on hover, re-anchored after dock updates so the game cannot pull them back.",
		},
		changesDE = {
			"Die Channel-, Voice- und Chatmenü-Buttons sind jetzt ein eigener Strip: Statt an Blizzards Standard-Ankern halb außerhalb des Panels zu hängen, sind es 16px-Inset-Chips in der Tab-Zeile direkt vor dem Emoji-Chip - abgedimmt bis Hover, Accent-Rahmen bei Hover, nach Dock-Updates neu verankert, damit das Spiel sie nicht zurückzieht.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Fixed the regression from the scroll-chip rebuild: HookScript threw on script names this client does not know (OnMessageScrollChanged, possibly OnHyperlinkEnter/Leave) - that aborted StyleChatFrame mid-way so everything after the scroll chip (tabs, edit box, copy button, hyperlink tooltips) never ran. All HookScript calls on chat frames now go through pcall.",
		},
		changesDE = {
			"Die Regression aus dem Scroll-Chip-Umbau ist gefixt: HookScript warf bei Scriptnamen, die dieser Client nicht kennt (OnMessageScrollChanged, evtl. OnHyperlinkEnter/Leave) - das brach StyleChatFrame mitten drin ab, sodass alles nach dem Scroll-Chip (Tabs, Eingabezeile, Copy-Button, Link-Tooltips) nie lief. Alle HookScript-Calls auf Chatframes laufen jetzt per pcall.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Isolated every module enable step (panels, buttons, emoji, filters, scans, positioning) so a failure in one can no longer abort the rest - each now reports with its own chat:* tag so the failing piece is identifiable instead of leaving the whole chat unstyled.",
		},
		changesDE = {
			"Jeder Enable-Schritt (Panels, Buttons, Emoji, Filter, Scans, Positionierung) läuft jetzt einzeln isoliert - ein Fehler bricht den Rest nicht mehr ab und jeder Schritt meldet sich mit eigenem chat:*-Tag, sodass der werfende Teil identifizierbar ist statt den ganzen Chat ungestylt zu lassen.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Hardened the whole style + position pass: every block now runs guarded so one bad frame can no longer skip the rest - which is what left the chat bar unstyled and unanchored. The edit box also resolves Blizzard's shared ChatFrameEditBox fallback, re-asserts its anchor on show and after ChatEdit_SetLastActiveWindow / dock updates, and secret-value reads in GetRegions/GetFont/GetMaxLines are pcall'd.",
		},
		changesDE = {
			"Der komplette Style- + Positionierungslauf ist jetzt abgesichert: Jeder Block läuft einzeln geguarded, damit ein kaputter Frame den Rest nicht mehr überspringt - genau das ließ die Chatleiste ungestylt und ohne Anker. Die Eingabezeile nutzt jetzt auch Blizzards geteilte ChatFrameEditBox-Fallback, setzt ihren Anker bei OnShow sowie nach ChatEdit_SetLastActiveWindow/Dock-Updates neu, und Secret-Value-Lesevorgänge in GetRegions/GetFont/GetMaxLines laufen per pcall.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"Fixed the chat never docking into the panel: PositionChat died during enable - FCF_SavePositionAndDimensions was not wrapped and unnamed temporary chat frames could break the name lookups. Every frame now styles on its own, the dock manager and tab colors are guarded, so one bad frame can no longer take the whole layout down.",
		},
		changesDE = {
			"Der Chat dockte nicht ins Panel: PositionChat starb beim Enable - FCF_SavePositionAndDimensions war nicht abgesichert und namenlose temporäre Chatfenster konnten die Namensauflösung brechen. Jetzt styled jeder Frame einzeln abgesichert, Dock-Manager und Tabfarben sind geguarded - ein kaputter Frame reißt das Layout nicht mehr mit.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"The edit box now sits below the chat by default; existing profiles are migrated once. The position stays switchable in the options.",
		},
		changesDE = {
			"Die Eingabezeile liegt jetzt standardmäßig unter dem Chat; bestehende Profile werden einmalig umgestellt. Die Position bleibt in den Optionen wählbar.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Fixed the scroll-to-bottom chip doing nothing: Blizzard's own button was reparented, which broke its click handler. It is a proper SentiUI chip now that scrolls the frame itself and only shows while you are scrolled up.",
		},
		changesDE = {
			"Der Nach-unten-Chip tat nichts: Blizzard's eigener Button wurde umparentet und sein Klick-Handler lief ins Leere. Jetzt ist es ein echter SentiUI-Chip, der selbst scrollt und nur sichtbar ist, wenn man hochgescrollt hat.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Fixed the copy chip: its text now fills the button and centers properly instead of spilling out.",
			"Emoticons: :) ;-) :D :( :P <3 o.O ^^ render as the Sentinel pixel icons in chat, and a ':)' chip in the tab strip opens a picker that inserts codes into the edit box.",
			"Channel, voice and chat menu buttons are no longer hidden - they sit next to the chat dimmed until hovered, toggleable in the options.",
		},
		changesDE = {
			"Kopier-Chip gefixt: Der Text füllt jetzt den Button und zentriert sauber statt herauszuragen.",
			"Emoticons: :) ;-) :D :( :P <3 o.O ^^ werden als Sentinel-Pixel-Icons im Chat gerendert, und ein ':)'-Chip in der Tab-Leiste öffnet einen Wähler, der Codes in die Eingabezeile einfügt.",
			"Kanal-, Voice- und Chatmenü-Buttons werden nicht mehr versteckt - sie liegen abgedimmt neben dem Chat, abschaltbar in den Optionen.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Panels now match the SentiUI look: the bordered dark panel every window uses, an accent hairline under the tab row and accent corner ticks at the bottom edge. 'Fade at top' still switches to the plain transparent shade.",
			"The copy button became a proper readable chip (inset style, accent text, lit border on hover); the copy window got the accent title line.",
			"The scroll-to-bottom button is a dark chip with an accent arrow now.",
		},
		changesDE = {
			"Panels sehen jetzt aus wie der Rest von SentiUI: dunkles Panel mit Rahmen, Accent-Linie unter den Tabs und Accent-Ecken unten. 'Oben ausblenden' schaltet weiterhin auf den transparenten Schatten um.",
			"Der Kopier-Button ist jetzt ein lesbarer Chip (Inset-Stil, Accent-Text, leuchtender Rahmen bei Hover); das Kopierfenster hat die Accent-Titellinie bekommen.",
			"Der Nach-unten-Button ist jetzt ein dunkler Chip mit Accent-Pfeil.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: Sentinel-styled chat for SentiUI - shade panels behind the dock (movable), restyled tabs with an accent underline, a borderless edit box above or below the chat that borrows the channel color.",
			"Message filter: short channel names, clickable links with a copy popup, keyword highlighting with an alert sound, timestamps in the panel color.",
			"Class-colored player names, player levels for known players, spam throttle, sticky channels, hyperlink hover tooltips, per-frame copy button and window, scroll-to-bottom arrow, optional chat history across reloads.",
		},
		changesDE = {
			"Erste Version: Sentinel-Chat für SentiUI - Schatten-Panels hinter dem Dock (verschiebbar), Tabs mit Accent-Unterstrich, rahmenlose Eingabezeile über oder unter dem Chat in Kanalfarbe.",
			"Nachrichtenfilter: kurze Kanalnamen, klickbare Links mit Kopier-Popup, Keyword-Hervorhebung mit Sound, Zeitstempel in Panelfarbe.",
			"Klassenfarbene Spielernamen, Level bekannter Spieler, Spam-Bremse, Sticky-Kanäle, Link-Tooltips, Kopier-Button und -Fenster je Frame, Nach-unten-Pfeil, optionale Chat-Historie über Reloads.",
		},
	},
}
