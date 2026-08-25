@echo off
setlocal
echo ============================================================
echo   Blue Oath - Release Publisher
echo ============================================================
echo.

:: Optional: set explicit output directory.
:: This guarantees launcher-settings.json is generated to a known location.
:: Usage: publish-release.bat [输出目录]
set ROOT=%~dp0
set OUTPUT_DIR=%ROOT%release
if not "%~1"=="" set OUTPUT_DIR=%~1

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [1/3] Restoring and building .NET projects...
dotnet restore "%ROOT%BlueOath.Local.sln"
if %ERRORLEVEL% neq 0 (
    echo ERROR: dotnet restore failed
    exit /b 1
)
dotnet build "%ROOT%BlueOath.Local.sln" -c Release --no-restore
if %ERRORLEVEL% neq 0 (
    echo ERROR: dotnet build failed
    exit /b 1
)

echo.
echo [2/3] Running publisher...
dotnet run --project "%ROOT%src\BlueOath.Publisher\BlueOath.Publisher.csproj" --no-build -- --output "%OUTPUT_DIR%\BlueOath-Release"
if %ERRORLEVEL% neq 0 (
    echo ERROR: publisher failed
    exit /b 1
)

if not exist "%OUTPUT_DIR%\BlueOath-Release\launcher-settings.json" (
    echo ERROR: launcher-settings.json is missing in publish output, please check launch settings copy rules.
    exit /b 1
)

if not exist "%OUTPUT_DIR%\BlueOath-Release\BlueOath.Launcher.Wpf.exe" (
    echo ERROR: launcher executable is missing in publish output, release package invalid.
    exit /b 1
)

echo.
echo [3/3] Done. Output is in %OUTPUT_DIR%\BlueOath-Release.
pause
