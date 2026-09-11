//
//  PromptItem.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 10.06.2024.
//

import SwiftUI

struct PromptItem: View {
    var target: BrowserTarget
    var title: String
    var shortcut: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(
                        .system(size: 12, weight: .bold)
                    )
                
                Spacer()
                
                if let shortcut {
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
                
                BrowserTargetIcon(target: target, badgeSize: 11)
                    .frame(width: 24, height: 24)
            }
            .padding(8)
        }
        .if(shortcut != nil) {
            return $0.keyboardShortcut(
                KeyEquivalent(shortcut!.lowercased().first!),
                modifiers: [.shift]
            ).background {
                Button(action: action) {}
                    .opacity(0)
                    .keyboardShortcut(
                        KeyEquivalent(shortcut!.lowercased().first!),
                        modifiers: []
                    )
            }
        }
    }
}
