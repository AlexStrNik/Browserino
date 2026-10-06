import Foundation
import CoreFoundation

enum SettingsPolicy {
    static let booleans: Set<String> = ["copy_closeAfterCopy", "copy_alternativeShortcut", "showInMenuBar", "apps_atTop", "profilesEnabled", "switch_closeSourceTab"]
    static let keys = booleans.union(["browsers", "hiddenBrowsers", "apps", "rules", "directories", "privateArgs", "shortcuts", "profileNames", "language", "KeyboardShortcuts_moveCurrentTab"])

    struct LegacyProfile: Codable { let directoryName: String; let displayName: String; let isHidden: Bool }
    static func migrateLegacyProfiles(defaults: UserDefaults, chrome: URL) {
        guard !defaults.bool(forKey: "profileMigration48"),
              let raw = defaults.string(forKey: "chromeProfiles"),
              let data = raw.data(using: .utf8),
              let profiles = try? JSONDecoder().decode([LegacyProfile].self, from: data),
              profiles.allSatisfy({ ProfilePathPolicy.isSafeComponent($0.directoryName) }) else { return }
        func dictionary(_ key: String) -> [String: String] {
            guard let raw = defaults.string(forKey: key), let data = raw.data(using: .utf8) else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
        var names = dictionary("profileNames"), shortcuts = dictionary("shortcuts")
        var hidden = defaults.string(forKey: "hiddenBrowsers").flatMap { $0.data(using: .utf8) }.flatMap { try? JSONDecoder().decode([BrowserTarget].self, from: $0) } ?? []
        for profile in profiles {
            let target = BrowserTarget(app: chrome, profile: profile.directoryName)
            let key = target.shortcutKey(bundleIdentifier: "com.google.Chrome")
            if names[key] == nil { names[key] = profile.displayName }
            if shortcuts[key] == nil { shortcuts[key] = shortcuts["com.google.Chrome::" + profile.directoryName] }
            if profile.isHidden && !hidden.contains(target) { hidden.append(target) }
        }
        for (key, value) in [("profileNames", names), ("shortcuts", shortcuts)] {
            if let data = try? JSONEncoder().encode(value), let raw = String(data: data, encoding: .utf8) { defaults.set(raw, forKey: key) }
        }
        if let data = try? JSONEncoder().encode(hidden), let raw = String(data: data, encoding: .utf8) { defaults.set(raw, forKey: "hiddenBrowsers") }
        if defaults.object(forKey: "profilesEnabled") == nil, let enabled = defaults.object(forKey: "chromeProfilesEnabled") as? Bool { defaults.set(enabled, forKey: "profilesEnabled") }
        defaults.set(true, forKey: "profileMigration48")
    }

    static func validate(_ settings: [String: Any]) throws -> [String: Any] {
        var normalized = settings
        if let legacy = settings["chromeProfiles"] {
            guard let raw = legacy as? String, let data = raw.data(using: .utf8) else { throw CocoaError(.fileReadCorruptFile) }
            let profiles = try JSONDecoder().decode([LegacyProfile].self, from: data)
            guard profiles.allSatisfy({ ProfilePathPolicy.isSafeComponent($0.directoryName) }) else { throw CocoaError(.fileReadCorruptFile) }
            func dictionary(_ key: String) throws -> [String: String] {
                guard let value = settings[key] else { return [:] }
                guard let raw = value as? String else { throw CocoaError(.fileReadCorruptFile) }
                return try JSONDecoder().decode([String: String].self, from: Data(raw.utf8))
            }
            var names = try dictionary("profileNames"), shortcuts = try dictionary("shortcuts")
            var hidden: [BrowserTarget] = []
            if let raw = settings["hiddenBrowsers"] as? String { hidden = try JSONDecoder().decode([BrowserTarget].self, from: Data(raw.utf8)) }
            let browser = URL(fileURLWithPath: "/Applications/Google Chrome.app")
            for profile in profiles {
                let target = BrowserTarget(app: browser, profile: profile.directoryName)
                let key = target.shortcutKey(bundleIdentifier: "com.google.Chrome")
                if names[key] == nil { names[key] = profile.displayName }
                if shortcuts[key] == nil { shortcuts[key] = shortcuts["com.google.Chrome::" + profile.directoryName] }
                if profile.isHidden && !hidden.contains(target) { hidden.append(target) }
            }
            normalized["profileNames"] = String(decoding: try JSONEncoder().encode(names), as: UTF8.self)
            normalized["shortcuts"] = String(decoding: try JSONEncoder().encode(shortcuts), as: UTF8.self)
            normalized["hiddenBrowsers"] = String(decoding: try JSONEncoder().encode(hidden), as: UTF8.self)
        }
        if let legacy = settings["chromeProfilesEnabled"] {
            guard let number = legacy as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { throw CocoaError(.fileReadCorruptFile) }
            if normalized["profilesEnabled"] == nil { normalized["profilesEnabled"] = legacy }
        }
        let accepted = normalized.filter { keys.contains($0.key) }
        for (key, value) in accepted {
            if booleans.contains(key) {
                guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { throw CocoaError(.fileReadCorruptFile) }
                continue
            }
            guard let string = value as? String else { throw CocoaError(.fileReadCorruptFile) }
            if key == "language" {
                guard string.isEmpty || LanguagePolicy.options.contains(where: { $0.id == string }) else { throw CocoaError(.fileReadCorruptFile) }
                continue
            }
            guard let data = string.data(using: .utf8) else { throw CocoaError(.fileReadCorruptFile) }
            switch key {
            case "browsers", "hiddenBrowsers":
                let targets = try JSONDecoder().decode([BrowserTarget].self, from: data)
                guard targets.allSatisfy({ $0.app.isFileURL && $0.app.pathExtension == "app" && ($0.profile.map(ProfilePathPolicy.isSafeComponent) ?? true) }) else { throw CocoaError(.fileReadCorruptFile) }
            case "apps", "rules":
                struct Mapping: Decodable { let host: String; let schemeOverride: String; let app: URL; let profile: String? }
                struct Pattern: Decodable { let regex: String; let app: URL; let profile: String?; let profileDirectory: String? }
                let targets: [BrowserTarget]
                if key == "rules" { targets = try JSONDecoder().decode([Pattern].self, from: data).map { BrowserTarget(app: $0.app, profile: $0.profile ?? $0.profileDirectory) } }
                else { targets = try JSONDecoder().decode([Mapping].self, from: data).map { BrowserTarget(app: $0.app, profile: $0.profile) } }
                guard targets.allSatisfy({ $0.app.isFileURL && $0.app.pathExtension == "app" && ($0.profile.map(ProfilePathPolicy.isSafeComponent) ?? true) }) else { throw CocoaError(.fileReadCorruptFile) }
            case "KeyboardShortcuts_moveCurrentTab":
                struct Shortcut: Decodable { let carbonKeyCode: Int; let carbonModifiers: Int }
                let shortcut = try JSONDecoder().decode(Shortcut.self, from: data)
                guard (0...255).contains(shortcut.carbonKeyCode), UInt32(exactly: shortcut.carbonModifiers) != nil else { throw CocoaError(.fileReadCorruptFile) }
            case "directories":
                guard let rows = try JSONSerialization.jsonObject(with: data) as? [[String: String]], rows.allSatisfy({ $0["directoryPath"]?.hasPrefix("/") == true }) else { throw CocoaError(.fileReadCorruptFile) }
            default: _ = try JSONDecoder().decode([String: String].self, from: data)
            }
        }
        return accepted
    }
}
