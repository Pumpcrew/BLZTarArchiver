
# BLZTar (Swift) — TAR/USTAR with PAX + Proper GZIP, Progress

- Pure Swift TAR archiver/extractor with **PAX** extended headers for long paths
- Proper **GZIP** (zlib wrapper) with optional **swift-nio-extras**
- **Real-time progress** callbacks (bytes-based), both archive & extract
- iOS 13+ / macOS 11+

## Install (SPM)
Add this repository to your Package.swift or Xcode SPM UI.

## Usage
```swift
import BLZTar

let archOpt = BLZTarArchiveOptions(
    gzip: true, gzipEngine: .zlib,
    onProgressBytes: { done, total in
        print("Archive: \(done)/\(total)")
    }
)
try BLZTar.archive(
    directory: URL(fileURLWithPath: "/path/in"),
    to: URL(fileURLWithPath: "/path/out/archive.tar.gz"),
    options: archOpt
)

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

### Enabling swift-nio-extras GZIP
- In `Package.swift`, uncomment the dependency & target products (NIOExtras/NIOCore).
- In source, the NIO-based engine is already conditionally compiled.
