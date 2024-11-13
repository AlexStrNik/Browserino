//
//  BrowserUtil.swift
//  Browserino
//
//  Created by byt3m4st3r.
//

import AppKit
import Foundation

class BrowserUtil {
    static func loadBrowsers() -> [URL] {
        // URL representing the "https" scheme which browsers can handle
        guard let url = URL(string: "https:") else {
            return []
        }

        // Fetch all applications that can open the https scheme
        let urlsForApplications = NSWorkspace.shared.urlsForApplications(toOpen: url)

        let validDirectories = [
            "/Applications",
        ]

        // Filter the browsers to include only those in the specified directories
        var filteredUrlsForApplications = urlsForApplications.filter { urlsForApplication in
            // Check if the browser's path starts with any of the valid directories
            validDirectories.contains { urlsForApplication.path.hasPrefix($0) }
        }

        // Always include Safari by adding it explicitly if not already present
        if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
            if !filteredUrlsForApplications.contains(safariURL) {
                filteredUrlsForApplications.append(safariURL)
            }
        }

        return filteredUrlsForApplications
    }
}
