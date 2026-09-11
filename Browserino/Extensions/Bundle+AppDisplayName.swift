//
//  Bundle+AppDisplayName.swift
//  Browserino
//

import Foundation

extension Bundle {
    /// CFBundleName is optional in Info.plist and plenty of shipping apps omit it.
    var appDisplayName: String {
        infoDictionary?["CFBundleName"] as? String
            ?? infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundleURL.appDisplayName
    }
}

extension URL {
    /// Best-effort name for an app bundle that no longer resolves on disk,
    /// e.g. one the user has uninstalled or renamed since it was stored.
    var appDisplayName: String {
        deletingPathExtension().lastPathComponent
    }
}
