//
//  BrowsersTab.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct BrowsersTab: View {
    @AppStorage("browsers") private var browsers: [StoredBrowser] = []
    @AppStorage("hiddenBrowsers") private var hiddenBrowsers: [URL] = []

    @State private var editingId: UUID? = nil
    @FocusState private var nameFocus: Bool

    private func move(from source: IndexSet, to destination: Int) {
        browsers.move(fromOffsets: source, toOffset: destination)
    }

    

    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(Array(browsers.enumerated()), id: \.offset) { offset, stored in
                    if let bundle = Bundle(url: stored.app) {
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

                            let baseName = bundle.infoDictionary!["CFBundleName"] as! String

                            let nameBinding: Binding<String> = .init(
                                get: {
                                    if offset < browsers.count {
                                        return browsers[offset].name
                                    }
                                    return ""
                                },
                                set: { newValue in
                                    if offset < browsers.count {
                                        browsers[offset].name = newValue
                                    }
                                }
                            )

                            if editingId == stored.id {
                                TextField(baseName, text: nameBinding)
                                    .font(.system(size: 14))
                                    .focused($nameFocus)
                                    .onSubmit {
                                        editingId = nil
                                    }
                                    .onChange(of: nameFocus) { focused in
                                        if !focused {
                                            editingId = nil
                                        }
                                    }
                            } else {
                                Text(nameBinding.wrappedValue.isEmpty ? baseName : nameBinding.wrappedValue)
                                    .font(.system(size: 14))
                                    .onTapGesture {
                                        editingId = stored.id
                                        DispatchQueue.main.async {
                                            nameFocus = true
                                        }
                                    }
                            }

                            Spacer()
                                .frame(width: 32)

                            TextField(
                                "Private argument",
                                text: Binding(
                                    get: { offset < browsers.count ? browsers[offset].privateArg : "" },
                                    set: { newValue in if offset < browsers.count { browsers[offset].privateArg = newValue } }
                                )
                            )
                            .font(
                                .system(size: 14).monospaced()
                            )

                            Spacer()
                                .frame(width: 32)

                            ShortcutButton(
                                browserId: stored.id.uuidString
                            )
                            
                            Spacer()
                                .frame(width: 8)

                            Button(action: {
                                let insertIndex = offset + 1
                                if insertIndex <= browsers.count {
                                    let existingName = (offset < browsers.count && !browsers[offset].name.isEmpty) ? browsers[offset].name : baseName
                                    let newStored = StoredBrowser(app: stored.app, name: existingName + " Copy", hidden: false)
                                    browsers.insert(newStored, at: insertIndex)
                                } else {
                                    let existingName = (offset < browsers.count && !browsers[offset].name.isEmpty) ? browsers[offset].name : baseName
                                    let newStored = StoredBrowser(app: stored.app, name: existingName + " Copy", hidden: false)
                                    browsers.append(newStored)
                                }
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)

                            Spacer()
                                .frame(width: 8)

                            Button(action: {
                                // toggle hidden flag on stored browser and keep legacy hiddenBrowsers in sync
                                if offset < browsers.count {
                                    browsers[offset].hidden.toggle()
                                    let isHidden = browsers[offset].hidden
                                    if isHidden {
                                        if !hiddenBrowsers.contains(stored.app) {
                                            hiddenBrowsers.append(stored.app)
                                        }
                                    } else {
                                        hiddenBrowsers.removeAll { $0 == stored.app }
                                    }
                                }
                            }) {
                                Image(
                                    systemName: hiddenBrowsers.contains(stored.app) || (offset < browsers.count && browsers[offset].hidden)
                                        ? "eye.slash.fill" : "eye.fill")
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                                .frame(width: 8)

                            Button(action: {
                                if offset >= 0 && offset < browsers.count {
                                    let removed = browsers.remove(at: offset)
                                    // also remove from hidden list any exact matches for this URL
                                    hiddenBrowsers.removeAll { $0 == removed.app }
                                }
                            }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                    }
                }
                .onMove(perform: move)
            }
            .onAppear {
                if browsers.isEmpty {
                    browsers = BrowserUtil.loadBrowsers(
                        oldBrowsers: browsers
                    )
                }
            }

            Text(
                "Drag and drop to reorder. Press record to assign a shortcut. Click on eye to hide unwanted browsers from prompt"
            )
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
