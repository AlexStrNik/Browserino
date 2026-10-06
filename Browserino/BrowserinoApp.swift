//
//  BrowserinoApp.swift
//  Browserino
//
//  Created by Aleksandr Strizhnev on 06.06.2024.
//

import SwiftUI
import Foundation
import Combine
import KeyboardShortcuts

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, BrowserSwitchPresenting {
    private var languageSubscription: AnyCancellable?
    private var selectorWindow: BrowserinoWindow?
    private var preferencesWindow: NSWindow?
    
    @AppStorage("rules") private var rules: [Rule] = []
    @AppStorage("showInMenuBar") private var showInMenuBar: Bool = true
    
    var statusMenu: NSMenu!
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let chrome = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            SettingsPolicy.migrateLegacyProfiles(defaults: .standard, chrome: chrome)
        }
        BrowserSwitchService.shared.presenter = self
        BrowserSwitchService.shared.startTracking()
        KeyboardShortcuts.onKeyUp(for: .moveCurrentTab) { BrowserSwitchService.shared.beginMove(preferFrontmost: true) }
        languageSubscription = Localization.shared.$activeLanguage.sink { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if let item = self.statusBarItem { NSStatusBar.system.removeStatusItem(item); self.statusBarItem = nil }
                self.setupStatusBar()
                self.preferencesWindow?.title = L10n.text("settings.window.title")
            }
        }
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
                
                let preferences = NSMenuItem(title: L10n.text("menu.preferences"), action: #selector(openPreferences), keyEquivalent: "")
                let quit = NSMenuItem(title: L10n.text("menu.quit"), action: #selector(quitApp), keyEquivalent: "")
                
                statusMenu = NSMenu()
                
                let move = NSMenuItem(title: L10n.text("tabs.transfer.title"), action: #selector(moveCurrentTab), keyEquivalent: "")
                statusMenu!.addItem(move)
                statusMenu!.addItem(.separator())
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
    
    override nonisolated func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "showInMenuBar" {
            // Another process writing our defaults delivers this off the main
            // thread, so hop rather than assuming isolation.
            Task { @MainActor in
                setupStatusBar()
                NSApp.setActivationPolicy(.accessory)
            }
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
    
    @objc func moveCurrentTab() { BrowserSwitchService.shared.beginMove(preferFrontmost: false) }

    func presentMovePrompt(snapshot: SourceTabSnapshot) {
        let targets = [BrowserTarget](rawValue: UserDefaults.standard.string(forKey: "browsers") ?? "") ?? []
        let hidden = [BrowserTarget](rawValue: UserDefaults.standard.string(forKey: "hiddenBrowsers") ?? "") ?? []
        guard TargetPolicy.visible(targets, hidden: hidden, profilesEnabled: UserDefaults.standard.object(forKey: "profilesEnabled") as? Bool != false).contains(where: { Bundle(url: $0.app) != nil && Bundle(url: $0.app)?.bundleIdentifier != snapshot.bundleIdentifier }) else {
            BrowserSwitchService.shared.presentNoDestinationAlert(); return
        }
        presentSelector(urls: [snapshot.url], sourceTab: snapshot)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    @objc func openPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 860, height: 500),
                styleMask: [.miniaturizable, .closable, .resizable, .titled],
                backing: .buffered,
                defer: false
            )
        }
        
        preferencesWindow!.center()
        preferencesWindow!.title = L10n.text("settings.window.title")
        preferencesWindow!.contentView = NSHostingView(rootView: LocalizedRoot { PreferencesView() })
        
        preferencesWindow!.isReleasedWhenClosed = false
        preferencesWindow!.titlebarAppearsTransparent = true
        
        preferencesWindow!.contentMinSize = NSSize(width: 860, height: 500)
        
        preferencesWindow!.collectionBehavior = [.moveToActiveSpace, .fullScreenNone]
        
        NSApplication.shared.activateCompat()
        
        preferencesWindow!.makeKeyAndOrderFront(nil)
        preferencesWindow!.orderFrontRegardless()
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        let processedUrls = urls.compactMap(\.browserinoIncomingURL)
        guard !processedUrls.isEmpty else { return }

        if processedUrls.count == 1 {
            let urlString = processedUrls.first!.absoluteString

            for rule in rules {
                let regex = try? Regex(rule.regex).ignoresCase()
                
                if let regex, urlString.firstMatch(of: regex) != nil {
                    BrowserUtil.openURL(
                        processedUrls,
                        target: rule.target,
                        isIncognito: false
                    )
                    return
                }
            }
        }
        
        presentSelector(urls: processedUrls)
    }

    private func presentSelector(urls: [URL], sourceTab: SourceTabSnapshot? = nil) {
        if selectorWindow == nil {
            selectorWindow = BrowserinoWindow()
        }
        
        guard let screen = (getScreenWithMouse() ?? NSScreen.main ?? NSScreen.screens.first)?.visibleFrame else { return }
        
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
        
        NSApplication.shared.activateCompat()
        selectorWindow!.deactivateDelay()
        
        selectorWindow!.contentView = NSHostingView(
            rootView: LocalizedRoot { PromptView(urls: urls, sourceTab: sourceTab) }
        )
        
        selectorWindow!.makeKeyAndOrderFront(nil)
        selectorWindow!.isReleasedWhenClosed = false
        selectorWindow!.delegate = self
    }
    
    func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        CGFloat.minimum(CGFloat.maximum(min, value), max)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        if notification.object as? NSWindow === selectorWindow, selectorWindow?.hidesOnDeactivate == true, selectorWindow?.presentingAlert == false {
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
