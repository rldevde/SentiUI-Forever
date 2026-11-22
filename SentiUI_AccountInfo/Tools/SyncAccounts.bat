@echo off
rem Merges SentiAccountInfoDB across all WoW accounts under WTF\Account.
rem WoW writes SavedVariables on logout - run this after logging out.
py -3 "%~dp0SyncAccounts.py" %*
if errorlevel 1 (
	python "%~dp0SyncAccounts.py" %*
)
pause
