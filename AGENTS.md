# Taktwerk — Agent Instructions

A native macOS SwiftUI application for managing launchd agents and daemons. This file captures project-specific conventions and decisions for AI agents working on this codebase.

## Tech Stack

- **Swift 6.2+** / **SwiftUI** — macOS 26 (Tahoe) only, no multiplatform
- **Architecture**: MVVM with `@Observable` ViewModels (`@MainActor`)
- **Build system**: XcodeGen from `project.yml` — run `xcodegen generate` after adding files
- **Testing**: Swift Testing (`@Test`, `#expect`) — not XCTest
- **Dependencies**: Zero third-party — pure Foundation + SwiftUI
- **Concurrency**: `complete` strict concurrency checking; Services are `actor`-based

## Development Commands

```bash
# Generate Xcode project (required after adding/removing source files)
xcodegen generate

# Build
xcodebuild -project Taktwerk.xcodeproj -scheme Taktwerk -configuration Debug build

# Run tests
xcodebuild -project Taktwerk.xcodeproj -scheme Taktwerk -configuration Debug test

# Open in Xcode
open Taktwerk.xcodeproj
```

## Versioning

- **Semantic versioning** via Git tags: `v<major>.<minor>.<patch>`
- Info.plist uses `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` — never hardcode version numbers
- Default values in `project.yml` build settings; CI overrides them at build time
- CI workflows: `.github/workflows/ci.yml` (build+test) and `release.yml` (signed DMG release on `v*` tags)
- Self-hosted runner required (macOS 26 + Xcode 26)

## Project Structure

```
Taktwerk/
├── Models/           # Domain models (LaunchdJob, PlistConfig, CalendarInterval, TagStore)
├── Services/         # Actor-based system interaction (LaunchctlService, PlistService, LogService)
├── Features/         # Feature-based UI modules
│   ├── JobList/      # Sidebar list with filtering (View + ViewModel + Components)
│   ├── JobDetail/    # Detail pane with job info, tags, actions
│   ├── JobEditor/    # Plist editor with form↔XML sync and validation
│   └── Settings/     # Preferences: General + Tags tabs
├── Shared/           # Reusable views (FilterChip, TagBadge), modifiers, extensions
├── Assets.xcassets/  # App icon (10 PNG sizes) and colors
├── Resources/        # Bundled resources
├── ContentView.swift # Root NavigationSplitView
└── TaktwerkApp.swift # App entry point with @main
TaktwerkTests/        # Unit tests (Swift Testing)
project.yml           # XcodeGen project specification
```

## Architecture Decisions

### MVVM Pattern
- Views own their ViewModel via `@State private var viewModel = SomeViewModel()`
- ViewModels are `@Observable @MainActor final class` — no `ObservableObject`/`@Published`
- Feature folders group View + ViewModel + Components together

### Services (Actor-based)
- `LaunchctlService` — wraps `Process` calls to `launchctl` for load/unload/status
- `PlistService` — scans plist directories, parses/writes XML, validates with `plutil`
- `LogService` — reads launchd log output
- All services are `actor` for thread-safe concurrent access

### Tag System
- `TagStore` is a singleton (`TagStore.shared`) backed by `UserDefaults`
- Tags use **stable UUID-based identity** (`TagDefinition.id` is a UUID string, separate from `name`)
- Tag assignments map job labels → sets of tag IDs (not names)
- Supports rename without breaking assignments; migration from legacy name-based data on init
- Default tags seeded once via `UserDefaults.bool(forKey: "tagDefaultsSeeded")` guard

### Plist Editor
- Two-way sync: structured form ↔ raw XML editor
- Toggling between modes converts in both directions
- Live XML validation with warning banner; Save disabled on invalid XML
- `plutil -lint` integration for Apple's official validation via temp file

### Filter System
- Source filter (All / User Agents / Global Agents / User Daemons / Global Daemons)
- Tag filter (All / specific tag)
- Visible filter chips in sidebar status bar with clear buttons
- Default filters persisted via `@AppStorage` / `UserDefaults`

## Platform-Specific Notes

- **No App Sandbox** — requires filesystem access to `/Library/LaunchAgents`, `/Library/LaunchDaemons`, `~/Library/LaunchAgents`, and `launchctl`
- **Hardened Runtime** enabled
- **launchctl** is at `/bin/launchctl` on macOS Tahoe (not `/usr/bin/launchctl`) — service dynamically resolves paths searching `/bin`, `/usr/bin`, `/usr/sbin`
- **plutil** is at `/usr/bin/plutil` for plist validation
- **Plist parsing** uses `PropertyListSerialization` (handles both XML and binary formats natively)

## Coding Conventions

- macOS only — no `#if os()` conditionals
- Prefer `struct` for value types, `final class` for reference types
- Feature folders contain View + ViewModel + Components together
- Minimal code comments — only where clarification is genuinely needed
- Use `foregroundStyle()` not `foregroundColor()` (deprecated)
- Avoid `ColorPicker` on macOS (renders as oversized pill) — use inline preset color dot circles instead

## Build Environment Quirks

- **Icon regeneration**: Use `sips -z <size> <size> <src> --out <dest>` (Apple's Scriptable Image Processing System with Lanczos resampling)
- **`foregroundStyle` type mismatch**: Mixing `Color` and `HierarchicalShapeStyle` in the same context fails in Swift 6.2 — use concrete `Color` values or `foregroundColor` as fallback

## Git Workflow

- **Do NOT push** unless the user explicitly asks — commit locally, let the user decide when to push
- **Use signed commits** — do not pass `-c commit.gpgsign=false`; let the system's default signing handle it
- **Squashed history** — this repo uses a single-commit history; amend the existing commit when making changes

## Skills

This project uses the following agent skills (see `.agents/skills/`):

- **swiftui-pro** — SwiftUI best practices and modern API review
- **swiftdata-pro** — SwiftData patterns (not currently used, available for future persistence)
- **swift-concurrency-pro** — Swift concurrency correctness review
- **swift-testing-pro** — Swift Testing framework best practices
- **swift-architecture-skill** — Architecture patterns (MVVM, TCA, Clean Architecture)

Refer to individual skill SKILL.md files for their specific instructions. This document covers only project-level conventions not addressed by skills.
