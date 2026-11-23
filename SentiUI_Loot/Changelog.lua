local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.2.17",
		date = "2026-11-23",
		changes = {
			"Blizzard loot frame no longer flashes visible: the alpha/mouse kill only ran a frame after the game showed it (deferred via C_Timer + the shown watch). It now fires synchronously inside every loot event dispatch and via hooksecurefunc on LootFrame_Show/LootFrame_Update, so the frame is neutralised inside the same pass it is shown in.",
		},
		changesDE = {
			"Blizzard-Lootfenster blitzt nicht mehr auf: der Alpha-/Maus-Kill lief erst einen Frame nach dem Zeigen (verzoegert via C_Timer + Shown-Watch). Er feuert jetzt synchron in jedem Loot-Event-Dispatch und via hooksecurefunc auf LootFrame_Show/LootFrame_Update - der Frame wird im selben Pass neutralisiert, in dem er gezeigt wird.",
		},
	},
	{
		version = "0.2.16",
		date = "2026-11-22",
		changes = {
			"Fixed the double loot window: the alpha/mouse kill that keeps the game's LootFrame out of the way only ran inside a shown-state watch registered at enable time - if LootFrame was created lazily on the first loot (load-on-demand), no watch ever registered and both windows stayed up. The kill now also runs on every own-window update and the watch uses the resolver form so a late-created frame is caught.",
			"Roll panel finishing pass: the scroll frame's scrollbar is actually anchored now (the UIPanelScrollFrame template leaves it unpositioned on this client, sitting in the right gutter the frame reserves). Mouse wheel on a roll card forwards to the panel scroll, roll glyph buttons show Need/Greed/Disenchant/Pass tooltips, and LOOT_ROLLS_COMPLETE clears all pending rolls at once instead of waiting for each card's timeout check.",
		},
		changesDE = {
			"Doppeltes Loot-Fenster behoben: der Alpha-/Maus-Kill, der den Blizzard-LootFrame versteckt, lief nur in einem beim Enable registrierten Shown-Watcher - wurde der LootFrame erst beim ersten Loot erzeugt (Load-on-Demand), registrierte sich nie ein Watcher und beide Fenster blieben offen. Der Kill laeuft jetzt bei jedem Fenster-Update und der Watcher nutzt die Resolver-Form, die spaet erzeugte Frames fängt.",
			"Feinschliff am Wuerfel-Panel: die Scrollbar des ScrollFrames ist jetzt wirklich verankert (das UIPanelScrollFrame-Template laesst sie auf diesem Client unpositioniert - sie sitzt in der rechten Rinne, die der Frame freihaelt). Mausrad auf einer Wuerfelkarte leitet ans Panel-Scroll weiter, die Glyphen-Buttons zeigen Bedarf/Gier/Entzaubern/Passen-Tooltips, und LOOT_ROLLS_COMPLETE raeumt alle offenen Wuerfe auf einmal auf statt auf den Timeout-Check jeder Karte zu warten.",
		},
	},
	{
		version = "0.2.15",
		date = "2026-11-22",
		changes = {
			"Roll cards now show the item tooltip on hover: the card frame never enabled mouse input and the icon is a plain texture that cannot take scripts, so hovering a party/raid roll showed nothing. The card now takes the hover itself and paints the item tooltip from the cached roll link; hovering also lights the card's border edge.",
		},
		changesDE = {
			"Wuerfelkarten zeigen jetzt den Item-Tooltip bei Hover: der Karten-Frame hatte die Maus nie aktiviert und das Icon ist eine reine Textur ohne Script-Moeglichkeit - Hover ueber einem Party-/Raid-Wurf zeigte also nichts. Die Karte nimmt den Hover jetzt selbst entgegen und zeigt den Item-Tooltip aus dem gecachten Roll-Link; der Hover beleuchtet ausserdem die Kartenkante.",
		},
	},
	{
		version = "0.2.14",
		date = "2026-11-22",
		changes = {
			"Fixed the recurring question-mark icons while looting: item data arrives async on this client, so the first draw often found nothing cached and every icon source came back empty. A new RetryIcon helper uses Item:CreateFromItemLink + ContinueOnItemLoad to re-resolve the icon the moment the item lands in the cache - applied to the loot window rows, roll cards and the loot feed. A suiIconLink guard stops stale callbacks from painting over recycled feed rows.",
			"Loot window close button replaced with the shared W.Close - consistent Sentinel look instead of the Blizzard UIPanelCloseButton.",
		},
		changesDE = {
			"Die wiederkehrenden Fragezeichen-Icons beim Looten behoben: Item-Daten kommen auf diesem Client asynchron an, beim ersten Zeichnen war oft nichts gecacht und jede Icon-Quelle lief leer. Ein neuer RetryIcon-Helper nutzt Item:CreateFromItemLink + ContinueOnItemLoad, um das Icon erneut aufzuloesen sobald das Item im Cache landet - fuer Loot-Fenster-Zeilen, Roll-Karten und den Loot-Feed. Ein suiIconLink-Guard verhindert, dass veraltete Callbacks ueber wiederverwendete Feed-Zeilen malen.",
			"Schliessen-Button des Loot-Fensters durch das gemeinsame W.Close ersetzt - einheitliches Sentinel-Aussehen statt dem Blizzard-UIPanelCloseButton.",
		},
	},
	{
		version = "0.2.13",
		date = "2026-11-22",
		changes = {
			"Roll card icons now clip to soft rounded corners via the rewritten core S.IconRound MaskTexture — the icon itself is cut instead of being covered by overlay tiles.",
		},
		changesDE = {
			"Roll-Karten-Icons werden jetzt ueber die neu geschriebene Core-S.IconRound-MaskTexture auf weich abgerundete Ecken geclippt — das Icon selbst wird geschnitten statt von Overlay-Kacheln verdeckt.",
		},
	},
	{
		version = "0.2.12",
		date = "2026-11-22",
		changes = {
			"Loot history close and clear buttons replaced: UIPanelCloseButton and UIPanelButtonTemplate swapped for the shared W.Close and W.Button — consistent Sentinel look across the whole suite.",
			"Roll card icons now have soft rounded corners via S.IconRound (4px, matching the card's inset template look).",
		},
		changesDE = {
			"Schliessen- und Leeren-Buttons im Loot-Verlauf ersetzt: UIPanelCloseButton und UIPanelButtonTemplate durch das gemeinsame W.Close und W.Button — einheitliches Sentinel-Aussehen in der ganzen Suite.",
			"Roll-Karten-Icons haben jetzt weiche abgerundete Ecken via S.IconRound (4px, passend zum Inset-Template der Karte).",
		},
	},
	{
		version = "0.2.11",
		date = "2026-11-22",
		changes = {
			"Loot icons finally show: the quality border was created on the OVERLAY layer and painted as a solid square on top of the icon - every item looked like a plain quality-colored box (roll cards, loot rows, feed rows, Blizzard button styling). The ring now sits on the BORDER layer so only the 1px frame peeks out.",
			"Roll button glyphs: a missing glyph texture (the disenchant sheet on this client) rendered as a grey box because SetTexture keeps dead paths. Glyph paths are now probed via GetFileIDFromPath when available, with fallback candidates and the letter fallback if nothing resolves.",
		},
		changesDE = {
			"Beute-Icons sind endlich sichtbar: der Qualitaetsrahmen lag auf dem OVERLAY-Layer und malte als gefuelltes Quadrat ueber dem Icon - jedes Item war nur ein qualitaetsfarbenes Kaestchen (Wuerfelkarten, Beute-Zeilen, Feed-Zeilen, Spiel-Buttons). Der Ring liegt jetzt auf dem BORDER-Layer, sodass nur der 1px-Rahmen herausschaut.",
			"Wuerfel-Button-Glyphen: eine fehlende Glyphen-Textur (das Entzaubern-Sheet auf diesem Client) zeigte einen grauen Kasten, weil SetTexture tote Pfade behaelt. Glyph-Pfade werden jetzt ueber GetFileIDFromPath geprueft (falls vorhanden), mit Alternativ-Pfaden und Buchstaben-Fallback, wenn nichts aufloest.",
		},
	},
	{
		version = "0.2.10",
		date = "2026-11-22",
		changes = {
			"The own loot window no longer dies instantly: hiding the game's LootFrame triggered its OnHide -> CloseLoot(), ending the loot session the moment it opened. The frame now gets alpha 0 and its mouse killed instead of hidden - the session stays alive, invisible.",
			"Icons actually verify now: SetTexture silently drops secret/bad values on this client, so every icon (loot rows, roll cards, feed) is checked with GetTexture after setting and walks fallbacks - slot data, the game button's own icon, C_Item.GetItemIconByID, GetItemInfo, then a question mark.",
			"The normal-loot modifier works again: IsModifiedClick can answer falsely on this client, so the held check reads the configured AUTOLOOTTOGGLE key via GetModifiedClick and tests the raw key state instead.",
			"The group roll panel is a real Sentinel card now: the client's roll frames are hidden and click-dead while our cards show icon + quality border, quality-colored name, an accent countdown bar and the dice/coin/disenchant/pass glyphs - clicks go through RollOnLoot, rolls vanish when resolved.",
		},
		changesDE = {
			"Das eigene Beutefenster stirbt nicht mehr sofort: das Verstecken des Spiel-LootFrame loeste dessen OnHide -> CloseLoot() aus und beendete die Beute-Session im selben Moment. Der Frame bekommt jetzt Alpha 0 und tote Maus statt Hide - die Session bleibt unsichtbar am Leben.",
			"Icons werden jetzt verifiziert: SetTexture verwirft geheime/kaputte Werte auf diesem Client still, daher wird jedes Icon (Beute-Zeilen, Wuerfelkarten, Feed) nach dem Setzen per GetTexture geprueft und läuft Fallbacks durch - Slot-Daten, Icon des Spiel-Buttons, C_Item.GetItemIconByID, GetItemInfo, dann Fragezeichen.",
			"Der Normal-Beute-Modifier geht wieder: IsModifiedClick kann auf diesem Client falsch antworten, daher liest der Check die konfigurierte AUTOLOOTTOGGLE-Taste ueber GetModifiedClick und prueft den rohen Tastenzustand.",
			"Das Wuerfel-Panel ist jetzt eine echte Sentinel-Karte: die Spiel-Rahmen sind versteckt und klick-tot, waehrend unsere Karten Icon + Qualitaetsrahmen, qualitaetsgefaerbten Namen, Akzent-Countdown und die Wuerfel-/Muenz-/Entzaubern-/Passen-Glyphen zeigen - Klicks gehen ueber RollOnLoot, erledigte Wuerfe verschwinden.",
		},
	},
	{
		version = "0.2.9",
		date = "2026-11-22",
		changes = {
			"Loot window stayed closed with leftovers: LOOT_CLOSED hid it blindly. A full bag ends the session with items still inside - the window now re-checks a frame later and stays open while anything remains.",
			"Loot window icons could vanish: a secret icon return made SetTexture fail silently. Secret values are skipped and the icon falls back to C_Item.GetItemIconByID.",
			"Fast and normal loot side by side: 'Always fast loot' now yields to your autoloot modifier - hold it to loot by hand, and the window gets a 'Loot all' button for manual sessions.",
		},
		changesDE = {
			"Beutefenster blieb bei Restbeute zu: LOOT_CLOSED versteckte es blind. Eine volle Tasche beendet den Vorgang mit Items im Fenster - es prueft jetzt einen Frame spaeter erneut und bleibt offen, solange etwas uebrig ist.",
			"Beutefenster-Icons konnten verschwinden: ein geheimer Icon-Rueckgabewert liess SetTexture still fehlschlagen. Geheime Werte werden uebersprungen und das Icon faellt auf C_Item.GetItemIconByID zurueck.",
			"Schnell- und Normalpluendern nebeneinander: 'Immer schnell pluendern' weicht jetzt dem Autoloot-Modifier - gedrueckt halten lootet von Hand, und das Fenster bekommt einen 'Alles pluendern'-Knopf.",
		},
	},
	{
		version = "0.2.8",
		date = "2026-11-22",
		changes = {
			"The loot window now registers its mover at module enable, not on the first loot - before, it had no handle in move mode until you had looted once. The handle also only shows while the own loot window is enabled.",
		},
		changesDE = {
			"Das Plünderfenster meldet seinen Mover jetzt beim Laden des Moduls an, nicht erst beim ersten Loot - vorher hatte es im Verschiebemodus keinen Griff, bis man einmal gelootet hatte. Der Griff erscheint zudem nur, solange das eigene Plünderfenster aktiv ist.",
		},
	},
	{
		version = "0.2.7",
		date = "2026-11-22",
		changes = {
			"Window now closes on Escape via the shared S.EscClosable helper instead of a UISpecialFrames entry - addon-written entries in that game table taint the Escape dispatch, which made protected calls (spell stop, reload) fail and get blamed on the addon.",
		},
		changesDE = {
			"Fenster schliesst jetzt per gemeinsamem S.EscClosable-Helfer auf Escape statt ueber einen UISpecialFrames-Eintrag - von Addons geschriebene Eintraege in dieser Spiel-Tabelle tainten den Escape-Dispatch, weshalb geschuetzte Aufrufe (Zauber abbrechen, Neuladen) fehlschlugen und dem Addon angelastet wurden.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Interface-dispatch audit: hiding the Blizzard loot frame and refreshing the custom window no longer run inside LOOT_* events or the frame's OnShow - a visibility watcher and deferred calls do the work one frame outside the dispatch. Auto-loot slot pickup is deferred the same way.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Das Verstecken des Blizzard-Lootfensters und das Refresh des eigenen Fensters laufen nicht mehr in LOOT_*-Events oder im OnShow des Frames - ein Sichtbarkeits-Watcher und deferred Aufrufe erledigen die Arbeit einen Frame ausserhalb des Dispatch. Auto-Loot-Slotaufnahme ebenfalls deferred.",
		},
	},

	{
		version = "0.2.5",
		changes = {
			"Dispatcher rollback: LOOT_READY/LOOT_OPENED/LOOT_SLOT_*/LOOT_CLOSED events and the OnShow hook that re-hides the Blizzard loot frame are back - the GetNumLootItems/visibility polling is removed.",
		},
		changesDE = {
			"Dispatcher-Rollback: LOOT_READY/LOOT_OPENED/LOOT_SLOT_*/LOOT_CLOSED-Events und der OnShow-Hook, der den Blizzard-Lootframe versteckt, sind zurueck - das GetNumLootItems-/Sichtbarkeits-Polling ist entfernt.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"LOOT_* events and the Blizzard LootFrame hooks were replaced by GetNumLootItems/visibility polling - running addon code inside the client's loot dispatch tainted follow-up protected calls.",
		},
		changesDE = {
			"LOOT_*-Events und die Blizzard-LootFrame-Hooks wurden durch GetNumLootItems-/Sichtbarkeits-Polling ersetzt - Addon-Code im Loot-Dispatch taintete die folgenden geschuetzten Aufrufe.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Roll presentation rebuilt: active rolls are re-homed into a Sentinel panel docked directly to the side of the loot window (the items) - or the game's loot frame, with the roll mover's position as fallback - instead of floating wherever the container was left. Rolls stack top-down in one deterministic column (oldest on top), the panel shows up to 3 cards and scrolls past that via its scrollbar or the mouse wheel anywhere over the panel or a card.",
		},
		changesDE = {
			"Wüfel-Darstellung neu gebaut: Aktive Wüfel werden in ein Sentinel-Panel umgewidmet, das direkt an der Seite des Loot-Fensters (der Items) dockt - oder des Spiel-Lootfensters, mit der Mover-Position als Fallback - statt irgendwo zu schweben, wo der Container stand. Wüfel stapeln sich von oben nach unten in einer festen Spalte (der älteste oben), das Panel zeigt bis zu 3 Karten und scrollt darüber hinaus per Scrollbar oder Mausrad überall über Panel oder Karte.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Roll frame skin actually reaches the visible frames now: on this client the roll popups live inside GroupLootContainer.rollFrames, which the old loop over GroupLootFrame1-4 never touched - that is why rolls showed the plain Blizzard frame with the green quality border. The skin now covers container frames, strips BACKGROUND and BORDER chrome (the quality glow included), hides the frame's own border regions, slims the timer into an accent line and tints the roll buttons found on LootButtonContainer as well.",
		},
		changesDE = {
			"Der Wüfelframe-Skin erreicht die sichtbaren Frames jetzt wirklich: Auf diesem Client liegen die Wüfel-Popups in GroupLootContainer.rollFrames, die die alte Schleife über GroupLootFrame1-4 nie anfasste - darum zeigten Wüfel den normalen Blizzard-Frame mit grünem Qualitätsrand. Der Skin deckt nun Container-Frames ab, entfernt BACKGROUND- und BORDER-Chrom (inkl. Quality-Glow), blendet die eigenen Rand-Regionen des Frames aus, verschlankt den Timer zu einer Akzentlinie und findet die Wüfel-Buttons auch im LootButtonContainer.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"The loot window's title-drag now saves through Movers.Save like the bag windows - nearest-anchor format plus a MoversChanged event, instead of a hand-rolled center offset that mixed frame-space and UIParent-space coordinates.",
		},
		changesDE = {
			"Der Titel-Drag des Loot-Fensters speichert jetzt über Movers.Save wie die Taschenfenster - Nearest-Anchor-Format plus MoversChanged-Event, statt eines handgerollten Mittelpunkts-Offsets, der Frame- und UIParent-Koordinaten vermischte.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Own loot window: a Sentinel panel replaces the game's loot frame - every slot as a row with quality border and colored name, a click loots it, hover shows the tooltip. It's a mover; the game's window hides while the option is on.",
			"Loot feed: your recent loot as small fading rows (items stack by count, money pools on one row, hover shows the tooltip, right-click dismisses). Self-loot is matched through the game's own format strings, so it works in every language. Mover, plus row-count and hold-time settings.",
		},
		changesDE = {
			"Eigenes Beutefenster: ein Sentinel-Panel ersetzt das Beutefenster des Spiels - jeder Slot als Zeile mit Qualitätsrahmen und farbigem Namen, Klick plündert, Hover zeigt den Tooltip. Es ist ein Mover; das Spielfenster bleibt aus, solange die Option an ist.",
			"Beute-Feed: deine letzte Beute als kleine ausblendende Zeilen (Items stapeln nach Anzahl, Geld sammelt sich auf einer Zeile, Hover zeigt den Tooltip, Rechtsklick blendet aus). Eigene Beute wird über die Format-Strings des Spiels erkannt und funktioniert in jeder Sprache. Mover, plus Zeilen- und Haltezeit-Einstellungen.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: fast loot takes every slot the moment the loot window opens, respecting the autoloot modifier unless 'always' is set.",
			"Chat filter hides loot spam: item messages below a chosen quality and, optionally, coin lines.",
			"Loot log window (/slootlog): every loot line with an item is kept across sessions, item links stay clickable, scrollable, with a clear button.",
			"Sentinel skins: dark panel and quality-colored icon borders on the loot window; quality border plus tinted need/greed/pass/disenchant buttons on the group roll frames.",
		},
		changesDE = {
			"Erste Version: Schnellplündern nimmt jeden Slot beim Öffnen des Beutefensters, respektiert Autoloot-Modifier, außer 'Immer' ist aktiv.",
			"Chat-Filter blendet Beute-Spam aus: Item-Meldungen unter einer wählbaren Qualität und auf Wunsch Münz-Zeilen.",
			"Beute-Log (/slootlog): Jede Beutezeile mit Item bleibt über Sessions erhalten, Item-Links klickbar, scrollbar, mit Löschen-Button.",
			"Sentinel-Skins: dunkles Panel und qualitätsfarbene Icon-Rahmen am Beutefenster; Qualitätsrahmen und getönte Bedarf-/Gier-/Passen-/Entzaubern-Buttons an den Würfelfenstern.",
		},
	},
}
