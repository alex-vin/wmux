// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxCanvasUI",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxCanvasUI",
            targets: ["WmuxCanvasUI"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxCanvas"),
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxCanvasUI",
            dependencies: [
                "WmuxCanvas",
                "WmuxFoundation",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxCanvasUITests",
            dependencies: [
                "WmuxCanvasUI",
            ]
        ),
    ]
)
