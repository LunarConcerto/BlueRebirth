param(
  [switch]$DebugHooks,
  [ValidateSet('Debug', 'Release')]
  [string]$Configuration = 'Release'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vcvars = $null

if (Test-Path -LiteralPath $vswhere) {
  $vsInstallRaw = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1
  $vsInstall = if ($vsInstallRaw) { $vsInstallRaw.Trim() } else { $null }
  if ($vsInstall) {
    $candidate = Join-Path $vsInstall 'VC\Auxiliary\Build\vcvarsall.bat'
    if (Test-Path -LiteralPath $candidate) { $vcvars = $candidate }
  }
}

# VS18 Insiders may not be registered in the stable vswhere product list.
if (-not $vcvars) {
  $insidersVcvars = 'C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvarsall.bat'
  if (Test-Path -LiteralPath $insidersVcvars) { $vcvars = $insidersVcvars }
}

# Keep compatibility with older self-hosted machines that only have VS2019.
if (-not $vcvars) {
  $legacy = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat'
  if (Test-Path -LiteralPath $legacy) { $vcvars = $legacy }
}

if (-not $vcvars) {
  throw 'Visual Studio C++ Build Tools not found. Install the VC.Tools.x86.x64 workload.'
}

$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake) {
  $insidersCmake = 'C:\Program Files\Microsoft Visual Studio\18\Insiders\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
  if (Test-Path -LiteralPath $insidersCmake) { $cmake = $insidersCmake }
}
if (-not $cmake) { throw 'CMake not found. Install the CMake tools for Windows workload.' }

# Keep NMake/link.exe away from the Chinese user TEMP path. This also makes
# local builds reproducible and avoids LNK1201 caused by non-ASCII temp paths.
$build = Join-Path $root 'native\build-nmake-x86'
$output = Join-Path $root 'native\bin-x86'
New-Item -ItemType Directory -Force -Path $build | Out-Null
New-Item -ItemType Directory -Force -Path $output | Out-Null
$hooksFlag = if ($DebugHooks) { '-DBLUEOATH_HOOKS_DEBUG=ON' } else { '-DBLUEOATH_HOOKS_DEBUG=OFF' }
$command = 'call "' + $vcvars + '" x86 && "' + $cmake + '" -S "' + (Join-Path $root 'native') + '" -B "' + $build + '" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=' + $Configuration + ' ' + $hooksFlag + ' && "' + $cmake + '" --build "' + $build + '"'
cmd.exe /d /s /c $command
if ($LASTEXITCODE -ne 0) { throw "Native build failed: $LASTEXITCODE" }
Copy-Item -LiteralPath (Join-Path $build 'BlueOath.Injector.exe') -Destination $output -Force
Copy-Item -LiteralPath (Join-Path $build 'BlueOath.Payload.dll') -Destination $output -Force
