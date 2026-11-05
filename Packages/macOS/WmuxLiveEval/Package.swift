// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxLiveEval",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxLiveEval",
            targets: ["WmuxLiveEval"]
        ),
        .executable(
            name: "LiveEvalDemo",
            targets: ["LiveEvalDemo"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxSwiftRender"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
    ],
    targets: [
        .target(
            name: "WmuxLiveEval",
            dependencies: [
                .product(name: "WmuxSwiftRender", package: "WmuxSwiftRender"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "LiveEvalDemo",
            dependencies: ["WmuxLiveEval"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "WmuxLiveEvalTests",
            dependencies: ["WmuxLiveEval"]
        ),
    ]
)
