param(
  [switch]$DebugHooks,
  [ValidateSet('Debug', 'Release')]
  [string]$Configuration = 'Release'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$vcvars = $null

# Prefer VS2019 Build Tools: its MSVC 14.29 STL ABI matches the game's bundled
# MSVCP140.dll. VS2022 (14.4x) builds crash at startup in MSVCP140 and also tend
# to fail cmake/NMake linking with 'Unknown system error -1' on this machine.
$vs2019 = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars32.bat'
if (Test-Path -LiteralPath $vs2019) { $vcvars = $vs2019 }

if (-not $vcvars) {
  $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
  if (Test-Path -LiteralPath $vswhere) {
    $vsInstallRaw = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1
    $vsInstall = if ($vsInstallRaw) { $vsInstallRaw.Trim() } else { $null }
    if ($vsInstall) {
      $candidate = Join-Path $vsInstall 'VC\Auxiliary\Build\vcvars32.bat'
      if (Test-Path -LiteralPath $candidate) { $vcvars = $candidate }
    }
  }
}

if (-not $vcvars) {
  throw 'Visual Studio C++ Build Tools not found. Install the VC.Tools.x86.x64 workload.'
}

# A CMake cache stores the absolute path of cl.exe. Keep caches separated by
# MSVC toolset so switching/updating Visual Studio cannot silently reuse a
# compiler from a different installation.
$vcRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $vcvars))
$toolsetVersionFile = Join-Path $vcRoot 'Auxiliary\Build\Microsoft.VCToolsVersion.default.txt'
$toolsetVersion = if (Test-Path -LiteralPath $toolsetVersionFile) {
  (Get-Content -LiteralPath $toolsetVersionFile -Raw).Trim()
} else {
  'unknown'
}
$toolsetToken = $toolsetVersion -replace '[^0-9A-Za-z.-]', '_'
Write-Host "Using MSVC environment: $vcvars"
Write-Host "Using MSVC toolset: $toolsetVersion"

$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake) {
  $vsCmake = Join-Path (Split-Path (Split-Path $vcvars -Parent) -Parent) 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
  if (Test-Path -LiteralPath $vsCmake) { $cmake = $vsCmake }
}
if (-not $cmake) { throw 'CMake not found.' }

# Keep NMake/link.exe away from the Chinese user TEMP path. This also makes
# local builds reproducible and avoids LNK1201 caused by non-ASCII temp paths.
$build = Join-Path $root "native\build-nmake-x86-$toolsetToken"
$output = Join-Path $root 'native\bin-x86'
New-Item -ItemType Directory -Force -Path $build | Out-Null
New-Item -ItemType Directory -Force -Path $output | Out-Null
$hooksFlag = if ($DebugHooks) { '-DBLUEOATH_HOOKS_DEBUG=ON' } else { '-DBLUEOATH_HOOKS_DEBUG=OFF' }

# vcvars32.bat already configures an x86 environment; no 'x86' arg needed.
$command = 'call "' + $vcvars + '" && "' + $cmake + '" -S "' + (Join-Path $root 'native') + '" -B "' + $build + '" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=' + $Configuration + ' ' + $hooksFlag + ' && "' + $cmake + '" --build "' + $build + '"'
cmd.exe /d /s /c $command
if ($LASTEXITCODE -ne 0) { throw "Native build failed: $LASTEXITCODE" }

function Assert-SelfContainedMsvcBinary {
  param([Parameter(Mandatory)][string]$BinaryPath)

  # The game ships old MSVC DLLs beside its executable. Windows resolves those
  # before the system copies, so any dynamic CRT import can make a CI-built
  # payload crash in DllMain before it signals the injector's ready event.
  $inspectCommand = 'call "' + $vcvars + '" x86 >nul && dumpbin /nologo /dependents "' + $BinaryPath + '"'
  $dependencyOutput = @(& cmd.exe /d /s /c $inspectCommand 2>&1)
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to inspect native dependencies for $BinaryPath"
  }

  $dependencyText = $dependencyOutput -join [Environment]::NewLine
  $forbiddenRuntime = '(?i)\b(?:(?:MSVCP|VCRUNTIME)[^\s]*|UCRTBASE|api-ms-win-crt-[^\s]*)\.dll\b'
  if ($dependencyText -match $forbiddenRuntime) {
    throw "Native binary imports a dynamic MSVC/UCRT runtime ($($Matches[0])): $BinaryPath"
  }

  $imports = @($dependencyOutput |
    Where-Object { $_ -match '^\s+[A-Za-z0-9_.-]+\.dll\s*$' } |
    ForEach-Object { $_.Trim() })
  Write-Host "Verified static MSVC runtime: $(Split-Path -Leaf $BinaryPath) [$($imports -join ', ')]"
}

$injectorBinary = Join-Path $build 'BlueOath.Injector.exe'
$payloadBinary = Join-Path $build 'BlueOath.Payload.dll'
Assert-SelfContainedMsvcBinary -BinaryPath $injectorBinary
Assert-SelfContainedMsvcBinary -BinaryPath $payloadBinary
Copy-Item -LiteralPath $injectorBinary -Destination $output -Force
Copy-Item -LiteralPath $payloadBinary -Destination $output -Force
