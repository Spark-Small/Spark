// swift-tools-version: 6.0
// Package: SparkSearch — Search (Domain / Data / Presentation).

import PackageDescription

let package = Package(
    name: "SparkSearch",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkSearch", targets: ["SparkSearch"]),
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkDesignSystem"),
    ],
    targets: [
        .target(
            name: "SparkSearch",
            dependencies: ["SparkCore", "SparkNetworking", "SparkDesignSystem"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SparkSearchTests",
            dependencies: ["SparkSearch"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
