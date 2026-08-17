# start-client.ps1
#
# Starts the OFFLINE CLIENT environment (TLS loopback proxy + game injection)
# against a LOCAL SERVER that is ALREADY RUNNING - typically the BlueOath.Server
# started under Rider's debugger so you can set breakpoints in Program.cs.
#
# The server is NOT started by this script. Start it in Rider with:
#   Program arguments:
#     --port=7080 --game-login-port=7201 --region=jp --data=E:\逆向工程\苍蓝誓约项目\runtime\jp
#
#   --port must match this script's -ServerPort (default 7080).
#   --game-login-port is configured only in the server (default 7201, returned by /phone/serverlist/).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start-client.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\start-client.ps1 -ServerPort 7080 -SkipBuild
param(
  [ValidateRange(1, 65535)][int]$ServerPort = 7080,   # must match the server's --port (Rider)
  [ValidateRange(0, 65535)][int]$ProxyPort  = 0,     # 0 = auto (recommended, avoids port conflicts)
  [ValidateSet('jp', 'cn')][string]$Region = 'jp',
  [switch]$SkipBuild,
  [switch]$KeepLog
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# ---------------------------------------------------------------- build ----
if (-not $SkipBuild) {
  Write-Host '[1/4] building native payload...' -ForegroundColor Cyan
  & (Join-Path $PSScriptRoot 'build-native.ps1')
} else {
  Write-Host '[1/4] build skipped' -ForegroundColor DarkGray
}

# ------------------------------------------------------------ run paths ----
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$runRoot   = Join-Path $root "runtime\debug\$stamp"
$tlsRoot   = Join-Path $root 'runtime\tls'
$proxyErr  = Join-Path $runRoot 'proxy.stderr.log'
$payloadLog = Join-Path $root 'native\bin-x86\BlueOath.Payload.log'
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
New-Item -ItemType Directory -Path $tlsRoot -Force | Out-Null
if (-not $KeepLog -and (Test-Path -LiteralPath $payloadLog)) { Remove-Item -LiteralPath $payloadLog -Force }

$serverDll = Join-Path $root 'src\BlueOath.Server\bin\Debug\net8.0\BlueOath.Server.dll'
if (-not (Test-Path -LiteralPath $serverDll)) {
  throw "Server assembly missing: $serverDll. Build the server project in Rider first."
}

# -------------------------------------------------- TLS material (proxy) ----
Write-Host '[2/4] preparing TLS material...' -ForegroundColor Cyan
$materialLine = & dotnet $serverDll '--tls-material-only' "--tls-output=$tlsRoot" 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "TLS material generation failed: $materialLine" }
$material = $materialLine | ConvertFrom-Json

# ------------------------------------------------------- start TLS proxy ----
Write-Host "[3/4] starting TLS proxy (tls auto -> server $ServerPort)..." -ForegroundColor Cyan
$proxyStart = [System.Diagnostics.ProcessStartInfo]::new('python')
$proxyStart.UseShellExecute = $false
$proxyStart.CreateNoWindow = $true
$proxyStart.RedirectStandardOutput = $true
$proxyStart.RedirectStandardError = $true
$proxyArgs = @(
  (Join-Path $PSScriptRoot 'tls-loopback-proxy.py'),
  '--port', [string]$ProxyPort,
  '--backend-port', [string]$ServerPort,
  '--cert', [string]$material.leafPem,
  '--key', [string]$material.leafKeyPem
)
$proxyStart.Arguments = ($proxyArgs | ForEach-Object {
  if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
}) -join ' '
$proxy = [System.Diagnostics.Process]::Start($proxyStart)
$proxyReadyTask = $proxy.StandardOutput.ReadLineAsync()
if (-not $proxyReadyTask.Wait([TimeSpan]::FromSeconds(10))) {
  throw "Proxy did not report ready within 10s. stderr: $($proxy.StandardError.ReadToEnd())"
}
$readyLine = $proxyReadyTask.Result
if ([string]::IsNullOrEmpty($readyLine)) {
  throw "Proxy exited before reporting ready. stderr: $($proxy.StandardError.ReadToEnd())"
}
$proxyReady = $readyLine | ConvertFrom-Json
if (-not $proxyReady.ready) { throw "Unexpected proxy ready response: $readyLine" }

$gamePid = $null
try {
  # ------------------------------------------------------- inject game ----
  Write-Host "[4/4] injecting game (redirect to tls $($proxyReady.port))..." -ForegroundColor Cyan
  $injectArgs = @(
    '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'inject-game.ps1'),
    '-Region', $Region, '-Redirect',
    '-Port', [string]$proxyReady.port,
    '-HttpPort', [string]$ServerPort,
    '-AllowUntrusted'
  )
  $injectOutput = & powershell @injectArgs 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { throw "Injector failed: $injectOutput" }
  if ($injectOutput -match 'Injected PID\s+(\d+)') {
    $gamePid = [int]$Matches[1]
  }

  Write-Host ''
  Write-Host 'Client injected. The game will now talk to the server running in Rider.' -ForegroundColor Green
  Write-Host ('  game PID      : ' + $(if ($gamePid) { $gamePid } else { '?' })) -ForegroundColor Green
  Write-Host ("  server http   : $ServerPort (Rider --port)") -ForegroundColor Green
  Write-Host ("  proxy tls     : $($proxyReady.port)") -ForegroundColor Green
  Write-Host ("  payload log   : $payloadLog") -ForegroundColor Green
  Write-Host ''
  Write-Host 'Watching payload log live. Press Ctrl+C to stop the proxy and clean up.' -ForegroundColor Yellow
  Write-Host '===================================================='

  if (-not (Test-Path -LiteralPath $payloadLog)) { New-Item -ItemType File -Path $payloadLog -Force | Out-Null }
  try {
    Get-Content -LiteralPath $payloadLog -Wait -Tail 0 | ForEach-Object { Write-Host $_ }
  } catch {
    # Ctrl+C or the file was removed; fall through to cleanup.
  }
}
finally {
  Write-Host ''
  Write-Host 'cleaning up...' -ForegroundColor Yellow
  if ($gamePid) {
    $game = Get-Process -Id $gamePid -ErrorAction SilentlyContinue
    if ($game) { Stop-Process -Id $gamePid -Force -ErrorAction SilentlyContinue }
  }
  if ($proxy -and -not $proxy.HasExited) { $proxy.Kill(); $proxy.WaitForExit(5000) | Out-Null }
  if ($proxy) {
    $proxyErrors = $proxy.StandardError.ReadToEnd()
    if ($proxyErrors) { Set-Content -LiteralPath $proxyErr -Encoding UTF8 -Value $proxyErrors }
    $proxy.Dispose()
  }
  Write-Host ('done. proxy stderr: ' + $proxyErr) -ForegroundColor Green
}
