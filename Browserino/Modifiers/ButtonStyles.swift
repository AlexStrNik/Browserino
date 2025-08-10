//
//  ButtonStyles.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import SwiftUI
import Foundation

struct BackgroundOnHover: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.secondary.opacity(0.5) : .clear)
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
    }
}

struct SelectButtonStyle: ButtonStyle {
    let selected: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .contentShape(RoundedRectangle(cornerSize: CGSize(width: 8, height: 8)))
            .background(configuration.isPressed || selected ? Color.accentColor : .clear)
            .modifier(BackgroundOnHover())
            .cornerRadius(8)
    }
}
