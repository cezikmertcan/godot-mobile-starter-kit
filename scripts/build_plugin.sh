#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_root="$repo_root/android-plugin"
debug_only="${1:-}"

if [[ -x "$plugin_root/gradlew" ]]; then
    gradle_command=("$plugin_root/gradlew")
elif command -v gradle >/dev/null 2>&1; then
    gradle_command=("gradle")
else
    echo "Gradle wrapper or a Gradle installation was not found. Open android-plugin in Android Studio or install Gradle 8.14.3." >&2
    exit 1
fi

if [[ "$debug_only" == "--debug-only" ]]; then
    gradle_tasks=(":levelplay:copyDebugAar")
    expected=("$repo_root/addons/LevelPlayAds/bin/debug/LevelPlayAds-debug.aar")
else
    gradle_tasks=(":levelplay:packagePlugin")
    expected=(
        "$repo_root/addons/LevelPlayAds/bin/debug/LevelPlayAds-debug.aar"
        "$repo_root/addons/LevelPlayAds/bin/release/LevelPlayAds-release.aar"
    )
fi

(
    cd "$plugin_root"
    "${gradle_command[@]}" "${gradle_tasks[@]}"
)

for artifact in "${expected[@]}"; do
    if [[ ! -f "$artifact" ]]; then
        echo "Expected plugin artifact was not produced: $artifact" >&2
        exit 1
    fi
done
echo "LevelPlay Android plugin packaged successfully."
