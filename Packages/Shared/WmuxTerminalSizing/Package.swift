// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WmuxTerminalSizing",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "WmuxTerminalSizing", targets: ["WmuxTerminalSizing"])],
    targets: [
        .target(name: "WmuxTerminalSizing"),
        .testTarget(name: "WmuxTerminalSizingTests", dependencies: ["WmuxTerminalSizing"])
    ],
    swiftLanguageModes: [.v6]
)
