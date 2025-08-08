//
//  View+FocusEffectDisabled.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 08.08.2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func focusEffectDisabledCompat() -> some View {
        if #available(macOS 14.0, *) {
            self.focusEffectDisabled()
        } else {
            self
        }
    }
}
