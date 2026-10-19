# Publication selection and sanitization

Publication preparation run: `20261019-publication-01`. This repository was assembled from the round-3 worktree into a new Git repository. Its Git history starts with the intentional leak and then records the reviewed correction. Original worktrees, tags, commits, and evidence were left in place. No remote was configured.

The archived evidence cites source commits from the private local experiment. In this public repository, use `baseline-leak` for the intentional leak and `main` for the correction. The source states correspond to original `6a6a4bd617c741930ba5ae5f9f0f8720e87fdc7c` and `e0809d718d9dc0c8d36121841856e1cf7b82e169`, respectively; those identifiers are provenance, not commands for this new repository. A typo in the original `AUTONOMY_REPORT.md` used `ba5ae4f` in one place; the archived source object resolved as `ba5ae5f`. That report was not copied.

## Selection

- Copied the app source/resources, Gradle scripts and full wrapper, Journey XML/protocol, and identical instrumented test from round 3.
- Selected diagnosis, correction review/diff/build result, Journey results, JUnit XML, round-3 summary, one visually reviewed app screenshot, and relevant Logcat.
- Created `baseline-selected-logcat.txt` and `corrected-selected-logcat.txt` by retaining only lines tagged `LeakStudy`, `LeakCanary`, or `TestRunner` from the original per-test Logcat. The unchanged JUnit XML preserves the baseline assertion's full reference chain and the corrected assertion outcome. These extracts are not full Logcat.
- In the public copies only, removed trailing whitespace from the diagnostic Logcat extract, the correction diff, and the build result; updated two archival references in the diagnosis to say their full source files remain local. The original evidence was left intact.
- Excluded full system Logcat, other screenshots, local handoff files, raw token/session records, build products, caches, `local.properties`, `private-raw`, heap dumps, signing files, and the old `.git` directory.

The original evidence files were not edited. The public selection was checked for local profile paths, personal email patterns, and common credential markers. This is a review of the selected files, not a guarantee about unselected local evidence or external services.
