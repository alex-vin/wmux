// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxTestSupport",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxTestSupport",
            targets: ["WmuxTestSupport"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxTestSupport",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxTestSupportTests",
            dependencies: ["WmuxTestSupport"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
