// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WMUXAgentLaunch",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WMUXAgentLaunch",
            targets: ["WMUXAgentLaunch"]
        ),
    ],
    targets: [
        .target(
            name: "WMUXAgentLaunch"
        ),
        .testTarget(
            name: "WMUXAgentLaunchTests",
            dependencies: ["WMUXAgentLaunch"]
        ),
    ]
)
