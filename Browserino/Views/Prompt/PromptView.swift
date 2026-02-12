//
//  PromptView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

struct PickerBrowserItem: Identifiable {
    let id: String
    let appURL: URL
    let displayName: String?
    let profileDirectory: String?
    let shortcutKey: String?
}

struct PromptView: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [URL] = []
    @AppStorage("apps") private var apps: [App] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]
    @AppStorage("chromeProfiles") private var chromeProfiles: [ChromeProfile] = []
    @AppStorage("chromeProfilesEnabled") private var chromeProfilesEnabled: Bool = true

    @AppStorage("copy_closeAfterCopy") private var closeAfterCopy: Bool = false
    @AppStorage("copy_alternativeShortcut") private var alternativeShortcut: Bool = false
    @AppStorage("apps_atTop") private var appsAtTop: Bool = true

    let urls: [URL]

    @State private var opacityAnimation = 0.0
    @State private var selected = 0
    @FocusState private var focused: Bool

    var appsForUrls: [App] {
        urls.flatMap { url in
            return apps.filter { app in
                url.matchesHost(app.host)
            }
        }
        .filter {
            !browsers.contains($0.app)
        }
    }

    var visibleBrowsers: [URL] {
        browsers.filter { !hiddenBrowsers.contains($0) }
    }

    var pickerBrowserItems: [PickerBrowserItem] {
        var items: [PickerBrowserItem] = []

        for browser in visibleBrowsers {
            guard let bundle = Bundle(url: browser) else { continue }
            let bundleID = bundle.bundleIdentifier ?? ""

            if chromeProfilesEnabled && bundleID == ChromeProfileUtil.chromeBundleID {
                let visibleProfiles = chromeProfiles.filter { !$0.isHidden }
                if !visibleProfiles.isEmpty {
                    for profile in visibleProfiles {
                        let profileID = "\(bundleID)::\(profile.directoryName)"
                        let chromeName = bundle.infoDictionary?["CFBundleName"] as? String ?? "Google Chrome"
                        items.append(PickerBrowserItem(
                            id: profileID,
                            appURL: browser,
                            displayName: "\(chromeName) - \(profile.displayName)",
                            profileDirectory: profile.directoryName,
                            shortcutKey: shortcuts[profileID]
                        ))
                    }
                    continue
                }
            }

            items.append(PickerBrowserItem(
                id: bundleID,
                appURL: browser,
                displayName: nil,
                profileDirectory: nil,
                shortcutKey: shortcuts[bundleID]
            ))
        }

        return items
    }

    var totalItemCount: Int {
        pickerBrowserItems.count + appsForUrls.count
    }

    func openUrlsInApp(app: App) {
        let urls =
            if app.schemeOverride.isEmpty {
                urls
            } else {
                urls.map {
                    let url = NSURLComponents.init(
                        url: $0,
                        resolvingAgainstBaseURL: true
                    )
                    url!.scheme = app.schemeOverride

                    return url!.url!
                }
            }

        BrowserUtil.openURL(
            urls,
            app: app.app,
            isIncognito: false
        )
    }

    func openBrowserItem(_ item: PickerBrowserItem, isIncognito: Bool) {
        BrowserUtil.openURL(
            urls,
            app: item.appURL,
            isIncognito: isIncognito,
            profileDirectory: item.profileDirectory
        )
    }

    func handleEnter(isIncognito: Bool) {
        let browserItems = pickerBrowserItems
        if appsAtTop {
            if selected < appsForUrls.count {
                openUrlsInApp(app: appsForUrls[selected])
            } else {
                let idx = selected - appsForUrls.count
                if idx < browserItems.count {
                    openBrowserItem(browserItems[idx], isIncognito: isIncognito)
                }
            }
        } else {
            if selected < browserItems.count {
                openBrowserItem(browserItems[selected], isIncognito: isIncognito)
            } else {
                let idx = selected - browserItems.count
                if idx < appsForUrls.count {
                    openUrlsInApp(app: appsForUrls[idx])
                }
            }
        }
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if !appsForUrls.isEmpty && appsAtTop {
                            ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                                if let bundle = Bundle(url: app.app) {
                                    PromptItem(
                                        browser: app.app,
                                        urls: urls,
                                        bundle: bundle,
                                        shortcut: shortcuts[bundle.bundleIdentifier!]
                                    ) {
                                        openUrlsInApp(app: app)
                                    }
                                    .id(index)
                                    .buttonStyle(
                                        SelectButtonStyle(
                                            selected: selected == index
                                        )
                                    )
                                }
                            }

                            Divider()
                        }

                        ForEach(Array(pickerBrowserItems.enumerated()), id: \.element.id) {
                            index, item in
                            if let bundle = Bundle(url: item.appURL) {
                                PromptItem(
                                    browser: item.appURL,
                                    urls: urls,
                                    bundle: bundle,
                                    shortcut: item.shortcutKey,
                                    displayName: item.displayName
                                ) {
                                    openBrowserItem(item, isIncognito: NSEvent.modifierFlags.contains(.shift))
                                }
                                .id(index + (appsAtTop ? appsForUrls.count : 0))
                                .buttonStyle(
                                    SelectButtonStyle(
                                        selected: selected == index + (appsAtTop ? appsForUrls.count : 0)
                                    )
                                )
                            }
                        }

                        if !appsForUrls.isEmpty && !appsAtTop {
                            Divider()

                            ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                                if let bundle = Bundle(url: app.app) {
                                    PromptItem(
                                        browser: app.app,
                                        urls: urls,
                                        bundle: bundle,
                                        shortcut: shortcuts[bundle.bundleIdentifier!]
                                    ) {
                                        openUrlsInApp(app: app)
                                    }
                                    .id(pickerBrowserItems.count + index)
                                    .buttonStyle(
                                        SelectButtonStyle(
                                            selected: selected == pickerBrowserItems.count + index
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
                .focusable()
                .focusEffectDisabledCompat()
                .focused($focused)
                .onMoveCommand { command in
                    if command == .up {
                        selected = max(0, selected - 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                    } else if command == .down {
                        selected = min(totalItemCount - 1, selected + 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                    }
                }
                .background {
                    Button(action: {
                        handleEnter(isIncognito: false)
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.defaultAction)

                    Button(action: {
                        handleEnter(isIncognito: true)
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.return, modifiers: [.shift])

                    Button(action: {
                        NSApplication.shared.keyWindow?.close()
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.cancelAction)
                }
                .onAppear {
                    focused.toggle()
                    withAnimation(.interactiveSpring(duration: 0.3)) {
                        opacityAnimation = 1
                    }
                }
                .scrollEdgeEffectDisabledCompat()
            }

            Divider()

            if let host = urls.first?.host() {
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(urls.first?.absoluteString ?? "", forType: .string)

                    if closeAfterCopy {
                        NSApplication.shared.keyWindow?.close()
                    }
                }) {
                    Text(
                        host
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(
                    KeyEquivalent("c"),
                    modifiers: alternativeShortcut ? [.command] : [.command, .option]
                )
                .toolTip(urls.first?.absoluteString ?? "")
            }
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(BlurredView())
        .opacity(opacityAnimation)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    PromptView(urls: [])
}
