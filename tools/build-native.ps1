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

# Use project-local CMake to avoid the Chinese-user TEMP path causing LNK1201 / link Unknown system error.
$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake) {
  $vsCmake = Join-Path (Split-Path (Split-Path $vcvars -Parent) -Parent) 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
  if (Test-Path -LiteralPath $vsCmake) { $cmake = $vsCmake }
}
if (-not $cmake) { throw 'CMake not found.' }

# Build dir MUST be on an ASCII path (cl/link/rsp fail on paths containing CJK like
# the project root 'E:\逆向工程\苍蓝誓约项目'). $env:TEMP is ASCII here (LUNARC~1 8.3).
$build = Join-Path $env:TEMP 'blueoath-native-x86-nmake'
$output = Join-Path $root 'native\bin-x86'
New-Item -ItemType Directory -Force -Path $build | Out-Null
New-Item -ItemType Directory -Force -Path $output | Out-Null
$hooksFlag = if ($DebugHooks) { '-DBLUEOATH_HOOKS_DEBUG=ON' } else { '-DBLUEOATH_HOOKS_DEBUG=OFF' }

# vcvars32.bat already configures an x86 environment; no 'x86' arg needed.
$command = 'call "' + $vcvars + '" && "' + $cmake + '" -S "' + (Join-Path $root 'native') + '" -B "' + $build + '" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=' + $Configuration + ' ' + $hooksFlag + ' && "' + $cmake + '" --build "' + $build + '"'
cmd.exe /d /s /c $command
if ($LASTEXITCODE -ne 0) { throw "Native build failed: $LASTEXITCODE" }
Copy-Item -LiteralPath (Join-Path $build 'BlueOath.Injector.exe') -Destination $output -Force
Copy-Item -LiteralPath (Join-Path $build 'BlueOath.Payload.dll') -Destination $output -Force