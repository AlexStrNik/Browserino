//
//  BrowsersTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct BrowsersTab: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [URL] = []
    @AppStorage("privateArgs") private var privateArgs: [String: String] = [:]

    private func move(from source: IndexSet, to destination: Int) {
        browsers.move(fromOffsets: source, toOffset: destination)
    }
    
    private func privateArg(for key: String) -> Binding<String> {
        return .init(
            get: { self.privateArgs[key, default: ""] },
            set: { self.privateArgs[key] = $0 })
    }

    var body: some View {
        VStack (alignment: .leading) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.offset) { offset, browser in
                    if let bundle = Bundle(url: browser) {
                        HStack {
                            Text((offset + 1).formatted())
                                .font(
                                    .system(size: 16)
                                )
                                .frame(width: 30, alignment: .leading)
                            
                            Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Spacer()
                                .frame(width: 8)
                            
                            Text(bundle.infoDictionary!["CFBundleName"] as! String)
                                .font(
                                    .system(size: 14)
                                )
                            
                            Spacer()
                                .frame(width: 32)
                            
                            TextField(
                                "Private argument",
                                text: privateArg(for: bundle.bundleIdentifier!)
                            )
                            .font(
                                .system(size: 14).monospaced()
                            )
                            
                            Spacer()
                                .frame(width: 32)
                            
                            ShortcutButton(
                                browserId: bundle.bundleIdentifier!
                            )
                            
                            Spacer()
                                .frame(width: 8)
                            
                            Button(action: {
                                if let idx = hiddenBrowsers.firstIndex(of: browser) {
                                    hiddenBrowsers.remove(at: idx)
                                } else {
                                    hiddenBrowsers.append(browser)
                                }
                            }) {
                                Image(
                                    systemName: hiddenBrowsers.contains(browser) ? "eye.slash.fill" : "eye.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }
                .onMove(perform: move)
            }
            .onAppear {
                if browsers.isEmpty {
                    browsers = BrowserUtil.loadBrowsers(
                        oldBrowsers: browsers
                    )
                }
            }
            
            Text("Drag and drop to reorder. Press record to assign a shortcut")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.5))
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
    }
}


#Preview {
    PreferencesView()
}
