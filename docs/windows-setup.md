# Windows setup

1. Install Godot 4.7.x, Android Studio, Android SDK Platform 35, Build Tools, and JDK 17.
2. Set the Android SDK and Java paths through Godot Editor Settings or the machine's normal developer tooling. Do not add them to the repository.
3. Open PowerShell at the repository root.
4. Run `scripts/build_plugin.ps1`.
5. Use the Godot Android export preset, then run `scripts/build_final_apk.ps1` only when the milestone is complete.

The scripts resolve paths from their own location, so the repository can move between drives and machines. They use a repository-local Gradle wrapper when available and otherwise use a `gradle` executable on `PATH`.

The shared Godot code uses `res://` and `user://` paths only. Keep `config/levelplay_config.json`, SDK paths, and signing credentials local to the Windows machine.
