// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxAuthRuntime",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxAuthRuntime",
            targets: ["WmuxAuthRuntime"]
        ),
    ],
    dependencies: [
        .package(path: "../WMUXAuthCore"),
        .package(path: "../../macOS/WmuxFoundation"),
        .package(path: "../../../vendor/stack-auth-swift-sdk-prerelease"),
    ],
    targets: [
        .target(
            name: "WmuxAuthRuntime",
            dependencies: [
                "WMUXAuthCore",
                "WmuxFoundation",
                .product(name: "StackAuth", package: "stack-auth-swift-sdk-prerelease"),
            ],
            swiftSettings: [
                .define("WMUX_DEV_AUTH", .when(configuration: .debug)),
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxAuthRuntimeTests",
            dependencies: [
                "WmuxAuthRuntime",
                .product(name: "StackAuth", package: "stack-auth-swift-sdk-prerelease"),
            ],
            swiftSettings: [
                .define("WMUX_DEV_AUTH", .when(configuration: .debug)),
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
