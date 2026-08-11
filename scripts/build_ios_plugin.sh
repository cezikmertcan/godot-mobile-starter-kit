#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_root="$repo_root/ios-plugin"
output_root="$repo_root/ios/plugins/LevelPlayAds"
godot_source="${GODOT_SOURCE_DIR:-$plugin_root/godot}"
descriptor_template="$output_root/LevelPlayAds.gdip.template"
descriptor_output="$output_root/LevelPlayAds.gdip"

if [[ ! -f "$descriptor_template" ]]; then
    echo "iOS plugin descriptor template was not found at: $descriptor_template" >&2
    exit 1
fi

for command_name in pod python3 xcrun xcodebuild lipo; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command was not found: $command_name" >&2
        exit 1
    fi
done

if command -v scons >/dev/null 2>&1; then
    scons_command=(scons)
elif python3 -c 'import SCons' >/dev/null 2>&1; then
    scons_command=(python3 -m SCons)
else
    echo "SCons was not found. Install it with: python3 -m pip install scons" >&2
    exit 1
fi

if [[ ! -f "$godot_source/core/version.h" ]]; then
    echo "Godot source was not found at: $godot_source" >&2
    echo "Clone the Godot 4.7.1 source there or set GODOT_SOURCE_DIR to its absolute path." >&2
    exit 1
fi

if ! grep -Eq '^major[[:space:]]*=[[:space:]]*4$' "$godot_source/version.py" || ! grep -Eq '^minor[[:space:]]*=[[:space:]]*7$' "$godot_source/version.py"; then
    echo "GODOT_SOURCE_DIR must point to the Godot 4.7.x source tree." >&2
    exit 1
fi

"${scons_command[@]}" -C "$godot_source" \
    platform=ios \
    target=template_debug \
    arch=arm64 \
    core/disabled_classes.gen.h \
    core/version_generated.gen.h \
    core/extension/gdextension_interface.gen.h

(
    cd "$plugin_root"
    pod install
)

levelplay_headers="$plugin_root/Pods/IronSourceSDK/IronSource/IronSource.xcframework/ios-arm64/IronSource.framework/Headers"
if [[ ! -f "$levelplay_headers/IronSource.h" ]]; then
    echo "LevelPlay headers were not installed at the expected CocoaPods path." >&2
    exit 1
fi

mkdir -p "$plugin_root/build" "$output_root"

build_slice() {
    local variant="$1"
    local architecture="$2"
    local simulator="$3"

    "${scons_command[@]}" -C "$plugin_root" \
        target="$variant" \
        arch="$architecture" \
        simulator="$simulator" \
        godot_source="$godot_source" \
        levelplay_headers="$levelplay_headers" \
        target_path="$plugin_root/build"
}

for variant in debug release; do
    build_slice "$variant" arm64 no
    build_slice "$variant" arm64 yes
    build_slice "$variant" x86_64 yes

    simulator_library="$plugin_root/build/LevelPlayAds.simulator.$variant.a"
    lipo -create \
        "$plugin_root/build/LevelPlayAds.arm64-simulator.$variant.a" \
        "$plugin_root/build/LevelPlayAds.x86_64-simulator.$variant.a" \
        -output "$simulator_library"

    framework_path="$output_root/LevelPlayAds.$variant.xcframework"
    if [[ -e "$framework_path" ]]; then
        rm -rf -- "$framework_path"
    fi
    xcodebuild -create-xcframework \
        -library "$plugin_root/build/LevelPlayAds.arm64-device.$variant.a" \
        -library "$simulator_library" \
        -output "$framework_path"
done

cp "$descriptor_template" "$descriptor_output"

echo "iOS plugin frameworks were created under: $output_root"
echo "Godot plugin descriptor was created at: $descriptor_output"
