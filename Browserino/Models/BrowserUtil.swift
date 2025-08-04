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
        oldBrowsers: [URL]
    ) -> [URL] {
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
        
        var oldPositions: [URL: Int] = [:]
        for (index, browser) in oldBrowsers.enumerated() {
            oldPositions[browser] = index
        }
        
        filteredUrlsForApplications.sort { browser1, browser2 in
            if let pos1 = oldPositions[browser1], let pos2 = oldPositions[browser2] {
                return pos1 < pos2
            }
            else if oldPositions[browser1] != nil {
                return true
            }
            else if oldPositions[browser2] != nil {
                return false
            }
            
            return true
        }
        
        return filteredUrlsForApplications
    }
    
    static func openURL(_ urls: [URL], app: URL, isIncognito: Bool) {
        guard let bundle = Bundle(url: app) else {
            return
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        
        if isIncognito, let privateArg = privateArgs[bundle.bundleIdentifier!] {
            configuration.createsNewApplicationInstance = true
            configuration.arguments = [privateArg] + urls.map(\.absoluteString)
        }
        
        NSWorkspace.shared.open(
            isIncognito ? [] : urls,
            withApplicationAt: app,
            configuration: configuration
        )
    }
}
