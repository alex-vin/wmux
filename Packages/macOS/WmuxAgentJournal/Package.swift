// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WmuxAgentJournal",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "WmuxAgentJournal",
            targets: ["WmuxAgentJournal"]
        ),
    ],
    targets: [
        .target(
            name: "WmuxAgentJournal",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
            ]
        ),
        .testTarget(
            name: "WmuxAgentJournalTests",
            dependencies: ["WmuxAgentJournal"]
        ),
    ]
)
