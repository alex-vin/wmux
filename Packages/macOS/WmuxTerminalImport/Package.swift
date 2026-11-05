// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxTerminalImport",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxTerminalImport",
            targets: ["WmuxTerminalImport"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxTerminalImport",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxTerminalImportTests",
            dependencies: ["WmuxTerminalImport"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
