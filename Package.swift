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
            .package(url: "https://github.com/nerdsupremacist/CRuntime.git", from: "2.1.2"),
            .package(url: "https://github.com/mattgallagher/CwlDemangle.git", from: "0.1.0"),
        ],
    targets: [
        .target(
            name: "Runtime",
            dependencies: ["CRuntime", "CwlDemangle"],
            swiftSettings: [
                .unsafeFlags(["-Xcc", "-D_GNU_SOURCE=1"], .when(platforms: [.linux]))
            ]),
        .testTarget(
            name: "RuntimeTests",
            dependencies: ["Runtime"])
    ],
    swiftLanguageVersions: [.v5]
)
