# config-excel.ps1
#
# One-click SQLite config <-> Excel conversion.
#   export  : dump all config_*.db under the region into <repo>\excel
#   import  : write the .xlsx files under <repo>\excel back into the config DBs
#             (original .db files are backed up before overwrite)
#   backup  : full snapshot of the region's original config directory
#   selftest: in-memory round-trip self check
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\config-excel.ps1 -Action export -Region jp
param(
  [ValidateSet('export', 'import', 'backup', 'selftest', 'cs')][string]$Action = 'export',
  [ValidateSet('jp', 'cn')][string]$Region = 'jp',
  [string]$InputPath = '',
  [string]$OutputPath = ''
)
$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $PSScriptRoot
$excel = Join-Path $root 'excel'
$proj  = Join-Path $root 'src\BlueOath.Tools\BlueOath.Tools.csproj'

function Invoke-Tool([string[]]$ToolArgs) {
  & dotnet run --project $proj -- @ToolArgs
  if ($LASTEXITCODE -ne 0) { throw "BlueOath.Tools exited with code $LASTEXITCODE" }
}

switch ($Action) {
  'export' {
    New-Item -ItemType Directory -Path $excel -Force | Out-Null
    Write-Host "[export] region=$Region -> $excel" -ForegroundColor Cyan
    Invoke-Tool @('--config-excel', "--region=$Region", "--output=$excel")
    Write-Host "[export] done. see $excel" -ForegroundColor Green
  }
  'import' {
    $inputPath = if ($InputPath) { $InputPath } else { $excel }
    if (-not (Test-Path -LiteralPath $inputPath)) {
      throw "Export folder not found: $inputPath. Run export first (export-config.bat)."
    }
    Write-Host "[import] region=$Region <- $inputPath (original DBs backed up automatically)" -ForegroundColor Cyan
    $importArgs = @('--config-excel-import', "--region=$Region", "--input=$inputPath")
    if ($OutputPath) { $importArgs += "--output=$OutputPath" }
    Invoke-Tool $importArgs
    Write-Host '[import] done.' -ForegroundColor Green
  }
  'backup' {
    Write-Host "[backup] region=$Region (full snapshot)" -ForegroundColor Cyan
    Invoke-Tool @('--config-excel-backup', "--region=$Region")
    Write-Host '[backup] done.' -ForegroundColor Green
  }
  'selftest' {
    Invoke-Tool @('--config-excel-self-test')
  }
  'cs' {
    $csOut = if ($OutputPath) { $OutputPath } else { Join-Path $root 'src\BlueOath.Server\configs' }
    New-Item -ItemType Directory -Path $csOut -Force | Out-Null
    Write-Host "[gen-cs] region=$Region -> $csOut" -ForegroundColor Cyan
    Invoke-Tool @('--config-cs', "--region=$Region", "--output=$csOut")
    Write-Host "[gen-cs] done. see $csOut" -ForegroundColor Green
  }
}
