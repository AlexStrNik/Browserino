//
//  ShortcutButton.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct ShortcutButton: View {
    let shortcutKey: String
    
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
                .onChange(of: focus) { _, newFocus in
                    isRecording = newFocus
                }
                .onKeyPress { press in
                    let key = press.key.character.uppercased()
                    isRecording = false

                    if let shortcut = shortcuts.first(where: { $0.value == key }) {
                        shortcuts[shortcut.key] = nil
                    }
                    shortcuts[shortcutKey] = key

                    return .handled
                }
        } else {
            let recordedKey = shortcuts[shortcutKey]
            
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
