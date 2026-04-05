# swiftswiss

A Swiss army knife CLI tool written in Swift using **only native Apple frameworks** — no third-party packages allowed. Inspired by [mtool](https://github.com/jftuga/mtool) (the Go equivalent).

The primary goal of this project is to demonstrate how many Apple standard library frameworks can be meaningfully used in a single, compilable, actually-useful CLI tool.

## Framework Usage

**23 distinct Apple frameworks** are used across 23 subcommands:

| Framework | Subcommand(s) | What It Does |
|---|---|---|
| **Foundation** | everywhere | JSON, dates, files, regex, process info |
| **CryptoKit** | hash, encrypt, decrypt, generate | SHA-256/384/512, HMAC, AES-GCM, ChaChaPoly, HKDF |
| **Security** | keychain, generate | Keychain Services, SecRandomCopyBytes |
| **NaturalLanguage** | nlp | Language detection, sentiment, NER, POS, tokenization, lemmatization |
| **Vision** | ocr | Text recognition in images |
| **CoreGraphics** | ocr, image | Image loading, resizing, drawing contexts |
| **ImageIO** | ocr, image | Image format I/O, EXIF metadata |
| **CoreImage** | image | 200+ image filters (sepia, blur, noir, etc.) |
| **Accelerate** | math, image | vDSP (statistics, FFT, dot product, linspace), vImage (histogram) |
| **Compression** | compress | LZFSE, LZ4, ZLIB, LZMA compress/decompress |
| **UniformTypeIdentifiers** | filetype, image | File type identification, MIME types, type conformance |
| **os** | shared | Structured logging via `Logger` |
| **CoreLocation** | geo | Forward/reverse geocoding |
| **SystemConfiguration** | info | Network reachability, computer name, proxy config |
| **CoreServices** | spotlight | Spotlight index search via MDQuery |
| **AVFoundation** | media, speak | Audio/video inspection, text-to-speech |
| **CoreAudio** | info, media | Audio device enumeration, codec/format listing, audio file properties |
| **Network** | net | TCP port checking, network path monitoring |
| **CoreWLAN** | net, info | Wi-Fi connection details, network scanning, SSID |
| **IOKit** | info | Battery/power source information |
| **PDFKit** | pdf | PDF text extraction, search, split, merge, metadata |
| **CoreML** | ml | Model inspection, metadata, predictions |
| **DiskArbitration** | disk | Volume enumeration, mount/unmount event watching |

## Subcommands

### Math & Science
- **math** — Numeric operations: descriptive statistics (mean, median, stddev, percentiles), FFT, dot product, L2 norm, linspace

### Machine Learning
- **ml** — Inspect CoreML model metadata, inputs, and outputs; run predictions with key=value inputs

### Crypto
- **hash** — Compute SHA-256/384/512 hashes and HMACs of files or stdin
- **encrypt** — Encrypt files with AES-GCM or ChaChaPoly (password-based); outputs to `<file>.enc` by default
- **decrypt** — Decrypt files encrypted with the encrypt command; strips `.enc` extension by default
- **generate** — Generate passwords, UUIDs, random bytes, or symmetric keys

### Text & Data
- **nlp** — Natural language processing: language detection, sentiment analysis, named entity recognition, part-of-speech tagging, tokenization, lemmatization
- **json** — Pretty-print, compact, validate, or query JSON with dot-notation paths
- **time** — Display current time, convert to/from Unix epoch, list timezones
- **transform** — Text transforms: upper/lower/capitalize/reverse/trim/count, regex replace, base64/hex encode/decode

### Media & Image
- **ocr** — Extract text from images (PNG, JPEG, TIFF, HEIC) via OCR
- **image** — Resize, convert formats, apply Core Image filters, inspect EXIF metadata, per-channel color histogram
- **media** — Inspect audio/video files: duration, tracks, codecs, sample rates, metadata; list system audio codecs and formats
- **speak** — Text-to-speech synthesis with voice selection and rate control
- **pdf** — Extract text, search, split, merge, and inspect PDF metadata

### System & Network
- **net** — TCP port check, port range scan, network status, Wi-Fi connection details and network scanning
- **geo** — Forward geocoding (address to coordinates) and reverse geocoding
- **info** — System info (hostname, CPU, memory, uptime), battery status, network reachability, Wi-Fi SSID, disk usage, audio devices
- **filetype** — Identify file types, get MIME types, explore type conformance hierarchies
- **keychain** — Store, retrieve, delete, and list secrets in the macOS Keychain
- **compress** — Compress/decompress files using LZFSE, LZ4, ZLIB, or LZMA
- **spotlight** — Search the Spotlight index by file name, content, kind, or author
- **disk** — List mounted volumes with BSD name, filesystem, size, and flags; watch for disk mount/unmount events

## Build and Run

### Prerequisites

- macOS 14 (Sonoma) or later
- Swift 5.9+ (included with Xcode 15+ or the Swift toolchain)
- No Xcode project required — uses Swift Package Manager

Verify your setup:

```bash
swift --version
swift package --version
```

### Build

```bash
swift build
```

The compiled binary will be at `.build/debug/swiftswiss`.

### Run

```bash
# Via swift run
swift run swiftswiss <command> [options]

# Or directly after building
.build/debug/swiftswiss <command> [options]
```

### Build Release

```bash
swift build -c release
```

The optimized binary will be at `.build/release/swiftswiss`.

### Run Tests

```bash
swift test
```

150 tests covering hash, encrypt/decrypt, NLP, JSON, time, transform, generate, compress, filetype, image, math, PDF, ML, and disk operations.

## Examples

```bash
# Descriptive statistics
echo "1 2 3 4 5 6 7 8 9 10" | swiftswiss math

# FFT of a signal
echo "1 0 -1 0 1 0 -1 0" | swiftswiss math -mode fft

# Dot product
echo "1 2 3 4 5 6" | swiftswiss math -mode dot

# L2 norm
echo "3 4" | swiftswiss math -mode norm

# Generate evenly spaced numbers
echo "0 100" | swiftswiss math -mode linspace -n 11

# Image color histogram
swiftswiss image -mode histogram photo.png

# Hash a file
echo "hello" | swiftswiss hash -a sha256

# Detect language from inline text
swiftswiss nlp -mode detect -t "Bonjour le monde"

# Analyze sentiment from a file
swiftswiss nlp -mode sentiment review.txt

# Tokenize from stdin
echo "The quick brown fox" | swiftswiss nlp -mode tokenize

# Generate a password
swiftswiss generate -mode password -length 32 -charset alphanum

# Pretty-print JSON
cat data.json | swiftswiss json -mode pretty

# OCR an image
swiftswiss ocr screenshot.png

# Encrypt/decrypt a file (default extension: .enc)
swiftswiss encrypt -in secret.txt                       # creates secret.txt.enc
swiftswiss decrypt -in secret.txt.enc                   # creates secret.txt
swiftswiss encrypt -in secret.txt -out custom.bin       # explicit output path
swiftswiss decrypt -in custom.bin -out restored.txt     # -out required without .enc

# Compress with LZFSE
swiftswiss compress -algo lzfse -in large.txt -out large.lzfse
swiftswiss compress -d -algo lzfse -in large.lzfse -out large.txt

# Geocode an address
swiftswiss geo "1 Apple Park Way, Cupertino, CA"

# Check a port
swiftswiss net -host example.com -port 443

# Wi-Fi connection details (SSID, RSSI, channel, security)
swiftswiss net -mode wifi

# Scan for nearby Wi-Fi networks (requires Location Services)
swiftswiss net -mode wifi -scan

# System info
swiftswiss info

# Text-to-speech
swiftswiss speak "Hello from SwiftSwiss"

# Identify file type
swiftswiss filetype photo.heic

# Search Spotlight
swiftswiss spotlight -mode name "README"

# PDF info
swiftswiss pdf document.pdf

# Extract text from PDF pages 1-3
swiftswiss pdf -mode text -in document.pdf -pages 1-3

# Search a PDF
swiftswiss pdf -mode search -in document.pdf -search "quarterly"

# Extract pages into a new PDF
swiftswiss pdf -mode split -in document.pdf -pages 2-5 -out excerpt.pdf

# Merge multiple PDFs
swiftswiss pdf -mode merge -out combined.pdf file1.pdf file2.pdf

# Inspect a CoreML model
swiftswiss ml model.mlmodel

# Run a CoreML prediction
swiftswiss ml -mode predict -model regressor.mlmodel -input x=1.0 y=2.0

# List mounted volumes
swiftswiss disk

# Watch for disk mount/unmount events
swiftswiss disk -mode watch -timeout 30

# List available audio codecs
swiftswiss media -mode codecs

# List supported audio file formats
swiftswiss media -mode formats
```

## Architecture

```
Package.swift                          # SPM manifest (3 targets)
Sources/
  swiftswiss/
    main.swift                         # Entry point — calls SwiftSwiss.run()
  SwiftSwissLib/
    SwiftSwiss.swift                   # Dispatcher, usage text
    Errors.swift                       # SwiftSwissError enum
    Shared.swift                       # readInput, formatBytes, Logger, etc.
    Commands/
      HashCommand.swift                # CryptoKit
      EncryptCommand.swift             # CryptoKit
      DecryptCommand.swift             # CryptoKit
      GenerateCommand.swift            # CryptoKit, Security
      NLPCommand.swift                 # NaturalLanguage
      JSONCommand.swift                # Foundation
      TimeCommand.swift                # Foundation
      TransformCommand.swift           # Foundation
      OCRCommand.swift                 # Vision, CoreGraphics, ImageIO
      ImageCommand.swift               # CoreGraphics, ImageIO, CoreImage, UTType
      MathCommand.swift                # Accelerate (vDSP)
      MediaCommand.swift               # AVFoundation, CoreAudio (AudioToolbox)
      SpeakCommand.swift               # AVFoundation
      NetCommand.swift                 # Network, CoreWLAN
      GeoCommand.swift                 # CoreLocation
      InfoCommand.swift                # IOKit, SystemConfiguration, CoreAudio, CoreWLAN
      FileTypeCommand.swift            # UniformTypeIdentifiers
      KeychainCommand.swift            # Security
      CompressCommand.swift            # Compression
      SpotlightCommand.swift           # CoreServices
      PDFCommand.swift                 # PDFKit
      MLCommand.swift                  # CoreML
      DiskCommand.swift                # DiskArbitration
Tests/
  SwiftSwissTests/
    TestHelpers.swift                  # captureStdout, writeTestFile
    HashTests.swift
    EncryptTests.swift
    NLPTests.swift
    JSONTests.swift
    TimeTests.swift
    TransformTests.swift
    GenerateTests.swift
    CompressTests.swift
    FileTypeTests.swift
    ImageTests.swift
    MathTests.swift
    PDFTests.swift
    MLTests.swift
    DiskTests.swift
```

## License

MIT
