@echo off
setlocal

echo ============================================================
echo   Blue Oath JP offline - client launcher
echo   Starts the TLS proxy + game against the server running
echo   under Rider's debugger (HTTP port 7080).
echo.
echo   Make sure the server is running in Rider first with:
echo     --port=7080 --game-login-port=7201 --region=jp --client-path=blueoath\blueoath
echo.
echo   Press Ctrl+C to stop (auto cleanup).
echo   Log: native\bin-x86\BlueOath.Payload.log
echo ============================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\start-client.ps1" -SkipBuild

echo.
echo [start-client] stopped.
pause
