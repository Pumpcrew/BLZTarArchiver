# BLZTar

Pure Swift TAR/USTAR archiver with **PAX extended headers** and **proper GZIP support**, including **real-time progress reporting**.

## Features

- ✅ **USTAR + PAX 지원** — 255바이트 넘는 경로나 긴 파일명 완벽 보존
- ✅ **정식 GZIP 헤더/푸터** — zlib 기반 gzip, 100% 호환 (옵션으로 swift-nio-extras 사용 가능)
- ✅ **실시간 진행률 콜백** — 전체 바이트 기준, 파일별 진행률까지 지원
- ✅ iOS 15+, macOS 11+, tvOS 13+, watchOS 6+ 지원
- ✅ 외부 의존성 없음 (선택적으로 swift-nio-extras)

## Installation (Swift Package Manager)

Xcode에서:
- File → Add Packages → `https://github.com/Pumpcrew/BLZTarArchiver.git`
- 또는 `Package.swift`에 직접 추가:

```swift
.package(url: "https://github.com/Pumpcrew/BLZTarArchiver.git", from: "1.0.0")
```

## Usage

```swift
import BLZTar

// 아카이브 (gzip 포함)
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

// 추출
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

| Option | 설명 |
|-------|------|
| `gzip` | `.tar.gz` 생성 여부 |
| `gzipEngine` | `.zlib` (기본) 또는 `.nioExtras` |
| `onProgressBytes` | 전체 진행률 콜백 (processed, total) |
| `reportGranularityBytes` | 콜백 호출 최소 간격 (기본 512KB) |
| `onProgressPerFile` | 파일별 진행률 콜백 |

## Enabling swift-nio-extras

- `Package.swift`의 의존성에 `swift-nio-extras` 추가 후
- `BLZTarArchiveOptions.gzipEngine = .nioExtras` 로 설정

## License

MIT
