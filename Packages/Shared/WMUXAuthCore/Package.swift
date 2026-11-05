// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WMUXAuthCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WMUXAuthCore",
            targets: ["WMUXAuthCore"]
        ),
    ],
    targets: [
        .target(
            name: "WMUXAuthCore"
        ),
        .testTarget(
            name: "WMUXAuthCoreTests",
            dependencies: ["WMUXAuthCore"]
        ),
    ]
)
