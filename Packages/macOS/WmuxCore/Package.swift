// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxCore",
            targets: ["WmuxCore"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxAgentDeliveryCore"),
    ],
    targets: [
        .target(
            name: "WmuxCore",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxAgentDeliveryCore", package: "WmuxAgentDeliveryCore"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxCoreTests",
            dependencies: ["WmuxCore"]
        ),
    ]
)
