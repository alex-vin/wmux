// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxProductAnalytics",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxProductAnalytics",
            targets: ["WmuxProductAnalytics"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WmuxProductAnalytics",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxProductAnalyticsTests",
            dependencies: ["WmuxProductAnalytics"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
