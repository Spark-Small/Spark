// swift-tools-version: 6.0
// Package: SparkNotifications — APNs registration and push payload routing.

import PackageDescription

let package = Package(
    name: "SparkNotifications",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SparkNotifications", targets: ["SparkNotifications"])
    ],
    dependencies: [
        .package(path: "../SparkNetworking")
    ],
    targets: [
        .target(
            name: "SparkNotifications",
            dependencies: ["SparkNetworking"],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "SparkNotificationsTests",
            dependencies: ["SparkNotifications"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
