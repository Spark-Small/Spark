// swift-tools-version: 6.0
// Package: SparkCommunity — Community posts (Domain / Data / Presentation).

import PackageDescription

let package = Package(
    name: "SparkCommunity",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkCommunity", targets: ["SparkCommunity"]),
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkDesignSystem"),
    ],
    targets: [
        .target(
            name: "SparkCommunity",
            dependencies: ["SparkCore", "SparkNetworking", "SparkDesignSystem"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SparkCommunityTests",
            dependencies: ["SparkCommunity"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
