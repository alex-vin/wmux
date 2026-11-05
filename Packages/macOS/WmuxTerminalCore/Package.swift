// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxTerminalCore",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxTerminalCore",
            targets: ["WmuxTerminalCore"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../WMUXDebugLog"),
        .package(path: "../../Shared/WmuxGhosttyKit"),
    ],
    targets: [
        .target(
            name: "WmuxTerminalCore",
            dependencies: [
                // The same libghostty the app links; the terminal core's
                // value types and FFI seam speak the ghostty C types
                // directly so no translation layer can drift from the
                // runtime.
                .product(name: "WmuxGhosttyKit", package: "WmuxGhosttyKit"),
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WMUXDebugLog", package: "WMUXDebugLog"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ],
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),
        // Test-only stand-in for the @_silgen_name libghostty symbol bound by
        // GhosttyRuntimeCInterop: SwiftPM cannot link the GhosttyKit macOS
        // archive (its binary lacks the lib prefix), so the test runner
        // satisfies the link with a stub. The app links the real GhosttyKit.
        .target(
            name: "GhosttyRuntimeTestStubs",
            path: "Tests/GhosttyRuntimeTestStubs"
        ),
        .testTarget(
            name: "WmuxTerminalCoreTests",
            dependencies: [
                "WmuxTerminalCore",
                "GhosttyRuntimeTestStubs",
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ],
            // GhosttyKit's static lib carries C++ objects (glslang); the
            // standalone xctest bundle must link the C++ runtime itself.
            linkerSettings: [
                .linkedLibrary("c++"),
            ]
        ),
    ]
)
