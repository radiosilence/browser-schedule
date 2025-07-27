import AppKit
import CoreServices
import Foundation
import os.log
import TOMLKit

// MARK: - Configuration Types

public struct Config: Codable {
    public let browsers: Browsers
    public let urls: OverrideUrls?
    public let workTime: WorkTime
    public let workDays: WorkDays
    public let log: Log?

    public struct Browsers: Codable {
        public let work: String
        public let personal: String
        
        public init(work: String, personal: String) {
            self.work = work
            self.personal = personal
        }
    }

    public struct OverrideUrls: Codable {
        public let personal: [String]?
        public let work: [String]?
        
        public init(personal: [String]?, work: [String]?) {
            self.personal = personal
            self.work = work
        }
    }

    public struct WorkTime: Codable {
        public let start: String
        public let end: String
        
        public init(start: String, end: String) {
            self.start = start
            self.end = end
        }
    }

    public struct WorkDays: Codable {
        public let start: String
        public let end: String
        
        public init(start: String, end: String) {
            self.start = start
            self.end = end
        }
    }

    public struct Log: Codable {
        public let hide_urls: Bool
        
        public init(hide_urls: Bool) {
            self.hide_urls = hide_urls
        }
    }

    enum CodingKeys: String, CodingKey {
        case browsers
        case urls
        case workTime = "work_time"
        case workDays = "work_days"
        case log
    }

    public init(
        browsers: Browsers = Browsers(work: "Google Chrome", personal: "Zen"),
        urls: OverrideUrls? = nil,
        workTime: WorkTime = WorkTime(start: "9:00", end: "18:00"),
        workDays: WorkDays = WorkDays(start: "Mon", end: "Fri"),
        log: Log? = nil
    ) {
        self.browsers = browsers
        self.urls = urls
        self.workTime = workTime
        self.workDays = workDays
        self.log = log
    }

    public static func loadFromFile() -> Config {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configPath = homeDir.appendingPathComponent(".config/browser-schedule/config.toml")
        let localConfigPath = homeDir.appendingPathComponent(
            ".config/browser-schedule/config.local.toml")

        // Load main config
        guard let configData = try? String(contentsOf: configPath) else {
            let defaults = Config()
            logger.debug("Config file not found at \(configPath.path), using defaults")
            return defaults
        }

        do {
            let tomlTable = try TOMLTable(string: configData)
            var config = try TOMLDecoder().decode(Config.self, from: tomlTable)

            // Try to load and merge local config
            if let localConfigData = try? String(contentsOf: localConfigPath) {
                do {
                    let localTomlTable = try TOMLTable(string: localConfigData)
                    let localConfig = try TOMLDecoder().decode(
                        LocalConfig.self, from: localTomlTable
                    )
                    config = mergeConfigs(base: config, local: localConfig)
                    logger.debug("Loaded config from \(configPath.path) and merged \(localConfigPath.path)")
                } catch {
                    logger.error("Error parsing local config file at \(localConfigPath.path): \(error.localizedDescription)")
                }
            } else {
                logger.debug("Loaded config from \(configPath.path)")
            }

            return config
        } catch {
            let defaults = Config()
            logger.error("Error parsing config file at \(configPath.path): \(error.localizedDescription), using defaults")
            return defaults
        }
    }

    public static func mergeConfigs(base: Config, local: LocalConfig) -> Config {
        // Merge override domains
        var mergedPersonalDomains: [String] = []
        var mergedWorkDomains: [String] = []

        // Add base config domains
        if let baseOverrides = base.urls {
            if let personal = baseOverrides.personal {
                mergedPersonalDomains.append(contentsOf: personal)
            }
            if let work = baseOverrides.work {
                mergedWorkDomains.append(contentsOf: work)
            }
        }

        // Add local config domains
        if let localOverrides = local.urls {
            if let personal = localOverrides.personal {
                mergedPersonalDomains.append(contentsOf: personal)
            }
            if let work = localOverrides.work {
                mergedWorkDomains.append(contentsOf: work)
            }
        }

        let mergedOverrides = OverrideUrls(
            personal: mergedPersonalDomains.isEmpty ? nil : mergedPersonalDomains,
            work: mergedWorkDomains.isEmpty ? nil : mergedWorkDomains
        )

        return Config(
            browsers: local.browsers ?? base.browsers,
            urls: mergedOverrides,
            workTime: local.workTime ?? base.workTime,
            workDays: local.workDays ?? base.workDays,
            log: local.log ?? base.log
        )
    }
}

public struct LocalConfig: Codable {
    public let browsers: Config.Browsers?
    public let urls: Config.OverrideUrls?
    public let workTime: Config.WorkTime?
    public let workDays: Config.WorkDays?
    public let log: Config.Log?

    enum CodingKeys: String, CodingKey {
        case browsers
        case urls
        case workTime = "work_time"
        case workDays = "work_days"
        case log
    }
}

// MARK: - Logging

public let logger = Logger(subsystem: "com.radiosilence.browser-schedule", category: "main")

public func shouldHideUrls(_ config: Config) -> Bool {
    return config.log?.hide_urls ?? false
}

public func logSafeURL(_ url: String, config: Config) -> String {
    return shouldHideUrls(config) ? "***" : url
}

// MARK: - Time and Day Parsing

public func parseTime(_ timeString: String) -> Int? {
    let components = timeString.split(separator: ":").map { String($0) }
    guard components.count == 2, let hour = Int(components[0]), hour >= 0, hour <= 23,
          let minute = Int(components[1]), minute >= 0, minute <= 59
    else {
        return nil
    }
    return hour
}

public func dayNameToWeekday(_ dayName: String) -> Int? {
    let days = ["Sun": 1, "Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6, "Sat": 7]
    return days[dayName]
}

// MARK: - Configuration Validation

public struct ConfigValidation {
    public let isValid: Bool
    public let errors: [String]

    public static func validate(_ config: Config) -> ConfigValidation {
        var errors: [String] = []

        // Validate work time
        if parseTime(config.workTime.start) == nil {
            errors.append("Invalid work start time: \(config.workTime.start) (use HH:MM format)")
        }
        if parseTime(config.workTime.end) == nil {
            errors.append("Invalid work end time: \(config.workTime.end) (use HH:MM format)")
        }

        // Validate work days
        if dayNameToWeekday(config.workDays.start) == nil {
            errors.append(
                "Invalid work start day: \(config.workDays.start) (use Sun,Mon,Tue,Wed,Thu,Fri,Sat)"
            )
        }
        if dayNameToWeekday(config.workDays.end) == nil {
            errors.append(
                "Invalid work end day: \(config.workDays.end) (use Sun,Mon,Tue,Wed,Thu,Fri,Sat)")
        }

        // Validate day range makes sense
        if let startDay = dayNameToWeekday(config.workDays.start),
           let endDay = dayNameToWeekday(config.workDays.end),
           startDay > endDay
        {
            errors.append(
                "Work day range invalid: \(config.workDays.start) is after \(config.workDays.end)")
        }

        return ConfigValidation(isValid: errors.isEmpty, errors: errors)
    }
}

// MARK: - Work Time Logic

public func isWorkTime(config: Config, currentDate: Date = Date()) -> Bool {
    let validation = ConfigValidation.validate(config)
    if !validation.isValid {
        return false
    }

    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: currentDate)
    let weekday = calendar.component(.weekday, from: currentDate) // 1=Sunday, 2=Monday, etc.

    let startHour = parseTime(config.workTime.start)!
    let endHour = parseTime(config.workTime.end)!
    let startWeekday = dayNameToWeekday(config.workDays.start)!
    let endWeekday = dayNameToWeekday(config.workDays.end)!

    let isWorkDay = weekday >= startWeekday && weekday <= endWeekday

    let isWorkHour: Bool
    if startHour < endHour {
        isWorkHour = hour >= startHour && hour < endHour
    } else {
        isWorkHour = hour >= startHour || hour < endHour
    }

    let shiftType = startHour < endHour ? "day" : "night"
    logger.debug("\(shiftType) shift check: weekday=\(weekday), workDays=\(config.workDays.start)-\(config.workDays.end), hour=\(hour), workHours=\(config.workTime.start)-\(config.workTime.end), isWorkDay=\(isWorkDay), isWorkHour=\(isWorkHour)")

    return isWorkDay && isWorkHour
}

// MARK: - Browser Selection Logic

public func getBrowserForURL(_ urlString: String, config: Config, currentDate: Date = Date()) -> String {
    guard URL(string: urlString) != nil else {
        return isWorkTime(config: config, currentDate: currentDate) ? config.browsers.work : config.browsers.personal
    }

    // Check URL fragment overrides
    if let overrides = config.urls {
        // Check personal overrides first
        if let personalFragments = overrides.personal {
            for fragment in personalFragments {
                if urlString.contains(fragment) {
                    return config.browsers.personal
                }
            }
        }

        // Check work overrides
        if let workFragments = overrides.work {
            for fragment in workFragments {
                if urlString.contains(fragment) {
                    return config.browsers.work
                }
            }
        }
    }

    return isWorkTime(config: config, currentDate: currentDate) ? config.browsers.work : config.browsers.personal
}

// MARK: - URL Opening

public func openURL(_ urlString: String, config: Config, currentDate: Date = Date()) {
    let targetBrowser = getBrowserForURL(urlString, config: config, currentDate: currentDate)
    let timeString = DateFormatter()
    timeString.dateFormat = "HH:mm"
    let safeURL = logSafeURL(urlString, config: config)

    logger.info("Opening \(safeURL) in \(targetBrowser) (\(timeString.string(from: currentDate)))")

    let task = Process()
    task.launchPath = "/usr/bin/open"
    task.arguments = ["-a", targetBrowser, urlString]

    do {
        try task.run()
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            logger.debug("Successfully opened \(safeURL) in \(targetBrowser)")
        } else {
            logger.error("Error opening \(safeURL): exit code \(task.terminationStatus)")
        }
    } catch {
        logger.error("Error opening \(safeURL): \(error)")
    }
}