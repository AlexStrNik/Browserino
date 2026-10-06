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

@MainActor
protocol BrowserSwitchPresenting: AnyObject {
    func presentMovePrompt(snapshot: SourceTabSnapshot)
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

@MainActor
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
                Task { @MainActor in self?.lastNonSelfApp = app }
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

        Task {
            do {
                let snapshot = try await BrowserTabScripting.currentTab(in: source)
                presenter?.presentMovePrompt(snapshot: snapshot)
            } catch { presentError(error) }
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
            let urls = [BrowserTarget](rawValue: raw)
        else {
            return []
        }

        return Set(urls.compactMap { Bundle(url: $0.app)?.bundleIdentifier })
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
        NSApplication.shared.activateCompat()
        let alert = NSAlert()
        alert.messageText = L10n.text("errors.move_tab.title")
        switch error {
        case BrowserSwitchError.noBrowser, BrowserSwitchError.unsupportedBrowser:
            alert.informativeText = L10n.text("errors.move_tab.no_supported_browser")
        case BrowserSwitchError.noDestination:
            alert.informativeText = L10n.text("errors.move_tab.no_destination")
        case BrowserSwitchError.closeFailed:
            alert.informativeText = L10n.text("tabs.transfer.source_kept")
        case BrowserTabScriptingError.denied:
            alert.informativeText = L10n.text("errors.automation_permission_required")
        case BrowserTabScriptingError.changed, BrowserTabScriptingError.unsafeClose:
            alert.informativeText = L10n.text("tabs.transfer.source_kept")
        default: alert.informativeText = error.localizedDescription
        }
        alert.addButton(withTitle: L10n.text("common.ok"))
        let denied = (error as? BrowserTabScriptingError) == .denied
        if denied { alert.addButton(withTitle: L10n.text("common.open_system_settings")) }
        if BrowserUtil.runAlert(alert) == .alertSecondButtonReturn && denied { Self.openAutomationSettings() }
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
