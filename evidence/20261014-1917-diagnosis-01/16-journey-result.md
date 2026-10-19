# Journey result — 20261014-1917-diagnosis-01

- Script: `NewsBulletin/journeys/leak_reproduction.xml` (SHA256 `814BC3F3C7D0705AB358AE6AE413379ACB69A0003603FF1972C261C30A503363`), unchanged from stage 4.
- Device: `Pixel_6a`, Android API 36, `emulator-5554`, 1080x2400.
- App: unchanged intentional-leak debug APK (SHA256 `A42AB68A41E873D1E8BA62B19E494D28C578827C4F73174D0E70BA8FEA049D0B`).
- Reset: `adb -s emulator-5554 shell am force-stop com.example.newsbulletin`; `adb -s emulator-5554 logcat -c`; `android run --apks=app/build/outputs/apk/debug/app-debug.apk --activity=HomeActivity --device=emulator-5554`.
- Evaluation: Android CLI `layout --no-idle` and `screen capture`, with `adb shell input` for taps and Back. This Android CLI version has no Journey runner. Each XML action was evaluated in order.

| XML actions | Observed result | Evidence |
| --- | --- | --- |
| 1: initial Home | Three article titles visible | `02-initial-home.json` |
| 2–7: passage one | First article opened; Follow status visible; Home list visible after Back | `03-p1-article.json`, `04-p1-follow.json`, `04-p1-follow.png`, `05-p1-home.json` |
| 8–13: passage two | Same article opened; Follow status visible; Home list visible after Back | `06-p2-article.json`, `07-p2-follow.json`, `08-p2-home.json` |
| 14–19: passage three | Same article opened; Follow status visible; Home list visible after Back | `09-p3-article.json`, `10-p3-follow.json`, `11-p3-home.json` |
| 20–23: About and return | About title visible; final Home list visible | `12-about.json`, `13-final-home.json`, `13-final-home.png` |

**Result:** 23 of 23 specified actions/checks passed. The two screenshots were visually inspected. No dialog blocked this run; the notification permission had been granted and recorded during stage 4. The LeakCanary result is recorded separately in `17-diagnosis.md` and the Logcat artifacts.
