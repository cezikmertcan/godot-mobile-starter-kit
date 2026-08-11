[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Assert-StaticCondition {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "Static validation failed: $Message"
    }
}

$requiredConfigKeys = @(
    "app_key",
    "rewarded_ad_unit_id",
    "interstitial_ad_unit_id",
    "banner_ad_unit_id",
    "banner_placement",
    "enable_test_suite"
)
$stringConfigKeys = @(
    "app_key",
    "rewarded_ad_unit_id",
    "interstitial_ad_unit_id",
    "banner_ad_unit_id",
    "banner_placement"
)
$requiredValueKeys = @(
    "app_key",
    "rewarded_ad_unit_id",
    "interstitial_ad_unit_id",
    "banner_ad_unit_id"
)
$placeholderSuffixes = @{
    app_key = "LEVELPLAY_APP_KEY"
    rewarded_ad_unit_id = "REWARDED_AD_UNIT_ID"
    interstitial_ad_unit_id = "INTERSTITIAL_AD_UNIT_ID"
    banner_ad_unit_id = "BANNER_AD_UNIT_ID"
}

function Assert-LevelPlayConfig {
    param(
        [object]$Config,
        [string]$Label,
        [bool]$RequirePlaceholders
    )

    Assert-StaticCondition ($Config -is [pscustomobject]) "$Label root must be an object"
    $platformNames = @($Config.PSObject.Properties.Name)
    Assert-StaticCondition ($platformNames.Count -eq 2 -and $platformNames -contains "android" -and $platformNames -contains "ios") "$Label must contain exactly the android and ios sections"

    foreach ($platform in @("android", "ios")) {
        $platformProperty = $Config.PSObject.Properties[$platform]
        Assert-StaticCondition ($null -ne $platformProperty -and $platformProperty.Value -is [pscustomobject]) "$Label $platform section is missing or is not an object"
        $platformConfig = $platformProperty.Value
        $actualKeys = @($platformConfig.PSObject.Properties.Name)
        Assert-StaticCondition ($actualKeys.Count -eq $requiredConfigKeys.Count) "$Label $platform config has an unexpected key count"
        foreach ($key in $requiredConfigKeys) {
            Assert-StaticCondition ($actualKeys -contains $key) "$Label $platform config is missing $key"
        }
        foreach ($key in $stringConfigKeys) {
            Assert-StaticCondition ($platformConfig.PSObject.Properties[$key].Value -is [string]) "$Label $platform.$key must be a string"
        }
        Assert-StaticCondition ($platformConfig.enable_test_suite -is [bool]) "$Label $platform.enable_test_suite must be a boolean"
        foreach ($key in $requiredValueKeys) {
            $value = [string]$platformConfig.PSObject.Properties[$key].Value
            Assert-StaticCondition (-not [string]::IsNullOrWhiteSpace($value)) "$Label $platform.$key must not be empty"
            if ($RequirePlaceholders) {
                $expected = "REPLACE_WITH_{0}_{1}" -f $platform.ToUpperInvariant(), $placeholderSuffixes[$key]
                Assert-StaticCondition ($value -ceq $expected) "$Label $platform.$key must use the safe documented placeholder"
            }
        }
    }
}

$configPath = Join-Path $repoRoot "config/levelplay_config.example.json"
try {
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
} catch {
    throw "Static validation failed: could not parse $configPath. $($_.Exception.Message)"
}
Assert-LevelPlayConfig $config "example config" $true

$localConfigPath = Join-Path $repoRoot "config/levelplay_config.json"
if (Test-Path -LiteralPath $localConfigPath -PathType Leaf) {
    try {
        $localConfig = Get-Content -LiteralPath $localConfigPath -Raw | ConvertFrom-Json
    } catch {
        throw "Static validation failed: could not parse $localConfigPath. $($_.Exception.Message)"
    }
    Assert-LevelPlayConfig $localConfig "local config" $false
}

foreach ($requiredPublicFile in @("LICENSE", "THIRD_PARTY_NOTICES.md", "README.md")) {
    Assert-StaticCondition (Test-Path -LiteralPath (Join-Path $repoRoot $requiredPublicFile) -PathType Leaf) "required public-release file is missing: $requiredPublicFile"
}

$androidBuildText = Get-Content -LiteralPath (Join-Path $repoRoot "android-plugin/levelplay/build.gradle.kts") -Raw
$androidExportText = Get-Content -LiteralPath (Join-Path $repoRoot "addons/LevelPlayAds/export_plugin.gd") -Raw
Assert-StaticCondition ($androidBuildText.Contains('val levelPlayVersion = "9.5.0"')) "Android build does not pin LevelPlay 9.5.0"
Assert-StaticCondition ($androidExportText.Contains('const LEVELPLAY_VERSION := "9.5.0"')) "Android export plugin does not pin LevelPlay 9.5.0"
foreach ($dependency in @(
    "com.unity3d.ads-mediation:unityads-adapter:5.11.0",
    "com.unity3d.ads:unity-ads:4.19.0",
    "com.google.android.gms:play-services-appset:16.0.0",
    "com.google.android.gms:play-services-ads-identifier:18.1.0",
    "com.google.android.gms:play-services-basement:18.1.0"
)) {
    Assert-StaticCondition ($androidBuildText.Contains($dependency) -and $androidExportText.Contains($dependency)) "Android build and export dependencies are not synchronized: $dependency"
}

$wrapperText = Get-Content -LiteralPath (Join-Path $repoRoot "android-plugin/gradle/wrapper/gradle-wrapper.properties") -Raw
Assert-StaticCondition ($wrapperText.Contains("gradle-8.14.3-bin.zip") -and $wrapperText.Contains("distributionSha256Sum=")) "Gradle wrapper version or distribution checksum is missing"
$wrapperJarPath = Join-Path $repoRoot "android-plugin/gradle/wrapper/gradle-wrapper.jar"
$wrapperJarSha256 = (Get-FileHash -LiteralPath $wrapperJarPath -Algorithm SHA256).Hash.ToLowerInvariant()
Assert-StaticCondition ($wrapperJarSha256 -ceq "7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172") "Gradle 8.14.3 wrapper JAR checksum does not match Gradle's published checksum"

$presetText = Get-Content -LiteralPath (Join-Path $repoRoot "export_presets.cfg") -Raw
foreach ($requiredText in @(
    "[preset.0]",
    'name="Android"',
    'platform="Android"',
    "[preset.1]",
    'name="iOS"',
    'platform="iOS"',
    "architectures/arm64=true",
    "plugins/LevelPlayAds=true",
    "application/targeted_device_family=2"
)) {
    Assert-StaticCondition ($presetText.Contains($requiredText)) "export preset is missing $requiredText"
}

$minIosMatch = [regex]::Match($presetText, 'application/min_ios_version="([0-9]+(?:\.[0-9]+)*)"')
Assert-StaticCondition $minIosMatch.Success "iOS preset minimum version is missing"
$minIosVersion = [version]$minIosMatch.Groups[1].Value
Assert-StaticCondition ($minIosVersion -ge [version]"14.0") "iOS preset must target iOS 14.0 or newer"

$requiredIosFiles = @(
    "ios-plugin/.gdignore",
    "ios-plugin/Podfile",
    "ios-plugin/ExportPodfile.template",
    "ios-plugin/SConstruct",
    "ios-plugin/src/levelplay_ads.h",
    "ios-plugin/src/levelplay_ads.mm",
    "ios-plugin/src/levelplay_ads_module.cpp",
    "ios-plugin/src/levelplay_ads_module.h",
    "ios/plugins/LevelPlayAds/LevelPlayAds.gdip.template",
    "scripts/build_ios_plugin.sh",
    "scripts/prepare_ios_export.sh",
    "docs/ios-setup.md"
)
foreach ($relativePath in $requiredIosFiles) {
    Assert-StaticCondition (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf) "required iOS support file is missing: $relativePath"
}

$podfileText = Get-Content -LiteralPath (Join-Path $repoRoot "ios-plugin/Podfile") -Raw
$exportPodfileText = Get-Content -LiteralPath (Join-Path $repoRoot "ios-plugin/ExportPodfile.template") -Raw
foreach ($dependency in @("IronSourceSDK', '9.5.0.0", "IronSourceUnityAdsAdapter', '5.8.0.0")) {
    Assert-StaticCondition ($podfileText.Contains($dependency) -and $exportPodfileText.Contains($dependency)) "iOS Podfiles are missing synchronized dependency $dependency"
}
Assert-StaticCondition ($podfileText.Contains("platform :ios, '14.0'") -and $exportPodfileText.Contains("platform :ios, '14.0'")) "iOS Podfiles must target iOS 14.0"

$gdipText = Get-Content -LiteralPath (Join-Path $repoRoot "ios/plugins/LevelPlayAds/LevelPlayAds.gdip.template") -Raw
foreach ($requiredText in @(
    'name="LevelPlayAds"',
    'binary="LevelPlayAds.xcframework"',
    'initialization="levelplay_ads_initialize"',
    'deinitialization="levelplay_ads_deinitialize"'
)) {
    Assert-StaticCondition ($gdipText.Contains($requiredText)) "iOS plugin descriptor is missing $requiredText"
}

$iosBridgeText = Get-Content -LiteralPath (Join-Path $repoRoot "ios-plugin/src/levelplay_ads.mm") -Raw
foreach ($requiredText in @(
    "initWithRequest:request",
    "LPMRewardedAd",
    "LPMInterstitialAd",
    "LPMBannerAdView",
    'emit_signal("reward_earned"'
)) {
    Assert-StaticCondition ($iosBridgeText.Contains($requiredText)) "iOS bridge is missing $requiredText"
}

$managerText = Get-Content -LiteralPath (Join-Path $repoRoot "scripts/godot/ads_manager.gd") -Raw
foreach ($requiredText in @(
    "_try_resolve_plugin(IOS_PLUGIN_NAME)",
    "_try_resolve_plugin(IOS_SHARED_PLUGIN_NAME)",
    'parsed.get(platform_key, null)',
    'return "ios"'
)) {
    Assert-StaticCondition ($managerText.Contains($requiredText)) "ads manager is missing $requiredText"
}
Write-Host "Static Godot cross-platform checks completed."

$godot = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $godot) {
    Write-Warning "Godot 4 was not found on PATH; Godot parser validation was skipped."
    exit 0
}

$validationLog = Join-Path ([System.IO.Path]::GetTempPath()) "godot-mobile-starter-validation.log"
& $godot.Source --headless --path $repoRoot --log-file $validationLog --editor --quit
if ($LASTEXITCODE -ne 0) {
    throw "Godot headless validation failed with exit code $LASTEXITCODE."
}
$validationLogText = Get-Content -LiteralPath $validationLog -Raw
if ($validationLogText -match "(?i)SCRIPT ERROR|Parse Error|Invalid plugin config file") {
    throw "Godot validation log contains a script, parser, or plugin descriptor error: $validationLog"
}
Write-Host "Godot project validation completed."
