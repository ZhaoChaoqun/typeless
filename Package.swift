// swift-tools-version: 5.9
import PackageDescription

let packageDir = Context.packageDirectory

let package = Package(
    name: "Typeless",
    platforms: [
        .macOS(.v14)
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
