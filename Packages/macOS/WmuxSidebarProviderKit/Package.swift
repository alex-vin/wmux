// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WmuxSidebarProviderKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxSidebarProviderKit",
            targets: ["WmuxSidebarProviderKit"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxFoundation"),
    ],
    targets: [
        .target(
            name: "WmuxSidebarProviderKit",
            dependencies: ["WmuxFoundation"]
        ),
    ]
)
