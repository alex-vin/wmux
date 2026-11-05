// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WMUXDebugLog",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WMUXDebugLog",
            targets: ["WMUXDebugLog"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WMUXDebugLog",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ],
            path: "Sources/WMUXDebugLog"
        ),
        .testTarget(
            name: "WMUXDebugLogTests",
            dependencies: ["WMUXDebugLog"],
            path: "Tests/WMUXDebugLogTests"
        ),
    ]
)
