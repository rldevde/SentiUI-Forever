local _, ns = ...

ns.CHANGELOG = {
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
