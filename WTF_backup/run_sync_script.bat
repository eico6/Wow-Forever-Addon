@echo off
setlocal
powershell.exe -ExecutionPolicy Bypass -File "%~dp0sync_script.ps1"
if errorlevel 1 goto failed

git -C "%~dp0." add -A -- WTF
if errorlevel 1 goto failed
git -C "%~dp0." diff --cached --quiet -- WTF
if errorlevel 2 goto failed
if not errorlevel 1 goto push

git -C "%~dp0." commit --only -m "Sync WTF folder with new settings" -- WTF
if errorlevel 1 goto failed

:push
git -C "%~dp0." push
if errorlevel 1 goto failed
echo WTF backup is up to date.
pause
exit /b 0

:failed
set "result=%errorlevel%"
echo WTF backup failed. See the error above.
pause
exit /b %result%
