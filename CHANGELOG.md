# Changelog

## Unreleased

### Added

- **Full SwiftUI settings UI** — replaces the old "set default browser" alert with a proper tabbed settings window
  - **General tab**: browser pickers (auto-discovers installed browsers), default browser status/registration
  - **Schedule tab**: work hours and days editor with night shift detection, live status indicator
  - **URL Rules tab**: add/remove URL patterns with auto-save, split into personal/work columns
  - **Config Files tab**: raw TOML editor with syntax highlighting, side-by-side main/local config panes
- **Local config override support** in UI — toggle between editing `config.toml` and `config.local.toml` with override/inherit controls
- **`ConfigManager`** (`@Observable`) — centralized config state for SwiftUI binding, handles load/save/merge/validation
- **`BrowserEnumeration`** — discovers installed browsers via `NSWorkspace.urlsForApplications`
- **TOML syntax highlighting** — NSTextView-based editor with regex highlighting for keys, strings, sections, booleans, numbers, comments
- **Smart quote sanitization** — strips macOS curly quotes/dashes on both load and save to prevent TOML parse errors
- **Standard menu bar** — programmatic App menu (Cmd+Q) and Edit menu (Cmd+C/V/X/Z/A) since bare NSApplication has none

### Changed

- Bumped minimum deployment target from macOS 11 to macOS 14 (required for `@Observable`)
- TOML serialization now uses double-quoted strings (removed `allowLiteralStrings` from TOMLKit format options)
