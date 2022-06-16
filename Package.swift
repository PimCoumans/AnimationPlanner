// swift-tools-version:5.5

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
    ]
)
