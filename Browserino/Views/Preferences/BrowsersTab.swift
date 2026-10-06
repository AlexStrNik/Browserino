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
    @AppStorage("profilesEnabled") private var profilesEnabled = true
    @AppStorage("profileNames") private var profileNames: [String: String] = [:]
    @AppStorage("privateArgs") private var privateArgs: [String: String] = [:]

    private var displayed: [(offset: Int, element: BrowserTarget)] {
        var seen = Set<URL>()
        return browsers.enumerated().compactMap { index, target in
            if profilesEnabled { return (index, target) }
            return seen.insert(target.app).inserted ? (index, BrowserTarget(app: target.app)) : nil
        }
    }
    private func move(from source: IndexSet, to destination: Int) {
        guard profilesEnabled else { return }
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
        ChromiumProfileService.userDataDirectory(forAppAt: target.app) != nil
            && ChromiumProfileService.profiles(forAppAt: target.app) == nil
    }

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(L10n.text("browsers.profiles.show"), isOn: $profilesEnabled)
                .padding(.horizontal, 20)
            List {
                ForEach(displayed, id: \.offset) { offset, browser in
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

                            Group {
                            if let profile = browser.profile, let identifier = bundle.bundleIdentifier {
                                TextField(profile, text: Binding(
                                    get: { profileNames[browser.shortcutKey(bundleIdentifier: identifier)] ?? browser.chromiumProfile?.name ?? profile },
                                    set: { profileNames[browser.shortcutKey(bundleIdentifier: identifier)] = $0 }
                                ))
                                .frame(minWidth: 100)
                            } else {
                                Text(browser.displayName)
                            }
                            }
                                .font(
                                    .system(size: 14)
                                )

                            Spacer()
                                .frame(width: 32)

                            if let browserId = bundle.bundleIdentifier {
                                // Incognito is a property of the browser, not of one
                                // profile, so it stays on the plain row and every
                                // profile of that browser inherits it.
                                if !profilesEnabled || browsers.first(where: { $0.app == browser.app }) == browser {
                                    TextField(L10n.text("browsers.private_argument.placeholder"),
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

                            if profilesEnabled && browsers.first(where: { $0.app == browser.app }) == browser && needsProfileAccess(browser) {
                                Button(L10n.text("browsers.profiles.enable")) {
                                    if ChromiumProfileService.requestAccess(forAppAt: browser.app) {
                                        if let refreshed = BrowserUtil.rescanBrowsers(oldBrowsers: browsers) { browsers = refreshed }
                                    }
                                }
                                .help(L10n.text("browsers.profiles.enable"))

                                Spacer()
                                    .frame(width: 8)
                            }

                            Spacer()
                                .frame(width: 8)

                            Button(action: {
                                hiddenBrowsers = TargetPolicy.toggle(browser, targets: browsers, hidden: hiddenBrowsers)
                            }) {
                                Image(
                                    systemName: TargetPolicy.visible(browsers.filter { $0.app == browser.app }, hidden: hiddenBrowsers, profilesEnabled: profilesEnabled).isEmpty || TargetPolicy.isHidden(browser, hidden: hiddenBrowsers)
                                        ? "eye.slash.fill" : "eye.fill")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }
                .onMove(perform: move)
                .moveDisabled(!profilesEnabled)
            }
            .scrollContentBackground(.hidden)
            .onChange(of: profilesEnabled) { _, _ in
                if let refreshed = BrowserUtil.rescanBrowsers(oldBrowsers: browsers) { browsers = refreshed }
            }
            .onAppear {
                // Safe to run every time: the merge keeps the user's order and is
                // idempotent, so this picks up profiles added since the last visit
                // without waiting for an explicit Rescan.
                if let refreshed = BrowserUtil.rescanBrowsers(oldBrowsers: browsers) { browsers = refreshed }
            }

            Text(verbatim: L10n.text("browsers.list.instructions")
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
