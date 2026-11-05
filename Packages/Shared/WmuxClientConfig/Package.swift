// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxClientConfig",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxClientConfig",
            targets: ["WmuxClientConfig"]
        ),
    ],
    dependencies: [
        .package(path: "../../macOS/WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxClientConfig",
            dependencies: ["WmuxFoundation"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "WmuxClientConfigTests",
            dependencies: ["WmuxClientConfig"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
