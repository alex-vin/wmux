// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSettingsUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSettingsUI",
            targets: ["WmuxSettingsUI"]
        ),
    ],
    dependencies: [
                .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxSettings"),
    ],
    targets: [
        .target(
            name: "WmuxSettingsUI",
            dependencies: [
                                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxSettings", package: "WmuxSettings"),
            ],
            resources: [
                .process("Resources/Localizable.xcstrings"),
                .copy("Resources/CustomSidebars"),
                .copy("Resources/CustomSidebarTemplatePreviews"),
            ]
        ),
        .testTarget(
            name: "WmuxSettingsUITests",
            dependencies: [
                                "WmuxSettingsUI",
                "WmuxSettings",
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ]
        ),
    ]
)
