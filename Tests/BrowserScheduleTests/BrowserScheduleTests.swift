import XCTest
import Foundation
@testable import BrowserScheduleCore

final class BrowserScheduleTests: XCTestCase {
    
    // MARK: - Time Parsing Tests
    
    func testParseValidTime() {
        XCTAssertEqual(parseTime("09:00"), 9)
        XCTAssertEqual(parseTime("18:30"), 18)
        XCTAssertEqual(parseTime("00:00"), 0)
        XCTAssertEqual(parseTime("23:59"), 23)
    }
    
    func testParseInvalidTime() {
        // Note: parseTime actually accepts single digit hours (returns hour component)
        XCTAssertEqual(parseTime("9:00"), 9) // Single digit hour is valid
        XCTAssertNil(parseTime("09:60")) // Invalid minute
        XCTAssertNil(parseTime("24:00")) // Invalid hour
        XCTAssertNil(parseTime("09")) // Missing colon
        XCTAssertNil(parseTime("invalid"))
        XCTAssertNil(parseTime(""))
    }
    
    // MARK: - Day Name Tests
    
    func testDayNameToWeekday() {
        XCTAssertEqual(dayNameToWeekday("Sun"), 1)
        XCTAssertEqual(dayNameToWeekday("Mon"), 2)
        XCTAssertEqual(dayNameToWeekday("Tue"), 3)
        XCTAssertEqual(dayNameToWeekday("Wed"), 4)
        XCTAssertEqual(dayNameToWeekday("Thu"), 5)
        XCTAssertEqual(dayNameToWeekday("Fri"), 6)
        XCTAssertEqual(dayNameToWeekday("Sat"), 7)
    }
    
    func testInvalidDayName() {
        XCTAssertNil(dayNameToWeekday("Monday"))
        XCTAssertNil(dayNameToWeekday("sun"))
        XCTAssertNil(dayNameToWeekday("invalid"))
        XCTAssertNil(dayNameToWeekday(""))
    }
    
    // MARK: - Configuration Validation Tests
    
    func testValidConfiguration() {
        let config = Config(
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        let validation = ConfigValidation.validate(config)
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
    }
    
    func testInvalidTimeConfiguration() {
        let config = Config(
            workTime: Config.WorkTime(start: "invalid", end: "25:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        let validation = ConfigValidation.validate(config)
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.errors.count, 2)
        XCTAssertTrue(validation.errors.contains { $0.contains("Invalid work start time") })
        XCTAssertTrue(validation.errors.contains { $0.contains("Invalid work end time") })
    }
    
    func testInvalidDayConfiguration() {
        let config = Config(
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Monday", end: "Friday")
        )
        let validation = ConfigValidation.validate(config)
        XCTAssertFalse(validation.isValid)
        XCTAssertEqual(validation.errors.count, 2)
        XCTAssertTrue(validation.errors.contains { $0.contains("Invalid work start day") })
        XCTAssertTrue(validation.errors.contains { $0.contains("Invalid work end day") })
    }
    
    func testInvalidDayRange() {
        let config = Config(
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Fri", end: "Mon")
        )
        let validation = ConfigValidation.validate(config)
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.contains("Work day range invalid") })
    }
    
    // MARK: - Work Time Detection Tests
    
    func testIsWorkTimeDayShift() {
        let config = Config(
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test Monday 10:00 (work time)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8  // Monday
        components.hour = 10
        components.minute = 0
        let mondayWorkTime = Calendar.current.date(from: components)!
        XCTAssertTrue(isWorkTime(config: config, currentDate: mondayWorkTime))
        
        // Test Monday 8:00 (before work)
        components.hour = 8
        let mondayBeforeWork = Calendar.current.date(from: components)!
        XCTAssertFalse(isWorkTime(config: config, currentDate: mondayBeforeWork))
        
        // Test Monday 19:00 (after work)
        components.hour = 19
        let mondayAfterWork = Calendar.current.date(from: components)!
        XCTAssertFalse(isWorkTime(config: config, currentDate: mondayAfterWork))
        
        // Test Saturday 10:00 (weekend)
        components.day = 13  // Saturday
        components.hour = 10
        let saturdayWorkTime = Calendar.current.date(from: components)!
        XCTAssertFalse(isWorkTime(config: config, currentDate: saturdayWorkTime))
    }
    
    func testIsWorkTimeNightShift() {
        let config = Config(
            workTime: Config.WorkTime(start: "18:00", end: "09:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test Monday 20:00 (work time)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8  // Monday
        components.hour = 20
        components.minute = 0
        let mondayNightWork = Calendar.current.date(from: components)!
        XCTAssertTrue(isWorkTime(config: config, currentDate: mondayNightWork))
        
        // Test Tuesday 8:00 (still work time, before 9:00)
        components.day = 9  // Tuesday
        components.hour = 8
        let tuesdayEarlyWork = Calendar.current.date(from: components)!
        XCTAssertTrue(isWorkTime(config: config, currentDate: tuesdayEarlyWork))
        
        // Test Monday 12:00 (not work time)
        components.day = 8  // Monday
        components.hour = 12
        let mondayMidday = Calendar.current.date(from: components)!
        XCTAssertFalse(isWorkTime(config: config, currentDate: mondayMidday))
    }
    
    func testIsWorkTimeInvalidConfig() {
        let config = Config(
            workTime: Config.WorkTime(start: "invalid", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        let date = Date()
        XCTAssertFalse(isWorkTime(config: config, currentDate: date))
    }
    
    // MARK: - Browser Selection Tests
    
    func testGetBrowserForURLWorkTime() {
        let config = Config(
            browsers: Config.Browsers(work: "Chrome", personal: "Zen"),
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test during work hours
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8  // Monday
        components.hour = 10
        let workTime = Calendar.current.date(from: components)!
        
        XCTAssertEqual(getBrowserForURL("https://example.com", config: config, currentDate: workTime), "Chrome")
    }
    
    func testGetBrowserForURLPersonalTime() {
        let config = Config(
            browsers: Config.Browsers(work: "Chrome", personal: "Zen"),
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test during personal hours
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 13  // Saturday
        components.hour = 10
        let personalTime = Calendar.current.date(from: components)!
        
        XCTAssertEqual(getBrowserForURL("https://example.com", config: config, currentDate: personalTime), "Zen")
    }
    
    func testGetBrowserForURLPersonalOverride() {
        let config = Config(
            browsers: Config.Browsers(work: "Chrome", personal: "Zen"),
            urls: Config.OverrideUrls(personal: ["reddit.com"], work: nil),
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test during work hours but personal override
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8  // Monday
        components.hour = 10
        let workTime = Calendar.current.date(from: components)!
        
        XCTAssertEqual(getBrowserForURL("https://reddit.com/r/programming", config: config, currentDate: workTime), "Zen")
    }
    
    func testGetBrowserForURLWorkOverride() {
        let config = Config(
            browsers: Config.Browsers(work: "Chrome", personal: "Zen"),
            urls: Config.OverrideUrls(personal: nil, work: ["mycompany.com"]),
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test during personal hours but work override
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 13  // Saturday
        components.hour = 10
        let personalTime = Calendar.current.date(from: components)!
        
        XCTAssertEqual(getBrowserForURL("https://mycompany.com/dashboard", config: config, currentDate: personalTime), "Chrome")
    }
    
    func testGetBrowserForURLInvalidURL() {
        let config = Config(
            browsers: Config.Browsers(work: "Chrome", personal: "Zen"),
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test during work hours with invalid URL (should fall back to time-based)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8  // Monday
        components.hour = 10
        let workTime = Calendar.current.date(from: components)!
        
        XCTAssertEqual(getBrowserForURL("invalid-url", config: config, currentDate: workTime), "Chrome")
    }
    
    // MARK: - Config Merging Tests
    
    func testConfigMerging() {
        let baseConfig = Config(
            browsers: Config.Browsers(work: "Chrome", personal: "Zen"),
            urls: Config.OverrideUrls(personal: ["reddit.com"], work: ["work1.com"]),
            workTime: Config.WorkTime(start: "09:00", end: "18:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri"),
            log: Config.Log(hide_urls: false)
        )
        
        let localConfig = LocalConfig(
            browsers: Config.Browsers(work: "Firefox", personal: "Safari"),
            urls: Config.OverrideUrls(personal: ["personal.com"], work: ["work2.com"]),
            workTime: Config.WorkTime(start: "10:00", end: "19:00"),
            workDays: nil,
            log: Config.Log(hide_urls: true)
        )
        
        let merged = Config.mergeConfigs(base: baseConfig, local: localConfig)
        
        // Browsers should be overridden
        XCTAssertEqual(merged.browsers.work, "Firefox")
        XCTAssertEqual(merged.browsers.personal, "Safari")
        
        // URLs should be merged
        XCTAssertEqual(merged.urls?.personal?.count, 2)
        XCTAssertTrue(merged.urls?.personal?.contains("reddit.com") ?? false)
        XCTAssertTrue(merged.urls?.personal?.contains("personal.com") ?? false)
        XCTAssertEqual(merged.urls?.work?.count, 2)
        XCTAssertTrue(merged.urls?.work?.contains("work1.com") ?? false)
        XCTAssertTrue(merged.urls?.work?.contains("work2.com") ?? false)
        
        // Work time should be overridden
        XCTAssertEqual(merged.workTime.start, "10:00")
        XCTAssertEqual(merged.workTime.end, "19:00")
        
        // Work days should use base (local was nil)
        XCTAssertEqual(merged.workDays.start, "Mon")
        XCTAssertEqual(merged.workDays.end, "Fri")
        
        // Logging should be overridden
        XCTAssertTrue(merged.log?.hide_urls ?? false)
    }
    
    func testConfigMergingEmptyURLs() {
        let baseConfig = Config(
            urls: Config.OverrideUrls(personal: [], work: [])
        )
        
        let localConfig = LocalConfig(
            browsers: nil,
            urls: Config.OverrideUrls(personal: [], work: []),
            workTime: nil,
            workDays: nil,
            log: nil
        )
        
        let merged = Config.mergeConfigs(base: baseConfig, local: localConfig)
        
        // Empty arrays should result in nil
        XCTAssertNil(merged.urls?.personal)
        XCTAssertNil(merged.urls?.work)
    }
    
    // MARK: - Edge Cases
    
    func testMidnightEdgeCases() {
        let config = Config(
            workTime: Config.WorkTime(start: "0:00", end: "23:00"),
            workDays: Config.WorkDays(start: "Mon", end: "Fri")
        )
        
        // Test at exactly midnight on Monday
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 8  // Monday
        components.hour = 0
        components.minute = 0
        let midnight = Calendar.current.date(from: components)!
        
        XCTAssertTrue(isWorkTime(config: config, currentDate: midnight))
        
        // Test at 22:00 on Friday (before 23:00 end)
        components.day = 12  // Friday
        components.hour = 22
        components.minute = 59
        let lateEvening = Calendar.current.date(from: components)!
        
        XCTAssertTrue(isWorkTime(config: config, currentDate: lateEvening))
        
        // Test at 23:00 on Friday (exactly at end time, should be false)
        components.hour = 23
        components.minute = 0
        let endTime = Calendar.current.date(from: components)!
        
        XCTAssertFalse(isWorkTime(config: config, currentDate: endTime))
    }
    
    func testNightShiftSpanningWeekend() {
        let config = Config(
            workTime: Config.WorkTime(start: "22:00", end: "06:00"),
            workDays: Config.WorkDays(start: "Sun", end: "Thu")
        )
        
        // Test Thursday 23:00 (should be work time)
        var components = DateComponents()
        components.year = 2024
        components.month = 1
        components.day = 11  // Thursday
        components.hour = 23
        let thursdayNight = Calendar.current.date(from: components)!
        
        XCTAssertTrue(isWorkTime(config: config, currentDate: thursdayNight))
        
        // Test Friday 5:00 (should NOT be work time - Friday is not a work day)
        components.day = 12  // Friday
        components.hour = 5
        let fridayMorning = Calendar.current.date(from: components)!
        
        XCTAssertFalse(isWorkTime(config: config, currentDate: fridayMorning))
    }
}