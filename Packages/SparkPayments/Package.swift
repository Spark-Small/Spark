// swift-tools-version: 6.0
// Package: SparkPayments — StoreKit 2 subscriptions and paywall routing.

import PackageDescription

let package = Package(
    name: "SparkPayments",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkPayments", targets: ["SparkPayments"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking")
    ],
    targets: [
        .target(
            name: "SparkPayments",
            dependencies: ["SparkCore", "SparkNetworking"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkPaymentsTests",
            dependencies: ["SparkPayments"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
