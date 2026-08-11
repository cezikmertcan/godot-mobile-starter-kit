#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_directory="$repo_root/builds/android/apk"
output_path="$output_directory/godot-mobile-starter-debug.apk"

if command -v godot >/dev/null 2>&1; then
    godot_command="godot"
elif command -v godot4 >/dev/null 2>&1; then
    godot_command="godot4"
else
    echo "Godot 4 was not found on PATH." >&2
    exit 1
fi

mkdir -p "$output_directory"
shopt -s nullglob
for apk in "$output_directory"/*.apk; do
    if [[ "$apk" != "$output_path" ]]; then
        echo "The APK output directory contains more than the single allowed final artifact: $apk" >&2
        exit 1
    fi
done
rm -f "$output_path"

"$godot_command" --headless --path "$repo_root" --export-debug "Android" "$output_path"
test -f "$output_path"
echo "Final APK created: $output_path"
echo "Real-device verification remains: PENDING USER DEVICE TEST."
