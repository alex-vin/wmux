// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxTerminal",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxTerminal",
            targets: ["WmuxTerminal"]
        ),
        // Lets other packages' test targets that link WmuxTerminal satisfy the
        // libghostty symbols the same way WmuxTerminalTests does.
        .library(
            name: "WmuxTerminalGhosttyRuntimeTestStubs",
            targets: ["WmuxTerminalGhosttyRuntimeTestStubs"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxTerminalCore"),
        .package(path: "../WMUXDebugLog"),
        .package(path: "../WMUXAgentLaunch"),
                .package(path: "../../Shared/WmuxTerminalPrediction"),
        .package(path: "../../Shared/WmuxGhosttyKit"),
        .package(path: "../../../vendor/bonsplit"),
    ],
    targets: [
        .target(
            name: "WmuxTerminal",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxTerminalCore", package: "WmuxTerminalCore"),
                .product(name: "WmuxGhosttyKit", package: "WmuxGhosttyKit"),
                .product(name: "WMUXDebugLog", package: "WMUXDebugLog"),
                .product(name: "WMUXAgentLaunch", package: "WMUXAgentLaunch"),
                                .product(name: "WmuxTerminalPrediction", package: "WmuxTerminalPrediction"),
                .product(name: "Bonsplit", package: "bonsplit"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        // Test-only stand-in for the @_silgen_name libghostty symbol bound by
        // WmuxTerminalCore's GhosttyRuntimeCInterop: SwiftPM cannot link the
        // GhosttyKit macOS archive (its binary lacks the lib prefix), so the
        // test runner satisfies the link with a stub. The app links the real
        // GhosttyKit. Named distinctly from WmuxTerminalCore's own
        // GhosttyRuntimeTestStubs target (a different implementation for a
        // different test suite): SwiftPM target names must be unique across
        // the whole resolved graph, and both packages resolve together in
        // wmux.xcworkspace.
        .target(
            name: "WmuxTerminalGhosttyRuntimeTestStubs",
            path: "Tests/GhosttyRuntimeTestStubs"
        ),
        .testTarget(
            name: "WmuxTerminalTests",
            dependencies: [
                "WmuxTerminal",
                "WmuxTerminalGhosttyRuntimeTestStubs",
                .product(name: "WmuxTerminalCore", package: "WmuxTerminalCore"),
                .product(name: "WmuxGhosttyKit", package: "WmuxGhosttyKit"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
