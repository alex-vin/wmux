// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxCanvas",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "WmuxCanvas",
            targets: ["WmuxCanvas"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxCanvas",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxCanvasTests",
            dependencies: [
                "WmuxCanvas",
            ]
        ),
    ]
)
