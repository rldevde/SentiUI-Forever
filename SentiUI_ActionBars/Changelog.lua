-- Release history for the in-game changelog (SentiUI > Changelog).
-- `changes` = English, `changesDE` = German; keep CHANGELOG.md in sync.
local _, ns = ...

ns.CHANGELOG = {
	{
		version = "0.3.16",
		date = "2026-11-22",
		changes = {
			"Fix 'hide when empty' bars blinking on fresh characters: the bare SetShown fought the visibility state driver, which re-asserted 'show' and made the bar flicker every check tick. Empty bars now hide by unregistering the visibility driver and re-registering it when a slot gains an action; they also reappear while dragging a spell (ACTIONBAR_SHOWGRID) so they can receive drops.",
		},
		changesDE = {
			"Fix: 'Verstecken wenn leer'-Leisten blinkten auf frischen Charakteren - das nackte SetShown kaempfte gegen den Sichtbarkeits-State-Driver, der 'show' zuruecksetzte und die Leiste pro Pruef-Tick flackern liess. Leere Leisten verstecken sich jetzt ueber das Abmelden des Drivers und melden ihn wieder, sobald ein Platz eine Aktion traegt; beim Ziehen eines Zaubers erscheinen sie ebenfalls (ACTIONBAR_SHOWGRID), damit sie Drops annehmen.",
		},
	},
	{
		version = "0.3.15",
		date = "2026-11-22",
		changes = {
			"Real click blocker found via /suibars foci: parked Blizzard bars keep CHILD frames at their old rects with mouse enabled (an unnamed MultiBarBottomLeft child at MEDIUM/level 1001 sat over the extra bar). Parked subtrees and the status-tracking containers now lose their mouse recursively; secure twin buttons keep theirs (click targets). Unnamed fullscreen ModelScenes lose the mouse in the sweep.",
		},
		changesDE = {
			"Echter Klick-Blocker via /suibars foci gefunden: geparkte Blizzard-Leisten behalten KIND-Frames an alter Position mit aktiver Maus (ein namenloses MultiBarBottomLeft-Kind auf MEDIUM/Level 1001 lag ueber der Zusatzleiste). Geparkte Teilbaeume und Status-Tracking-Container verlieren jetzt rekursiv ihre Maus; die sicheren Twin-Buttons behalten ihre (Klick-Ziele). Namenlose Vollbild-ModelScenes verlieren die Maus im Sweep.",
		},
	},
	{
		version = "0.3.14",
		date = "2026-11-22",
		changes = {
			"TextOverlayContainer can be created lazily after the button - its mouse now gets disabled in the 2s sweep too, not only at button creation.",
		},
		changesDE = {
			"TextOverlayContainer kann erst lazy nach dem Button entstehen - seine Maus wird jetzt auch im 2s-Sweep abgestellt, nicht nur bei der Button-Erzeugung.",
		},
	},
	{
		version = "0.3.13",
		date = "2026-11-22",
		changes = {
			"Follow-up click fix: the widget CONTAINER frames themselves (UIWidgetBelowMinimap/TopCenter/PowerBar, ObjectiveTrackerUIWidget, ContainerFrame) also lose their mouse - they are pure layout frames; children keep their own hit flags. New /suibars foci prints the mouse-enabled frames under the cursor so any remaining click blocker names itself.",
		},
		changesDE = {
			"Klick-Fix Nachtrag: die Widget-CONTAINER selbst (UIWidgetBelowMinimap/TopCenter/PowerBar, ObjectiveTrackerUIWidget, ContainerFrame) verlieren ebenfalls ihre Maus - reine Layout-Frames, die Kinder behalten eigene Hit-Flags. Neu: /suibars foci zeigt die mausaktiven Frames unter dem Cursor, damit sich ein verbleibender Klick-Blocker selbst nennt.",
		},
	},
	{
		version = "0.3.12",
		date = "2026-11-22",
		changes = {
			"Fix extension bar slots only clicking on a thin lower rim: the template's TextOverlayContainer rides at frame level 500 with its mouse enabled and covered the whole button, and the client's global FX/widget model scenes at high strata swallowed clicks where they overlap the bars. The container's mouse is dropped per button; the FX/widget model scenes lose theirs on a 2s sweep (they respawn late).",
		},
		changesDE = {
			"Fix: Slots der Zusatzleisten liessen sich nur an einem schmalen unteren Rand klicken - der TextOverlayContainer des Templates liegt auf Frame-Level 500 mit aktiver Maus ueber dem ganzen Button, und die globalen FX-/Widget-ModelScenes des Clients auf hohen Strata schluckten Klicks, wo sie die Leisten ueberlagern. Die Maus des Containers wird je Button abgestellt; die FX-/Widget-ModelScenes verlieren ihre im 2s-Sweep (sie spawnen spaet neu).",
		},
	},
	{
		version = "0.3.11",
		date = "2026-11-22",
		changes = {
			"Holder attach keeps ExtraAbilityContainer and friends in place by a 0.5s drift poll instead of SetParent/SetPoint post-hooks - the hooks ran inside the client's layout dispatch and tainted whatever protected work followed.",
		},
		changesDE = {
			"Die Holder-Befestigung hält ExtraAbilityContainer & Co. per 0,5s-Drift-Poll statt SetParent/SetPoint-Post-Hooks - die Hooks liefen im Layout-Dispatch des Clients und vergifteten die geschützte Arbeit danach.",
		},
	},
	{
		version = "0.3.10",
		changes = {
			"The labelled Call/Sec wrappers now delegate to the shared core wrapper (S.Call): blocked engine calls print the api name AND the call site (file.lua:line) once.",
		},
		changesDE = {
			"Die gelabelten Call/Sec-Wrapper delegieren jetzt an den gemeinsamen Core-Wrapper (S.Call): Blockierte Engine-Calls melden API-Namen UND Aufrufstelle (datei.lua:zeile) einmal.",
		},
	},

	{
		version = "0.3.9",
		changes = {
			"Fixed the action-button press point covering only the slot's center: ActionBarButtonTemplate ships an inset hit rect (the artwork ring is not clickable), while our slot look fills the whole button - the hit rect is reset to the full frame now.",
		},
		changesDE = {
			"Der Druckpunkt auf Aktionsbuttons traf nur die Slot-Mitte: ActionBarButtonTemplate bringt einen eingezogenen Hit-Rect mit (der Artwork-Ring ist nicht klickbar), waehrend unser Slot den ganzen Button fuellt - der Hit-Rect deckt jetzt den vollen Frame ab.",
		},
	},

	{
		version = "0.3.8",
		changes = {
			"Interface-dispatch audit: micro-button alert frames are hidden via visibility watchers instead of OnShow hooks (insecure scripts in the alert dispatch taint the client's follow-up). The talent pill forwards a real secure click to the micro button instead of calling ToggleTalentFrame; watcher installation is deduplicated.",
		},
		changesDE = {
			"Interface-Dispatch-Audit: Micro-Button-Alerts werden ueber Sichtbarkeits-Watcher statt OnShow-Hooks versteckt (unsichere Scripts im Alert-Dispatch tainten die Folgearbeit des Clients). Die Talent-Pille leitet einen echten Secure-Click an den Micro-Button weiter statt ToggleTalentFrame zu rufen; Watcher-Installation dedupliziert.",
		},
	},

	{
		version = "0.3.7",
		changes = {
			"Dispatcher rollback: the event-removal/poll rework broke the bars - the full native event set is back (slot/state/autorepeat/combat/mount/cooldown/usable/range/charges/target/shapeshift/page/vehicle), the 0.2s state poll and button signatures are gone.",
		},
		changesDE = {
			"Dispatcher-Rollback: Der Event-Entfernungs-/Poll-Umbau hat die Leisten kaputtgemacht - das volle native Event-Set ist zurueck (Slot/State/Autorepeat/Kampf/Mount/Cooldown/Usable/Range/Charges/Target/Shapeshift/Page/Vehicle), der 0,2s-Status-Poll und die Button-Signaturen sind weg.",
		},
	},
	{
		version = "0.3.6",
		changes = {
			"Cooldown repaint fixed: cooldown times are secret so they cannot live in the button signature - a spell recast during an active cooldown produced no transition and the sweep froze, which made healer bars look dead. A button now repaints whenever its signature changes AND on every tick while a cooldown runs (the sweep handles secret times natively). The signature also diffs the slot texture id and checked state, so ACTIONBAR_SLOT_CHANGED/UPDATE_STATE/AUTOREPEAT events could go too - they fired inside the spell-drag and auto-shot click dispatches. Combat and mount state moved into the poll as well.",
		},
		changesDE = {
			"Cooldown-Repaint gefixt: Cooldown-Zeiten sind secret und können nicht in die Button-Signatur - ein Recast bei laufendem Cooldown erzeugte keinen Wechsel und der Sweep fror ein, wodurch Heiler-Leisten tot wirkten. Ein Button zeichnet jetzt bei jedem Signatur-Wechsel UND bei jedem Tick, solange ein Cooldown läuft (der Sweep verarbeitet Secret-Zeiten nativ). Die Signatur prüft zusätzlich die Slot-Textur-ID und den Checked-State, sodass auch ACTIONBAR_SLOT_CHANGED/UPDATE_STATE/AUTOREPEAT-Events weg konnten - sie feuerten im Spell-Drag- und Autoschuss-Klick-Dispatch. Kampf- und Mount-Status laufen ebenfalls über den Poll.",
		},
	},
	{
		version = "0.3.5",
		changes = {
			"Cooldown/usable/range/charge events moved into the 0.2s bar state poll as a per-button signature - those events fire inside the protected cast and target-swap dispatches and tainted Blizzard's CooldownFrame_Set on secret times.",
		},
		changesDE = {
			"Cooldown-/Usable-/Reichweiten-/Ladungs-Events als Pro-Button-Signatur in den 0,2s-Bar-State-Poll verlagert - die Events feuern im geschuetzten Cast- und Zielwechsel-Dispatch und tainteten Blizzards CooldownFrame_Set bei Secret-Werten.",
		},
	},
	{
		version = "0.3.4",
		changes = {
			"Input-dispatch events replaced by a state poll: PLAYER_TARGET_CHANGED, UPDATE_SHAPESHIFT_FORM(S), UPDATE_BONUS_ACTIONBAR, ACTIONBAR_PAGE_CHANGED, UPDATE_VEHICLE_ACTIONBAR and UPDATE_OVERRIDE_ACTIONBAR all fire inside protected key/click dispatches, where Lua taints the client's follow-up protected calls. A 0.2s poll now watches target presence, action page, shapeshift form and vehicle/override/bonus/possess state and issues the same queued repaints.",
		},
		changesDE = {
			"Input-Dispatch-Events durch State-Poll ersetzt: PLAYER_TARGET_CHANGED, UPDATE_SHAPESHIFT_FORM(S), UPDATE_BONUS_ACTIONBAR, ACTIONBAR_PAGE_CHANGED, UPDATE_VEHICLE_ACTIONBAR und UPDATE_OVERRIDE_ACTIONBAR feuern in geschützten Tasten-/Klick-Dispatches, wo Lua die folgenden geschützten Aufrufe taintet. Ein 0,2s-Poll überwacht jetzt Ziel, Aktionsseite, Gestalt und Fahrzeug-/Override-/Bonus-/Besessen-Status und stößt dieselben gequeuüten Repaints an.",
		},
	},
	{
		version = "0.3.3",
		changes = {
			"Escape-forbidden-call fix: the EditMode manager's OnHide hook ran inside the Escape dispatch when leaving Edit Mode - it watches the hidden transition via S.WatchHide now.",
		},
		changesDE = {
			"Escape-Blockier-Fix: Der OnHide-Hook des EditMode-Managers lief im Escape-Dispatch beim Verlassen des Edit-Modus - er beobachtet den Uebergang jetzt ueber S.WatchHide.",
		},
	},

	{
		version = "0.3.2",
		changes = {
			"Status tracking bars are no longer reparented into the park frame - layout passes call their manager methods, which expect the real parent (caused 'blizzard: TextStatusBar' errors). They now stay put with events off and alpha 0.",
			"Extra-button attach: when another addon's holder frame claims the same Blizzard frame, we yield instead of fighting it - two holder hooks ping-ponged ExtraAbilityContainer into a C stack overflow when both UI suites were loaded.",
		},
		changesDE = {
			"Status-Tracking-Leisten werden nicht mehr in den Park-Frame umgarentet - Layout-Pässe rufen ihre Manager-Methoden auf, die den echten Parent erwarten (verursachte 'blizzard: TextStatusBar'-Fehler). Sie bleiben jetzt mit abgeschalteten Events und Alpha 0 an Ort und Stelle.",
			"Extra-Button-Verankerung: Beansprucht ein fremder Holder-Frame dasselbe Blizzard-Frame, geben wir nach statt zu kämpfen - zwei Holder-Hooks haben ExtraAbilityContainer per Ping-Pong in einen C-Stack-Overflow getrieben, wenn beide UI-Suiten geladen waren.",
		},
	},
	{
		version = "0.3.1",
		changes = {
			"Stopped the StatusTrackingBarManager's events under the park frame - its Blizzard TextStatusBar updates kept running while hidden and errored on the client's secret XP/reputation values (error source 'blizzard: TextStatusBar').",
		},
		changesDE = {
			"Events des StatusTrackingBarManager unter dem Park-Frame abgeschaltet - seine Blizzard-TextStatusBar-Updates liefen versteckt weiter und crashten an den Secret-EP-/Rufwerten des Clients (Fehlerquelle 'blizzard: TextStatusBar').",
		},
	},
	{
		version = "0.3.0",
		changes = {
			"Unspent-talent-points hint redone in SentiUI style: the game's micro-button alert anchored to the parked micro bar and floated mid-screen - all *MicroButtonAlert frames are now re-hidden, and a small gold-lit pill above the bottom bars shows 'Unspent talent points: N' instead (count via UnitCharacterPoints / C_ClassTalents where available, otherwise it still follows the game's own alert). Click opens the talent frame. German label 'Unverteilte Talentpunkte'.",
		},
		changesDE = {
			"Hinweis auf unverteilte Talentpunkte im SentiUI-Stil: Der Micro-Button-Hinweis des Spiels ankerte an der geparkten Micro-Leiste und schwebte mitten im Bild - alle *MicroButtonAlert-Frames werden jetzt wieder versteckt, stattdessen zeigt eine kleine gold umrandete Pille über der unteren Leiste 'Unverteilte Talentpunkte: N' (Zähler über UnitCharacterPoints / C_ClassTalents wo verfügbar, sonst folgt sie dem Spiel-Hinweis). Klick öffnet das Talentfenster.",
		},
	},
	{
		version = "0.2.9",
		changes = {
			"Parking/hidden frames now stub the Blizzard layout methods (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame) that client scripts call on GetParent() - fixes a StatusTrackingManager UpdateShownState crash caused by frames parked under a bare hidden parent.",
		},
		changesDE = {
			"Park-/Versteck-Frames stubben jetzt die Blizzard-Layout-Methoden (Layout, MarkDirty, SetNeedsLayout, UpdateLayout, IsLayoutFrame), die Client-Skripte auf GetParent() aufrufen - behebt einen StatusTrackingManager-UpdateShownState-Fehler durch unter einem nackten versteckten Parent geparkte Frames.",
		},
	},
	{
		version = "0.2.8",
		changes = {
			"Every bar now fires through the game's own twin button (type=click on ActionButton1-12 / MultiBar*ButtonN): the twin knows its real action slot AND handles the Shift pickup modifier natively, so casting and pickup behave exactly like the client's own buttons. Bar 1's twins get their page pushed by the existing state snippet.",
			"Click registration is AnyDown+AnyUp again: this client ignores useOnKeyDown=false and fires on the down half, so AnyUp alone made all bars dead. Drag-out pickup stays gated on Shift / unlocked bars.",
			"Removed the custom OnMouseDown pickup hack - the twin's own modified click logic covers press-to-pickup.",
		},
		changesDE = {
			"Jede Leiste feuert jetzt über den eigenen Zwillingsbutton des Spiels (type=click auf ActionButton1-12 / MultiBar*ButtonN): Der Twin kennt seinen echten Action-Slot UND handhabt den Shift-Aufnahme-Modifikator nativ - Zaubern und Aufnehmen verhalten sich exakt wie bei den Original-Buttons. Die Twins von Leiste 1 bekommen ihre Seite vom vorhandenen State-Snippet gepusht.",
			"Click-Registrierung ist wieder AnyDown+AnyUp: Der Client ignoriert useOnKeyDown=false und feuert auf der Down-Hälfte - nur AnyUp machte alle Leisten tot. Drag-out-Pickup bleibt an Shift / entsperrte Leisten gebunden.",
			"Der eigene OnMouseDown-Pickup-Hack ist raus - die Modified-Click-Logik des Twins deckt Press-to-Pickup ab.",
		},
	},
	{
		version = "0.2.7",
		changes = {
			"Bars 2-4 now actually cast: instead of type=action + a guessed slot, each button clicks through to the game's own twin button (type=click + clickbutton on MultiBarBottomLeftButtonN etc.) - the twin holds the client's real action mapping, so the spell it shows is the spell that fires. The slot attribute still feeds painting and pickup.",
		},
		changesDE = {
			"Leisten 2-4 wirken jetzt wirklich: Statt type=action + geratenem Slot klickt jeder Button auf den eigenen Zwillingsbutton des Spiels (type=click + clickbutton auf MultiBarBottomLeftButtonN etc.) - der Twin trägt das echte Action-Mapping des Clients, also feuert der Zauber, der angezeigt wird. Das Slot-Attribut bleibt für Painting und Aufnehmen.",
		},
	},
	{
		version = "0.2.6",
		changes = {
			"Fixed bars 2-4 doing nothing: their buttons pointed at main-bar page slots (61-72, 49-60, 25-36) instead of the multi-bar ranges. Buttons now read their action slot from the game's own twin button (MultiBarBottomLeft = 85-96 etc. on this client's 132-slot map), so the mapping is correct whatever the client uses; the old page math stays as fallback only.",
		},
		changesDE = {
			"Leisten 2-4 taten nichts: Ihre Buttons zeigten auf Hauptleisten-Seiten-Slots (61-72, 49-60, 25-36) statt auf die Multi-Leisten-Bereiche. Buttons lesen ihren Action-Slot jetzt vom eigenen Zwillingsbutton des Spiels (MultiBarBottomLeft = 85-96 etc. im 132-Slot-Mapping des Clients) - das Mapping ist damit korrekt, egal was der Client nutzt; die alte Seitenrechnung bleibt nur als Fallback.",
		},
	},
	{
		version = "0.2.5",
		changes = {
			"Fixed dead action bars: IsModifiedClick(\"PICKUPACTION\") can return truthy on this client without the key being held, so every button press picked the spell up instead of casting it. Pickup now requires Shift held (the game's default modifier) or unlocked action bars.",
		},
		changesDE = {
			"Tote Aktionsleisten gefixt: IsModifiedClick(\"PICKUPACTION\") kann auf diesem Client truthy antworten, ohne dass die Taste gehalten wird - jeder Tastendruck nahm den Zauber auf statt ihn zu wirken. Aufnehmen braucht jetzt gehaltene Shift-Taste (Spiel-Standard) oder entsperrte Aktionsleisten.",
		},
	},
	{
		version = "0.2.4",
		changes = {
			"Dragging an action off a bar no longer triggers it: pickup now needs the pick-up modifier (Shift by default, remappable via the PICKUPACTION binding) or unlocked action bars, matching normal WoW behavior.",
			"Buttons fire on release only (AnyUp) - the AnyDown registration let a plain press cast before a drag could start.",
		},
		changesDE = {
			"Das Herausziehen einer Aktion löst sie nicht mehr aus: Das Aufnehmen braucht jetzt den Aufnahme-Modifikator (Standard Shift, per PICKUPACTION-Belegung änderbar) oder entsperrte Aktionsleisten - wie im normalen Spiel.",
			"Buttons feuern erst beim Loslassen (AnyUp) - die AnyDown-Registrierung ließ ein einfaches Drücken schon zaubern, bevor ein Ziehen starten konnte.",
		},
	},
	{
		version = "0.2.3",
		changes = {
			"The Counts toggle is honored now: the count painter ignored the setting and always drew item and charge counts.",
		},
		changesDE = {
			"Der Counts-Schalter greift jetzt: Der Zähler-Painter ignorierte die Einstellung und malte Item-/Charge-Zahlen immer.",
		},
	},
	{
		version = "0.2.2",
		changes = {
			"Fixed the park pass dying mid-list: BagsBar and MicroButtonAndBagsBar are plain controller tables on this client, not frames - a nil GetParent call aborted the loop and left everything after them (status tracking bar, micro menu, totem bar, cooldown viewers) visible.",
			"Fixed clicks on the action bars: the un-parked MultiCastActionBarFrame sat on top of the buttons and ate them.",
			"Buttons now also register for AnyDown so press-and-hold casting works.",
		},
		changesDE = {
			"Der Park-Durchlauf starb mitten in der Liste: BagsBar und MicroButtonAndBagsBar sind auf diesem Client reine Tabellen, keine Frames - der nil-Call brach die Schleife ab und ließ alles danach (Fortschrittsleiste, Micro-Menü, Totem-Leiste, Cooldown-Viewer) sichtbar.",
			"Klicks auf den Aktionsleisten gehen wieder: Das ungeparkte MultiCastActionBarFrame lag über den Buttons und fraß sie.",
			"Buttons registrieren jetzt auch AnyDown, damit Press-and-Hold-Casting geht.",
		},
	},
	{
		version = "0.2.1",
		changes = {
			"Fixed cooldowns never sweeping: without a DurationObject the sweep fell through to Clear() on every paint - now it uses raw times while they are readable, and leaves an active sweep alone instead of clearing it.",
			"Fixed parked game frames coming back: the game re-parents its bars on its own layout passes, so the park now rechecks behind UpdateMicroButtons, the micro menu fullscreen hand-offs, talent/spec updates, Edit Mode changes and the vehicle/override events.",
			"Each post-build enable step runs on its own now - one failure can no longer take the extras (pet/stance/totem bars) down with it.",
		},
		changesDE = {
			"Cooldowns zeichneten nie: Ohne DurationObject lief der Sweep bei jedem Paint in Clear() - jetzt nutzt er lesbare Rohzeiten und lässt einen laufenden Sweep stehen statt ihn zu löschen.",
			"Geparkte Spiel-Frames kamen zurück: Das Spiel setzt seine Bars bei eigenen Layout-Durchläufen zurück - der Park prüft jetzt hinter UpdateMicroButtons, den Fullscreen-Übergaben, Talent-/Spec-Updates, Edit-Mode-Änderungen und den Vehicle-/Override-Events nach.",
			"Jeder Enable-Schritt nach dem Bau läuft jetzt einzeln abgesichert - ein Fehler reißt die Extras (Pet-/Stance-/Totem-Bars) nicht mehr mit.",
		},
	},
	{
		version = "0.2.0",
		changes = {
			"Full rework of the bar engine to the proven native architecture: every button is detached from the game's dispatch lists right after creation - the template's OnLoad had signed each button up, so the game ran its own protected writes (SetAttribute/SetShown) on our buttons under addon taint and every one of them was the 'UNKNOWN()' blocked call. That root cause is gone; no pcall can hide a blocked call, so now nothing shared ever runs on our buttons.",
			"Painting is event-driven now (no more 0.15s poll): per-painter updates on the real game events, queued to one flush per frame, plus the range watch only while a target exists.",
			"Keybinds work natively again: they press the game's hidden twin buttons and the secure page driver copies bar 1's page onto them (actionpage) - cast-on-key-down included, no override bindings. Only flyout slots are re-pointed.",
			"The game's bars are parked (reparented under a hidden frame) instead of alpha-faded; their twin buttons are unlisted and parked too so no in-fight layout pass touches them.",
			"Stance and pet bars adopt the game's own buttons (StanceButton*/PetActionButton*) - their updates, keybinds and tooltips stay the game's.",
			"Cooldowns stay secret-safe through the DurationObject path; the slot mapping now matches the client's real bar pages (bar2=6, bar3=5, bar4=3).",
		},
		changesDE = {
			"Leisten-Engine komplett auf die bewährte native Architektur umgebaut: Jeder Button wird direkt nach dem Erstellen aus den Dispatch-Listen des Spiels getragen - das Template-OnLoad hatte jeden Button eingetragen, also liefen die geschützten Schreibzugriffe des Spiels (SetAttribute/SetShown) unter Addon-Taint auf unseren Buttons und jeder war der 'UNKNOWN()'-Block. Die Ursache ist weg; kein pcall versteckt einen geblockten Call - jetzt läuft nichts Geteiltes mehr auf unseren Buttons.",
			"Das Zeichnen ist jetzt event-getrieben (kein 0.15s-Poll mehr): Pro-Painter-Updates auf die echten Spiel-Events, gebündelt in einen Flush pro Frame, plus der Range-Watch nur mit Ziel.",
			"Keybinds laufen wieder nativ: Sie drücken die versteckten Twin-Buttons des Spiels und der Secure-Page-Driver kopiert die Seite von Bar 1 auf sie (actionpage) - inklusive Cast-on-Key-Down, keine Override-Bindings. Nur Flyout-Slots werden umgelenkt.",
			"Die Leisten des Spiels werden geparkt (unter einen versteckten Frame gelegt) statt ge-alphat; auch ihre Twin-Buttons sind unlisted und geparkt, damit kein Layout-Durchlauf im Kampf sie anfasst.",
			"Stance- und Pet-Bar adoptieren die eigenen Buttons des Spiels (StanceButton*/PetActionButton*) - Updates, Keybinds und Tooltips bleiben beim Spiel.",
			"Cooldowns bleiben über den DurationObject-Pfad secret-sicher; das Slot-Mapping nutzt jetzt die echten Bar-Seiten des Clients (bar2=6, bar3=5, bar4=3).",
		},
	},
	{
		version = "0.1.22",
		changes = {
			"Fixed the action bars not loading at all (Blizzard bars visible again): the labelled Call() helper was declared below DriverHide, so Blizzard suppression called a nil global and Enable aborted before creating a single bar - leaving Core.enabled stuck on so no retry ever ran. Call/Sec are now declared at the top of the file.",
			"Fixed the duration-object reads: Call() returns its ok flag first, so GetActionCooldownDuration's object never reached the cooldown widget.",
		},
		changesDE = {
			"Actionbars luden gar nicht mehr (Blizzard-Leisten wieder sichtbar): Der Call()-Helper stand unter DriverHide, die Blizzard-Unterdrückung rief also ein nil-Global auf und Enable brach ab, bevor eine Leiste gebaut wurde - Core.enabled blieb true, kein Retry lief je. Call/Sec stehen jetzt ganz oben.",
			"DurationObject-Lesefehler gefixt: Call() gibt zuerst sein ok-Flag zurück, das Objekt von GetActionCooldownDuration kam nie beim Cooldown-Widget an.",
		},
	},
	{
		version = "0.1.21",
		changes = {
			"Fixed the 100x cooldown spam ('Cooldown.lua: attempt to compare local start (a secret number value)'): the cooldown widget now gets a DurationObject (GetActionCooldownDuration / C_DurationUtil.CreateDuration) instead of raw secret numbers - the widget handles secrets natively in C++, no Lua compare. Raw CooldownFrame_Set is only used when the values are actually readable.",
			"securecall was tested and does NOT untaint on this client - removed from the cooldown path.",
		},
		changesDE = {
			"Der 100x Cooldown-Spam gefixt ('Cooldown.lua: attempt to compare local start (a secret number value)'): Der Cooldown-Widget bekommt jetzt ein DurationObject (GetActionCooldownDuration / C_DurationUtil.CreateDuration) statt roher Secret-Werte - das Widget verarbeitet Secrets nativ in C++, ohne Lua-Vergleich. Rohes CooldownFrame_Set läuft nur noch bei wirklich lesbaren Werten.",
			"securecall wurde getestet und ent-taintet auf diesem Client NICHT - aus dem Cooldown-Pfad entfernt.",
		},
	},
	{
		version = "0.1.20",
		changes = {
			"Cooldown and tooltip calls that touch secret values internally now run through securecall (untainted) - fixes 'attempt to compare local start (a secret number value)' in the client's cooldown code and the resulting blocked/forbidden spam.",
		},
		changesDE = {
			"Cooldown- und Tooltip-Calls, die intern geheime Werte anfassen, laufen jetzt über securecall (untainted) - fixt 'attempt to compare local start (a secret number value)' im Cooldown-Code des Clients und den entstehenden blocked/forbidden-Spam.",
		},
	},
	{
		version = "0.1.19",
		changes = {
			"Every engine call in the module now runs through a labelled wrapper that tracks the current call site - since ADDON_ACTION_FORBIDDEN fires synchronously, the chat now names the exact call that got blocked (e.g. 'forbidden during GameTooltip:SetAction') instead of UNKNOWN().",
		},
		changesDE = {
			"Jeder Engine-Call im Modul läuft jetzt durch einen gelabelten Wrapper, der die aktuelle Aufrufstelle mitführt - da ADDON_ACTION_FORBIDDEN synchron feuert, nennt der Chat jetzt den exakten blockierten Call (z.B. 'forbidden during GameTooltip:SetAction') statt UNKNOWN().",
		},
	},
	{
		version = "0.1.18",
		changes = {
			"The blocked-api diagnostic now also shows the bug tracker hint (https://dev.xrl-dev.de/bugtracker).",
		},
		changesDE = {
			"Die blocked-api-Diagnose zeigt jetzt auch den Bugtracker-Hinweis (https://dev.xrl-dev.de/bugtracker).",
		},
	},
	{
		version = "0.1.17",
		changes = {
			"If the module enables during combat (e.g. /reload mid-fight), bar construction is deferred until combat ends - frames created during lockdown are born protected and every layout call would fire ADDON_ACTION_FORBIDDEN.",
		},
		changesDE = {
			"Wenn das Modul im Kampf aktiviert wird (z.B. /reload im Kampf), wird der Leistenbau bis zum Kampfende verschoben - im Lockdown erstellte Frames werden protected geboren und jeder Layout-Call würde ADDON_ACTION_FORBIDDEN feuern.",
		},
	},
	{
		version = "0.1.16",
		changes = {
			"Fixed the ADDON_ACTION_FORBIDDEN spam: GetBindingKey/GetBindingText are now read once per binding change instead of ~320x/sec in the refresh tick - binding queries from insecure code are restricted on this client.",
			"Every client API read in the button update is now labelled - if another protected call ever fires, the error names the exact API instead of UNKNOWN().",
		},
		changesDE = {
			"ADDON_ACTION_FORBIDDEN-Spam gefixt: GetBindingKey/GetBindingText werden jetzt einmal pro Binding-Änderung gelesen statt ~320x/Sek im Refresh-Tick - Binding-Abfragen aus insecurem Code sind auf diesem Client eingeschränkt.",
			"Jeder Client-API-Read im Button-Update ist jetzt gelabelt - falls noch ein protected Call feuert, nennt der Fehler die genaue API statt UNKNOWN().",
		},
	},
	{
		version = "0.1.15",
		changes = {
			"SetFont rounds sizes first - the client rejects float font sizes and silently leaves the FontString without a font.",
		},
		changesDE = {
			"SetFont rundet Größen jetzt - der Client lehnt Float-Schriftgrößen ab und lässt den FontString ohne Schrift.",
		},
	},
	{
		version = "0.1.14",
		changes = {
			"The combat checked-state path no longer calls GetCheckedTexture on the protected button - the texture is captured at creation.",
		},
		changesDE = {
			"Der Kampf-Checked-Pfad ruft kein GetCheckedTexture mehr auf dem geschützten Button auf - die Textur wird bei der Erstellung gespeichert.",
		},
	},
	{
		version = "0.1.13",
		changes = {
			"Stopped the repeating \"forbidden call\" reports: the button tick no longer calls restricted methods on protected buttons in combat (checked state only on change via the texture, cached hotkeys, layouts deferred to after combat).",
			"More secret-value guards in the pet/stance/totem updates - IsSecret is checked before any comparison.",
		},
		changesDE = {
			"Die wiederholten \"forbidden call\"-Meldungen gestoppt: Der Button-Tick ruft im Kampf keine beschränkten Methoden mehr auf geschützten Buttons auf (Checked-Zustand nur bei Änderung über die Textur, Hotkeys gecacht, Layouts auf nach dem Kampf verschoben).",
			"Mehr Secret-Wert-Guards in den Begleiter-/Haltungs-/Totem-Updates - IsSecret wird vor jedem Vergleich geprüft.",
		},
	},
	{
		version = "0.1.12",
		changes = {
			"Vehicle exit and taxi landing buttons show Sentinel icons now instead of red text.",
		},
		changesDE = {
			"Fahrzeug-Ausstieg und Taxi-Landung zeigen jetzt Sentinel-Icons statt rotem Text.",
		},
	},
	{
		version = "0.1.11",
		changes = {
			"Internal error reports use S.Stack now - the real traceback prints instead of \"error in error handling\".",
		},
		changesDE = {
			"Interne Fehlermeldungen nutzen jetzt S.Stack - der echte Traceback erscheint statt \"error in error handling\".",
		},
	},
	{
		version = "0.1.10",
		changes = {
			"Release history is now filed for the in-game changelog (SentiUI > Changelog, English + German).",
		},
		changesDE = {
			"Die Versionshistorie ist jetzt im In-Game-Changelog eingetragen (SentiUI > Changelog, Englisch + Deutsch).",
		},
	},
	{
		version = "0.1.9",
		changes = {
			"Stance bar capped at the real form/stance count - no more phantom buttons on characters without forms, and it still grows as stances are learned.",
		},
		changesDE = {
			"Haltungsleiste auf die echte Form-/Haltungsanzahl begrenzt - keine Phantom-Buttons mehr ohne Formen, und sie wächst weiter automatisch mit.",
		},
	},
	{
		version = "0.1.8",
		changes = {
			"Removed the micro menu bar: the minimap menu already covers the game menu and the client does not expose usable button icons.",
		},
		changesDE = {
			"Micro-Leiste entfernt: Das Minimap-Menü deckt das Spielmenü ab und der Client liefert keine brauchbaren Button-Icons.",
		},
	},
	{
		version = "0.1.7",
		changes = {
			"Micro bar rebuilt on own Sentinel buttons forwarding clicks to the hidden Blizzard buttons via /click.",
		},
		changesDE = {
			"Micro-Leiste neu: eigene Sentinel-Buttons leiten Klicks per /click an die versteckten Blizzard-Buttons weiter.",
		},
	},
	{
		version = "0.1.6",
		changes = {
			"Fixed \"hide when empty\": HasAction returns secret values on this client - the check now looks for an action texture, so empty bars actually vanish.",
		},
		changesDE = {
			"\"Verstecken wenn leer\" gefixt: HasAction liefert auf diesem Client Secret-Werte - jetzt zählt die Aktions-Textur, und leere Leisten verschwinden wirklich.",
		},
	},
	{
		version = "0.1.5",
		changes = {
			"New \"Vertical\" option on every bar: action bars fill columns, pet/stance/totem bars stack downward.",
			"New micro bar with the Blizzard menu buttons reparented into a movable Sentinel bar.",
		},
		changesDE = {
			"Neue \"Vertikal\"-Option auf jeder Leiste: Aktionsleisten füllen Spalten, Begleiter-/Haltungs-/Totem-Leisten stapeln nach unten.",
			"Neue Micro-Leiste mit den Blizzard-Menübuttons in einer verschiebbaren Sentinel-Leiste.",
		},
	},
	{
		version = "0.1.4",
		changes = {
			"Internal error reports now include a Lua traceback - the failing file and line show in chat.",
		},
		changesDE = {
			"Interne Fehlermeldungen zeigen jetzt einen Lua-Traceback - Datei und Zeile stehen im Chat.",
		},
	},
	{
		version = "0.1.3",
		changes = {
			"Buttons now use the native C_ActionBar.* API: real cooldown sweeps via DurationObject, display counts, and the checked glow on active abilities.",
		},
		changesDE = {
			"Buttons nutzen jetzt die native C_ActionBar.*-API: echte Cooldown-Sweeps per DurationObject, Anzeigezahlen und der Aktiv-Glow auf laufenden Fähigkeiten.",
		},
	},
	{
		version = "0.1.2",
		changes = {
			"New per-bar option \"Hide when empty\" (default on for bars 2-4): no more dark empty rows.",
		},
		changesDE = {
			"Neue Option \"Verstecken wenn leer\" pro Leiste (Standard: an für Leiste 2-4): keine dunklen Leerreihen mehr.",
		},
	},
	{
		version = "0.1.1",
		changes = {
			"The client's Cooldown Manager viewers (Essential/Utility/BuffIcon/BuffBar) are suppressed too - they load on demand, so suppression re-runs after every addon load.",
		},
		changesDE = {
			"Die Cooldown-Manager-Anzeigen des Clients (Essential/Utility/BuffIcon/BuffBar) werden ebenfalls unterdrückt - sie laden bei Bedarf, also läuft die Unterdrückung nach jedem Addon-Load erneut.",
		},
	},
	{
		version = "0.1.0",
		changes = {
			"First release, ported from the proven SentinelForeverCore implementation.",
			"Bar 1 pages through druid forms, warrior stances, stealth, shadowform, monk/evoker states, vehicles, override and possess bars.",
			"Bars 2-4 on the free pages, pet bar, stance bar, totem bar, extra/zone buttons, vehicle exit and taxi landing.",
			"Secure buttons with drag & drop, key binds, hotkey/count/macro text, range coloring and tooltips; all bars are movers.",
		},
		changesDE = {
			"Erste Version, portiert aus der bewährten SentinelForeverCore-Umsetzung.",
			"Leiste 1 blättert durch Druidenformen, Kriegerhaltungen, Verstohlenheit, Schattengestalt, Mönch-/Evoker-Zustände, Fahrzeug-, Override- und Possess-Leisten.",
			"Leisten 2-4 auf den freien Seiten, Begleiter-, Haltungs- und Totemleiste, Extra-/Zonen-Buttons, Fahrzeugausstieg und Taxi-Landung.",
			"Sichere Buttons mit Drag & Drop, Tastenbelegung, Hotkey-/Anzahl-/Makrotext, Reichweitenfärbung und Tooltips; alle Leisten sind Mover.",
		},
	},
}
