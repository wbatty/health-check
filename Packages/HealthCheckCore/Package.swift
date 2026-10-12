// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HealthCheckCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "HealthCheckCore", targets: ["HealthCheckCore"])
    ],
    targets: [
        .target(name: "HealthCheckCore"),
        .testTarget(name: "HealthCheckCoreTests", dependencies: ["HealthCheckCore"])
    ]
)
