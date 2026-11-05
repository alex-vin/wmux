// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxAppKitSupportUI",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxAppKitSupportUI",
            targets: ["WmuxAppKitSupportUI"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxWorkspaces"),
    ],
    targets: [
        .target(
            name: "WmuxAppKitSupportUI",
            dependencies: [
                "WmuxFoundation",
                "WmuxWorkspaces",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxAppKitSupportUITests",
            dependencies: ["WmuxAppKitSupportUI"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
