import ArgumentParser
import BrowserScheduleCore
import Foundation

struct BrowserScheduleCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "browser-schedule-cli",
        abstract: "Command-line interface for BrowserSchedule configuration and management",
        subcommands: [Config.self, SetDefault.self, Open.self],
        defaultSubcommand: Config.self
    )
}

extension BrowserScheduleCLI {
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
            let localConfigPath = homeDir.appendingPathComponent(".config/browser-schedule/config.local.toml")
            print("  Config file: \(configPath.path)")
            if FileManager.default.fileExists(atPath: localConfigPath.path) {
                print("  Local config: \(localConfigPath.path) (merged)")
            }

            if !validation.isValid {
                print("  ⚠️  Configuration errors:")
                for error in validation.errors {
                    print("     - \(error)")
                }
                print("  Current: Using personal browser (\(config.browsers.personal)) due to config errors")
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
            do {
                try registerAppBundle()
                print("Registered app bundle with Launch Services")
                
                try setAsDefaultBrowser()
                print("Successfully set BrowserSchedule as default browser")
            } catch let error as SetupError {
                switch error {
                case .registrationFailed(let details):
                    print("Warning: Could not register app bundle: \(details)")
                    throw ExitCode.failure
                case .setDefaultFailed(let httpStatus, let httpsStatus):
                    if httpStatus == 0 || httpsStatus == 0 {
                        // Partial success - at least one scheme worked
                        print("Setting default browser requires user consent.")
                        print("If prompted, please allow BrowserSchedule to be set as default browser.")
                        print("HTTP handler status: \(httpStatus), HTTPS handler status: \(httpsStatus)")
                        if httpStatus == 0 && httpsStatus == 0 {
                            print("Successfully set BrowserSchedule as default browser")
                        } else {
                            print("Partial success - HTTP handler registered")
                        }
                    } else {
                        // Both failed
                        print("Failed to set as default browser.")
                        print("HTTP handler status: \(httpStatus), HTTPS handler status: \(httpsStatus)")
                        throw ExitCode.failure
                    }
                }
            }
        }
    }
    
    struct Open: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Open a URL using BrowserSchedule routing rules"
        )
        
        @Argument(help: "URL to open")
        var url: String
        
        func run() throws {
            guard url.hasPrefix("http://") || url.hasPrefix("https://") else {
                print("Error: URL must start with http:// or https://")
                throw ExitCode.failure
            }
            
            let config = BrowserScheduleCore.Config.loadFromFile()
            openURL(url, config: config)
        }
    }
}

BrowserScheduleCLI.main()