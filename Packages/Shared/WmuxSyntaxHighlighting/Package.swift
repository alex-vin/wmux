// swift-tools-version: 6.0

import PackageDescription

/// Leaf syntax-highlighting engine used by File Preview (and later other
/// native code views). Highlightr is the v1 adapter; chrome stays in the app.
let package = Package(
    name: "WmuxSyntaxHighlighting",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSyntaxHighlighting",
            targets: ["WmuxSyntaxHighlighting"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/raspu/Highlightr.git",
            exact: "2.3.0"
        ),
    ],
    targets: [
        .target(
            name: "WmuxSyntaxHighlighting",
            dependencies: [
                .product(name: "Highlightr", package: "Highlightr"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
            ]
        ),
        .testTarget(
            name: "WmuxSyntaxHighlightingTests",
            dependencies: ["WmuxSyntaxHighlighting"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
            ]
        ),
    ]
)
