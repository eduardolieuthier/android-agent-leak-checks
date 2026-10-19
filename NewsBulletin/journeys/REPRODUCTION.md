# News Bulletin reproduction protocol

Use `Pixel_6a` (`emulator-5554`, AVD API 36.1, device API property 36, 1080×2400) and the debug APK. Keep this emulator, variant, reset method, Journey XML, and article choice unchanged for baseline and corrected runs.

On a fresh install, Android may show a one-time notification permission prompt from LeakCanary. Grant it before the measured run and record the intervention. Confirm that no system dialog covers Home before starting the Journey. This setup action is outside the XML actions and must be identical for baseline and corrected runs.

From the repository root, run these commands in order before each measured run:

```powershell
$adbExe = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
& $adbExe -s emulator-5554 shell am force-stop com.example.newsbulletin
& $adbExe -s emulator-5554 logcat -c
Set-Location NewsBulletin
android run --apks=app/build/outputs/apk/debug/app-debug.apk --activity=HomeActivity --device=emulator-5554
```

Follow [leak_reproduction.xml](leak_reproduction.xml) one action at a time. For each of its three passages, open **Community garden opens**, tap **Follow updates**, press Back, and verify that all three article titles are visible on Home. After passage three, open About and return to Home. Use `android layout --device=emulator-5554 --pretty` to inspect each state and `adb shell input` to tap the center coordinates returned by the current layout. Capture screenshots of the Article screen, the status after Follow updates, and the returned Home screen for every passage.

The Journey checks UI behavior only. Collect and interpret the LeakCanary reference chain separately in the diagnostic stage. Save each run's layout, screenshots, Logcat and result report under one `run_id`.
