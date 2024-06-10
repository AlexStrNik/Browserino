//
//  ContentView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

struct SelectView: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]
    
    let urls: [URL]
    
    @State private var opacityAnimation = 0.0
    @State private var selected = 0
    @FocusState private var focused: Bool
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(browsers.enumerated()), id: \.offset) { index, browser in
                            if let bundle = Bundle(url: browser) {
                                Button(action: {
                                    NSWorkspace.shared.open(
                                        urls,
                                        withApplicationAt: browser,
                                        configuration: .init()
                                    )
                                }) {
                                    HStack {
                                        Text(bundle.infoDictionary!["CFBundleName"] as! String)
                                            .font(
                                                .system(size: 12, weight: .bold)
                                            )
                                        
                                        Spacer()
                                        
                                        if let shortcut = shortcuts[bundle.bundleIdentifier!] {
                                            Text(shortcut)
                                                .font(.caption)
                                                .frame(minWidth: 4)
                                                .opacity(0.5)
                                                .padding(5)
                                                .background(
                                                    Color.secondary.opacity(0.2)
                                                )
                                                .cornerRadius(4)
                                        }
                                        
                                        Spacer()
                                            .frame(width: 8)
                                        
                                        Image(
                                            nsImage: NSWorkspace.shared.icon(
                                                forFile: bundle.bundlePath
                                            )
                                        )
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                    }
                                    .padding(8)
                                    .id(index)
                                }
                                .if(shortcuts[bundle.bundleIdentifier!] != nil) {
                                    $0.keyboardShortcut(
                                        KeyEquivalent(shortcuts[bundle.bundleIdentifier!]!.first!),
                                        modifiers: []
                                    )
                                }
                                .buttonStyle(
                                    SelectButtonStyle(
                                        selected: selected == index
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
                        selected = min(browsers.count - 1, selected + 1)
                        scrollViewProxy.scrollTo(selected, anchor: .center)
                        return .handled
                    } else if press.key == KeyEquivalent.return {
                        let browser = browsers[selected]
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
//        .clipShape(
//            .rect(
//                cornerSize: .init(width: 16, height: 16)
//            )
//        )
        .opacity(opacityAnimation)
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    SelectView(urls: [])
}
