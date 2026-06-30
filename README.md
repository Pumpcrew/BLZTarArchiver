# BLZTar

[![Swift Version Compatibility](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/Pumpcrew/BLZTarArchiver/badge?type=swift-versions)](https://swiftpackageindex.com/Pumpcrew/BLZTarArchiver)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/Pumpcrew/BLZTarArchiver/badge?type=platforms)](https://swiftpackageindex.com/Pumpcrew/BLZTarArchiver)

Pure Swift TAR/USTAR archiver with **PAX extended headers** and **proper GZIP support**, including **real-time progress reporting**.

## Features

- ✅ **USTAR + PAX support** — Full preservation of long paths and file names (>255 bytes)
- ✅ **Proper GZIP header/footer** — zlib-based gzip, 100% compatible (optional swift-nio-extras engine)
- ✅ **Real-time progress callbacks** — Byte-based overall progress and per-file progress
- ✅ Supports iOS 15+, macOS 11+, tvOS 13+, watchOS 6+
- ✅ No external dependencies (optional swift-nio-extras)

## Installation (Swift Package Manager)

In Xcode:
- Go to **File → Add Packages** → `https://github.com/Pumpcrew/BLZTarArchiver.git`
- Or add to your `Package.swift` manually:

```swift
.package(url: "https://github.com/Pumpcrew/BLZTarArchiver.git", from: "1.0.0")
```

## Usage

```swift
import BLZTar

// Archive (with gzip)
let archOpt = BLZTarArchiveOptions(
    gzip: true,
    gzipEngine: .zlib,
    onProgressBytes: { processed, total in
        let pct = Double(processed) / Double(total) * 100
        print(String(format: "Archive %.1f%%", pct))
    }
)

try BLZTar.archive(
    directory: URL(fileURLWithPath: "/path/to/folder"),
    to: URL(fileURLWithPath: "/path/out/archive.tar.gz"),
    options: archOpt
)

// Extract
let extOpt = BLZTarExtractOptions(
    onProgressBytes: { done, total in
        print("Extract: \(done)/\(total)")
    }
)

try BLZTar.extract(
    archive: URL(fileURLWithPath: "/path/out/archive.tar.gz"),
    toDirectory: URL(fileURLWithPath: "/path/restore"),
    options: extOpt
)
```

## Options

| Option | Description |
|-------|-------------|
| `gzip` | Generate `.tar.gz` archive |
| `gzipEngine` | `.zlib` (default) or `.nioExtras` |
| `onProgressBytes` | Global byte progress callback `(processed, total)` |
| `reportGranularityBytes` | Minimum byte interval for callback (default 512KB) |
| `onProgressPerFile` | Per-file progress callback |

## Enabling swift-nio-extras

- Add `swift-nio-extras` dependency in `Package.swift`
- Set `BLZTarArchiveOptions.gzipEngine = .nioExtras`

## License

MIT
