// swift-tools-version: 6.0
// Package: SparkCore — shared types, errors, logging, retry policies.

import PackageDescription

let package = Package(
    name: "SparkCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkCore", targets: ["SparkCore"])
    ],
    targets: [
        .target(
            name: "SparkCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkCoreTests",
            dependencies: ["SparkCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
