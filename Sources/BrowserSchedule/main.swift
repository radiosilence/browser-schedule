@preconcurrency import AppKit
import ArgumentParser
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
            // Register the app bundle first
            let registerTask = Process()
            registerTask.executableURL = URL(
                fileURLWithPath:
                    "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
            )
            registerTask.arguments = ["-f", "/Applications/BrowserSchedule.app"]

            do {
                try registerTask.run()
                registerTask.waitUntilExit()
                logger.debug("Registered app bundle with Launch Services")
            } catch {
                logger.error("Could not register app bundle: \(error)")
                showAlert(
                    title: "Registration Failed",
                    message: "Could not register BrowserSchedule with the system: \(error)",
                    style: .critical
                )
                NSApplication.shared.terminate(nil)
                return
            }

            // Set as default for http and https
            let httpStatus = LSSetDefaultHandlerForURLScheme(
                "http" as CFString, bundleIdentifier as CFString)
            let httpsStatus = LSSetDefaultHandlerForURLScheme(
                "https" as CFString, bundleIdentifier as CFString)

            if httpStatus == noErr, httpsStatus == noErr {
                showAlert(
                    title: "Setup Complete",
                    message:
                        "BrowserSchedule has been set as your default browser. URLs will now be routed based on your configuration."
                )
            } else {
                showAlert(
                    title: "Setup Required",
                    message:
                        "Please allow BrowserSchedule to be set as your default browser in the system dialog that appears.",
                    style: .warning
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

// ArgumentParser commands
struct BrowserSchedule: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Automatically switch default browser based on schedule and URL patterns",
        subcommands: [Config.self, SetDefault.self, Run.self],
        defaultSubcommand: Run.self
    )
}

extension BrowserSchedule {
    struct Config: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Display current configuration and status"
        )
        
        func run() throws {
            let config = BrowserScheduleCore.Config.loadFromFile()
            let validation = ConfigValidation.validate(config)

            print("Current configuration:")
            print("  Work browser: \(config.browsers.work)")
            print("  Personal browser: \(config.browsers.personal)")
            let shiftType = config.workTime.isNightShift ? " (night shift)" : ""
            print("  Work hours: \(config.workTime.start)-\(config.workTime.end)\(shiftType)")
            print("  Work days: \(config.workDays.start)-\(config.workDays.end)")
            // Show merged domain overrides
            if let overrides = config.urls {
                if let personal = overrides.personal, !personal.isEmpty {
                    print("  Personal overrides: \(personal.joined(separator: ", "))")
                }
                if let work = overrides.work, !work.isEmpty {
                    print("  Work overrides: \(work.joined(separator: ", "))")
                }
            }

            print("  Logging: enabled (unified logging)")
            print("  Privacy: URLs automatically redacted by macOS unified logging")
            print("  View logs: log show --predicate 'subsystem == \"\(bundleIdentifier)\"' --last 1h")

            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            let configPath = homeDir.appendingPathComponent(".config/browser-schedule/config.toml")
            let localConfigPath = homeDir.appendingPathComponent(
                ".config/browser-schedule/config.local.toml")
            print("  Config file: \(configPath.path)")
            if FileManager.default.fileExists(atPath: localConfigPath.path) {
                print("  Local config: \(localConfigPath.path) (merged)")
            }

            if !validation.isValid {
                print("  ⚠️  Configuration errors:")
                for error in validation.errors {
                    print("     - \(error)")
                }
                print(
                    "  Current: Using personal browser (\(config.browsers.personal)) due to config errors"
                )
            } else {
                if isWorkTime(config: config) {
                    print("  Current: Work time - using \(config.browsers.work)")
                } else {
                    print("  Current: Personal time - using \(config.browsers.personal)")
                }
            }
        }
    }
    
    struct SetDefault: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "set-default",
            abstract: "Set BrowserSchedule as the default browser"
        )
        
        func run() throws {
            // Register the app bundle first
            let registerTask = Process()
            registerTask.executableURL = URL(
                fileURLWithPath:
                    "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
            )
            registerTask.arguments = ["-f", "/Applications/BrowserSchedule.app"]

            do {
                try registerTask.run()
                registerTask.waitUntilExit()
                print("Registered app bundle with Launch Services")
            } catch {
                print("Warning: Could not register app bundle: \(error)")
            }

            // Set as default for http and https
            let httpStatus = LSSetDefaultHandlerForURLScheme(
                "http" as CFString, bundleIdentifier as CFString)
            let httpsStatus = LSSetDefaultHandlerForURLScheme(
                "https" as CFString, bundleIdentifier as CFString)

            if httpStatus == noErr, httpsStatus == noErr {
                print("Successfully set BrowserSchedule as default browser")
            } else {
                print("Setting default browser requires user consent.")
                print("If prompted, please allow BrowserSchedule to be set as default browser.")
                print("HTTP handler status: \(httpStatus), HTTPS handler status: \(httpsStatus)")
            }
        }
    }
    
    struct Run: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Run as background app (default mode)"
        )
        
        @Argument(help: "URL to open directly")
        var url: String? = nil
        
        func run() throws {
            // Handle direct URL argument
            if let urlString = url {
                if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                    let config = BrowserScheduleCore.Config.loadFromFile()
                    logger.debug("Received URL from macOS via command line: \(urlString)")
                    openURL(urlString, config: config)
                    return
                } else if urlString == "--install" || urlString == "--update" {
                    print("Use 'task install' or 'task update' to manage app bundle")
                    throw ExitCode.failure
                }
            }
            
            // Default behavior: run as app and handle both GUI launch and URL events
            Task { @MainActor in
                let app = NSApplication.shared
                let delegate = URLAppDelegate()
                app.delegate = delegate
                app.setActivationPolicy(.prohibited)  // Background app
                app.run()
            }
            
            // Keep the main thread alive
            RunLoop.main.run()
        }
    }
}

// Default behavior: run as app with URL event handling or setup
func isDefaultBrowser() -> Bool {
    let workspace = NSWorkspace.shared

    guard let httpURL = URL(string: "http://example.com"),
        let httpsURL = URL(string: "https://example.com")
    else {
        return false
    }

    let httpHandler = workspace.urlForApplication(toOpen: httpURL)?.lastPathComponent
        .replacingOccurrences(of: ".app", with: "")
    let httpsHandler = workspace.urlForApplication(toOpen: httpsURL)?.lastPathComponent
        .replacingOccurrences(of: ".app", with: "")

    return httpHandler == "BrowserSchedule" && httpsHandler == "BrowserSchedule"
}

@MainActor func showAlert(title: String, message: String, style: NSAlert.Style = .informational) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = style
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

// Main entry point
BrowserSchedule.main()
