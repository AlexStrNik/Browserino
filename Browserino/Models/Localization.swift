import Foundation
import SwiftUI
import Combine

@MainActor
final class Localization: ObservableObject {
    static let shared = Localization()
    @Published private(set) var activeLanguage: String
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "language")
            updateLanguage()
        }
    }
    private var observation: AnyCancellable?

    private init() {
        let initial = UserDefaults.standard.string(forKey: "language") ?? ""
        selectedLanguage = initial
        activeLanguage = LanguagePolicy.resolve(selection: initial, preferred: Locale.preferredLanguages)
        observation = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { _ in
                Task { @MainActor in
                    let service = Localization.shared
                    let stored = UserDefaults.standard.string(forKey: "language") ?? ""
                    if service.selectedLanguage != stored { service.selectedLanguage = stored }
                    service.updateLanguage()
                }
            }
    }
    private func updateLanguage() {
        let resolved = LanguagePolicy.resolve(selection: selectedLanguage, preferred: Locale.preferredLanguages)
        if activeLanguage != resolved { activeLanguage = resolved }
    }
    var bundle: Bundle {
        Bundle.main.path(forResource: activeLanguage, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }
    func text(_ key: String) -> String {
        let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
        guard localized == key,
              let englishPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let english = Bundle(path: englishPath) else { return localized }
        return english.localizedString(forKey: key, value: key, table: nil)
    }
    func format(_ key: String, _ value: String) -> String {
        String(format: text(key), locale: Locale(identifier: activeLanguage), value)
    }
}

@MainActor
enum L10n {
    static func text(_ key: String) -> String { Localization.shared.text(key) }
    static func format(_ key: String, _ value: String) -> String { Localization.shared.format(key, value) }
}

struct LocalizedRoot<Content: View>: View {
    @ObservedObject private var localization = Localization.shared
    @ViewBuilder let content: () -> Content
    var body: some View {
        content()
            .environment(\.locale, Locale(identifier: localization.activeLanguage))
            .id(localization.activeLanguage)
    }
}
