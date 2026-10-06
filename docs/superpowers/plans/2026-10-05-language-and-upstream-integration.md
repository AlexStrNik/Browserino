# Language and Upstream Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for inline execution, or superpowers:subagent-driven-development if the user chooses delegation. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate all six reviewed PRs and persistent, immediate manual language selection while retaining security fixes and Liquid Glass.

**Architecture:** PR #65 already contains #63/#64, and supplies the browser target/profile model. Port #61 onto that model, capturing a stable source tab rather than closing the active tab. Add one localization service used by SwiftUI and AppKit. Fold #48's naming/visibility/enablement capabilities into the shared profile model rather than creating competing profile stores.

**Tech Stack:** Swift 6, AppKit, SwiftUI, macOS 27 SDK, macOS 14 deployment minimum, KeyboardShortcuts, Xcode string catalogs.

**Spec:** `docs/superpowers/specs/2026-10-05-language-and-upstream-integration.md`

## Global Constraints

- Minimum macOS: 14.0, consistently at project and target levels. Swift language mode: 6.0.
- Preserve HTTP(S) wrapper validation, Finder documents, no-self routing, restricted settings keys and Hardened Runtime.
- Liquid Glass on macOS 26+, existing blur on 14–25, opaque background for Reduce Transparency.
- Ten languages: en, ru, de, fr, es, pt-BR, it, ja, ko, zh-Hans. Dynamic names, URLs and regexes are verbatim.
- Only new third-party package: pinned KeyboardShortcuts from #61, after license/advisory review.
- No GitHub merges, pushes or comments. Retain a snapshot of existing uncommitted work before editing. Test processes must be stopped.

## Review Focus

- Malformed or old settings must not erase targets/order/shortcuts. Migration and import tests belong to Task 1/3.
- Unreadable profile state is unknown, not an empty list; deny and stale-bookmark tests belong to Task 2.
- Imported relative profile/avatar paths must not escape the authorized root; traversal/symlink tests belong to Task 2.
- A changed source tab/window must never cause a different tab to close; identity tests belong to Task 4.
- Private-open failures must preserve the URL/source and show an error; launch and move tests belong to Task 2/4.

---

### Task 1: Integrate target migration, missing-app handling and Swift 6

**Files:** Modify `Browserino.xcodeproj/project.pbxproj`, `Browserino/BrowserinoApp.swift`, `Browserino/BrowserinoWindow.swift`, `Browserino/Models/BrowserUtil.swift`, `Browserino/Models/Rule.swift`, preferences and prompt views; add `Browserino/Models/BrowserTarget.swift`, `Browserino/Extensions/Bundle+AppDisplayName.swift`, `Browserino/Views/BrowserTargetIcon.swift`, `Browserino/Views/Preferences/BrowserTargetPicker.swift`; remove obsolete pre-14 compatibility source references; add `Tests/IntegrationTests.swift` and `scripts/test-integration.sh`.

**Interfaces:** Produces `BrowserTarget: Codable, Hashable` with `app: URL`, `profile: String?`, `init(app:profile:)` and `shortcutKey(bundleIdentifier:) -> String`. Browser/rule/app storage uses this representation or backward-compatible optional profile properties. Existing app names have safe bundle/URL fallbacks.

- [ ] Snapshot tracked changes and untracked artifacts into a unique `/tmp` directory, with original paths and checksums.
- [ ] Retrieve pinned #65 head `a9f46f3cb148f82de8a330a7c7d32434606169e6` and #61 head `676c0fd538b49989be93837debfaf73ab6439c87`; retain attribution and upstream URLs.
- [ ] Write migration checks: old bare URL arrays decode without losing order; missing optional profiles decode; profile-less shortcut keys equal old bundle IDs; malformed arrays produce a reported failure rather than replacing saved data.
- [ ] Run the migration checks against the baseline and observe the expected missing-profile/migration failure.
- [ ] Port #65/#63/#64 into the working tree, preserving local security, localization and Glass changes. Use `Bundle(url:)` optionals in every preferences path; missing targets remain visible and editable. Make SettingsDocument's stored representation Sendable via Data.
- [ ] Run `scripts/test-integration.sh` and Debug build; pass with migration assertions and no Swift compiler errors. Inspect missing-app editor views with a disposable fixture rather than user settings.

### Task 2: Unified profile discovery, access and launch

**Files:** Add/modify `Browserino/Models/ChromiumProfile.swift`, `Browserino/Models/BrowserTarget.swift`, `Browserino/Models/BrowserUtil.swift`, `Browserino/Views/Preferences/BrowsersTab.swift`, `Browserino/Views/Prompt/PromptView.swift`, `Tests/IntegrationTests.swift`.

**Interfaces:** Consume BrowserTarget. Produce `ChromiumProfileService.profiles(forAppAt:) -> [ChromiumProfile]?`, `requestAccess(forAppAt:) -> Bool`, and `BrowserUtil.openURL(_:target:isIncognito:completionHandler:)` where completion returns the destination running app or an error. Nil discovery means unknown. Display-name aliases and profile enablement are persisted separately from browser-owned metadata.

- [ ] Write tests using temporary fake browser data: readable empty state versus unreadable state, stale/unknown profiles, expected-folder grant validation, path traversal and symlink escape, deterministic ordering and legacy #48 names/hidden/shortcuts migration.
- [ ] Run tests against upstream behavior to verify containment/grant tests fail for the identified gaps.
- [ ] Correct #65's access flow: require the actual selected canonical directory to match the expected root; refresh stale bookmarks; keep scope balanced; validate profile and avatar containment before reading.
- [ ] Implement #48 capabilities in the shared Browsers UI: profile enablement, native-name display alias, per-profile hiding/shortcuts and targeting in rules/apps. Migrate applicable old chromeProfiles settings without creating a second profile subsystem.
- [ ] Validate all launch inputs; unsupported private mode and failed targets report errors without closing the picker. Use the same completion path for plain/profile/private launch.
- [ ] Run integration checks, then Debug build; verify no personal browser data was needed for the automated tests.

### Task 3: Immediate manual language selection and settings validation

**Files:** Add `Browserino/Models/Localization.swift`; modify `Browserino/Views/Preferences/GeneralTab.swift`, `Browserino/BrowserinoApp.swift`, preferences/prompt views, `Browserino/Localizable.xcstrings`, `scripts/check-localizations.py`, `Tests/IntegrationTests.swift`.

**Interfaces:** Produces a main-actor localization service with `selectedLanguage: String`, `activeLanguage: String`, `bundle: Bundle`, `locale: Locale` and `string(_ key: String) -> String`. Empty selectedLanguage means System default. All visible localized keys resolve through this service; import/export/reset share an explicit language identifier validator.

- [ ] Write tests: default follows supported preferred languages; ru persists; an unknown ID falls back to system; unavailable preferred languages fall back to en; direct bundle lookups resolve Russian and German keys; reset restores system mode.
- [ ] Run tests before implementation and verify expected resolver failure.
- [ ] Implement the service without changing system AppleLanguages. Refresh SwiftUI localization and AppKit window/menu strings immediately on selection. Add native-name options to the General picker.
- [ ] Update import schema to validate supported language and target/profile collections before any write. Exclude access bookmarks from export; malformed JSON cannot erase saved lists.
- [ ] Translate Language/System default and every new profile/move string for all ten languages; validate placeholders as well as empty values.
- [ ] Run integration and localization scripts. UI-check manual Russian ↔ German ↔ System default switching and persistence with an isolated preferences domain.

### Task 4: Safe current-tab movement and global shortcut

**Files:** Add `Browserino/Models/BrowserSwitchService.swift`, `Browserino/Models/BrowserTabScripting.swift`; modify `Browserino/BrowserinoApp.swift`, `Browserino/Views/Prompt/PromptView.swift`, `Browserino/Models/BrowserUtil.swift`, `Browserino/Views/Preferences/GeneralTab.swift`, `Browserino/Browserino.entitlements`, `Browserino/Info.plist`, localized InfoPlist resources and Xcode package configuration; add tests.

**Interfaces:** Consume BrowserTarget and completion-based launch. Produce `SourceTabSnapshot` containing source bundle/process, stable window/tab identity and captured URL. Scripting reads that snapshot; close accepts that snapshot and revalidates it. BrowserSwitchService holds transient move state and exposes menu/shortcut entry points.

- [ ] Review and pin the KeyboardShortcuts version from #61; check official repository license, supported APIs and advisory information. No arbitrary package upgrades.
- [ ] Write move-state tests: cancel/no target/open failure/private failure never request close; success requests close for the original ID; changed identity/URL or vanished source prevents closing; another tab becoming active never becomes the close target.
- [ ] Run tests against the original active-tab close approach and verify the changed-tab case fails.
- [ ] Port #61 using stable source snapshots and typed Apple Event descriptors/validated IDs. Safely reject sources that cannot expose stable identity. Validate URLs with the existing input policy; limit Automation to explicit user-triggered moves.
- [ ] Add localized move action, global shortcut control, close-source toggle and recoverable errors. Keep source intact until successful destination handoff and identity revalidation.
- [ ] Run integration checks and Debug build; runtime-test only disposable browser tabs where Automation is already available or the user explicitly grants it. Record denied permissions as unverified runtime behavior, not a pass.

### Task 5: Documentation and complete verification

**Files:** Modify `Readme.md`, `SECURITY_REVIEW.md`, `docs/UPSTREAM_REVIEW.md`; update integration checks if final review identifies a regression.

- [ ] Include #55's corrected installation instructions, profile/language/move usage, macOS 14 requirement, migration/downgrade limitations and authentication-session fallback.
- [ ] Run complete integration checks, URL security checks, localization checks, plist lint and `git diff --check`.
- [ ] Build Debug and Release using macOS 27 SDK, CODE_SIGNING_ALLOWED=NO. Build supported architectures and inspect the resulting binary architectures. Read full failure/warning output before claiming success.
- [ ] Visually verify Russian and German settings, missing-app editing and chooser Glass on the available macOS 26.6.2. Avoid modifying the user's default browser/login settings.
- [ ] Audit the final diff against every requirement in the approved spec; record fixes, validation and environment limitations in the review document.
- [ ] Stop all processes created for testing and verify none remain. Deliver the local changes and a concise report; do not commit/push/publish without separate user instruction.
