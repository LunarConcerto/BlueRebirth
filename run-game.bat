@echo off
setlocal

echo ============================================================
echo   Blue Oath JP offline - one-click launcher
echo   Press Ctrl+C to stop (auto cleanup)
echo   Log: native\bin-x86\BlueOath.Payload.log
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\debug-game.ps1" -SkipBuild

echo.
echo [run-game] stopped. Log: native\bin-x86\BlueOath.Payload.log
pause
