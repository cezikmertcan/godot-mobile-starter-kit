# Third-party notices

The MIT License in this repository applies to the original project source and assets authored for Godot Mobile Starter Kit. It does not relicense third-party engines, SDKs, build tools, adapters, or transitive dependencies.

## Godot Engine

This project is designed for Godot Engine 4.7.x; the native Android integration currently pins `org.godotengine:godot:4.7.1.stable`. Godot Engine is distributed under the MIT License:

- https://godotengine.org/license/

Godot Engine binaries and export templates are installed separately and are not included in this repository. Applications exported with Godot must preserve the notices required by the engine and its bundled third-party components.

## Gradle Wrapper

`android-plugin/gradlew`, `android-plugin/gradlew.bat`, and `android-plugin/gradle/wrapper/gradle-wrapper.jar` are Gradle 8.14.3 Wrapper files distributed under the Apache License 2.0:

- https://github.com/gradle/gradle/blob/master/LICENSE

The wrapper JAR contains its license at `META-INF/LICENSE`. The wrapper downloads the pinned Gradle distribution from `services.gradle.org` when used.

The committed Gradle 8.14.3 wrapper JAR is verified against Gradle's published SHA-256 checksum: `7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172`. The distribution ZIP has its separate official checksum in `gradle-wrapper.properties`.

## Unity LevelPlay, Unity Ads, and mediation adapters

The Android and iOS build definitions resolve Unity LevelPlay, Unity Ads, and the Unity Ads mediation adapter from their official package repositories. Their binaries are not stored in this source repository and are not covered by this project's MIT License.

Pinned direct package versions:

- Android: Unity LevelPlay mediation SDK `9.5.0`, Unity Ads adapter `5.11.0`, and Unity Ads runtime `4.19.0`.
- iOS: IronSource/Unity LevelPlay SDK `9.5.0.0` and IronSource Unity Ads adapter `5.8.0.0`.

Use of these products is governed by Unity's applicable documentation, licenses, policies, and service terms, including:

- https://docs.unity.com/en-us/grow/levelplay
- https://docs.unity.com/en-us/grow/levelplay/platform/legal-resources
- https://unity.com/legal/one-operate-services-terms-of-service

Anyone shipping an application is responsible for reviewing the current terms, privacy requirements, consent obligations, enabled mediation-network terms, and store disclosures for that application.

## Google Play Services

The Android plugin resolves selected Google Play Services libraries through Gradle. Those artifacts retain their own notices and terms:

- App Set `16.0.0`
- Ads Identifier `18.1.0`
- Basement `18.1.0`

- https://developers.google.com/android/guides/overview
- https://developers.google.com/terms

## CocoaPods dependencies

The iOS build uses CocoaPods to resolve native SDKs locally. Direct pod versions are pinned above; transitive dependencies are resolved when the native plugin or exported Xcode project is prepared. Pod metadata and generated acknowledgements identify the licenses shipped by each resolved version. Review the generated dependency notices before distributing an iOS application.

## Project media

This repository intentionally contains no third-party character, animation, music, sound-effect, or stock-art packages. The project icon and UI graphics in the repository are original project assets covered by the project's MIT License.
