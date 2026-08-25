@echo off
setlocal
echo ============================================================
echo   Blue Oath - Release Publisher
echo ============================================================
echo.

set ROOT=%~dp0

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
dotnet run --project "%ROOT%src\BlueOath.Publisher\BlueOath.Publisher.csproj" --no-build
if %ERRORLEVEL% neq 0 (
    echo ERROR: publisher failed
    exit /b 1
)

echo.
echo [3/3] Done. Output is in release\ folder.
pause