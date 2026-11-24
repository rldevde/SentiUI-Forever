local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.4.21",
		date = "2026-11-25",
		changes = {
			"New-item markers: freshly looted slots carry a soft gold sheen plus a small gold corner tag via C_NewItems.IsNewItem - the flags clear on bag close or when the item moves (New item glow option).",
		},
		changesDE = {
			"Neu-Marker: Frisch gelootete Felder tragen einen sanften Goldschimmer ueber dem Icon plus eine kleine goldene Eckmarkierung, gesteuert ueber C_NewItems.IsNewItem - die Flags loesen sich beim Schliessen der Tasche oder beim Bewegen des Items selbst (Neu-Glühen in den Ansichtsoptionen, standardmaessig an).",
		},
	},
	{
		version = "0.4.20",
		date = "2026-11-24",
		changes = {
			"Secure use overlay removed entirely: neither parenting (restricts the slot's ancestor chain) nor anchoring (restricts the frame it anchors to) lets a protected button follow the grid under lockdown, so the overlay idea cannot work on this client. Item use inside a fight stays a protected call only Blizzard-owned dispatches may run - same limitation every addon bag has. Layout is back to fully live in combat exactly like before 0.4.17; junk sell/repair keep their lockdown early-out.",
		},
		changesDE = {
			"Secure-Use-Overlay komplett entfernt: weder Parenting (sperrt die Ahnenkette des Slots) noch Verankerung (sperrt den Referenz-Frame) laesst einen protected Button dem Grid unter Lockdown folgen - die Idee ist auf diesem Client nicht machbar. Item-Nutzung im Kampf bleibt ein geschuetzter Aufruf, den nur Blizzard-Dispatches ausfuehren duerfen - dieselbe Grenze wie bei jedem Addon-Bag. Das Layout ist wieder komplett live im Kampf wie vor 0.4.17; Schrottverkauf/Reparatur behalten ihr Lockdown-Fruehaussstieg.",
		},
	},
	{
		version = "0.4.19",
		date = "2026-11-24",
		changes = {
			"Bag contents update live in combat again AND right-click item use still works: the secure overlay no longer parents to the slot (a protected descendant restricts its whole ancestor chain - that is what froze the layout in 0.4.18). It now lives on UIParent, anchored to its slot, and follows every reposition engine-side with zero Lua work. Under lockdown unused slots are parked offscreen instead of hidden so their overlays travel with them; window close still waits for regen so no invisible click-catchers linger.",
		},
		changesDE = {
			"Tascheninhalt aktualisiert wieder live im Kampf UND Rechtsklick-Benutzung geht weiter: das Secure-Overlay parented nicht mehr am Slot (ein geschuetzter Nachfahre sperrt die ganze Ahnenkette - das hat 0.4.18 das Layout eingefroren). Es liegt jetzt auf UIParent, am Slot verankert, und folgt jeder Position engine-seitig ohne Lua-Arbeit. Unter Lockdown werden freie Slots offscreen geparkt statt versteckt, damit ihre Overlays mitwandern; das Fenster-Schliessen wartet weiter auf den Regen, damit keine unsichtbaren Klick-Fallen liegen bleiben.",
		},
	},
	{
		version = "0.4.18",
		date = "2026-11-24",
		changes = {
			"Forbidden calls in combat on every bag refresh: the 0.4.17 secure overlay is a protected child, which restricts its whole ancestor chain - slot, grid, window. Core.Layout now defers entirely under lockdown and repaints on PLAYER_REGEN_ENABLED; window Hide waits for regen too, the bag-slot strip skips its repaint in combat, and junk sell/repair bail early since UseContainerItem/RepairAllItems are protected anyway.",
		},
		changesDE = {
			"Verbotene Aufrufe im Kampf bei jeder Taschen-Aktualisierung: das Secure-Overlay aus 0.4.17 ist ein geschuetztes Kind, das die komplette Ahnenkette sperrt - Slot, Grid, Fenster. Core.Layout wartet jetzt unter Lockdown komplett und bemalt nach PLAYER_REGEN_ENABLED neu; auch das Fenster-Hide wartet auf den Regen, der Taschen-Slot-Streifen ueberspringt sein Repaint im Kampf, und Schrottverkauf/Reparatur steigen frueh aus, da UseContainerItem/RepairAllItems ohnehin geschuetzt sind.",
		},
	},
	{
		version = "0.4.17",
		date = "2026-11-24",
		changes = {
			"Using items from the bag window in combat was still blocked: the template's UseContainerItem is a protected call and stays forbidden whenever the click dispatch ran through addon-created code. Each slot now carries a small secure overlay child that sends right clicks through the client's own secure path (/use bag slot) - works mid-fight. Left click, drag, split and link keep the template's native handler via click pass-through; on a client without that API the overlay hides itself and nothing changes.",
		},
		changesDE = {
			"Items aus dem Taschenfenster im Kampf benutzen war weiter blockiert: das UseContainerItem des Templates ist ein geschuetzter Aufruf und bleibt verboten, sobald der Klick-Dispatch durch Addon-Code lief. Jeder Slot traegt jetzt ein kleines sicheres Overlay, das Rechtsklicks ueber den eigenen Secure-Pfad des Clients schickt (/use Tasche Platz) - geht mitten im Kampf. Linksklick, Drag, Splitten und Verlinken bleiben ueber Click-Pass-Through beim nativen Template-Handler; auf einem Client ohne diese API versteckt sich das Overlay und nichts aendert sich.",
		},
	},
	{
		version = "0.4.16",
		date = "2026-11-23",
		changes = {
			"Bags window opening then closing at merchant: MERCHANT_SHOW fires Core.Sync() AND ns.Core.Open(). Sync calls IsAnyBagOpen() which reads game bag frames - not ours - returns false, closes the window a frame later. Fix: Core.forceOpen flag set on MERCHANT_SHOW, cleared on MERCHANT_CLOSED; Sync returns ApplyGameState(true) early when set.",
		},
		changesDE = {
			"Taschenfenster oeffnet und schliesst sofort beim Haendler: MERCHANT_SHOW feuert Core.Sync() UND ns.Core.Open(). Sync ruft IsAnyBagOpen() auf - liest Game-Bags nicht unser Fenster - gibt false zurueck und schliesst es. Fix: Core.forceOpen-Flag bei MERCHANT_SHOW gesetzt, bei MERCHANT_CLOSED geloescht; Sync ruft ApplyGameState(true) fruehzeitig auf.",
		},
	},
	{
		version = "0.4.15",
		date = "2026-11-23",
		changes = {
			"Bags open at merchant: MERCHANT_SHOW now calls ns.Core.Open() unconditionally - bags window opens alongside the merchant frame (previously only opened when autoRepair or sellJunk was on).",
			"Auto-repair fix: RepairAllItems now called via securecall (protected function - plain pcall fails silently). GetRepairAllCost returning secret no longer silently aborts; repair proceeds and cost shows as ?.",
			"Repair toolbar button: hidden when autoRepair is enabled. Toggling autoRepair in settings updates the button without a reload.",
			"Bag slot tooltip: shows the bag's contents (up to 8 items) plus the assigned category label when a bag preference is set.",
			"Bag preferences: new settings group under SentiUI > Bags with four dropdowns (Bag 1-4) assigning a category per bag. 'Everything' keeps the bag unrestricted.",
		},
		changesDE = {
			"Taschen oeffnen beim Haendler: MERCHANT_SHOW ruft ns.Core.Open() bedingungslos - Taschenfenster oeffnet parallel zum Haendler (bisher nur bei autoRepair oder sellJunk).",
			"Auto-Reparatur-Fix: RepairAllItems jetzt ueber securecall (geschuetzte Funktion - pcall schlaegt stillschweigend fehl). GetRepairAllCost als secret bricht die Reparatur nicht mehr ab; Kosten zeigen als ?.",
			"Reparatur-Button: ausgeblendet wenn autoRepair aktiv ist. Umschalten in den Einstellungen aktualisiert den Button ohne Reload.",
			"Taschen-Slot-Tooltip: zeigt den Inhalt der Tasche (bis zu 8 Items) plus zugewiesene Kategorie wenn eine Taschen-Praeferenz gesetzt ist.",
			"Taschen-Praeferenzen: neue Einstellungsgruppe unter SentiUI > Bags mit vier Dropdowns (Tasche 1-4) zur Kategorie-Zuweisung. 'Alles' laesst die Tasche frei.",
		},
	},
	{
		version = "0.4.14",
		date = "2026-11-23",
		changes = {
			"Removed the own bank window: Bank.Enable no longer creates a SentiUI bank frame. Blizzard BankFrame is no longer parked under the hidden holder - it stays visible and shows the client's native slot purchase UI (Taschenplaetze: Kaufen). The carried-bags window still opens alongside the bank via BANKFRAME_OPENED.",
		},
		changesDE = {
			"Eigenes Bank-Fenster entfernt: Bank.Enable erzeugt kein SentiUI-Bankfenster mehr. Blizzard BankFrame wird nicht mehr im versteckten Holder geparkt - es bleibt sichtbar und zeigt die eigene Slot-Kauf-UI des Clients (Taschenplaetze: Kaufen). Das Taschen-Fenster oeffnet weiterhin parallel zur Bank ueber BANKFRAME_OPENED.",
		},
	},
	{
		version = "0.4.13",
		date = "2026-11-23",
		changes = {
			"Bank slot purchase: securecall applied to every candidate API before pcall - protected functions refuse plain addon calls. Added BuyBankSlot, C_Bank.PurchaseNextBankSlot, C_Bank.BuyNextBankSlot. Fallback scans BankFrame for PurchaseButton/BuyButton/BankFramePurchaseButton and clicks it programmatically.",
		},
		changesDE = {
			"Bankfach-Kauf: securecall fuer jeden Kandidaten-API vor pcall - geschuetzte Funktionen lehnen Addon-Aufrufe ab. BuyBankSlot, C_Bank.PurchaseNextBankSlot, C_Bank.BuyNextBankSlot hinzugefuegt. Fallback sucht BankFrame nach PurchaseButton/BuyButton/BankFramePurchaseButton und klickt ihn programmgesteuert.",
		},
	},
	{
		version = "0.4.12",
		date = "2026-11-23",
		changes = {
			"Bank slot purchase crash: removed StaticPopup_Show(CONFIRM_BUY_BANK_SLOT) from the fallback chain. The client's own OnAccept handler for that dialog calls a nil function on this build (GameDialogDefs.lua:698), so clicking Buy on the game's own confirm popup crashes. Now shows the hidden Blizzard BankFrame as last resort - it carries its own working purchase UI.",
		},
		changesDE = {
			"Bankfach-Kauf-Absturz: StaticPopup_Show(CONFIRM_BUY_BANK_SLOT) aus der Fallback-Kette entfernt. Der eigene OnAccept-Handler des Clients fuer diesen Dialog ruft auf diesem Build eine nil-Funktion auf (GameDialogDefs.lua:698), das Klicken auf Kaufen im eigenen Bestaetigungsfenster stuerzt ab. Zeigt jetzt das verborgene Blizzard-BankFrame als letztes Mittel - es hat eine eigene funktionierende Kauf-UI.",
		},
	},
	{
		version = "0.4.11",
		date = "2026-11-23",
		changes = {
			"Buy bank slots: new Buy slot toolbar button in the bank window. Slots.BuySlot() walks the API fallback chain - PurchaseSlot -> BankFramePurchaseSlot -> PurchaseBankSlot -> C_Bank.PurchaseSlot - then falls back to StaticPopup_Show(CONFIRM_BUY_BANK_SLOT) or showing the hidden Blizzard BankFrame. Works even when GetNumBankSlots or PurchaseSlot are secret or absent.",
		},
		changesDE = {
			"Bankfaecher kaufen: Neuer Slot-kaufen-Button in der Bank-Fenster-Toolbar. Slots.BuySlot() geht die API-Kette durch - PurchaseSlot -> BankFramePurchaseSlot -> PurchaseBankSlot -> C_Bank.PurchaseSlot - und faellt auf StaticPopup_Show(CONFIRM_BUY_BANK_SLOT) oder das verborgene Blizzard-BankFrame zurueck. Funktioniert auch wenn GetNumBankSlots oder PurchaseSlot secret sind oder fehlen.",
		},
	},
	{
		version = "0.4.10",
		date = "2026-11-22",
		changes = {
			"Fix: using items straight from the bag window was blocked with ADDON_ACTION_FORBIDDEN (UseContainerItem). The item buttons were real game template buttons, but our own scripts were planted on them - a custom OnEnter/OnLeave tooltip, an OnDragStart fallback hook, and the S.IconRound size hook. On this client an addon script on the button marks its whole dispatch addon-owned, so the protected use-call inside the game's own click handler got blamed on SentiUI_Bags. The buttons are now completely script-free: the template's native click, drag and tooltip paths do everything. Corner rounding on slot icons is dropped with it - square icons are the price of working item clicks.",
		},
		changesDE = {
			"Fix: Items direkt aus der Tasche benutzen wurde mit ADDON_ACTION_FORBIDDEN geblockt (UseContainerItem). Die Item-Buttons waren echte Game-Template-Buttons, aber unsere eigenen Skripte hingen dran - eigener OnEnter/OnLeave-Tooltip, ein OnDragStart-Fallback-Hook und der S.IconRound-Size-Hook. Auf diesem Client markiert ein Addon-Skript am Button den ganzen Dispatch als Addon-Besitz, der geschützte Use-Call im eigenen Klick-Handler des Spiels wurde deshalb SentiUI_Bags angelastet. Die Buttons sind jetzt komplett skriptfrei: Klick, Drag und Tooltip macht das Template nativ. Die Eckenrundung der Slot-Icons fällt damit weg - eckige Icons sind der Preis für funktionierende Item-Klicks.",
		},
	},
	{
		version = "0.4.9",
		date = "2026-11-22",
		changes = {
			"Bag slot icons now clip to soft rounded corners via the rewritten core S.IconRound MaskTexture — the icon itself is cut, so a failing overlay can never paint a dark box over it.",
		},
		changesDE = {
			"Bag-Slot-Icons werden jetzt ueber die neu geschriebene Core-S.IconRound-MaskTexture auf weich abgerundete Ecken geclippt — das Icon selbst wird geschnitten, ein fehlschlagendes Overlay kann also nie eine dunkle Box darueber malen.",
		},
	},
	{
		version = "0.4.8",
		date = "2026-11-22",
		changes = {
			"Bag slot icons now have soft rounded corners: S.IconRound covers each icon's square corner with a background-colored arc (4px radius, matching the slot backdrop dark bg).",
		},
		changesDE = {
			"Bag-Slot-Icons haben jetzt weiche abgerundete Ecken: S.IconRound überdeckt jede eckige Icon-Ecke mit einem hintergrundfarbigen Bogen (4px Radius, passend zur dunklen Slot-Hintergrundfarbe).",
		},
	},
	{
		version = "0.4.7",
		date = "2026-11-22",
		changes = {
			"Bank slots are purchasable now: the bag strip in the bank window shows the next buyable slot with an accent border and its price in the tooltip; clicking it asks for confirmation and calls PurchaseSlot. Locked slots beyond the next stay hidden.",
		},
		changesDE = {
			"Bankfaecher sind jetzt kaufbar: die Taschenleiste im Bankfenster zeigt das naechste kaufbare Fach mit Akzent-Rahmen und Preis im Tooltip; ein Klick fragt nach und ruft PurchaseSlot. Gesperrte Faecher dahinter bleiben versteckt.",
		},
	},

	{
		version = "0.4.6",
		changes = {
			"Bag and bank windows: The window joins the combat deferral: opening mid-combat queues for after the fight with a chat note, an open window hides on combat start and returns after.",
		},
		changesDE = {
			"Das Fenster haengt an der Kampf-Verzoegerung: Oeffnen im Kampf wird mit Chat-Notiz nach dem Kampf nachgeholt, ein offenes Fenster versteckt sich bei Kampfbeginn und kehrt danach zurueck.",
		},
	},

	{
		version = "0.4.5",
		changes = {
			"Removed the leftover bag diagnostics (trace buffer, /sbagtrace) now that the mirror is stable. Bank and merchant open/close work (window swap, auto-repair, auto-sell) now runs a frame outside the client dispatch - those dispatches carry secret values and item APIs called inside them can fail.",
		},
		changesDE = {
			"Die restliche Taschen-Diagnose entfernt (Trace-Puffer, /sbagtrace) - das Mirror laeuft stabil. Bank- und Haendler-Arbeit (Fensterwechsel, Auto-Reparatur, Auto-Verkauf) laeuft jetzt einen Frame ausserhalb des Client-Dispatch - diese Dispatches tragen Secret-Werte und Item-APIs darin koennen fehlschlagen.",
		},
	},

	{
		version = "0.4.4",
		changes = {
			"Bag window mirror is hook-driven only now: the 0.15s state poll raced the client's multi-frame open sequence - IsAnyBagOpen can read false mid-transition, which flashed the window open and shut on some key presses. Every real open/close path already goes through the hooked bag functions, so the deferred mirror after them is the only driver.",
		},
		changesDE = {
			"Das Taschen-Mirror ist jetzt rein hook-getrieben: Der 0,15s-Zustandspoll raste der mehrstufigen Oeffnungssequenz des Clients hinterher - IsAnyBagOpen kann mitten im Uebergang false lesen, wodurch das Fenster bei manchen Tastendruecken kurz auf- und wieder zuging. Jeder echte Auf/Zu-Weg laeuft ohnehin ueber die gehakten Taschenfunktionen, das deferred Mirror danach ist der einzige Treiber.",
		},
	},
	{
		version = "0.4.3",
		changes = {
			"Followed the bag model proven elsewhere on this client: addon code never calls CloseAllBags/ToggleAllBags (their bookkeeping writes run tainted and break follow-up calls) - the game's containers are hidden directly like their own close buttons do. Window stays out of UISpecialFrames; hooks flag a batched mirror and the state poll keeps watching IsAnyBagOpen.",
		},
		changesDE = {
			"Dem auf diesem Client bewaehrten Taschenmodell gefolgt: Addon-Code ruft nie CloseAllBags/ToggleAllBags (deren Bookkeeping-Schreibzugriffe laufen tainted und brechen Folgeaufrufe) - die Container des Spiels werden direkt versteckt wie deren eigene Schliessen-Buttons. Fenster bleibt aus UISpecialFrames; Hooks flaggen ein gebatchtes Mirror und der Zustands-Poll wacht weiter ueber IsAnyBagOpen.",
		},
	},
	{
		version = "0.4.2",
		changes = {
			"Root cause of the instant close found via trace: the client's own UISpecialFrames walk hid the window a tick after it showed (it closes members it did not open), our WatchHide then called CloseAllBags and the state looped. The window is no longer a special frame - ESC still works because it hides the game's container frames, which the state poll mirrors. Containers are reparented again (the alpha ghost made the client flap the bag state).",
		},
		changesDE = {
			"Ursache des Sofort-Zu via Trace gefunden: Der UISpecialFrames-Walk des Clients versteckte das Fenster einen Tick nach dem Oeffnen (er schliesst Mitglieder, die er nicht geoeffnet hat), unser WatchHide rief daraufhin CloseAllBags und der Zustand lief in Schleife. Das Fenster ist kein Special-Frame mehr - ESC funktioniert weiterhin, weil er die Container-Frames des Spiels versteckt, die der Zustands-Poll spiegelt. Container sind wieder umgarentet (das Alpha-Ghosting liess den Taschenzustand flattern).",
		},
	},
	{
		version = "0.4.1",
		changes = {
			"Fixed the bag window closing instantly on B: the reparented-under-hidden container frames were IsVisible=false, so the client treated them as closed, flipped its bag state back and hid our window in the close pass. They are ghosted instead now (SetAlpha 0 + mouse off, staying IsVisible and truthful to IsAnyBagOpen) plus a state poll - BAG_OPEN/CLOSED never fire on this client. /sbagtrace toggles a diagnostic trace.",
		},
		changesDE = {
			"Fix: Taschenfenster schloss sofort nach B - die unter einem versteckten Holder geparkten Container-Frames waren IsVisible=false, der Client behandelte sie als geschlossen, kippte den Taschen-Zustand zurueck und versteckte unser Fenster beim Close-Pass mit. Sie werden jetzt geghostet (Alpha 0 + Maus aus, bleiben IsVisible und wahrheitsgemaess fuer IsAnyBagOpen) plus Zustands-Poll - BAG_OPEN/CLOSED feuern auf diesem Client nie. /sbagtrace schaltet eine Diagnose-Spur.",
		},
	},
	{
		version = "0.4.1",
		changes = {
			"Dispatcher rollback: BAG_OPEN/BAG_CLOSED/MERCHANT_* events restored (the 0.15s poll is gone) and GameBagOpen is back to IsAnyBagOpen/IsBagOpen - the parked containers' IsShown read as always-hidden under the holder, so the bag window could never report open.",
		},
		changesDE = {
			"Dispatcher-Rollback: BAG_OPEN/BAG_CLOSED/MERCHANT_*-Events sind zurueck (der 0,15s-Poll ist weg) und GameBagOpen nutzt wieder IsAnyBagOpen/IsBagOpen - das IsShown der geparkten Container las unter dem versteckten Parent immer als unsichtbar, das Taschenfenster meldete sich nie offen.",
		},
	},
	{
		version = "0.4.0",
		changes = {
			"Bag state is read from the parked container frames' own IsShown flags instead of IsAnyBagOpen/IsBagOpen: those can return secret or plain wrong values on this client, which dropped Sync to a blind toggle - each hooked call in the B-key chain toggled again and the window closed right after opening.",
		},
		changesDE = {
			"Taschen-Zustand wird jetzt aus den IsShown-Flags der geparkten Container-Frames gelesen statt IsAnyBagOpen/IsBagOpen: Die liefern auf diesem Client Secret- oder schlicht falsche Werte, wodurch Sync auf einen Blind-Toggle fiel - jeder gehakte Aufruf in der B-Kette toggelte erneut und das Fenster schloss direkt nach dem Oeffnen.",
		},
	},
	{
		version = "0.3.9",
		changes = {
			"Fixed the bag state poll never mirroring: the transition check tested an undeclared variable and could never pass, so the window only followed the bag-function hooks. Polling now tracks bagSeen correctly.",
		},
		changesDE = {
			"Taschen-Zustandspoll repariert: Die Uebergangspruefung testete eine nicht deklarierte Variable und konnte nie zutreffen - das Fenster folgte nur den Funktions-Hooks. Der Poll verfolgt bagSeen jetzt korrekt.",
		},
	},
	{
		version = "0.3.8",
		changes = {
			"Bag function post-hooks (ToggleBag, OpenBag, ...) now only set a flag - running our sync inside the client's keypress dispatch tainted the follow-up protected calls. The mirror runs from a 0.05s ticker.",
		},
		changesDE = {
			"Post-Hooks der Taschenfunktionen (ToggleBag, OpenBag, ...) setzen nur noch ein Flag - der Sync lief sonst im Tasten-Dispatch des Clients und taintete die folgenden geschuetzten Aufrufe. Der Mirror laeuft ueber einen 0,05s-Ticker.",
		},
	},
	{
		version = "0.3.7",
		changes = {
			"Bag, bank and merchant windows no longer use BAG_OPEN/BAG_CLOSED/BANKFRAME_*/MERCHANT_* events - those fire inside the client's protected window dispatch. Open/close state is now detected via GameBagOpen plus S.WatchShown visibility polling.",
		},
		changesDE = {
			"Taschen-, Bank- und Haendlerfenster nutzen keine BAG_OPEN/BAG_CLOSED/BANKFRAME_*/MERCHANT_*-Events mehr - die feuern im geschuetzten Fenster-Dispatch. Der Zustand wird jetzt ueber GameBagOpen und S.WatchShown-Polling erkannt.",
		},
	},
	{
		version = "0.3.6",
		changes = {
			"Escape-forbidden-call fix: the bag window's OnHide hook ran inside the Escape dispatch (it is in UISpecialFrames) - the new-item cleanup now runs via S.WatchHide polling instead.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Der OnHide-Hook des Taschenfensters lief im Escape-Dispatch (es steht in UISpecialFrames) - das New-Item-Cleanup laeuft jetzt ueber S.WatchHide-Polling.",
		},
	},

	{
		version = "0.3.5",
		changes = {
			"Fixed dragging items out of the bags: the modern item-button mixin reads BagID/SlotID off the button itself, not the parent holder's GetID, so drag-pickup ran on a nil bag and nothing lifted. The fields are set now plus a fallback OnDragStart that calls C_Container.PickupContainerItem if the template did not - items can be dragged between slots and thrown out into the world again.",
		},
		changesDE = {
			"Items lassen sich wieder per Drag aus den Taschen ziehen: Das moderne Item-Button-Mixin liest BagID/SlotID am Button selbst statt am Holder-Parent - der Drag-Pickup lief auf einer nil-Tasche ins Leere. Die Felder sind jetzt gesetzt, plus ein Fallback-OnDragStart über C_Container.PickupContainerItem, falls das Template nicht gegriffen hat - Items lassen sich zwischen Slots ziehen und in die Welt werfen.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Equipped-bag slots are back: both windows now show a strip of bag slots above the item grid (bags 1-4 + reagent bag; bank bags in the bank window). Drag a bag onto a slot to equip it, click an equipped bag to pick it back up - swap goes through the game's own PutItemInBag/PickupBagFromSlot so the client rules (non-empty bags, soulbound) apply natively.",
			"Slots paint the equipped bag's icon, tint the border by its quality, dim the empty-slot placeholder and show the bag's tooltip (or a hint on empty slots). BAG_SLOT_FLAGS_UPDATED refreshes them live.",
		},
		changesDE = {
			"Taschenplätze sind zurück: Beide Fenster zeigen jetzt eine Reihe Taschenplätze über dem Item-Raster (Taschen 1-4 + Mats-Tasche; Banktaschen im Bankfenster). Tasche auf einen Platz ziehen zum Ausrüsten, ausgerüstete Tasche anklicken zum Aufheben - der Tausch läuft über die Spiel-eigenen PutItemInBag/PickupBagFromSlot, sodass die Client-Regeln (volle Taschen, seelengebunden) nativ greifen.",
			"Plätze zeigen das Icon der ausgerüsteten Tasche, färben den Rand nach deren Qualität, dimmen den Leer-Platzhalter und zeigen den Taschen-Tooltip (oder einen Hinweis bei leeren Plätzen). BAG_SLOT_FLAGS_UPDATED aktualisiert sie live.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.",
		},
		changesDE = {
			"Park-/Versteck-Frames stubben jetzt die Blizzard-Layout-Methoden (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame), die Client-Skripte auf GetParent() aufrufen - behebt einen StatusTrackingManager-UpdateShownState-Fehler durch unter einem nackten versteckten Parent geparkte Frames.",
		},
	},
	{
		version = "0.3.2",
		changes = {
			"Auto repair clarified and hardened: it pays from your own gold by default (enable 'Guild repair first' only if you want guild funds tried first - it falls back to your gold when the guild bank doesn't allow it). The repair report now prints the full cost in gold/silver/copper, and guild funds are only attempted when you're in a guild and actually allowed to withdraw for repairs.",
		},
		changesDE = {
			"Auto-Reparatur klargestellt und robuster: Sie zahlt standardmäßig aus deinem eigenen Gold ('Gildenreparatur zuerst' nur einschalten, wenn die Gildenkasse zuerst probiert werden soll - fällt bei fehlender Erlaubnis auf dein Gold zurück). Der Reparatur-Report zeigt jetzt die vollen Kosten in Gold/Silber/Kupfer, und Gildengeld wird nur versucht, wenn du in einer Gilde bist und für Reparaturen abheben darfst.",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Fixed the window creeping upward on every item click or bag update: the pixel-snap re-anchored the frame from measured screen coordinates (GetLeft/GetTop) on every layout, which drifts on this client. It now rounds the stored anchor offsets (GetPoint) instead - it converges after one half-unit nudge and can never accumulate.",
			"Fixed leftover ghost slots: buttons freed by a layout were never hidden because their parent is now the per-bag holder frame, not the grid.",
		},
		changesDE = {
			"Behoben: Das Fenster rutschte bei jedem Item-Klick oder Bag-Update nach oben - der Pixel-Snap hat das Fenster bei jedem Layout aus gemessenen Bildschirm-Koordinaten (GetLeft/GetTop) neu verankert, was auf diesem Client driftet. Er rundet jetzt die gespeicherten Anker-Offsets (GetPoint) - konvergiert nach einmaligem Halb-Pixel-Nudge und kann sich nie aufschaukeln.",
			"Behoben: verwaiste Geist-Slots - freigewordene Buttons wurden nie versteckt, weil ihr Eltern-Frame jetzt der Holder pro Tasche ist, nicht das Grid.",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"The last piece of the click puzzle: slots are now created as ItemButton frames, not plain Buttons with the same template. On this client the mixin's click logic (pickup, use, sell, split, link/dressup) lives on the ItemButton class - a Button only got the look, which is why right click and splitting stayed dead and left click behaved oddly.",
		},
		changesDE = {
			"Das letzte Puzzleteil für die Klicks: Die Slots werden jetzt als ItemButton-Frames erstellt, nicht als plain Buttons mit demselben Template. Auf diesem Client lebt die Mixin-Klicklogik (Aufheben, Benutzen, Verkaufen, Teilen, Verlinken/Anprobe) auf der ItemButton-Klasse - ein Button bekam nur das Aussehen, weshalb Rechtsklick und Teilen tot blieben und Linksklick sich merkwürdig verhielt.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Item clicks completely rebuilt: slots are now real ContainerFrameItemButtonTemplate buttons, so the game's own trusted click handler does everything natively - pickup, use, equip, sell at vendors, bank transfers, stack split, link/dressup. Custom handlers and the secure overlay are gone; that path could never work because protected actions only run inside game code. Bag id comes from the slot's holder frame, slot from its own ID - the proven recipe on this client.",
			"Bonus: the template's cooldown wheel is now driven (item cooldowns show on slots).",
		},
		changesDE = {
			"Item-Klicks komplett neu: Die Slots sind jetzt echte ContainerFrameItemButtonTemplate-Buttons, der vertrauenswürdige Game-Handler macht alles nativ - Aufheben, Benutzen, Anlegen, beim Händler verkaufen, Bank-Transfer, Stapel teilen, Verlinken/Anprobe. Eigene Handler und das Secure-Overlay sind raus; dieser Weg konnte nie funktionieren, weil geschützte Aktionen nur innerhalb des Game-Codes laufen. Bag-ID vom Holder-Frame, Slot von der eigenen ID - das bewährte Rezept auf diesem Client.",
			"Bonus: Das Cooldown-Rad des Templates wird jetzt angetrieben (Item-Cooldowns sichtbar auf den Slots).",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"Right-click sell for real this time: a transparent SecureActionButton now parks on top of the hovered slot, so your genuine right click lands on it (the way bag addons do it). It registers BOTH the down and the up click because the ActionButtonUseKeyDown cvar decides which one counts - registering only \"up\" is why the previous fix still did nothing. Overlay skips combat, modifiers and a busy cursor, and hides when the window closes.",
		},
		changesDE = {
			"Rechtsklick-Verkauf jetzt wirklich: Ein transparenter SecureActionButton parkt über dem gehoverten Slot, sodass dein echter Rechtsklick ihn trifft (das bewährte Taschen-Rezept). Er registriert Down UND Up, weil der ActionButtonUseKeyDown-CVar entscheidet, welcher Klick zählt - nur \"Up\" zu registrieren war der Grund, warum der letzte Fix nichts brachte. Overlay pausiert in Kampf, bei Modifiers und vollem Cursor und versteckt sich beim Schließen.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Right click works again - use items, equip, sell at vendors, move to/from the bank. Slots are now real SecureActionButtons (type2=\"item\"): the previous hidden helper button was clicked programmatically, and the engine only runs protected actions on genuine hardware clicks. Left click pickup stays in OnMouseDown, which does not need protection.",
		},
		changesDE = {
			"Rechtsklick funktioniert wieder - Items benutzen, anlegen, beim Händler verkaufen, in die/aus der Bank legen. Die Slots sind jetzt echte SecureActionButtons (type2=\"item\"): der vorherige versteckte Hilfs-Button wurde programmatisch geklickt, und geschützte Aktionen führt die Engine nur bei echten Hardware-Klicks aus. Linksklick-Aufheben bleibt in OnMouseDown, das braucht keinen Schutz.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Fixed the strange \"15:15\" style numbers on slots: this client reports fractional item levels (15.15) whose decimal point looks like a colon at slot font size - the display is now rounded to whole numbers.",
			"Item level no longer appears on trade goods and consumables: the gear check now uses GetItemInfoInstant's classID (weapon/armour) instead of an unreliable GetItemInfo return position.",
		},
		changesDE = {
			"Fix: Die seltsamen Zahlen wie \"15:15\" auf den Slots - der Client meldet Komma-Gegenstandsstufen (15.15), deren Punkt bei der Schriftgröße wie ein Doppelpunkt aussieht; die Anzeige wird jetzt gerundet.",
			"Gegenstandsstufe erscheint nicht mehr auf Handelswaren und Verbrauchbarem: der Ausrüstungs-Check nutzt jetzt die classID aus GetItemInfoInstant (Waffe/Rüstung) statt einer unzuverlässigen GetItemInfo-Rückgabeposition.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Quality borders now start at Uncommon (green) instead of Common - white is the Common quality colour, which drew a plain white box around most of the inventory.",
			"Fixed slot borders losing their top (or another) edge: the window now snaps its origin to whole pixels on every layout so 1px borders land on real pixels again.",
		},
		changesDE = {
			"Qualitätsrahmen färben jetzt erst ab Ungewöhnlich (grün) statt Common - Weiß ist die Common-Qualitätsfarbe und hat um fast das ganze Inventar einen weißen Kasten gezeichnet.",
			"Fix: Slot-Ränder verloren die obere (oder eine andere) Kante - das Fenster snapt seinen Ursprung jetzt bei jedem Layout auf ganze Pixel, damit 1px-Ränder wieder auf echten Pixeln liegen.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Fixed some item icons rendering blank or partial: the icon field is no longer filtered to numbers (texture paths were dropped) and the whole icon read+apply runs inside one pcall so secret values can't leave a half-painted slot.",
		},
		changesDE = {
			"Fix: Manche Item-Icons renderten leer oder abgeschnitten - das Icon-Feld wird nicht mehr auf Zahlen gefiltert (Textur-Pfade gingen verloren) und das komplette Icon-Lesen läuft in einem pcall, damit Secret-Werte keinen halb bemalten Slot hinterlassen.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"Bag and bank windows can now be dragged directly by their title bar; the position is persisted through the mover DB (Movers.Save) so unlock-mode moves and resets stay consistent.",
		},
		changesDE = {
			"Taschen- und Bankfenster lassen sich jetzt direkt an der Titelzeile ziehen; die Position wird über die Mover-DB gespeichert (Movers.Save), damit Unlock-Modus und Reset konsistent bleiben.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Fixed the bag key needing two presses and the window refusing to close: hooks no longer toggle blindly, they mirror the game's real bag state (IsAnyBagOpen) after each call.",
			"New close button in the title bar and ESC support; hiding the window also settles the game's bag state so the next key press behaves.",
			"Fixed the toolbar layout: proper title row, buttons size to their captions and the window never gets narrower than the search bar and buttons.",
		},
		changesDE = {
			"Fix: Die Taschentaste brauchte zwei Drücke und das Fenster ließ sich nicht schließen - die Hooks toggeln nicht mehr blind, sondern spiegeln nach jedem Aufruf den echten Taschen-Status des Spiels (IsAnyBagOpen).",
			"Neu: Schließen-Button in der Titelzeile und ESC-Support; beim Verstecken wird auch der Taschen-Status des Spiels bereinigt, damit der nächste Tastendruck stimmt.",
			"Fix: Toolbar-Layout - eigene Titelzeile, Buttons passen sich ihrer Beschriftung an und das Fenster wird nie schmaler als Suchfeld und Buttons.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Fixed the bag key doing nothing: the game's container frames are now parked under a hidden parent instead of hidden outright, so the client's bag open/close state stays truthful and toggles keep working.",
			"New /sbags command toggles the bag window directly; the window also follows the game's BAG_OPEN/BAG_CLOSED events when present.",
			"Hardened slot painting and junk selling against secret values (isLocked, hasNoValue, quality) so one unreadable field can no longer break the whole grid or the merchant button.",
		},
		changesDE = {
			"Fix: Die Taschentaste tat nichts mehr - die Spiel-Taschen werden jetzt unter einen versteckten Parent geparkt statt versteckt, damit der Client-Öffnen/Schließen-Status stimmt und Toggles weiter funktionieren.",
			"Neu: /sbags schaltet das Taschenfenster direkt um; das Fenster folgt außerdem den BAG_OPEN/BAG_CLOSED-Events des Spiels, wenn vorhanden.",
			"Slot-Rendering und Schrott-Verkauf gegen Secret-Werte gehärtet (isLocked, hasNoValue, quality), damit ein unlesbares Feld nicht mehr das ganze Raster oder den Händler-Button bricht.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Bank window: the game's bank opens a second Sentinel window (bank container + bank bags + reagent bank) with its own mover, sort button and search. The Blizzard BankFrame is hidden.",
			"Categories: items group under headers — New, Quest, Equipment, Consumables, Trade goods, Miscellaneous, Junk, Empty — switchable for one flat grid.",
			"New items section: fresh loot lands on top first and clears when you close the window (client new-item flags).",
			"Currency strip: backpack-tracked currencies show as icon + amount in the bags footer.",
			"Per-view settings: slot size, spacing, columns, empty slots, quality border, item level and junk mark are now configured separately for bags and bank.",
		},
		changesDE = {
			"Bankfenster: Die Bank öffnet ein zweites Sentinel-Fenster (Bank-Fach + Banktaschen + Reagenzienbank) mit eigenem Mover, Sortier-Button und Suche. Das Blizzard-BankFrame wird versteckt.",
			"Kategorien: Items gruppieren sich unter Überschriften — Neu, Quest, Ausrüstung, Verbrauchbares, Handelswaren, Sonstiges, Schrott, Leer — abschaltbar für ein flaches Raster.",
			"Neue-Items-Sektion: Frische Beute landet zuerst oben und leert sich beim Schließen (Client-New-Item-Flags).",
			"Währungsleiste: Im Rucksack verfolgte Währungen zeigen sich als Icon + Betrag in der Fußzeile.",
			"Getrennte Ansichts-Einstellungen: Feldgröße, Abstand, Spalten, leere Felder, Qualitätsrahmen, Gegenstandsstufe und Schrott-Marke sind jetzt getrennt für Taschen und Bank einstellbar.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release: one clean Sentinel-styled bag window replacing the Blizzard bag frames. Unified grid over all carried bags with quality-colored borders, stack counts, item level on gear and a junk mark on grey items.",
			"Search box dims non-matching slots live; toolbar buttons sort bags, sell every grey item at an open vendor and repair. Optional automations: auto-sell grey items and auto repair (guild funds first, then own gold) when a merchant opens.",
			"Right-click uses items through a hidden SecureActionButton, left-click picks them onto the cursor; shift-click links, ctrl-click dresses up. The window is a mover.",
		},
		changesDE = {
			"Erste Version: ein sauberes Taschenfenster im Sentinel-Look ersetzt die Blizzard-Taschen. Einheitliches Raster über alle Taschen mit qualitätsgefärbten Rändern, Stapelzahlen, Gegenstandsstufe auf Ausrüstung und Schrott-Markierung auf grauen Items.",
			"Suchfeld blendet nicht passende Felder live ab; Toolbar-Buttons sortieren, verkaufen alle grauen Items beim offenen Händler und reparieren. Optionale Automatik: graue Items auto-verkaufen und auto-reparieren (erst Gildenkasse, dann eigenes Gold) beim Öffnen eines Händlers.",
			"Rechtsklick benutzt Items über einen versteckten SecureActionButton, Linksklick hebt sie auf den Cursor; Shift-Klick verlinkt, Strg-Klick zieht an. Das Fenster ist ein Mover.",
		},
	},
}
