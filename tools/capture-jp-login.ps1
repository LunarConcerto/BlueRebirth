param(
  [ValidateRange(5, 600)][int]$CaptureSeconds = 45,
  [switch]$AllowUntrusted,
  [switch]$UseProcessLocalRoot,
  [switch]$BypassSdk
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runRoot = Join-Path $root "runtime\captures\jp-live-$stamp"
$dataRoot = Join-Path $root 'runtime\jp'
$tlsRoot = Join-Path $runRoot 'tls'
$captureRoot = Join-Path $runRoot 'traffic'
$serverOut = Join-Path $runRoot 'server.stdout.log'
$serverErr = Join-Path $runRoot 'server.stderr.log'
$proxyErr = Join-Path $runRoot 'tls-proxy.stderr.log'
$injectorOut = Join-Path $runRoot 'injector.log'
$unityLog = Join-Path $runRoot 'unity-player.log'
$payloadRunLog = Join-Path $runRoot 'payload.log'
$bootstrap = Join-Path $root 'native\bin-x86\bootstrap.ini'
$bootstrapBackup = Join-Path $runRoot 'bootstrap.ini.before'
$payloadLog = Join-Path $root 'native\bin-x86\BlueOath.Payload.log'
$payloadOffset = if (Test-Path -LiteralPath $payloadLog) {
  (Get-Item -LiteralPath $payloadLog).Length
} else {
  0
}

New-Item -ItemType Directory -Path $captureRoot -Force | Out-Null
New-Item -ItemType Directory -Path $tlsRoot -Force | Out-Null
if (Test-Path -LiteralPath $bootstrap) {
  Copy-Item -LiteralPath $bootstrap -Destination $bootstrapBackup -Force
}

$server = $null
$proxy = $null
$gamePid = $null
try {
  $serverDll = Join-Path $root 'src\BlueOath.Server\bin\Debug\net8.0\BlueOath.Server.dll'
  if (-not (Test-Path -LiteralPath $serverDll)) {
    throw "Server assembly is missing; build the solution first: $serverDll"
  }
  $materialLine = & dotnet $serverDll '--tls-material-only' "--tls-output=$tlsRoot" 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { throw "TLS material generation failed: $materialLine" }
  $material = $materialLine | ConvertFrom-Json

  $serverArgs = @($serverDll, '--port=0', '--region=jp', "--data=$dataRoot", "--capture=$captureRoot", '--kcp-game-login-port=7201')
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
  if (-not $readyTask.Wait([TimeSpan]::FromSeconds(15))) {
    throw 'Local TLS server did not report ready within 15 seconds.'
  }
  $readyLine = $readyTask.Result
  if (-not $readyLine) {
    $startupError = $server.StandardError.ReadToEnd()
    throw "Local TLS server exited before ready: $startupError"
  }
  Set-Content -LiteralPath $serverOut -Encoding UTF8 -Value $readyLine
  $ready = $readyLine | ConvertFrom-Json
  if (-not $ready.ready) {
    throw "Unexpected server ready response: $readyLine"
  }

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
  if (-not $proxyReadyTask.Wait([TimeSpan]::FromSeconds(10))) {
    throw 'OpenSSL TLS proxy did not report ready within 10 seconds.'
  }
  $proxyReadyLine = $proxyReadyTask.Result
  if (-not $proxyReadyLine) {
    throw "OpenSSL TLS proxy exited before ready: $($proxy.StandardError.ReadToEnd())"
  }
  $proxyReady = $proxyReadyLine | ConvertFrom-Json

  $trustCertificate = [IO.Path]::GetFullPath([string]$material.rootCertificate)
  if (-not (Test-Path -LiteralPath $trustCertificate)) {
    throw "Generated root certificate was not found: $trustCertificate"
  }

  $injectArgs = @(
    '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'inject-game.ps1'),
    '-Region', 'jp', '-Redirect', '-Port', [string]$proxyReady.port,
    '-HttpPort', [string]$ready.port,
    '-GameArguments', ('-logFile "' + $unityLog + '"')
  )
  if ($UseProcessLocalRoot) { $injectArgs += @('-TrustCertificate', $trustCertificate) }
  if ($AllowUntrusted) { $injectArgs += '-AllowUntrusted' }
  if ($BypassSdk) { $injectArgs += '-BypassSdk' }
  $injectOutput = & powershell @injectArgs 2>&1 | Out-String
  Set-Content -LiteralPath $injectorOut -Encoding UTF8 -Value $injectOutput
  if ($LASTEXITCODE -ne 0) {
    throw "Injector failed with exit code $LASTEXITCODE. See $injectorOut"
  }
  if ($injectOutput -match 'Injected PID\s+(\d+)') {
    $gamePid = [int]$Matches[1]
  } else {
    throw "Injector succeeded but did not report the game PID. See $injectorOut"
  }

  Write-Host "JP client injected (PID $gamePid). Capturing for $CaptureSeconds seconds..."
  $deadline = [DateTime]::UtcNow.AddSeconds($CaptureSeconds)
  while ([DateTime]::UtcNow -lt $deadline) {
    if ($server.HasExited) { throw "Local TLS server exited unexpectedly with code $($server.ExitCode)." }
    if ($proxy.HasExited) { throw "OpenSSL TLS proxy exited unexpectedly with code $($proxy.ExitCode)." }
    $game = Get-Process -Id $gamePid -ErrorAction SilentlyContinue
    if (-not $game) { break }
    Start-Sleep -Milliseconds 500
  }
}
finally {
  if ($gamePid) {
    $game = Get-Process -Id $gamePid -ErrorAction SilentlyContinue
    if ($game) { Stop-Process -Id $gamePid -Force -ErrorAction SilentlyContinue }
  }
  if ($server -and -not $server.HasExited) {
    $server.Kill()
    $server.WaitForExit(5000) | Out-Null
  }
  if ($proxy -and -not $proxy.HasExited) {
    $proxy.Kill()
    $proxy.WaitForExit(5000) | Out-Null
  }
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
  if (Test-Path -LiteralPath $bootstrapBackup) {
    Copy-Item -LiteralPath $bootstrapBackup -Destination $bootstrap -Force
  }
  if (Test-Path -LiteralPath $payloadLog) {
    $stream = [IO.File]::Open($payloadLog, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
      if ($payloadOffset -le $stream.Length) {
        [void]$stream.Seek($payloadOffset, [IO.SeekOrigin]::Begin)
        $reader = [IO.StreamReader]::new($stream)
        try { Set-Content -LiteralPath $payloadRunLog -Encoding UTF8 -Value $reader.ReadToEnd() }
        finally { $reader.Dispose() }
      }
    } finally { $stream.Dispose() }
  }
}

$captures = @(Get-ChildItem -LiteralPath $captureRoot -Filter '*.json' -ErrorAction SilentlyContinue)
Write-Host "Capture complete: $runRoot"
Write-Host "Decrypted request captures: $($captures.Count)"
foreach ($capture in $captures) {
  $metadata = Get-Content -LiteralPath $capture.FullName -Raw | ConvertFrom-Json
  Write-Host "  $($metadata.kind): $($metadata.detail) ($($metadata.byteCount) bytes)"
}
