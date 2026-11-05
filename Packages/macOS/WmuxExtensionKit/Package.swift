// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WmuxExtensionKit",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxExtensionKit",
            targets: ["WmuxExtensionKit"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxExtensionKit"
        ),
        .testTarget(
            name: "WmuxExtensionKitTests",
            dependencies: ["WmuxExtensionKit"]
        ),
    ]
)
