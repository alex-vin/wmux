// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxGit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxGit",
            targets: ["WmuxGit"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../../Shared/WmuxAgentChat"),
            ],
    targets: [
        .target(
            name: "WmuxGit",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxAgentChat", package: "WmuxAgentChat"),
                            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxGitTests",
            dependencies: ["WmuxGit"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
