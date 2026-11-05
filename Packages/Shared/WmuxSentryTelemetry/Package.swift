// swift-tools-version: 6.0

import PackageDescription

// `WmuxSentryTelemetry` provides local scrubbing with zero external Sentry dependencies.
let package = Package(
    name: "WmuxSentryTelemetry",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSentryScrubbing",
            targets: ["WmuxSentryScrubbing"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxSentryScrubbing",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxSentryScrubbingTests",
            dependencies: ["WmuxSentryScrubbing"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
