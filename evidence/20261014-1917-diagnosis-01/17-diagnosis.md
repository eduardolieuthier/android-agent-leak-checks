# Baseline LeakCanary diagnosis — 20261014-1917-diagnosis-01

## Collection

After the unchanged three-passage Journey completed, the agent ran:

```text
adb -s emulator-5554 logcat -d -v threadtime
```

The complete command output was archived locally as `14-full-logcat.txt` and is not in this public selection. All `LeakCanary` and `LeakStudy` lines are in `15-leak-tags-logcat.txt` for inspection. The result appeared without placing the app in the background. LeakCanary says: `Heap dump reason: 6 retained objects, app is visible` and `Analysis duration: 12079 ms`.

## Observed result

At device Logcat time `10-14 22:25:02.238`, PID 20149, LeakCanary 2.14 reported `HEAP ANALYSIS RESULT` and `1 APPLICATION LEAKS`. It reported 595931 bytes retained by leaking objects and displayed one leak trace out of three with the same signature. The displayed `ArticleActivity` retained 199.2 kB in 1176 objects; it had received `onDestroy()` and `mDestroyed` was true.

The displayed strong-reference path is:

```text
GC Root: System class
→ FontsContract.sContext
→ NewsBulletinApplication.updateRegistry
→ UpdateRegistry.listeners
→ LinkedHashSet[element()]
→ ArticleActivity$onCreate$1$listener$1.this$0
→ ArticleActivity (mDestroyed = true; Leaking: YES)
```

The code point is the anonymous `ArticleUpdateListener` constructed in `ArticleActivity.kt:28`, registered with the application-scoped registry at `ArticleActivity.kt:35`. `UpdateRegistry.kt:8` holds it in `listeners`. The intentional baseline `ArticleActivity.onDestroy()` at `ArticleActivity.kt:42–48` omits `unregister` and logs `listenerIntentionallyRetained`. The `LeakStudy` lines for the same PID show listener counts 1, 2 and 3 after the three Back actions, with count 3 at the third `onDestroy`.

This diagnosis is based on the LeakCanary reference chain and the matching app events, not on a memory graph. The trace establishes retention of the destroyed Activity through this path in this run. The trace does not by itself evaluate a correction.

## Environment and identifiers

- `Pixel_6a`, AVD android-36.1, device API 36, 1080x2400, `emulator-5554`.
- Debug app with intentional leak; Git HEAD `a64351ba88f86e0523e5fe4b01636d82cb489d71`; APK SHA256 `A42AB68A41E873D1E8BA62B19E494D28C578827C4F73174D0E70BA8FEA049D0B`.
- Frozen Journey SHA256 `814BC3F3C7D0705AB358AE6AE413379ACB69A0003603FF1972C261C30A503363`.
- `LeakCanary` version 2.14 (reported in trace). The original local archive retains the full environment verification in `01-environment.txt`.
