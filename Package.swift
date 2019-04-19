// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "GraphQLGen",
    products: [
        .library(name: "GraphQLGen", targets: ["GraphQLGen"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GraphQLGen",
            dependencies: []),
        .testTarget(
            name: "GraphQLTests",
            dependencies: ["GraphQLGen"]),
    ]
)
