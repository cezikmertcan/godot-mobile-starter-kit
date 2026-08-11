# macOS setup

1. Install Godot 4.7.x and its Android/iOS export templates.
2. For Android, install Android Studio, Android SDK Platform 35, Build Tools, and JDK 17, then configure Godot's Android SDK path locally.
3. For iOS, install current Xcode command-line tools, CocoaPods, SCons, and the matching Godot 4.7.x source tree.
4. From the repository root, make the scripts executable once if needed: `chmod +x scripts/*.sh`.
5. Run `scripts/build_plugin.sh` for Android or follow `ios-setup.md` for iOS.
6. Use the matching Godot export preset. Run `scripts/build_final_apk.sh` only for an Android milestone build.

The scripts derive the project root from the script location and use POSIX paths. No macOS-specific absolute path is required.

The shared Godot code uses `res://` and `user://` paths only. Keep `config/levelplay_config.json`, SDK paths, Apple team/signing data, and Android signing credentials local to the Mac.
