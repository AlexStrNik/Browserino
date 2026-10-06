import AppKit
import Foundation

@MainActor
extension BrowserTarget {
    var chromiumProfile: ChromiumProfile? {
        guard let profile else {
            return nil
        }

        return ChromiumProfileService.profiles(forAppAt: app)?
            .first { $0.directory == profile }
    }

    /// A profile the browser no longer knows about — the user switched machines,
    /// restored a backup, or deleted it in the browser.
    var hasMissingProfile: Bool {
        profile != nil && chromiumProfile == nil
    }

    /// "Chrome", or "Chrome — Work" for a profile.
    var displayName: String {
        let browser = Bundle(url: app)?.appDisplayName ?? app.appDisplayName

        guard let profile else {
            return browser
        }

        let aliases = UserDefaults.standard.string(forKey: "profileNames").flatMap { [String: String](rawValue: $0) } ?? [:]
        let aliasKey = shortcutKey(bundleIdentifier: Bundle(url: app)?.bundleIdentifier ?? app.path)
        return "\(browser) — \(aliases[aliasKey] ?? chromiumProfile?.name ?? profile)"
    }

    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: app.path)
    }
}
