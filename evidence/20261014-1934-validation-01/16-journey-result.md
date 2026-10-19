# Corrected Journey result — 20261014-1934-validation-01

- Frozen script: `NewsBulletin/journeys/leak_reproduction.xml`, SHA256 `814BC3F3C7D0705AB358AE6AE413379ACB69A0003603FF1972C261C30A503363`.
- Corrected debug APK: SHA256 `FC7E7DC094EB898EF44DA893227723E45BF94A7843E507175531172DA265A524`.
- Device: `Pixel_6a`, AVD android-36.1, device API 36, `emulator-5554`, 1080x2400. Notification permission already granted from recorded stage 4 setup.
- Reset: force-stop, Logcat clear, then `android run --apks=app/build/outputs/apk/debug/app-debug.apk --activity=HomeActivity --device=emulator-5554`.
- Evaluation: Android CLI `layout --no-idle` and `screen capture`; `adb shell input` for taps and Back. Each XML action was evaluated in order. All screenshots below were visually inspected.

| XML actions | Observed result | Evidence |
| --- | --- | --- |
| 1: initial Home | Three article titles visible | `02-initial-home.json` |
| 2–7: passage one | First article opened with updates off; Follow displayed `Following updates for this article.`; Home list visible after Back | `03-p1-article.json`, `03-p1-article.png`, `04-p1-follow.json`, `04-p1-follow.png`, `05-p1-home.json`, `05-p1-home.png` |
| 8–13: passage two | Same article and Follow status verified; Home list visible after Back | `06-p2-article.json`, `06-p2-article.png`, `07-p2-follow.json`, `07-p2-follow.png`, `08-p2-home.json`, `08-p2-home.png` |
| 14–19: passage three | Same article and Follow status verified; Home list visible after Back | `09-p3-article.json`, `09-p3-article.png`, `10-p3-follow.json`, `10-p3-follow.png`, `11-p3-home.json`, `11-p3-home.png` |
| 20–23: About and return | About title visible; final Home list visible | `12-about.json`, `12-about.png`, `13-final-home.json`, `13-final-home.png` |

**Observed UI result:** 23 of 23 actions/checks passed. `LeakStudy` from PID 20888 confirms `updateDelivered` after each Follow tap, then `listenerUnregistered listenerCount=0` at each Article destruction. This UI result alone does not establish the post-fix memory outcome; see the Logcat analysis record.
