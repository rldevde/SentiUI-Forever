local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.1.1",
		date = "2026-11-25",
		changes = {
			"Death recap: the feed keeps a ring buffer of the last incoming events - when you die a small card lists the last eight hits (damage, heals, misses) so you can see what killed you. It fades after ~12s and hides on resurrect. Toggle under Combat Text > Shown events.",
		},
		changesDE = {
			"Todes-Protokoll: Der Feed puffert die letzten eingehenden Ereignisse - beim Tod listet eine kleine Karte die letzten acht Treffer (Schaden, Heilung, Fehlschlaege), damit du siehst was dich umgebracht hat. Blendet nach ~12s aus und verschwindet beim Wiederbeleben. Schalter unter Kampftext > Angezeigte Ereignisse.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: a scrolling incoming-combat feed driven by COMBAT_TEXT_UPDATE - damage taken, heals, misses and resource gains stack from the bottom, hold, then fly off to a screen edge (configurable direction) or fade in place. Crits render bigger and gold. The feed is a mover and every event family can be toggled. Outgoing damage has no unprotected source on this client, so the feed covers incoming events only.",
		},
		changesDE = {
			"Erste Version: ein laufender Feed eingehender Kampfereignisse ueber COMBAT_TEXT_UPDATE - erlittener Schaden, Heilung, Fehlschlaege und Ressourcengewinne stapeln sich von unten, halten kurz, dann fliegen sie zum Bildschirmrand (Richtung konfigurierbar) oder verblassen. Kritische Treffer erscheinen groesser und golden. Der Feed ist ein Mover, jede Ereignisfamilie ist einzeln schaltbar. Ausgehender Schaden hat auf diesem Client keine ungeschuetzte Quelle - der Feed zeigt nur eingehende Ereignisse.",
		},
	},
}
