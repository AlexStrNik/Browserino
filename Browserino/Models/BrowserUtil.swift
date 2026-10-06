//  BrowserUtil.swift
//  Browserino
//
//  Created by byt3m4st3r.
//

import AppKit
import Foundation
import SwiftUI

@MainActor
class BrowserUtil {
    @AppStorage("directories") private static var directories: [Directory] = []
    @AppStorage("privateArgs") private static var privateArgs: [String: String] = [:]

    static func rescanBrowsers(oldBrowsers: [BrowserTarget]) -> [BrowserTarget]? {
        if let raw = UserDefaults.standard.string(forKey: "browsers"), [BrowserTarget](rawValue: raw) == nil {
            presentError(NSError(domain: "Browserino", code: 2, userInfo: [NSLocalizedDescriptionKey: L10n.text("errors.invalid_settings_format")]))
            return nil
        }
        return loadBrowsers(oldBrowsers: oldBrowsers)
    }

    static func loadBrowsers(
        oldBrowsers: [BrowserTarget]
    ) -> [BrowserTarget] {
        if directories.isEmpty {
            let defaultDirectory = Directory(directoryPath: "/Applications")
            directories.append(defaultDirectory)
        }
        
        let validDirectories = directories.map { $0.directoryPath }

        guard let url = URL(string: "https:") else {
            return []
        }

        let urlsForApplications = NSWorkspace.shared.urlsForApplications(toOpen: url)

        var seen = Set<URL>()
        var filteredUrlsForApplications = urlsForApplications.filter { application in
            let canonical = application.standardizedFileURL.resolvingSymlinksInPath()
            return seen.insert(canonical).inserted && validDirectories.contains { directory in
                canonical.pathComponents.starts(with: URL(fileURLWithPath: directory).standardizedFileURL.resolvingSymlinksInPath().pathComponents)
            }
        }

        if let browserino = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "xyz.alexstrnik.Browserino") {
            filteredUrlsForApplications.removeAll { $0 == browserino }
        }

        if let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
            if !filteredUrlsForApplications.contains(safari) {
                filteredUrlsForApplications.append(safari)
            }
        }
        
        let discovered = filteredUrlsForApplications.flatMap { app in
            targets(forAppAt: app, oldBrowsers: oldBrowsers)
        }

        let hidden = UserDefaults.standard.string(forKey: "hiddenBrowsers").flatMap { [BrowserTarget](rawValue: $0) } ?? []
        let preserved = TargetPolicy.preserveHidden(oldTargets: oldBrowsers, newTargets: discovered, hidden: hidden)
        if preserved != hidden { UserDefaults.standard.set(preserved.rawValue, forKey: "hiddenBrowsers") }
        return merge(discovered: discovered, into: oldBrowsers)
    }

    /// A browser with several profiles is represented by its profiles rather than
    /// by itself — opening "Chrome" when every link could go to a specific profile
    /// is just an extra row that does nothing distinct.
    private static func targets(
        forAppAt app: URL,
        oldBrowsers: [BrowserTarget]
    ) -> [BrowserTarget] {
        guard UserDefaults.standard.object(forKey: "profilesEnabled") as? Bool != false else {
            let known = oldBrowsers.filter { $0.app == app }
            return known.isEmpty ? [BrowserTarget(app: app)] : known
        }
        guard let profiles = ChromiumProfileService.profiles(forAppAt: app) else {
            // Local State unreadable. If this is a Chromium browser we already knew
            // profiles for, keep them: dropping to a bare entry here would discard
            // the user's ordering, hidden flags and shortcuts on one bad rescan.
            guard ChromiumProfileService.userDataDirectory(forAppAt: app) != nil else {
                return [BrowserTarget(app: app)]
            }

            let known = oldBrowsers.filter { $0.app == app }

            return known.isEmpty ? [BrowserTarget(app: app)] : known
        }

        guard profiles.count > 1 else {
            return [BrowserTarget(app: app)]
        }

        return profiles.map { BrowserTarget(app: app, profile: $0.directory) }
    }

    /// Keeps the order the user arranged, and drops anything newly discovered next
    /// to its own browser rather than at the end.
    private static func merge(
        discovered: [BrowserTarget],
        into oldBrowsers: [BrowserTarget]
    ) -> [BrowserTarget] {
        let discoveredTargets = Set(discovered)

        var merged: [BrowserTarget] = []
        var placed: Set<BrowserTarget> = []

        for old in oldBrowsers {
            if discoveredTargets.contains(old) {
                if placed.insert(old).inserted {
                    merged.append(old)
                }
            } else {
                // This exact entry is gone, but the same browser may now be
                // represented differently — profiles replacing the plain row on
                // first run. Those belong where the user had put the browser, not
                // at the bottom of the list.
                for target in discovered
                where target.app == old.app && placed.insert(target).inserted {
                    merged.append(target)
                }
            }
        }

        for target in discovered where !placed.contains(target) {
            if let last = merged.lastIndex(where: { $0.app == target.app }) {
                merged.insert(target, at: last + 1)
            } else {
                merged.append(target)
            }

            placed.insert(target)
        }

        return merged
    }
    
    static func openURL(
        _ urls: [URL], target: BrowserTarget, isIncognito: Bool,
        completionHandler: (@MainActor @Sendable (NSRunningApplication?, Error?) -> Void)? = nil
    ) {
        func fail(_ key: String) {
            let error = NSError(domain: "Browserino", code: 1, userInfo: [NSLocalizedDescriptionKey: L10n.text(key)])
            if let completionHandler { completionHandler(nil, error) }
            else { presentError(error) }
        }
        guard !urls.isEmpty, target.app.isFileURL,
              target.app.pathExtension.lowercased() == "app",
              let bundle = Bundle(url: target.app), let identifier = bundle.bundleIdentifier,
              identifier != Bundle.main.bundleIdentifier else {
            fail("errors.application_unavailable")
            return
        }
        var arguments: [String] = []
        if let profile = target.profile {
            guard ProfilePathPolicy.isSafeComponent(profile),
                  let profiles = ChromiumProfileService.profiles(forAppAt: target.app),
                  profiles.contains(where: { $0.directory == profile }) else {
                fail("errors.profile_unavailable")
                return
            }
            arguments.append("--profile-directory=\(profile)")
        }
        if isIncognito {
            guard let privateArg = privateArgs[identifier], !privateArg.isEmpty else {
                fail("errors.private_argument_missing")
                return
            }
            arguments.append(privateArg)
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = !arguments.isEmpty
        configuration.arguments = arguments.isEmpty ? [] : arguments + urls.map(\.absoluteString)
        NSWorkspace.shared.open(arguments.isEmpty ? urls : [], withApplicationAt: target.app, configuration: configuration) { app, error in
            Task { @MainActor in
                if let completionHandler { completionHandler(app, error) }
                else if let error { presentError(error) }
            }
        }
    }

    @discardableResult
    static func runAlert(_ alert: NSAlert) -> NSApplication.ModalResponse {
        let selector = NSApp.windows.compactMap { $0 as? BrowserinoWindow }.first { $0.contentView != nil }
        selector?.presentingAlert = true
        defer {
            selector?.presentingAlert = false
            if let selector, selector.contentView != nil { selector.makeKeyAndOrderFront(nil) }
        }
        return alert.runModal()
    }

    static func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = L10n.text("errors.open_link.title")
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: L10n.text("common.ok"))
        runAlert(alert)
    }
}
