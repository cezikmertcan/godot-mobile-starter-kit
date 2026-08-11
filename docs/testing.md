# Testing process

## Automated and lightweight checks

Run these during development:

```text
Godot diagnostics: scripts/validate_project.ps1 or scripts/validate_project.sh
Android AAR:       scripts/build_plugin.ps1 or scripts/build_plugin.sh
iOS XCFramework:   scripts/build_ios_plugin.sh (macOS)
```

Run the validator during development to catch static configuration and parser/type errors. Before a release, also start the Bootstrap scene and complete the shell and device checklists below. Do not install through ADB or deploy from repository scripts.

## Shell flow checklist

In a debug run:

1. Bootstrap opens the Main Menu.
2. Start Placeholder Level opens the gameplay placeholder.
3. Complete and Failed each reach the matching result screen.
4. Pause can resume, open Settings, or return to Main Menu.
5. Settings toggles sound, music, and vibration and survives a restart.
6. Complete grants the normal local currency reward without an ad.
7. The optional rewarded bonus is disabled safely when the provider is unavailable and cannot be claimed twice for one transaction.
8. Continue applies interstitial cooldown state and continues even when no fill/not-ready is returned.
9. Developer Tools is visible only in debug builds and can reset the local save.

## LevelPlay debug checklist

From Main Menu -> Developer Tools -> Open LevelPlay Ad Test Screen:

1. Initialize SDK.
2. Load and show rewarded.
3. Load and show interstitial.
4. Show and hide banner.
5. Clear the event log.

Run the same checklist on each supported platform. Confirm the status panel reports platform, provider, SDK, rewarded, interstitial, and banner state changes. The log should contain callbacks for load, display, close, failure, and reward events where the configured test inventory supports them.

## Evidence recorded for the current shell

- Godot project diagnostics: pass; no parse errors or type issues.
- Bootstrap runtime verification: pass; ran for about 8 seconds with no errors or warnings.
- New shell scenes: all seven `.tscn` files validated successfully.
- Android native plugin: the LevelPlay AAR build completed with the Unity Ads adapter and runtime dependencies.
- iOS native plugin: debug/release device and universal simulator XCFramework compilation passed against Godot 4.7.1 and the pinned LevelPlay headers.
- Device verification: Android tests and ad callbacks were completed successfully. iOS delivery still requires a maintainer-signed physical-device run with real dashboard identifiers.
