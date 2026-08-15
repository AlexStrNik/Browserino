//
//  PromptView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

enum PromptMode {
    case open
    case move(source: NSRunningApplication)
}

struct PromptView: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [URL] = []
    @AppStorage("apps") private var apps: [App] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]

    @AppStorage("copy_closeAfterCopy") private var closeAfterCopy: Bool = false
    @AppStorage("copy_alternativeShortcut") private var alternativeShortcut: Bool = false
    @AppStorage("apps_atTop") private var appsAtTop: Bool = true
    @AppStorage("switch_closeSourceTab") private var closeSourceTab: Bool = true

    let urls: [URL]
    var mode: PromptMode = .open

    @State private var opacityAnimation = 0.0
    @State private var selected = 0
    @FocusState private var focused: Bool

    var isMoveMode: Bool {
        if case .move = mode {
            return true
        }
        return false
    }

    var sourceApplication: NSRunningApplication? {
        if case .move(let source) = mode {
            return source
        }
        return nil
    }

    var appsForUrls: [App] {
        if isMoveMode {
            return []
        }

        return urls.flatMap { url in
            return apps.filter { app in
                url.matchesHost(app.host)
            }
        }
        .filter {
            !browsers.contains($0.app)
        }
    }

    var visibleBrowsers: [URL] {
        browsers.filter { browser in
            if hiddenBrowsers.contains(browser) {
                return false
            }

            if let source = sourceApplication,
               Bundle(url: browser)?.bundleIdentifier == source.bundleIdentifier
            {
                return false
            }

            return true
        }
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

    func openInBrowser(_ browser: URL, isIncognito: Bool) {
        BrowserUtil.openURL(
            urls,
            app: browser,
            isIncognito: isIncognito
        ) { _, error in
            DispatchQueue.main.async {
                handleMoveCompletion(error: error)
            }
        }
    }

    func handleMoveCompletion(error: Error?) {
        guard let source = sourceApplication else {
            return
        }

        if let error {
            BrowserSwitchService.shared.presentOpenFailedAlert(error)
            return
        }

        guard closeSourceTab else {
            return
        }

        BrowserTabScripting.closeActiveTab(in: source) { closeError in
            if let closeError {
                DispatchQueue.main.async {
                    BrowserSwitchService.shared.presentCloseFailedAlert(closeError)
                }
            }
        }
    }

    var body: some View {
        VStack {
            if let sourceName = sourceApplication?.localizedName {
                Text("Moving from \(sourceName)")
                    .font(.callout)
                    .opacity(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

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

                        ForEach(Array(visibleBrowsers.enumerated()), id: \.offset) {
                            index, browser in
                            if let bundle = Bundle(url: browser) {
                                PromptItem(
                                    browser: browser,
                                    urls: urls,
                                    bundle: bundle,
                                    shortcut: shortcuts[bundle.bundleIdentifier!]
                                ) {
                                    openInBrowser(
                                        browser,
                                        isIncognito: NSEvent.modifierFlags.contains(.shift)
                                    )
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
                                    .id(visibleBrowsers.count + index)
                                    .buttonStyle(
                                        SelectButtonStyle(
                                            selected: selected == visibleBrowsers.count + index
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
                        selected = min(visibleBrowsers.count + appsForUrls.count - 1, selected + 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                    }
                }
                .background {
                    Button(action: {
                        if appsAtTop {
                            if selected < appsForUrls.count {
                                openUrlsInApp(app: appsForUrls[selected])
                            } else {
                                openInBrowser(
                                    visibleBrowsers[selected - appsForUrls.count],
                                    isIncognito: false
                                )
                            }
                        } else {
                            if selected < visibleBrowsers.count {
                                openInBrowser(
                                    visibleBrowsers[selected],
                                    isIncognito: false
                                )
                            } else {
                                openUrlsInApp(app: appsForUrls[selected - visibleBrowsers.count])
                            }
                        }
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.defaultAction)

                    Button(action: {
                        if appsAtTop {
                            if selected < appsForUrls.count {
                                openUrlsInApp(app: appsForUrls[selected])
                            } else {
                                openInBrowser(
                                    visibleBrowsers[selected - appsForUrls.count],
                                    isIncognito: true
                                )
                            }
                        } else {
                            if selected < visibleBrowsers.count {
                                openInBrowser(
                                    visibleBrowsers[selected],
                                    isIncognito: true
                                )
                            } else {
                                openUrlsInApp(app: appsForUrls[selected - visibleBrowsers.count])
                            }
                        }
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
