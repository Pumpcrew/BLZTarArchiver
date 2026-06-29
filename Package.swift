
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BLZTar",
    platforms: [
        .iOS(.v15), .macOS(.v11), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "BLZTar", targets: ["BLZTar"]),
    ],
    dependencies: [
        // If you want to use swift-nio-extras gzip engine, uncomment below and in Sources/BLZTar/GzipNIOExtras.swift
        // .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "BLZTar",
            dependencies: [
                // .product(name: "NIOExtras", package: "swift-nio-extras"),
                // .product(name: "NIOCore", package: "swift-nio-extras")
            ]
        ),
        .testTarget(
            name: "BLZTarTests",
            dependencies: ["BLZTar"]
        ),
    ]
)
