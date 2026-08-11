# Reusable mobile shell

The project provides a small, genre-neutral shell. It is intentionally not a framework and contains no game mechanic.

## Structure

| Area | Responsibility |
| --- | --- |
| `core/` | Bootstrap, scene transitions, loading overlay, safe area, pause menu, popup dialogs, shared styling |
| `services/` | Local save/settings, audio, haptics, currency, reward transactions, ad policy, session state |
| `ui/` | Main menu, settings, complete, and failure/retry screens |
| `debug/` | Developer-only utilities and ad test entry point |
| `gameplay_placeholder/` | Temporary timer/buttons used to prove the flow |

## Generic flow

```text
Bootstrap -> Main Menu -> Gameplay Placeholder
                         |       |
                         |       +-> Pause -> Resume / Settings / Main Menu
                         v
                   Complete or Failure
                         |
                         +-> Optional reward -> Continue / Retry / Main Menu
```

The normal complete reward is local and immediate. A rewarded ad is only an optional multiplier. Interstitials are considered only after gameplay, respect the saved cooldown, and are skipped safely when unavailable.

## Starting a real game

Replace `gameplay_placeholder/` and its scene with gameplay-specific code when adding a real game. Keep the reusable services and UI contracts intact:

- Call `GameSession.begin_level()` when a level starts.
- Call `GameSession.complete_level()` or `GameSession.fail_level()` once.
- Use `SceneTransitionManager` for scene changes.
- Use `RewardService`/`SoftCurrencyService` for local rewards and currency.
- Use `RewardedAdHelper` for optional rewarded bonuses.
- Keep provider calls behind `AdsManager`.

The first real game should add its own folder and scenes rather than teaching the shell about a particular genre.
