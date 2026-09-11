//
//  BrowsersTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct BrowsersTab: View {
    @AppStorage("browsers") private var browsers: [BrowserTarget] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [BrowserTarget] = []
    @AppStorage("privateArgs") private var privateArgs: [String: String] = [:]

    private func move(from source: IndexSet, to destination: Int) {
        browsers.move(fromOffsets: source, toOffset: destination)
    }

    private func privateArg(for key: String) -> Binding<String> {
        return .init(
            get: { self.privateArgs[key, default: ""] },
            set: { self.privateArgs[key] = $0 })
    }

    /// Offer the grant only where it could actually help: a Chromium browser whose
    /// profiles we have not been able to read yet.
    private func needsProfileAccess(_ target: BrowserTarget) -> Bool {
        target.profile == nil
            && ChromiumProfileService.userDataDirectory(forAppAt: target.app) != nil
            && ChromiumProfileService.profiles(forAppAt: target.app) == nil
    }

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.offset) { offset, browser in
                    if let bundle = Bundle(url: browser.app) {
                        HStack {
                            Text((offset + 1).formatted())
                                .font(
                                    .system(size: 16)
                                )
                                .frame(width: 30, alignment: .leading)

                            BrowserTargetIcon(target: browser)
                                .frame(width: 32, height: 32)

                            Spacer()
                                .frame(width: 8)

                            Text(browser.displayName)
                                .font(
                                    .system(size: 14)
                                )

                            Spacer()
                                .frame(width: 32)

                            if let browserId = bundle.bundleIdentifier {
                                // Incognito is a property of the browser, not of one
                                // profile, so it stays on the plain row and every
                                // profile of that browser inherits it.
                                if browser.profile == nil {
                                    TextField(
                                        "Private argument",
                                        text: privateArg(for: browserId)
                                    )
                                    .font(
                                        .system(size: 14).monospaced()
                                    )
                                } else {
                                    Spacer()
                                }

                                Spacer()
                                    .frame(width: 32)

                                ShortcutButton(
                                    shortcutKey: browser.shortcutKey(bundleIdentifier: browserId)
                                )
                            }

                            if needsProfileAccess(browser) {
                                Button("Enable profiles") {
                                    if ChromiumProfileService.requestAccess(forAppAt: browser.app) {
                                        browsers = BrowserUtil.loadBrowsers(oldBrowsers: browsers)
                                    }
                                }
                                .help("macOS keeps a browser's profiles private until you point at the folder once.")

                                Spacer()
                                    .frame(width: 8)
                            }

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
                                    systemName: hiddenBrowsers.contains(browser)
                                        ? "eye.slash.fill" : "eye.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }
                .onMove(perform: move)
            }
            .scrollContentBackground(.hidden)
            .onAppear {
                // Safe to run every time: the merge keeps the user's order and is
                // idempotent, so this picks up profiles added since the last visit
                // without waiting for an explicit Rescan.
                browsers = BrowserUtil.loadBrowsers(
                    oldBrowsers: browsers
                )
            }

            Text(
                "Drag and drop to reorder. Press record to assign a shortcut. Click on eye to hide unwanted browsers from prompt. Browsers with several profiles appear once per profile — use Rescan in General after adding one."
            )
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
