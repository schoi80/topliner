// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ToplinerCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "ToplinerCore", targets: ["ToplinerCore"])
    ],
    targets: [
        .target(
            name: "ToplinerCore",
            path: "Topliner",
            exclude: [
                "App",
                "ContentView.swift",
                "Info.plist"
            ],
            sources: [
                "Models",
                "Services"
            ]
        ),
        .testTarget(
            name: "ToplinerCoreTests",
            dependencies: ["ToplinerCore"],
            path: "Tests/ToplinerCoreTests"
        )
    ]
)
