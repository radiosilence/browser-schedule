# 🌐 Browser Schedule

[![CI](https://github.com/radiosilence/browser-schedule/actions/workflows/ci.yml/badge.svg)](https://github.com/radiosilence/browser-schedule/actions/workflows/ci.yml)

Automatically switches default browser based on time, day, and URL patterns. Built for macOS with Swift and TOML configuration.

## Quick Start

```sh
task install
```

This builds the app, creates the macOS app bundle, and sets up configuration files.

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

# Optional logging configuration
# [log]
# (reserved for future logging options)
```

### Advanced Features

- **URL overrides**: Specific URL fragments always open in designated browser
- **Private overrides**: Create `config.local.toml` with same format (merged with main config, git-ignored)
- **Work schedule**: Flexible time and day ranges for automatic browser selection
- **Night shifts**: Inverse time ranges (e.g., "18:00"-"9:00") support workers spanning midnight
- **Logging**: Always logs to unified logging with optional URL redaction for privacy

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
