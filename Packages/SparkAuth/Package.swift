// swift-tools-version: 6.0
// Package: SparkAuth — Authentication domain, services, and login UI.

import PackageDescription

let package = Package(
    name: "SparkAuth",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkAuth", targets: ["SparkAuth"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkPersistence"),
        .package(path: "../SparkDesignSystem")
    ],
    targets: [
        .target(
            name: "SparkAuth",
            dependencies: ["SparkCore", "SparkNetworking", "SparkPersistence", "SparkDesignSystem"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkAuthTests",
            dependencies: ["SparkAuth"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
