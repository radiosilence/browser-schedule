# Changelog

## v1.2.2

### Fixed

- **Wrapping day ranges** — Mon-Sun, Fri-Tue etc now work correctly. `isWorkTime()` was using simple `>=`/`<=` comparison which fails when start weekday > end weekday in Apple's Calendar convention (Sun=1). Uses the same `||` pattern as night shift hours.

## v1.2.1

### Fixed

- **Day range validation** — removed bogus "Mon is after Sun" error caused by Apple Calendar's Sun=1 convention. Wrapping day ranges are valid use cases.

### Changed

- Smaller app icon globe (0.32 → 0.27 radius) for better visual balance

## v1.2.0

### Fixed

- **Minute-precision scheduling** — `parseTime()` was silently dropping minutes, so "9:30" routed as "9:00". Now returns total minutes and `isWorkTime()` compares at minute granularity.

### Added

- **Form-based layout** — all settings tabs use `Form { Section { LabeledContent } }.formStyle(.grouped)` for native macOS settings appearance
- **Centralized scope picker** — single `config.toml` / `config.local.toml` toggle above the tab bar instead of duplicated per-tab
- **Browser icons** — picker shows 16x16 app icons via `NSWorkspace.shared.icon(forFile:)`, menu-based for proper image rendering
- **DatePicker time input** — stepper fields replace raw text input for work hours
- **24-hour timeline bar** — visual schedule overview with work/personal segments, red current-time marker, hour labels; night shift renders as two edge segments
- **Routing status on General tab** — shows which browser is currently active and why
- **Monokai Pro Filter Machine theme** — TOML editor now has a dark theme with proper syntax colors (pink keys, yellow strings, cyan sections, orange booleans, purple numbers)
- **Delete confirmation** — "Delete Local Config" requires confirmation dialog, moved to left side of footer
- **Better URL rules UX** — `"e.g. github.com"` placeholder, `"No patterns — URLs follow the schedule"` empty state, duplicate detection on add
- **Minute-precision test** — new `testMinutePrecisionWorkTime` covering exact 9:30/17:45 boundaries

### Changed

- Default window height increased to fit all Schedule tab content
- `BrowserInfo` now carries `NSImage` icon (dropped `Sendable` conformance)
- "Set as Default" button hidden when already the default browser

## v1.1.0

### Added

- **Homebrew Cask** — `brew install radiosilence/browser-schedule/browser-schedule`, auto-strips quarantine on install
- **Ad-hoc code signing** — app bundle is now signed during build, enabling right-click → Open without `xattr` workarounds
- **Full SwiftUI settings UI** — replaces the old "set default browser" alert with a proper tabbed settings window
  - **General tab**: browser pickers (auto-discovers installed browsers), default browser status/registration
  - **Schedule tab**: work hours and days editor with night shift detection, live status indicator
  - **URL Rules tab**: add/remove URL patterns with auto-save, split into personal/work columns
  - **Config Files tab**: raw TOML editor with syntax highlighting, side-by-side main/local config panes
- **Local config override support** in UI — toggle between editing `config.toml` and `config.local.toml` with override/inherit controls
- **`ConfigManager`** (`@Observable`) — centralized config state for SwiftUI binding, handles load/save/merge/validation
- **`BrowserEnumeration`** — discovers installed browsers via `NSWorkspace.urlsForApplications`
- **TOML syntax highlighting** — NSTextView-based editor with regex highlighting for keys, strings, sections, booleans, numbers, comments
- **App icon** — Core Graphics-generated macOS icon (clock with work/personal arcs + globe badge), `Scripts/generate-icon.swift` to regenerate
- **Smart quote sanitization** — strips macOS curly quotes/dashes on both load and save to prevent TOML parse errors
- **Standard menu bar** — programmatic App menu (Cmd+Q) and Edit menu (Cmd+C/V/X/Z/A) since bare NSApplication has none

### Changed

- Bumped minimum deployment target from macOS 11 to macOS 14 (required for `@Observable`)
- TOML serialization now uses double-quoted strings (removed `allowLiteralStrings` from TOMLKit format options)
