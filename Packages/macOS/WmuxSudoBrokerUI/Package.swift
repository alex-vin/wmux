// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSudoBrokerUI",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "WmuxSudoBrokerUI", targets: ["WmuxSudoBrokerUI"]),
    ],
    dependencies: [
        .package(path: "../WmuxSudoBroker"),
    ],
    targets: [
        .target(
            name: "WmuxSudoBrokerUI",
            dependencies: ["WmuxSudoBroker"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxSudoBrokerUITests",
            dependencies: ["WmuxSudoBrokerUI"]
        ),
    ]
)
