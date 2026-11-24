local _, ns = ...

ns.CHANGELOG = {
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
