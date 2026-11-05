// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxWorkspaces",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxWorkspaces",
            targets: ["WmuxWorkspaces"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        // WorkspaceGroupNewPlacement (the typed setting value for new
        // in-group workspace placement) is owned by WmuxSettings.
        .package(path: "../WmuxSettings"),
        // Bonsplit drives the Window/ tmux pane-overlay geometry.
        .package(path: "../../../vendor/bonsplit"),
        // WMUXDebugLog backs the Session/ snapshot-restore logging.
        .package(path: "../WMUXDebugLog"),
        // WmuxTestSupport backs FileOpen/ PreferredEditorService UI-test capture.
        .package(path: "../WmuxTestSupport"),
        // WMUXAgentLaunch owns the OMX HUD command match the Session/ restore policy shares with the CLI.
        .package(path: "../WMUXAgentLaunch"),
    ],
    targets: [
        .target(
            name: "WmuxWorkspaces",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxSettings", package: "WmuxSettings"),
                .product(name: "Bonsplit", package: "bonsplit"),
                .product(name: "WMUXDebugLog", package: "WMUXDebugLog"),
                .product(name: "WmuxTestSupport", package: "WmuxTestSupport"),
                .product(name: "WMUXAgentLaunch", package: "WMUXAgentLaunch"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxWorkspacesTests",
            dependencies: [
                "WmuxWorkspaces",
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "Bonsplit", package: "bonsplit"),
                .product(name: "WmuxTestSupport", package: "WmuxTestSupport"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
