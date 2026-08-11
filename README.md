# Godot Mobile Starter Kit

A reusable, genre-neutral Godot 4.7 mobile shell for Android and iOS. It provides the application flow and native advertisement boundary that usually has to be rebuilt before work on game-specific mechanics can begin.

The project is intentionally not a finished game. Replace `gameplay_placeholder/` with your own gameplay while keeping the shared shell, services, and platform integrations.

## Current status

| Area | Status |
| --- | --- |
| Godot project validation and bootstrap flow | Verified |
| Android native plugin build | Verified |
| Android physical-device LevelPlay callbacks | Verified |
| iOS device and simulator native compilation | Verified |
| iOS signed physical-device ad delivery | Pending final verification |

The starter kit is suitable for evaluation and extension, but it should not be described as production-ready until the target app has completed its own signing, privacy, dashboard, mediation, and physical-device release checks.

## Included

- Bootstrap, scene transitions, loading overlay, popups, pause flow, and safe-area helpers.
- Main menu, settings, level-complete, and failure/retry screens.
- Local save/settings, audio, haptics, soft currency, rewards, session state, and ad-frequency services.
- A platform-neutral `AdsManager` autoload used by gameplay code.
- Android `LevelPlayAds` Godot plugin implemented in Kotlin.
- iOS `LevelPlayAds` Godot plugin implemented in Objective-C++.
- Rewarded, interstitial, and banner test controls available only in debug builds.
- Android, iOS, build, architecture, configuration, and testing documentation.

## Deliberately out of scope

- Genre-specific gameplay, characters, art, audio, or animation assets.
- Analytics, crash reporting, in-app purchases, cloud saves, remote configuration, or localization.
- Store signing credentials, LevelPlay keys, ad unit IDs, generated native binaries, or exported applications.
- Automatic privacy consent or App Tracking Transparency flows. Each shipping app must implement the requirements that apply to its audience, regions, and enabled mediation networks.

## Requirements

### Shared

- Godot 4.7.x with matching export templates.
- Python 3 for the static validation helper.

### Android

- JDK 17.
- Android SDK Platform 35 and Android Build Tools.
- The included Gradle wrapper downloads Gradle 8.14.3.

### iOS

- macOS with Xcode and command-line tools.
- CocoaPods and SCons.
- A Godot source checkout matching the editor/export-template version.

## Quick start

1. Clone or download the repository.
2. Create the ignored local LevelPlay configuration:

   ```bash
   cp config/levelplay_config.example.json config/levelplay_config.json
   ```

   PowerShell:

   ```powershell
   Copy-Item config/levelplay_config.example.json config/levelplay_config.json
   ```

3. Enter separate Android and iOS dashboard values in the local file:

   ```json
   {
     "android": {
       "app_key": "ANDROID_APP_KEY",
       "rewarded_ad_unit_id": "ANDROID_REWARDED_ID",
       "interstitial_ad_unit_id": "ANDROID_INTERSTITIAL_ID",
       "banner_ad_unit_id": "ANDROID_BANNER_ID",
       "banner_placement": "",
       "enable_test_suite": false
     },
     "ios": {
       "app_key": "IOS_APP_KEY",
       "rewarded_ad_unit_id": "IOS_REWARDED_ID",
       "interstitial_ad_unit_id": "IOS_INTERSTITIAL_ID",
       "banner_ad_unit_id": "IOS_BANNER_ID",
       "banner_placement": "",
       "enable_test_suite": false
     }
   }
   ```

   The runtime reads only the object matching the exported platform. The local file is ignored by Git; the example file is the only configuration template intended for source control.

4. Build the native plugin for the target platform:

   ```text
   Android, Windows:      scripts/build_plugin.ps1
   Android, macOS/Linux: scripts/build_plugin.sh
   iOS, macOS:           scripts/build_ios_plugin.sh
   ```

5. Open the project in Godot and run it. The default flow is:

   ```text
   Bootstrap -> Main Menu -> Placeholder Level -> Complete or Retry
   ```

6. In a debug build, open `Developer Tools -> Open LevelPlay Ad Test Screen` to verify initialization and ad callbacks.

See [the documentation index](docs/README.md) for platform-specific setup and export instructions.

## Runtime advertisement boundary

Gameplay code talks only to the shared GDScript API:

```gdscript
AdsManager.initialize()
AdsManager.load_rewarded()
AdsManager.show_rewarded()
AdsManager.load_interstitial()
AdsManager.show_interstitial()
AdsManager.show_banner()
AdsManager.hide_banner()
```

Android and iOS normalize their native callbacks into the same Godot signals. `RewardedAdHelper` and `AdFrequencyController` add reward settlement, cooldown, and suppression policy around that boundary.

Normal gameplay rewards never require an advertisement. A rewarded ad may grant an optional bonus, and a failed or unavailable interstitial never blocks continuation.

## Project layout

```text
addons/             Godot export plugin for Android native artifacts
android-plugin/     Kotlin LevelPlay Godot plugin and Gradle wrapper
config/             Tracked example config; ignored local config
core/               Bootstrap, navigation, overlays, popups, pause, safe area
debug/              Debug-only developer menu
docs/               Architecture, setup, build, and testing guides
gameplay_placeholder/ Replaceable example gameplay flow
ios-plugin/         Objective-C++ bridge and CocoaPods/SCons build files
ios/                Tracked iOS descriptor template; generated descriptor/binaries ignored
scenes/             Reusable shell and debug scenes
scripts/godot/      Shared advertisement manager and debug controller
services/           Persistence, settings, rewards, currency, session, ad policy
ui/                 Menu, settings, completion, and retry controllers
```

## Validation

Run the project validator without creating release artifacts:

```text
Windows:      scripts/validate_project.ps1
macOS/Linux: scripts/validate_project.sh
```

The validator checks the cross-platform configuration shape, export presets, required iOS support files, pinned native dependencies, and Godot parser state when a compatible editor is available.

Full device and release checklists are documented in [docs/testing.md](docs/testing.md).

## Credentials and generated files

Do not commit real app keys, ad unit IDs, SDK paths, signing material, store service files, generated AAR/XCFramework files, exported Xcode projects, APKs, AABs, or IPAs. The repository's `.gitignore` covers the expected local files, but always review `git status` before committing.

If a credential is committed accidentally, revoke or rotate it before rewriting Git history. Removing a secret from the latest commit does not remove it from earlier commits.

## Development transparency

AI-assisted coding and documentation tools were used during development. The maintainer remains responsible for reviewing, testing, licensing, and shipping every release. This repository does not include AI-generated visual or audio assets.

## License and third-party software

The original source code in this repository is licensed under the [MIT License](LICENSE).

Godot Engine, the Gradle wrapper, Unity LevelPlay, Unity Ads, mediation adapters, Google Play Services, and CocoaPods-resolved components retain their own licenses and terms. Native provider binaries are resolved during local builds and are not relicensed under this project's MIT License. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Contributing

Issues and focused pull requests are welcome. When reporting a platform problem, include the Godot version, operating system, target platform, export step, and sanitized logs. Never include dashboard keys, ad unit IDs, signing credentials, or personal device identifiers.
