// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSwiftRenderUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSwiftRenderUI",
            targets: ["WmuxSwiftRenderUI"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxSwiftRender"),
        .package(path: "../WmuxSettings"),
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxSwiftRenderUI",
            dependencies: [
                .product(name: "WmuxSwiftRender", package: "WmuxSwiftRender"),
                .product(name: "WmuxSettings", package: "WmuxSettings"),
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "WmuxSwiftRenderUITests",
            dependencies: ["WmuxSwiftRenderUI"]
        ),
        // Dev-only GUI lab for iterating on the reorderable drag interaction
        // without an app build. Run: swift run reorder-lab
        .executableTarget(
            name: "reorder-lab",
            dependencies: ["WmuxSwiftRenderUI"]
        ),
    ]
)
