// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSidebarGit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSidebarGit",
            targets: ["WmuxSidebarGit"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxGit"),
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxSidebarGit",
            dependencies: [
                .product(name: "WmuxGit", package: "WmuxGit"),
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxSidebarGitTests",
            dependencies: [
                "WmuxSidebarGit",
                .product(name: "WmuxGit", package: "WmuxGit"),
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
