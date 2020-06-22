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
            .package(url: "https://github.com/nerdsupremacist/CwlDemangle.git", from: "0.1.1-beta."),
        ],
    targets: [
        .target(
            name: "Runtime",
            dependencies: ["CRuntime", "CwlDemangle", "CSymbols"]),

        .target(name: "CSymbols"),
        
        .testTarget(
            name: "RuntimeTests",
            dependencies: ["Runtime"]),
    ],
    swiftLanguageVersions: [.v5]
)
