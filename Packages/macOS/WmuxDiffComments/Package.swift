// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WmuxDiffComments",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WmuxDiffComments",
            targets: ["WmuxDiffComments"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxDiffComments",
            path: "Sources/WmuxDiffComments"
        ),
    ]
)
