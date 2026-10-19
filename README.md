# Android memory leak investigation with agents

News Bulletin is a small offline Android app used to reproduce an intentional `ArticleActivity` listener leak and validate a reviewed lifecycle correction. The repository history has two source states: tag `baseline-leak` contains the leak, and `main` contains the correction. This repository has a new history; commit IDs quoted inside archived reports identify the **original local experiment only** and are not checkout commands here.

## Observed result

The three-passage UI test reached its final assertion in both states. On the baseline, LeakCanary 2.14 reported `1 APPLICATION LEAKS` and an assertion failure through `NewsBulletinApplication.updateRegistry → UpdateRegistry.listeners → ArticleUpdateListener.this$0 → destroyed ArticleActivity`. On the correction, the same assertion passed with `No watched objects after triggering an explicit GC.` Follow updates was delivered in all three passages, and the listener count returned to zero after each Activity destruction. The result applies to this tested flow; the original automatic post-fix collection did not produce a heap analysis and is recorded separately.

## Reproduce both states

Use a Windows host with Git, JDK 17, Android SDK platform 36 and platform-tools, Gradle dependency access for the first build, and a `Pixel_6a` AVD at Android API 36 (`emulator-5554`, 1080×2400) to match the recorded experiment. The checked-in wrapper uses Gradle 9.1.0; the project uses AGP 9.0.1. The exact [Journey XML](NewsBulletin/journeys/leak_reproduction.xml) and [reproduction protocol](NewsBulletin/journeys/REPRODUCTION.md) apply to both states. The baseline intentionally retains the listener, so its test should fail at the LeakCanary assertion with the known reference chain. A build or device failure is not a positive control.

Start the `Pixel_6a` AVD, wait for it to finish booting, and ensure it is the only connected test device. Run both states with the same emulator, debug variant, first article, and three explicitly spelled-out passages. Before **each** instrumented run, force-stop the app and clear device Logcat; the commands below do both. On a fresh install, grant the one-time LeakCanary notification permission before the measured Journey if prompted, record that intervention, and use the same preparation for both states. The [Journey protocol](NewsBulletin/journeys/REPRODUCTION.md) covers the separate agent-driven UI run.

Run the following from the repository root in PowerShell. It creates two new directories under `evidence/`, copies each run's fresh JUnit XML before switching source states, and saves selected LeakCanary, app, and test-runner Logcat from each run. Keep these new results separate from the historical evidence already in this repository.

```powershell
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
$adbExe = Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe'
$device = 'emulator-5554'
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$baselineEvidence = Join-Path (Get-Location) "evidence/reproduction-$runId-baseline"
$correctedEvidence = Join-Path (Get-Location) "evidence/reproduction-$runId-corrected"
if ((Test-Path $baselineEvidence) -or (Test-Path $correctedEvidence)) {
    throw 'Evidence directory already exists; choose a new run ID.'
}
New-Item -ItemType Directory -Path $baselineEvidence, $correctedEvidence | Out-Null

& $adbExe devices -l
if ((& $adbExe -s $device get-state).Trim() -ne 'device' -or
    (& $adbExe -s $device shell getprop sys.boot_completed).Trim() -ne '1') {
    throw 'Start the emulator and wait for it to finish booting.'
}

function Invoke-InstrumentedRun($evidenceDir) {
    & $adbExe -s $device shell am force-stop com.example.newsbulletin
    if ($LASTEXITCODE -ne 0) { throw 'Device preparation failed.' }
    & $adbExe -s $device logcat -c
    if ($LASTEXITCODE -ne 0) { throw 'Could not clear device Logcat.' }

    $started = Get-Date
    Push-Location NewsBulletin
    try {
        $gradleLog = Join-Path $evidenceDir 'gradle-output.txt'
        & .\gradlew.bat :app:connectedDebugAndroidTest --console=plain *> $gradleLog
        $gradleExit = $LASTEXITCODE
    } finally { Pop-Location }

    & $adbExe -s $device logcat -d -v threadtime -s 'LeakCanary:D' 'LeakStudy:D' 'TestRunner:D' '*:S' |
        Set-Content -Encoding utf8 (Join-Path $evidenceDir 'selected-logcat.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Could not save device Logcat.' }

    $reportDir = 'NewsBulletin/app/build/outputs/androidTest-results/connected/debug'
    $reports = @(Get-ChildItem $reportDir -Filter '*.xml' -Recurse -File |
        Where-Object { $_.LastWriteTime -ge $started })
    if ($reports.Count -eq 0) {
        throw "No fresh JUnit XML was produced. Gradle exit code: $gradleExit. Inspect the build/device failure."
    }
    $junitDir = Join-Path $evidenceDir 'junit'
    New-Item -ItemType Directory -Path $junitDir | Out-Null
    $reports | Copy-Item -Destination $junitDir
    return $gradleExit
}

git switch --detach baseline-leak
if ($LASTEXITCODE -ne 0) { throw 'Could not switch to baseline-leak.' }
$baselineExit = Invoke-InstrumentedRun $baselineEvidence
$baselineText = (Get-ChildItem (Join-Path $baselineEvidence 'junit') -Filter '*.xml' |
    ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
if ($baselineExit -eq 0 -or $baselineText -notmatch 'NoLeakAssertionFailedError' -or
    $baselineText -notmatch '1 APPLICATION LEAKS') {
    throw 'Baseline did not show the expected LeakCanary assertion failure. Inspect its JUnit XML and Logcat before continuing.'
}

git switch main
if ($LASTEXITCODE -ne 0) { throw 'Could not switch to main.' }
$correctedExit = Invoke-InstrumentedRun $correctedEvidence
if ($correctedExit -ne 0) {
    throw 'Corrected run failed. Inspect its JUnit XML and Logcat.'
}
Write-Host "Baseline evidence: $baselineEvidence"
Write-Host "Corrected evidence: $correctedEvidence"
```

The baseline's nonzero Gradle exit is expected **only** when its fresh JUnit XML contains the `NoLeakAssertionFailedError` and `1 APPLICATION LEAKS` result. A build, installation, device, or missing-report failure does not confirm the leak; resolve it before running the correction. The corrected run should finish successfully. The [instrumented test](NewsBulletin/app/src/androidTest/java/com/example/newsbulletin/LeakReproductionInstrumentationTest.kt) performs all three passages, checks the live update status and Home titles, visits About, then invokes `LeakAssertions.assertNoLeaks()`. For the agent-driven Journey, build the debug APK and follow the XML one action at a time using Android CLI layout/screenshots and adb input as described in the protocol. The Android CLI version installed during the original run did not expose a Journey execution subcommand, so the agent performed those actions individually. The [Android CLI overview](https://developer.android.com/tools/agents) and [Journeys guidance](https://developer.android.com/tools/agents/android-cli/journeys) describe the current tool and workflow.

## Evidence

| Question | Reviewed evidence |
| --- | --- |
| What was the known reference chain? | [Diagnosis](evidence/20261014-1917-diagnosis-01/17-diagnosis.md), [filtered diagnostic Logcat](evidence/20261014-1917-diagnosis-01/15-leak-tags-logcat.txt) |
| Did the UI flow work? | [Baseline Journey](evidence/20261014-1917-diagnosis-01/16-journey-result.md), [corrected Journey](evidence/20261014-1934-validation-01/16-journey-result.md), [reviewed screenshot](evidence/20261014-1934-validation-01/04-p1-follow.png) |
| What changed? | [Correction review](evidence/20261014-1930-fix-01/01-correction-review.md), [source diff](evidence/20261014-1930-fix-01/02-article-activity.diff), [build result](evidence/20261014-1930-fix-01/04-build-retry.txt) |
| What did the explicit assertion report? | [Baseline JUnit XML](evidence/20261014-1952-instrumented-01/03-baseline-test-result.xml), [corrected JUnit XML](evidence/20261014-1952-instrumented-01/07-corrected-test-result.xml), [baseline selected Logcat](evidence/20261014-1952-instrumented-01/baseline-selected-logcat.txt), [corrected selected Logcat](evidence/20261014-1952-instrumented-01/corrected-selected-logcat.txt) |
| Did it repeat? | [Round 3 result and limits](benchmarks/rodada-03-repeticao/20261015-1614-round03-01-resultado.md) |

The [automatic post-fix assessment](evidence/20261014-1934-validation-01/19-postfix-assessment.md) is inconclusive on its own. The later instrumented assertion is a separate validation method. Rounds 2 and 3 repeated the outcome, but emulator state, caches, and runtime grants were not fully controlled. No speed or token savings are inferred. Android Studio Profiler and Gemini's Fix with Agent were outside this experiment; CI has not been implemented.

See [publication sanitization notes](PUBLICATION_NOTES.md) for the selection, historical commit mapping, and limits of the publication copy. 

## License

This project's original code and documentation are available under the [MIT License](LICENSE). Third-party components remain subject to their respective licenses and notices.

## Official references

- [Android CLI](https://developer.android.com/tools/agents)
- [Journeys with Android CLI](https://developer.android.com/tools/agents/android-cli/journeys)
- [LeakCanary](https://square.github.io/leakcanary/)
- [LeakCanary leak detection in UI tests](https://square.github.io/leakcanary/ui-tests/)
