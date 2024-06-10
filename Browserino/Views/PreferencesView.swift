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
        enclosingScrollView!.drawsBackground = false
    }
}

struct RecordButton: View {
    let browserId: String
    
    @AppStorage("shortcuts") private var shortcuts: [String: String] = [:]
    
    @State private var isRecording: Bool = false
    @FocusState private var focus: Bool
    
    var body: some View {
        if isRecording {
            Text("Press any key")
                .padding(5)
                .contentShape(.rect)
                .focusable()
                .focused($focus)
                .onChange(of: focus) {
                    isRecording = focus
                }
                .onKeyPress { key in
                    isRecording = false
                    
                    let recordedKey = key.key.character.uppercased()
                    
                    if let shortcut = shortcuts.first(where: { $0.value == recordedKey }) {
                        shortcuts[shortcut.key] = nil
                    }
                    shortcuts[browserId] = recordedKey
                    
                    return .handled
                }
        } else {
            let recordedKey = shortcuts[browserId]
            
            Button(action: {
                isRecording = true
                focus = true
            }, label: {
                Text(recordedKey ?? "Record")
                    .padding(5)
            })
            .opacity(recordedKey == nil ? 0.5 : 1)
        }
    }
}

struct PreferencesView: View {
    @AppStorage("browsers") private var browsers: [URL] = []
    @State private var isDefault = false
    
    func loadBrowsers() -> [URL] {
        return NSWorkspace.shared.urlsForApplications(toOpen: URL(string: "https:")!)
            .filter {
                let pathComponents = $0.pathComponents
                
                return pathComponents[1] == "Applications" || pathComponents[pathComponents.count - 1] == "Safari.app"
            }
            .filter { Bundle(url: $0) != nil }
            .filter { Bundle(url: $0)!.bundleIdentifier != "xyz.alexstrnik.Browserino" }
    }
    
    func defaultBrowser() -> String? {
        guard let browserUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https:")!) else {
            return nil
        }
        
        return Bundle(url: browserUrl)?.bundleIdentifier
    }
    
    func move(from source: IndexSet, to destination: Int) {
        browsers.move(fromOffsets: source, toOffset: destination)
    }

    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                    .resizable()
                    .frame(width: 32, height: 32)
                
                Spacer()
                    .frame(width: 8)
                
                Text("Browserino v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)")
                    .font(.title2)
                
                Spacer()
                
                Button(action: {
                    browsers = loadBrowsers()
                }) {
                    Text("Rescan")
                }
                
                if !isDefault {
                    Button(action: {
                        NSWorkspace.shared.setDefaultApplication(
                            at: Bundle.main.bundleURL,
                            toOpenURLsWithScheme: "http"
                        ) { _ in
                            isDefault = defaultBrowser() == "xyz.alexstrnik.Browserino"
                        }
                    }) {
                        Text("Make default")
                    }
                }
            }
            .padding(.horizontal, 20)
            .onAppear {
                isDefault = defaultBrowser() == "xyz.alexstrnik.Browserino"
            }
            
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
                            
                            RecordButton(
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
        .padding(.vertical, 20)
    }
}

#Preview {
    PreferencesView()
}
