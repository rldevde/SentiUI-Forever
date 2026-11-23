# SentiUI AccountInfo

## 1.5.4 - 2026-11-22

- The sidebar navigation uses the shared Sentinel tab chip now: dark inset body with a 2px accent blade on the left edge that glows on hover and burns on the active page, page icons kept - one design language across the whole suite instead of the module's own constants.

## 1.5.3 - 2026-11-22

- Fixed: the addon could be invisible to the client and the scanner stayed silent. Removed the `AllowLoadGameType` gate that no other SentiUI module uses.
- Character name/realm lookups no longer call globals that may not exist on this client: `GetUnitName("player", false)` for the name, `GetNormalizedRealmName`/`GetRealmName` for the realm - each pcall'd, so a missing API resolves to nil instead of throwing through every scan call.
- Error isolation: event handlers and internal callbacks (SAI_BOOT etc.) now run pcall'd. A throwing listener reports to chat instead of aborting the chain - one bad hook could previously keep the scanner's boot hook from ever running.

## 1.5.2 - 2026-11-22

- The current character was never scanned when PLAYER_ENTERING_WORLD fired before the module's enable (PLAYER_LOGIN): the initial scan only listened for that event. The scanner now also runs an initial scan on boot, retrying until the realm name is known.

## 1.5.1 - 2026-11-22

- No more 'unknown event' spam at login: RegisterEvent now validates via C_EventUtils.IsEventValid, so events this client dropped (PLAYERBANKBAGSLOTS_CHANGED, PLAYERREAGENTBANKSLOTS_CHANGED) are skipped quietly. Bank data still scans on BANKFRAME_OPENED.

## 1.5.0 - 2026-11-22

- SentiAccountInfo is now the SentiUI module SentiUI_AccountInfo: same window, same data (SentiAccountInfoDB carries over), registered under SentiUI > AccountInfo with an enable switch.
- Everything stays: dashboard, characters, search, per-character view, statistics, lockouts, currency/reputation, recipes, sync (export/import strings) and settings - plus item tooltips showing who owns what.
- The own minimap button is gone - SentiUI's minimap button and the new panel bar plugin cover it. Escape closes the window via S.EscClosable instead of UISpecialFrames.
- A disabled module is fully inert now: scanning, events and tooltip hooks only start when the module is enabled.
