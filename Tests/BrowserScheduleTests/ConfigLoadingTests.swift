import XCTest
import Foundation
import TOMLKit
@testable import BrowserScheduleCore

final class ConfigLoadingTests: XCTestCase {
    
    var tempConfigDir: URL!
    var originalHomeDir: URL!
    
    override func setUp() {
        super.setUp()
        
        // Create temporary directory for test configs
        tempConfigDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("browser-schedule-tests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: tempConfigDir, withIntermediateDirectories: true)
        
        // Store original home directory (we'll mock it in tests)
        originalHomeDir = FileManager.default.homeDirectoryForCurrentUser
    }
    
    override func tearDown() {
        super.tearDown()
        
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempConfigDir)
    }
    
    func testTOMLDecoding() throws {
        let tomlString = """
        [browsers]
        work = "Google Chrome"
        personal = "Zen"
        
        [urls]
        personal = ["reddit.com", "youtube.com"]
        work = ["mycompany.atlassian.net", "confluence.com"]
        
        [work_time]
        start = "09:00"
        end = "18:00"
        
        [work_days]
        start = "Mon"
        end = "Fri"
        
        [log]
        enabled = true
        """
        
        let tomlTable = try TOMLTable(string: tomlString)
        let config = try TOMLDecoder().decode(Config.self, from: tomlTable)
        
        XCTAssertEqual(config.browsers.work, "Google Chrome")
        XCTAssertEqual(config.browsers.personal, "Zen")
        XCTAssertEqual(config.urls?.personal, ["reddit.com", "youtube.com"])
        XCTAssertEqual(config.urls?.work, ["mycompany.atlassian.net", "confluence.com"])
        XCTAssertEqual(config.workTime.start, "09:00")
        XCTAssertEqual(config.workTime.end, "18:00")
        XCTAssertEqual(config.workDays.start, "Mon")
        XCTAssertEqual(config.workDays.end, "Fri")
        XCTAssertEqual(config.log?.enabled, true)
    }
    
    func testTOMLDecodingMinimal() throws {
        let tomlString = """
        [browsers]
        work = "Chrome"
        personal = "Safari"
        
        [work_time]
        start = "10:00"
        end = "19:00"
        
        [work_days]
        start = "Tue"
        end = "Sat"
        """
        
        let tomlTable = try TOMLTable(string: tomlString)
        let config = try TOMLDecoder().decode(Config.self, from: tomlTable)
        
        XCTAssertEqual(config.browsers.work, "Chrome")
        XCTAssertEqual(config.browsers.personal, "Safari")
        XCTAssertNil(config.urls)
        XCTAssertEqual(config.workTime.start, "10:00")
        XCTAssertEqual(config.workTime.end, "19:00")
        XCTAssertEqual(config.workDays.start, "Tue")
        XCTAssertEqual(config.workDays.end, "Sat")
        XCTAssertNil(config.log)
    }
    
    func testLocalConfigDecoding() throws {
        let tomlString = """
        [urls]
        personal = ["local.dev"]
        
        [log]
        enabled = false
        """
        
        let tomlTable = try TOMLTable(string: tomlString)
        let localConfig = try TOMLDecoder().decode(LocalConfig.self, from: tomlTable)
        
        XCTAssertNil(localConfig.browsers)
        XCTAssertEqual(localConfig.urls?.personal, ["local.dev"])
        XCTAssertNil(localConfig.urls?.work)
        XCTAssertNil(localConfig.workTime)
        XCTAssertNil(localConfig.workDays)
        XCTAssertEqual(localConfig.log?.enabled, false)
    }
    
    func testTOMLDecodingInvalidFormat() {
        let invalidToml = """
        [browsers
        work = "Chrome"
        """
        
        XCTAssertThrowsError(try TOMLTable(string: invalidToml))
    }
    
    func testTOMLDecodingMissingRequiredFields() {
        let tomlString = """
        [browsers]
        work = "Chrome"
        # Missing personal browser
        
        [work_time]
        start = "09:00"
        # Missing end time
        """
        
        let tomlTable = try! TOMLTable(string: tomlString)
        XCTAssertThrowsError(try TOMLDecoder().decode(Config.self, from: tomlTable))
    }
    
    func testDefaultConfigValues() {
        let config = Config()
        
        XCTAssertEqual(config.browsers.work, "Google Chrome")
        XCTAssertEqual(config.browsers.personal, "Zen")
        XCTAssertNil(config.urls)
        XCTAssertEqual(config.workTime.start, "9:00")
        XCTAssertEqual(config.workTime.end, "18:00")
        XCTAssertEqual(config.workDays.start, "Mon")
        XCTAssertEqual(config.workDays.end, "Fri")
        XCTAssertNil(config.log)
    }
    
    func testURLArrayMerging() {
        let baseConfig = Config(
            urls: Config.OverrideUrls(
                personal: ["base-personal1.com", "base-personal2.com"],
                work: ["base-work1.com"]
            )
        )
        
        let localConfig = LocalConfig(
            browsers: nil,
            urls: Config.OverrideUrls(
                personal: ["local-personal.com"],
                work: ["local-work1.com", "local-work2.com"]
            ),
            workTime: nil,
            workDays: nil,
            log: nil
        )
        
        let merged = Config.mergeConfigs(base: baseConfig, local: localConfig)
        
        // Check personal URLs are merged
        let personalUrls = merged.urls?.personal ?? []
        XCTAssertEqual(personalUrls.count, 3)
        XCTAssertTrue(personalUrls.contains("base-personal1.com"))
        XCTAssertTrue(personalUrls.contains("base-personal2.com"))
        XCTAssertTrue(personalUrls.contains("local-personal.com"))
        
        // Check work URLs are merged
        let workUrls = merged.urls?.work ?? []
        XCTAssertEqual(workUrls.count, 3)
        XCTAssertTrue(workUrls.contains("base-work1.com"))
        XCTAssertTrue(workUrls.contains("local-work1.com"))
        XCTAssertTrue(workUrls.contains("local-work2.com"))
    }
    
    func testPartialURLMerging() {
        let baseConfig = Config(
            urls: Config.OverrideUrls(personal: ["base.com"], work: nil)
        )
        
        let localConfig = LocalConfig(
            browsers: nil,
            urls: Config.OverrideUrls(personal: nil, work: ["local.com"]),
            workTime: nil,
            workDays: nil,
            log: nil
        )
        
        let merged = Config.mergeConfigs(base: baseConfig, local: localConfig)
        
        XCTAssertEqual(merged.urls?.personal, ["base.com"])
        XCTAssertEqual(merged.urls?.work, ["local.com"])
    }
    
    func testNilURLMerging() {
        let baseConfig = Config(urls: nil)
        let localConfig = LocalConfig(
            browsers: nil,
            urls: Config.OverrideUrls(personal: ["local.com"], work: nil),
            workTime: nil,
            workDays: nil,
            log: nil
        )
        
        let merged = Config.mergeConfigs(base: baseConfig, local: localConfig)
        
        XCTAssertEqual(merged.urls?.personal, ["local.com"])
        XCTAssertNil(merged.urls?.work)
    }
    
    func testComplexNightShiftConfig() throws {
        let tomlString = """
        [browsers]
        work = "Chrome"
        personal = "Safari"
        
        [work_time]
        start = "22:00"
        end = "06:00"
        
        [work_days]
        start = "Sun"
        end = "Thu"
        
        [urls]
        work = ["work.example.com", "jira.company.com"]
        personal = ["reddit.com", "youtube.com", "personal.blog"]
        
        [log]
        enabled = true
        """
        
        let tomlTable = try TOMLTable(string: tomlString)
        let config = try TOMLDecoder().decode(Config.self, from: tomlTable)
        
        let validation = ConfigValidation.validate(config)
        XCTAssertTrue(validation.isValid, "Night shift config should be valid")
        XCTAssertTrue(validation.errors.isEmpty)
        
        // Test that night shift detection works
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 7  // Sunday
        components.hour = 23  // 11 PM
        let sundayNight = Calendar.current.date(from: components)!
        
        XCTAssertTrue(isWorkTime(config: config, currentDate: sundayNight))
        
        // Test early Monday morning (still work time)
        components.day = 8  // Monday
        components.hour = 5   // 5 AM
        let mondayEarly = Calendar.current.date(from: components)!
        
        XCTAssertTrue(isWorkTime(config: config, currentDate: mondayEarly))
        
        // Test Monday afternoon (not work time)
        components.hour = 14  // 2 PM
        let mondayAfternoon = Calendar.current.date(from: components)!
        
        XCTAssertFalse(isWorkTime(config: config, currentDate: mondayAfternoon))
    }
}