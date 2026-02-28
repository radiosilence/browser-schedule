# Browser Schedule

[![CI](https://github.com/radiosilence/browser-schedule/actions/workflows/ci.yml/badge.svg)](https://github.com/radiosilence/browser-schedule/actions/workflows/ci.yml)

Automatically switches default browser based on time, day, and URL patterns. Built for macOS 14+ with Swift and SwiftUI.

## Installation

### Option 1: Direct Download

1. Download `BrowserSchedule.dmg` from the [latest release](https://github.com/radiosilence/browser-schedule/releases/latest)
2. Mount the DMG and drag BrowserSchedule.app to Applications
3. Remove quarantine protection: `xattr -d com.apple.quarantine /Applications/BrowserSchedule.app`
4. **Double-click the app** to open the settings UI and set it as your default browser
5. Configure browsers, schedule, and URL rules from the UI

### Option 2: Build from Source (Recommended - Safer)

```sh
task install
```

This builds the app, creates the macOS app bundle, and sets up configuration files.

## Settings UI

Double-clicking the app opens a full settings window with four tabs:

- **General** - Pick work/personal browsers from installed apps, set as default browser
- **Schedule** - Configure work hours and days, see current work/personal status
- **URL Rules** - Add URL patterns that always route to a specific browser
- **Config Files** - Edit raw TOML config files directly (both main and local override)

When invoked via URL (as the default browser), the app handles the URL silently in the background without showing any UI.

## How It Works

BrowserSchedule registers as your default browser and routes URLs to work or personal browsers based on:

1. **URL fragment overrides** (highest priority)
2. **Time/day-based work schedule detection**
3. **Fallback to personal browser**

## Configuration

Configure via the Settings UI, or edit `~/.config/browser-schedule/config.toml` directly:

```toml
[browsers]
work = "Google Chrome"
personal = "Zen"

[urls]
personal = ["reddit.com", "news.ycombinator.com"]
work = ["atlassian.net", "meet.google.com", "figma.com"]

[work_time]
start = "9:00"
end = "18:00"

[work_days]
start = "Mon"
end = "Fri"
```

### Private Overrides

Create `~/.config/browser-schedule/config.local.toml` for private overrides that aren't checked into git. URL arrays are merged; everything else is replaced.

### Features

- [x] **Settings UI**: Full SwiftUI settings window for all configuration
- [x] **URL overrides**: Specific URL fragments always open in designated browser
- [x] **Private overrides**: `config.local.toml` merges with main config, git-ignored
- [x] **Browser detection**: Auto-discovers installed browsers for easy picker selection
- [x] **Night shift support**: Work hours can span midnight
- [x] **Release Pipeline**: Automated DMG builds on GitHub releases
- [ ] **Homebrew Cask**: Install without build tools (tap repo needed)
- [x] **App Icon**: Clock with work/personal arcs and globe badge, generated via Core Graphics

## Development

### Testing

```sh
task test           # Run unit tests (30+ tests)
task test-verbose   # Verbose test output
task test-coverage  # Generate code coverage
task test-app       # Integration test with real URL
task test-all       # Run both unit and integration tests
```

### Architecture

- **`BrowserScheduleCore`** - Testable Swift module: config loading/saving, URL routing, schedule logic, browser enumeration
- **`BrowserSchedule`** - SwiftUI settings UI + NSApplication URL handler
- **`BrowserScheduleCLI`** - CLI interface for headless management

### Commands

- `task build` - Build Swift executable
- `task build-dmg` - Build distributable DMG
- `task release -- patch|minor|major` - Create and push semantic version release
- `task install` - Install app bundle and register as default browser
- `task update` - Update existing app bundle
- `task uninstall` - Remove app bundle
- `task status` - Check installation status
- `task config` - Show current parsed configuration
- `task set-default` - Set BrowserSchedule as the default browser
- `task completions -- <shell>` - Generate shell completions (fish/zsh/bash)
- `task logs` - Show recent logs (last 30 minutes)
- `task logs-realtime` - Stream real-time logs
- `task logs-all` - Show all logs (last 24 hours)
- `task clean` - Clean build artifacts

### Shell Completions

```sh
task completions -- fish > ~/.config/fish/completions/browser-schedule.fish
task completions -- zsh > ~/.zsh/completion/_browser-schedule
task completions -- bash > ~/.bash_completions/browser-schedule
```

### Viewing Logs

```sh
task logs           # Recent activity (30 minutes)
task logs-realtime  # Real-time monitoring
task logs-all       # Extended history (24 hours)
```
