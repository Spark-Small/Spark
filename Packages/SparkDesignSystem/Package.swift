// swift-tools-version: 6.0
// Package: SparkDesignSystem — Reusable SwiftUI layout primitives (tokens unchanged).

import PackageDescription

let package = Package(
    name: "SparkDesignSystem",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkDesignSystem", targets: ["SparkDesignSystem"])
    ],
    dependencies: [
        .package(path: "../SparkNetworking")
    ],
    targets: [
        .target(
            name: "SparkDesignSystem",
            dependencies: ["SparkNetworking"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkDesignSystemTests",
            dependencies: ["SparkDesignSystem"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
