#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python_command=""
if command -v python3 >/dev/null 2>&1; then
    python_command="python3"
fi

if [[ -z "$python_command" ]]; then
    echo "Python 3 was not found on PATH; static JSON validation was skipped." >&2
else
    "$python_command" - "$repo_root" <<'PY'
import hashlib
import json
import re
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])


def fail(message: str) -> None:
    raise SystemExit(f"Static validation failed: {message}")


required_config_keys = {
    "app_key",
    "rewarded_ad_unit_id",
    "interstitial_ad_unit_id",
    "banner_ad_unit_id",
    "banner_placement",
    "enable_test_suite",
}
string_config_keys = required_config_keys.difference({"enable_test_suite"})
required_value_keys = {
    "app_key",
    "rewarded_ad_unit_id",
    "interstitial_ad_unit_id",
    "banner_ad_unit_id",
}
placeholder_suffixes = {
    "app_key": "LEVELPLAY_APP_KEY",
    "rewarded_ad_unit_id": "REWARDED_AD_UNIT_ID",
    "interstitial_ad_unit_id": "INTERSTITIAL_AD_UNIT_ID",
    "banner_ad_unit_id": "BANNER_AD_UNIT_ID",
}


def validate_config(config: object, label: str, require_placeholders: bool) -> None:
    if not isinstance(config, dict):
        fail(f"{label} root must be an object")
    platform_keys = set(config)
    expected_platforms = {"android", "ios"}
    if platform_keys != expected_platforms:
        fail(f"{label} must contain exactly the android and ios sections")

    for platform in ("android", "ios"):
        platform_config = config.get(platform)
        if not isinstance(platform_config, dict):
            fail(f"{label} {platform} section is missing or is not an object")
        config_keys = set(platform_config)
        if config_keys != required_config_keys:
            missing = required_config_keys.difference(config_keys)
            unexpected = config_keys.difference(required_config_keys)
            details = []
            if missing:
                details.append(f"missing: {', '.join(sorted(missing))}")
            if unexpected:
                details.append(f"unexpected: {', '.join(sorted(unexpected))}")
            fail(f"{label} {platform} keys do not match the schema ({'; '.join(details)})")

        for key in string_config_keys:
            if not isinstance(platform_config[key], str):
                fail(f"{label} {platform}.{key} must be a string")
        if not isinstance(platform_config["enable_test_suite"], bool):
            fail(f"{label} {platform}.enable_test_suite must be a boolean")
        for key in required_value_keys:
            if not platform_config[key].strip():
                fail(f"{label} {platform}.{key} must not be empty")
            if require_placeholders:
                expected = f"REPLACE_WITH_{platform.upper()}_{placeholder_suffixes[key]}"
                if platform_config[key] != expected:
                    fail(f"{label} {platform}.{key} must use the safe documented placeholder")


example_config_path = repo_root / "config/levelplay_config.example.json"
try:
    example_config = json.loads(example_config_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"could not parse {example_config_path}: {error}")
validate_config(example_config, "example config", require_placeholders=True)

local_config_path = repo_root / "config/levelplay_config.json"
if local_config_path.is_file():
    try:
        local_config = json.loads(local_config_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"could not parse {local_config_path}: {error}")
    validate_config(local_config, "local config", require_placeholders=False)

for required_public_file in ("LICENSE", "THIRD_PARTY_NOTICES.md", "README.md"):
    if not (repo_root / required_public_file).is_file():
        fail(f"required public-release file is missing: {required_public_file}")

android_build_text = (repo_root / "android-plugin/levelplay/build.gradle.kts").read_text(encoding="utf-8")
android_export_text = (repo_root / "addons/LevelPlayAds/export_plugin.gd").read_text(encoding="utf-8")
if 'val levelPlayVersion = "9.5.0"' not in android_build_text:
    fail("Android build does not pin LevelPlay 9.5.0")
if 'const LEVELPLAY_VERSION := "9.5.0"' not in android_export_text:
    fail("Android export plugin does not pin LevelPlay 9.5.0")
for dependency in (
    "com.unity3d.ads-mediation:unityads-adapter:5.11.0",
    "com.unity3d.ads:unity-ads:4.19.0",
    "com.google.android.gms:play-services-appset:16.0.0",
    "com.google.android.gms:play-services-ads-identifier:18.1.0",
    "com.google.android.gms:play-services-basement:18.1.0",
):
    if dependency not in android_build_text or dependency not in android_export_text:
        fail(f"Android build and export dependencies are not synchronized: {dependency}")

wrapper_text = (repo_root / "android-plugin/gradle/wrapper/gradle-wrapper.properties").read_text(encoding="utf-8")
if "gradle-8.14.3-bin.zip" not in wrapper_text or "distributionSha256Sum=" not in wrapper_text:
    fail("Gradle wrapper version or distribution checksum is missing")
wrapper_jar_path = repo_root / "android-plugin/gradle/wrapper/gradle-wrapper.jar"
wrapper_jar_sha256 = hashlib.sha256(wrapper_jar_path.read_bytes()).hexdigest()
if wrapper_jar_sha256 != "7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172":
    fail("Gradle 8.14.3 wrapper JAR checksum does not match Gradle's published checksum")

preset_text = (repo_root / "export_presets.cfg").read_text(encoding="utf-8")
for required_text in (
    '[preset.0]',
    'name="Android"',
    'platform="Android"',
    '[preset.1]',
    'name="iOS"',
    'platform="iOS"',
    'architectures/arm64=true',
    'plugins/LevelPlayAds=true',
    'application/targeted_device_family=2',
):
    if required_text not in preset_text:
        fail(f"export preset is missing {required_text}")

min_ios_match = re.search(r'application/min_ios_version="([0-9]+(?:\.[0-9]+)*)"', preset_text)
if min_ios_match is None or tuple(map(int, min_ios_match.group(1).split("."))) < (14, 0):
    fail("iOS preset must target iOS 14.0 or newer")

required_ios_files = (
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
    "docs/ios-setup.md",
)
for relative_path in required_ios_files:
    if not (repo_root / relative_path).is_file():
        fail(f"required iOS support file is missing: {relative_path}")

podfile_text = (repo_root / "ios-plugin/Podfile").read_text(encoding="utf-8")
export_podfile_text = (repo_root / "ios-plugin/ExportPodfile.template").read_text(encoding="utf-8")
for dependency in ("IronSourceSDK', '9.5.0.0", "IronSourceUnityAdsAdapter', '5.8.0.0"):
    if dependency not in podfile_text or dependency not in export_podfile_text:
        fail(f"iOS Podfiles are missing synchronized dependency {dependency}")
if "platform :ios, '14.0'" not in podfile_text or "platform :ios, '14.0'" not in export_podfile_text:
    fail("iOS Podfiles must target iOS 14.0")

gdip_text = (repo_root / "ios/plugins/LevelPlayAds/LevelPlayAds.gdip.template").read_text(encoding="utf-8")
for required_text in (
    'name="LevelPlayAds"',
    'binary="LevelPlayAds.xcframework"',
    'initialization="levelplay_ads_initialize"',
    'deinitialization="levelplay_ads_deinitialize"',
):
    if required_text not in gdip_text:
        fail(f"iOS plugin descriptor is missing {required_text}")

ios_bridge_text = (repo_root / "ios-plugin/src/levelplay_ads.mm").read_text(encoding="utf-8")
for required_text in (
    "initWithRequest:request",
    "LPMRewardedAd",
    "LPMInterstitialAd",
    "LPMBannerAdView",
    'emit_signal("reward_earned"',
):
    if required_text not in ios_bridge_text:
        fail(f"iOS bridge is missing {required_text}")

manager_text = (repo_root / "scripts/godot/ads_manager.gd").read_text(encoding="utf-8")
for required_text in (
    '_try_resolve_plugin(IOS_PLUGIN_NAME)',
    '_try_resolve_plugin(IOS_SHARED_PLUGIN_NAME)',
    'parsed.get(platform_key, null)',
    'return "ios"',
):
    if required_text not in manager_text:
        fail(f"ads manager is missing {required_text}")

print("Static Godot cross-platform checks completed.")
PY
fi

godot_command=""
if command -v godot >/dev/null 2>&1; then
    godot_command="godot"
elif command -v godot4 >/dev/null 2>&1; then
    godot_command="godot4"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    godot_command="/Applications/Godot.app/Contents/MacOS/Godot"
fi

if [[ -z "$godot_command" ]]; then
    echo "Godot 4 was not found on PATH; Godot parser validation was skipped." >&2
    exit 0
fi

validation_log="${TMPDIR:-/tmp}/godot-mobile-starter-validation.log"
"$godot_command" --headless --path "$repo_root" --log-file "$validation_log" --editor --quit
if grep -Eiq 'SCRIPT ERROR|Parse Error|Invalid plugin config file' "$validation_log"; then
    echo "Godot validation log contains a script, parser, or plugin descriptor error: $validation_log" >&2
    exit 1
fi
echo "Godot project validation completed."
