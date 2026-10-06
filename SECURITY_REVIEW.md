# Security and macOS compatibility review

## Changes

- Browserino URL wrappers accept only HTTP(S) with a host; every incoming URL is validated. Direct Finder file URLs remain supported.
- Launch requires a local `.app` with a bundle identifier and rejects Browserino itself. Unknown profile access and unconfigured private mode fail with a visible error. Recoverable error alerts preserve the chooser.
- Import/export/reset use an explicit application-setting allowlist. Imports validate nested model types, URLs, safe profile components, language identifiers, booleans and the move shortcut before writing. Security-scoped bookmarks are not exported. Malformed saved browser arrays are not silently replaced by rescanning.
- Discovery uses directory component boundaries and canonical deduplication. Missing apps remain editable without bundle force unwraps.
- Profile grants must match the expected canonical folder, stale bookmarks refresh while access is active, and scopes are balanced. Profile, Local State and avatar paths are checked against symlink/traversal escapes.
- Tab transfer captures a Chromium window/tab identifier and original URL. Closing occurs only following successful destination launch and exact identity/URL revalidation. Ambiguous multiple-instance sources are rejected. Safari never auto-closes its source. URL parameters are passed as typed Apple Event arguments, not inserted into script source.

## Compatibility

Swift 6, macOS 14 minimum, Xcode 27 / macOS 27 SDK. Liquid Glass on macOS 26+, blur on 14–25, opaque system background with Reduce Transparency. `canBecomeKey` is scoped to BrowserinoWindow, panel level is floating, and activation/default-handler updates use the main actor. Both HTTP and HTTPS handler schemes are registered when requested.

KeyboardShortcuts 2.4.0 is pinned to a fixed revision. Its MIT license is packaged in `ThirdPartyNotices.txt`. Public advisories were reviewed; no exhaustive dependency security guarantee is made.

## Checks and limits

Run URL tests from `Tests/main.swift`, `sh scripts/test-integration.sh`, and `python3 scripts/check-localizations.py`. AppleScript compilation check: generate with `python3 scripts/check-browser-scripts.py`, compile the generated Swift checker, then run it outside the filesystem sandbox. The checker never executes the AppleScript commands.

Debug and Release compile on Xcode 27 with signing disabled. Interface checks use a separate test bundle ID on macOS 26.6.2. SDK compilation does not establish macOS 27 runtime compatibility. Actual Automation permission and browser-tab transfer round trips, fullscreen Spaces, multiple displays and Reduce Transparency rendering remain manual checks. Distribution signing/notarization is not verified.

Residual risks: user regular expressions run synchronously without a timeout; routing imports intentionally select applications and arguments; destination launch success does not prove navigation completion; this is not an App Sandbox application. Successive URL events can replace a pending chooser request (issue #45). The source review and tests do not guarantee absence of vulnerabilities.
