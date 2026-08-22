param(
  [ValidateSet('jp','cn')][string]$Region = 'jp',
  [switch]$Redirect,
  [ValidateRange(0,65535)][int]$Port = 0,
  [ValidateRange(0,65535)][int]$HttpPort = 0,
  [string]$TrustCertificate = '',
  [switch]$AllowUntrusted,
  [switch]$BypassSdk,
  [string]$GameArguments = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$baseline = Get-Content -LiteralPath (Join-Path $root 'baseline.json') -Raw | ConvertFrom-Json
$client = if ($Region -eq 'jp') { Join-Path $root 'blueoath\blueoath' } else { (Get-ChildItem -LiteralPath $root -Directory | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory -Filter clsy -ErrorAction SilentlyContinue } | Select-Object -First 1).FullName }
$exe = Join-Path $client $(if ($Region -eq 'jp') { 'blueoath.exe' } else { 'clsy.exe' })
$native = Join-Path $root 'native\bin-x86'
$injector = Join-Path $native 'BlueOath.Injector.exe'
$payload = Join-Path $native 'BlueOath.Payload.dll'
if (-not (Test-Path -LiteralPath $injector)) { & (Join-Path $PSScriptRoot 'build-native.ps1') }
Copy-Item -LiteralPath (Join-Path $root 'native\bootstrap.ini') -Destination (Join-Path $native 'bootstrap.ini') -Force
$config = Join-Path $native 'bootstrap.ini'
$enabled = if ($Redirect) { 1 } else { 0 }
$configLines = @('[redirect]',"enabled=$enabled","port=$Port","http_port=$HttpPort")
$srcConfig = Join-Path $root 'native\bootstrap.ini'
if (Test-Path -LiteralPath $srcConfig) {
  $srcLines = @(Get-Content -LiteralPath $srcConfig -Encoding Unicode)
  $captureBugly = ($srcLines | Where-Object { $_ -match '^\s*capture_bugly\s*=\s*(\d+)' } | ForEach-Object { $Matches[1] } | Select-Object -First 1)
  $capturePort = ($srcLines | Where-Object { $_ -match '^\s*capture_port\s*=\s*(\d+)' } | ForEach-Object { $Matches[1] } | Select-Object -First 1)
  if ($captureBugly) { $configLines += "capture_bugly=$captureBugly" }
  if ($capturePort) { $configLines += "capture_port=$capturePort" }
}
if ($TrustCertificate) {
  $resolvedTrust = (Resolve-Path -LiteralPath $TrustCertificate).Path
  $configLines += @('[trust]',"certificate=$resolvedTrust")
}
if ($AllowUntrusted) {
  if (-not $TrustCertificate) { $configLines += '[trust]' }
  $configLines += 'allow_untrusted=1'
}
if ($BypassSdk) {
  $configLines += @('[sdk]', 'bypass=1')
}
$configLines += @('[debug]', 'diagnostics=1')
Set-Content -LiteralPath $config -Encoding Unicode -Value $configLines
$entry = $baseline | Where-Object region -eq $Region
$gameHash = ($entry.files.PSObject.Properties | Where-Object Name -like '*GameAssembly.dll').Value
$injectorArgs = @("--exe=$exe", "--payload=$payload", "--game-hash=$gameHash")
if ($GameArguments) { $injectorArgs += "--args=$GameArguments" }
& $injector @injectorArgs
exit $LASTEXITCODE
