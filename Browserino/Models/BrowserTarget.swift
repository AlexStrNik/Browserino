//
//  BrowserTarget.swift
//  Browserino
//

import AppKit
import Foundation

/// A browser to open links in. `profile` names a Chromium profile directory;
/// nil means the browser picks, which is what every entry meant before profiles
/// existed.
struct BrowserTarget: Codable, Hashable {
    var app: URL
    var profile: String?

    init(app: URL, profile: String? = nil) {
        self.app = app
        self.profile = profile
    }

    /// Earlier builds stored these as bare URL strings. Both shapes have to decode,
    /// because Array+RawRepresentable turns any decode failure into nil and
    /// @AppStorage then silently substitutes an empty array — losing the user's
    /// browser order and hidden set with nothing shown to explain it.
    init(from decoder: any Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let app = try? container.decode(URL.self) {
            self.init(app: app)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            app: try container.decode(URL.self, forKey: .app),
            profile: try container.decodeIfPresent(String.self, forKey: .profile)
        )
    }

    /// Shortcuts are stored per target. Profile-less targets keep using the bare
    /// bundle identifier so shortcuts recorded before this feature still resolve.
    func shortcutKey(bundleIdentifier: String) -> String {
        guard let profile else {
            return bundleIdentifier
        }

        return "\(bundleIdentifier)#\(profile)"
    }
}

