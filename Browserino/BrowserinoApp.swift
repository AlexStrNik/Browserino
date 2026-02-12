//
//  BrowserinoApp.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import SwiftUI
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var selectorWindow: BrowserinoWindow?
    private var preferencesWindow: NSWindow?
    
    @AppStorage("rules") private var rules: [Rule] = []
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    
    var statusMenu: NSMenu!
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBar()
        
        UserDefaults.standard.addObserver(self, forKeyPath: "showInMenuBar", options: [.new], context: nil)
        
        if UserDefaults.standard.object(forKey: "browsers") == nil {
            openPreferences()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        self.openPreferences()
        return true
    }
    
    func setupStatusBar() {
        if showInMenuBar {
            if statusBarItem == nil {
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
            }
        } else {
            if statusBarItem != nil {
                NSStatusBar.system.removeStatusItem(statusBarItem!)
                statusBarItem = nil
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "showInMenuBar" {
            setupStatusBar()
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "showInMenuBar")
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
        var processedUrls = urls
        
        if urls.count == 1 {
            let url = urls.first!
            
            if url.scheme == "browserino" && url.host == "open" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems,
                   let encodedUrl = queryItems.first(where: { $0.name == "url" })?.value,
                   let decodedData = Data(base64Encoded: encodedUrl),
                   let decodedUrlString = String(data: decodedData, encoding: .utf8),
                   let decodedUrl = URL(string: decodedUrlString) {
                    processedUrls = [decodedUrl]
                } else {
                    return
                }
            }
            
            let urlString = processedUrls.first!.absoluteString

            for rule in rules {
                let regex = try? Regex(rule.regex).ignoresCase()
                
                if let regex, urlString.firstMatch(of: regex) != nil {
                    BrowserUtil.openURL(
                        processedUrls,
                        app: rule.app,
                        isIncognito: false,
                        profileDirectory: rule.profileDirectory
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
                    min: screen.minX + 20,
                    max: screen.maxX - selectorWindow!.frame.width - 20,
                    value: NSEvent.mouseLocation.x - selectorWindow!.frame.width / 2
                ),
                y: clamp(
                    min: screen.minY + 20,
                    max: screen.maxY - selectorWindow!.frame.height - 20,
                    value: NSEvent.mouseLocation.y - (selectorWindow!.frame.height - 30)
                )
            )
        )
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        selectorWindow!.deactivateDelay()
        
        selectorWindow!.contentView = NSHostingView(
            rootView: PromptView(
                urls: processedUrls
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
