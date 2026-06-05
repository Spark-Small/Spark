// swift-tools-version: 6.0
// Package: SparkMessages — Messages feature (Domain / Data / Presentation).

import PackageDescription

let package = Package(
    name: "SparkMessages",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkMessages", targets: ["SparkMessages"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkDesignSystem")
    ],
    targets: [
        .target(
            name: "SparkMessages",
            dependencies: ["SparkCore", "SparkNetworking", "SparkDesignSystem"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkMessagesTests",
            dependencies: ["SparkMessages"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
