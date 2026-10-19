# Correction review — 20261014-1930-fix-01

## Evidence considered

The stage 5 LeakCanary trace follows `NewsBulletinApplication.updateRegistry` → `UpdateRegistry.listeners` → an anonymous `ArticleUpdateListener` → its `this$0` reference → a destroyed `ArticleActivity`. The same run logged three listener registrations and a count of three after the third `ArticleActivity.onDestroy()`.

## Proposed change

Keep registration on the first **Follow updates** tap. In `ArticleActivity.onDestroy()`, pass the existing `articleUpdateListener` instance to `UpdateRegistry.unregister`, log the resulting listener count and clear the Activity field. Use `onDestroy()` because the baseline retains the listener after that callback and because this is the lifecycle boundary identified by LeakCanary; `Follow updates` remains functional until the Activity is destroyed. The registry's existing `unregister` removes the instance from its `LinkedHashSet`.

The app's three screens, strings, button behavior, Journey actions, APK variant and emulator configuration stay the same. This source correction is intended to break the observed retention path; stage 7 must test whether it actually does so. No post-fix memory result is available during stage 6.

## Review after editing

- `ArticleActivity.kt:34–35` still stores and registers the listener created for the first Follow tap.
- `ArticleActivity.kt:43–47` takes that field, passes the same instance to `UpdateRegistry.unregister` before `super.onDestroy()`, logs the count, and clears the field. `UpdateRegistry.kt:14–15` removes the instance from the set.
- The code diff changes only `ArticleActivity.kt`; no layout, UI string, Journey or registry implementation changed. The frozen Journey SHA256 remained `814BC3F3C7D0705AB358AE6AE413379ACB69A0003603FF1972C261C30A503363`.
- The first sandbox build failed before compilation because network access to the Gradle distribution was denied. The approved retry completed `:app:assembleDebug` with `BUILD SUCCESSFUL in 8s`; corrected APK SHA256 `FC7E7DC094EB898EF44DA893227723E45BF94A7843E507175531172DA265A524`.
- Static review supports that the code removes the observed registry reference at destruction. Whether the same Journey avoids retaining the destroyed Activity and still delivers updates is unobserved and belongs to stage 7.
