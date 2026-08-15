//
//  BrowserSwitchService.swift
//  Browserino
//

import AppKit
import CoreGraphics
import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let moveCurrentTab = Self("moveCurrentTab")
}

protocol BrowserSwitchPresenting: AnyObject {
    func presentMovePrompt(url: URL, source: NSRunningApplication)
}

enum BrowserSwitchError: LocalizedError {
    case noBrowser
    case unsupportedBrowser(String)
    case noDestination
    case openFailed(String)
    case closeFailed(String)

    var errorDescription: String? {
        switch self {
        case .noBrowser:
            return "Bring a supported browser to the front and try again."
        case .unsupportedBrowser(let name):
            return "\(name) does not support moving tabs. Try Safari, Chrome, Brave, or Edge."
        case .noDestination:
            return "Show another browser in the Browsers list, or unhide one, then try again."
        case .openFailed(let message):
            return message
        case .closeFailed(let message):
            return "The tab was opened in the destination browser, but the original tab could not be closed. \(message)"
        }
    }

    var messageText: String {
        switch self {
        case .noBrowser:
            return "No browser tab to move"
        case .unsupportedBrowser:
            return "This browser cannot expose its current tab"
        case .noDestination:
            return "No other browser to move to"
        case .openFailed:
            return "Could not open the tab in the selected browser"
        case .closeFailed:
            return "Could not close the original tab"
        }
    }
}

final class BrowserSwitchService {
    static let shared = BrowserSwitchService()

    weak var presenter: BrowserSwitchPresenting?

    private var lastNonSelfApp: NSRunningApplication?
    private var activationObserver: NSObjectProtocol?

    private init() {}

    func startTracking() {
        let front = NSWorkspace.shared.frontmostApplication
        if front?.bundleIdentifier != Bundle.main.bundleIdentifier {
            lastNonSelfApp = front
        }

        if activationObserver == nil {
            activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard
                    let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                        as? NSRunningApplication,
                    app.bundleIdentifier != Bundle.main.bundleIdentifier
                else {
                    return
                }
                self?.lastNonSelfApp = app
            }
        }
    }

    func beginMove(preferFrontmost: Bool) {
        let source: NSRunningApplication
        do {
            source = try resolveSource(preferFrontmost: preferFrontmost)
        } catch {
            presentError(error)
            return
        }

        BrowserTabScripting.currentTabURL(in: source) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self?.presenter?.presentMovePrompt(url: url, source: source)
                case .failure(let error):
                    self?.presentError(error)
                }
            }
        }
    }

    func presentOpenFailedAlert(_ error: Error) {
        presentError(BrowserSwitchError.openFailed(error.localizedDescription))
    }

    func presentCloseFailedAlert(_ error: Error) {
        presentError(BrowserSwitchError.closeFailed(error.localizedDescription))
    }

    func presentNoDestinationAlert() {
        presentError(BrowserSwitchError.noDestination)
    }

    private func resolveSource(preferFrontmost: Bool) throws -> NSRunningApplication {
        let selfID = Bundle.main.bundleIdentifier
        var ordered: [NSRunningApplication] = []

        if preferFrontmost {
            if let front = NSWorkspace.shared.frontmostApplication {
                ordered.append(front)
            }
        } else {
            if let last = lastNonSelfApp, !last.isTerminated {
                ordered.append(last)
            }
            if let front = NSWorkspace.shared.frontmostApplication {
                ordered.append(front)
            }
        }

        ordered.append(contentsOf: appsInZOrder())

        var seen = Set<pid_t>()
        let unique = ordered.filter { app in
            guard app.bundleIdentifier != selfID else {
                return false
            }
            guard !seen.contains(app.processIdentifier) else {
                return false
            }
            seen.insert(app.processIdentifier)
            return true
        }

        if let first = unique.first, isConfiguredBrowser(first) {
            switch family(for: first) {
            case .unsupported:
                throw BrowserSwitchError.unsupportedBrowser(first.localizedName ?? "This browser")
            case .safari, .chromium:
                return first
            }
        }

        if let match = unique.first(where: {
            isConfiguredBrowser($0) && family(for: $0) != .unsupported
        }) {
            return match
        }

        if let unsupported = unique.first(where: { isConfiguredBrowser($0) }) {
            throw BrowserSwitchError.unsupportedBrowser(unsupported.localizedName ?? "This browser")
        }

        throw BrowserSwitchError.noBrowser
    }

    private func appsInZOrder() -> [NSRunningApplication] {
        guard
            let info = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]]
        else {
            return []
        }

        var seen = Set<pid_t>()
        var apps: [NSRunningApplication] = []

        for window in info {
            guard let pid = window[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }
            guard !seen.contains(pid) else {
                continue
            }
            seen.insert(pid)

            if let app = NSRunningApplication(processIdentifier: pid) {
                apps.append(app)
            }
        }

        return apps
    }

    private func configuredBrowserBundleIDs() -> Set<String> {
        guard
            let raw = UserDefaults.standard.string(forKey: "browsers"),
            let urls = [URL](rawValue: raw)
        else {
            return []
        }

        return Set(urls.compactMap { Bundle(url: $0)?.bundleIdentifier })
    }

    private func isConfiguredBrowser(_ app: NSRunningApplication) -> Bool {
        guard let bundleIdentifier = app.bundleIdentifier else {
            return false
        }
        return configuredBrowserBundleIDs().contains(bundleIdentifier)
    }

    private func family(for app: NSRunningApplication) -> BrowserScriptingFamily {
        guard let bundleIdentifier = app.bundleIdentifier else {
            return .unsupported
        }
        return BrowserTabScripting.family(for: bundleIdentifier)
    }

    private func presentError(_ error: Error) {
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)

            let alert = NSAlert()
            if let switchError = error as? BrowserSwitchError {
                alert.messageText = switchError.messageText
                alert.informativeText = switchError.localizedDescription
            } else if let scriptingError = error as? BrowserTabScriptingError {
                alert.messageText = scriptingError.isAppleEventDenied
                    ? "Browserino cannot control this browser"
                    : "Could not read the current tab"
                alert.informativeText = scriptingError.localizedDescription
            } else {
                alert.messageText = "Could not move the current tab"
                alert.informativeText = error.localizedDescription
            }

            alert.addButton(withTitle: "OK")

            let denied =
                (error as? BrowserTabScriptingError)?.isAppleEventDenied == true
            if denied {
                alert.addButton(withTitle: "Open System Settings")
            }

            let response = alert.runModal()
            if denied, response == .alertSecondButtonReturn {
                Self.openAutomationSettings()
            }
        }
    }

    private static func openAutomationSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Automation",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        ]

        for string in urls {
            if let url = URL(string: string), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
