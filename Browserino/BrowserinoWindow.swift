//
//  BrowserinoWindow.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import Foundation
import AppKit

class BrowserinoWindow: NSPanel {
    static let selectorWidth: CGFloat = 250
    static let selectorHeight: CGFloat = 200
    
    public convenience init() {
        self.init(
            contentRect: .init(x: 0, y: 0, width: Self.selectorWidth, height: Self.selectorHeight),
            styleMask: .nonactivatingPanel,
            backing: .buffered,
            defer: false
        )
        
        self.collectionBehavior = [.stationary, .ignoresCycle, .fullScreenAuxiliary, .canJoinAllSpaces]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.level = NSWindow.Level(Int(CGShieldingWindowLevel()))
        self.hidesOnDeactivate = true
        self.isMovable = false
    }
}

extension NSPanel {
    open override var canBecomeKey: Bool { true }
}
