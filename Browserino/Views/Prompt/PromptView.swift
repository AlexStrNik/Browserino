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
    @AppStorage("apps") private var apps: [App] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]
    
    let urls: [URL]
    
    @State private var opacityAnimation = 0.0
    @State private var selected = 0
    @FocusState private var focused: Bool
    
    var appsForUrls: [URL] {
        urls.flatMap { url in
            return apps.filter { app in
                url.host() == app.domain
            }.map {
                $0.app
            }
        }
        .filter {
            !browsers.contains($0)
        }
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if !appsForUrls.isEmpty {
                            ForEach(Array(appsForUrls.enumerated()), id: \.offset) { index, app in
                                if let bundle = Bundle(url: app) {
                                    PromptItem(
                                        browser: app,
                                        urls: urls,
                                        bundle: bundle,
                                        shortcut: shortcuts[bundle.bundleIdentifier!]
                                    )
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
                        
                        ForEach(Array(browsers.enumerated()), id: \.offset) { index, browser in
                            if let bundle = Bundle(url: browser) {
                                PromptItem(
                                    browser: browser,
                                    urls: urls,
                                    bundle: bundle,
                                    shortcut: shortcuts[bundle.bundleIdentifier!]
                                )
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
                .focusEffectDisabled()
                .focused($focused)
                .onKeyPress { press in
                    if press.key == KeyEquivalent.upArrow {
                        selected = max(0, selected - 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                        return .handled
                    } else if press.key == KeyEquivalent.downArrow {
                        selected = min(browsers.count + appsForUrls.count - 1, selected + 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                        return .handled
                    } else if press.key == KeyEquivalent.return {
                        let browser = if selected < appsForUrls.count {
                            appsForUrls[selected]
                        } else {
                            browsers[selected]
                        }
                        
                        NSWorkspace.shared.open(
                            urls,
                            withApplicationAt: browser,
                            configuration: NSWorkspace.OpenConfiguration.init()
                        )
                        return .handled
                    }
                    
                    return .ignored
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
                Text(
                    host
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
