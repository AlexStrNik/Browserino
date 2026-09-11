//
//  PromptView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

struct PromptView: View {
    @AppStorage("browsers") private var browsers: [BrowserTarget] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [BrowserTarget] = []
    @AppStorage("apps") private var apps: [App] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]

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
            !browsers.contains($0.target)
        }
        // A row whose bundle no longer resolves renders as nothing, so excluding it
        // here keeps the keyboard selection indices in step with what is on screen.
        .filter {
            Bundle(url: $0.app) != nil
        }
    }

    var visibleBrowsers: [BrowserTarget] {
        browsers.filter {
            !hiddenBrowsers.contains($0) && Bundle(url: $0.app) != nil
        }
    }

    func shortcut(for target: BrowserTarget) -> String? {
        Bundle(url: target.app)?.bundleIdentifier.flatMap {
            shortcuts[target.shortcutKey(bundleIdentifier: $0)]
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
            target: app.target,
            isIncognito: false
        )
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if !appsForUrls.isEmpty && appsAtTop {
                            ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                                PromptItem(
                                    target: app.target,
                                    title: app.target.displayName,
                                    shortcut: shortcut(for: app.target)
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

                            Divider()
                        }
                        
                        ForEach(Array(visibleBrowsers.enumerated()), id: \.offset) {
                            index, browser in
                            PromptItem(
                                target: browser,
                                title: browser.displayName,
                                shortcut: shortcut(for: browser)
                            ) {
                                BrowserUtil.openURL(
                                    urls,
                                    target: browser,
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

                        if !appsForUrls.isEmpty && !appsAtTop {
                            Divider()

                            ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                                PromptItem(
                                    target: app.target,
                                    title: app.target.displayName,
                                    shortcut: shortcut(for: app.target)
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
                .focusable()
                .focusEffectDisabled()
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
                                BrowserUtil.openURL(
                                    urls,
                                    target: visibleBrowsers[selected - appsForUrls.count],
                                    isIncognito: false
                                )
                            }
                        } else {
                            if selected < visibleBrowsers.count {
                                BrowserUtil.openURL(
                                    urls,
                                    target: visibleBrowsers[selected],
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
                                BrowserUtil.openURL(
                                    urls,
                                    target: visibleBrowsers[selected - appsForUrls.count],
                                    isIncognito: true
                                )
                            }
                        } else {
                            if selected < visibleBrowsers.count {
                                BrowserUtil.openURL(
                                    urls,
                                    target: visibleBrowsers[selected],
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
