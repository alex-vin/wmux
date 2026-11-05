// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxAgentSessionStore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxAgentSessionStore",
            targets: ["WmuxAgentSessionStore"]
        ),
    ],
    dependencies: [
        .package(path: "../WMUXAgentLaunch"),
    ],
    targets: [
        .target(
            name: "WmuxAgentSessionStore",
            dependencies: [
                .product(name: "WMUXAgentLaunch", package: "WMUXAgentLaunch"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxAgentSessionStoreTests",
            dependencies: ["WmuxAgentSessionStore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
