# CLAUDE.md — swiftswiss development guide

## Project overview

`swiftswiss` is a Swiss army knife CLI tool written in Swift using **only native Apple frameworks**. No third-party packages are allowed — this is a hard constraint. Every feature must be implemented with what Apple ships in the macOS SDK.

This project is inspired by [mtool](https://github.com/jftuga/mtool), an equivalent project in Go that uses only Go standard library packages. The project currently uses **23 distinct Apple frameworks** across 23 subcommands.

## Hard constraints

- **Zero third-party dependencies.** The `Package.swift` must never contain external package URLs. If a capability can't be achieved with Apple frameworks, find a creative alternative or skip it.
- **Must compile as a CLI tool.** No app bundle, no Xcode project, no entitlements. Everything builds with `swift build` via SPM.
- **macOS 14+ minimum deployment target.** Set in Package.swift `platforms: [.macOS(.v14)]`.
- **Quality over quantity.** Don't add frameworks just to inflate the count. Each framework usage must be meaningful and the subcommand genuinely useful.
- **Single framework, multiple subsystems.** A framework like Accelerate can be used for both vDSP (math) and vImage (image histogram) — this counts as one framework, not two.

## Excluded framework categories

These categories were intentionally excluded as unsuitable for a CLI tool:

- **UI Frameworks**: SwiftUI, AppKit, UIKit, PencilKit, PhotosUI
- **Augmented Reality**: ARKit, RealityKit
- **Game Development**: GameKit, GameController, SpriteKit, SceneKit
- **Requires Hardware/Sensors**: CoreMotion, CoreBluetooth, CoreNFC, CoreHaptics, Nearby Interaction
- **Requires Entitlements/Sandbox**: HealthKit, HomeKit, EventKit, Contacts, Photos, StoreKit, CloudKit, CallKit, PushKit, EndpointSecurity, WidgetKit, ActivityKit
- **Requires App Bundle**: TipKit, App Intents, MusicKit
- **Virtualization**: Dropped for complexity — could be reconsidered

## Current framework inventory (23)

| # | Framework | Import | Used In |
|---|-----------|--------|---------|
| 1 | Foundation | `import Foundation` | everywhere |
| 2 | CryptoKit | `import CryptoKit` | hash, encrypt, decrypt, generate |
| 3 | Security | `import Security` | keychain, generate (SecRandomCopyBytes) |
| 4 | NaturalLanguage | `import NaturalLanguage` | nlp |
| 5 | Vision | `import Vision` | ocr |
| 6 | CoreGraphics | `import CoreGraphics` | ocr, image |
| 7 | ImageIO | `import ImageIO` | ocr, image |
| 8 | CoreImage | `import CoreImage` | image |
| 9 | Compression | `import Compression` | compress |
| 10 | UniformTypeIdentifiers | `import UniformTypeIdentifiers` | filetype, image |
| 11 | os | `import os` | shared (Logger) |
| 12 | CoreLocation | `import CoreLocation` | geo |
| 13 | SystemConfiguration | `import SystemConfiguration` | info |
| 14 | CoreServices | `import CoreServices` | spotlight |
| 15 | AVFoundation | `import AVFoundation` | media, speak |
| 16 | Network | `import Network` | net |
| 17 | IOKit | `import IOKit` | info |
| 18 | PDFKit | `import PDFKit` | pdf |
| 19 | CoreAudio | `import CoreAudio`, `import AudioToolbox` | info (device enumeration), media (codecs, formats, file properties) |
| 20 | Accelerate | `import Accelerate` | math (vDSP: stats, FFT, dot product, norm, linspace), image (vImage: histogram) |
| 21 | CoreWLAN | `import CoreWLAN` | net (Wi-Fi connection details, network scanning), info (current SSID) |
| 22 | CoreML | `import CoreML` | ml (model inspection, metadata, predictions) |
| 23 | DiskArbitration | `import DiskArbitration` | disk (volume enumeration, mount/unmount events) |

Additional system-level imports that don't count as separate frameworks: `CoreMedia` (sub-framework of AVFoundation usage), `IOKit.ps` (sub-module of IOKit), `AudioToolbox` (sub-framework of CoreAudio).

## Architecture

### Build system

Swift Package Manager with three targets defined in `Package.swift`:
- `swiftswiss` — executable target (thin entry point)
- `SwiftSwissLib` — library target (all command logic, testable)
- `SwiftSwissTests` — test target

The library/executable split exists so tests can `@testable import SwiftSwissLib`.

### File structure

```
Package.swift                              # SPM manifest
Makefile                                   # build, test, release, dist, install
Sources/
  swiftswiss/
    main.swift                             # 3-line entry point, calls SwiftSwiss.run()
  SwiftSwissLib/
    SwiftSwiss.swift                       # Dispatcher, usage text, version (single source of truth)
    Errors.swift                           # SwiftSwissError enum
    Shared.swift                           # readInput, writeOutput, formatBytes, formatDuration, readSecureInput, Logger
    Commands/
      <Name>Command.swift                  # One file per subcommand (23 commands)
Tests/
  SwiftSwissTests/
    TestHelpers.swift                      # captureStdout, writeTestFile, writeTestData
    <Name>Tests.swift                      # One file per tested subcommand
```

### Command structure

Each command is a `public enum` (never instantiated — pure namespace) with:

```swift
public enum FooCommand {
    // CLI entry point: parses args, prints output
    public static func run(_ args: [String]) throws { ... }

    // Core logic: public for testing, returns values instead of printing
    public static func coreFn(...) throws -> SomeType { ... }

    // Help text
    static func printHelp() { ... }
}
```

Key conventions:
- Arguments are parsed manually with a `while` loop over `args` (no argument parser library)
- Sync commands use `throws`, async commands use `async throws`
- The dispatcher in `SwiftSwiss.swift` calls each command's `run()` — sync commands called from async context work fine
- Each command's help text includes a "Frameworks:" line listing what it uses

### Async commands

Three commands require `async`: `geo` (CLGeocoder), `net` (NWConnection/NWPathMonitor), `media` (AVAsset.load). The entry point in `main.swift` uses top-level `await`. All other commands (including `math`) are synchronous.

### Version

The version string lives in **one place**: `SwiftSwiss.swift` as `public static let version`. The Makefile extracts it via `grep`/`sed` for the `dist` target. Do not duplicate the version elsewhere.

## Testing

Tests use XCTest and live in `Tests/SwiftSwissTests/`. 150 tests currently.

### Patterns

- **Known-value tests**: SHA-256 of "hello" must equal a specific hex string
- **Round-trip tests**: encrypt then decrypt, compress then decompress, base64 encode then decode
- **Error path tests**: wrong password, invalid input, unknown algorithm, truncated data
- **Output capture tests**: `captureStdout {}` redirects stdout via `dup2` to verify CLI output
- **Programmatic fixtures**: test images created via `CGContext` in-process, temp files via `writeTestFile()`

### What's tested vs not

Tested (deterministic, no side effects): hash, encrypt/decrypt, nlp, json, time, transform, generate, compress, filetype, image, math, pdf, ml (helper functions, error paths), disk (volume enumeration, CLI output)

Not tested (requires system access): ocr (needs image files with text), geo (network), info (system-dependent), keychain (security prompts), media (needs media files), speak (audio output), spotlight (index-dependent), net (network, Wi-Fi hardware, Location Services)

### Running tests

```bash
swift test          # or: make test  (150 tests)
```

## Adding a new subcommand

1. Create `Sources/SwiftSwissLib/Commands/<Name>Command.swift`
   - `public enum <Name>Command` with `run(_ args:)` and `printHelp()`
   - Import the Apple framework(s) you're using
   - Extract testable core logic into separate public static methods
2. Register it in `SwiftSwiss.swift`:
   - Add a `case` in the dispatcher `switch`
   - Add a line in `printUsage()`
3. Create `Tests/SwiftSwissTests/<Name>Tests.swift` if the command is testable
4. Update `README.md`:
   - Add to the subcommand list
   - Add to the framework table if using a new framework
   - Add an example
5. If using a new C-based framework that needs explicit linking, add a `.linkedFramework()` entry in `Package.swift`'s `SwiftSwissLib` target `linkerSettings`

## Frameworks that could still be added

These are CLI-feasible Apple frameworks not yet used — candidates for new subcommands:

| Framework | Potential Use | Notes |
|---|---|---|
| **Combine** | Reactive pipeline for file watching or network monitoring | Could enhance `net` or add a `watch` command |
| **Distributed** | Distributed actors demo | Stretch — hard to make useful in CLI |
| **WeatherKit** | Weather data | Requires Apple Developer account / API key |

## Build and verify

```bash
swift build         # debug build
swift build -c release  # optimized build
swift test          # run all 150 tests
make dist           # create distributable .tar.xz archive
```

## Makefile targets

```
make build       # debug build (default)
make release     # optimized release build
make test        # run all tests
make clean       # remove build artifacts
make install     # build release + copy to /usr/local/bin
make uninstall   # remove from /usr/local/bin
make run         # build + run (shows usage)
make dist        # build release + create swiftswiss-v<VERSION>.tar.xz
make help        # list all targets
```
