//
//  ChromeProfile.swift
//  Browserino
//

import AppKit
import Foundation

struct ChromeProfile: Codable, Hashable {
    var directoryName: String
    var displayName: String
    var isHidden: Bool = false
}

class ChromeProfileUtil {
    static let chromeBundleID = "com.google.Chrome"

    static func chromeURL() -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: chromeBundleID)
    }

    static func detectProfiles() -> [ChromeProfile] {
        let localStatePath = NSString("~/Library/Application Support/Google/Chrome/Local State")
            .expandingTildeInPath

        guard let data = FileManager.default.contents(atPath: localStatePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileInfo = json["profile"] as? [String: Any],
              let infoCache = profileInfo["info_cache"] as? [String: Any]
        else {
            return []
        }

        return infoCache.compactMap { (dirName, value) in
            guard let profileDict = value as? [String: Any],
                  let name = profileDict["name"] as? String
            else {
                return nil
            }

            return ChromeProfile(
                directoryName: dirName,
                displayName: name
            )
        }
        .sorted { $0.directoryName < $1.directoryName }
    }
}
