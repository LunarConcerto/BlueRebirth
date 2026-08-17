@echo off
setlocal

echo ============================================================
echo   Blue Oath config - generate C# classes (schema only)
echo   Parses the JSON structure of every config_*.db and emits
echo   one strongly-typed C# class per table into:
echo     %~dp0src\BlueOath.Server\configs
echo   Usage: generate-config-cs.bat [jp^|cn]   (default: jp)
echo ============================================================
echo.

set REGION=%~1
if "%REGION%"=="" set REGION=jp

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\config-excel.ps1" -Action cs -Region %REGION%

echo.
echo [generate-config-cs] finished. See %~dp0src\BlueOath.Server\configs
pause
