@preconcurrency import AppKit
import BrowserScheduleCore
import CoreServices
import Foundation
import os.log

// Custom Application Delegate
class URLAppDelegate: NSObject, NSApplicationDelegate {
    let config = Config.loadFromFile()
    var urlsReceived = false

    func applicationDidFinishLaunching(_: Notification) {
        logger.debug("BrowserSchedule app finished launching and ready for URL events")

        // Set up timeout to determine launch type
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.urlsReceived {
                // No URLs received in timeout - treat as GUI launch
                self.handleGUILaunch()
            } else {
                // This is URL handling - set timeout to exit
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    logger.debug("Timeout reached (5s) for URL handling, exiting")
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    @MainActor func handleGUILaunch() {
        logger.debug("BrowserSchedule launched as GUI app")

        if isDefaultBrowser() {
            showAlert(
                title: "BrowserSchedule is Active",
                message:
                    "BrowserSchedule is already set as your default browser and will automatically route URLs based on your configuration."
            )
            NSApplication.shared.terminate(nil)
        } else {
            do {
                try registerAppBundle()
                try setAsDefaultBrowser()
                
                showAlert(
                    title: "Setup Complete",
                    message:
                        "BrowserSchedule has been set as your default browser. URLs will now be routed based on your configuration."
                )
            } catch {
                logger.error("Setup failed: \(error)")
                showAlert(
                    title: "Setup Failed",
                    message: "Could not set BrowserSchedule as default browser: \(error.localizedDescription)",
                    style: .critical
                )
            }
            NSApplication.shared.terminate(nil)
        }
    }

    func application(_: NSApplication, open urls: [URL]) {
        self.urlsReceived = true
        logger.info("Received \(urls.count) URLs from macOS via Swift delegate")

        for url in urls {
            let urlString = url.absoluteString
            logger.debug("Processing URL from Swift delegate: \(urlString)")
            openURL(urlString, config: self.config)
        }

        logger.debug("URLs processed via Swift delegate, exiting")
        NSApplication.shared.terminate(nil)
    }
}

@MainActor func showAlert(title: String, message: String, style: NSAlert.Style = .informational) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = style
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

// Main execution - handle URL arguments, otherwise run as app
if CommandLine.arguments.count > 1 {
    let arg = CommandLine.arguments[1]
    
    // Check if it's a URL
    if arg.hasPrefix("http://") || arg.hasPrefix("https://") {
        let config = Config.loadFromFile()
        logger.debug("Received URL from macOS via command line: \(arg)")
        openURL(arg, config: config)
        exit(0)
    }
}

// Default behavior: run as app and handle both GUI launch and URL events
let app = NSApplication.shared
let delegate = URLAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.prohibited)  // Background app
app.run()