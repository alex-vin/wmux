// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxGeminiQuota",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxGeminiQuota",
            targets: ["WmuxGeminiQuota"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxGeminiQuota",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxGeminiQuotaTests",
            dependencies: ["WmuxGeminiQuota"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
