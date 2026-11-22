# SentiUI AccountInfo

## 1.5.1 - 2026-11-22

- No more 'unknown event' spam at login: RegisterEvent now validates via C_EventUtils.IsEventValid, so events this client dropped (PLAYERBANKBAGSLOTS_CHANGED, PLAYERREAGENTBANKSLOTS_CHANGED) are skipped quietly. Bank data still scans on BANKFRAME_OPENED.

## 1.5.0 - 2026-11-22

- SentiAccountInfo is now the SentiUI module SentiUI_AccountInfo: same window, same data (SentiAccountInfoDB carries over), registered under SentiUI > AccountInfo with an enable switch.
- Everything stays: dashboard, characters, search, per-character view, statistics, lockouts, currency/reputation, recipes, sync (export/import strings) and settings - plus item tooltips showing who owns what.
- The own minimap button is gone - SentiUI's minimap button and the new panel bar plugin cover it. Escape closes the window via S.EscClosable instead of UISpecialFrames.
- A disabled module is fully inert now: scanning, events and tooltip hooks only start when the module is enabled.
