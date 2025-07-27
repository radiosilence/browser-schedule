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

BrowserSchedule is a macOS application that automatically switches your default browser based on time, day, and URL patterns. Built in Swift with TOML configuration, it integrates with macOS Launch Services to intercept URL opens and route them to work (Chrome) or personal (Zen) browsers based on configurable rules.

## Architecture

The application consists of a single Swift file (`main.swift`) with these key components:

- **Config System**: TOML-based configuration with support for local overrides (`config.local.toml` merges with `config.toml`)
- **URL Routing Logic**: Three-tier decision making:
  1. URL fragment overrides (highest priority)
  2. Time/day-based work schedule detection
  3. Fallback to personal browser
- **macOS Integration**: Registers as URL scheme handler via Launch Services and app bundle creation
- **Logging**: Optional unified logging to macOS Console with subsystem `com.radiosilence.browser-schedule`

### Key Design Patterns

- **Config Merging**: Local config files override base config, with URL arrays being merged (not replaced)
- **Night Shift Support**: Work hours can span midnight (e.g., "18:00"-"9:00") for night workers
- **Validation with Graceful Degradation**: Invalid config falls back to personal browser rather than failing
- **Dual Execution Modes**: Command-line URL handling and NSApplication-based URL event handling

## Common Commands

### Development & Testing

- `task build` - Build Swift executable with TOMLKit dependency
- `task test` - Test with sample URL and show logs
- `task test-work` - Test during simulated work hours
- `task config` - Display current parsed configuration and validation status
- `task logs` - View recent activity via unified logging

### Installation & Management

- `task install` - Build, create app bundle, and register as default browser
- `task update` - Rebuild and update existing app bundle
- `task uninstall` - Remove app bundle and open System Settings to reset default browser
- `task status` - Check installation and URL handler registration status

### Configuration Management

Config files are automatically created at:

- `~/.config/browser-schedule/config.toml` (main config)
- `~/.config/browser-schedule/config.local.toml` (private overrides, git-ignored)

The app validates time formats (HH:MM), day names (Mon-Sun), and provides detailed error reporting via `--config` flag.

## Development Notes

- Uses Swift Package Manager with TOMLKit dependency for TOML parsing
- Requires macOS 11+ minimum for unified logging and modern Swift features
- App bundle is created at `/Applications/BrowserSchedule.app` with proper Info.plist for URL scheme handling
- Registration with Launch Services requires the `--set-default` flag after bundle creation
- Logging can be viewed in Console.app or via `log show` command with subsystem filtering
