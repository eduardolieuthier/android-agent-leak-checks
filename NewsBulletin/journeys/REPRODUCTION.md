# News Bulletin reproduction protocol

The recorded environment used a Pixel_6a AVD identified as android-36.1; the device reported SDK_INT 36. Emulator serials and SDK paths may differ on another machine. For comparable baseline and corrected agent-driven Journey runs, use the same emulator, debug variant, reset method, [Journey XML](leak_reproduction.xml), and first article. The separate instrumented test is run by [reproduce-memory-checks.ps1](../../scripts/reproduce-memory-checks.ps1).

For the **agent-driven Journey**, Android may show a one-time notification permission prompt from LeakCanary on a fresh install. Grant it before the measured Journey, record the intervention, and confirm that no system dialog covers Home. This setup action is outside the XML actions. Runtime permission grants during historical instrumented runs were not independently captured; do not describe their starting conditions as fully identical.

**PowerShell commands in a terminal** from the repository root before each measured agent-driven Journey (set `ANDROID_HOME` to your SDK and adjust the serial for your machine):

```powershell
$adbExe = Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
& $adbExe -s emulator-5554 shell am force-stop com.example.newsbulletin
& $adbExe -s emulator-5554 logcat -c
Set-Location NewsBulletin
.\gradlew.bat :app:assembleDebug --console=plain
android run --apks=app/build/outputs/apk/debug/app-debug.apk --activity=HomeActivity --device=emulator-5554
```

Follow the [Journey XML](leak_reproduction.xml) one action at a time. For each of its three passages, open **Community garden opens**, tap **Follow updates**, press Back, and verify that all three article titles are visible on Home. After passage three, open About and return to Home. Use `android layout --device=emulator-5554 --pretty` to inspect each state and `adb shell input` to tap the center coordinates returned by the current layout. Capture screenshots of the Article screen, the status after Follow updates, and the returned Home screen for every passage.

The Journey checks UI behavior only. Collect and interpret the LeakCanary reference chain separately in the diagnostic stage. Save each run's layout, screenshots, Logcat, and result report under one `run_id`. A missing diagnostic trace is inconclusive, and build, installation, or device failures do not establish a leak. Preserve archived evidence, save new runs separately, and make no application changes during reproduction.
