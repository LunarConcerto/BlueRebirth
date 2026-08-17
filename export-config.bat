@echo off
setlocal

echo ============================================================
echo   Blue Oath config - one-click EXPORT to Excel
echo   Dumps every config_*.db (decrypted) into:
echo     %~dp0excel
echo   Usage: export-config.bat [jp^|cn]   (default: jp)
echo ============================================================
echo.

set REGION=%~1
if "%REGION%"=="" set REGION=jp

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\config-excel.ps1" -Action export -Region %REGION%

echo.
echo [export-config] finished. See %~dp0excel
pause
