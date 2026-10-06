# Manual language selection and open PR integration

## Approved intent and scope

The user requested manual language selection and integration of all six currently open upstream PRs: #48, #55, #61, #63, #64, #65. Existing security fixes, translations and Liquid Glass must survive. This document resolves conflicts and defines verification before implementation.

## Language selection

General settings contains a Language picker with System default and English, Русский, Deutsch, Français, Español, Português (Brasil), Italiano, 日本語, 한국어, 简体中文. Default follows macOS preferred language order with English fallback. Persist the selected supported identifier separately from AppleLanguages. Changing it updates SwiftUI localized content, settings window title and status menu immediately without relaunch. System file panels and permission prompts remain under macOS control.

A single localization service resolves the active bundle and locale. SwiftUI receives the locale and appropriate localization bundle for localized keys; dynamic application names, URLs, regex patterns and profile labels remain verbatim. AppKit strings use the same resolver. Invalid or removed language identifiers fall back to System default. The preference participates in settings import/export/reset with identifier validation. New functionality introduced by PRs must receive translations in every existing language.

## Integration boundaries

Use PR #65 (head a9f46f3cb148f82de8a330a7c7d32434606169e6) as the base for #63 and #64, which it already contains. Integrate PR #61 separately. No external PR merges, pushes or GitHub comments are part of this task. Preserve a recoverable snapshot of all current uncommitted changes before integrating code.

### #63 — missing applications

Missing applications must be represented by a safe fallback name/icon, remain editable and removable in both Rules and Apps, and never crash editor presentation. Picker indexes must reflect renderable targets. Keep our safe incoming URL policy and no-self-routing checks.

### #64 — Swift 6 and macOS baseline

Use Swift 6 language mode and a consistent macOS 14.0 minimum across project and target settings, as proposed by #64. This intentionally removes macOS 13 support. Dispatch AppKit work onto the main actor; remove obsolete pre-14 focus/key handling. Keep pre-26 blur fallback and 26+ Liquid Glass/Reduce Transparency handling.

### #65 and #48 — one profile implementation

Use BrowserTarget and Chromium profile discovery/migration from #65, rather than maintaining two competing storage formats. Retain the capabilities of #48: per-profile visibility and shortcuts, profiles in picker and rules, private/profile launch combination, editable display names and an enable/disable setting. Profile controls can live alongside the existing Browsers settings rather than adding a second conflicting Profiles subsystem.

Decode legacy URL arrays and preserve browser order, hidden entries, existing shortcuts, rules and app mappings. Import old #48 chromeProfiles settings where applicable; do not wipe lists on unsupported/malformed JSON. Persist an override display name separately from Chromium's actual name/directory. Profile discovery distinguishes unavailable data from an empty list, preserving configured targets on denied/interrupted reads.

Require selection of the expected browser data directory for an access grant. Resolve and refresh stale security-scoped bookmarks. Constrain profile and avatar paths to that data root. Do not export machine-specific access bookmarks. Validate a profile before launching; handle stale/unknown targets explicitly. A private-open request without a private argument must report an error and preserve the chooser/source tab rather than silently opening normally or discarding the link.

### #61 — move current tab

Keep menu action, configurable global shortcut, source browser selection, move-mode picker and close-source toggle. Reuse the browser target/profile launch path. Automation permission is requested by macOS only when the user invokes tab movement; permission denial is recoverable.

Read and retain a stable source window/tab identity, not merely active tab of window 1. After a successful destination launch, close only that captured tab after revalidation; if identity or URL has changed, leave the source open and explain why. Cancel, empty destinations, private/profile failures and open failures must preserve the source. Opening a target means successful Launch Services handoff, not proof that the page loaded. Filter source URLs using the existing safe scheme policy. Do not transfer cookies/history/session state.

KeyboardShortcuts is the only new third-party package from this PR. Pin its resolved version and review API compatibility, license and current advisory information before adopting it. Translate all new alerts/menu/settings strings and the Automation usage description.

### #55 — installation documentation

Keep the corrected brew command without --no-quarantine; add useful installation instructions from #55. Do not bypass Gatekeeper. Homebrew cask issues #57/#66 belong to a different repository and are outside this integration.

## Related issues

#51 and #4 are covered by missing-app and profile integration. #45 (URL queue), #39 (discovery duplicates) and the other reviewed issue features are not automatically included by "all PRs": they have no corresponding open PR. Existing fixes for #27's relevant rendering paths remain. Authentication capability flags are not added without a complete handler.

## Verification

- Swift 6 Debug and Release builds against macOS 27 SDK, targeting macOS 14.0; verify supported architectures.
- Regression checks for safe URL handling, old/new profile migration, order/hidden/shortcut preservation, unknown languages, locale lookup and invalid imports.
- Tests for containment and stale/denied profile grants without reading personal browser data.
- Tab movement tests prove original identity is used and close is skipped for cancellation, changed identity/URL, failed open and unsupported private mode. Browser runtime checks use disposable test tabs only.
- Translation completeness and placeholder checks for all ten languages; visually inspect Russian and a long Latin-language layout.
- Runtime smoke check on available macOS 26.6.2; explicitly report that macOS 27 runtime, real signing/notarization and macOS 14 runtime remain unverified if no corresponding environment is available.
- Stop all test application processes created during verification.
