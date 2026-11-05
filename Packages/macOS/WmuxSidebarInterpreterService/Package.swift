// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSidebarInterpreterService",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // Host-side client + wire protocol the app links against.
        .library(
            name: "WmuxSidebarInterpreterClient",
            targets: ["WmuxSidebarInterpreterClient"]
        ),
        // The out-of-process worker that runs the untrusted interpreter.
        .executable(
            name: "wmux-sidebar-interpreter",
            targets: ["wmux-sidebar-interpreter"]
        ),
        // Headless protocol fixture for RenderWorkerClient supervision tests.
        .executable(
            name: "wmux-sidebar-render-fixture",
            targets: ["wmux-sidebar-render-fixture"]
        ),
        // Remote rendering: the faceless render-worker loop and the host-side
        // layer-hosting sidebar surface.
        .library(
            name: "WmuxSidebarRemoteRender",
            targets: ["WmuxSidebarRemoteRender"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxSwiftRender"),
        .package(path: "../WmuxSwiftRenderUI"),
    ],
    targets: [
        .target(
            name: "WmuxSidebarInterpreterClient",
            dependencies: ["WmuxSwiftRender"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "wmux-sidebar-interpreter",
            dependencies: ["WmuxSidebarInterpreterClient"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "wmux-sidebar-render-fixture",
            dependencies: ["WmuxSidebarInterpreterClient"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "WmuxSidebarRemoteRender",
            dependencies: [
                "WmuxSidebarInterpreterClient",
                .product(name: "WmuxSwiftRenderUI", package: "WmuxSwiftRenderUI"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "WmuxSidebarInterpreterClientTests",
            dependencies: ["WmuxSidebarInterpreterClient"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "WmuxSidebarRemoteRenderTests",
            dependencies: ["WmuxSidebarRemoteRender"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
