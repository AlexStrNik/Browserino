//
//  BrowserinoApp.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var selectorWindow: BrowserinoWindow?
    private var preferencesWindow: NSWindow?
    
    @AppStorage("rules") private var rules: [Rule] = []
    
    var statusMenu: NSMenu!
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let statusButton = statusBarItem!.button
        statusButton!.image = NSImage.menuIcon
        
        let preferences = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: "")
        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "")
        
        statusMenu = NSMenu()
        
        statusMenu!.addItem(preferences)
        statusMenu!.addItem(.separator())
        statusMenu!.addItem(quit)
        
        statusBarItem!.menu = statusMenu!
        
        if UserDefaults.standard.object(forKey: "browsers") == nil {
            openPreferences()
        }
    }
    
    func application(_ application: NSApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        if userActivityType == NSUserActivityTypeBrowsingWeb {
            return true
        }
        
        return false
    }
    
    func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            self.application(application, open: [url])
            return true
        }
        
        return false
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func openPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                styleMask: [.miniaturizable, .closable, .resizable, .titled],
                backing: .buffered,
                defer: false
            )
        }
        
        preferencesWindow!.center()
        preferencesWindow!.title = "Preferences"
        preferencesWindow!.contentView = NSHostingView(rootView: PreferencesView())
        
        preferencesWindow!.isReleasedWhenClosed = false
        preferencesWindow!.titlebarAppearsTransparent = true
        
        preferencesWindow!.contentMinSize = NSSize(width: 700, height: 500)
        
        preferencesWindow!.collectionBehavior = [.moveToActiveSpace, .fullScreenNone]
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        preferencesWindow!.makeKeyAndOrderFront(nil)
        preferencesWindow!.orderFrontRegardless()
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if urls.count == 1 {
            let url = urls.first!.absoluteString

            for rule in rules {
                let regex = try? Regex(rule.regex).ignoresCase()
                
                if let regex, url.firstMatch(of: regex) != nil {
                    NSWorkspace.shared.open(
                        urls,
                        withApplicationAt: rule.app,
                        configuration: NSWorkspace.OpenConfiguration.init()
                    )
                    return
                }
            }
        }
        
        if selectorWindow == nil {
            selectorWindow = BrowserinoWindow()
        }
        
        let screen = getScreenWithMouse()!.visibleFrame
        
        selectorWindow?.setFrameOrigin(
            NSPoint(
                x: clamp(
                    min: 20,
                    max: screen.width - BrowserinoWindow.selectorWidth - 20,
                    value: NSEvent.mouseLocation.x - BrowserinoWindow.selectorWidth / 2
                ),
                y: clamp(
                    min: 20,
                    max: screen.height - BrowserinoWindow.selectorHeight - 20,
                    value: NSEvent.mouseLocation.y - (BrowserinoWindow.selectorHeight - 30)
                )
            )
        )
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        selectorWindow!.deactivateDelay()
        
        selectorWindow!.contentView = NSHostingView(
            rootView: PromptView(
                urls: urls
            )
        )
        
        selectorWindow!.makeKeyAndOrderFront(nil)
        selectorWindow!.isReleasedWhenClosed = false
        selectorWindow!.delegate = self
    }
    
    func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        CGFloat.minimum(CGFloat.maximum(min, value), max)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        if selectorWindow!.hidesOnDeactivate {
            selectorWindow!.contentView = nil
            selectorWindow!.close()
        }
    }
    
    func getScreenWithMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) })
        
        return screenWithMouse
    }
}
