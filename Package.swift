// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "GraphQLer",
    products: [
        .library(name: "GraphQLer", targets: ["GraphQLer"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GraphQLer",
            dependencies: []),
        .testTarget(
            name: "GraphQLTests",
            dependencies: ["GraphQLer"]),
    ]
)
