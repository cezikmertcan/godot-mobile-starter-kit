# Documentation

Use these documents in order:

1. [Architecture](architecture.md)
2. [Reusable shell](reusable-shell.md)
3. [Android setup](android-setup.md)
4. [iOS setup](ios-setup.md)
5. [Windows setup](windows-setup.md) or [macOS setup](macos-setup.md)
6. [LevelPlay configuration](levelplay.md)
7. [Build process](build.md)
8. [Testing process](testing.md)

The native providers are isolated in `android-plugin/` and `ios-plugin/`. Godot gameplay code talks to the `AdsManager` autoload and shell services; it does not import LevelPlay classes.

When adding a first real game, replace the placeholder gameplay scene while keeping the shared shell contracts and services intact.
