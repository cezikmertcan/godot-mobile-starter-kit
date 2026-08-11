# Unity LevelPlay configuration

Gameplay uses one normalized `AdsManager` API while each platform owns its native provider:

- Android: LevelPlay SDK `9.5.0`, Unity Ads adapter `5.11.0`, Unity Ads SDK `4.19.0`.
- iOS: LevelPlay pod `9.5.0.0`, Unity Ads adapter pod `5.8.0.0` (resolving Unity Ads `4.18.1`).

Keep Android versions synchronized between `android-plugin/levelplay/build.gradle.kts` and `addons/LevelPlayAds/export_plugin.gd`. Keep iOS versions synchronized between `ios-plugin/Podfile` and `ios-plugin/ExportPodfile.template`.

## Local configuration

Copy `config/levelplay_config.example.json` to the ignored `config/levelplay_config.json`. The file has separate `android` and `ios` objects; each contains:

- `app_key`;
- rewarded, interstitial, and banner ad unit IDs;
- optional `banner_placement`;
- optional `enable_test_suite` for integration checks.

Use platform-specific dashboard values. Never commit a real app key or ad unit ID. The runtime reads only the object matching the exported platform.

## Dashboard checklist

1. Register separate Android and iOS apps in the Unity LevelPlay dashboard.
2. Create rewarded, interstitial, and banner ad units for each app.
3. Enable the mediation networks/adapters required by the account.
4. Copy each platform's values into its local config section.
5. Configure mediation groups and test devices in the dashboard.
6. Test only with test mode, the LevelPlay test suite, or approved test devices.
7. Treat `Mediation No Fill (509)` as an inventory/dashboard condition first; newly created apps and ad units can need propagation time.

Both native bridges create ad objects only after initialization succeeds, check readiness before full-screen shows, reload rewarded/interstitial ads after close, and forward the same Godot signals. Banners are attached to the Android content view or the iOS safe area.

For iOS privacy, gather any required consent before SDK initialization and add `NSUserTrackingUsageDescription` only if the app actually requests App Tracking Transparency authorization. Review every enabled mediation network's current privacy and SKAdNetwork requirements before release.

Official references:

- [LevelPlay Android SDK integration](https://docs.unity.com/en-us/grow/levelplay/sdk/android/sdk-integration)
- [LevelPlay iOS SDK integration](https://docs.unity.com/en-us/grow/levelplay/sdk/ios/sdk-integration)
- [LevelPlay iOS rewarded ads](https://docs.unity.com/en-us/grow/levelplay/sdk/ios/rewarded-ads-integration)
- [LevelPlay iOS interstitial ads](https://docs.unity.com/en-us/grow/levelplay/sdk/ios/interstitial-integration)
- [LevelPlay iOS banner ads](https://docs.unity.com/en-us/grow/levelplay/sdk/ios/banner-integration)
- [Godot Android plugins](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html)
- [Godot iOS plugins](https://docs.godotengine.org/en/stable/tutorials/platform/ios/ios_plugin.html)
