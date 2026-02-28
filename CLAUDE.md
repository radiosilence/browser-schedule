# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

### Claude Code Configuration

#### Response Style

- Be extremely concise and information-dense
- Avoid unnecessary validation phrases ("You're absolutely right")
- Target engineer-level technical communication
- Skip ego-stroking and pleasantries

#### Documentation Guidelines

- Prioritize information density over verbosity
- Explain the "why" behind decisions and implementations
- Avoid marketing language and feature promotion
- Focus on technical insights not obvious from code skimming
- Omit trivial breakdowns of obvious functionality

#### Code Style Preferences

- Avoid building unnecessary helper functions/abstractions
- Keep code inline unless it needs reuse, testing, or improves clarity
- Follow the "rule of 3" - abstract after third repetition, not before
- Balance DRY (Don't Repeat Yourself) with WET (Write Everything Twice) principles
- Prioritize concise but readable code over verbose clarity
- Suggest tests for complex logic, edge cases, and critical paths

## Project Overview

BrowserSchedule is a macOS 14+ application that automatically switches your default browser based on time, day, and URL patterns. Built in Swift with SwiftUI and TOML configuration, it integrates with macOS Launch Services to intercept URL opens and route them to work (Chrome) or personal (Zen) browsers based on configurable rules. On direct launch it shows a full settings UI; on URL invocation it handles the URL silently in the background.

## Architecture

### Module Structure

- **`Sources/BrowserScheduleCore/`** - Core logic module (testable, pure Swift)
  - `BrowserScheduleCore.swift` - Config types, loading, parsing, validation, URL routing, browser selection, work time logic
  - `ConfigManager.swift` - `@Observable` config manager for SwiftUI data binding, config saving via TOMLKit
  - `BrowserEnumeration.swift` - Discovers installed browsers via Launch Services
- **`Sources/BrowserSchedule/`** - Executable with SwiftUI settings UI
  - `main.swift` - NSApplication + SwiftUI hybrid: URL handling via AppDelegate, settings window via NSHostingView
  - `Views/` - SwiftUI views: ContentView (tabs), GeneralView (browser pickers), ScheduleView (work hours/days), URLRulesView (URL patterns), ConfigEditorView (raw TOML editor)
- **`Sources/BrowserScheduleCLI/`** - CLI interface for headless management
- **`Tests/BrowserScheduleTests/`** - Comprehensive test suite (30+ tests)

### Key Components

- **Config System**: TOML-based with local override support (`config.local.toml` merges with `config.toml`). ConfigManager provides `@Observable` bindings for SwiftUI and handles save/reload.
- **URL Routing Logic**: Three-tier decision hierarchy:
  1. URL fragment overrides (highest priority)
  2. Time/day-based work schedule detection
  3. Fallback to personal browser
- **App Lifecycle**: NSApplication with 0.5s timeout to distinguish direct launch (show UI) from URL invocation (silent handling). `setActivationPolicy` switches between `.prohibited` and `.regular`.
- **Logging**: Unified logging to macOS Console with centralized subsystem identifier
- **Bundle ID**: Centralized as `bundleIdentifier` constant in BrowserScheduleCore

### Key Design Patterns

- **Config Merging**: Local config files override base config, with URL arrays being merged (not replaced)
- **Night Shift Support**: Work hours can span midnight (e.g., "18:00"-"9:00") for night workers
- **Validation with Graceful Degradation**: Invalid config falls back to personal browser rather than failing
- **Dual Execution Modes**: Direct launch shows SwiftUI settings; URL invocation handles silently and exits
- **TOML Serialization**: ConfigManager builds TOMLTable manually for output (since Config uses `let` properties)

## Common Commands

### Development & Testing

- `task build` - Build Swift executable with TOMLKit dependency
- `task test` - Run comprehensive unit test suite (30+ tests)
- `task test-verbose` - Run tests with verbose output
- `task test-coverage` - Run tests with code coverage reporting
- `task test-app` - Integration test with real URL
- `task config` - Display current parsed configuration and validation status
- `task logs` - Recent activity (30 minutes)
- `task logs-realtime` - Stream real-time logs
- `task logs-all` - Extended history (24 hours)

### Installation & Management

- `task install` - Build, create app bundle, and register as default browser
- `task update` - Rebuild and update existing app bundle
- `task uninstall` - Remove app bundle and open System Settings to reset default browser
- `task status` - Check installation and URL handler registration status

### Configuration Management

Config files at `~/.config/browser-schedule/`:
- `config.toml` - Main config (created on first install)
- `config.local.toml` - Private overrides (git-ignored, created via UI or manually)

Configurable via the Settings UI or direct file editing. The app validates time formats (HH:MM), day names (Mon-Sun), and shows validation errors inline.

## Development Notes

- Requires macOS 14+ (Sonoma) for `@Observable` macro and modern SwiftUI
- Uses Swift Package Manager with TOMLKit for TOML parsing
- App bundle at `/Applications/BrowserSchedule.app` with `LSUIElement=true` in Info.plist (background by default, switches to foreground when showing UI)
- TOMLKit API: use direct assignment to TOMLTable subscripts (`table["key"] = "value"`), `TOMLArray(["a","b"])` for arrays, `table.convert()` for serialization

## Workflow Memories

- Always update the readme
