import Foundation
import Observation
import TOMLKit

@MainActor
@Observable
public class ConfigManager {
    // MARK: - Editable config fields

    public var workBrowser: String
    public var personalBrowser: String
    public var workStartTime: String
    public var workEndTime: String
    public var workStartDay: String
    public var workEndDay: String
    public var personalUrls: [String]
    public var workUrls: [String]

    // MARK: - Local config overrides

    public var localWorkBrowser: String?
    public var localPersonalBrowser: String?
    public var localWorkStartTime: String?
    public var localWorkEndTime: String?
    public var localWorkStartDay: String?
    public var localWorkEndDay: String?
    public var localPersonalUrls: [String]?
    public var localWorkUrls: [String]?
    public var hasLocalConfig: Bool

    // MARK: - Raw TOML

    public var rawConfigTOML: String
    public var rawLocalConfigTOML: String

    // MARK: - Status

    public var validation: ConfigValidation
    public var isDefaultBrowserStatus: Bool
    public var lastError: String?

    // MARK: - Paths

    public static let configDir: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/browser-schedule")
    }()

    public static let configPath: URL = {
        configDir.appendingPathComponent("config.toml")
    }()

    public static let localConfigPath: URL = {
        configDir.appendingPathComponent("config.local.toml")
    }()

    // MARK: - Init

    public init() {
        // Set defaults before loading
        let defaults = Config()
        self.workBrowser = defaults.browsers.work
        self.personalBrowser = defaults.browsers.personal
        self.workStartTime = defaults.workTime.start
        self.workEndTime = defaults.workTime.end
        self.workStartDay = defaults.workDays.start
        self.workEndDay = defaults.workDays.end
        self.personalUrls = []
        self.workUrls = []
        self.localWorkBrowser = nil
        self.localPersonalBrowser = nil
        self.localWorkStartTime = nil
        self.localWorkEndTime = nil
        self.localWorkStartDay = nil
        self.localWorkEndDay = nil
        self.localPersonalUrls = nil
        self.localWorkUrls = nil
        self.hasLocalConfig = false
        self.rawConfigTOML = ""
        self.rawLocalConfigTOML = ""
        self.validation = ConfigValidation(isValid: true, errors: [])
        self.isDefaultBrowserStatus = false
        self.lastError = nil

        reload()
    }

    // MARK: - Load

    public func reload() {
        lastError = nil

        // Read raw TOML
        rawConfigTOML = (try? String(contentsOf: Self.configPath, encoding: .utf8)) ?? ""
        rawLocalConfigTOML = (try? String(contentsOf: Self.localConfigPath, encoding: .utf8)) ?? ""
        hasLocalConfig = FileManager.default.fileExists(atPath: Self.localConfigPath.path)

        // Parse main config
        let config: Config
        if rawConfigTOML.isEmpty {
            config = Config()
        } else {
            do {
                let table = try TOMLTable(string: rawConfigTOML)
                config = try TOMLDecoder().decode(Config.self, from: table)
            } catch {
                lastError = "Failed to parse config.toml: \(error.localizedDescription)"
                let fallback = Config()
                applyConfig(fallback)
                return
            }
        }

        applyConfig(config)

        // Parse local config
        if hasLocalConfig, !rawLocalConfigTOML.isEmpty {
            do {
                let table = try TOMLTable(string: rawLocalConfigTOML)
                let local = try TOMLDecoder().decode(LocalConfig.self, from: table)
                applyLocalConfig(local)
            } catch {
                lastError = "Failed to parse config.local.toml: \(error.localizedDescription)"
            }
        } else {
            clearLocalConfig()
        }

        validation = ConfigValidation.validate(mergedConfig)
        isDefaultBrowserStatus = isDefaultBrowser()
    }

    // MARK: - Save

    public func saveConfig() {
        do {
            try ensureConfigDir()
            let toml = buildConfigTOML()
            try toml.write(to: Self.configPath, atomically: true, encoding: .utf8)
            rawConfigTOML = toml
            validation = ConfigValidation.validate(mergedConfig)
            lastError = nil
        } catch {
            lastError = "Failed to save config.toml: \(error.localizedDescription)"
        }
    }

    public func saveLocalConfig() {
        do {
            try ensureConfigDir()
            let toml = buildLocalConfigTOML()
            try toml.write(to: Self.localConfigPath, atomically: true, encoding: .utf8)
            rawLocalConfigTOML = toml
            hasLocalConfig = true
            validation = ConfigValidation.validate(mergedConfig)
            lastError = nil
        } catch {
            lastError = "Failed to save config.local.toml: \(error.localizedDescription)"
        }
    }

    public func saveRawConfig() {
        do {
            try ensureConfigDir()
            rawConfigTOML = Self.sanitizeTOML(rawConfigTOML)
            try rawConfigTOML.write(to: Self.configPath, atomically: true, encoding: .utf8)
            lastError = nil
            reload()
        } catch {
            lastError = "Failed to save config.toml: \(error.localizedDescription)"
        }
    }

    public func saveRawLocalConfig() {
        do {
            try ensureConfigDir()
            rawLocalConfigTOML = Self.sanitizeTOML(rawLocalConfigTOML)
            try rawLocalConfigTOML.write(to: Self.localConfigPath, atomically: true, encoding: .utf8)
            lastError = nil
            reload()
        } catch {
            lastError = "Failed to save config.local.toml: \(error.localizedDescription)"
        }
    }

    /// Replace smart quotes/dashes that macOS text input may inject
    private static func sanitizeTOML(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2014}", with: "-")
    }

    public func deleteLocalConfig() {
        do {
            if FileManager.default.fileExists(atPath: Self.localConfigPath.path) {
                try FileManager.default.removeItem(at: Self.localConfigPath)
            }
            clearLocalConfig()
            hasLocalConfig = false
            rawLocalConfigTOML = ""
            validation = ConfigValidation.validate(mergedConfig)
            lastError = nil
        } catch {
            lastError = "Failed to delete config.local.toml: \(error.localizedDescription)"
        }
    }

    public func refreshDefaultBrowserStatus() {
        isDefaultBrowserStatus = isDefaultBrowser()
    }

    // MARK: - Build Config structs

    public func buildConfig() -> Config {
        Config(
            browsers: Config.Browsers(work: workBrowser, personal: personalBrowser),
            urls: (personalUrls.isEmpty && workUrls.isEmpty)
                ? nil
                : Config.OverrideUrls(
                    personal: personalUrls.isEmpty ? nil : personalUrls,
                    work: workUrls.isEmpty ? nil : workUrls
                ),
            workTime: Config.WorkTime(start: workStartTime, end: workEndTime),
            workDays: Config.WorkDays(start: workStartDay, end: workEndDay)
        )
    }

    public func buildLocalConfig() -> LocalConfig {
        LocalConfig(
            browsers: (localWorkBrowser != nil || localPersonalBrowser != nil)
                ? Config.Browsers(
                    work: localWorkBrowser ?? workBrowser,
                    personal: localPersonalBrowser ?? personalBrowser
                )
                : nil,
            urls: (localPersonalUrls != nil || localWorkUrls != nil)
                ? Config.OverrideUrls(
                    personal: localPersonalUrls,
                    work: localWorkUrls
                )
                : nil,
            workTime: (localWorkStartTime != nil || localWorkEndTime != nil)
                ? Config.WorkTime(
                    start: localWorkStartTime ?? workStartTime,
                    end: localWorkEndTime ?? workEndTime
                )
                : nil,
            workDays: (localWorkStartDay != nil || localWorkEndDay != nil)
                ? Config.WorkDays(
                    start: localWorkStartDay ?? workStartDay,
                    end: localWorkEndDay ?? workEndDay
                )
                : nil
        )
    }

    public var mergedConfig: Config {
        Config.mergeConfigs(base: buildConfig(), local: buildLocalConfig())
    }

    // MARK: - Private helpers

    private func applyConfig(_ config: Config) {
        workBrowser = config.browsers.work
        personalBrowser = config.browsers.personal
        workStartTime = config.workTime.start
        workEndTime = config.workTime.end
        workStartDay = config.workDays.start
        workEndDay = config.workDays.end
        personalUrls = config.urls?.personal ?? []
        workUrls = config.urls?.work ?? []
    }

    private func applyLocalConfig(_ local: LocalConfig) {
        localWorkBrowser = local.browsers?.work
        localPersonalBrowser = local.browsers?.personal
        localWorkStartTime = local.workTime?.start
        localWorkEndTime = local.workTime?.end
        localWorkStartDay = local.workDays?.start
        localWorkEndDay = local.workDays?.end
        localPersonalUrls = local.urls?.personal
        localWorkUrls = local.urls?.work
    }

    private func clearLocalConfig() {
        localWorkBrowser = nil
        localPersonalBrowser = nil
        localWorkStartTime = nil
        localWorkEndTime = nil
        localWorkStartDay = nil
        localWorkEndDay = nil
        localPersonalUrls = nil
        localWorkUrls = nil
    }

    private func ensureConfigDir() throws {
        try FileManager.default.createDirectory(
            at: Self.configDir, withIntermediateDirectories: true)
    }

    private func buildConfigTOML() -> String {
        let table = TOMLTable()

        let browsers = TOMLTable()
        browsers["work"] = workBrowser
        browsers["personal"] = personalBrowser
        table["browsers"] = browsers

        let wt = TOMLTable()
        wt["start"] = workStartTime
        wt["end"] = workEndTime
        table["work_time"] = wt

        let wd = TOMLTable()
        wd["start"] = workStartDay
        wd["end"] = workEndDay
        table["work_days"] = wd

        if !personalUrls.isEmpty || !workUrls.isEmpty {
            let urls = TOMLTable()
            if !personalUrls.isEmpty {
                urls["personal"] = TOMLArray(personalUrls)
            }
            if !workUrls.isEmpty {
                urls["work"] = TOMLArray(workUrls)
            }
            table["urls"] = urls
        }

        return table.convert()
    }

    private func buildLocalConfigTOML() -> String {
        let table = TOMLTable()

        if localWorkBrowser != nil || localPersonalBrowser != nil {
            let browsers = TOMLTable()
            if let wb = localWorkBrowser { browsers["work"] = wb }
            if let pb = localPersonalBrowser { browsers["personal"] = pb }
            table["browsers"] = browsers
        }

        if localWorkStartTime != nil || localWorkEndTime != nil {
            let wt = TOMLTable()
            if let s = localWorkStartTime { wt["start"] = s }
            if let e = localWorkEndTime { wt["end"] = e }
            table["work_time"] = wt
        }

        if localWorkStartDay != nil || localWorkEndDay != nil {
            let wd = TOMLTable()
            if let s = localWorkStartDay { wd["start"] = s }
            if let e = localWorkEndDay { wd["end"] = e }
            table["work_days"] = wd
        }

        if localPersonalUrls != nil || localWorkUrls != nil {
            let urls = TOMLTable()
            if let pu = localPersonalUrls {
                urls["personal"] = TOMLArray(pu)
            }
            if let wu = localWorkUrls {
                urls["work"] = TOMLArray(wu)
            }
            table["urls"] = urls
        }

        return table.convert()
    }
}
