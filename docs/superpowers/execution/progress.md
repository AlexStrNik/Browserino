# SDD ledger — plan: docs/superpowers/plans/2026-10-05-language-and-upstream-integration.md

Ruling: work in the current checkout on codex/upstream-integration with a complete checksum snapshot in /tmp/browserino-before-integration-20261005-144839 — preserves all earlier uncommitted work; no extra worktree consent is needed for the user-requested continuation here.
Baseline: 54 localization strings / 10 languages and URL security tests pass.
Task 1: in progress. Pinned upstream source snapshots downloaded.

Final implementation: all six PR capabilities integrated locally; no push, GitHub merge, PR creation or commit performed. User explicitly requested no push, so branch codex/upstream-integration remains in place with uncommitted changes.
Task 1: complete — pinned sources ported; legacy targets and missing-app paths retained; Swift 6 and minimum macOS 14 aligned.
Task 2: complete — shared profile settings, path/grant safeguards, access recovery, aliases and legacy Chrome migration. Tests use disposable data; actual OS bookmark denial/staleness still needs manual permission checks.
Task 3: complete — immediate persistent language selection; 79 strings in ten languages; native recorder wrapper; nested import validation and move-shortcut export/import/reset.
Task 4: complete — stable Chromium tab/window/URL targeting, typed Apple Event argument, multiple-process guard, Safari source preservation, opt-in closing and global shortcut. Script templates compile against Chrome/Safari without executing them; actual Automation round trip is unverified.
Task 5: complete — upstream/security/readme/third-party documentation and permission translations.
Task 6: completed available checks — latest Debug and Release builds both BUILD SUCCEEDED with Xcode 27/macOS 27 SDK; URL security tests, integration/settings/visibility/migration regressions, fake profile discovery, localization coverage and git diff --check pass. Russian/German UI and German language persistence verified on macOS 26.6.2. macOS 27 runtime, Spaces/Reduce Transparency and distribution signing/notarization remain unverified.
Fresh final review: six actionable findings fixed (typed app/rule profiles; recoverable alert preserves chooser; disabled-profile hiding; representation-transition hidden inheritance + shortcut fallback; access recovery for preserved profiles; legacy profile imports). Added regressions for settings/visibility/migration findings. Alert lifecycle fix inspected; UI alert round trip is not claimed tested.
User follow-ups: recorder placeholder now follows chosen language; control/label alignment and Russian/German wrapping checked visually. Native OS panels and package shortcut-conflict dialogs still use system localization.
Final process check: no running BrowserinoReview.app or browserino-xcode27 test executables. Only exact verified test PID 25692 was terminated; user's other applications were not targeted.

2026-10-06 PR preparation: user requested Git Flow naming. Renamed local branch to feature/browser-profiles-tab-transfer-localization. Prepared docs/PULL_REQUEST.md with title, upstream author credits and GitHub closing keywords for issues #4 and #51. #39 is related, not automatically closed, because its specific reproduction is unverified. Prior no-push instruction remains in force; no remote PR was created and no issue state changed. Integration tests, localization coverage and git diff --check passed again.

2026-10-06 publication: user explicitly authorized push and GitHub PR creation, superseding the earlier no-push instruction. Integration, localization and whitespace checks passed immediately before publication. Preparing one feature commit and PR targeting main.
