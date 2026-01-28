// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Typeless",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "Typeless",
            dependencies: ["WhisperKit"],
            path: "Sources"
        )
    ]
)
