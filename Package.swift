// swift-tools-version: 5.9
import PackageDescription

// 获取包根目录
let packageDir = Context.packageDirectory

let package = Package(
    name: "Typeless",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "CSherpaOnnx",
            path: "Sources/CSherpaOnnx",
            publicHeadersPath: "."
        ),
        .executableTarget(
            name: "Typeless",
            dependencies: [
                "WhisperKit",
                "CSherpaOnnx"
            ],
            path: "Sources",
            exclude: ["CSherpaOnnx"],
            linkerSettings: [
                .unsafeFlags(["-L\(packageDir)/Frameworks/sherpa-onnx/lib"]),
                .linkedLibrary("sherpa-onnx-c-api"),
                .linkedLibrary("onnxruntime")
            ]
        )
    ]
)
