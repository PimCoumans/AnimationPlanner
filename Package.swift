// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnimationPlanner",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "AnimationPlanner",
            targets: ["AnimationPlanner"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AnimationPlanner",
            dependencies: []),
        .testTarget(
            name: "AnimationPlannerTests",
            dependencies: ["AnimationPlanner"]),
    ],
    swiftLanguageVersions: [.v5]
)
