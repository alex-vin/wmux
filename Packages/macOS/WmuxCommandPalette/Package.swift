// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxCommandPalette",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxCommandPalette",
            targets: ["WmuxCommandPalette"]
        ),
    ],
    dependencies: [
        // WmuxFoundation backs the FocusGuards/ command-palette focus-stealing
        // NSResponder/NSView guards.
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxCommandPalette",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxCommandPaletteTests",
            dependencies: [
                "WmuxCommandPalette",
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
