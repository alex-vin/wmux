// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WmuxControlSocket",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxControlSocket",
            targets: ["WmuxControlSocket"]
        ),
    ],
    dependencies: [
        .package(path: "../WmuxCore"),
        .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxSettings"),
    ],
    targets: [
        .target(
            name: "WmuxControlSocketAtomicsC",
            publicHeadersPath: "include"
        ),
        .target(
            name: "WmuxControlSocket",
            dependencies: [
                .product(name: "WmuxCore", package: "WmuxCore"),
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxSettings", package: "WmuxSettings"),
                "WmuxControlSocketAtomicsC",
            ],
            resources: [
                .process("Resources/Localizable.xcstrings"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxControlSocketTests",
            dependencies: [
                "WmuxControlSocket",
                .product(name: "WmuxFoundation", package: "WmuxFoundation"),
                .product(name: "WmuxSettings", package: "WmuxSettings"),
            ]
        ),
    ]
)
