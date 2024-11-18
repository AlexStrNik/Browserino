//  BrowserUtil.swift
//  Browserino
//
//  Created by byt3m4st3r.
//

import AppKit
import Foundation
import SwiftUI

class BrowserUtil {
    @AppStorage("directories") private static var directories: [Directory] = []

    static func loadBrowsers() -> [URL] {
        // Convert directories to valid paths
        let validDirectories = directories.map { $0.directoryPath }

        guard let url = URL(string: "https:") else {
            return []
        }

        // Fetch all applications that can open the https scheme
        let urlsForApplications = NSWorkspace.shared.urlsForApplications(toOpen: url)

        // Filter the browsers to include only those in the specified browser search directories (/Applications default)
        var filteredUrlsForApplications = urlsForApplications.filter { urlsForApplication in
            validDirectories.contains { urlsForApplication.path.hasPrefix($0) }
        }

        // Remove Browserino from the browser list
        if let browserino = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "xyz.alexstrnik.Browserino") {
            if filteredUrlsForApplications.contains(browserino) {
                filteredUrlsForApplications.removeAll { $0 == browserino }
            }
        }

        // Always include Safari by adding it explicitly if not already present
        if let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
            if !filteredUrlsForApplications.contains(safari) {
                filteredUrlsForApplications.append(safari)
            }
        }

        return filteredUrlsForApplications
    }
}
