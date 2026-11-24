local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.3",
		date = "2026-11-24",
		changes = {
			"Fix aura switching staying stuck on the first known aura: the skill check behind the aura pick used the rank-1 spell ids - any aura learned at a higher rank failed the check, so the bar chip fell back to the first known aura no matter what the grid assigned and the cycle could never leave the one known entry. Aura and seal picks are no longer skill-gated (same as the reference); with no aura assigned the chip shows a dimmed placeholder instead of hiding.",
		},
		changesDE = {
			"Aura-Wechsel blieb auf der ersten bekannten Aura haengen, behoben: Der Skill-Check hinter der Aura-Auswahl nutzte die Rang-1-Spell-IDs - jede hoeher gelernte Aura schlug fehl, die Bar fiel auf die erste bekannte Aura zurueck, egal was das Grid zuwies, und der Cycle kam nie aus dem einen bekannten Eintrag raus. Aura- und Siegel-Auswahl sind jetzt nicht mehr skill-gated (wie die Referenz); ohne Zuweisung zeigt der Chip ein gedimmtes Platzhalter-Icon statt zu verschwinden.",
		},
	},
	{
		version = "0.1.2",
		date = "2026-11-24",
		changes = {
			"Fix hundreds of ADDON_ACTION_BLOCKED during combat: SPELLS_CHANGED repainted the RF/aura/seal chips directly, and the chips are protected (they contain secure buttons) - every aura tick hit a forbidden Show(). The three chip paints now defer the whole repaint through RunOutOfCombat, so icon and cast attributes always stay in sync with what a click would fire.",
		},
		changesDE = {
			"Hunderte ADDON_ACTION_BLOCKED im Kampf behoben: SPELLS_CHANGED malte die Zorner-/Aura-/Siegel-Chips direkt, und die Chips sind protected (sie enthalten Secure-Buttons) - jeder Aura-Tick traf ein verbotenes Show(). Die drei Chip-Paints deferieren den ganzen Repaint jetzt ueber RunOutOfCombat, Icon und Cast-Attribute bleiben so immer synchron mit dem, was ein Klick wirken wuerde.",
		},
	},
	{
		version = "0.1.1",
		date = "2026-11-24",
		changes = {
			"Fix casts doing nothing: the secure spell attribute needs the spell NAME on this client, not the id - every cast button (RF/aura/seal chips, greater/single blessing rows) now resolves ids to names like SentinelForeverBlessings does.",
			"Fix grid changes not reaching the buff bar: the local name key used GetUnitName's realm-suffixed form while the wire tables are keyed by the short name - aura and blessing assignments written in the grid never matched the row the bar reads. All name keys (player, roster, senders) now normalize through Ambiguate short.",
			"Aura cell cycling in the grid now skips auras the paladin does not know (own row via spellbook, other paladins via their ASELF aura ranks).",
		},
		changesDE = {
			"Wirken ohne Wirkung behoben: Das secure spell-Attribut braucht auf diesem Client den ZauberNAMEN, nicht die ID - alle Cast-Buttons (Zorner-/Aura-/Siegel-Chips, Grosser-/Einzel-Segenszeilen) loesen IDs jetzt zu Namen auf, wie SentinelForeverBlessings.",
			"Grid-Aenderungen kommen jetzt auf der Buff-Leiste an: Der lokale Namensschluessel nutzte die Realm-Form von GetUnitName, die Wire-Tabellen sind aber mit dem Kurznamen gekeyed - Aura- und Segens-Zuweisungen aus dem Grid trafen nie die Zeile, die die Leiste liest. Alle Namensschluessel (Spieler, Roster, Sender) normalisieren jetzt ueber Ambiguate short.",
			"Aura-Zellen im Grid ueberspringen jetzt Auren, die der Paladin nicht kennt (eigene Zeile uebers Zauberbuch, fremde ueber die ASELF-Aurenraenge).",
		},
	},
	{
		version = "0.1.0",
		date = "2026-11-23",
		changes = {
			"New blessings window for paladins, fully wire-compatible with PallyPower: the PLPWR addon channel carries REQ/SELF/ASELF, ASSIGN/PASSIGN/MASSIGN, NASSIGN, AASSIGN, CLEAR and FREEASSIGN with symbol counts and cooldowns, so assignments sync with every real PallyPower in the group.",
			"One row per class in the group: class icon, buffed/total count (red, gold, green), one blessing cell per known paladin (click cycles the assignment when you may control it), and a secure cast button that puts your assigned blessing on the first member missing it. Rows expand to member lists with per-player overrides.",
			"Personal strip: aura and seal chips (mouse wheel cycles, icon click casts) plus Righteous Fury, all as script-free secure buttons - static type/spell attributes and both click phases, the same proven shape as the secure reload overlay.",
			"Footer: auto-assign (per-class blessing priorities), clear, report to group chat, free-assignment checkbox, refresh/REQ. Symbol of Kings count in the title bar. Window: /sp toggle, drag by the title band, Esc closes, mover support.",
		},
		changesDE = {
			"Neues Segens-Fenster für Paladine, voll drahtkompatibel mit PallyPower: Der PLPWR-Addonkanal trägt REQ/SELF/ASELF, ASSIGN/PASSIGN/MASSIGN, NASSIGN, AASSIGN, CLEAR und FREEASSIGN mit Symbolzahlen und Cooldowns - Zuweisungen synchronisieren sich mit jedem echten PallyPower in der Gruppe.",
			"Eine Zeile pro Klasse in der Gruppe: Klassenicon, gesegnet/gesamt-Zahl (rot, gold, grün), eine Segenszelle pro bekanntem Paladin (Klick wechselt die Zuweisung, wenn erlaubt) und ein Secure-Cast-Button, der deinen zugewiesenen Segen auf das erste fehlende Mitglied wirkt. Zeilen klappen zu Mitgliederlisten mit Einzel-Overrides auf.",
			"Persönliches Feld: Aura- und Siegel-Chips (Mausrad wechselt, Icon-Klick wirkt) plus Zorner - alles scriptfreie Secure-Buttons mit statischen type/spell-Attributen und beiden Klick-Phasen, wie das bewaehrte Secure-Reload-Overlay.",
			"Fussbereich: Auto-Zuweisung (Klassenprioritäten), Löschen, Report in den Gruppenchat, Free-Assignment-Häkchen, Refresh/REQ. Symbol der Könige-Zähler in der Titelzeile. Fenster: /sp-Toggle, Drag am Titelband, Esc schliesst, Mover-Unterstützung.",
		},
	},
}
