// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MusicStudio",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MusicStudio", targets: ["MusicStudio"])],
    targets: [
        .executableTarget(name: "MusicStudio", path: "Sources/MusicStudio"),
        .testTarget(name: "MusicStudioTests", dependencies: ["MusicStudio"], path: "Tests/MusicStudioTests")
    ]
)
