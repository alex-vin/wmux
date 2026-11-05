// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxAgentChat",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxAgentChat",
            targets: ["WmuxAgentChat"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxAgentChat",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "WmuxAgentChatTests",
            dependencies: ["WmuxAgentChat"],
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
