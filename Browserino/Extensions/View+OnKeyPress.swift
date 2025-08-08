//
//  View+OnKeyPress.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 08.08.2025.
//

import SwiftUI
import AppKit

struct KeyPressCompatModifier: ViewModifier {
    let handler: (String) -> Bool

    func body(content: Content) -> some View {
        content
            .background(FocusableKeyView(handler: handler))
    }
}

struct FocusableKeyView: NSViewRepresentable {
    let handler: (String) -> Bool

    class KeyView: NSView {
        var handler: (String) -> Bool

        init(handler: @escaping (String) -> Bool) {
            self.handler = handler
            super.init(frame: .zero)
            self.postsFrameChangedNotifications = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            if let chars = event.charactersIgnoringModifiers, let char = chars.uppercased().first {
                _ = handler(String(char))
            }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async {
                self.window?.makeFirstResponder(self)
            }
        }
    }

    func makeNSView(context: Context) -> NSView {
        return KeyView(handler: handler)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    @ViewBuilder
    func onKeyPressCompat(_ handler: @escaping (String) -> Bool) -> some View {
        if #available(macOS 14.0, *) {
            self.onKeyPress { key in
                let handled = handler(key.key.character.uppercased())
                return handled ? .handled : .ignored
            }
        } else {
            self.modifier(KeyPressCompatModifier(handler: handler))
        }
    }
}
