# PR title

feat: add browser profiles, tab transfer, localization, and modern macOS support

# PR description

Browserino can now open links in a specific Chromium profile, transfer the current browser tab to another browser, and switch interface languages from Preferences. Rules targeting removed applications remain editable instead of crashing the settings window.

## Changes

- Add Chromium profile discovery, profile names/avatars, individual visibility and shortcuts, and profile destinations for rules and site mappings.
- Preserve existing browser order and settings, including legacy Chrome profile rules, names, visibility and shortcuts. Add an option to disable profile display without deleting profile preferences.
- Add a menu command and configurable global shortcut for tab transfer. Source closing is opt-in; Chromium closing revalidates the captured window/tab IDs and URL. Safari keeps its original tab open.
- Add ten interface languages, including Russian, with persistent manual selection and a system-default option. Refresh settings and menu labels immediately; align controls and wrap longer translations. Use stable semantic localization keys rather than full source text.
- Adopt Swift 6 and a consistent macOS 14 minimum. Build with the macOS 27 SDK; use Liquid Glass on macOS 26+, blur on earlier supported systems, and an opaque Reduce Transparency fallback.
- Validate incoming URLs and nested imported settings, prevent self-routing, preserve the chooser on recoverable launch errors, and validate profile grants and paths against traversal/symlink escapes.
- Deduplicate canonical browser paths and update Homebrew installation instructions without `--no-quarantine`.

## Upstream contributions

This integrates and adapts the following contributions. Their authors retain credit; the implementations were combined with additional migration, localization and safety fixes.

| Original PR | Author | Included contribution |
| --- | --- | --- |
| #63 | @matijazezelj | Missing-application crash fixes and current SDK compatibility |
| #64 | @matijazezelj | Swift 6 and consistent macOS 14 baseline |
| #65 | @matijazezelj | Chromium BrowserTarget profiles, migration, discovery and access grants; stacks on #63 and #64 |
| #48 | @motilevy | Chrome profile naming, visibility, shortcuts and rule targeting, folded into the shared profile model |
| #61 | @dotWee | Browser-tab transfer, Automation integration and global shortcut |
| #55 | @ninadpchaudhari | Homebrew installation command and documentation improvements |

The upstream PRs are incorporated references; this PR does not merge or close them individually. Pinned source revisions and adaptation notes are recorded in `docs/UPSTREAM_REVIEW.md`.

## Issues

Closes #4
Closes #51

Related: #39 (canonical-path deduplication; the Atlas-specific reproduction remains unverified).

## Validation

- [x] URL security regression checks.
- [x] `sh scripts/test-integration.sh`: target/rule migration, typed settings imports, language selection, hidden-profile transitions, source-close policy, profile fixtures and traversal/symlink checks.
- [x] `python3 scripts/check-localizations.py`: 79 strings complete in ten languages.
- [x] Debug and Release arm64 builds with Xcode 27 / macOS 27 SDK, `CODE_SIGNING_ALLOWED=NO` (2026-10-05).
- [x] Chrome/Safari AppleScript syntax compilation without executing tab commands.
- [x] Russian/German preferences layout, immediate switching and language persistence checked using an isolated test bundle on macOS 26.6.2.
- [x] Fresh code review and regressions for the actionable findings; `git diff --check`.

## Compatibility and verification limits

The minimum supported version changes from macOS 13 to macOS 14. Older builds cannot decode the new profile-target browser array; export settings before downgrading. Security-scoped grants are intentionally excluded from exports and must be granted on the destination Mac.

Runtime behavior on macOS 27, actual Automation read/open/close round trips, fullscreen Spaces, multiple displays and Reduce Transparency rendering still require manual verification. Destination application-open success does not prove page loading completed. Source closing defaults to off. Distribution signing/notarization is outside this change.

KeyboardShortcuts is pinned to 2.4.0 and its MIT notice is included in the app. Native OS panels and third-party shortcut-conflict dialogs use system localization.
