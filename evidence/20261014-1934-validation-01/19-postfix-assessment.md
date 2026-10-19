# Post-fix assessment — 20261014-1934-validation-01

## Method and observed functional result

The same `Pixel_6a` emulator, debug variant, process reset and 23-action Journey from the baseline were used. The Journey SHA256 stayed `814BC3F3C7D0705AB358AE6AE413379ACB69A0003603FF1972C261C30A503363`. All 23 UI actions/checks passed. The three Follow taps displayed `Following updates for this article.` while Article was open, and the three Home returns displayed the article list. See `16-journey-result.md` and screenshots.

The corrected app's PID 20888 logged three sequences of `followClick`, `listenerRegistered listenerCount=1`, and `updateDelivered`. Each following `ArticleActivity.onDestroy` was preceded by `listenerUnregistered listenerCount=0`. These are direct behavioral observations from `15-leak-tags-initial.txt` and `18-leak-tags-recheck.txt`.

## LeakCanary evidence

LeakCanary 2.14 reported that it was running and watching each destroyed `ArticleActivity`. Three complete `adb -s emulator-5554 logcat -d -v threadtime` captures after the Journey contain no `HEAP ANALYSIS RESULT`, post-fix reference trace or explicit retained-object verdict. The last capture was taken at 19:46:53 local time, more than five minutes after the third Activity destruction at device time 22:41:06. The baseline, by contrast, produced a completed heap analysis and the registry → listener → destroyed Activity chain in `evidence/20261014-1917-diagnosis-01/14-full-logcat.txt`.

The corrected run therefore confirms listener removal and preserved UI behavior, but **does not yet provide the new LeakCanary analysis required to conclude the post-fix memory outcome under the plan's criterion**. Absence of a trace in these captures is not presented as proof of collection. A manual LeakCanary analysis would change the diagnostic collection method, so user authorization was requested before attempting it.

## Evidence and environment

- Initial full Logcat: `14-full-logcat-initial.txt`; tag-only copy: `15-leak-tags-initial.txt`.
- Later full Logcat: `17-full-logcat-recheck.txt`; tag-only copy: `18-leak-tags-recheck.txt`.
- Final automatic-analysis wait capture: `20-full-logcat-late.txt`; tag-only copy: `21-leak-tags-late.txt`.
- Environment verification: `01-environment.txt`.
- Corrected APK SHA256 `FC7E7DC094EB898EF44DA893227723E45BF94A7843E507175531172DA265A524`; correction commit `e0809d718d9dc0c8d36121841856e1cf7b82e169`.

## Later user-authorized assertion

After this automatic-only assessment, the user approved a separate instrumentation validation. The identical test failed on the baseline with the expected reference chain and passed on the corrected commit; LeakCanary's explicit GC check reported no watched objects. Full comparison and evidence are in `../20261014-1952-instrumented-01/09-instrumented-comparison.md`. The automatic run above remains inconclusive on its own; the separate assertion supplies the observed after result for the targeted flow.
