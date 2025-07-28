import AppKit
import CoreServices
import Foundation
import TOMLKit
@preconcurrency import os.log

// MARK: - Constants

public let bundleIdentifier = "com.radiosilence.browser-schedule"

// MARK: - Configuration Types

public enum ConfigError: LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case mergeError(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Config file not found at \(path)"
        case .invalidFormat(let details):
            return "Invalid config format: \(details)"
        case .mergeError(let details):
            return "Error merging configs: \(details)"
        }
    }
}

public struct Config: Codable {
    public let browsers: Browsers
    public let urls: OverrideUrls?
    public let workTime: WorkTime
    public let workDays: WorkDays

    public struct Browsers: Codable {
        public let work: String
        public let personal: String

        public init(work: String = "Google Chrome", personal: String = "Zen") {
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

        public var startHour: Int? { parseTime(start) }
        public var endHour: Int? { parseTime(end) }
        public var isNightShift: Bool {
            guard let start = startHour, let end = endHour else { return false }
            return start >= end
        }

        public init(start: String = "9:00", end: String = "18:00") {
            self.start = start
            self.end = end
        }
    }

    public struct WorkDays: Codable {
        public let start: String
        public let end: String

        public var startWeekday: Int? { dayNameToWeekday(start) }
        public var endWeekday: Int? { dayNameToWeekday(end) }

        public init(start: String = "Mon", end: String = "Fri") {
            self.start = start
            self.end = end
        }
    }

    enum CodingKeys: String, CodingKey {
        case browsers
        case urls
        case workTime = "work_time"
        case workDays = "work_days"
    }

    public init(
        browsers: Browsers = Browsers(),
        urls: OverrideUrls? = nil,
        workTime: WorkTime = WorkTime(),
        workDays: WorkDays = WorkDays(),
    ) {
        self.browsers = browsers
        self.urls = urls
        self.workTime = workTime
        self.workDays = workDays
    }

    public static func loadFromFileWithResult() -> Result<Config, ConfigError> {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configPath = homeDir.appendingPathComponent(".config/browser-schedule/config.toml")
        let localConfigPath = homeDir.appendingPathComponent(
            ".config/browser-schedule/config.local.toml")

        // Load main config
        guard let configData = try? String(contentsOf: configPath) else {
            return .failure(.fileNotFound(configPath.path))
        }

        do {
            let tomlTable = try TOMLTable(string: configData)
            var config = try TOMLDecoder().decode(Config.self, from: tomlTable)

            // Try to load and merge local config
            if let localConfigData = try? String(contentsOf: localConfigPath) {
                do {
                    let localTomlTable = try TOMLTable(string: localConfigData)
                    let localConfig = try TOMLDecoder().decode(
                        LocalConfig.self, from: localTomlTable)
                    config = mergeConfigs(base: config, local: localConfig)
                    logger.debug(
                        "Loaded config from \(configPath.path) and merged \(localConfigPath.path)")
                } catch {
                    logger.error(
                        "Error parsing local config file at \(localConfigPath.path): \(error.localizedDescription)"
                    )
                    return .failure(
                        .invalidFormat("Local config error: \(error.localizedDescription)"))
                }
            } else {
                logger.debug("Loaded config from \(configPath.path)")
            }

            return .success(config)
        } catch {
            return .failure(.invalidFormat(error.localizedDescription))
        }
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
                    logger.debug(
                        "Loaded config from \(configPath.path) and merged \(localConfigPath.path)")
                } catch {
                    logger.error(
                        "Error parsing local config file at \(localConfigPath.path): \(error.localizedDescription)"
                    )
                }
            } else {
                logger.debug("Loaded config from \(configPath.path)")
            }

            return config
        } catch {
            let defaults = Config()
            logger.error(
                "Error parsing config file at \(configPath.path): \(error.localizedDescription), using defaults"
            )
            return defaults
        }
    }

    public static func mergeConfigs(base: Config, local: LocalConfig) -> Config {
        // Merge override domains using modern Swift collection operations
        let mergedPersonalDomains = [base.urls?.personal, local.urls?.personal]
            .compactMap { $0 }
            .flatMap { $0 }

        let mergedWorkDomains = [base.urls?.work, local.urls?.work]
            .compactMap { $0 }
            .flatMap { $0 }

        let mergedOverrides = OverrideUrls(
            personal: mergedPersonalDomains.isEmpty ? nil : mergedPersonalDomains,
            work: mergedWorkDomains.isEmpty ? nil : mergedWorkDomains
        )

        return Config(
            browsers: local.browsers ?? base.browsers,
            urls: mergedOverrides,
            workTime: local.workTime ?? base.workTime,
            workDays: local.workDays ?? base.workDays,
        )
    }
}

public struct LocalConfig: Codable {
    public let browsers: Config.Browsers?
    public let urls: Config.OverrideUrls?
    public let workTime: Config.WorkTime?
    public let workDays: Config.WorkDays?

    enum CodingKeys: String, CodingKey {
        case browsers
        case urls
        case workTime = "work_time"
        case workDays = "work_days"
    }
}

// MARK: - Logging

public let logger = Logger(subsystem: bundleIdentifier, category: "main")

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

private let dayNameToWeekdayMap: [String: Int] = [
    "Sun": 1, "Mon": 2, "Tue": 3, "Wed": 4, "Thu": 5, "Fri": 6, "Sat": 7,
]

public func dayNameToWeekday(_ dayName: String) -> Int? {
    dayNameToWeekdayMap[dayName]
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
    guard validation.isValid,
        let startHour = config.workTime.startHour,
        let endHour = config.workTime.endHour,
        let startWeekday = config.workDays.startWeekday,
        let endWeekday = config.workDays.endWeekday
    else {
        return false
    }

    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: currentDate)
    let weekday = calendar.component(.weekday, from: currentDate)  // 1=Sunday, 2=Monday, etc.

    let isWorkDay = weekday >= startWeekday && weekday <= endWeekday
    let isWorkHour =
        config.workTime.isNightShift
        ? (hour >= startHour || hour < endHour) : (hour >= startHour && hour < endHour)

    let shiftType = config.workTime.isNightShift ? "night" : "day"
    logger.debug(
        "\(shiftType) shift check: weekday=\(weekday), workDays=\(config.workDays.start)-\(config.workDays.end), hour=\(hour), workHours=\(config.workTime.start)-\(config.workTime.end), isWorkDay=\(isWorkDay), isWorkHour=\(isWorkHour)"
    )

    return isWorkDay && isWorkHour
}

// MARK: - Browser Selection Logic

public func getBrowserForURL(_ urlString: String, config: Config, currentDate: Date = Date())
    -> String
{
    guard URL(string: urlString) != nil else {
        return isWorkTime(config: config, currentDate: currentDate)
            ? config.browsers.work : config.browsers.personal
    }

    // Check URL fragment overrides using modern Swift patterns
    if let overrides = config.urls {
        // Check personal overrides first
        if let personalFragments = overrides.personal,
            personalFragments.contains(where: urlString.contains)
        {
            return config.browsers.personal
        }

        // Check work overrides
        if let workFragments = overrides.work,
            workFragments.contains(where: urlString.contains)
        {
            return config.browsers.work
        }
    }

    return isWorkTime(config: config, currentDate: currentDate)
        ? config.browsers.work : config.browsers.personal
}

// MARK: - URL Opening

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

public func openURL(_ urlString: String, config: Config, currentDate: Date = Date()) {
    let targetBrowser = getBrowserForURL(urlString, config: config, currentDate: currentDate)
    let timeString = timeFormatter.string(from: currentDate)
    logger.info("Opening \(urlString) in \(targetBrowser) (\(timeString))")

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    task.arguments = ["-a", targetBrowser, urlString]

    do {
        try task.run()
        task.waitUntilExit()
        if task.terminationStatus == 0 {
            logger.debug("Successfully opened \(urlString) in \(targetBrowser)")
        } else {
            logger.error("Error opening \(urlString): exit code \(task.terminationStatus)")
        }
    } catch {
        logger.error("Error opening \(urlString): \(error)")
    }
}

// MARK: - Browser Setup & Registration

public func isDefaultBrowser() -> Bool {
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

public enum SetupError: LocalizedError {
    case registrationFailed(String)
    case setDefaultFailed(OSStatus, OSStatus)
    
    public var errorDescription: String? {
        switch self {
        case .registrationFailed(let error):
            return "Failed to register app bundle: \(error)"
        case .setDefaultFailed(let httpStatus, let httpsStatus):
            return "Failed to set as default browser (HTTP: \(httpStatus), HTTPS: \(httpsStatus))"
        }
    }
}

public func registerAppBundle() throws {
    let registerTask = Process()
    registerTask.executableURL = URL(
        fileURLWithPath: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    )
    registerTask.arguments = ["-f", "/Applications/BrowserSchedule.app"]

    do {
        try registerTask.run()
        registerTask.waitUntilExit()
        if registerTask.terminationStatus != 0 {
            throw SetupError.registrationFailed("lsregister exit code: \(registerTask.terminationStatus)")
        }
        logger.debug("Registered app bundle with Launch Services")
    } catch {
        logger.error("Could not register app bundle: \(error)")
        throw SetupError.registrationFailed(error.localizedDescription)
    }
}

public func setAsDefaultBrowser() throws {
    let httpStatus = LSSetDefaultHandlerForURLScheme("http" as CFString, bundleIdentifier as CFString)
    let httpsStatus = LSSetDefaultHandlerForURLScheme("https" as CFString, bundleIdentifier as CFString)

    if httpStatus != noErr || httpsStatus != noErr {
        throw SetupError.setDefaultFailed(httpStatus, httpsStatus)
    }
    
    logger.debug("Successfully set as default browser")
}
