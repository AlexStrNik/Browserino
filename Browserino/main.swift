//
//  main.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import Foundation
import AppKit

let app = BrowserinoApplication.shared
let delegate = AppDelegate()

app.delegate = delegate
app.setActivationPolicy(.accessory)

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
