# Changelog

## v1.3.1

### Changed

- **Cask uses pinned version with SHA256** — replaced `:latest`/`:no_check` with explicit version and hash for integrity verification.
- **Release CI auto-updates cask** — workflow now computes DMG hash post-build and commits updated cask back to `main`.

## v1.3.0

### Changed

- **Responsive layout** — UI scales with window size. Schedule grid grows vertically, all sections fill the window width.
- **GroupBox sections** — replaced `Form` + `.formStyle(.grouped)` (which caps width at ~600px on macOS) with `GroupBox`-based sections that stretch naturally. Custom `SettingsRowStyle` ensures label-left/content-right alignment with proper internal padding.
- **Single-pane config editor** — Config Files tab shows one editor at a time based on the centralized scope picker, removing the redundant split view. Single "Save" button replaces separate "Save Main"/"Save Local".
- **Week schedule grid** — replaced the single-day timeline bar with a 7-column weekly grid showing work hours per day, with dimmed non-work days and a red current-time marker on today's column.

## v1.2.2

### Fixed

- **Wrapping day ranges** — Mon-Sun, Fri-Tue etc now work correctly. `isWorkTime()` was using simple `>=`/`<=` comparison which fails when start weekday > end weekday in Apple's Calendar convention (Sun=1). Uses the same `||` pattern as night shift hours.

### Added

- **Wrapping day range tests** — `testWrappingDayRangeWorkTime` (Mon-Sun = every day) and `testWrappingDayRangeFriToTue` (Fri-Tue covers 5 days, excludes Wed/Thu).

## v1.2.1

### Fixed

- **Bogus day range validation removed** — "Work day range invalid: X is after Y" error was wrong — Apple Calendar uses Sun=1 convention so Mon(2) > Sun(1) tripped validation. Wrapping day ranges are valid use cases.

### Changed

- **Smaller app icon globe** — radius reduced from 0.32 to 0.27 for better visual balance with surrounding elements.

## v1.2.0

### Fixed

- **Minute-precision scheduling** — `parseTime()` was silently dropping minutes, so "9:30" routed as "9:00". Now returns total minutes (`hour * 60 + minute`) and `isWorkTime()` compares at minute granularity.

### Added

- **Form-based layout** — all settings tabs use `Form { Section { LabeledContent } }.formStyle(.grouped)` for native macOS settings appearance.
- **Centralized scope picker** — single `config.toml` / `config.local.toml` toggle above the tab bar instead of duplicated per-tab.
- **Browser icons** — picker shows 16×16 app icons via `NSWorkspace.shared.icon(forFile:)`, menu-based for proper image rendering.
- **DatePicker time input** — stepper fields replace raw text input for work hours, preventing invalid time formats.
- **24-hour timeline bar** — visual schedule overview with work/personal segments, red current-time marker, hour labels; night shift renders as two edge segments.
- **Routing status on General tab** — shows which browser is currently active and why.
- **Monokai Pro Filter Machine theme** — TOML editor dark theme with syntax colors (pink keys, yellow strings, cyan sections, orange booleans, purple numbers).
- **Delete confirmation** — "Delete Local Config" requires confirmation dialog, moved to left side of footer.
- **Better URL rules UX** — `"e.g. github.com"` placeholder, `"No patterns — URLs follow the schedule"` empty state, duplicate detection on add.

### Changed

- Default window height increased to fit all Schedule tab content.
- `BrowserInfo` now carries `NSImage` icon (dropped `Sendable` conformance).
- "Set as Default" button hidden when already the default browser.

## v1.1.1

### Changed

- **Cyberpunk neon app icon** — replaced the blue-teal clock/globe icon with a cyberpunk-themed design using neon cyan and magenta wireframe glow effects on a dark void background.

## v1.1.0

### Added

- **Homebrew Cask distribution** — `brew install --cask radiosilence/browser-schedule/browser-schedule`, auto-strips quarantine on install.
- **Ad-hoc code signing** — app bundle signed with `codesign -s - --deep --force` during build, enabling right-click → Open without `xattr` workarounds.

### Changed

- **Cask uses `version :latest`** — always pulls latest release instead of pinning a specific version.

## v1.0.0

### Added

- **Full SwiftUI settings UI** — replaces the old "set default browser" alert with a proper tabbed settings window:
  - **General tab**: browser pickers with auto-discovery of installed browsers, default browser status and registration button
  - **Schedule tab**: work hours and days editor with night shift detection and live status indicator
  - **URL Rules tab**: add/remove URL pattern overrides for work and personal browsers with auto-save
  - **Config Files tab**: side-by-side raw TOML editor for `config.toml` and `config.local.toml` with syntax highlighting
- **ConfigManager** — `@Observable` class providing SwiftUI data binding for all config fields, with auto-save on structured changes and manual save for raw TOML editing.
- **Browser enumeration** — discovers installed browsers via `NSWorkspace.urlsForApplications(toOpen:)` for picker dropdowns.
- **"Other..." button in browser picker** — allows selecting a custom app via file dialog if it's not in the auto-detected list.
- **App icon** — clock face with work/personal time arcs and globe badge, generated via Core Graphics script (`Scripts/generate-icon.swift`).
- **Standard menu bar** — Cmd+Q, Cmd+C/V/X, undo/redo support since bare NSApplication has none.
- **Pinned footer bar** — action buttons (Save, Reload, Delete) pinned at bottom of each tab.

### Changed

- **Dual execution mode** — direct launch shows SwiftUI settings window; URL invocation handles silently in background and exits.
- **`setAsDefaultBrowser()` no longer throws** — macOS prompts the user for confirmation asynchronously; app polls for status.

## v0.5.0

### Added

- **Two-binary architecture** — separate `BrowserSchedule` (GUI/URL handler) and `BrowserScheduleCLI` (command-line management) executables sharing `BrowserScheduleCore`.
- **Shared setup helpers** — `registerAppBundle()`, `setAsDefaultBrowser()`, `isDefaultBrowser()` moved to `BrowserScheduleCore` for reuse across both binaries.
- **CLI `open` subcommand** — route a URL through BrowserSchedule rules from the command line.

### Changed

- **ArgumentParser removed from GUI binary** — CLI concerns fully separated into `BrowserScheduleCLI`.

## v0.4.0

### Changed

- **Taskfile cleanup** — removed unnecessary build tasks, simplified task definitions.

## v0.3.0

### Added

- **ArgumentParser CLI** — replaced raw `CommandLine.arguments` parsing with Swift ArgumentParser, providing proper subcommands (`config`, `set-default`, `run`) with help text and validation.
- **Shell completions** — zsh/bash/fish completion generation via ArgumentParser.

## v0.2.0

### Changed

- **Swift 6 concurrency safety** — `@preconcurrency import AppKit`, `@MainActor` annotations, `@Sendable` where needed to eliminate strict concurrency warnings.
- **Minimum macOS version bumped to 14** (Sonoma).

## v0.1.1

### Fixed

- **Deprecated API replacement** — replaced `LSCopyDefaultHandlerForURLScheme` (deprecated macOS 12) with `NSWorkspace.urlForApplication(toOpen:)` for default browser detection.

## v0.1.0 / v0.0.6

Tag-only version bumps, no code changes from v0.0.5.

## v0.0.5

### Changed

- **Removed `[log]` config section** — logging is always enabled via macOS unified logging; removed the unnecessary config toggle.

## v0.0.4

### Changed

- **Removed unnecessary dependencies** — cleaned up Package.swift.

## v0.0.3

### Changed

- **Updated release workflow** — fixes to GitHub Actions release configuration.

## v0.0.2

### Fixed

- **Release task version parsing** — fixed version extraction and validation in the Taskfile release task.

## v0.0.1

### Added

- **Initial release** — macOS app that automatically switches default browser based on time, day, and URL patterns.
- **TOML configuration** — `config.toml` at `~/.config/browser-schedule/` with browser names, work hours, work days, and URL pattern overrides.
- **Local config overrides** — `config.local.toml` merges with main config (URL arrays merged, not replaced).
- **URL routing** — three-tier decision: URL fragment overrides → time/day schedule → personal browser fallback.
- **Night shift support** — work hours can span midnight (e.g., 18:00–9:00).
- **Config validation** — validates time formats (HH:MM), day names (Mon-Sun), with graceful fallback to personal browser on invalid config.
- **Unified logging** — macOS Console via `os.log` with centralized subsystem identifier.
- **Comprehensive test suite** — 30+ unit tests covering config loading, merging, validation, URL routing, time logic, and edge cases.
- **Swift Package Manager** — `BrowserScheduleCore` (testable logic) and `BrowserSchedule` (executable) targets.
- **CI/CD** — GitHub Actions workflow for building and testing.
- **Homebrew tap** — initial Cask definition for distribution.
- **Taskfile** — `task install`, `task update`, `task uninstall`, `task config`, `task logs`, `task status` commands.
