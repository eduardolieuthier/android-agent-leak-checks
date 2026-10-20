# Android memory leak investigation with agents

News Bulletin is a small offline Android app used to reproduce an intentional `ArticleActivity` listener leak and validate a reviewed lifecycle correction. Tag `baseline-leak` contains the leak; `main` contains the correction. Archived commit IDs refer to the original local experiment and are provenance, not checkout commands for this publication repository.

## Observed results

The three-passage instrumented test reached `LeakAssertions.assertNoLeaks()` in both source states. On the baseline, LeakCanary 2.14 reported `1 APPLICATION LEAKS` and a failed assertion through `NewsBulletinApplication -> UpdateRegistry.listeners -> listener -> destroyed ArticleActivity` (`mDestroyed = true`). On the correction, the same test passed and selected Logcat recorded `No watched objects after triggering an explicit GC.` These results apply to the tested flow. The earlier automatic post-fix collection produced no heap analysis and remains inconclusive on its own.

## Quick start

Use a Windows host with Git, JDK 17 or newer, Android SDK platform 36 and platform-tools, an Android emulator, and Gradle dependency access for the first build. The checked-in wrapper uses Gradle 9.1.0 and the project uses AGP 9.0.1. The recorded environment was: **Pixel_6a AVD identified as android-36.1; the device reported SDK_INT 36.** SDK paths and emulator serials may differ on another machine. Start the emulator and wait for it to finish booting. It must be the only connected test device.

**PowerShell command in a terminal** (from any working directory, with the repository path adjusted as needed):

```powershell
& 'C:\path\to\android-agent-leak-checks\scripts\reproduce-memory-checks.ps1' -DeviceSerial emulator-5554 -SdkPath 'C:\path\to\Android\Sdk'
```

If `ANDROID_HOME` already points to a valid SDK, omit `-SdkPath`. The script runs the intentional-leak reference and corrected test, saving a unique `evidence/reproduction-*` directory. It returns to the starting `main` checkout when possible. Inspect its result metadata and preserved logs if either run fails. Review newly captured Gradle output before sharing it.

## Try it with an agent

**Example prompt for reproducing the workflow**: enter this natural-language prompt into Codex, not a PowerShell terminal. It is an example for a new run, not the original experiment prompt:

> Read the repository instructions and `NewsBulletin/journeys/REPRODUCTION.md`. Follow the defined Journey on one emulator. Collect and interpret LeakCanary evidence; distinguish infrastructure failures from detected leaks. Compare the intentional-leak reference with the correction. Preserve historical evidence and save new results separately. Treat missing diagnostic evidence as inconclusive. Make no application changes during reproduction.

## Detailed reproduction

The [PowerShell reproduction script](scripts/reproduce-memory-checks.ps1) runs the [instrumented test](NewsBulletin/app/src/androidTest/java/com/example/newsbulletin/LeakReproductionInstrumentationTest.kt) against both states and checks the named JUnit result and LeakCanary evidence. The [reproduction protocol](NewsBulletin/journeys/REPRODUCTION.md) and [Journey XML](NewsBulletin/journeys/leak_reproduction.xml) describe the separate agent-driven UI Journey. They use the same three passages through the first article, Follow updates, return to Home, and About visit.

The script force-stops the app and clears Logcat before each instrumented run. Notification permission handling in the protocol applies to the agent-driven Journey. Runtime permission grants during historical instrumented runs were not independently captured; do not assume fully identical starting conditions across historical rounds.

The baseline counts as a positive control only when the named JUnit test fails at the LeakCanary assertion, with the known `UpdateRegistry.listeners -> listener -> destroyed ArticleActivity` chain. A build, installation, device, missing-report, or unrelated test failure is inconclusive. The corrected test must pass; if its explicit diagnostic line is missing, test success and diagnostic evidence are reported separately. A missing trace alone does not prove leak absence.

## Evidence and limitations

| Question | Reviewed evidence |
| --- | --- |
| What was the known reference chain? | [Diagnosis](evidence/20261014-1917-diagnosis-01/17-diagnosis.md), [filtered diagnostic Logcat](evidence/20261014-1917-diagnosis-01/15-leak-tags-logcat.txt) |
| Did the UI flow work? | [Baseline Journey](evidence/20261014-1917-diagnosis-01/16-journey-result.md), [corrected Journey](evidence/20261014-1934-validation-01/16-journey-result.md), [reviewed screenshot](evidence/20261014-1934-validation-01/04-p1-follow.png) |
| What changed? | [Correction review](evidence/20261014-1930-fix-01/01-correction-review.md), [source diff](evidence/20261014-1930-fix-01/02-article-activity.diff) |
| What did the assertion report? | [Baseline JUnit XML](evidence/20261014-1952-instrumented-01/03-baseline-test-result.xml), [corrected JUnit XML](evidence/20261014-1952-instrumented-01/07-corrected-test-result.xml), [baseline selected Logcat](evidence/20261014-1952-instrumented-01/baseline-selected-logcat.txt), [corrected selected Logcat](evidence/20261014-1952-instrumented-01/corrected-selected-logcat.txt) |
| Did it repeat? | [Round 3 result and limits](benchmarks/rodada-03-repeticao/20261015-1614-round03-01-resultado.md) |

The [automatic post-fix assessment](evidence/20261014-1934-validation-01/19-postfix-assessment.md) is inconclusive on its own. Later instrumented assertions are separate validation. Historical rounds did not fully control emulator state, caches, or runtime grants. No speed or token savings are inferred. Android Studio Profiler and Gemini's Fix with Agent were outside this experiment; CI has not been implemented. See [publication notes](PUBLICATION_NOTES.md) for provenance and selection limits.

## License

Original code and documentation are available under the [MIT License](LICENSE). Third-party components retain their own licenses and notices.

## Official references

- [Android CLI](https://developer.android.com/tools/agents)
- [Journeys with Android CLI](https://developer.android.com/tools/agents/android-cli/journeys)
- [LeakCanary](https://square.github.io/leakcanary/)
- [LeakCanary leak detection in UI tests](https://square.github.io/leakcanary/ui-tests/)
