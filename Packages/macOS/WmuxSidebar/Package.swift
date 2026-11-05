// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxSidebar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSidebar",
            targets: ["WmuxSidebar"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxSwiftRender"),
        // WmuxExtensionKit backs the ExtensionHost/ sidebar-extension host view
        // and browser presenter.
        .package(path: "../WmuxExtensionKit"),
    ],
    targets: [
        .target(
            name: "WmuxSidebar",
            dependencies: [
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxSwiftRender", package: "WmuxSwiftRender"),
                .product(name: "WmuxExtensionKit", package: "WmuxExtensionKit"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxSidebarTests",
            dependencies: [
                "WmuxSidebar",
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxSwiftRender", package: "WmuxSwiftRender"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
    ]
)
