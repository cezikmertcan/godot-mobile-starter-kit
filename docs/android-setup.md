# Android setup

Install the following locally:

- Godot 4.7.x and the matching Android export templates.
- Android Studio with Android SDK Platform 35 and Android Build Tools.
- JDK 17.
- Gradle 8.14.3, or let the project Gradle wrapper provide it when present.

Do not commit SDK paths, keystores, certificates, or app keys. Configure the Android SDK path in Godot Editor Settings on each machine.

The repository is portable by design: the Android plugin uses its Gradle wrapper and the Godot export uses local editor settings. No absolute Windows or macOS SDK path belongs in source control.

## Godot plugin flow

1. Open the repository in Godot.
2. Confirm `LevelPlayAds` is enabled under Project Settings → Plugins.
3. Install the Android Gradle build template from Project → Install Android Build Template.
4. Keep the Android export preset's Gradle build option enabled.
5. Build the native plugin before exporting the game:

   - Windows: `scripts/build_plugin.ps1`
   - macOS/Linux: `scripts/build_plugin.sh`

The build copies `LevelPlayAds-debug.aar` and `LevelPlayAds-release.aar` into the Godot add-on's ignored binary folders. These are local build artifacts, not source files.

The Unity Ads adapter/runtime are resolved through Gradle; the repository does not vendor provider binaries.

Use the `android` object in `config/levelplay_config.json`. Android and iOS credentials are intentionally kept in separate platform objects.

## Android package identity

The sample preset uses `com.example.godotmobilestarter`. Change it to the final package name before publishing. A package name is not a secret, but it must remain stable once the app is registered in Google Play and LevelPlay.
