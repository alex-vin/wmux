// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WMUXProjectModel",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WMUXProjectModel",
            targets: ["WMUXProjectModel"]
        ),
        .executable(
            name: "wmux-project-dump",
            targets: ["WMUXProjectDump"]
        ),
    ],
    targets: [
        .target(
            name: "WMUXProjectModel"
        ),
        .executableTarget(
            name: "WMUXProjectDump",
            dependencies: ["WMUXProjectModel"]
        ),
        .testTarget(
            name: "WMUXProjectModelTests",
            dependencies: ["WMUXProjectModel"]
        ),
    ]
)
