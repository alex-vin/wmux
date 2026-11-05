// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxFoundation",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxFoundation",
            targets: ["WmuxFoundation"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxFoundationAtomicsC",
            publicHeadersPath: "include"
        ),
        .target(
            name: "WmuxFoundation",
            dependencies: ["WmuxFoundationAtomicsC"],
            resources: [.process("Resources")],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxFoundationTests",
            dependencies: ["WmuxFoundation"]
        ),
    ]
)
