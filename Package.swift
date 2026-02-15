// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "wt",
    platforms: [.macOS("13.0")],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/tuist/Noora", from: "0.15.0"),
        .package(url: "https://github.com/mattt/swift-toml.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "wt",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Noora",
                .product(name: "TOML", package: "swift-toml"),
            ],
            path: "Sources/wt"
        ),
    ]
)
