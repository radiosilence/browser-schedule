import AppKit
import CoreServices
import Foundation
import os.log
import BrowserScheduleCore

// Custom Application Delegate
class URLAppDelegate: NSObject, NSApplicationDelegate {
    let config = Config.loadFromFile()

    func applicationDidFinishLaunching(_: Notification) {
        if isLoggingEnabled(config) {
            logger.info("BrowserSchedule app finished launching and ready for URL events")
        }

        // Set up timeout to exit if no URLs received within 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if isLoggingEnabled(self.config) {
                logger.info("Timeout reached (5s), no URLs received, exiting")
            }
            NSApplication.shared.terminate(nil)
        }
    }

    func application(_: NSApplication, open urls: [URL]) {
        if isLoggingEnabled(config) {
            logger.info("Received \(urls.count) URLs from macOS via Swift delegate")
        }

        for url in urls {
            let urlString = url.absoluteString
            if isLoggingEnabled(config) {
                logger.info("Processing URL from Swift delegate: \(urlString)")
            }
            openURL(urlString, config: config)
        }

        if isLoggingEnabled(config) {
            logger.info("URLs processed via Swift delegate, exiting")
        }
        NSApplication.shared.terminate(nil)
    }
}

// Main execution
if CommandLine.arguments.count > 1 {
    let arg = CommandLine.arguments[1]

    // Handle command line arguments (--config, --install, etc.)
    switch arg {
    case "--config":
        let config = Config.loadFromFile()
        let validation = ConfigValidation.validate(config)

        print("Current configuration:")
        print("  Work browser: \(config.browsers.work)")
        print("  Personal browser: \(config.browsers.personal)")
        let startHour = parseTime(config.workTime.start) ?? 0
        let endHour = parseTime(config.workTime.end) ?? 0
        let shiftType = startHour < endHour ? "" : " (night shift)"
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

        print("  Logging: \(isLoggingEnabled(config) ? "enabled (unified logging)" : "disabled")")
        if isLoggingEnabled(config) {
            print(
                "  View logs: log show --predicate 'subsystem == \"com.radiosilence.browser-schedule\"' --last 1h"
            )
        }

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
        exit(0)

    case "--set-default":
        let bundleId = "com.radiosilence.browser-schedule"

        // Register the app bundle first
        let registerTask = Process()
        registerTask.launchPath =
            "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
        registerTask.arguments = ["-f", "/Applications/BrowserSchedule.app"]

        do {
            try registerTask.run()
            registerTask.waitUntilExit()
            print("Registered app bundle with Launch Services")
        } catch {
            print("Warning: Could not register app bundle: \(error)")
        }

        // Set as default for http and https
        let httpStatus = LSSetDefaultHandlerForURLScheme("http" as CFString, bundleId as CFString)
        let httpsStatus = LSSetDefaultHandlerForURLScheme("https" as CFString, bundleId as CFString)

        if httpStatus == noErr, httpsStatus == noErr {
            print("Successfully set BrowserSchedule as default browser")
        } else {
            print("Setting default browser requires user consent.")
            print("If prompted, please allow BrowserSchedule to be set as default browser.")
            print("HTTP handler status: \(httpStatus), HTTPS handler status: \(httpsStatus)")
        }

        exit(0)

    case "--install", "--update":
        print("Use 'task install' or 'task update' to manage app bundle")
        exit(1)

    default:
        // Check if it's a URL
        if arg.hasPrefix("http://") || arg.hasPrefix("https://") {
            let config = Config.loadFromFile()
            if isLoggingEnabled(config) {
                logger.info("Received URL from macOS via command line: \(arg)")
            }
            openURL(arg, config: config)
            exit(0)
        }
    }
}

// Default behavior: run as app with URL event handling
let config = Config.loadFromFile()
if isLoggingEnabled(config) {
    logger.info("Starting BrowserSchedule as native Swift app")
}

let app = NSApplication.shared
let delegate = URLAppDelegate()
app.delegate = delegate
app.setActivationPolicy(.prohibited) // Background app
app.run()