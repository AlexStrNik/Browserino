// Adapted from upstream PR #61; close refers to a captured tab, never the active tab.
import AppKit
import Carbon
import Foundation

struct SourceTabSnapshot: Sendable {
    let bundleIdentifier: String
    let processIdentifier: pid_t
    let sourceName: String
    let identity: SourceTabIdentity
    let isSafari: Bool
    var url: URL { URL(string: identity.url)! }
}

enum BrowserScriptingFamily { case safari, chromium, unsupported }

enum BrowserTabScriptingError: Error, Sendable, Equatable {
    case denied, unavailable, changed, unsafeClose, failed(String)
}

@MainActor
enum BrowserTabScripting {
    static func family(for id: String) -> BrowserScriptingFamily {
        guard id.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || [45, 46, 95].contains($0) }) else { return .unsupported }
        if ["com.apple.Safari", "com.apple.SafariTechnologyPreview"].contains(id) { return .safari }
        let ids = ["com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac", "com.operasoftware.Opera", "com.operasoftware.OperaGX", "com.vivaldi.Vivaldi", "company.thebrowser.Browser", "org.chromium.Chromium"]
        return ids.contains(where: { id == $0 || id.hasPrefix($0 + ".") }) ? .chromium : .unsupported
    }

    static func currentTab(in app: NSRunningApplication) async throws -> SourceTabSnapshot {
        guard let identifier = app.bundleIdentifier, family(for: identifier) != .unsupported else {
            throw BrowserTabScriptingError.unavailable
        }
        guard NSWorkspace.shared.runningApplications.filter({ $0.bundleIdentifier == identifier }).count == 1 else { throw BrowserTabScriptingError.unavailable }
        let pid = app.processIdentifier
        let name = app.localizedName ?? identifier
        let safari = family(for: identifier) == .safari
        return try await Task.detached {
            try read(identifier: identifier, pid: pid, name: name, safari: safari)
        }.value
    }

    static func close(_ snapshot: SourceTabSnapshot) async throws {
        guard NSWorkspace.shared.runningApplications.filter({ $0.bundleIdentifier == snapshot.bundleIdentifier }).count == 1,
              NSRunningApplication(processIdentifier: snapshot.processIdentifier)?.bundleIdentifier == snapshot.bundleIdentifier else {
            throw BrowserTabScriptingError.changed
        }
        // Safari's scripting dictionary exposes no stable tab ID. Keep its source
        // open rather than ever closing a different tab after a reorder.
        guard !snapshot.isSafari else { throw BrowserTabScriptingError.unsafeClose }
        try await Task.detached { try closeCaptured(snapshot) }.value
    }

    nonisolated private static func read(identifier: String, pid: pid_t, name: String, safari: Bool) throws -> SourceTabSnapshot {
        let property = safari ? "current tab" : "active tab"
        let tabID = safari ? "0" : "(id of t) as integer"
        let result = try runScript("""
        with timeout of 5 seconds
            tell application id "\(identifier)"
                if (count of windows) is 0 then error "No window"
                set w to window 1
                set t to \(property) of w
                return {(id of w) as integer, \(tabID), URL of t}
            end tell
        end timeout
        """)
        guard let window = result.atIndex(1), let tab = result.atIndex(2),
              let raw = result.atIndex(3)?.stringValue,
              let url = URL(string: raw), url.browserinoIncomingURL != nil,
              ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            throw BrowserTabScriptingError.unavailable
        }
        return SourceTabSnapshot(bundleIdentifier: identifier, processIdentifier: pid, sourceName: name,
            identity: SourceTabIdentity(windowID: Int(window.int32Value), tabID: Int(tab.int32Value), url: raw), isSafari: safari)
    }

    nonisolated private static func closeCaptured(_ source: SourceTabSnapshot) throws {
        // The URL is supplied as a typed Apple Event parameter, not script source.
        // Integer IDs came from the scripting bridge and cannot inject script code.
        let result = try runScript("""
        on closeCapturedTab(originalURL)
        with timeout of 5 seconds
            tell application id "\(source.bundleIdentifier)"
                repeat with w in windows
                    if (id of w) as integer is \(source.identity.windowID) then
                        repeat with t in tabs of w
                            if (id of t) as integer is \(source.identity.tabID) then
                                if URL of t is originalURL then
                                    close t
                                    return true
                                end if
                                return false
                            end if
                        end repeat
                    end if
                end repeat
                return false
            end tell
        end timeout
        end closeCapturedTab
        """, argument: source.identity.url)
        guard result.booleanValue else { throw BrowserTabScriptingError.changed }
    }

    nonisolated private static func runScript(_ source: String, argument: String? = nil) throws -> NSAppleEventDescriptor {
        guard let script = NSAppleScript(source: source) else { throw BrowserTabScriptingError.unavailable }
        var error: NSDictionary?
        let result: NSAppleEventDescriptor
        if let argument {
            let event = NSAppleEventDescriptor(eventClass: AEEventClass(kASAppleScriptSuite), eventID: AEEventID(kASSubroutineEvent), targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
            event.setParam(NSAppleEventDescriptor(string: "closeCapturedTab"), forKeyword: AEKeyword(keyASSubroutineName))
            let parameters = NSAppleEventDescriptor.list()
            parameters.insert(NSAppleEventDescriptor(string: argument), at: 1)
            event.setParam(parameters, forKeyword: AEKeyword(keyDirectObject))
            result = script.executeAppleEvent(event, error: &error)
        } else {
            result = script.executeAndReturnError(&error)
        }
        if let error {
            let number = error[NSAppleScript.errorNumber] as? Int ?? 0
            if [-1743, -10004, -1744].contains(number) { throw BrowserTabScriptingError.denied }
            throw BrowserTabScriptingError.failed(error[NSAppleScript.errorMessage] as? String ?? "")
        }
        return result
    }
}
