[CmdletBinding()]
param(
    [switch]$DebugOnly
)

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pluginRoot = Join-Path $repoRoot "android-plugin"
$gradleWrapper = Join-Path $pluginRoot "gradlew.bat"

function Invoke-Gradle {
    param([string[]]$Arguments)

    if (Test-Path -LiteralPath $gradleWrapper) {
        & $gradleWrapper @Arguments
        return
    }

    $gradle = Get-Command gradle -ErrorAction SilentlyContinue
    if ($null -eq $gradle) {
        throw "Gradle wrapper or a Gradle installation was not found. Open android-plugin in Android Studio or install Gradle 8.14.3."
    }
    & $gradle.Source @Arguments
}

$tasks = if ($DebugOnly) { @(":levelplay:copyDebugAar") } else { @(":levelplay:packagePlugin") }
Push-Location $pluginRoot
try {
    Invoke-Gradle -Arguments $tasks
} finally {
    Pop-Location
}

$expected = if ($DebugOnly) {
    @(Join-Path $repoRoot "addons\LevelPlayAds\bin\debug\LevelPlayAds-debug.aar")
} else {
    @(
        (Join-Path $repoRoot "addons\LevelPlayAds\bin\debug\LevelPlayAds-debug.aar"),
        (Join-Path $repoRoot "addons\LevelPlayAds\bin\release\LevelPlayAds-release.aar")
    )
}
foreach ($path in $expected) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Expected plugin artifact was not produced: $path"
    }
}
Write-Host "LevelPlay Android plugin packaged successfully."
