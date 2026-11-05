// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxFilePreviewCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxFilePreviewCore",
            targets: ["WmuxFilePreviewCore"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxFilePreviewCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxFilePreviewCoreTests",
            dependencies: ["WmuxFilePreviewCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
