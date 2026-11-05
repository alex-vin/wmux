// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxAgentDeliveryCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxAgentDeliveryCore",
            targets: ["WmuxAgentDeliveryCore"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxAgentDeliveryCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxAgentDeliveryCoreTests",
            dependencies: ["WmuxAgentDeliveryCore"]
        ),
    ]
)
