//
//  AppsTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct App: Codable, Hashable {
    var host: String
    var schemeOverride: String
    var app: URL
    var profile: String?

    var target: BrowserTarget {
        BrowserTarget(app: app, profile: profile)
    }
}

struct NewApp: View {
    @AppStorage("apps") private var apps: [App] = []
    @State private var host: String = ""
    @State private var selectedApp: URL?
    @State private var selectedProfile: String?
    
    private var hostValid: Bool {
        if host.isEmpty {
            return true
        }

        let url = if host.starts(with: /https?:\/\//) {
            host
        } else {
            "http://" + host
        }

        return URL(string: url)?.host() != nil
    }
    
    var body: some View {
        HStack {
            Image(systemName: "plus")
                .font(
                    .system(size: 14)
                )
                .opacity(0)
            
            TextField(L10n.text("apps.host.placeholder"), text: $host)
                .font(
                    .system(size: 14)
                )
            
            Spacer()
                .frame(width: 16)
            
            BrowserTargetPicker(app: $selectedApp, profile: $selectedProfile)
            .onChange(of: selectedApp) { _, url in
                guard let url else { return }
                let input = host.hasPrefix("http://") || host.hasPrefix("https://") ? host : "http://" + host
                guard host.isEmpty || URL(string: input)?.host != nil else { return }
                apps.append(App(host: host.isEmpty ? "" : URL(string: input)!.host!, schemeOverride: "", app: url, profile: selectedProfile))
                host = ""
                selectedApp = nil
                selectedProfile = nil
            }
            .disabled(!hostValid)
        }
        .padding(10)
    }
}

struct AppItem: View {
    @Binding var app: App
    @State private var editPresented = false

    var body: some View {
        let bundle = Bundle(url: app.app)

        HStack {
            Button(action: {
                editPresented.toggle()
            }) {
                Label(
                    app.host.isEmpty ? "*" : app.host,
                    systemImage: "pencil"
                )
                .font(
                    .system(size: 14)
                )
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()


            Text(bundle == nil
                 ? L10n.format("browsers.status.not_installed", app.app.appDisplayName)
                 : app.target.displayName)
                .font(
                    .system(size: 14)
                )
                .foregroundStyle(
                    bundle == nil || app.target.hasMissingProfile ? .secondary : .primary
                )


            Spacer()
                .frame(width: 32)

            if let browserId = bundle?.bundleIdentifier {
                ShortcutButton(
                    shortcutKey: app.target.shortcutKey(bundleIdentifier: browserId)
                )
            }

            Spacer()
                .frame(width: 8)

            if bundle != nil {
                BrowserTargetIcon(target: app.target)
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "questionmark.app.dashed")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(10)
        .sheet(isPresented: $editPresented) {
            EditAppForm(
                app: $app,
                isPresented: $editPresented
            )
        }
    }
}

struct AppsTab: View {
    @AppStorage("apps") private var apps: [App] = []
    
    var body: some View {
        VStack (alignment: .leading) {
            List {
                NewApp()
                
                ForEach(Array($apps.enumerated()), id: \.offset) { offset, app in
                    AppItem(
                        app: app
                    )
                }
            }
            .scrollContentBackground(.hidden)
            
            Text(verbatim: L10n.text("apps.list.instructions"))
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.5))
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    AppsTab()
}
