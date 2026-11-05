// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WmuxSurfaceCatalogModel",
    platforms: [.macOS(.v14)],
    products: [.library(name: "WmuxSurfaceCatalogModel", targets: ["WmuxSurfaceCatalogModel"])],
    dependencies: [
        .package(path: "../WMUXDebugLog"),
        .package(path: "../WmuxCore"),
            ],
    targets: [
        .target(
            name: "WmuxSurfaceCatalogModel",
            dependencies: ["WMUXDebugLog", "WmuxCore"],
            // The files moved out of the app target unchanged; keep its language mode.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "WmuxSurfaceCatalogModelTests", dependencies: ["WmuxSurfaceCatalogModel"])
    ]
)
