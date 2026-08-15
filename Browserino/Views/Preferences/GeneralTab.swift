//
//  GeneralTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI
import UniformTypeIdentifiers
import ServiceManagement
import KeyboardShortcuts

struct SettingsDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var settings: [String: Any]

    init(settings: [String: Any] = [:]) {
        self.settings = settings
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.settings = jsonObject
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
        return .init(regularFileWithContents: data)
    }
}

struct GeneralTab: View {
    @State private var isDefault = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showingExportPicker = false
    @State private var showingImportPicker = false
    @State private var exportDocument = SettingsDocument()
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("copy_closeAfterCopy") private var closeAfterCopy: Bool = false
    @AppStorage("copy_alternativeShortcut") private var alternativeShortcut: Bool = false
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    @AppStorage("apps_atTop") private var appsAtTop: Bool = true
    @AppStorage("switch_closeSourceTab") private var closeSourceTab: Bool = true

    func defaultBrowser() -> String? {
        guard let browserUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https:")!) else {
            return nil
        }

        return Bundle(url: browserUrl)?.bundleIdentifier
    }

    func exportSettings() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()

        let filteredSettings = dictionary.filter { key, _ in
            !key.contains("NS") &&
            !key.contains("com.apple.") &&
            !key.contains("Apple") &&
            !key.contains("METAL") &&
            !key.contains("KB_") &&
            !key.contains("cloud.") &&
            !key.starts(with: "_") &&
            !key.starts(with: "AK") &&
            key != "shouldShowRSVPDataDetectors" &&
            key != "MultipleSessionEnabled" &&
            key != "WebAutomaticSpellingCorrectionEnabled" &&
            key != "Country"
        }

        var appSettings: [String: Any] = [:]
        for (key, value) in filteredSettings {
            appSettings[key] = value
        }

        print(appSettings)

        exportDocument = SettingsDocument(settings: appSettings)
        showingExportPicker = true
    }

    func importSettings(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let settings = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let settings = settings else {
                print("Invalid settings format")
                return
            }

            let defaults = UserDefaults.standard
            for (key, value) in settings {
                defaults.set(value, forKey: key)
            }

            print("Settings imported successfully")
        } catch {
            print("Failed to import settings: \(error.localizedDescription)")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 32) {
                Text("Default browser")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading) {
                    Button(action: {
                        NSWorkspace.shared.setDefaultApplication(
                            at: Bundle.main.bundleURL,
                            toOpenURLsWithScheme: "http"
                        ) { _ in
                            isDefault = defaultBrowser() == Bundle.main.bundleIdentifier
                        }
                    }) {
                        Text("Make default")
                    }
                    .disabled(isDefault)

                    Text("Make Browserino default browser to use it")
                        .font(.callout)
                        .opacity(0.5)
                }
            }

            HStack(alignment: .top, spacing: 32) {
                Text("Installed Browsers")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading) {
                    Button(action: {
                        browsers = BrowserUtil.loadBrowsers(
                            oldBrowsers: browsers
                        )
                    }) {
                        Text("Rescan")
                    }

                    Text("Rescan list of installed browsers")
                        .font(.callout)
                        .opacity(0.5)
                }
            }

            HStack(alignment: .top, spacing: 32) {
                Text("Copy URL")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading) {
                    Toggle(isOn: $closeAfterCopy) {
                        Text("Close prompt view after copying URL")
                            .font(.callout)
                            .opacity(0.5)
                    }

                    Toggle(isOn: $alternativeShortcut) {
                        Text("Use Command+C instead of Command+Option+C")
                            .font(.callout)
                            .opacity(0.5)
                    }
                }
            }

            HStack(alignment: .top, spacing: 32) {
                Text("Tab switching")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Move current tab")
                            .font(.callout)
                        KeyboardShortcuts.Recorder(for: .moveCurrentTab)
                    }

                    Toggle(isOn: $closeSourceTab) {
                        Text("Close the original tab after opening the destination")
                            .font(.callout)
                            .opacity(0.5)
                    }

                    Text("macOS will ask for permission to control each browser the first time you move a tab.")
                        .font(.callout)
                        .opacity(0.5)
                }
            }

            HStack(alignment: .top, spacing: 32) {
                Text("Appearance")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading) {
                    Toggle(isOn: $appsAtTop) {
                        Text("Show apps before browsers")
                            .font(.callout)
                            .opacity(0.5)
                    }

                    Toggle(isOn: $showInMenuBar) {
                        Text("Show Browserino in menu bar")
                            .font(.callout)
                            .opacity(0.5)
                    }
                }
            }

            HStack(alignment: .top, spacing: 32) {
                Text("Startup")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading) {
                    Toggle(isOn: $launchAtLogin) {
                        Text("Launch Browserino at login")
                            .font(.callout)
                            .opacity(0.5)
                    }
                    .onChange(of: launchAtLogin) { newValue in
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
                Text("Import/Export")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading) {
                    Button(action: {
                        exportSettings()
                    }) {
                        Text("Export")
                    }

                    Text("Export all settings")
                        .font(.callout)
                        .opacity(0.5)

                    Button(action: {
                        showingImportPicker = true
                    }) {
                        Text("Import")
                    }

                    Text("Import all settings")
                        .font(.callout)
                        .opacity(0.5)
                }
            }

            HStack(alignment: .top, spacing: 32) {
                Text("System reset")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)

                VStack(alignment: .leading) {
                    Button(action: {
                        let defaults = UserDefaults.standard
                        let dictionary = defaults.dictionaryRepresentation()
                        dictionary.keys.forEach { key in
                            defaults.removeObject(forKey: key)
                        }
                    }) {
                        Text("Reset")
                    }

                    Text("Reset all preferences")
                        .font(.callout)
                        .opacity(0.5)
                }
            }
        }
        .onAppear {
            isDefault = defaultBrowser() == Bundle.main.bundleIdentifier
        }
        .padding(20)
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
