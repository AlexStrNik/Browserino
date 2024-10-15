//
//  PreferencesView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import AppKit
import SwiftUI

extension NSTableView {
    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        backgroundColor = NSColor.clear
        enclosingScrollView?.drawsBackground = false
    }
}

struct PreferencesView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(0)
            
            BrowsersTab()
                .tabItem {
                    Label("Browsers", systemImage: "gear")
                }
                .tag(1)
            
            AppsTab()
                .tabItem {
                    Label("Apps", systemImage: "gear")
                }
                .tag(2)
            
            AboutTab()
                .tabItem {
                    Label("About", systemImage: "gear")
                }
                .tag(2)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

#Preview {
    PreferencesView()
}
