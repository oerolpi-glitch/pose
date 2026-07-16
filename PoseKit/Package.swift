// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "PoseKit",
    products: [
        .library(name: "PoseKit", targets: ["PoseKit"])
    ],
    targets: [
        .target(name: "PoseKit"),
        .testTarget(name: "PoseKitTests", dependencies: ["PoseKit"])
    ]
)
