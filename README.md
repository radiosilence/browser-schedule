# Browser Schedule

[![CI/CD](https://github.com/radiosilence/browser-schedule/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/radiosilence/browser-schedule/actions/workflows/ci-cd.yml)

Automatically switches default browser based on time, day, and URL patterns. Built for macOS 14+ with Swift and SwiftUI.

<img width="702" height="612" alt="Screenshot 2026-02-28 at 10 31 21" src="https://github.com/user-attachments/assets/c87347bc-ff0b-407b-a5e0-fb0785ad366e" />
<img width="707" height="613" alt="Screenshot 2026-02-28 at 10 31 30" src="https://github.com/user-attachments/assets/833aab29-ab02-455d-9220-71bbe96d4b38" />


## Installation

### Homebrew (Recommended)

```sh
brew install --cask radiosilence/browser-schedule/browser-schedule
```

This installs via a [Homebrew Cask](https://github.com/radiosilence/homebrew-browser-schedule) which handles quarantine removal automatically. Double-click the app to open settings and set as default browser.

#### Brewfile

```ruby
tap "radiosilence/browser-schedule"
cask "browser-schedule"
```

### Direct Download

1. Download `BrowserSchedule.dmg` from the [latest release](https://github.com/radiosilence/browser-schedule/releases/latest)
2. Mount the DMG and drag BrowserSchedule.app to Applications
3. Remove quarantine: `xattr -cr /Applications/BrowserSchedule.app`
4. **Double-click the app** to open settings and set as default browser

### Build from Source

```sh
task install
```

Builds, ad-hoc signs, creates the app bundle, and installs to `/Applications`.

## Settings UI

Double-clicking the app opens a native macOS settings window with four tabs:

- **General** - Browser pickers with app icons, default browser status, live routing indicator
- **Schedule** - Native time pickers (stepper fields), day pickers, 24-hour timeline visualization
- **URL Rules** - Side-by-side pattern lists with duplicate detection, better empty states
- **Config Files** - Monokai Pro-themed TOML editor with syntax highlighting, delete confirmation

A scope picker at the top switches between `config.toml` and `config.local.toml` across all tabs. When invoked via URL (as the default browser), the app handles the URL silently in the background.

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

- [x] **Native settings UI**: Form-based layout with `LabeledContent`, browser icons, stepper time pickers
- [x] **URL overrides**: Specific URL fragments always open in designated browser
- [x] **Private overrides**: `config.local.toml` merges with main config, git-ignored
- [x] **Browser detection**: Auto-discovers installed browsers with icons for picker selection
- [x] **Minute-precision scheduling**: Work times like `9:30`/`17:45` are respected exactly
- [x] **Night shift support**: Work hours can span midnight
- [x] **Timeline visualization**: 24-hour bar showing work/personal segments with current time marker
- [x] **Monokai Pro editor**: TOML config editor with Filter Machine syntax theme
- [x] **Release Pipeline**: Automated DMG builds on GitHub releases
- [x] **Homebrew Cask**: `brew install --cask radiosilence/browser-schedule/browser-schedule`
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
