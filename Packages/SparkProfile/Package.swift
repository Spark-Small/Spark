// swift-tools-version: 6.0
// Package: SparkProfile — Viewer profile and trust surfaces (avatar upload).

import PackageDescription

let package = Package(
    name: "SparkProfile",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkProfile", targets: ["SparkProfile"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking")
    ],
    targets: [
        .target(
            name: "SparkProfile",
            dependencies: ["SparkCore", "SparkNetworking"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkProfileTests",
            dependencies: ["SparkProfile"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
