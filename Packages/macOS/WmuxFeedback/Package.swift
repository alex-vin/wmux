// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxFeedback",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxFeedback",
            targets: ["WmuxFeedback"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxFeedback",
            dependencies: [
                "WmuxFoundation",
            ],
            resources: [
                // Folded from WmuxFeedbackUI: the composer's localized strings.
                .process("ComposerUI/Resources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxFeedbackTests",
            dependencies: ["WmuxFeedback"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
