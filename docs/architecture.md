# Architecture

```text
Bootstrap
   |
   v
Player-facing scenes  <---->  Core UI helpers
   |
   v
Reusable services: save, settings, rewards, currency, ads policy
   |
   +--> AdsManager (platform-neutral autoload)
             |
             +--> Android: LevelPlayAds Kotlin plugin -> Unity LevelPlay SDK
             |
             +--> iOS: LevelPlayAds Objective-C++ plugin -> Unity LevelPlay SDK
```

## Shared advertisement API

`AdsManager` exposes the stable calls used by gameplay:

```gdscript
AdsManager.initialize()
AdsManager.load_rewarded()
AdsManager.show_rewarded()
AdsManager.load_interstitial()
AdsManager.show_interstitial()
AdsManager.show_banner()
AdsManager.hide_banner()
```

The manager owns provider discovery, configuration loading, state mapping, and signals. Gameplay can subscribe to `sdk_initialized`, `ad_event`, and `reward_earned` without importing a provider SDK.

The shell does not call the provider directly. `RewardedAdHelper` grants optional bonuses exactly once after a reward callback. `AdFrequencyController` owns interstitial cooldown state and continues the flow safely when an ad is unavailable. The normal level reward is granted by `GameSession` and never requires an ad.

## Folder boundaries

- `core/`: reusable scene and UI infrastructure. It has no game-specific rules.
- `services/`: small autoloads for local state and policy. They use `user://` only and have no cloud/account dependency.
- `ui/`: reusable player-facing screens.
- `debug/`: developer-only tools, hidden from release builds with `OS.is_debug_build()`.
- `gameplay_placeholder/`: temporary flow proof. Game-specific content may replace this folder without changing the shell.
- `android-plugin/` and `addons/LevelPlayAds/`: Android provider integration and Gradle export packaging.
- `ios-plugin/` and `ios/plugins/LevelPlayAds/`: iOS provider source, build tooling, and the Godot `.gdip` descriptor template.

## Android boundary

`addons/LevelPlayAds/export_plugin.gd` packages the release/debug AAR and declares Maven dependencies during a Godot Android Gradle export. `android-plugin/levelplay` contains only native Android integration code. The Kotlin class creates ad objects after SDK initialization, registers listeners, and forwards normalized events to Godot signals.

## iOS boundary

`ios-plugin/src` implements the same methods and signals in Objective-C++. It initializes LevelPlay on the iOS main thread, creates ad objects after a successful initialization, reloads full-screen ads after close, and anchors adaptive banners to the active view controller's safe area. The iOS build creates the `.gdip` file from its tracked template so the singleton is available only when its XCFrameworks exist; CocoaPods adds LevelPlay and the Unity Ads adapter to the exported Xcode workspace.

## Deliberate boundaries

There is no genre-specific gameplay mechanic, shop, IAP, analytics, remote config, cloud save, achievement, leaderboard, or localization system in the current shell.
