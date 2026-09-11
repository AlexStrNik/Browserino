//
//  PreferencesView.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import SwiftUI

struct PreferencesView: View {
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
            
            RulesTab()
                .tabItem {
                    Label("Rules", systemImage: "gear")
                }
                .tag(3)
            
            BrowserSearchLocationsTab()
                .tabItem {
                    Label("Locations", systemImage: "gear")
                }
                .tag(4)

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "gear")
                }
                .tag(5)
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

#Preview {
    PreferencesView()
}
