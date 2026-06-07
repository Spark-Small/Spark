// swift-tools-version: 6.0
// Package: SparkProfile — Nexus「我的」tab.

import PackageDescription

let package = Package(
    name: "SparkProfile",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkProfile", targets: ["SparkProfile"])
    ],
    dependencies: [
        .package(path: "../SparkCore"),
        .package(path: "../SparkDesignSystem"),
        .package(path: "../SparkTrust"),
        .package(path: "../SparkSearch"),
        .package(path: "../SparkPayments"),
        .package(path: "../SparkNotifications")
    ],
    targets: [
        .target(
            name: "SparkProfile",
            dependencies: [
                "SparkCore",
                "SparkDesignSystem",
                "SparkTrust",
                "SparkSearch",
                "SparkPayments",
                "SparkNotifications"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkProfileTests",
            dependencies: ["SparkProfile"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
