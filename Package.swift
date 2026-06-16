// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacKeyMapper",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "MacKeyMapperCore"),
        .executableTarget(
            name: "MacKeyMapper",
            dependencies: ["MacKeyMapperCore"]
        ),
        .testTarget(
            name: "MacKeyMapperCoreTests",
            dependencies: ["MacKeyMapperCore"]
        ),
    ]
)
