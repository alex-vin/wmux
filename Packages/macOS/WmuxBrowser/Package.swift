// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxBrowser",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxBrowser",
            targets: ["WmuxBrowser"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../WMUXDebugLog"),
        .package(path: "../WmuxSettings"),
        .package(path: "../../../vendor/bonsplit"),
    ],
    targets: [
        .target(
            name: "WmuxBrowser",
            dependencies: [
                "WmuxFoundation",
                "WMUXDebugLog",
                "WmuxSettings",
                .product(name: "Bonsplit", package: "bonsplit"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxBrowserTests",
            dependencies: [
                "WmuxBrowser",
                "WmuxFoundation",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
