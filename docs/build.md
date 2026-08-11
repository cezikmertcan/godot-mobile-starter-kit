# Build process

## Android native plugin

Build the AARs first:

```text
Windows:      scripts/build_plugin.ps1
macOS/Linux: scripts/build_plugin.sh
```

Expected ignored outputs:

```text
addons/LevelPlayAds/bin/debug/LevelPlayAds-debug.aar
addons/LevelPlayAds/bin/release/LevelPlayAds-release.aar
```

The Android plugin and export add-on declare LevelPlay `9.5.0`, Unity Ads adapter `5.11.0`, Unity Ads runtime `4.19.0`, and their required Google Play Services dependencies.

## iOS native plugin

On macOS, provide the matching Godot source tree and build both XCFramework variants:

```text
GODOT_SOURCE_DIR=/absolute/path/to/godot-4.7.1 scripts/build_ios_plugin.sh
```

Expected ignored outputs:

```text
ios/plugins/LevelPlayAds/LevelPlayAds.gdip
ios/plugins/LevelPlayAds/LevelPlayAds.debug.xcframework
ios/plugins/LevelPlayAds/LevelPlayAds.release.xcframework
```

The script installs the pinned CocoaPods dependencies, generates required Godot headers, builds arm64 device plus arm64/x86_64 simulator slices, packages them as XCFrameworks, and copies the tracked `LevelPlayAds.gdip.template` to the ignored runtime descriptor. Generating the descriptor only when its binaries exist keeps a clean clone free of invalid-plugin warnings while still letting Godot discover the completed plugin.

## Android APK

The Android preset has Gradle export enabled. Run one final debug export at milestone completion:

```text
Windows:      scripts/build_final_apk.ps1
macOS/Linux: scripts/build_final_apk.sh
```

Output:

```text
builds/android/apk/godot-mobile-starter-debug.apk
```

## iOS Xcode workspace

1. Build the iOS XCFrameworks.
2. In Godot's iOS export options, confirm `LevelPlayAds` is enabled, set the final bundle identifier and Apple team, and export the project ZIP.
3. Extract the ZIP into a clean directory.
4. Run `scripts/prepare_ios_export.sh /absolute/path/to/extracted/export`.
5. Open the generated `.xcworkspace` in Xcode, configure signing, and run/archive from the workspace.

The preparation script creates a Podfile from the tracked template and installs LevelPlay `9.5.0.0` plus Unity Ads adapter `5.8.0.0`. It refuses to overwrite an existing Podfile.

## Before export

- `config/levelplay_config.json` exists locally and has valid IDs for the target platform.
- The target platform's native debug/release plugin binaries exist.
- Matching Godot export templates are installed.
- Android Gradle/JDK or iOS Xcode/CocoaPods tooling is configured locally.
- No keystore, certificate, provisioning profile, app key, or signing credential is stored in the repository.

## Source release ZIP

Create public source archives from a reviewed Git tag instead of compressing the working directory. This excludes ignored local configuration, native dependencies, caches, and signing files:

```text
mkdir -p builds/releases
git archive --format=zip --prefix=godot-mobile-starter-kit-v0.1.0/ --output=builds/releases/godot-mobile-starter-kit-v0.1.0.zip v0.1.0
```

Replace `v0.1.0` with the release tag. Publish the same tagged source on GitHub and itch.io, and record a SHA-256 checksum for the uploaded ZIP.
