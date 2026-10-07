// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MusicStudio",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "MusicStudioCore", targets: ["MusicStudioCore"]),
        .executable(name: "MusicStudio", targets: ["MusicStudio"])
    ],
    targets: [
        .target(
            name: "MusicStudioCore",
            path: "Sources/MusicStudioCore"
        ),
        .executableTarget(
            name: "MusicStudio",
            dependencies: ["MusicStudioCore"],
            path: "Sources/MusicStudio"
        ),
        .testTarget(
            name: "MusicStudioTests",
            dependencies: ["MusicStudioCore", "MusicStudio"],
            path: "Tests/MusicStudioTests"
        )
    ]
)
