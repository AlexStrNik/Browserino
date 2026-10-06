import Foundation

enum LanguagePolicy {
    static let options: [(id: String, name: String)] = [
        ("en", "English"), ("ru", "Русский"), ("de", "Deutsch"), ("fr", "Français"),
        ("es", "Español"), ("pt-BR", "Português (Brasil)"), ("it", "Italiano"),
        ("ja", "日本語"), ("ko", "한국어"), ("zh-Hans", "简体中文")
    ]
    static func resolve(selection: String, preferred: [String]) -> String {
        let supported = options.map(\.id)
        if supported.contains(selection) { return selection }
        return Bundle.preferredLocalizations(from: supported, forPreferences: preferred).first ?? "en"
    }
}

enum ProfilePathPolicy {
    static func isSafeComponent(_ value: String) -> Bool {
        !value.isEmpty && value != "." && value != ".." && !value.contains("/")
            && !value.contains("\\") && !value.contains("\0")
    }
    static func contains(_ url: URL, in root: URL) -> Bool {
        func canonical(_ value: URL) -> [String] {
            var resolved = URL(fileURLWithPath: "/")
            for component in value.standardizedFileURL.pathComponents.dropFirst() {
                resolved.appendPathComponent(component)
                resolved = resolved.resolvingSymlinksInPath()
            }
            return resolved.pathComponents
        }
        let parent = canonical(root)
        let child = canonical(url)
        return child.count > parent.count && child.starts(with: parent)
    }
}

struct SourceTabIdentity: Equatable, Sendable {
    let windowID: Int
    let tabID: Int
    let url: String
    func matches(_ other: SourceTabIdentity) -> Bool { self == other }
}

enum MovePolicy {
    static func shouldClose(openSucceeded: Bool, closeEnabled: Bool, original: SourceTabIdentity, current: SourceTabIdentity?) -> Bool {
        openSucceeded && closeEnabled && current == original
    }
}


enum TargetPolicy {
    static func isHidden(_ target: BrowserTarget, hidden: [BrowserTarget]) -> Bool {
        hidden.contains(target) || hidden.contains(BrowserTarget(app: target.app))
    }
    static func visible(_ targets: [BrowserTarget], hidden: [BrowserTarget], profilesEnabled: Bool) -> [BrowserTarget] {
        let visible = targets.filter { !isHidden($0, hidden: hidden) }
        guard !profilesEnabled else { return visible }
        var seen = Set<URL>()
        return visible.compactMap { seen.insert($0.app).inserted ? BrowserTarget(app: $0.app) : nil }
    }
    static func preserveHidden(oldTargets: [BrowserTarget], newTargets: [BrowserTarget], hidden: [BrowserTarget]) -> [BrowserTarget] {
        var result = hidden
        for target in newTargets where target.profile == nil {
            let old = oldTargets.filter { $0.app == target.app }
            if !old.isEmpty, old.allSatisfy({ isHidden($0, hidden: hidden) }), !result.contains(target) { result.append(target) }
        }
        return result
    }
    static func toggle(_ target: BrowserTarget, targets: [BrowserTarget], hidden: [BrowserTarget]) -> [BrowserTarget] {
        var result = hidden
        if target.profile == nil {
            let appTargets = targets.filter { $0.app == target.app }
            if hidden.contains(target) || (!appTargets.isEmpty && appTargets.allSatisfy({ isHidden($0, hidden: hidden) })) {
                result.removeAll { $0.app == target.app }
            } else { result.append(target) }
        } else {
            let base = BrowserTarget(app: target.app)
            if result.contains(base) {
                result.removeAll { $0 == base }
                for row in targets where row.app == target.app && !result.contains(row) { result.append(row) }
            }
            if let index = result.firstIndex(of: target) { result.remove(at: index) }
            else { result.append(target) }
        }
        return result
    }
}
