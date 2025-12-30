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
    @AppStorage("privateArgs") private static var privateArgs: [String: String] = [:]

    static func loadBrowsers(
        oldBrowsers: [StoredBrowser]
    ) -> [StoredBrowser] {
        if directories.isEmpty {
            let defaultDirectory = Directory(directoryPath: "/Applications")
            directories.append(defaultDirectory)
        }
        
        let validDirectories = directories.map { $0.directoryPath }

        guard let url = URL(string: "https:") else {
            return []
        }

        let urlsForApplications = NSWorkspace.shared.urlsForApplications(toOpen: url)

        var filteredUrlsForApplications = urlsForApplications.filter { urlsForApplication in
            validDirectories.contains { urlsForApplication.path.hasPrefix($0) }
        }
        
        if let browserino = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "xyz.alexstrnik.Browserino") {
            filteredUrlsForApplications.removeAll { $0 == browserino }
        }

        if let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
            if !filteredUrlsForApplications.contains(safari) {
                filteredUrlsForApplications.append(safari)
            }
        }

        // Preserve duplicates and custom names from oldStored list while ensuring all installed apps are present
        let installedSet = Set(filteredUrlsForApplications)

        var result: [StoredBrowser] = []

        // First, keep old entries that are still installed
        for stored in oldBrowsers {
            if installedSet.contains(stored.app) {
                result.append(stored)
            }
        }

        // Append installed apps that are not represented yet
        let represented = Set(result.map { $0.app })
        for appUrl in filteredUrlsForApplications {
            if !represented.contains(appUrl) {
                result.append(StoredBrowser.from(url: appUrl))
            }
        }

        return result
    }
    
    static func openURL(_ urls: [URL], app: URL, isIncognito: Bool, privateArg: String? = nil) {
        guard let bundle = Bundle(url: app) else {
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        
        // prefer passed privateArg, otherwise fall back to stored privateArgs mapping
        let useArg = privateArg ?? privateArgs[bundle.bundleIdentifier!]
        if let useArg = useArg, !useArg.isEmpty {
            if isIncognito {
                configuration.createsNewApplicationInstance = true
                configuration.arguments = [useArg] + urls.map(\.absoluteString)
            } else {
                // pass private arg even when not incognito; URLs will be opened normally
                configuration.arguments = [useArg]
            }
        }
        
        NSWorkspace.shared.open(
            isIncognito ? [] : urls,
            withApplicationAt: app,
            configuration: configuration
        )
    }

    // MARK: - StoredBrowser persistence & migration

    static func storedBrowsersFromDefaults() -> [StoredBrowser] {
        let defaults = UserDefaults.standard

        // Try decode JSON Data first
        if let data = defaults.data(forKey: "browsers") {
            do {
                let decoded = try JSONDecoder().decode([StoredBrowser].self, from: data)
                return decoded
            } catch {
                // fallthrough to try older formats
            }
        }

        // Try array of strings (paths or urls)
        if let array = defaults.array(forKey: "browsers") {
            var result: [StoredBrowser] = []
            for item in array {
                if let url = item as? URL {
                    // try to bring old privateArgs mapping forward
                    let bundleId = Bundle(url: url)?.bundleIdentifier
                    let pArg = bundleId.flatMap { privateArgs[$0] } ?? ""
                    result.append(StoredBrowser.from(url: url, privateArg: pArg))
                } else if let str = item as? String {
                    var url: URL?
                    if str.hasPrefix("/") {
                        url = URL(fileURLWithPath: str)
                    } else if let u = URL(string: str) {
                        url = u
                    }

                    if let url = url {
                        let bundleId = Bundle(url: url)?.bundleIdentifier
                        let pArg = bundleId.flatMap { privateArgs[$0] } ?? ""
                        result.append(StoredBrowser.from(url: url, privateArg: pArg))
                    }
                }
            }

            if !result.isEmpty {
                // save migrated representation
                saveStoredBrowsersToDefaults(result)
            }

            return result
        }

        return []
    }

    static func saveStoredBrowsersToDefaults(_ browsers: [StoredBrowser]) {
        let defaults = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(browsers)
            defaults.set(data, forKey: "browsers")
        } catch {
            print("Failed to encode stored browsers: \(error)")
        }
    }

    static func migrateStoredBrowsersIfNeeded() {
        let defaults = UserDefaults.standard

        // If key exists as Data decoded to StoredBrowser, nothing to do
        if let data = defaults.data(forKey: "browsers") {
            if (try? JSONDecoder().decode([StoredBrowser].self, from: data)) != nil {
                return
            }
        }

        // Otherwise try to read old formats and save new representation
        let migrated = storedBrowsersFromDefaults()
        if !migrated.isEmpty {
            saveStoredBrowsersToDefaults(migrated)
        }
    }

    static func migrateShortcutsToStoredIds() {
        let defaults = UserDefaults.standard
        guard var shortcuts = defaults.dictionary(forKey: "shortcuts") as? [String: String] else {
            return
        }

        // load current stored browsers
        let stored = storedBrowsersFromDefaults()

        // For each shortcut keyed by a bundle identifier, move it to the first matching stored browser id if available
        for (key, value) in shortcuts {
            // skip keys that are UUID strings (already migrated)
            if UUID(uuidString: key) != nil {
                continue
            }

            // key is likely a bundle identifier; find a stored browser with matching bundle id
            if let match = stored.first(where: { bundleIdentifier(of: $0.app) == key }) {
                let newKey = match.id.uuidString
                // only set if not already present
                if shortcuts[newKey] == nil {
                    shortcuts[newKey] = value
                }

                // remove old key
                shortcuts.removeValue(forKey: key)
            }
        }

        defaults.set(shortcuts, forKey: "shortcuts")
    }

    private static func bundleIdentifier(of appUrl: URL) -> String? {
        return Bundle(url: appUrl)?.bundleIdentifier
    }
}
