// swift-tools-version: 6.0
// Package: SparkActivity — Activity list (Domain / Data / Presentation).

import PackageDescription

let package = Package(
    name: "SparkActivity",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkActivity", targets: ["SparkActivity"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkDesignSystem")
    ],
    targets: [
        .target(
            name: "SparkActivity",
            dependencies: ["SparkCore", "SparkNetworking", "SparkDesignSystem"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkActivityTests",
            dependencies: ["SparkActivity"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
