// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CmuxGeminiQuota",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "CmuxGeminiQuota",
            targets: ["CmuxGeminiQuota"]
        ),
    ],
    targets: [
        .target(
            name: "CmuxGeminiQuota",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "CmuxGeminiQuotaTests",
            dependencies: ["CmuxGeminiQuota"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
