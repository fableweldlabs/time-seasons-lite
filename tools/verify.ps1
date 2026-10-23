param([string]$Godot = 'C:\Program Files\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$paid = Test-Path -LiteralPath "$root\addons\rpg_time\paid\world_clock.gd"
$fixture = Join-Path $root 'upgrade-proof'
if(-not $paid -and (Test-Path -LiteralPath $fixture)) { throw 'Preexisting upgrade-proof fixture requires review; not overwritten.' }
& "$PSScriptRoot\headless.ps1" -Godot $Godot -LogName 'verify-import'
 $suites = if($paid) { @('run','advanced','adversarial','authoring','lighting','demo','properties','starter','contracts','growth','host','reactions','extensions','date_events') } else { @('lite') }
try {
 foreach($suite in $suites) {
  & "$PSScriptRoot\headless.ps1" -Godot $Godot -EngineArgs @('--script',"res://tests/$suite.gd") -LogName "verify-$suite"
 }
 & "$PSScriptRoot\headless.ps1" -Godot $Godot -EngineArgs @('--editor','--','--fw-editor-probe') -LogName 'verify-lifecycle'
} finally {
 if(-not $paid -and (Test-Path -LiteralPath $fixture)) {
  $resolved = (Resolve-Path -LiteralPath $fixture).Path
  if($resolved -ne [IO.Path]::GetFullPath((Join-Path $root 'upgrade-proof'))) { throw 'Unsafe fixture cleanup path' }
  Remove-Item -LiteralPath $resolved -Recurse -Force
 }
}


