# Android memory leak investigation with agents

News Bulletin is a small offline Android app used to reproduce an intentional `ArticleActivity` listener leak and validate a reviewed lifecycle correction. The public history has two source states: tag `baseline-leak` contains the leak, and `main` contains the correction. This repository has a new history; commit IDs quoted inside archived reports identify the **original local experiment only** and are not checkout commands here.

## Observed result

The three-passage UI test reached its final assertion in both states. On the baseline, LeakCanary 2.14 reported `1 APPLICATION LEAKS` and an assertion failure through `NewsBulletinApplication.updateRegistry → UpdateRegistry.listeners → ArticleUpdateListener.this$0 → destroyed ArticleActivity`. On the correction, the same assertion passed with `No watched objects after triggering an explicit GC.` Follow updates was delivered in all three passages, and the listener count returned to zero after each Activity destruction. The result applies to this tested flow; the original automatic post-fix collection did not produce a heap analysis and is recorded separately.

## Reproduce both states

Use a Windows host with Git, JDK 17, Android SDK platform 36 and platform-tools, Gradle dependency access for the first build, and a `Pixel_6a` AVD at Android API 36 (`emulator-5554`, 1080×2400) to match the recorded experiment. The checked-in wrapper uses Gradle 9.1.0; the project uses AGP 9.0.1. The exact [Journey XML](NewsBulletin/journeys/leak_reproduction.xml) and [reproduction protocol](NewsBulletin/journeys/REPRODUCTION.md) apply to both states. The baseline intentionally retains the listener, so its test should fail at the LeakCanary assertion with the known reference chain. A build or device failure is not a positive control.

Run each state separately from a clean app process. The original measurement used the same emulator, debug variant, first article, and three explicitly spelled-out passages before and after the fix. Grant the one-time LeakCanary notification permission before the measured Journey if prompted; record any intervention. Keep that preparation the same in both states.

```powershell
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
$adbExe = Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe'
& $adbExe devices -l
git switch --detach baseline-leak
Set-Location NewsBulletin
.\gradlew.bat :app:connectedDebugAndroidTest --console=plain
Set-Location ..
git switch main
Set-Location NewsBulletin
.\gradlew.bat :app:connectedDebugAndroidTest --console=plain
```

Keep the JUnit XML under `NewsBulletin/app/build/outputs/androidTest-results/connected/debug/` and relevant LeakCanary Logcat for each new run. The [instrumented test](NewsBulletin/app/src/androidTest/java/com/example/newsbulletin/LeakReproductionInstrumentationTest.kt) performs all three passages, checks the live update status and Home titles, visits About, then invokes `LeakAssertions.assertNoLeaks()`. For the agent-driven Journey, build the debug APK and follow the XML one action at a time using Android CLI layout/screenshots and adb input as described in the protocol. The Android CLI version installed during the original run did not expose a Journey execution subcommand, so the agent performed those actions individually. The [Android CLI overview](https://developer.android.com/tools/agents) and [Journeys guidance](https://developer.android.com/tools/agents/android-cli/journeys) describe the current tool and workflow.

## Evidence

| Question | Reviewed public evidence |
| --- | --- |
| What was the known reference chain? | [Diagnosis](evidence/20261014-1917-diagnosis-01/17-diagnosis.md), [filtered diagnostic Logcat](evidence/20261014-1917-diagnosis-01/15-leak-tags-logcat.txt) |
| Did the UI flow work? | [Baseline Journey](evidence/20261014-1917-diagnosis-01/16-journey-result.md), [corrected Journey](evidence/20261014-1934-validation-01/16-journey-result.md), [reviewed screenshot](evidence/20261014-1934-validation-01/04-p1-follow.png) |
| What changed? | [Correction review](evidence/20261014-1930-fix-01/01-correction-review.md), [source diff](evidence/20261014-1930-fix-01/02-article-activity.diff), [build result](evidence/20261014-1930-fix-01/04-build-retry.txt) |
| What did the explicit assertion report? | [Baseline JUnit XML](evidence/20261014-1952-instrumented-01/03-baseline-test-result.xml), [corrected JUnit XML](evidence/20261014-1952-instrumented-01/07-corrected-test-result.xml), [baseline selected Logcat](evidence/20261014-1952-instrumented-01/baseline-selected-logcat.txt), [corrected selected Logcat](evidence/20261014-1952-instrumented-01/corrected-selected-logcat.txt) |
| Did it repeat? | [Round 3 result and limits](benchmarks/rodada-03-repeticao/20261015-1614-round03-01-resultado.md) |

The [automatic post-fix assessment](evidence/20261014-1934-validation-01/19-postfix-assessment.md) is inconclusive on its own. The later instrumented assertion is a separate validation method. Rounds 2 and 3 repeated the outcome, but emulator state, caches, and runtime grants were not fully controlled. No speed or token savings are inferred. Android Studio Profiler and Gemini's Fix with Agent were outside this experiment; CI has not been implemented.

See [publication sanitization notes](PUBLICATION_NOTES.md) for the selection, historical commit mapping, and limits of the public copy. This repository does not include a license pending the author's choice.

## Official references

- [Android CLI](https://developer.android.com/tools/agents)
- [Journeys with Android CLI](https://developer.android.com/tools/agents/android-cli/journeys)
- [LeakCanary](https://square.github.io/leakcanary/)
- [LeakCanary leak detection in UI tests](https://square.github.io/leakcanary/ui-tests/)
