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
                    Label(L10n.text("settings.tabs.general"), systemImage: "gear")
                }
                .tag(0)
            
            BrowsersTab()
                .tabItem {
                    Label(L10n.text("settings.tabs.browsers"), systemImage: "gear")
                }
                .tag(1)
            
            AppsTab()
                .tabItem {
                    Label(L10n.text("settings.tabs.apps"), systemImage: "gear")
                }
                .tag(2)
            
            RulesTab()
                .tabItem {
                    Label(L10n.text("settings.tabs.rules"), systemImage: "gear")
                }
                .tag(3)
            
            BrowserSearchLocationsTab()
                .tabItem {
                    Label(L10n.text("settings.tabs.locations"), systemImage: "gear")
                }
                .tag(4)

            AboutTab()
                .tabItem {
                    Label(L10n.text("settings.tabs.about"), systemImage: "gear")
                }
                .tag(5)
        }
        .frame(minWidth: 860, minHeight: 500)
    }
}

#Preview {
    PreferencesView()
}
