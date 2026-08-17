@echo off
setlocal

echo ============================================================
echo   Blue Oath config - one-click IMPORT back from Excel
echo   Reads %~dp0excel and writes back into the config DBs.
echo   Original DBs are backed up automatically before overwrite.
echo   Usage: import-config.bat [jp^|cn]   (default: jp)
echo ============================================================
echo.

set REGION=%~1
if "%REGION%"=="" set REGION=jp

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\config-excel.ps1" -Action import -Region %REGION%

echo.
echo [import-config] finished.
pause
