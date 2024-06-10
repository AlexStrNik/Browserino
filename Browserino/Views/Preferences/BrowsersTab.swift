//
//  BrowsersTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct BrowsersTab: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    
    func loadBrowsers() -> [URL] {
        return NSWorkspace.shared.urlsForApplications(toOpen: URL(string: "https:")!)
            .filter {
                let pathComponents = $0.pathComponents
                
                return pathComponents[1] == "Applications" || pathComponents[pathComponents.count - 1] == "Safari.app"
            }
            .filter { Bundle(url: $0) != nil }
            .filter { Bundle(url: $0)!.bundleIdentifier != Bundle.main.bundleIdentifier }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        browsers.move(fromOffsets: source, toOffset: destination)
    }

    var body: some View {
        VStack (alignment: .leading) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.offset) { offset, browser in
                    if let bundle = Bundle(url: browser) {
                        HStack {
                            Text((offset + 1).formatted())
                                .font(
                                    .system(size: 16)
                                )
                                .frame(width: 30, alignment: .leading)
                            
                            Image(nsImage: NSWorkspace.shared.icon(forFile: bundle.bundlePath))
                                .resizable()
                                .frame(width: 32, height: 32)
                            
                            Spacer()
                                .frame(width: 8)
                            
                            Text(bundle.infoDictionary!["CFBundleName"] as! String)
                                .font(
                                    .system(size: 14)
                                )
                            
                            Spacer()
                            
                            ShortcutButton(
                                browserId: bundle.bundleIdentifier!
                            )
                        }
                        .padding(10)
                    }
                }
                .onMove(perform: move)
            }
            .onAppear {
                if browsers.isEmpty {
                    browsers = loadBrowsers()
                }
            }
            
            Text("Drag and drop to reorder. Press record to assign a shortcut")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.5))
                .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 20)
    }
}


#Preview {
    PreferencesView()
}
