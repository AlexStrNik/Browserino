//
//  PromptView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

struct PromptView: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [URL] = []
    @AppStorage("apps") private var apps: [App] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]
    
    let urls: [URL]
    
    @State private var opacityAnimation = 0.0
    @State private var selected = 0
    @FocusState private var focused: Bool
    
    var appsForUrls: [App] {
        urls.flatMap { url in
            return apps.filter { app in
                url.host() == app.host
            }
        }
        .filter {
            !browsers.contains($0.app)
        }
    }
    
    var visibleBrowsers: [URL] {
        browsers.filter { !hiddenBrowsers.contains($0) }
    }
    
    func openUrlsInApp(app: App) {
        let urls = if app.schemeOverride.isEmpty {
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
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if !appsForUrls.isEmpty {
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
                        
                        ForEach(Array(visibleBrowsers.enumerated()), id: \.offset) { index, browser in
                            if let bundle = Bundle(url: browser) {
                                PromptItem(
                                    browser: browser,
                                    urls: urls,
                                    bundle: bundle,
                                    shortcut: shortcuts[bundle.bundleIdentifier!]
                                ) {
                                    BrowserUtil.openURL(
                                        urls,
                                        app: browser,
                                        isIncognito: NSEvent.modifierFlags.contains(.shift)
                                    )
                                }
                                .id(appsForUrls.count + index)
                                .buttonStyle(
                                    SelectButtonStyle(
                                        selected: selected == appsForUrls.count + index
                                    )
                                )
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
                        if selected < appsForUrls.count {
                            openUrlsInApp(app: appsForUrls[selected])
                        } else {
                            BrowserUtil.openURL(
                                urls,
                                app: browsers[selected - appsForUrls.count],
                                isIncognito: false
                            )
                        }
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.defaultAction)
                    
                    Button(action: {
                        if selected < appsForUrls.count {
                            openUrlsInApp(app: appsForUrls[selected])
                        } else {
                            BrowserUtil.openURL(
                                urls,
                                app: browsers[selected - appsForUrls.count],
                                isIncognito: true
                            )
                        }
                    }) {}
                    .opacity(0)
                    .keyboardShortcut(.return, modifiers: [.shift])
                }
                .onAppear {
                    focused.toggle()
                    withAnimation(.interactiveSpring(duration: 0.3)) {
                        opacityAnimation = 1
                    }
                }
            }
            
            Divider()
            
            if let host = urls.first?.host() {
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.declareTypes([.string], owner: nil)
                    pasteboard.setString(urls.first?.absoluteString ?? "", forType: .string)
                }) {
                    Text(
                        host
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(
                    KeyEquivalent("c"),
                    modifiers: [.command, .option]
                )
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
