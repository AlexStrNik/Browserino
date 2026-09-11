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
}

struct NewApp: View {
    @AppStorage("apps") private var apps: [App] = []
    @State private var host: String = ""
    @State private var openWithPresented = false
    
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
            
            TextField("example.com or empty for all", text: $host)
                .font(
                    .system(size: 14)
                )
            
            Spacer()
                .frame(width: 16)
            
            Button(action: {
                openWithPresented.toggle()
            }) {
                Text("Open with")
            }
            .fileImporter(
                isPresented: $openWithPresented,
                allowedContentTypes: [.application]
            ) {
                if case .success(let url) = $0 {
                    let appHost: String

                    if host.isEmpty {
                        appHost = ""
                    } else {
                        let hostUrl = if host.starts(with: /https?:\/\//) {
                            host
                        } else {
                            "http://" + host
                        }
                        appHost = URL(string: hostUrl)!.host()!
                    }

                    apps.append(
                        App(
                            host: appHost,
                            schemeOverride: "",
                            app: url
                        )
                    )
                    host = ""
                }
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


            Text(bundle?.appDisplayName ?? "\(app.app.appDisplayName) (not installed)")
                .font(
                    .system(size: 14)
                )
                .foregroundStyle(bundle == nil ? .secondary : .primary)


            Spacer()
                .frame(width: 32)

            if let browserId = bundle?.bundleIdentifier {
                ShortcutButton(
                    browserId: browserId
                )
            }

            Spacer()
                .frame(width: 8)

            if let bundle {
                Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                    .resizable()
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
            
            Text("Type domain and choose app in which links will be opened")
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
