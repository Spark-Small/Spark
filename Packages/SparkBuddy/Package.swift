// swift-tools-version: 6.0
// Package: SparkBuddy — Paid companion & offline meetup listings (Domain / Data / Presentation).

import PackageDescription

let package = Package(
    name: "SparkBuddy",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkBuddy", targets: ["SparkBuddy"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkNetworking"),
        .package(path: "../SparkDesignSystem"),
        .package(path: "../SparkPayments")
    ],
    targets: [
        .target(
            name: "SparkBuddy",
            dependencies: ["SparkCore", "SparkNetworking", "SparkDesignSystem", "SparkPayments"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkBuddyTests",
            dependencies: ["SparkBuddy"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
