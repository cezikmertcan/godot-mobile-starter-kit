# iOS setup

iOS exports require macOS. Install:

- Godot 4.7.x with its matching iOS export templates;
- current Xcode and command-line tools;
- CocoaPods;
- SCons;
- the Godot source tree matching the editor/export template version.

The project targets iOS 14.0 or newer because Godot 4.7's Metal renderer requires it. This is stricter than the pinned Unity Ads adapter's iOS 13 minimum.

## Build the Godot plugin

From the repository root:

```text
GODOT_SOURCE_DIR=/absolute/path/to/godot-4.7.1 scripts/build_ios_plugin.sh
```

The script installs native dependencies under the ignored `ios-plugin/Pods/` folder, creates ignored debug/release XCFrameworks under `ios/plugins/LevelPlayAds/`, and generates `LevelPlayAds.gdip` from the tracked descriptor template. The descriptor is intentionally absent until the binaries exist, so Godot does not report an incomplete plugin in a clean clone.

## Configure Godot

1. Copy `config/levelplay_config.example.json` to `config/levelplay_config.json` and fill the `ios` section with the iOS app key and ad unit IDs.
2. Open Project → Export → iOS.
3. Confirm `LevelPlayAds` is enabled in the preset's Plugins section (the tracked preset enables it by default).
4. Replace `com.example.godotmobilestarter` with the final bundle identifier.
5. Set the Apple team/signing fields locally and keep iOS 14.0 as the minimum.
6. Export the Xcode project ZIP and extract it.

## Add LevelPlay to the exported project

Run:

```text
scripts/prepare_ios_export.sh /absolute/path/to/extracted/export
```

This generates a Podfile for the detected application target and runs `pod install`. Open the resulting `.xcworkspace`, not the `.xcodeproj`, for signing, device runs, and archives.

Do not commit generated XCFrameworks, Pods, exported Xcode projects, provisioning profiles, certificates, app keys, or signing settings. Validate ad delivery on a physical test device; simulator compilation verifies the bridge but does not prove mediation inventory.
