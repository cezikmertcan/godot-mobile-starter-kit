[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outputDirectory = Join-Path $repoRoot "builds\android\apk"
$outputPath = Join-Path $outputDirectory "godot-mobile-starter-debug.apk"
$godot = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $godot) {
    throw "Godot 4 was not found on PATH."
}

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$otherApks = Get-ChildItem -LiteralPath $outputDirectory -Filter "*.apk" -File | Where-Object { $_.FullName -ne $outputPath }
if ($otherApks.Count -gt 0) {
    throw "The APK output directory contains more than the single allowed final artifact: $($otherApks.Name -join ', ')"
}
if (Test-Path -LiteralPath $outputPath) {
    Remove-Item -LiteralPath $outputPath -Force
}

& $godot.Source --headless --path $repoRoot --export-debug "Android" $outputPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputPath)) {
    throw "Final APK export failed."
}
Write-Host "Final APK created: $outputPath"
Write-Host "Real-device verification remains: PENDING USER DEVICE TEST."
