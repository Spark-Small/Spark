// swift-tools-version: 6.0
// Package: SparkLikes — Social discovery feed (喜欢 tab).

import PackageDescription

let package = Package(
    name: "SparkLikes",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkLikes", targets: ["SparkLikes"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkDesignSystem"),
        .package(path: "../SparkProfile")
    ],
    targets: [
        .target(
            name: "SparkLikes",
            dependencies: ["SparkCore", "SparkNetworking", "SparkDesignSystem", "SparkProfile"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkLikesTests",
            dependencies: ["SparkLikes"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
