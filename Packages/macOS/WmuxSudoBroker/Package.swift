// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSudoBroker",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "WmuxSudoBroker", targets: ["WmuxSudoBroker"]),
    ],
    targets: [
        .target(
            name: "WmuxSudoBroker",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxSudoBrokerTests",
            dependencies: ["WmuxSudoBroker"]
        ),
    ]
)
