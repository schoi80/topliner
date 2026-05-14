// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ToplinerCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "ToplinerCore", targets: ["ToplinerCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.7.2"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit.git", from: "5.7.4")
    ],
    targets: [
        .target(
            name: "ToplinerCore",
            dependencies: [
                .product(name: "AudioKit", package: "AudioKit"),
                .product(name: "SoundpipeAudioKit", package: "SoundpipeAudioKit")
            ],
            path: "Topliner",
            exclude: [
                "App",
                "ContentView.swift",
                "Info.plist"
            ],
            sources: [
                "Models",
                "Services",
                "Features",
                "Design"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ToplinerCoreTests",
            dependencies: ["ToplinerCore"],
            path: "Tests/ToplinerCoreTests"
        )
    ]
)
