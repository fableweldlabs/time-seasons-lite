param(
 [string]$Project = (Split-Path $PSScriptRoot),
 [string[]]$EngineArgs = @('--editor','--import','--quit'),
 [string]$LogName = 'headless-import',
 [string]$Godot = 'C:\Program Files\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$engine = $Godot
$evidence = Join-Path (Split-Path $PSScriptRoot) 'evidence'
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
$argsList = @('--headless','--path',('"' + $Project + '"')) + $EngineArgs
$stdout = Join-Path $evidence "$LogName.txt"
$stderr = Join-Path $evidence "$LogName-errors.txt"
$timeoutMs = if ('--import' -in $EngineArgs -or '--export-pack' -in $EngineArgs) { 300000 } else { 120000 }
$process = Start-Process -FilePath $engine -ArgumentList $argsList -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
if(-not $process.WaitForExit($timeoutMs)) {
 $process.Kill()
 throw "Headless engine timed out; see $stdout"
}
$process.Refresh()
Get-Content -LiteralPath $stdout -Tail 5
$errors = [IO.File]::ReadAllText($stderr)
if($process.ExitCode -ne 0 -or $errors -match 'SCRIPT ERROR|ERROR:') {
 Write-Output $errors
 throw "Headless engine failed: $($process.ExitCode)"
}

# Exit status alone is insufficient: a test must reach its named completion line.
$scriptFlag = [Array]::IndexOf($EngineArgs,'--script')
if($scriptFlag -ge 0 -and $scriptFlag + 1 -lt $EngineArgs.Count) {
 $suiteName = [IO.Path]::GetFileNameWithoutExtension($EngineArgs[$scriptFlag+1])
 $markers = @{growth='GROWTH:';host='HOST:';reactions='REACTIONS:';extensions='EXTENSIONS:';date_events='DATE EVENTS:';run='RESULT:';advanced='ADVANCED:';adversarial='ADVERSARIAL:';authoring='AUTHORING:';lighting='LIGHTING/SLEEP:';demo='DEMO:';properties='TIMELINE PROPERTIES:';starter='STARTER CONVENIENCES:';contracts='CONVENIENCE CONTRACTS:';lite='LITE:';upgrade='UPGRADE:';export_smoke='PACKED RUNTIME:'}
 if($markers.ContainsKey($suiteName) -and [IO.File]::ReadAllText($stdout) -notmatch [regex]::Escape($markers[$suiteName])) { throw "Test ended without its completion marker: $suiteName" }
}
if('--fw-editor-probe' -in $EngineArgs -and [IO.File]::ReadAllText($stdout) -notmatch 'EDITOR LIFECYCLE:') { throw 'Editor probe ended without its completion marker.' }


