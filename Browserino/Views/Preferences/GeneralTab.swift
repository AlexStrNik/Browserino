//
//  GeneralTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI
import UniformTypeIdentifiers
import ServiceManagement
import CoreFoundation
import KeyboardShortcuts
import Combine

struct SettingsDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    // Serialized on the way in: [String: Any] cannot cross a Sendable boundary.
    private var data: Data

    init(settings: [String: Any] = [:]) {
        data = (try? JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)) ?? Data()
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents,
              let object = try? JSONSerialization.jsonObject(with: contents),
              object is [String: Any] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

struct GeneralTab: View {
    @ObservedObject private var localization = Localization.shared
    @AppStorage("switch_closeSourceTab") private var closeSourceTab = false
    @State private var isDefault = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showingExportPicker = false
    @State private var showingImportPicker = false
    @State private var exportDocument = SettingsDocument()
    @AppStorage("browsers") private var browsers: [BrowserTarget] = []
    @AppStorage("copy_closeAfterCopy") private var closeAfterCopy: Bool = false
    @AppStorage("copy_alternativeShortcut") private var alternativeShortcut: Bool = false
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    @AppStorage("apps_atTop") private var appsAtTop: Bool = true

    func defaultBrowser() -> String? {
        guard let browserUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https:")!) else {
            return nil
        }

        return Bundle(url: browserUrl)?.bundleIdentifier
    }

    func exportSettings() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()

        let appSettings = dictionary.filter { Self.settingsKeys.contains($0.key) }

        exportDocument = SettingsDocument(settings: appSettings)
        showingExportPicker = true
    }

    private static let settingsKeys = SettingsPolicy.keys

    func importSettings(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let settings = settings else {
                BrowserUtil.presentError(NSError(domain: "Browserino", code: 2, userInfo: [NSLocalizedDescriptionKey: L10n.text("errors.invalid_settings_format")]))
                return
            }

            let defaults = UserDefaults.standard
            let accepted = try SettingsPolicy.validate(settings)
            for (key, value) in accepted {
                if key == "KeyboardShortcuts_moveCurrentTab", let raw = value as? String {
                    let shortcut = try JSONDecoder().decode(KeyboardShortcuts.Shortcut.self, from: Data(raw.utf8))
                    KeyboardShortcuts.setShortcut(shortcut, for: .moveCurrentTab)
                } else { defaults.set(value, forKey: key) }
            }

            print("Settings imported successfully")
        } catch {
            BrowserUtil.presentError(NSError(domain: "Browserino", code: 2, userInfo: [NSLocalizedDescriptionKey: L10n.text("errors.invalid_settings_format")]))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.language.title")).font(.headline).frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                    Picker(L10n.text("settings.language.title"), selection: $localization.selectedLanguage) {
                        Text(verbatim: L10n.text("settings.language.system_default")).tag("")
                        ForEach(LanguagePolicy.options, id: \.id) { option in
                            Text(verbatim: option.name).tag(option.id)
                        }
                    }.labelsHidden().fixedSize().frame(width: 230, alignment: .leading).frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("tabs.transfer.title")).font(.headline).frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                    VStack(alignment: .leading, spacing: 8) {
                        LocalizedShortcutRecorder().fixedSize().frame(width: 230, height: 26, alignment: .leading)
                        Toggle(L10n.text("tabs.transfer.close_source"), isOn: $closeSourceTab)
                        Text(verbatim: L10n.text("tabs.transfer.safari_keep_source")).fixedSize(horizontal: false, vertical: true)
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.default_browser.title"))
                        .font(.headline)
                        .frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            NSWorkspace.shared.setDefaultApplication(
                                at: Bundle.main.bundleURL,
                                toOpenURLsWithScheme: "http"
                            ) { error in
                                guard error == nil else { return }
                                NSWorkspace.shared.setDefaultApplication(
                                    at: Bundle.main.bundleURL,
                                    toOpenURLsWithScheme: "https"
                                ) { _ in
                                    DispatchQueue.main.async {
                                        isDefault = defaultBrowser() == Bundle.main.bundleIdentifier
                                    }
                                }
                            }
                        }) {
                            Text(verbatim: L10n.text("settings.default_browser.make_default"))
                        }
                        .disabled(isDefault)

                        Text(verbatim: L10n.text("settings.default_browser.description"))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                            .opacity(0.5)
                    }
                }

                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.installed_browsers.title"))
                        .font(.headline)
                        .frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            if let refreshed = BrowserUtil.rescanBrowsers(oldBrowsers: browsers) { browsers = refreshed }
                        }) {
                            Text(verbatim: L10n.text("settings.installed_browsers.rescan"))
                        }

                        Text(verbatim: L10n.text("settings.installed_browsers.description"))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                            .opacity(0.5)
                    }
                }

                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.copy_url.title"))
                        .font(.headline)
                        .frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $closeAfterCopy) {
                            Text(verbatim: L10n.text("settings.copy_url.close_after_copy"))
                                .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                                .opacity(0.5)
                        }

                        Toggle(isOn: $alternativeShortcut) {
                            Text(verbatim: L10n.text("settings.copy_url.alternative_shortcut"))
                                .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                                .opacity(0.5)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.appearance.title"))
                        .font(.headline)
                        .frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $appsAtTop) {
                            Text(verbatim: L10n.text("settings.appearance.apps_at_top"))
                                .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                                .opacity(0.5)
                        }

                        Toggle(isOn: $showInMenuBar) {
                            Text(verbatim: L10n.text("settings.appearance.show_menu_bar"))
                                .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                                .opacity(0.5)
                        }
                    }
                }

                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.startup.title"))
                        .font(.headline)
                        .frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $launchAtLogin) {
                            Text(verbatim: L10n.text("settings.startup.launch_at_login"))
                                .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                                .opacity(0.5)
                        }
                        .onChange(of: launchAtLogin) { _, newValue in
                            do {
                                if newValue {
                                    try SMAppService.mainApp.register()
                                } else {
                                    try SMAppService.mainApp.unregister()
                                }
                            } catch {
                                launchAtLogin = SMAppService.mainApp.status == .enabled
                            }
                        }
                    }
                }

                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.import_export.title"))
                        .font(.headline)
                        .frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            exportSettings()
                        }) {
                            Text(verbatim: L10n.text("settings.import_export.export"))
                        }

                        Text(verbatim: L10n.text("settings.import_export.export_description"))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                            .opacity(0.5)

                        Button(action: {
                            showingImportPicker = true
                        }) {
                            Text(verbatim: L10n.text("settings.import_export.import"))
                        }

                        Text(verbatim: L10n.text("settings.import_export.import_description"))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                            .opacity(0.5)
                    }
                }

                HStack(alignment: .top, spacing: 32) {
                    Text(verbatim: L10n.text("settings.reset.title"))
                        .font(.headline)
                        .frame(width: 200, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            let defaults = UserDefaults.standard
                            KeyboardShortcuts.setShortcut(nil, for: .moveCurrentTab)
                            defaults.removeObject(forKey: "browserDataAccess")
                            Self.settingsKeys.forEach { key in
                                defaults.removeObject(forKey: key)
                            }
                        }) {
                            Text(verbatim: L10n.text("settings.reset.action"))
                        }

                        Text(verbatim: L10n.text("settings.reset.description"))
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.callout)
                            .opacity(0.5)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            isDefault = defaultBrowser() == Bundle.main.bundleIdentifier
        }
        .fileExporter(
            isPresented: $showingExportPicker,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "browserino-settings"
        ) { result in
            switch result {
            case .success(let url):
                print("Settings exported to: \(url)")
            case .failure(let error):
                print("Export failed: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importSettings(from: url)
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    PreferencesView()
}

/// KeyboardShortcuts uses its own bundle language for its Cocoa recorder.
/// The pinned 2.4.0 recorder emits a recording-state notification; bridge it
/// to Browserino's selected language, including first-responder transitions.
struct LocalizedShortcutRecorder: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> KeyboardShortcuts.RecorderCocoa {
        let view = KeyboardShortcuts.RecorderCocoa(for: .moveCurrentTab)
        context.coordinator.attach(view)
        view.placeholderString = L10n.text("shortcuts.recorder.assign")
        view.setAccessibilityPlaceholderValue(L10n.text("shortcuts.recorder.assign"))
        return view
    }
    func updateNSView(_ view: KeyboardShortcuts.RecorderCocoa, context: Context) {
        context.coordinator.refresh()
    }
    @MainActor
    final class Coordinator {
        weak var view: KeyboardShortcuts.RecorderCocoa?
        private var observations: [AnyCancellable] = []
        private var recording = false
        func attach(_ view: KeyboardShortcuts.RecorderCocoa) {
            self.view = view
            let recorderState = Notification.Name("KeyboardShortcuts_recorderActiveStatusDidChange")
            for name in [recorderState, NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification] {
                observations.append(NotificationCenter.default.publisher(for: name).receive(on: DispatchQueue.main).sink { [weak self] notification in
                    let name = notification.name
                    let object = notification.object as AnyObject?
                    let active = notification.userInfo?["isActive"] as? Bool
                    MainActor.assumeIsolated {
                        guard let self, let view = self.view else { return }
                        if name == recorderState, let active { self.recording = active }
                        else if object === view.window { self.recording = false }
                        else { return }
                        self.refresh()
                    }
                })
            }
        }
        func refresh() {
            let label = L10n.text(recording ? "shortcuts.recorder.press_key" : "shortcuts.recorder.assign")
            view?.placeholderString = label
            view?.setAccessibilityPlaceholderValue(label)
        }
    }
}
