// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sonexa",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Sonexa",
            targets: ["Sonexa"]
        ),
    ],
    dependencies: [
        // Add third-party dependencies here after verifying compatibility
    ],
    targets: [
        .target(
            name: "Sonexa",
            dependencies: [],
            path: "Sources/Sonexa",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SonexaTests",
            dependencies: ["Sonexa"],
            path: "Sources/SonexaTests"
        ),
    ]
)
