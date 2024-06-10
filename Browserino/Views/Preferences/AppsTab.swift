//
//  AppsTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct App: Codable {
    var domain: String
    var app: URL
}

struct NewApp: View {
    @AppStorage("apps") private var apps: [App] = []
    @State private var domain: String = ""
    @State private var openWithPresented = false
    
    var body: some View {
        HStack {
            Text("")
                .font(
                    .system(size: 16)
                )
                .frame(width: 30, alignment: .leading)
            
            TextField("example.com", text: $domain)
                .font(
                    .system(size: 14)
                )
            
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
                    apps.append(
                        App(
                            domain: domain,
                            app: url
                        )
                    )
                    domain = ""
                }
            }
        }
        .padding(10)
    }
}

struct AppsTab: View {
    @AppStorage("apps") private var apps: [App] = []
    
    var body: some View {
        VStack (alignment: .leading) {
            List {
                NewApp()
                
                ForEach(Array(apps.enumerated()), id: \.offset) { offset, app in
                    if let bundle = Bundle(url: app.app) {
                        HStack {
                            Text((offset + 1).formatted())
                                .font(
                                    .system(size: 16)
                                )
                                .frame(width: 30, alignment: .leading)
                            
                            Text(app.domain)
                                .font(
                                    .system(size: 14)
                                )
                            
                            Spacer()
                            
                            
                            Text(bundle.infoDictionary!["CFBundleName"] as! String)
                                .font(
                                    .system(size: 14)
                                )
                            
                            
                            Spacer()
                                .frame(width: 8)
                            
                            Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Button(role: .destructive) {
                                apps.remove(at: offset)
                            } label: {
                                Image(systemName: "trash")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }
            }
            
            Text("Add new app by typing domain which will be opened using it")
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
