@preconcurrency import AppKit
import SwiftUI
import BrowserScheduleCore

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindow: NSWindow?
    var configManager: ConfigManager!
    var urlsReceived = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        configManager = ConfigManager()

        // Timeout to detect if launched via URL or directly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.urlsReceived {
                self.showSettingsWindow()
            }
        }
    }

    @MainActor func showSettingsWindow() {
        NSApp.setActivationPolicy(.regular)

        let contentView = ContentView()
            .environment(configManager)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 520),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.title = "BrowserSchedule"
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urlsReceived = true
        let config = Config.loadFromFile()
        for url in urls {
            openURL(url.absoluteString, config: config)
        }
        // If settings window isn't showing, exit after handling URLs
        if settingsWindow == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NSApp.terminate(nil)
            }
        }
    }
}

// MARK: - CLI URL handling

if CommandLine.arguments.count > 1 {
    let arg = CommandLine.arguments[1]

    if arg.hasPrefix("http://") || arg.hasPrefix("https://") {
        let config = Config.loadFromFile()
        logger.debug("Received URL from macOS via command line: \(arg)")
        openURL(arg, config: config)
        exit(0)
    }
}

// MARK: - App lifecycle

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.prohibited)
app.run()
