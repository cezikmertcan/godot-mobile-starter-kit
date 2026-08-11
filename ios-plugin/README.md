# LevelPlayAds iOS plugin

This Objective-C++ bridge exposes the same `LevelPlayAds` singleton, methods, and signals as the Android plugin. It targets Godot 4.7.x, Unity LevelPlay `9.5.0.0`, and the Unity Ads adapter pod `5.8.0.0`.

The generated plugin binaries are intentionally ignored. Build them on macOS with Xcode, CocoaPods, SCons, and the matching Godot source tree:

```text
GODOT_SOURCE_DIR=/absolute/path/to/godot-4.7.1 scripts/build_ios_plugin.sh
```

The script installs the pinned pods for compilation headers, builds device and simulator static libraries, packages debug/release XCFrameworks under `ios/plugins/LevelPlayAds/`, and generates the ignored `.gdip` descriptor from the tracked template. A clean clone intentionally has no active descriptor until those binaries exist.

After Godot exports the Xcode project and you extract its ZIP, integrate the runtime SDKs:

```text
scripts/prepare_ios_export.sh /absolute/path/to/extracted/export
```

Open the generated `.xcworkspace`, not the `.xcodeproj`, to sign and run the app. Full setup details are in `docs/ios-setup.md`.
