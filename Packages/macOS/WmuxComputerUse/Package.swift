// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WmuxComputerUse",
    platforms: [.macOS(.v14)],
    products: [.library(name: "WmuxComputerUse", targets: ["WmuxComputerUse"])],
    dependencies: [
        .package(path: "../WmuxControlSocket"),
        .package(path: "../WmuxFoundation"),
        .package(path: "../WmuxSettings")
    ],
    targets: [
        .target(
            name: "WmuxComputerUse",
            dependencies: ["WmuxControlSocket", "WmuxFoundation", "WmuxSettings"],
            // Lane A preserves the executable target's language mode.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "WmuxComputerUseTests", dependencies: ["WmuxComputerUse"])
    ]
)
