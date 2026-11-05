// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WmuxTerminalSharing",
    platforms: [.macOS(.v14)],
    products: [.library(name: "WmuxTerminalSharing", targets: ["WmuxTerminalSharing"])],
    dependencies: [.package(path: "../../Shared/WmuxTerminalSizing")],
    targets: [
        .target(name: "WmuxTerminalSharing", dependencies: ["WmuxTerminalSizing"]),
        .testTarget(name: "WmuxTerminalSharingTests", dependencies: ["WmuxTerminalSharing", "WmuxTerminalSizing"]),
    ],
    swiftLanguageModes: [.v6]
)
