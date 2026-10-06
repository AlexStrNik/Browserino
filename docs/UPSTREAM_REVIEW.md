# Upstream integration — 2026-10-05

Reviewed six open pull requests and twenty open issues using the live GitHub API. Changes are integrated on `feature/browser-profiles-tab-transfer-localization`. Publication was requested on 2026-10-06; the upstream PRs are incorporated as source references rather than merged individually. Earlier uncommitted work is preserved in `/tmp/browserino-before-integration-20261005-144839`.

| PR | Local integration |
|---|---|
| [#63](https://github.com/AlexStrNik/Browserino/pull/63) | Missing applications remain visible/editable; optional bundle names and metadata have safe fallbacks. |
| [#64](https://github.com/AlexStrNik/Browserino/pull/64) | Swift 6 and consistent macOS 14 deployment minimum; concurrency and panel compatibility fixes retained. |
| [#65](https://github.com/AlexStrNik/Browserino/pull/65) | Chromium BrowserTarget profiles, legacy URL decoding, ordering, avatars and explicit folder grants. Corrected folder verification, stale bookmarks, traversal and symlink containment. Unknown/unreadable state preserves known targets. |
| [#48](https://github.com/AlexStrNik/Browserino/pull/48) | Profile aliases, hiding, shortcuts and enablement integrated into Browsers rather than a second profile subsystem. Existing and imported Chrome profile settings are migrated. |
| [#61](https://github.com/AlexStrNik/Browserino/pull/61) | Move-tab menu and configurable global shortcut, opt-in source closing, Automation entitlement and translated usage description. Captures Chromium window/tab IDs and URL; revalidates before closing. Safari sources stay open because its dictionary provides no stable tab ID. Multiple processes with the same browser identifier are rejected. |
| [#55](https://github.com/AlexStrNik/Browserino/pull/55) | Homebrew install command retains quarantine; installation guidance updated. |

Pinned source: #65 `a9f46f3cb148f82de8a330a7c7d32434606169e6`, #61 `676c0fd538b49989be93837debfaf73ab6439c87`. #65 includes #63/#64. KeyboardShortcuts is pinned to 2.4.0, revision `1aef85578fdd4f9eaeeb8d53b7b4fc31bf08fe27`. Its MIT notice is included in app resources. [Upstream advisory page](https://github.com/sindresorhus/KeyboardShortcuts/security/advisories) showed no published advisories during review; that does not establish absence of vulnerabilities.

## Issues

The user authorized all six PRs, not implementation of every issue. Missing-app handling relates to [#51](https://github.com/AlexStrNik/Browserino/issues/51); profiles relate to [#4](https://github.com/AlexStrNik/Browserino/issues/4). Canonical discovery deduplication also addresses part of [#39](https://github.com/AlexStrNik/Browserino/issues/39). No upstream issues are claimed closed.

Still separate work: [#45](https://github.com/AlexStrNik/Browserino/issues/45) successive URL queue; #62 tracking cleanup; #60/#38 default routing; #50 last-link recovery; #49/#42 deep-link rewrites; #13 source-app routing; #24 manual discovery; #19 synchronized settings; #36 discovery filtering. Homebrew cask warnings #57/#66 belong to the separate tap repository. Signing/notarization #6 requires release credentials. Liquid Glass relates to #27 but full Spaces/accessibility runtime coverage remains unverified.

For [#58](https://github.com/AlexStrNik/Browserino/issues/58), no unsupported web-authentication capabilities are declared. Applications requiring a browser authentication session may require Safari; protocol support is a separate feature.

## Validation

Debug and Release builds use Xcode 27 / macOS 27 SDK without distribution signing. Tests cover URL validation, old target decoding, typed settings validation, legacy Chrome migration/import, language resolution, profile discovery fixtures, path traversal/symlinks, hidden-state transitions and source-close policy. AppleScript templates are compiled against installed browser dictionaries without executing them. Russian/German interface switching and persistence were checked on an isolated app copy on macOS 26.6.2.

Runtime macOS 27, Automation grants and actual read/open/close browser round trips are not verified. NSWorkspace success confirms an application-open request, not successful destination page loading. Source closing defaults to off. Native OS panels and third-party shortcut-conflict dialogs use their own system localization; Browserino settings labels and recorder placeholders use the manually selected language.
