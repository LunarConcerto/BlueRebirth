@echo off
setlocal
set MODE=%~1
if "%MODE%"=="" set MODE=bypass

echo ============================================================
echo   Blue Oath JP offline - one-click launcher
echo   Mode: %MODE%  (redirect / bypass)
echo   Press Ctrl+C to stop (auto cleanup)
echo   Log: native\bin-x86\BlueOath.Payload.log
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\debug-game.ps1" -Mode %MODE% -SkipBuild

echo.
echo [run-game] stopped. Log: native\bin-x86\BlueOath.Payload.log
pause
