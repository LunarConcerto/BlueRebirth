$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$cnRoot = (Get-ChildItem -LiteralPath $root -Directory | ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory -Filter 'clsy' -ErrorAction SilentlyContinue } | Select-Object -First 1).FullName
$targets = @(
  @{ Region='jp'; VersionFile='blueoath\blueoath\Version.txt'; Exe='blueoath\blueoath\blueoath.exe'; Game='blueoath\blueoath\GameAssembly.dll'; Metadata='blueoath\blueoath\blueoath_Data\il2cpp_data\Metadata\global-metadata.dat'; Xlua='blueoath\blueoath\blueoath_Data\Plugins\xlua.dll' },
  @{ Region='cn'; VersionFile=(Join-Path $cnRoot 'Version.txt'); Exe=(Join-Path $cnRoot 'clsy.exe'); Game=(Join-Path $cnRoot 'GameAssembly.dll'); Metadata=(Join-Path $cnRoot 'clsy_Data\il2cpp_data\Metadata\global-metadata.dat'); Xlua=(Join-Path $cnRoot 'clsy_Data\Plugins\xlua.dll') }
)
$rows = foreach($t in $targets) { $files=@($t.Exe,$t.Game,$t.Metadata,$t.Xlua); $hashes=@{}; foreach($f in $files){$path=if([IO.Path]::IsPathRooted($f)){$f}else{Join-Path $root $f};$hashes[$f]=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash}; $vf=if([IO.Path]::IsPathRooted($t.VersionFile)){$t.VersionFile}else{Join-Path $root $t.VersionFile}; [ordered]@{region=$t.Region;version=(Get-Content $vf -Raw).Trim();architecture='x86';files=$hashes} }
$rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $root 'baseline.json') -Encoding UTF8
