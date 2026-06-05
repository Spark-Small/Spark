// swift-tools-version: 6.0
// Package: SparkNetworking — HTTP client and API configuration.

import PackageDescription

let package = Package(
    name: "SparkNetworking",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkNetworking", targets: ["SparkNetworking"])
    ],
    dependencies: [
        .package(path: "../SparkCore")
    ],
    targets: [
        .target(
            name: "SparkNetworking",
            dependencies: ["SparkCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkNetworkingTests",
            dependencies: ["SparkNetworking"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
