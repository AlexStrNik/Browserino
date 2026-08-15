//
//  BrowserTabScripting.swift
//  Browserino
//

import AppKit
import Foundation

enum BrowserScriptingFamily {
    case safari
    case chromium
    case unsupported
}

enum BrowserTabScriptingError: LocalizedError {
    case missingBundleIdentifier
    case unsupportedBrowser(String)
    case noWindows
    case emptyURL
    case internalPage
    case appleEventDenied
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingBundleIdentifier:
            return "Could not identify the frontmost browser."
        case .unsupportedBrowser(let name):
            return "\(name) does not support moving tabs. Try Safari, Chrome, Brave, or Edge."
        case .noWindows:
            return "The browser has no open windows."
        case .emptyURL:
            return "This tab has no URL to move."
        case .internalPage:
            return "Start pages and internal browser pages cannot be moved."
        case .appleEventDenied:
            return "Browserino cannot control this browser. Grant access in System Settings → Privacy & Security → Automation, then try again."
        case .scriptFailed(let message):
            return message
        }
    }

    var isAppleEventDenied: Bool {
        if case .appleEventDenied = self {
            return true
        }
        return false
    }
}

enum BrowserTabScripting {
    private static let queue = DispatchQueue(label: "xyz.alexstrnik.Browserino.tab-scripting")

    private static let safariBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.apple.SafariTechnologyPreview"
    ]

    private static let chromiumBundleIDs: Set<String> = [
        "com.google.Chrome",
        "com.google.Chrome.beta",
        "com.google.Chrome.dev",
        "com.google.Chrome.canary",
        "com.brave.Browser",
        "com.brave.Browser.beta",
        "com.brave.Browser.nightly",
        "com.microsoft.edgemac",
        "com.microsoft.edgemac.beta",
        "com.microsoft.edgemac.dev",
        "com.microsoft.edgemac.canary",
        "com.operasoftware.Opera",
        "com.operasoftware.OperaGX",
        "com.vivaldi.Vivaldi",
        "company.thebrowser.Browser",
        "org.chromium.Chromium"
    ]

    private static let blockedSchemes: Set<String> = [
        "about",
        "chrome",
        "edge",
        "brave",
        "safari",
        "opera",
        "vivaldi",
        "chrome-extension",
        "edge-extension"
    ]

    static func family(for bundleIdentifier: String) -> BrowserScriptingFamily {
        if safariBundleIDs.contains(bundleIdentifier) {
            return .safari
        }
        if chromiumBundleIDs.contains(bundleIdentifier) {
            return .chromium
        }
        return .unsupported
    }

    static func currentTabURL(
        in app: NSRunningApplication,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        queue.async {
            completion(Self.readCurrentTabURL(in: app))
        }
    }

    static func closeActiveTab(
        in app: NSRunningApplication,
        completion: @escaping (Error?) -> Void
    ) {
        queue.async {
            switch Self.closeActiveTab(in: app) {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    private static func readCurrentTabURL(in app: NSRunningApplication) -> Result<URL, Error> {
        guard let bundleIdentifier = app.bundleIdentifier else {
            return .failure(BrowserTabScriptingError.missingBundleIdentifier)
        }

        let family = family(for: bundleIdentifier)
        guard family != .unsupported else {
            return .failure(
                BrowserTabScriptingError.unsupportedBrowser(app.localizedName ?? "This browser")
            )
        }

        let tabProperty = family == .safari ? "current tab" : "active tab"
        let source = """
        tell application id "\(bundleIdentifier)"
            if (count of windows) is 0 then
                return ""
            end if
            try
                return URL of \(tabProperty) of window 1
            on error
                return ""
            end try
        end tell
        """

        switch runScript(source) {
        case .failure(let error):
            return .failure(error)
        case .success(let raw):
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed == "missing value" {
                return .failure(BrowserTabScriptingError.emptyURL)
            }
            guard let url = URL(string: trimmed) else {
                return .failure(BrowserTabScriptingError.emptyURL)
            }
            if let scheme = url.scheme?.lowercased(), blockedSchemes.contains(scheme) {
                return .failure(BrowserTabScriptingError.internalPage)
            }
            return .success(url)
        }
    }

    private static func closeActiveTab(in app: NSRunningApplication) -> Result<Void, Error> {
        guard let bundleIdentifier = app.bundleIdentifier else {
            return .failure(BrowserTabScriptingError.missingBundleIdentifier)
        }

        let family = family(for: bundleIdentifier)
        guard family != .unsupported else {
            return .failure(
                BrowserTabScriptingError.unsupportedBrowser(app.localizedName ?? "This browser")
            )
        }

        let tabProperty = family == .safari ? "current tab" : "active tab"
        let source = """
        tell application id "\(bundleIdentifier)"
            if (count of windows) is 0 then
                return
            end if
            close \(tabProperty) of window 1
        end tell
        """

        switch runScript(source) {
        case .failure(let error):
            return .failure(error)
        case .success:
            return .success(())
        }
    }

    private static func runScript(_ source: String) -> Result<String, Error> {
        guard let script = NSAppleScript(source: source) else {
            return .failure(BrowserTabScriptingError.scriptFailed("Could not create AppleScript."))
        }

        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)

        if let errorInfo {
            return .failure(mapAppleScriptError(errorInfo))
        }

        return .success(result.stringValue ?? "")
    }

    private static func mapAppleScriptError(_ errorInfo: NSDictionary) -> BrowserTabScriptingError {
        let number = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
        // errAEEventNotPermitted, errAEPrivilegeError, osErrPermission
        if number == -1743 || number == -10004 || number == -1744 {
            return .appleEventDenied
        }

        let message =
            (errorInfo[NSAppleScript.errorMessage] as? String)
            ?? (errorInfo[NSAppleScript.errorBriefMessage] as? String)
            ?? "The browser did not respond."

        let lowered = message.lowercased()
        if lowered.contains("not allowed to send apple events")
            || lowered.contains("not authorized to send apple events")
            || lowered.contains("not permitted")
        {
            return .appleEventDenied
        }

        return .scriptFailed(message)
    }
}
