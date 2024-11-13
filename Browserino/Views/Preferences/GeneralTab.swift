//
//  GeneralTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct GeneralTab: View {
    @State private var isDefault = false
    @AppStorage("browsers") private var browsers: [URL] = []
    
    func defaultBrowser() -> String? {
        guard let browserUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https:")!) else {
            return nil
        }
        
        return Bundle(url: browserUrl)?.bundleIdentifier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 32) {
                Text("Default browser")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)
                
                VStack(alignment: .leading) {
                    Button(action: {
                        NSWorkspace.shared.setDefaultApplication(
                            at: Bundle.main.bundleURL,
                            toOpenURLsWithScheme: "http"
                        ) { _ in
                            isDefault = defaultBrowser() == Bundle.main.bundleIdentifier
                        }
                    }) {
                        Text("Make default")
                    }
                    .disabled(isDefault)
                    
                    Text("Make Browserino default browser to use it")
                        .font(.callout)
                        .opacity(0.5)
                }
            }
            
            HStack(alignment: .top, spacing: 32) {
                Text("Installed Browsers")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)
                
                VStack(alignment: .leading) {
                    Button(action: {
                        browsers = BrowserUtil.loadBrowsers()
                    }) {
                        Text("Rescan")
                    }
                    
                    Text("Rescan list of installed browsers")
                        .font(.callout)
                        .opacity(0.5)
                }
            }
            
            HStack(alignment: .top, spacing: 32) {
                Text("System reset")
                    .font(.headline)
                    .frame(width: 200, alignment: .trailing)
                
                VStack(alignment: .leading) {
                    Button(action: {
                        let defaults = UserDefaults.standard
                        let dictionary = defaults.dictionaryRepresentation()
                        dictionary.keys.forEach { key in
                            defaults.removeObject(forKey: key)
                        }
                    }) {
                        Text("Reset")
                    }
                    
                    Text("Reset all preferences")
                        .font(.callout)
                        .opacity(0.5)
                }
            }
        }
        .onAppear {
            isDefault = defaultBrowser() == Bundle.main.bundleIdentifier
        }
        .padding(20)
    }
}

#Preview {
    PreferencesView()
}
