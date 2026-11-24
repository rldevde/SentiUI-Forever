local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.9",
		date = "2026-11-24",
		changes = {
			"Data bars animate now: the fill glides to new values (exponential ease, like the nameplate health bars - Smooth bars setting) and \"+N\" gain numbers pop off the fill's leading edge, rising while they fade (Gain flytext setting). Rapid gains pool into one sum; the pop is skipped on level-ups and standing changes where the range itself moves.",
		},
		changesDE = {
			"Datenleisten sind jetzt animiert: Die Fuellung gleitet zu neuen Werten (exponentielles Easing wie die Lebensleisten - Einstellung Weiche Leisten) und \"+N\"-Zugewinn-Zahlen springen von der vorderen Fuellkante ab und steigen ausblendend auf (Zugewinn-Fliessbarkeit). Schnelle Zugewinne sammeln sich in einer Summe; bei Level-Ups und Rangwechseln, wo der Bereich selbst wandert, wird der Pop uebersprungen.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Gold hairline now spans the bar's full width (was inset 5px each side - read as a golden section smaller than the bar itself).",
		},
		changesDE = {
			"Goldene Haarlinie laeuft jetzt ueber die volle Leistenbreite (war je Seite 5px eingezogen - wirkte wie ein goldener Abschnitt kleiner als die Leiste).",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"XP and rep bars now dock flush against the chat panel top edge (removed the 1px gap).",
		},
		changesDE = {
			"EP- und Ruf-Leisten docken jetzt bündig an der Oberkante des Chat-Panels an (1px Spalt entfernt).",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Dark-glass gloss overlay on the bar fill area, matching the unit frame / castbar look.",
		},
		changesDE = {
			"Dark-Glass-Glanz auf dem Fuellbereich der Leisten, passend zum Unit-Frame-/Castbar-Look.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"The accent line along the top edge is now inset 5px on each side so it ends on the straight edge instead of poking past the rounded corners.",
		},
		changesDE = {
			"Die Akzentlinie an der Oberkante ist jetzt je 5px eingesetzt, damit sie an der geraden Kante endet statt ueber die abgerundeten Ecken hinauszuragen.",
		},
	},
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
