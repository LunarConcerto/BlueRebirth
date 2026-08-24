param(
  [switch]$DebugHooks
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat'
if (-not (Test-Path -LiteralPath $vcvars)) { throw 'Visual Studio 2019 Build Tools not found' }
$build = Join-Path $env:TEMP 'blueoath-native-x86-nmake'
$output = Join-Path $root 'native\bin-x86'
New-Item -ItemType Directory -Force -Path $build | Out-Null
New-Item -ItemType Directory -Force -Path $output | Out-Null
$hooksFlag = if ($DebugHooks) { '-DBLUEOATH_HOOKS_DEBUG=ON' } else { '-DBLUEOATH_HOOKS_DEBUG=OFF' }
$command = 'call "' + $vcvars + '" x86 && cmake -S "' + (Join-Path $root 'native') + '" -B "' + $build + '" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release ' + $hooksFlag + ' && cmake --build "' + $build + '"'
cmd.exe /d /s /c $command
if ($LASTEXITCODE -ne 0) { throw "Native build failed: $LASTEXITCODE" }
Copy-Item -LiteralPath (Join-Path $build 'BlueOath.Injector.exe') -Destination $output -Force
Copy-Item -LiteralPath (Join-Path $build 'BlueOath.Payload.dll') -Destination $output -Force
