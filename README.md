# 🌐 Browser Schedule

[![CI](https://github.com/radiosilence/browser-schedule/actions/workflows/ci.yml/badge.svg)](https://github.com/radiosilence/browser-schedule/actions/workflows/ci.yml)

Automatically switches default browser based on time, day, and URL patterns. Built for macOS with Swift and TOML configuration.

## Installation

### Option 1: Direct Download

1. Download `BrowserSchedule.dmg` from the [latest release](https://github.com/radiosilence/browser-schedule/releases/latest)
2. Mount the DMG and drag BrowserSchedule.app to Applications
3. Remove quarantine protection: `xattr -d com.apple.quarantine /Applications/BrowserSchedule.app`
4. **Double-click the app** to set it as your default browser
5. Configure via `~/.config/browser-schedule/config.toml`

### Option 2: Build from Source (Recommended - Safer)

```sh
task install
```

This builds the app, creates the macOS app bundle, and sets up configuration files.

### Setting as Default Browser

After installation, **double-click BrowserSchedule.app** in Applications to:

- Set it as your default browser (if not already set)
- See confirmation that it's active and routing URLs correctly

The app will show a dialog confirming the setup or current status.

## How It Works

BrowserSchedule registers as your default browser and routes URLs to work (Chrome) or personal (Zen) browsers based on:

1. **URL fragment overrides** (highest priority)
2. **Time/day-based work schedule detection**
3. **Fallback to personal browser**

## Configuration

Edit `~/.config/browser-schedule/config.toml`:

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

### Features

- [x] **URL overrides**: Specific URL fragments always open in designated browser
- [x] **Private overrides**: Create `config.local.toml` with same format (merged with main config, git-ignored)
- [x] **Reasonable .app behaviour**: Double-clicking the app sets it as default browser
- [x] **Release Pipeline**: Automated DMG builds on GitHub releases
- [ ] **Homebrew Cask**: Install without build tools (tap repo needed)
- [ ] **App Icon**: It should look nice or something

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

- **`BrowserScheduleCore`** - Testable Swift module with all logic
- **`BrowserSchedule`** - Thin executable wrapper for CLI and app bundle
- **Comprehensive test suite** - Covers time parsing, config validation, work time detection, browser selection, and edge cases

### Commands

- `task build` - Build Swift executable
- `task build-dmg` - Build distributable DMG in `./build/BrowserSchedule.dmg`
- `task release -- patch|minor|major` - Create and push semantic version release
- `task install` - Install app bundle and register as default browser
- `task update` - Update existing app bundle
- `task uninstall` - Remove app bundle
- `task status` - Check installation status
- `task config` - Show current parsed configuration
- `task logs` - Show recent logs (last 30 minutes)
- `task logs-realtime` - Stream real-time logs
- `task logs-all` - Show all logs (last 24 hours)
- `task clean` - Clean build artifacts

### Viewing Logs

```sh
task logs           # Recent activity (30 minutes)
task logs-realtime  # Real-time monitoring
task logs-all       # Extended history (24 hours)
```
