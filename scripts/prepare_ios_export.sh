#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export_root="${1:-$repo_root/builds/ios/exported}"
template_path="$repo_root/ios-plugin/ExportPodfile.template"

for command_name in pod xcodebuild python3; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command was not found: $command_name" >&2
        exit 1
    fi
done

if [[ ! -d "$export_root" ]]; then
    echo "Extract the Godot iOS export first, then pass its directory to this script." >&2
    echo "Directory not found: $export_root" >&2
    exit 1
fi

project_files=()
while IFS= read -r project_file_path; do
    project_files+=("$project_file_path")
done < <(find "$export_root" -maxdepth 2 -type d -name '*.xcodeproj' -print)
if [[ ${#project_files[@]} -ne 1 ]]; then
    echo "Expected exactly one .xcodeproj below $export_root; found ${#project_files[@]}." >&2
    exit 1
fi

project_file="${project_files[0]}"
project_directory="$(dirname "$project_file")"
project_name="$(basename "$project_file")"
project_listing="$(xcodebuild -list -json -project "$project_file")"
target_name="$(python3 -c 'import json,sys; data=json.load(sys.stdin); targets=data.get("project",{}).get("targets",[]); print(targets[0] if targets else "")' <<<"$project_listing")"

if [[ -z "$target_name" ]]; then
    echo "Could not determine the application target in $project_file." >&2
    exit 1
fi

podfile_path="$project_directory/Podfile"
if [[ -e "$podfile_path" ]]; then
    echo "Refusing to overwrite the existing Podfile: $podfile_path" >&2
    exit 1
fi

python3 - "$template_path" "$podfile_path" "$project_name" "$target_name" <<'PY'
from pathlib import Path
import sys

template_path, output_path, project_name, target_name = sys.argv[1:]
text = Path(template_path).read_text(encoding="utf-8")
text = text.replace("__PROJECT_FILE__", project_name)
text = text.replace("__TARGET_NAME__", target_name)
Path(output_path).write_text(text, encoding="utf-8")
PY

(
    cd "$project_directory"
    pod install
)

workspace_path="$project_directory/${project_name%.xcodeproj}.xcworkspace"
echo "CocoaPods integration completed. Open this workspace in Xcode:"
echo "$workspace_path"
