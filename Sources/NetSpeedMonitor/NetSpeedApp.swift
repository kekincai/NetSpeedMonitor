import SwiftUI
import AppKit

@main
struct NetSpeedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var stats: NetworkStats?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.attributedTitle = NSAttributedString(string: "↓0 KB/s\n↑0 KB/s")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Network Speed Monitor", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        stats = NetworkStats()
        stats?.onUpdate = { [weak self] download, upload in
            self?.updateStatusBar(download: download, upload: upload)
        }
    }
    
    func updateStatusBar(download: String, upload: String) {
        guard let button = statusItem?.button else { return }
        
        let text = "↓\(download)\n↑\(upload)"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.lineSpacing = -2
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
            .paragraphStyle: paragraphStyle
        ]
        
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
