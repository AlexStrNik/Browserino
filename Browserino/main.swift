//
//  main.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import Foundation
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.accessory)

// 2
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
