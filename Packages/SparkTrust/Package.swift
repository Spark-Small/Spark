// swift-tools-version: 6.0
// Package: SparkTrust — Nexus Trust Score (L1–L3 MVP).

import PackageDescription

let package = Package(
    name: "SparkTrust",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkTrust", targets: ["SparkTrust"]),
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkDesignSystem"),
    ],
    targets: [
        .target(
            name: "SparkTrust",
            dependencies: ["SparkCore", "SparkNetworking", "SparkDesignSystem"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SparkTrustTests",
            dependencies: ["SparkTrust"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
