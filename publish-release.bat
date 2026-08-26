@echo off
setlocal EnableExtensions
echo ============================================================
echo   Blue Oath - Release Publisher
echo ============================================================
echo.

set "ROOT=%~dp0"
set "OUTPUT_DIR=%ROOT%release\BlueOath-Release"
if not "%~1"=="" set "OUTPUT_DIR=%~1"
set "LOG=%OUTPUT_DIR%\build.log"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%" >nul 2>&1

call :log "Build started"
call :log "ROOT=%ROOT%"
call :log "OUTPUT_DIR=%OUTPUT_DIR%"

echo [1/3] Restoring and building .NET projects...
dotnet restore "%ROOT%BlueOath.Local.sln"
if %ERRORLEVEL% neq 0 (
    call :fail "dotnet restore failed" 1
    exit /b 1
)
dotnet build "%ROOT%BlueOath.Local.sln" -c Release --no-restore
if %ERRORLEVEL% neq 0 (
    call :fail "dotnet build failed" 1
    exit /b 1
)

echo.
echo [2/3] Running publisher...
dotnet run --project "%ROOT%src\BlueOath.Publisher\BlueOath.Publisher.csproj" --no-build -- --output="%OUTPUT_DIR%"
if %ERRORLEVEL% neq 0 (
    call :fail "publisher failed" 1
    exit /b 1
)

echo.
echo [3/3] Validating auto-update release package...
if not exist "%OUTPUT_DIR%\launcher-settings.json" (call :fail "launcher-settings.json missing" 2 & exit /b 2)
if not exist "%OUTPUT_DIR%\BlueOath.Launcher.Wpf.exe" (call :fail "launcher executable missing" 2 & exit /b 2)
if not exist "%OUTPUT_DIR%\*.bat" (call :fail "start script missing" 2 & exit /b 2)

set "UPDATE_URL=https://gitee.com/asa233/blue-rebirth/raw/master/launcher-update-release.json"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='%OUTPUT_DIR%\launcher-settings.json'; $s=Get-Content -Raw -LiteralPath $p | ConvertFrom-Json; if (-not $s.PSObject.Properties['updateManifestUrl']) { $s | Add-Member -NotePropertyName updateManifestUrl -NotePropertyValue '%UPDATE_URL%' }; if (-not $s.PSObject.Properties['autoUpdateEnabled']) { $s | Add-Member -NotePropertyName autoUpdateEnabled -NotePropertyValue $true }; $s | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $p -Encoding UTF8"
if %ERRORLEVEL% neq 0 (call :fail "auto-update settings update failed" 3 & exit /b 3)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=Get-Content -Raw -LiteralPath '%OUTPUT_DIR%\launcher-settings.json' | ConvertFrom-Json; if ([string]::IsNullOrWhiteSpace($s.updateManifestUrl) -or $s.autoUpdateEnabled -ne $true) { exit 1 }"
if %ERRORLEVEL% neq 0 (call :fail "auto-update settings validation failed" 3 & exit /b 3)

call :log "Build completed successfully"
echo.
echo Done. Output is in %OUTPUT_DIR%.
echo Build log: %LOG%
pause
exit /b 0

:log
echo [%date% %time%] %~1>>"%LOG%"
exit /b 0

:fail
call :log "ERROR: %~1"
echo ERROR: %~1
echo See build log: %LOG%
exit /b %~2
