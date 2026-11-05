// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSettings",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSettings",
            targets: ["WmuxSettings"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxCore"),
    ],
    targets: [
        .target(
            name: "WmuxSettings",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxCore", package: "WmuxCore"),
            ],
            resources: [
                .copy("Resources/CustomSidebarTemplates"),
            ]
        ),
        .testTarget(
            name: "WmuxSettingsTests",
            dependencies: ["WmuxSettings"]
        ),
    ]
)
