// swift-tools-version:5.0
import PackageDescription
let package = Package(
    name: "Runtime",
    products: [
        .library(
            name: "Runtime",
            targets: ["Runtime"])
        ],
        dependencies: [
             .package(url: "https://github.com/wickwirew/CRuntime.git", from: "2.1.2"),
             .package(url: "https://github.com/mattgallagher/CwlDemangle.git", .branch("master")),
        ],
    targets: [
        .target(
            name: "Runtime",
            dependencies: ["CRuntime", "CwlDemangle"]),
        .testTarget(
            name: "RuntimeTests",
            dependencies: ["Runtime"])
    ],
    swiftLanguageVersions: [.v5]
)
