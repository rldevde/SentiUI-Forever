local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.4",
		changes = {
			"Fixed broken bar fills: the orientation helper was declared below the fill function, so it resolved to a nil global and errored on every update - bars rendered uncolored (white).",
		},
		changesDE = {
			"Kaputte Leistenfüllung behoben: Der Ausrichtungs-Helper war unterhalb der Füllfunktion deklariert, löste als leeres Global auf und warf bei jedem Update einen Fehler - Leisten renderten ungetintet (weiß).",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Bar orientation setting is live: the HORIZONTAL/VERTICAL default existed but was never read - vertical bars now fill bottom to top, keep Height as thickness, use Width as length and park at the screen edge instead of docking under the chat panels.",
		},
		changesDE = {
			"Leisten-Ausrichtung ist aktiv: der HORIZONTAL/VERTICAL-Default existierte, wurde aber nie gelesen - vertikale Leisten füllen jetzt von unten nach oben, nutzen Höhe als Dicke und Breite als Länge und parken am Bildschirmrand statt unter den Chat-Panels anzudocken.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"Fill colors retuned to the Sentinel palette: XP bar now fills in the amber-gold family instead of the bright UI blue, rested XP is violet and pending quest XP a muted green. Fill gradient softened so the bars no longer look muddy.",
		},
		changesDE = {
			"Füllfarben auf die Sentinel-Palette umgestellt: Die EP-Leiste füllt sich jetzt in Amber-Gold statt knalligem UI-Blau, Rested-EP ist violett und offene Quest-EP ein gedämpftes Grün. Farbverlauf abgeschwächt, damit die Leisten nicht mehr trüb wirken.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"Visual pass so the bars match the interface: they now dock flush onto the chat panel's top edge with width following the panel, carry the SentiUI accent hairline, a spark at the leading edge of the fill and a subtle gradient on all fill colors.",
		},
		changesDE = {
			"Optik an das Interface angepasst: Die Leisten docken jetzt bündig an der Oberkante der Chat-Panels an (Breite folgt dem Panel), tragen die SentiUI-Accent-Hairline, einen Funken an der Füllkante und einen subtilen Farbverlauf auf allen Füllfarben.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"Initial release: experience bar with rested and pending-quest-XP segments, a LEVEL UP marker when banked turn-ins would ding, XP/hour and time-to-level in the tooltip, plus a reputation bar for the watched faction colored by standing (friendship, renown and paragon aware, click to open the reputation frame). Both bars are SentiUI-styled, dock onto the chat panels by default and are their own movers.",
		},
		changesDE = {
			"Erste Version: Erfahrungsleiste mit Rested- und Quest-EP-Anteil, LEVEL-UP-Markierung wenn abgegebene Quests zum Stufenaufstieg reichen, EP/h und Zeit-bis-Level im Tooltip, dazu eine Rufleiste für die beobachtete Fraktion in Standing-Farbe (Freundschaft, Ruhm und Paragon berücksichtigt, Klick öffnet das Ruffenster). Beide Leisten im SentiUI-Stil, docken standardmäßig an die Chat-Panels und sind eigene Mover.",
		},
	},
}
