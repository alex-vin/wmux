// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxMemoryPressure",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxMemoryPressure",
            targets: ["WmuxMemoryPressure"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxMemoryPressure",
            dependencies: ["WmuxFoundation"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxMemoryPressureTests",
            dependencies: ["WmuxMemoryPressure"]
        ),
    ]
)
