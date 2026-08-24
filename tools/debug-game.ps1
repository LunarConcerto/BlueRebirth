param(
  [ValidateSet('redirect')][string]$Mode = 'redirect',
  [switch]$SkipBuild,
  [switch]$KeepLog
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# ---------------------------------------------------------------- build ----
if (-not $SkipBuild) {
  Write-Host '[1/5] building native payload (debug hooks)...' -ForegroundColor Cyan
  & (Join-Path $PSScriptRoot 'build-native.ps1') -DebugHooks
  Write-Host '[1/5] building local server...' -ForegroundColor Cyan
  & dotnet build (Join-Path $root 'src\BlueOath.Server\BlueOath.Server.csproj') -c Debug *> $null
  if ($LASTEXITCODE -ne 0) { throw "Build failed: $LASTEXITCODE" }
} else {
  Write-Host '[1/5] build skipped' -ForegroundColor DarkGray
}

# ------------------------------------------------------------ run paths ----
$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$runRoot   = Join-Path $root "runtime\debug\$stamp"
$dataRoot  = Join-Path $root 'runtime\jp'
$tlsRoot   = Join-Path $runRoot 'tls'
$traffic   = Join-Path $runRoot 'traffic'
$serverOut = Join-Path $runRoot 'server.stdout.log'
$serverErr = Join-Path $runRoot 'server.stderr.log'
$proxyErr  = Join-Path $runRoot 'proxy.stderr.log'
$payloadLog = Join-Path $root 'native\bin-x86\BlueOath.Payload.log'
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
New-Item -ItemType Directory -Path $tlsRoot -Force | Out-Null
if (-not $KeepLog -and (Test-Path -LiteralPath $payloadLog)) { Remove-Item -LiteralPath $payloadLog -Force }

# --------------------------------------- cleanup leftover processes ----
# Kill leftover server/game processes from a previous abnormal exit so they
# don't keep holding port 7201/7080 and block the next startup.
Write-Host '[cleanup] killing leftover server/game processes...' -ForegroundColor Cyan
Get-CimInstance Win32_Process -Filter "Name='dotnet.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -match 'BlueOath\.Server\.dll' } |
  ForEach-Object {
    Write-Host ('  killing leftover server PID ' + $_.ProcessId) -ForegroundColor DarkGray
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
Get-Process -Name 'blueoath', 'clsy' -ErrorAction SilentlyContinue |
  ForEach-Object {
    Write-Host ('  killing leftover game PID ' + $_.Id) -ForegroundColor DarkGray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
  }

$serverDll = Join-Path $root 'src\BlueOath.Server\bin\Debug\net8.0\BlueOath.Server.dll'
if (-not (Test-Path -LiteralPath $serverDll)) { throw "Server assembly missing: $serverDll" }

$server = $null
$proxy  = $null
$gamePid = $null
try {
  # ------------------------------------------------------- start server ----
  Write-Host '[2/5] starting local server...' -ForegroundColor Cyan
  $materialLine = & dotnet $serverDll '--tls-material-only' "--tls-output=$tlsRoot" 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { throw "TLS material generation failed: $materialLine" }
  $material = $materialLine | ConvertFrom-Json

  $serverArgs = @($serverDll,  '--port=0', '--region=jp', "--data=$dataRoot", "--capture=$traffic", '--game-login-port=7201', '--gm-port=9780')
  $serverStart = [System.Diagnostics.ProcessStartInfo]::new('dotnet')
  $serverStart.UseShellExecute = $false
  $serverStart.CreateNoWindow = $true
  $serverStart.RedirectStandardOutput = $true
  $serverStart.RedirectStandardError = $true
  $serverStart.Arguments = ($serverArgs | ForEach-Object {
    if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
  }) -join ' '
  $server = [System.Diagnostics.Process]::Start($serverStart)
  $readyTask = $server.StandardOutput.ReadLineAsync()
  if (-not $readyTask.Wait([TimeSpan]::FromSeconds(15))) { throw 'Server did not report ready within 15s.' }
  $ready = ($readyTask.Result | ConvertFrom-Json)
  if (-not $ready.ready) { throw "Unexpected server ready response: $($readyTask.Result)" }

  # ------------------------------------------------------- start proxy ----
  Write-Host '[3/5] starting TLS loopback proxy...' -ForegroundColor Cyan
  $proxyStart = [System.Diagnostics.ProcessStartInfo]::new('python')
  $proxyStart.UseShellExecute = $false
  $proxyStart.CreateNoWindow = $true
  $proxyStart.RedirectStandardOutput = $true
  $proxyStart.RedirectStandardError = $true
  $proxyArgs = @(
    (Join-Path $PSScriptRoot 'tls-loopback-proxy.py'), '--port', '0',
    '--backend-port', [string]$ready.port, '--cert', [string]$material.leafPem,
    '--key', [string]$material.leafKeyPem
  )
  $proxyStart.Arguments = ($proxyArgs | ForEach-Object {
    if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
  }) -join ' '
  $proxy = [System.Diagnostics.Process]::Start($proxyStart)
  $proxyReadyTask = $proxy.StandardOutput.ReadLineAsync()
  if (-not $proxyReadyTask.Wait([TimeSpan]::FromSeconds(10))) { throw 'Proxy did not report ready within 10s.' }
  $proxyReady = ($proxyReadyTask.Result | ConvertFrom-Json)
  if (-not $proxyReady.ready) { throw "Unexpected proxy ready response: $($proxyReadyTask.Result)" }

  # ------------------------------------------------------- inject game ----
  Write-Host '[4/5] injecting game (mode='$Mode')...' -ForegroundColor Cyan
  $injectArgs = @(
    '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'inject-game.ps1'),
    '-Region', 'jp', '-Redirect', '-Port', [string]$proxyReady.port,
    '-HttpPort', [string]$ready.port, '-AllowUntrusted'
  )
  $injectOutput = & powershell @injectArgs 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { throw "Injector failed: $injectOutput" }
  if ($injectOutput -match 'Injected PID\s+(\d+)') {
    $gamePid = [int]$Matches[1]
  } else {
    throw "Injector did not report the game PID: $injectOutput"
  }

  # ------------------------------------------------------- status ---------
  Write-Host ''
  Write-Host ('Game injected (PID ' + $gamePid + '). Mode=' + $Mode + '.') -ForegroundColor Green
  Write-Host ('  server http port : ' + $ready.port) -ForegroundColor Green
  Write-Host ('  proxy tls port   : ' + $proxyReady.port) -ForegroundColor Green
  Write-Host ('  game login port  : 7201') -ForegroundColor Green
  Write-Host ('  GM WebUI         : http://localhost:' + $ready.gmPort) -ForegroundColor Green
  Write-Host ('  payload log (live): ' + $payloadLog) -ForegroundColor Green
  Write-Host ('  run dir (server/proxy logs): ' + $runRoot) -ForegroundColor Green
  Write-Host ''
  Write-Host '[5/5] watching payload log live. Press Ctrl+C to stop and clean up.' -ForegroundColor Yellow
  Write-Host ('====================================================')

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
  if ($server -and -not $server.HasExited) { $server.Kill(); $server.WaitForExit(5000) | Out-Null }
  if ($proxy -and -not $proxy.HasExited) { $proxy.Kill(); $proxy.WaitForExit(5000) | Out-Null }
  if ($proxy) {
    $proxyErrors = $proxy.StandardError.ReadToEnd()
    if ($proxyErrors) { Set-Content -LiteralPath $proxyErr -Encoding UTF8 -Value $proxyErrors }
    $proxy.Dispose()
  }
  if ($server) {
    $remainingOut = $server.StandardOutput.ReadToEnd()
    $remainingErr = $server.StandardError.ReadToEnd()
    if ($remainingOut) { Add-Content -LiteralPath $serverOut -Encoding UTF8 -Value $remainingOut }
    if ($remainingErr) { Set-Content -LiteralPath $serverErr -Encoding UTF8 -Value $remainingErr }
    $server.Dispose()
  }
  Write-Host ('done. logs: ' + $runRoot) -ForegroundColor Green
}
