$ErrorActionPreference = 'Stop'
$godotPath = $env:GODOT_EXECUTABLE
if (-not $godotPath) {
    $godotPath = Join-Path $env:LOCALAPPDATA 'Programs\Godot\4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $godotPath)) {
    throw "Godot not found: $godotPath. Set GODOT_EXECUTABLE to your Godot console executable."
}
$projectRoot = Split-Path -Parent $PSScriptRoot
& $godotPath --path $projectRoot @args
exit $LASTEXITCODE
